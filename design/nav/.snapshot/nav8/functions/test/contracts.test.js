// Hiring and the work lifecycle (functions/src/contracts.ts), against a small
// in-memory stand-in for Firestore with transactions. Not Firebase.
const test = require("node:test");
const assert = require("node:assert/strict");
const { acceptProposal, contractAction, respondToDirectRequest, stageOf, validEvidence, CANCEL_REASONS, MAX_REVISIONS } = require("../.test-build/contracts.js");

const { fakeDb } = require("./fake_db");

const base = () => ({
  users: {
    c1: { role: "client", displayName: "Ayesha Khan", isActive: true },
    c2: { role: "client", displayName: "Usman", isActive: true },
    w1: { role: "worker", displayName: "Bilal Ahmed", isActive: true, workerProfile: { totalJobsCompleted: 3 } },
    w2: { role: "worker", displayName: "Kamran Ali", isActive: true, workerProfile: {} },
  },
  jobs: { j1: { clientId: "c1", clientName: "Ayesha Khan", title: "Fix sockets", description: "Two sockets spark.", city: "Lahore", address: "Gulberg III", status: "open", selectedWorkerId: null } },
  proposals: {
    j1_w1: { jobId: "j1", workerId: "w1", workerName: "Bilal Ahmed", clientId: "c1", status: "pending", proposedRate: 2500, rateType: "fixed", estimatedDuration: "1–2 days", jobTitle: "Fix sockets" },
    j1_w2: { jobId: "j1", workerId: "w2", workerName: "Kamran Ali", clientId: "c1", status: "pending", proposedRate: 700, rateType: "hourly", estimatedDuration: "Same day", jobTitle: "Fix sockets" },
  },
});

async function rejects(p, code) {
  await assert.rejects(p, (e) => e.code === code || (e.httpErrorCode && e.code === code) || String(e.code).includes(code));
}

test("1. accepting creates exactly one contract linked to job, proposal, client and worker", async () => {
  const db = fakeDb(base());
  const r = await acceptProposal(db, "c1", "j1_w1");
  assert.deepEqual(r, { contractId: "j1_w1", alreadyAccepted: false });
  const c = db.data.contracts.j1_w1;
  assert.equal(Object.keys(db.data.contracts).length, 1);
  assert.equal(c.jobId, "j1");
  assert.equal(c.proposalId, "j1_w1");
  assert.equal(c.clientId, "c1");
  assert.equal(c.workerId, "w1");
  assert.equal(c.agreedRate, 2500);
  assert.equal(c.rateType, "fixed");
  assert.equal(c.estimatedDuration, "1–2 days");
  assert.equal(c.jobDescription, "Two sockets spark.");
  assert.equal(c.commissionAmount, 250);
  assert.equal(c.workerEarnings, 2250);
  assert.equal(c.status, "active");
  assert.equal(c.paymentStatus, "unpaid");
  assert.deepEqual(c.createdAt, { __ts: true }, "server timestamp");
  assert.equal(stageOf(c), "not_started");
  assert.equal(db.data.jobs.j1.status, "assigned");
  assert.equal(db.data.jobs.j1.selectedWorkerId, "w1");
  assert.equal(db.data.proposals.j1_w1.status, "accepted");
  assert.equal(db.data.proposals.j1_w2.status, "rejected");
  assert.equal(db.data.proposals.j1_w2.closedReason, "filled");
  assert.deepEqual(db.data.chats.j1_w1.participantIds, ["c1", "w1"]);
  const notes = Object.values(db.data.notifications);
  assert.equal(notes.length, 1);
  assert.equal(notes[0].userId, "w1");
});

test("2. repeating the acceptance returns the same contract and writes nothing", async () => {
  const db = fakeDb(base());
  await acceptProposal(db, "c1", "j1_w1");
  const writes = db.writes;
  assert.deepEqual(await acceptProposal(db, "c1", "j1_w1"), { contractId: "j1_w1", alreadyAccepted: true });
  assert.equal(db.writes, writes);
  assert.equal(Object.keys(db.data.contracts).length, 1);
  await rejects(acceptProposal(db, "c1", "j1_w2"), "failed-precondition"); // second worker: proposal closed, job filled
  assert.equal(Object.keys(db.data.contracts).length, 1);
});

