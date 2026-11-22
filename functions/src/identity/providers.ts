// Identity-verification providers.
//
// The app and the session logic talk only to `BiometricProvider`. Two
// implementations exist:
//
//   * `NadraBiometricProvider`: the place where NADRA's official service
//     (BIOSYS / multi-biometric verification through Nishan Pakistan) is
//     connected once SkillBridge has authorised access. Its request and
//     response formats, endpoints, credentials and capture SDK come ONLY from
//     NADRA's documentation under an agreement. None of that exists yet, so
//     this adapter reports itself not ready and refuses every call. Nothing
//     about NADRA's API is guessed here.
//
//   * `SimulatorProvider`: a test double for development and the FYP demo.
//     It only accepts synthetic CNICs (99999-…), never sends anything
//     anywhere, and can only run on the Firebase emulator with a demo project
//     (see `simulatorAllowed`). Its results are marked `test: true` and never
//     produce a NADRA-verified badge.

import { SYNTHETIC_PREFIX, isSyntheticCnic } from "./cnic";

/** What the approved capture SDK hands over. Opaque to SkillBridge. */
export interface CaptureSubmission {
  /** Capture format reported by the SDK (e.g. "simulated" for the simulator). */
  format: string;
  /** Opaque payload or reference from the SDK. Never stored or logged. */
  payload: string;
  /** Capture quality 0–100 as reported by the SDK, if any. */
  quality?: number;
}

export type ProviderOutcome =
  | { kind: "match"; transactionRef: string }
  | { kind: "no_match"; transactionRef: string; category: "fingerprint_mismatch" | "cnic_mismatch" }
  | { kind: "retry"; transactionRef?: string; category: "poor_quality" | "service_unavailable" | "timeout" }
  | { kind: "manual_review"; transactionRef: string; category: string }
  | { kind: "error"; category: "invalid_request" | "invalid_response" | "authorization_failure" };

export interface ProviderReadiness {
  ready: boolean;
  checks: Record<string, boolean>;
}

export interface BiometricProvider {
  /** "nadra" or "simulator". */
  readonly id: "nadra" | "simulator";
  /** Simulated results are never genuine identity verification. */
  readonly isTest: boolean;
  readiness(): ProviderReadiness;
  /** Accepts this CNIC for a session (the simulator: synthetic only). */
  acceptsCnic(digits: string): boolean;
  /** Fingerprint-to-CNIC match for one capture. */
  verify(input: { cnic: string; capture: CaptureSubmission; sessionId: string; attempt: number }): Promise<ProviderOutcome>;
  /**
   * Authenticates and parses an asynchronous result sent by the provider
   * (if the official service works that way). Returns null when the call is
   * not authentic.
   */
  parseCallback(headers: Record<string, string | undefined>, body: unknown): Promise<{ sessionId: string; outcome: ProviderOutcome } | null>;
}

export class ProviderNotReady extends Error {
  constructor() {
    super("provider-not-ready");
  }
}

// ── NADRA ─────────────────────────────────────────────────────────────────

/**
 * Set to true only in the change that implements NADRA's official request
 * signing, endpoints, response validation and callback authentication from
 * their documentation, after sandbox tests pass. Until then the adapter can
 * never be used, whatever the environment says.
 */
export const NADRA_ADAPTER_IMPLEMENTED = false;

export interface NadraSettings {
  /** NADRA_BIOMETRIC_ENABLED: must stay false until everything below is true. */
  enabled: boolean;
  /** NADRA_ACCESS_APPROVED: organisation onboarded and agreement signed. */
  accessApproved: boolean;
  /** NADRA_CREDENTIALS_CONFIGURED: credentials stored in Secret Manager. */
  credentialsConfigured: boolean;
  /** NADRA_CAPTURE_SDK_APPROVED: an approved capture SDK/device is integrated. */
  captureSdkApproved: boolean;
  /** NADRA_ENVIRONMENT: "none" | "sandbox" | "production". */
  environment: string;
}

export class NadraBiometricProvider implements BiometricProvider {
  readonly id = "nadra" as const;
  readonly isTest = false;
  constructor(private readonly settings: NadraSettings) {}

