// Notifications + push (functions/src/notify.ts) and profile copies
// (functions/src/profileCopies.ts), against the in-memory fake DB and a fake
// push sender. No Firebase, no FCM.
const test = require("node:test");
const assert = require("node:assert/strict");
const notify = require("../.test-build/notify.js");
const copies = require("../.test-build/profileCopies.js");
const { fakeDb } = require("./fake_db");

const T1 = "tokenAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA:APA91b-1";
const T2 = "tokenBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB:APA91b-2";

const world = () => ({
  users: {
    c1: { displayName: "Ayesha Khan", isActive: true },
    w1: { displayName: "Bilal Ahmed", isActive: true, fcmToken: T2 },
    w9: { displayName: "Gone", isActive: false },
  },
  fcmTokens: { w1: { tokens: { [T1]: { platform: "android" } } }, c1: { tokens: { [T1]: { platform: "android" } } } },
  chats: { c1_w1: { participantIds: ["c1", "w1"] } },
  "chats/c1_w1/messages": {
    m1: { senderId: "c1", content: "Can you come at 5 pm tomorrow?", type: "text" },
    m2: { senderId: "c1", content: "", type: "image", attachments: ["x"] },
    m3: { senderId: "w1", content: "from the recipient", type: "text" },
  },
  contracts: { k1: { clientId: "c1", workerId: "w1", jobTitle: "Fix the kitchen sockets", status: "active" } },
  jobs: { j1: { clientId: "c1", title: "Paint a room", status: "open", selectedWorkerId: null } },
  proposals: { j1_w1: { jobId: "j1", workerId: "w1", clientId: "c1", status: "pending" } },
});

function run(seed, notif, { send } = {}) {
  const db = fakeDb({ ...seed, notifications: { n1: notif } });
  const sent = [];
  const deps = {
    db,
    now: () => new Date(1_700_000_000_000),
    send: send ?? (async (tokens, m) => { sent.push({ tokens, m }); return []; }),
  };
  return { db, sent, go: () => notify.processNotification(deps, "n1") };
}

const base = { title: "anything the app wrote", body: "even a phishing link", isRead: false };

test("message: the text is rebuilt from the real message and sender; pushed to every device", async () => {
  const { db, sent, go } = run(world(), { ...base, userId: "w1", type: "message", payload: { chatId: "c1_w1", messageId: "m1" } });
  assert.equal(await go(), "pushed");
  const n = db.data.notifications.n1;
  assert.equal(n.title, "Ayesha Khan");
  assert.equal(n.body, "Can you come at 5 pm tomorrow?");
  assert.ok(n.verifiedAt && n.pushedAt);
  assert.deepEqual(sent[0].tokens.sort(), [T1, T2].sort(), "per-device token and the old single field");
  assert.equal(sent[0].m.data.chatId, "c1_w1");
  assert.equal(sent[0].m.data.notificationId, "n1");
  assert.equal(sent[0].m.tag, "chat_c1_w1");
});

test("message: a photo reads as a photo; a forged sender is removed", async () => {
  let r = run(world(), { ...base, userId: "w1", type: "message", payload: { chatId: "c1_w1", messageId: "m2" } });
  await r.go();
  assert.equal(r.db.data.notifications.n1.body, "📷 Photo");
  // m3 was sent BY the recipient: nobody else can have notified them about it.
  r = run(world(), { ...base, userId: "w1", type: "message", payload: { chatId: "c1_w1", messageId: "m3" } });
  assert.equal(await r.go(), "deleted");
  assert.equal(r.db.data.notifications.n1, undefined);
  assert.equal(r.sent.length, 0);
});

