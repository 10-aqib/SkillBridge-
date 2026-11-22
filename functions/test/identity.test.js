// Identity verification (functions/src/identity/*) against the in-memory
// fake DB. Only the simulator is exercised: the NADRA adapter must refuse
// everything until an official integration exists.
const test = require("node:test");
const assert = require("node:assert/strict");
const cnic = require("../.test-build/identity/cnic.js");
const providers = require("../.test-build/identity/providers.js");
const sessions = require("../.test-build/identity/sessions.js");
const identity = require("../.test-build/identity/index.js");
const { fakeDb, rejects: rejectsWith } = require("./fake_db");

const rejects = (p, code) => rejectsWith(assert, p, code);
const EMU = { FUNCTIONS_EMULATOR: "true", GCLOUD_PROJECT: "demo-skillbridge" };
const MATCH = "99999-0000001-1";
const MISMATCH = "99999-0000002-2";
const UNAVAILABLE = "99999-0000004-4";
const REVIEW = "99999-0000006-6";

let clock;
let ids;
function setup(seed = {}) {
  clock = new Date("2026-11-22T10:00:00Z");
  ids = 0;
  const db = fakeDb({
    users: {
      w1: { role: "worker", isActive: true, displayName: "Bilal" },
      c1: { role: "client", isActive: true, displayName: "Ayesha" },
      x1: { role: "worker", isActive: false },
    },
    ...seed,
  });
  const notes = [];
  const deps = {
    db,
    now: () => clock,
    provider: new providers.SimulatorProvider(EMU),
    newId: () => `session${String(++ids).padStart(4, "0")}`,
    notify: async (uid, kind, sid, test) => notes.push({ uid, kind, sid, test }),
  };
  return { db, deps, notes };
}
const fresh = () => Math.floor(clock.getTime() / 1000) - 60;
const consent = (cnicValue) => ({ cnic: cnicValue, consentAccepted: true, consentVersion: sessions.CONSENT_VERSION });
const capture = (quality = 90) => ({ format: "simulated", payload: "SIMULATED-CAPTURE-REFERENCE", quality });
let req = 0;
const rid = () => `request${String(++req).padStart(4, "0")}`;

// ── CNIC ──────────────────────────────────────────────────────────────────

test("CNIC: 13 digits in XXXXX-XXXXXXX-X or plain form; masked and digested, never stored whole", () => {
  assert.equal(cnic.cnicDigits("35202-1234567-1"), "3520212345671");
  assert.equal(cnic.cnicDigits("3520212345671"), "3520212345671");
  for (const bad of ["35202-1234567", "35202-12345671-1", "0520212345671", "1111111111111", "35202 1234567 1", 3520212345671, null]) {
    assert.equal(cnic.cnicDigits(bad), null, String(bad));
  }
  assert.equal(cnic.maskCnic("3520212345671"), "35202-•••••••-1");
  const a = cnic.cnicDigest("3520212345671", "pepper-a");
  assert.equal(a.length, 64);
  assert.notEqual(a, cnic.cnicDigest("3520212345671", "pepper-b"), "keyed");
  assert.ok(!a.includes("3520212345671"));
});

// ── Gate ──────────────────────────────────────────────────────────────────

test("NADRA adapter: not ready with default settings, not ready even with every flag on (no official adapter yet), never callable", async () => {
  const off = new providers.NadraBiometricProvider({ enabled: false, accessApproved: false, credentialsConfigured: false, captureSdkApproved: false, environment: "none" });
  assert.equal(off.readiness().ready, false);
  const allOn = new providers.NadraBiometricProvider({ enabled: true, accessApproved: true, credentialsConfigured: true, captureSdkApproved: true, environment: "production" });
  assert.equal(allOn.readiness().ready, false);
  assert.equal(allOn.readiness().checks.adapterImplemented, false);
  await assert.rejects(allOn.verify(), /provider-not-ready/);
  assert.equal(await allOn.parseCallback({}, {}), null, "no callback accepted");
  assert.equal(allOn.acceptsCnic("9999900000011"), false, "synthetic identities never go to NADRA");
});

test("simulator: only on the emulator with a demo project, never in production", () => {
  assert.equal(providers.simulatorAllowed(EMU), true);
  assert.equal(providers.simulatorAllowed({ GCLOUD_PROJECT: "demo-skillbridge" }), false, "deployed demo project");
  assert.equal(providers.simulatorAllowed({ FUNCTIONS_EMULATOR: "true", GCLOUD_PROJECT: "skill-bridge-c68c3" }), false, "emulator pointed at prod");
  assert.equal(providers.simulatorAllowed({}), false);
  const nadra = new providers.NadraBiometricProvider({ enabled: true, accessApproved: true, credentialsConfigured: true, captureSdkApproved: true, environment: "production" });
  assert.equal(identity.chooseProvider(nadra, new providers.SimulatorProvider({ GCLOUD_PROJECT: "skill-bridge-c68c3" })), null, "production: nothing");
  assert.equal(identity.chooseProvider(nadra, new providers.SimulatorProvider(EMU)).id, "simulator");
});