  readiness(): ProviderReadiness {
    const s = this.settings;
    const checks = {
      enabled: s.enabled,
      accessApproved: s.accessApproved,
      credentialsConfigured: s.credentialsConfigured,
      captureSdkApproved: s.captureSdkApproved,
      environmentSelected: s.environment === "sandbox" || s.environment === "production",
      adapterImplemented: NADRA_ADAPTER_IMPLEMENTED,
    };
    return { ready: Object.values(checks).every(Boolean), checks };
  }

  acceptsCnic(digits: string): boolean {
    return !isSyntheticCnic(digits);
  }

  async verify(): Promise<ProviderOutcome> {
    // Implement from NADRA's official specification only (see
    // NADRA_INTEGRATION_REQUIREMENTS.md). Until then: never callable.
    throw new ProviderNotReady();
  }

  async parseCallback(): Promise<null> {
    // No callback is accepted until NADRA's authentication scheme for it is
    // implemented from their documentation.
    return null;
  }
}

// ── Simulator ─────────────────────────────────────────────────────────────

/**
 * The simulator may run only on the Functions emulator with a `demo-`
 * project (no real Firebase project can reach it). This is checked on every
 * call, not just at start-up.
 */
export function simulatorAllowed(env: Record<string, string | undefined> = process.env): boolean {
  const project = env.GCLOUD_PROJECT ?? env.GCP_PROJECT ?? "";
  return env.FUNCTIONS_EMULATOR === "true" && project.startsWith("demo-");
}

/** Synthetic identities and what the simulator answers for each. */
export const SIMULATOR_IDENTITIES: Record<string, { label: string; outcome: "match" | "fingerprint_mismatch" | "cnic_mismatch" | "service_unavailable" | "timeout" | "manual_review" }> = {
  [`${SYNTHETIC_PREFIX}00000011`]: { label: "Simulated successful match", outcome: "match" },
  [`${SYNTHETIC_PREFIX}00000022`]: { label: "Simulated fingerprint mismatch", outcome: "fingerprint_mismatch" },
  [`${SYNTHETIC_PREFIX}00000033`]: { label: "Simulated CNIC mismatch", outcome: "cnic_mismatch" },
  [`${SYNTHETIC_PREFIX}00000044`]: { label: "Simulated NADRA service unavailable", outcome: "service_unavailable" },
  [`${SYNTHETIC_PREFIX}00000055`]: { label: "Simulated NADRA timeout", outcome: "timeout" },
  [`${SYNTHETIC_PREFIX}00000066`]: { label: "Simulated additional review", outcome: "manual_review" },
};

export class SimulatorProvider implements BiometricProvider {
  readonly id = "simulator" as const;
  readonly isTest = true;
  constructor(private readonly env: Record<string, string | undefined> = process.env) {}

  readiness(): ProviderReadiness {
    const allowed = simulatorAllowed(this.env);
    return { ready: allowed, checks: { emulatorDemoProject: allowed } };
  }

  acceptsCnic(digits: string): boolean {
    return isSyntheticCnic(digits) && digits in SIMULATOR_IDENTITIES;
  }

  async verify({ cnic, capture, sessionId, attempt }: { cnic: string; capture: CaptureSubmission; sessionId: string; attempt: number }): Promise<ProviderOutcome> {
    if (!simulatorAllowed(this.env)) throw new ProviderNotReady();
    if (capture.format !== "simulated") return { kind: "error", category: "invalid_request" };
    const ref = `SIM-${sessionId.slice(0, 8)}-${attempt}`;
    if (typeof capture.quality === "number" && capture.quality < 40) return { kind: "retry", transactionRef: ref, category: "poor_quality" };
    const who = SIMULATOR_IDENTITIES[cnic];
    if (!who) return { kind: "error", category: "invalid_request" };
    switch (who.outcome) {
      case "match":
        return { kind: "match", transactionRef: ref };
      case "fingerprint_mismatch":
      case "cnic_mismatch":
        return { kind: "no_match", transactionRef: ref, category: who.outcome };
      case "service_unavailable":
      case "timeout":
        return { kind: "retry", transactionRef: ref, category: who.outcome };
      case "manual_review":
        return { kind: "manual_review", transactionRef: ref, category: "provider_review" };
    }
  }

  async parseCallback(): Promise<null> {
    return null;
  }
}
