// Conversations (functions/src/chats.ts), against the in-memory fake in
// fake_db.js. Not Firebase: the matching rules run in rules-tests/.
const test = require("node:test");
const assert = require("node:assert/strict");
const { openChat, applyNewMessage, previewOf } = require("../.test-build/chats.js");
const { fakeDb, ts, rejects: rejectsWith } = require("./fake_db");

const rejects = (p, code) => rejectsWith(assert, p, code);

const base = () => ({
  users: {
    c1: { role: "client", displayName: "Ayesha Khan", isActive: true, photoUrl: null },
    c2: { role: "client", displayName: "Usman", isActive: true },
    w1: { role: "worker", displayName: "Bilal Ahmed", isActive: true },
    w2: { role: "worker", displayName: "Kamran Ali", isActive: true },
    w3: { role: "worker", displayName: "Suspended Worker", isActive: false },
  },
  jobs: {
    j1: { clientId: "c1", title: "Fix sockets", status: "open", selectedWorkerId: null },
    j2: { clientId: "c1", title: "Paint a room", status: "assigned", selectedWorkerId: "w2" },
  },
  proposals: { j1_w1: { jobId: "j1", workerId: "w1", clientId: "c1", status: "pending" } },
});

test("job chats: the client and an applicant share one conversation with a fixed id", async () => {
  const db = fakeDb(base());
  const r = await openChat(db, "c1", "w1", "j1");
  assert.deepEqual(r, { chatId: "j1_w1", created: true });
  const chat = db.data.chats.j1_w1;
  assert.deepEqual(chat.participantIds, ["c1", "w1"]);
  assert.equal(chat.relatedJobId, "j1");
  assert.deepEqual(chat.unreadCount, { c1: 0, w1: 0 });
  assert.equal(chat.lastMessageType, "none");
  assert.deepEqual(chat.createdAt, { __ts: true });
  const writes = db.writes;
  assert.deepEqual(await openChat(db, "w1", "c1", "j1"), { chatId: "j1_w1", created: false }, "the other side opens the same chat");
  assert.equal(db.writes, writes, "opening again writes nothing");
  assert.equal(Object.keys(db.data.chats).length, 1);
});

test("job chats need a real link to the job", async () => {
  // A worker may ask about a public open job before applying.
  assert.equal((await openChat(fakeDb(base()), "w2", "c1", "j1")).chatId, "j1_w2");
  // The selected worker of an assigned job may message its client.
  assert.equal((await openChat(fakeDb(base()), "w2", "c1", "j2")).chatId, "j2_w2");
  // Others can't.
  await rejects(openChat(fakeDb(base()), "w1", "c1", "j2"), "permission-denied"); // not selected, no proposal, job not public
  await rejects(openChat(fakeDb(base()), "c1", "w2", "j2_x"), "not-found");
  await rejects(openChat(fakeDb(base()), "w1", "w2", "j1"), "permission-denied"); // neither is the client
  await rejects(openChat(fakeDb(base()), "c2", "w1", "j1"), "permission-denied"); // not the job's client
  await rejects(openChat(fakeDb(base()), "c1", "w2", "j2_missing"), "not-found");
});

test("direct chats: only a client can start one with a worker", async () => {
  const db = fakeDb(base());
  assert.deepEqual(await openChat(db, "c1", "w1"), { chatId: "direct_c1_w1", created: true });
  assert.equal(db.data.chats.direct_c1_w1.relatedJobId, undefined);
  await rejects(openChat(fakeDb(base()), "w1", "c1"), "permission-denied");
  await rejects(openChat(fakeDb(base()), "c1", "c2"), "permission-denied");
  await rejects(openChat(fakeDb(base()), "w1", "w2"), "permission-denied");
});

test("suspended, missing and self conversations are refused", async () => {
  await rejects(openChat(fakeDb(base()), "c1", "w3"), "failed-precondition");
  await rejects(openChat(fakeDb(base()), "c1", "nobody"), "failed-precondition");
  await rejects(openChat(fakeDb(base()), "c1", "c1"), "invalid-argument");
  await rejects(openChat(fakeDb(base()), "c1", ""), "invalid-argument");
  const s = base();
  s.users.c1.isActive = false;
  await rejects(openChat(fakeDb(s), "c1", "w1"), "permission-denied");
});