test("simulator: synthetic identities only (never a real person's CNIC)", () => {
  const sim = new providers.SimulatorProvider(EMU);
  assert.equal(sim.acceptsCnic("9999900000011"), true);
  assert.equal(sim.acceptsCnic("3520212345671"), false);
  assert.equal(sim.acceptsCnic("9999912345678"), false, "unknown synthetic id");
});

// ── Create ────────────────────────────────────────────────────────────────

test("create: needs a recent sign-in, explicit consent at the current version, a valid synthetic CNIC, an active account with a role", async () => {
  const { deps } = setup();
  await rejects(sessions.createSession(deps, "w1", fresh() - 3600, consent(MATCH)), "failed-precondition");
  await rejects(sessions.createSession(deps, "w1", fresh(), { cnic: MATCH, consentAccepted: false, consentVersion: sessions.CONSENT_VERSION }), "failed-precondition");
  await rejects(sessions.createSession(deps, "w1", fresh(), { cnic: MATCH, consentAccepted: true, consentVersion: "old" }), "failed-precondition");
  await rejects(sessions.createSession(deps, "w1", fresh(), consent("12345")), "invalid-argument");
  await rejects(sessions.createSession(deps, "w1", fresh(), consent("35202-1234567-1")), "invalid-argument");
  await rejects(sessions.createSession(deps, "x1", fresh(), consent(MATCH)), "permission-denied");
  await rejects(sessions.createSession({ ...deps, provider: null }, "w1", fresh(), consent(MATCH)), "failed-precondition");
});

test("create: a session with masked CNIC, digest, consent record and audit; same CNIC again reuses it", async () => {
  const { db, deps } = setup();
  const r = await sessions.createSession(deps, "w1", fresh(), consent(MATCH));
  assert.equal(r.provider, "simulator");
  assert.equal(r.test, true);
  const s = db.data.identityVerifications[r.sessionId];
  assert.equal(s.status, "pending");
  assert.equal(s.maskedCnic, "99999-•••••••-1");
  assert.equal(s.userRole, "worker");
  assert.equal(s.consentVersion, sessions.CONSENT_VERSION);
  assert.ok(!JSON.stringify(s).includes("9999900000011"), "full CNIC never stored");
  const events = Object.values(db.data[`identityVerifications/${r.sessionId}/events`]).map((e) => e.type);
  assert.deepEqual(events, ["session_created", "consent_recorded"]);
  assert.equal(db.data.users.w1.identityVerification.status, "pending");
  assert.equal(db.data.users.w1.identityVerification.verified, false);
  const again = await sessions.createSession(deps, "w1", fresh(), consent(MATCH));
  assert.equal(again.sessionId, r.sessionId);
  assert.equal(again.reused, true);
});

test("create: daily limit", async () => {
  const { deps } = setup();
  for (let i = 0; i < sessions.MAX_SESSIONS_PER_DAY; i++) {
    const r = await sessions.createSession(deps, "w1", fresh(), consent(MATCH));
    await sessions.cancelSession(deps, "w1", { sessionId: r.sessionId });
  }
  await rejects(sessions.createSession(deps, "w1", fresh(), consent(MATCH)), "resource-exhausted");
});

// ── Submit ────────────────────────────────────────────────────────────────

test("worker: simulated match → TEST verified, never a real NADRA verification; notifications sent", async () => {
  const { db, deps, notes } = setup();
  const { sessionId } = await sessions.createSession(deps, "w1", fresh(), consent(MATCH));
  const r = await sessions.submitCapture(deps, "w1", { sessionId, cnic: MATCH, requestId: rid(), capture: capture() });
  assert.equal(r.status, "verified");
  assert.equal(r.test, true);
  const u = db.data.users.w1.identityVerification;
  assert.equal(u.status, "verified");
  assert.equal(u.verified, false, "simulated success never sets verified");
  assert.equal(u.test, true);
  assert.equal(u.provider, "simulator");
  assert.deepEqual(notes.map((n) => n.kind), ["submitted", "verified"]);
  assert.ok(notes.every((n) => n.test));
  const s = db.data.identityVerifications[sessionId];
  assert.ok(!JSON.stringify(s).includes("SIMULATED-CAPTURE-REFERENCE"), "capture payload never stored");
});