test("only the job owner can accept; workers can't hire themselves; closed proposals can't be accepted", async () => {
  await rejects(acceptProposal(fakeDb(base()), "c2", "j1_w1"), "permission-denied");
  await rejects(acceptProposal(fakeDb(base()), "w1", "j1_w1"), "permission-denied");
  for (const status of ["rejected", "withdrawn"]) {
    const s = base();
    s.proposals.j1_w1.status = status;
    await rejects(acceptProposal(fakeDb(s), "c1", "j1_w1"), "failed-precondition");
  }
  const closed = base();
  closed.jobs.j1.status = "cancelled";
  await rejects(acceptProposal(fakeDb(closed), "c1", "j1_w1"), "failed-precondition");
  const suspended = base();
  suspended.users.c1.isActive = false;
  await rejects(acceptProposal(fakeDb(suspended), "c1", "j1_w1"), "permission-denied");
  await rejects(acceptProposal(fakeDb(base()), "c1", "missing"), "not-found");
});

async function hired() {
  const db = fakeDb(base());
  await acceptProposal(db, "c1", "j1_w1");
  return db;
}

test("5. only the hired worker can start work, once, and the job follows", async () => {
  const db = await hired();
  await rejects(contractAction(db, "c1", { contractId: "j1_w1", action: "start" }), "permission-denied");
  await rejects(contractAction(db, "w2", { contractId: "j1_w1", action: "start" }), "permission-denied");
  assert.deepEqual(await contractAction(db, "w1", { contractId: "j1_w1", action: "start" }), { status: "active", stage: "in_progress" });
  assert.deepEqual(db.data.contracts.j1_w1.workStartedAt, { __ts: true });
  assert.equal(db.data.jobs.j1.status, "in_progress");
  await rejects(contractAction(db, "w1", { contractId: "j1_w1", action: "start" }), "failed-precondition");
});

test("6. only the hired worker submits, after starting, once, with a valid note and own photos", async () => {
  const db = await hired();
  await rejects(contractAction(db, "w1", { contractId: "j1_w1", action: "submit", note: "All done and tested." }), "failed-precondition");
  await contractAction(db, "w1", { contractId: "j1_w1", action: "start" });
  await rejects(contractAction(db, "c1", { contractId: "j1_w1", action: "submit", note: "All done and tested." }), "permission-denied");
  await rejects(contractAction(db, "w1", { contractId: "j1_w1", action: "submit", note: "short" }), "invalid-argument");
  await rejects(contractAction(db, "w1", { contractId: "j1_w1", action: "submit", note: "All done and tested.", attachments: ["contracts/other/evidence/a.jpg"] }), "invalid-argument");
  const ok = await contractAction(db, "w1", { contractId: "j1_w1", action: "submit", note: "Both sockets replaced and tested.", attachments: ["contracts/j1_w1/evidence/a.jpg"] });
  assert.equal(ok.stage, "submitted");
  assert.deepEqual(db.data.contracts.j1_w1.submission.attachments, ["contracts/j1_w1/evidence/a.jpg"]);
  assert.equal(db.data.contracts.j1_w1.status, "active", "not complete until the client confirms");
  await rejects(contractAction(db, "w1", { contractId: "j1_w1", action: "submit", note: "Submitting a second time." }), "failed-precondition");
});