test("not in the chat / contract / job, or recipient inactive: removed, no push", async () => {
  const cases = [
    { userId: "w9", payload: { chatId: "c1_w1" } },
    { userId: "w2", payload: { chatId: "c1_w1" } },
    { userId: "w2", payload: { contractId: "k1" } },
    { userId: "w2", payload: { jobId: "j1" } },
    { userId: "w1", payload: { contractId: "missing" } },
    { userId: "w1", payload: {} },
    { userId: "c1", payload: { jobId: "j1", proposalId: "j9_w2" } },
  ];
  for (const c of cases) {
    const r = run({ ...world(), users: { ...world().users, w2: { displayName: "X", isActive: true } } }, { ...base, ...c });
    assert.equal(await r.go(), "deleted", JSON.stringify(c));
    assert.equal(r.sent.length, 0);
  }
});

test("contract step: server wording with the other party's real name and the job title", async () => {
  const { db, sent, go } = run(world(), { ...base, userId: "c1", type: "work_submitted", payload: { contractId: "k1", jobId: "j1" } });
  assert.equal(await go(), "pushed");
  assert.equal(db.data.notifications.n1.title, "Work submitted");
  assert.equal(db.data.notifications.n1.body, 'Bilal Ahmed submitted the work for "Fix the kitchen sockets". Please review it.');
  assert.equal(sent[0].m.data.contractId, "k1");
  assert.equal(sent[0].m.data.type, "work_submitted");
});

test("an unknown type on a contract gets a neutral server text, not the app's", async () => {
  const { db, go } = run(world(), { ...base, userId: "w1", type: "free_money", payload: { contractId: "k1" } });
  await go();
  assert.equal(db.data.notifications.n1.title, "Contract update");
  assert.equal(db.data.notifications.n1.type, "contract_update");
  assert.ok(!db.data.notifications.n1.body.includes("phishing"));
});

test("proposal: the client hears the worker's name and the job", async () => {
  const { db, go } = run(world(), { ...base, userId: "c1", payload: { jobId: "j1", proposalId: "j1_w1" } });
  await go();
  assert.equal(db.data.notifications.n1.title, "New proposal");
  assert.equal(db.data.notifications.n1.body, 'Bilal Ahmed sent a proposal for "Paint a room".');
});

test("settings: push off (or messages off) keeps the in-app item but sends nothing", async () => {
  const w = world();
  w.users.w1.notificationPrefs = { messages: false };
  let r = run(w, { ...base, userId: "w1", type: "message", payload: { chatId: "c1_w1", messageId: "m1" } });
  assert.equal(await r.go(), "saved");
  assert.equal(r.sent.length, 0);
  assert.equal(r.db.data.notifications.n1.title, "Ayesha Khan");
  // A contract step is still pushed (work category on).
  r = run(w, { ...base, userId: "w1", type: "work_started", payload: { contractId: "k1" } });
  assert.equal(await r.go(), "pushed");
  w.users.w1.notificationPrefs = { push: false };
  r = run(w, { ...base, userId: "w1", type: "work_started", payload: { contractId: "k1" } });
  assert.equal(await r.go(), "saved");
});

test("idempotent: a retried event does nothing the second time", async () => {
  const { sent, go } = run(world(), { ...base, userId: "w1", type: "message", payload: { chatId: "c1_w1", messageId: "m1" } });
  assert.equal(await go(), "pushed");
  assert.equal(await go(), "skipped");
  assert.equal(sent.length, 1);
});

test("dead tokens reported by FCM are removed (map entry and old single field)", async () => {
  const { db, go } = run(world(), { ...base, userId: "w1", type: "message", payload: { chatId: "c1_w1", messageId: "m1" } },
    { send: async () => [T1, T2] });
  assert.equal(await go(), "pushed");
  assert.deepEqual(db.data.fcmTokens.w1.tokens, {});
  assert.equal(db.data.users.w1.fcmToken, undefined);
});

test("no devices: saved for the in-app list, nothing sent", async () => {
  const w = world();
  delete w.fcmTokens.c1;
  const { sent, go } = run(w, { ...base, userId: "c1", type: "work_submitted", payload: { contractId: "k1" } });
  assert.equal(await go(), "saved");
  assert.equal(sent.length, 0);
});

