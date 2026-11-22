// Identity verification sessions (server side). The app never writes these
// records: firestore.rules allow the owner (and staff) to read them only.
//
// identityVerifications/{sessionId}
//   userId, userRole, provider ("nadra" | "simulator"), test, verificationMethod
//   ("fingerprint"), status, maskedCnic, cnicDigest, consentVersion,
//   consentAcceptedAt, consentPurpose, attempts, maxAttempts, lastRequestId,
//   transactionReference, resultCode, failureCategory, createdAt, updatedAt,
//   expiresAt, completedAt
// identityVerifications/{sessionId}/events/{eventId}: audit trail (no PII)
// identityCnicIndex/{digest}: one CNIC → one account (server only)
// identityTransactions/{providerRef}: a provider result is used once (server only)
// serverSecrets/identityPepper: random HMAC key for CNIC digests (server only)
// users/{uid}.identityVerification: {status, verified, method, provider,
//   verifiedAt, test} — server-managed; copied to publicProfiles.
//
// Never stored anywhere: the full CNIC, fingerprint images, templates,
// biometric hashes, capture payloads, or full provider responses.

import { randomBytes } from "crypto";
import { HttpsError } from "firebase-functions/v2/https";
import { cnicDigest, cnicDigits, maskCnic } from "./cnic";
import { BiometricProvider, CaptureSubmission, ProviderNotReady, ProviderOutcome } from "./providers";

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type Db = any;
type Data = Record<string, unknown>;

export const CONSENT_VERSION = "2026-11-22.v1";
export const CONSENT_PURPOSE = "identity_verification";
export const SESSION_MINUTES = 15;
export const MAX_ATTEMPTS_PER_SESSION = 3;
export const MAX_SESSIONS_PER_DAY = 5;
export const MAX_PAYLOAD_CHARS = 512 * 1024;
const RECENT_LOGIN_SECONDS = 15 * 60;

export const FINAL = new Set(["verified", "rejected", "failed", "manual_review", "expired", "cancelled"]);

export interface IdentityDeps {
  db: Db;
  now: () => Date;
  /** Chosen by the callable: NADRA when ready, else the simulator when allowed. */
  provider: BiometricProvider | null;
  newId: () => string;
}

const fail = (code: ConstructorParameters<typeof HttpsError>[0], message: string): never => {
  throw new HttpsError(code, message);
};

const str = (v: unknown) => (typeof v === "string" ? v : "");
const ms = (v: unknown): number => {
  if (v instanceof Date) return v.getTime();
  if (v && typeof (v as { toMillis?: () => number }).toMillis === "function") return (v as { toMillis: () => number }).toMillis();
  return typeof v === "number" ? v : 0;
};

/** The HMAC key for CNIC digests: created once, server-only. */
export async function pepper(db: Db): Promise<string> {
  const ref = db.collection("serverSecrets").doc("identityPepper");
  return db.runTransaction(async (tx: Db) => {
    const snap = await tx.get(ref);
    const existing = snap.exists ? str(snap.data().value) : "";
    if (existing.length >= 32) return existing;
    const value = randomBytes(32).toString("hex");
    tx.set(ref, { value, createdAt: new Date() });
    return value;
  });
}

async function audit(db: Db, sessionId: string, type: string, actor: string, at: Date, detail: Data = {}) {
  // Only codes and categories: never CNIC, payloads or provider responses.
  await db.collection("identityVerifications").doc(sessionId).collection("events").doc().set({ type, actor, at, ...detail });
}

function assertRecentLogin(authTime: unknown, now: Date) {
  if (typeof authTime !== "number" || now.getTime() / 1000 - authTime > RECENT_LOGIN_SECONDS) {
    fail("failed-precondition", "recent-login-required");
  }
}

// ── Create ────────────────────────────────────────────────────────────────

export interface CreateInput {
  cnic?: unknown;
  consentAccepted?: unknown;
  consentVersion?: unknown;
}