test("7–8. only the client confirms completion, only after submission; the worker can never self-confirm", async () => {
  const db = await hired();
  await contractAction(db, "w1", { contractId: "j1_w1", action: "start" });
  await rejects(contractAction(db, "c1", { contractId: "j1_w1", action: "confirm" }), "failed-precondition");
  await contractAction(db, "w1", { contractId: "j1_w1", action: "submit", note: "Both sockets replaced and tested." });
  await rejects(contractAction(db, "w1", { contractId: "j1_w1", action: "confirm" }), "permission-denied");
  await rejects(contractAction(db, "c2", { contractId: "j1_w1", action: "confirm" }), "permission-denied");
  assert.equal((await contractAction(db, "c1", { contractId: "j1_w1", action: "confirm" })).status, "completed");
  assert.equal(db.data.jobs.j1.status, "completed");
  assert.deepEqual(db.data.contracts.j1_w1.completedAt, { __ts: true });
  assert.equal(db.data.users.w1.workerProfile.totalJobsCompleted, 4, "trusted statistic, +1");
  assert.equal(db.data.proposals.j1_w1.status, "accepted", "proposal history kept");
  await rejects(contractAction(db, "c1", { contractId: "j1_w1", action: "confirm" }), "failed-precondition");
  assert.equal(db.data.users.w1.workerProfile.totalJobsCompleted, 4, "counted once");
  await rejects(contractAction(db, "c1", { contractId: "j1_w1", action: "cancel", reason: "other" }), "failed-precondition");
});

test("cancelling: either party before submission, with a listed reason; recorded and the job follows", async () => {
  const db = await hired();
  await rejects(contractAction(db, "c1", { contractId: "j1_w1", action: "cancel", reason: "because" }), "invalid-argument");
  await rejects(contractAction(db, "c2", { contractId: "j1_w1", action: "cancel", reason: "other" }), "permission-denied");
  const r = await contractAction(db, "w1", { contractId: "j1_w1", action: "cancel", reason: "schedule_conflict", note: "Family emergency" });
  assert.equal(r.status, "cancelled");
  const c = db.data.contracts.j1_w1;
  assert.equal(c.cancelledBy, "w1");
  assert.equal(c.cancelledByRole, "worker");
  assert.equal(c.cancelReason, "schedule_conflict");
  assert.equal(db.data.jobs.j1.status, "cancelled");
  await rejects(contractAction(db, "w1", { contractId: "j1_w1", action: "start" }), "failed-precondition");

  const submitted = await hired();
  await contractAction(submitted, "w1", { contractId: "j1_w1", action: "start" });
  await contractAction(submitted, "w1", { contractId: "j1_w1", action: "submit", note: "Both sockets replaced and tested." });
  await rejects(contractAction(submitted, "c1", { contractId: "j1_w1", action: "cancel", reason: "other" }), "failed-precondition");
  assert.ok(CANCEL_REASONS.includes("other"));
});

test("booking requests: only the worker answers, once; accepting keeps the job assigned", async () => {
  const s = base();
  s.jobs.b1 = { clientId: "c1", title: "Direct Hire: Electrician", status: "assigned", selectedWorkerId: "w1" };
  s.contracts = { k1: { jobId: "b1", proposalId: "direct_hire", clientId: "c1", workerId: "w1", status: "pending", jobTitle: "Direct Hire: Electrician" } };
  const db = fakeDb(s);
  await rejects(contractAction(db, "c1", { contractId: "k1", action: "respond", accept: true }), "permission-denied");
  assert.equal((await contractAction(db, "w1", { contractId: "k1", action: "respond", accept: true })).stage, "not_started");
  assert.equal(db.data.jobs.b1.status, "assigned");
  await rejects(contractAction(db, "w1", { contractId: "k1", action: "respond", accept: false }), "failed-precondition");

  const s2 = base();
  s2.jobs.b1 = { clientId: "c1", title: "Direct Hire", status: "assigned", selectedWorkerId: "w1" };
  s2.contracts = { k1: { jobId: "b1", proposalId: "direct_hire", clientId: "c1", workerId: "w1", status: "pending" } };
  const db2 = fakeDb(s2);
  assert.equal((await contractAction(db2, "w1", { contractId: "k1", action: "respond", accept: false })).status, "rejected");
  assert.equal(db2.data.jobs.b1.status, "cancelled");
});

test("only the client shares the exact address, kept on the private contract", async () => {
  const db = await hired();
  await rejects(contractAction(db, "w1", { contractId: "j1_w1", action: "shareAddress", address: "House 5, Street 2" }), "permission-denied");
  await contractAction(db, "c1", { contractId: "j1_w1", action: "shareAddress", address: "House 5, Street 2, Gulberg III" });
  assert.equal(db.data.contracts.j1_w1.serviceAddress, "House 5, Street 2, Gulberg III");
  assert.equal(db.data.jobs.j1.address, "Gulberg III", "the job keeps only the general area");
});