test("push settings helper", () => {
  assert.equal(notify.pushAllowed({}, "message"), true);
  assert.equal(notify.pushAllowed({ notificationPrefs: { work: false } }, "message"), true);
  assert.equal(notify.pushAllowed({ notificationPrefs: { work: false } }, "work_started"), false);
  assert.equal(notify.categoryOf("message"), "messages");
});

// ── Profile copies ────────────────────────────────────────────────────────

test("profile copies: only name/photo changes count", () => {
  assert.equal(copies.profileChange("u", { displayName: "A", photoUrl: "p", city: "x" }, { displayName: "A", photoUrl: "p", city: "y" }), null);
  const c = copies.profileChange("u", { displayName: "A", photoUrl: "p" }, { displayName: "A", photoUrl: "q" });
  assert.deepEqual(c, { uid: "u", name: "A", photo: "q", nameChanged: false, photoChanged: true });
  assert.equal(copies.profileChange("u", { photoUrl: "p" }, { photoUrl: null }).photo, null, "photo removed");
});

test("profile copies: open jobs, live proposals, active contracts and chats get the new photo; finished ones keep history", async () => {
  const db = fakeDb({
    jobs: {
      j1: { clientId: "c1", status: "open", clientPhotoUrl: "old" },
      j2: { clientId: "c1", status: "completed", clientPhotoUrl: "old" },
    },
    proposals: {
      a: { workerId: "c1", status: "pending", workerPhotoUrl: "old" }, // (c1 as a worker in this test)
      b: { workerId: "c1", status: "rejected", workerPhotoUrl: "old" },
    },
    contracts: {
      k1: { clientId: "c1", workerId: "w1", status: "active", clientPhotoUrl: "old", workerPhotoUrl: "w" },
      k2: { clientId: "c1", workerId: "w1", status: "completed", clientPhotoUrl: "old" },
    },
    chats: { c1_w1: { participantIds: ["c1", "w1"], participantPhotos: { c1: "old", w1: "w" }, participantNames: { c1: "Ayesha", w1: "Bilal" } } },
  });
  const n = await copies.refreshCopies(db, { uid: "c1", name: "Ayesha K", photo: "new", nameChanged: true, photoChanged: true });
  assert.equal(n, 4);
  assert.equal(db.data.jobs.j1.clientPhotoUrl, "new");
  assert.equal(db.data.jobs.j1.clientName, "Ayesha K");
  assert.equal(db.data.jobs.j2.clientPhotoUrl, "old");
  assert.equal(db.data.proposals.a.workerPhotoUrl, "new");
  assert.equal(db.data.proposals.b.workerPhotoUrl, "old");
  assert.equal(db.data.contracts.k1.clientPhotoUrl, "new");
  assert.equal(db.data.contracts.k1.workerPhotoUrl, "w", "the other party untouched");
  assert.equal(db.data.contracts.k2.clientPhotoUrl, "old");
  assert.equal(db.data.chats.c1_w1.participantPhotos.c1, "new");
  assert.equal(db.data.chats.c1_w1.participantPhotos.w1, "w");
  assert.equal(db.data.chats.c1_w1.participantNames.c1, "Ayesha K");
});

test("server-written notifications (identity verification) are pushed as written, not rewritten or deleted", async () => {
  const { db, sent, go } = run(world(), { userId: "w1", title: "Identity verified", body: "Your identity was confirmed.", type: "identity_verified",
    payload: { requestId: "session0001" }, isRead: false, source: "server", verifiedAt: new Date(1) });
  assert.equal(await go(), "pushed");
  assert.equal(db.data.notifications.n1.title, "Identity verified");
  assert.equal(sent[0].m.data.requestId, "session0001");
  assert.equal(sent[0].m.data.type, "identity_verified");
  assert.equal(await go(), "skipped", "pushed once");
});