test("hirer: same model, same result handling", async () => {
  const { db, deps } = setup();
  const { sessionId } = await sessions.createSession(deps, "c1", fresh(), consent(MATCH));
  const r = await sessions.submitCapture(deps, "c1", { sessionId, cnic: MATCH, requestId: rid(), capture: capture() });
  assert.equal(r.status, "verified");
  assert.equal(db.data.identityVerifications[sessionId].userRole, "client");
});

test("mismatch is 'rejected'; poor quality and service problems are retryable, never a mismatch", async () => {
  let { db, deps } = setup();
  let s = await sessions.createSession(deps, "w1", fresh(), consent(MISMATCH));
  let r = await sessions.submitCapture(deps, "w1", { sessionId: s.sessionId, cnic: MISMATCH, requestId: rid(), capture: capture() });
  assert.equal(r.status, "rejected");
  assert.equal(r.failureCategory, "fingerprint_mismatch");

  ({ db, deps } = setup());
  s = await sessions.createSession(deps, "w1", fresh(), consent(MATCH));
  r = await sessions.submitCapture(deps, "w1", { sessionId: s.sessionId, cnic: MATCH, requestId: rid(), capture: capture(20) });
  assert.equal(r.status, "pending");
  assert.equal(r.failureCategory, "poor_quality");
  assert.equal(r.attemptsLeft, 2);
  r = await sessions.submitCapture(deps, "w1", { sessionId: s.sessionId, cnic: MATCH, requestId: rid(), capture: capture(95) });
  assert.equal(r.status, "verified", "retry within the same session");

  ({ db, deps } = setup());
  s = await sessions.createSession(deps, "w1", fresh(), consent(UNAVAILABLE));
  r = await sessions.submitCapture(deps, "w1", { sessionId: s.sessionId, cnic: UNAVAILABLE, requestId: rid(), capture: capture() });
  assert.equal(r.status, "pending");
  assert.equal(r.failureCategory, "service_unavailable");
  assert.notEqual(db.data.users.w1.identityVerification.status, "rejected");
});

test("attempt limit: the third retryable failure ends the session as failed (not rejected)", async () => {
  const { deps } = setup();
  const s = await sessions.createSession(deps, "w1", fresh(), consent(UNAVAILABLE));
  let r;
  for (let i = 0; i < sessions.MAX_ATTEMPTS_PER_SESSION; i++) {
    r = await sessions.submitCapture(deps, "w1", { sessionId: s.sessionId, cnic: UNAVAILABLE, requestId: rid(), capture: capture() });
  }
  assert.equal(r.status, "failed");
  await rejects(sessions.submitCapture(deps, "w1", { sessionId: s.sessionId, cnic: UNAVAILABLE, requestId: rid(), capture: capture() }), "failed-precondition");
});

test("manual review result", async () => {
  const { deps, notes } = setup();
  const s = await sessions.createSession(deps, "w1", fresh(), consent(REVIEW));
  const r = await sessions.submitCapture(deps, "w1", { sessionId: s.sessionId, cnic: REVIEW, requestId: rid(), capture: capture() });
  assert.equal(r.status, "manual_review");
  assert.equal(notes.at(-1).kind, "review");
});

test("idempotent: the same request id returns the stored result without a second provider call", async () => {
  const { deps } = setup();
  let calls = 0;
  const sim = new providers.SimulatorProvider(EMU);
  const counting = { ...sim, id: sim.id, isTest: true, readiness: () => sim.readiness(), acceptsCnic: (d) => sim.acceptsCnic(d), parseCallback: async () => null,
    verify: async (x) => { calls++; return sim.verify(x); } };
  const d = { ...deps, provider: counting };
  const s = await sessions.createSession(d, "w1", fresh(), consent(MATCH));
  const id = rid();
  const a = await sessions.submitCapture(d, "w1", { sessionId: s.sessionId, cnic: MATCH, requestId: id, capture: capture() });
  const b = await sessions.submitCapture(d, "w1", { sessionId: s.sessionId, cnic: MATCH, requestId: id, capture: capture() });
  assert.equal(calls, 1);
  assert.equal(b.replay, true);
  assert.equal(b.status, a.status);
});