test("each step notifies the other party", async () => {
  const db = await hired();
  await contractAction(db, "w1", { contractId: "j1_w1", action: "start" });
  await contractAction(db, "w1", { contractId: "j1_w1", action: "submit", note: "Both sockets replaced and tested." });
  await contractAction(db, "c1", { contractId: "j1_w1", action: "confirm" });
  const types = Object.values(db.data.notifications).map((n) => `${n.userId}:${n.type}`);
  assert.deepEqual(types, ["w1:contract_created", "c1:work_started", "c1:work_submitted", "w1:completion_confirmed"]);
});

test("unrelated users and suspended participants are refused", async () => {
  const db = await hired();
  await rejects(contractAction(db, "c2", { contractId: "j1_w1", action: "start" }), "permission-denied");
  db.data.users.w1.isActive = false;
  await rejects(contractAction(db, "w1", { contractId: "j1_w1", action: "start" }), "permission-denied");
  await rejects(contractAction(db, "w1", { contractId: "nope", action: "start" }), "not-found");
  await rejects(contractAction(db, "c1", { contractId: "j1_w1", action: "dance" }), "invalid-argument");
});

test("evidence paths are limited to this contract's folder", () => {
  assert.deepEqual(validEvidence("k1", ["contracts/k1/evidence/a.jpg", "contracts/k1/evidence/a.jpg"]), ["contracts/k1/evidence/a.jpg"]);
  assert.throws(() => validEvidence("k1", ["contracts/k1/evidence/../../x.jpg"]));
  assert.throws(() => validEvidence("k1", ["a", "b", "c", "d"]));
});

function withDirectRequest() {
  const s = base();
  s.jobs.d1 = { clientId: "c1", clientName: "Ayesha Khan", title: "Fix the geyser", description: "Geyser trips the breaker.", city: "Lahore", address: "Gulberg III",
    status: "open", selectedWorkerId: "w1", selectedWorkerName: "Bilal Ahmed", budgetMin: 1500, budgetMax: 2500, budgetType: "fixed" };
  return fakeDb(s);
}

test("direct requests: only the requested worker accepts; one contract with the client's budget range", async () => {
  const db = withDirectRequest();
  await rejects(respondToDirectRequest(db, "w2", "d1", true), "permission-denied");
  await rejects(respondToDirectRequest(db, "c1", "d1", true), "permission-denied");
  const r = await respondToDirectRequest(db, "w1", "d1", true);
  assert.deepEqual(r, { contractId: "d1_w1", status: "active", alreadyAnswered: false });
  const c = db.data.contracts.d1_w1;
  assert.equal(c.proposalId, "direct_request");
  assert.equal(c.clientId, "c1");
  assert.equal(c.agreedRate, 2500);
  assert.equal(c.priceMin, 1500);
  assert.equal(c.status, "active");
  assert.equal(stageOf(c), "not_started");
  assert.equal(db.data.jobs.d1.status, "assigned");
  assert.deepEqual(db.data.chats.d1_w1.participantIds, ["c1", "w1"]);
  const writes = db.writes;
  assert.equal((await respondToDirectRequest(db, "w1", "d1", true)).alreadyAnswered, true);
  assert.equal(db.writes, writes, "repeat changes nothing");
  // The usual lifecycle follows.
  await contractAction(db, "w1", { contractId: "d1_w1", action: "start" });
  assert.equal(db.data.jobs.d1.status, "in_progress");
});

test("direct requests: declining cancels the job and creates no contract; closed requests can't be answered", async () => {
  const db = withDirectRequest();
  assert.equal((await respondToDirectRequest(db, "w1", "d1", false)).status, "cancelled");
  assert.equal(db.data.jobs.d1.status, "cancelled");
  assert.equal(Object.keys(db.data.contracts ?? {}).length, 0, "no contract");
  await rejects(respondToDirectRequest(db, "w1", "d1", true), "failed-precondition");
  await rejects(respondToDirectRequest(db, "w1", "missing", true), "not-found");
});