export async function createSession(deps: IdentityDeps, uid: string, authTime: unknown, input: CreateInput) {
  const now = deps.now();
  assertRecentLogin(authTime, now);
  const provider = deps.provider;
  if (!provider) fail("failed-precondition", "not-available");
  const p = provider as BiometricProvider;
  if (input.consentAccepted !== true || input.consentVersion !== CONSENT_VERSION) fail("failed-precondition", "consent-required");
  const digits = cnicDigits(input.cnic);
  if (!digits) fail("invalid-argument", "invalid-cnic");
  if (!p.acceptsCnic(digits as string)) {
    fail("invalid-argument", p.isTest ? "synthetic-cnic-required" : "invalid-cnic");
  }

  const db = deps.db;
  const user = await db.collection("users").doc(uid).get();
  if (!user.exists || user.data().isActive === false) fail("permission-denied", "account-inactive");
  const role = str(user.data().role);
  if (role !== "worker" && role !== "client") fail("failed-precondition", "role-required");
  const current = (user.data().identityVerification ?? {}) as Data;
  if (current.verified === true && !p.isTest) fail("already-exists", "already-verified");

  // One open session at a time; reuse it (idempotent "start").
  const mine = await db.collection("identityVerifications").where("userId", "==", uid).get();
  let today = 0;
  for (const d of mine.docs) {
    const s = d.data() as Data;
    const created = ms(s.createdAt);
    if (now.getTime() - created < 24 * 3600 * 1000) today++;
    if (!FINAL.has(str(s.status))) {
      if (ms(s.expiresAt) > now.getTime()) {
        if (str(s.cnicDigest) === cnicDigest(digits as string, await pepper(db))) {
          return { sessionId: d.id, provider: str(s.provider), test: s.test === true, expiresAt: ms(s.expiresAt), reused: true };
        }
        // A different CNIC: close the old session first.
        await d.ref.update({ status: "cancelled", updatedAt: now, completedAt: now, failureCategory: "superseded" });
      } else {
        await d.ref.update({ status: "expired", updatedAt: now, completedAt: now });
      }
    }
  }
  if (today >= MAX_SESSIONS_PER_DAY) fail("resource-exhausted", "daily-limit");

  const digest = cnicDigest(digits as string, await pepper(db));
  const indexId = `${p.isTest ? "test_" : ""}${digest}`;
  const owner = await db.collection("identityCnicIndex").doc(indexId).get();
  if (owner.exists && str(owner.data().userId) !== uid) fail("already-exists", "cnic-in-use");

  const sessionId = deps.newId();
  const expiresAt = new Date(now.getTime() + SESSION_MINUTES * 60 * 1000);
  await db.collection("identityVerifications").doc(sessionId).set({
    userId: uid,
    userRole: role,
    provider: p.id,
    test: p.isTest,
    verificationMethod: "fingerprint",
    status: "pending",
    maskedCnic: maskCnic(digits as string),
    cnicDigest: digest,
    consentVersion: CONSENT_VERSION,
    consentAcceptedAt: now,
    consentPurpose: CONSENT_PURPOSE,
    attempts: 0,
    maxAttempts: MAX_ATTEMPTS_PER_SESSION,
    lastRequestId: null,
    transactionReference: null,
    resultCode: null,
    failureCategory: null,
    createdAt: now,
    updatedAt: now,
    expiresAt,
    completedAt: null,
  });
  await audit(db, sessionId, "session_created", "user", now, { provider: p.id, test: p.isTest });
  await audit(db, sessionId, "consent_recorded", "user", now, { consentVersion: CONSENT_VERSION, purpose: CONSENT_PURPOSE });
  await userStatus(db, uid, current, { status: "pending", provider: p.id, test: p.isTest }, now);
  return { sessionId, provider: p.id, test: p.isTest, expiresAt: expiresAt.getTime(), reused: false };
}

/** Updates users/{uid}.identityVerification without ever lowering a real verification. */
async function userStatus(db: Db, uid: string, current: Data, next: { status: string; provider: string; test: boolean; verified?: boolean; verifiedAt?: Date | null }, now: Date) {
  if (current.verified === true) return; // a genuine verification is never overwritten by later attempts
  await db.collection("users").doc(uid).update({
    identityVerification: {
      status: next.status,
      verified: next.verified === true && !next.test,
      method: "fingerprint",
      provider: next.provider,
      test: next.test,
      verifiedAt: next.verifiedAt ?? null,
    },
    updatedAt: now,
  });
}

// ── Submit ────────────────────────────────────────────────────────────────

