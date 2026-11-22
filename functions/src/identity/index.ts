// Identity verification callables (NADRA fingerprint track).
//
// Gate: the real NADRA provider is used only when NADRA_BIOMETRIC_ENABLED is
// true AND every readiness check passes (which includes an adapter written
// from NADRA's official documentation; see providers.ts). Otherwise, on the
// emulator with a demo project only, the clearly-labelled simulator is used.
// In production without NADRA, verification reports "not available".

import { randomBytes } from "crypto";
import * as admin from "firebase-admin";
import { defineBoolean, defineString } from "firebase-functions/params";
import { logger } from "firebase-functions/v2";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { BiometricProvider, NadraBiometricProvider, SimulatorProvider } from "./providers";
import {
  CONSENT_VERSION,
  IdentityDeps,
  MAX_ATTEMPTS_PER_SESSION,
  Notify,
  SESSION_MINUTES,
  cancelSession,
  createSession,
  submitCapture,
} from "./sessions";

export const NADRA_BIOMETRIC_ENABLED = defineBoolean("NADRA_BIOMETRIC_ENABLED", { default: false });
export const NADRA_ACCESS_APPROVED = defineBoolean("NADRA_ACCESS_APPROVED", { default: false });
export const NADRA_CREDENTIALS_CONFIGURED = defineBoolean("NADRA_CREDENTIALS_CONFIGURED", { default: false });
export const NADRA_CAPTURE_SDK_APPROVED = defineBoolean("NADRA_CAPTURE_SDK_APPROVED", { default: false });
export const NADRA_ENVIRONMENT = defineString("NADRA_ENVIRONMENT", { default: "none" });

export function nadraProvider(): NadraBiometricProvider {
  return new NadraBiometricProvider({
    enabled: NADRA_BIOMETRIC_ENABLED.value(),
    accessApproved: NADRA_ACCESS_APPROVED.value(),
    credentialsConfigured: NADRA_CREDENTIALS_CONFIGURED.value(),
    captureSdkApproved: NADRA_CAPTURE_SDK_APPROVED.value(),
    environment: NADRA_ENVIRONMENT.value(),
  });
}

/** NADRA when fully ready; else the simulator where allowed; else none. */
export function chooseProvider(nadra: BiometricProvider, simulator: BiometricProvider): BiometricProvider | null {
  if (nadra.readiness().ready) return nadra;
  if (simulator.readiness().ready) return simulator;
  return null;
}

const TEXT: Record<string, { title: string; body: string }> = {
  submitted: { title: "Verification submitted", body: "We're checking your identity and will let you know the result." },
  verified: { title: "Identity verified", body: "Your identity was confirmed through NADRA fingerprint verification." },
  rejected: { title: "Identity not confirmed", body: "We couldn't confirm your identity. Open SkillBridge to see what you can do next." },
  review: { title: "Additional review needed", body: "Your identity verification needs an extra check." },
  failed: { title: "Verification didn't finish", body: "A technical problem stopped the check. You can try again." },
};
const TEST_TEXT: Record<string, { title: string; body: string }> = {
  ...TEXT,
  verified: { title: "TEST verification passed", body: "Simulated check only. This is not a real NADRA verification." },
};

/** In-app notification (and push, via the notify trigger). No CNIC or biometric data. */
export function notifier(db: admin.firestore.Firestore, now: () => Date): Notify {
  return async (uid, kind, sessionId, test) => {
    const t = (test ? TEST_TEXT : TEXT)[kind];
    await db.collection("notifications").doc(`identity_${sessionId}_${kind}`).set({
      userId: uid,
      title: test && kind !== "verified" ? `[TEST] ${t.title}` : t.title,
      body: t.body,
      type: `identity_${kind}`,
      payload: { requestId: sessionId },
      isRead: false,
      createdAt: now(),
      source: "server",
      verifiedAt: now(),
    });
  };
}

function deps(): IdentityDeps {
  return {
    db: admin.firestore(),
    now: () => new Date(),
    provider: chooseProvider(nadraProvider(), new SimulatorProvider()),
    newId: () => randomBytes(12).toString("hex"),
  };
}

const uidOf = (request: { auth?: { uid?: string } }): string => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Please sign in.");
  return uid;
};

const options = { maxInstances: 5, memory: "256MiB" as const, timeoutSeconds: 60 };

export const getIdentityVerificationConfig = onCall(options, async (request) => {
  uidOf(request);
  const nadra = nadraProvider().readiness();
  const simulator = new SimulatorProvider().readiness();
  const provider = nadra.ready ? "nadra" : simulator.ready ? "simulator" : null;
  return {
    provider,
    test: provider === "simulator",
    nadra: { ready: nadra.ready, checks: nadra.checks },
    consentVersion: CONSENT_VERSION,
    sessionMinutes: SESSION_MINUTES,
    maxAttempts: MAX_ATTEMPTS_PER_SESSION,
  };
});

export const createIdentityVerificationSession = onCall(options, async (request) => {
  const uid = uidOf(request);
  const r = await createSession(deps(), uid, request.auth?.token?.auth_time, request.data ?? {});
  logger.info(`[identity] ${uid}: session ${r.sessionId} (${r.provider}${r.reused ? ", reused" : ""})`);
  return r;
});

export const submitIdentityFingerprint = onCall(options, async (request) => {
  const uid = uidOf(request);
  const d = deps();
  const r = await submitCapture({ ...d, notify: notifier(d.db, d.now) }, uid, request.data ?? {});
  logger.info(`[identity] ${uid}: session ${r.sessionId} → ${r.status}${r.failureCategory ? ` (${r.failureCategory})` : ""}`);
  return r;
});

export const cancelIdentityVerificationSession = onCall(options, async (request) => {
  const uid = uidOf(request);
  return cancelSession(deps(), uid, request.data ?? {});
});