// ── Phase 4B: revision, progress updates, live location ───────────────────

const act = (db, uid, action, extra = {}) => contractAction(db, uid, { contractId: "j1_w1", action, ...extra });
const NOTE = "Both sockets replaced and tested.";

async function submittedContract() {
  const db = await hired();
  await act(db, "w1", "start");
  await act(db, "w1", "submit", { note: NOTE, attachments: ["contracts/j1_w1/evidence/a.jpg"] });
  return db;
}

test("4B: the client can send submitted work back; it returns to in progress and the submission is kept", async () => {
  const db = await submittedContract();
  await rejects(act(db, "w1", "requestRevision", { note: "Please fix the cover plate." }), "permission-denied");
  await rejects(act(db, "c2", "requestRevision", { note: "Please fix the cover plate." }), "permission-denied");
  await rejects(act(db, "c1", "requestRevision", { note: "short" }), "invalid-argument");
  const r = await act(db, "c1", "requestRevision", { note: "Please fix the loose cover plate." });
  assert.deepEqual(r, { status: "active", stage: "in_progress" });
  const c = db.data.contracts.j1_w1;
  assert.equal(c.revisionCount, 1);
  assert.equal(c.submissionCount, 1);
  assert.equal(c.revisionNote, "Please fix the loose cover plate.");
  assert.deepEqual(c.revisionRequestedAt, { __ts: true });
  assert.equal(stageOf(c), "in_progress");
  assert.equal(db.data.jobs.j1.status, "in_progress", "the job stays in progress");
  const first = db.data["contracts/j1_w1/submissions"]["1"];
  assert.equal(first.note, NOTE);
  assert.deepEqual(first.attachments, ["contracts/j1_w1/evidence/a.jpg"]);
  assert.equal(first.revisionNote, "Please fix the loose cover plate.");
  // Nothing to confirm or send back again until the worker resubmits.
  await rejects(act(db, "c1", "confirm"), "failed-precondition");
  await rejects(act(db, "c1", "requestRevision", { note: "Please fix the loose cover plate." }), "failed-precondition");
  const notes = Object.values(db.data.notifications).filter((n) => n.type === "revision_requested");
  assert.deepEqual(notes.map((n) => n.userId), ["w1"]);
});

test("4B: the worker resubmits; history has both submissions; then the client confirms once", async () => {
  const db = await submittedContract();
  await act(db, "c1", "requestRevision", { note: "Please fix the loose cover plate." });
  await rejects(act(db, "w1", "start"), "failed-precondition");
  await act(db, "w1", "submit", { note: "Cover plate tightened and checked.", attachments: ["contracts/j1_w1/evidence/b.jpg"] });
  const c = db.data.contracts.j1_w1;
  assert.equal(stageOf(c), "submitted");
  assert.equal(c.submissionCount, 2);
  assert.equal(c.submission.note, "Cover plate tightened and checked.", "latest submission mirrored for Phase 4A readers");
  const subs = db.data["contracts/j1_w1/submissions"];
  assert.deepEqual(Object.keys(subs).sort(), ["1", "2"]);
  assert.equal(subs["1"].note, NOTE);
  assert.equal(subs["2"].note, "Cover plate tightened and checked.");
  assert.ok(Object.values(db.data.notifications).some((n) => n.userId === "c1" && n.title === "Work resubmitted"));
  assert.equal((await act(db, "c1", "confirm")).status, "completed");
  assert.equal(db.data.users.w1.workerProfile.totalJobsCompleted, 4, "counted once");
});

test("4B: at most MAX_REVISIONS rounds", async () => {
  const db = await submittedContract();
  for (let i = 0; i < MAX_REVISIONS; i++) {
    await act(db, "c1", "requestRevision", { note: `Round ${i + 1}: please adjust it.` });
    await act(db, "w1", "submit", { note: `Adjusted after round ${i + 1}.` });
  }
  await rejects(act(db, "c1", "requestRevision", { note: "One more round please." }), "failed-precondition");
  assert.equal(db.data.contracts.j1_w1.revisionCount, MAX_REVISIONS);
  assert.equal(stageOf(db.data.contracts.j1_w1), "submitted");
});