test("security: another user's session, a different CNIC, an expired session, a finished session, a bad capture are all refused", async () => {
  const { db, deps } = setup();
  const s = await sessions.createSession(deps, "w1", fresh(), consent(MATCH));
  await rejects(sessions.submitCapture(deps, "c1", { sessionId: s.sessionId, cnic: MATCH, requestId: rid(), capture: capture() }), "permission-denied");
  await rejects(sessions.submitCapture(deps, "w1", { sessionId: s.sessionId, cnic: MISMATCH, requestId: rid(), capture: capture() }), "invalid-argument");
  await rejects(sessions.submitCapture(deps, "w1", { sessionId: s.sessionId, cnic: MATCH, requestId: rid(), capture: { format: "", payload: "" } }), "invalid-argument");
  await rejects(sessions.submitCapture(deps, "w1", { sessionId: s.sessionId, cnic: MATCH, requestId: rid(), capture: { format: "simulated", payload: "x".repeat(sessions.MAX_PAYLOAD_CHARS + 1) } }), "invalid-argument");
  clock = new Date(clock.getTime() + (sessions.SESSION_MINUTES + 1) * 60 * 1000);
  await rejects(sessions.submitCapture(deps, "w1", { sessionId: s.sessionId, cnic: MATCH, requestId: rid(), capture: capture() }), "deadline-exceeded");
  assert.equal(db.data.identityVerifications[s.sessionId].status, "expired");
  await rejects(sessions.submitCapture(deps, "w1", { sessionId: s.sessionId, cnic: MATCH, requestId: rid(), capture: capture() }), "failed-precondition");
});

test("a capture in a format the provider doesn't accept fails as an invalid request (not a mismatch)", async () => {
  const { deps } = setup();
  const s = await sessions.createSession(deps, "w1", fresh(), consent(MATCH));
  const r = await sessions.submitCapture(deps, "w1", { sessionId: s.sessionId, cnic: MATCH, requestId: rid(), capture: { format: "png", payload: "abc" } });
  assert.equal(r.status, "failed");
  assert.equal(r.failureCategory, "invalid_request");
});

test("one CNIC, one account: a second account with the same CNIC is refused", async () => {
  const { deps } = setup();
  const s = await sessions.createSession(deps, "w1", fresh(), consent(MATCH));
  await sessions.submitCapture(deps, "w1", { sessionId: s.sessionId, cnic: MATCH, requestId: rid(), capture: capture() });
  await rejects(sessions.createSession(deps, "c1", fresh(), consent(MATCH)), "already-exists");
});

test("a provider transaction reference can complete only one session (replay protection)", async () => {
  const { db, deps } = setup();
  const fixed = { ...new providers.SimulatorProvider(EMU), id: "simulator", isTest: true, readiness: () => ({ ready: true, checks: {} }),
    acceptsCnic: () => true, parseCallback: async () => null, verify: async () => ({ kind: "match", transactionRef: "SAME-REF" }) };
  const d = { ...deps, provider: fixed };
  const a = await sessions.createSession(d, "w1", fresh(), consent(MATCH));
  await sessions.submitCapture(d, "w1", { sessionId: a.sessionId, cnic: MATCH, requestId: rid(), capture: capture() });
  const b = await sessions.createSession(d, "c1", fresh(), consent(REVIEW));
  const r = await sessions.submitCapture(d, "c1", { sessionId: b.sessionId, cnic: REVIEW, requestId: rid(), capture: capture() });
  assert.equal(r.status, "failed");
  assert.equal(r.failureCategory, "invalid_response");
  assert.equal(db.data.users.c1.identityVerification.status, "failed");
});

test("cancel: own open session only; already-final stays as is", async () => {
  const { db, deps } = setup();
  const s = await sessions.createSession(deps, "w1", fresh(), consent(MATCH));
  await rejects(sessions.cancelSession(deps, "c1", { sessionId: s.sessionId }), "permission-denied");
  await sessions.cancelSession(deps, "w1", { sessionId: s.sessionId });
  assert.equal(db.data.identityVerifications[s.sessionId].status, "cancelled");
  assert.equal(db.data.users.w1.identityVerification.status, "cancelled");
});

test("a genuine verification is never overwritten by later attempts", async () => {
  const { db, deps } = setup({
    users: { w1: { role: "worker", isActive: true, identityVerification: { status: "verified", verified: true, provider: "nadra", test: false } } },
  });
  // Even the simulator cannot touch a real verification.
  const s = await sessions.createSession(deps, "w1", fresh(), consent(MISMATCH));
  await sessions.submitCapture(deps, "w1", { sessionId: s.sessionId, cnic: MISMATCH, requestId: rid(), capture: capture() });
  assert.equal(db.data.users.w1.identityVerification.verified, true);
  assert.equal(db.data.users.w1.identityVerification.provider, "nadra");
});

test("notifications: server-written, no CNIC; test results labelled", async () => {
  const { db } = setup();
  const n = identity.notifier(db, () => clock);
  await n("w1", "verified", "session0001", true);
  await n("w1", "verified", "session0002", false);
  const a = db.data.notifications.identity_session0001_verified;
  const b = db.data.notifications.identity_session0002_verified;
  assert.equal(a.source, "server");
  assert.match(a.title, /TEST/);
  assert.match(a.body, /not a real NADRA/);
  assert.equal(b.title, "Identity verified");
  assert.ok(!JSON.stringify(a).match(/\d{5}-\d{7}-\d/));
  assert.deepEqual(a.payload, { requestId: "session0001" });
});