export interface SubmitInput {
  sessionId?: unknown;
  cnic?: unknown;
  requestId?: unknown;
  capture?: unknown;
}

const RESULT_FOR: Record<ProviderOutcome["kind"], string> = {
  match: "verified",
  no_match: "rejected",
  retry: "pending",
  manual_review: "manual_review",
  error: "failed",
};

export type Notify = (uid: string, kind: "submitted" | "verified" | "rejected" | "review" | "failed", sessionId: string, test: boolean) => Promise<void>;

export async function submitCapture(deps: IdentityDeps & { notify: Notify }, uid: string, input: SubmitInput) {
  const now = deps.now();
  const db = deps.db;
  const sessionId = str(input.sessionId);
  const requestId = str(input.requestId);
  if (!/^[A-Za-z0-9_-]{8,64}$/.test(sessionId) || !/^[A-Za-z0-9_-]{8,64}$/.test(requestId)) fail("invalid-argument", "invalid-request");
  const c = (input.capture ?? {}) as Data;
  const capture: CaptureSubmission = { format: str(c.format), payload: str(c.payload), quality: typeof c.quality === "number" ? c.quality : undefined };
  if (!capture.format || !capture.payload || capture.payload.length > MAX_PAYLOAD_CHARS) fail("invalid-argument", "invalid-capture");
  const digits = cnicDigits(input.cnic);
  if (!digits) fail("invalid-argument", "invalid-cnic");

  const ref = db.collection("identityVerifications").doc(sessionId);
  const key = await pepper(db);

  // Claim the attempt atomically: ownership, state, expiry, idempotency, limits.
  const claim = await db.runTransaction(async (tx: Db) => {
    const snap = await tx.get(ref);
    if (!snap.exists) fail("not-found", "session-not-found");
    const s = snap.data() as Data;
    if (str(s.userId) !== uid) fail("permission-denied", "not-your-session");
    if (str(s.lastRequestId) === requestId) return { replay: true, s };
    if (FINAL.has(str(s.status))) fail("failed-precondition", `session-${str(s.status)}`);
    if (str(s.status) === "submitted" || str(s.status) === "processing") fail("failed-precondition", "already-submitted");
    if (ms(s.expiresAt) <= now.getTime()) {
      tx.update(ref, { status: "expired", updatedAt: now, completedAt: now });
      return { expired: true, s };
    }
    if (str(s.cnicDigest) !== cnicDigest(digits as string, key)) fail("invalid-argument", "cnic-mismatch-session");
    const attempts = (typeof s.attempts === "number" ? s.attempts : 0) + 1;
    if (attempts > MAX_ATTEMPTS_PER_SESSION) fail("resource-exhausted", "attempt-limit");
    tx.update(ref, { status: "submitted", attempts, lastRequestId: requestId, updatedAt: now });
    return { attempts, s };
  });
  if ((claim as { expired?: boolean }).expired) {
    await audit(db, sessionId, "session_expired", "system", now);
    fail("deadline-exceeded", "session-expired");
  }
  if ((claim as { replay?: boolean }).replay) {
    const s = (await ref.get()).data() as Data;
    return { sessionId, status: str(s.status), failureCategory: s.failureCategory ?? null, test: s.test === true, replay: true };
  }
  const session = (claim as { s: Data }).s;
  const attempts = (claim as { attempts: number }).attempts;
  const provider = deps.provider;
  if (!provider || provider.id !== str(session.provider)) {
    await ref.update({ status: "pending", updatedAt: now, failureCategory: "service_unavailable" });
    fail("unavailable", "provider-unavailable");
  }
  const p = provider as BiometricProvider;
  await audit(db, sessionId, "capture_submitted", "user", now, { attempt: attempts });
  if (attempts === 1) await deps.notify(uid, "submitted", sessionId, p.isTest);

  let outcome: ProviderOutcome;
  try {
    outcome = await p.verify({ cnic: digits as string, capture, sessionId, attempt: attempts });
  } catch (e) {
    // Not ready = the service can't be used now; anything else = treat as a
    // timeout. Both are retryable and never count as an identity mismatch.
    outcome = { kind: "retry", category: e instanceof ProviderNotReady ? "service_unavailable" : "timeout" };
  }
  // capture payload goes out of scope here: never stored or logged.
  capture.payload = "";

  // A provider transaction can complete exactly one session.
  const tref = "transactionRef" in outcome ? outcome.transactionRef : undefined;
  if (tref) {
    const tRef = db.collection("identityTransactions").doc(`${p.id}_${tref}`.replace(/[^A-Za-z0-9_-]/g, "_"));
    const used = await tRef.get();
    if (used.exists && str(used.data().sessionId) !== sessionId) outcome = { kind: "error", category: "invalid_response" };
    else await tRef.set({ sessionId, userId: uid, at: now });
  }

  let status = RESULT_FOR[outcome.kind];
  let category: string | null = outcome.kind === "match" ? null : (outcome as { category?: string }).category ?? null;
  // Out of attempts on a retryable problem: the session fails (user may start a new one).
  if (status === "pending" && attempts >= MAX_ATTEMPTS_PER_SESSION) status = "failed";

  const userRef = db.collection("users").doc(uid);
  const user = ((await userRef.get()).data() ?? {}) as Data;
  const current = (user.identityVerification ?? {}) as Data;

  if (status === "verified") {
    // One CNIC, one account: claim the index in the same transaction.
    const indexRef = db.collection("identityCnicIndex").doc(`${p.isTest ? "test_" : ""}${str(session.cnicDigest)}`);
    const ok = await db.runTransaction(async (tx: Db) => {
      const idx = await tx.get(indexRef);
      if (idx.exists && str(idx.data().userId) !== uid) return false;
      tx.set(indexRef, { userId: uid, sessionId, test: p.isTest, at: now });
      return true;
    });
    if (!ok) {
      status = "manual_review";
      category = "cnic_in_use";
    }
  }

  await ref.update({
    status,
    failureCategory: category,
    resultCode: outcome.kind,
    transactionReference: tref ?? null,
    updatedAt: now,
    completedAt: FINAL.has(status) ? now : null,
  });
  await audit(db, sessionId, "result", "provider", now, { status, category, test: p.isTest });
  await userStatus(db, uid, current, {
    status: status === "pending" ? "pending" : status,
    provider: p.id,
    test: p.isTest,
    verified: status === "verified",
    verifiedAt: status === "verified" ? now : null,
  }, now);

  const kind = status === "verified" ? "verified" : status === "rejected" ? "rejected" : status === "manual_review" ? "review" : status === "failed" ? "failed" : null;
  if (kind) await deps.notify(uid, kind, sessionId, p.isTest);
  return { sessionId, status, failureCategory: category, test: p.isTest, attemptsLeft: Math.max(0, MAX_ATTEMPTS_PER_SESSION - attempts), replay: false };
}