test("4B: a Phase 4A contract (no counters) can still be sent back and resubmitted", async () => {
  const s = base();
  s.contracts = { k1: { jobId: "j1", clientId: "c1", workerId: "w1", status: "active", workStartedAt: { __ts: true }, submittedAt: { __ts: true },
    submission: { note: "Old submission note.", attachments: [] }, jobTitle: "Fix sockets" } };
  const db = fakeDb(s);
  assert.equal(stageOf(db.data.contracts.k1), "submitted");
  await contractAction(db, "c1", { contractId: "k1", action: "requestRevision", note: "Please also check the switch." });
  const c = db.data.contracts.k1;
  assert.equal(stageOf(c), "in_progress");
  assert.equal(c.submissionCount, 1);
  assert.equal(db.data["contracts/k1/submissions"]["1"].note, "Old submission note.", "legacy submission recorded in history");
  await contractAction(db, "w1", { contractId: "k1", action: "submit", note: "Switch checked as well." });
  assert.equal(db.data.contracts.k1.submissionCount, 2);
  assert.equal(stageOf(db.data.contracts.k1), "submitted");
});

test("4B: progress updates: hired worker only, while open, saved once per request id", async () => {
  const db = await hired();
  const u = (uid, extra) => act(db, uid, "progressUpdate", { requestId: "req_12345678", note: "Bought the parts.", ...extra });
  await rejects(u("c1"), "permission-denied");
  await rejects(u("w2"), "permission-denied");
  await rejects(u("w1", { requestId: "bad id!" }), "invalid-argument");
  await rejects(u("w1", { note: "x" }), "invalid-argument");
  await u("w1"); // allowed before starting
  const writes = db.writes;
  await u("w1"); // retry with the same id
  assert.equal(db.writes, writes, "a retry writes nothing");
  const ups = db.data["contracts/j1_w1/updates"];
  assert.deepEqual(Object.keys(ups), ["req_12345678"]);
  assert.equal(ups.req_12345678.authorId, "w1");
  assert.deepEqual(ups.req_12345678.createdAt, { __ts: true }, "server time, not the client's");
  assert.equal(db.data.contracts.j1_w1.updateCount, 1);
  assert.equal(Object.values(db.data.notifications).filter((n) => n.type === "progress_update" && n.userId === "c1").length, 1);
  await act(db, "w1", "start");
  await u("w1", { requestId: "req_abcdefgh", note: "Wiring done, testing now." });
  assert.equal(db.data.contracts.j1_w1.updateCount, 2);
  await act(db, "w1", "submit", { note: NOTE });
  await rejects(u("w1", { requestId: "req_zzzzzzzz" }), "failed-precondition");
});

test("4B: live location ends when work is submitted, completed or cancelled", async () => {
  const live = (db) => (db.data["contracts/j1_w1/live"] ??= {});
  const db = await hired();
  await act(db, "w1", "start");
  live(db).location = { lat: 31.5, lng: 74.3, workerId: "w1" };
  await act(db, "w1", "submit", { note: NOTE });
  assert.equal(live(db).location, undefined, "deleted on submit");
  await act(db, "c1", "requestRevision", { note: "Please fix the loose cover plate." });
  live(db).location = { lat: 31.5, lng: 74.3, workerId: "w1" };
  await act(db, "w1", "submit", { note: NOTE });
  live(db).location = { lat: 31.5, lng: 74.3, workerId: "w1" }; // stray write
  await act(db, "c1", "confirm");
  assert.equal(live(db).location, undefined, "deleted on completion");

  const db2 = await hired();
  live(db2).location = { lat: 31.5, lng: 74.3, workerId: "w1" };
  await act(db2, "c1", "cancel", { reason: "other" });
  assert.equal(live(db2).location, undefined, "deleted on cancellation");
});