test("an older conversation between the same two people is reused, not duplicated", async () => {
  const s = base();
  s.chats = { legacy123: { participantIds: ["c1", "w1"], relatedJobId: null }, other: { participantIds: ["c1", "w1"], relatedJobId: "jX" } };
  const db = fakeDb(s);
  assert.deepEqual(await openChat(db, "c1", "w1"), { chatId: "legacy123", created: false });
  assert.equal(Object.keys(db.data.chats).length, 2);
});

function withMessages() {
  const s = base();
  s.chats = {
    k: { participantIds: ["c1", "w1"], participantNames: { c1: "Ayesha Khan", w1: "Bilal Ahmed" },
      lastMessage: "", lastMessageSenderId: "", lastMessageAt: ts(0), unreadCount: { c1: 0, w1: 0 }, lastReadAt: { w1: ts(1000) } },
  };
  s["chats/k/messages"] = {
    m1: { senderId: "c1", content: "Read already", type: "text", createdAt: ts(500) },
    m2: { senderId: "c1", content: "Are you free tomorrow?", type: "text", createdAt: ts(1500) },
    m3: { senderId: "c1", content: "", type: "image", createdAt: ts(2000) },
    m4: { senderId: "w1", content: "Yes", type: "text", createdAt: ts(900) },
  };
  return fakeDb(s);
}

test("a new message sets the preview, recounts the recipient's unread count and notifies once", async () => {
  const db = withMessages();
  const m3 = db.data["chats/k/messages"].m3;
  assert.equal(await applyNewMessage(db, "k", "m3", m3), "applied");
  const chat = db.data.chats.k;
  assert.equal(chat.unreadCount.w1, 2, "messages after the recipient last read");
  assert.equal(chat.unreadCount.c1, 0, "the sender's count is untouched");
  assert.equal(chat.lastMessage, "Photo");
  assert.equal(chat.lastMessageType, "image");
  assert.equal(chat.lastMessageSenderId, "c1");
  assert.equal(chat.lastMessageId, "m3");
  const n = db.data.notifications.msg_m3;
  assert.equal(n.userId, "w1");
  assert.equal(n.type, "message");
  assert.deepEqual(n.payload, { chatId: "k", messageId: "m3" });
  assert.equal(n.title, "New message from Ayesha Khan");

  // Duplicate trigger delivery: same result, still one notification.
  await applyNewMessage(db, "k", "m3", m3);
  assert.equal(db.data.chats.k.unreadCount.w1, 2);
  assert.equal(Object.keys(db.data.notifications).length, 1);
});

test("an older message delivered late never replaces a newer preview", async () => {
  const db = withMessages();
  const msgs = db.data["chats/k/messages"];
  await applyNewMessage(db, "k", "m3", msgs.m3);
  await applyNewMessage(db, "k", "m2", msgs.m2);
  assert.equal(db.data.chats.k.lastMessageId, "m3");
  assert.equal(db.data.chats.k.unreadCount.w1, 2);
});

test("a message from a non-member is ignored; a suspended recipient gets no notification", async () => {
  const db = withMessages();
  const writes = db.writes;
  assert.equal(await applyNewMessage(db, "k", "x", { senderId: "c2", content: "spam", type: "text", createdAt: ts(3000) }), "skipped");
  assert.equal(db.writes, writes);
  assert.equal(await applyNewMessage(db, "missing", "x", { senderId: "c1", content: "hi", type: "text" }), "skipped");

  const db2 = withMessages();
  db2.data.users.w1.isActive = false;
  await applyNewMessage(db2, "k", "m2", db2.data["chats/k/messages"].m2);
  assert.equal(db2.data.notifications, undefined);
});

test("with no read marker every message from the sender counts as unread", async () => {
  const db = withMessages();
  db.data.chats.k.lastReadAt = {};
  await applyNewMessage(db, "k", "m3", db.data["chats/k/messages"].m3);
  assert.equal(db.data.chats.k.unreadCount.w1, 3);
});

test("previews are short, single-line, and name photos", () => {
  assert.equal(previewOf({ type: "text", content: "  Hello\n there  " }), "Hello there");
  assert.equal(previewOf({ type: "image", content: "" }), "Photo");
  assert.equal(previewOf({ type: "image", content: "The meter" }), "Photo: The meter");
  assert.equal(previewOf({ type: "text", content: "x".repeat(500) }).length, 120);
});