// ── Cancel ────────────────────────────────────────────────────────────────

export async function cancelSession(deps: IdentityDeps, uid: string, input: { sessionId?: unknown }) {
  const now = deps.now();
  const sessionId = str(input.sessionId);
  if (!/^[A-Za-z0-9_-]{8,64}$/.test(sessionId)) fail("invalid-argument", "invalid-request");
  const ref = deps.db.collection("identityVerifications").doc(sessionId);
  const done = await deps.db.runTransaction(async (tx: Db) => {
    const snap = await tx.get(ref);
    if (!snap.exists) fail("not-found", "session-not-found");
    const s = snap.data() as Data;
    if (str(s.userId) !== uid) fail("permission-denied", "not-your-session");
    if (FINAL.has(str(s.status))) return false;
    if (str(s.status) === "submitted" || str(s.status) === "processing") fail("failed-precondition", "already-submitted");
    tx.update(ref, { status: "cancelled", updatedAt: now, completedAt: now, failureCategory: "user_cancelled" });
    return true;
  });
  if (done) {
    await audit(deps.db, sessionId, "session_cancelled", "user", now);
    const user = ((await deps.db.collection("users").doc(uid).get()).data() ?? {}) as Data;
    const current = (user.identityVerification ?? {}) as Data;
    if (current.verified !== true && str(current.status) === "pending") {
      await deps.db.collection("users").doc(uid).update({
        identityVerification: { ...current, status: "cancelled" },
        updatedAt: now,
      });
    }
  }
  return { sessionId, status: "cancelled" };
}
