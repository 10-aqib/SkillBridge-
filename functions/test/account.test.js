// Account deletion (functions/src/account.ts) against the in-memory fake DB.
const test = require("node:test");
const assert = require("node:assert/strict");
const account = require("../.test-build/account.js");
const { fakeDb, rejects: rejectsWith } = require("./fake_db");

const rejects = (p, code) => rejectsWith(assert, p, code);
const NOW = 2_000_000_000;

const seed = () => ({
  users: { u1: { displayName: "Ayesha", photoUrl: "p.jpg" }, w1: { displayName: "Bilal" } },
  "users/u1/private": { contact: { phone: "+92300" } },
  "users/u1/savedJobs": { j9: { jobId: "j9" } },
  publicProfiles: { u1: { displayName: "Ayesha" } },
  fcmTokens: { u1: { tokens: {} } },
  mapsUsage: { u1: { routes: 3 } },
  ratings: { u1: { count: 1 } },
  notifications: { n1: { userId: "u1" }, n2: { userId: "w1" } },
  jobs: {
    j1: { clientId: "u1", clientName: "Ayesha", clientPhotoUrl: "p.jpg", status: "open" },
    j2: { clientId: "u1", clientName: "Ayesha", clientPhotoUrl: "p.jpg", status: "completed" },
  },
  proposals: { j3_u1: { workerId: "u1", workerName: "Ayesha", workerPhotoUrl: "p.jpg", status: "pending" } },
  contracts: { k1: { clientId: "u1", workerId: "w1", clientName: "Ayesha", clientPhotoUrl: "p.jpg", workerName: "Bilal", status: "completed" } },
  reviews: { r1: { reviewerId: "u1", reviewerName: "Ayesha", reviewerPhotoUrl: "p.jpg", revieweeId: "w1", revieweeName: "Bilal" } },
  chats: { u1_w1: { participantIds: ["u1", "w1"], participantNames: { u1: "Ayesha", w1: "Bilal" }, participantPhotos: { u1: "p.jpg", w1: null } } },
});

function deps(db) {
  const calls = [];
  return {
    calls,
    deps: {
      db,
      deleteStorageFolder: async (p) => calls.push(`storage:${p}`),
      deleteAuthUser: async (u) => calls.push(`auth:${u}`),
      nowSeconds: () => NOW,
    },
  };
}

test("needs a sign-in from the last 10 minutes", async () => {
  const db = fakeDb(seed());
  const { deps: d, calls } = deps(db);
  await rejects(account.deleteAccountFor(d, "u1", NOW - 11 * 60), "failed-precondition");
  await rejects(account.deleteAccountFor(d, "u1", undefined), "failed-precondition");
  assert.equal(calls.length, 0);
  assert.ok(db.data.users.u1, "nothing deleted");
});

test("refused while a contract is active; nothing is touched", async () => {
  const s = seed();
  s.contracts.k2 = { clientId: "w1", workerId: "u1", status: "active" };
  const db = fakeDb(s);
  const { deps: d, calls } = deps(db);
  await rejects(account.deleteAccountFor(d, "u1", NOW - 60), "failed-precondition");
  assert.equal(calls.length, 0);
  assert.equal(db.data.jobs.j1.status, "open");
});

test("deletes the person's own data, anonymises shared history, closes open work, then the sign-in", async () => {
  const db = fakeDb(seed());
  const { deps: d, calls } = deps(db);
  const r = await account.deleteAccountFor(d, "u1", NOW - 60);
  assert.equal(r.deleted, true);
  // Own data gone.
  for (const [c, id] of [["users", "u1"], ["publicProfiles", "u1"], ["fcmTokens", "u1"], ["mapsUsage", "u1"], ["ratings", "u1"], ["notifications", "n1"]]) {
    assert.equal(db.data[c][id], undefined, `${c}/${id}`);
  }
  assert.deepEqual(db.data["users/u1/private"], {});
  assert.deepEqual(db.data["users/u1/savedJobs"], {});
  // Other people's data kept.
  assert.ok(db.data.users.w1);
  assert.ok(db.data.notifications.n2);
  // Shared history anonymised.
  assert.equal(db.data.jobs.j1.status, "cancelled");
  assert.equal(db.data.jobs.j1.clientName, "Deleted user");
  assert.equal(db.data.jobs.j2.status, "completed", "finished job kept as is");
  assert.equal(db.data.jobs.j2.clientPhotoUrl, null);
  assert.equal(db.data.proposals.j3_u1.status, "withdrawn");
  assert.equal(db.data.contracts.k1.clientName, "Deleted user");
  assert.equal(db.data.contracts.k1.workerName, "Bilal", "the other party untouched");
  assert.equal(db.data.reviews.r1.reviewerName, "Deleted user");
  assert.equal(db.data.reviews.r1.revieweeName, "Bilal");
  assert.equal(db.data.chats.u1_w1.participantNames.u1, "Deleted user");
  assert.equal(db.data.chats.u1_w1.participantPhotos.u1, null);
  assert.equal(db.data.chats.u1_w1.participantNames.w1, "Bilal");
  // Storage then sign-in, last.
  assert.deepEqual(calls, ["storage:users/u1/", "auth:u1"]);
});

test("identity verification records go with the account (sessions, audit events, CNIC index, provider refs)", async () => {
  const s = seed();
  s.identityVerifications = { s1: { userId: "u1", status: "verified" }, s2: { userId: "w1", status: "pending" } };
  s["identityVerifications/s1/events"] = { e1: { type: "session_created" } };
  s.identityCnicIndex = { d1: { userId: "u1" }, d2: { userId: "w1" } };
  s.identityTransactions = { t1: { userId: "u1", sessionId: "s1" } };
  const db = fakeDb(s);
  const { deps: d } = deps(db);
  await account.deleteAccountFor(d, "u1", NOW - 60);
  assert.equal(db.data.identityVerifications.s1, undefined);
  assert.deepEqual(db.data["identityVerifications/s1/events"], {});
  assert.equal(db.data.identityCnicIndex.d1, undefined);
  assert.equal(db.data.identityTransactions.t1, undefined);
  assert.ok(db.data.identityVerifications.s2, "another person's record kept");
  assert.ok(db.data.identityCnicIndex.d2);
});
