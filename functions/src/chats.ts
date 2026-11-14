import * as admin from "firebase-admin";
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";

/**
 * Conversations and their server-kept state (Phase 4B).
 *
 * - `openChatCall` is the only way to create a conversation. It checks a real
 *   relationship on the server and is idempotent (an existing conversation,
 *   including an older one with a random id, is returned instead).
 * - `onChatMessageCreated` keeps each chat's preview, ordering timestamp and
 *   the recipient's unread count, and notifies the recipient. Members can no
 *   longer write any of these (see firestore.rules).
 */

type Data = Record<string, unknown>;
type Db = admin.firestore.Firestore;

function fail(code: "failed-precondition" | "permission-denied" | "not-found" | "invalid-argument" | "unauthenticated", message: string): never {
  throw new HttpsError(code, message);
}

function displayName(u: Data | undefined): string {
  const n = typeof u?.displayName === "string" ? u.displayName.trim() : "";
  return n.length > 0 ? n : "SkillBridge user";
}

export type OpenChatResult = { chatId: string; created: boolean };

/**
 * Opens (or finds) the conversation between the caller and `otherUserId`.
 *
 * Job conversations (`{jobId}_{workerId}`) need a link to that job: the
 * client and either a worker writing about a public open job, a worker who
 * sent a proposal, or the selected/hired worker. Conversations outside a job
 * (`direct_{clientId}_{workerId}`) may only be started by an active client
 * with an active worker (approved Phase 4B decision).
 */
export async function openChat(db: Db, uid: string, otherUserId: string, jobId?: string): Promise<OpenChatResult> {
  if (typeof otherUserId !== "string" || otherUserId.length === 0) fail("invalid-argument", "otherUserId is required.");
  if (otherUserId === uid) fail("invalid-argument", "You can't message yourself.");
  const [meSnap, otherSnap] = [await db.collection("users").doc(uid).get(), await db.collection("users").doc(otherUserId).get()];
  const me = meSnap.data() as Data | undefined;
  const other = otherSnap.data() as Data | undefined;
  if (!me) fail("permission-denied", "No profile for this account.");
  if (me.isActive === false) fail("permission-denied", "This account is suspended.");
  if (!other || other.isActive === false) fail("failed-precondition", "This account is not available.");

  let chatId: string;
  let job: Data | undefined;
  if (typeof jobId === "string" && jobId.length > 0) {
    job = (await db.collection("jobs").doc(jobId).get()).data() as Data | undefined;
    if (!job) fail("not-found", "Job not found.");
    const clientId = job.clientId as string;
    if (uid !== clientId && otherUserId !== clientId) fail("permission-denied", "One of you must be the job's client.");
    const workerId = uid === clientId ? otherUserId : uid;
    const publicOpen = job.status === "open" && (job.selectedWorkerId === null || job.selectedWorkerId === undefined);
    const workerStarts = workerId === uid && me.role === "worker" && publicOpen;
    const applied = (await db.collection("proposals").doc(`${jobId}_${workerId}`).get()).exists;
    const selected = job.selectedWorkerId === workerId;
    if (!workerStarts && !applied && !selected) fail("permission-denied", "There is no link between you and this job.");
    chatId = `${jobId}_${workerId}`;
  } else {
    if (me.role !== "client" || other.role !== "worker") {
      fail("permission-denied", "Only a client can start a conversation with a worker outside a job.");
    }
    chatId = `direct_${uid}_${otherUserId}`;
  }

  const ref = db.collection("chats").doc(chatId);
  if ((await ref.get()).exists) return { chatId, created: false };

  // Keep using an older conversation between the same two people, if any.
  const legacy = await db.collection("chats").where("participantIds", "array-contains", uid).get();
  for (const d of legacy.docs) {
    const ids = (d.get("participantIds") as string[] | undefined) ?? [];
    const related = d.get("relatedJobId") ?? null;
    if (ids.includes(otherUserId) && ids.length === 2 && related === (jobId ?? null)) return { chatId: d.id, created: false };
  }

  const now = FieldValue.serverTimestamp();
  const created = await db.runTransaction(async (tx) => {
    if ((await tx.get(ref)).exists) return false;
    tx.set(ref, {
      participantIds: [uid, otherUserId],
      participantNames: { [uid]: displayName(me), [otherUserId]: displayName(other) },
      participantPhotos: { [uid]: me.photoUrl ?? null, [otherUserId]: other.photoUrl ?? null },
      lastMessage: "",
      lastMessageSenderId: "",
      lastMessageType: "none",
      lastMessageAt: now,
      unreadCount: { [uid]: 0, [otherUserId]: 0 },
      lastReadAt: {},
      createdAt: now,
      createdBy: uid,
      ...(job ? { relatedJobId: jobId, relatedJobTitle: job.title ?? "" } : {}),
    });
    return true;
  });
  return { chatId, created };
}

export const openChatCall = onCall(async (request) => {
  if (!request.auth?.uid) fail("unauthenticated", "Please sign in.");
  const data = (request.data ?? {}) as { otherUserId?: string; jobId?: string };
  return openChat(admin.firestore(), request.auth.uid, data.otherUserId as string, data.jobId);
});

// ── New messages ──────────────────────────────────────────────────────────

/** The list preview for a message: its text, or "Photo" for a photo message. */
export function previewOf(m: Data): string {
  const text = typeof m.content === "string" ? m.content.trim().replace(/\s+/g, " ") : "";
  if (m.type === "image") return text.length > 0 ? `Photo: ${text}`.slice(0, 120) : "Photo";
  return text.slice(0, 120);
}

function millis(v: unknown): number {
  if (v && typeof (v as { toMillis?: unknown }).toMillis === "function") return (v as Timestamp).toMillis();
  return 0;
}

/**
 * Applies one new message to its chat. Idempotent: the unread count is
 * recounted (not incremented), the preview only moves forward in time, and
 * the notification has a fixed id per message.
 */
export async function applyNewMessage(db: Db, chatId: string, messageId: string, m: Data): Promise<"applied" | "skipped"> {
  const chatRef = db.collection("chats").doc(chatId);
  const chat = (await chatRef.get()).data() as Data | undefined;
  if (!chat) return "skipped";
  const ids = (chat.participantIds as string[] | undefined) ?? [];
  const sender = m.senderId as string;
  if (!ids.includes(sender)) return "skipped";
  const recipient = ids.find((id) => id !== sender);
  if (!recipient) return "skipped";

  const lastRead = ((chat.lastReadAt as Data | undefined) ?? {})[recipient];
  let q = db.collection("chats").doc(chatId).collection("messages").where("senderId", "==", sender);
  if (lastRead) q = q.where("createdAt", ">", lastRead);
  const unread = (await q.count().get()).data().count;

  await db.runTransaction(async (tx) => {
    const fresh = (await tx.get(chatRef)).data() as Data | undefined;
    if (!fresh) return;
    const update: Record<string, admin.firestore.FieldValue | string | number | Timestamp> = { [`unreadCount.${recipient}`]: unread };
    if (millis(m.createdAt) >= millis(fresh.lastMessageAt) || !fresh.lastMessageSenderId) {
      update.lastMessage = previewOf(m);
      update.lastMessageSenderId = sender;
      update.lastMessageType = m.type === "image" ? "image" : "text";
      update.lastMessageAt = (m.createdAt as Timestamp | undefined) ?? FieldValue.serverTimestamp();
      update.lastMessageId = messageId;
    }
    tx.update(chatRef, update);
  });

  const recipientUser = (await db.collection("users").doc(recipient).get()).data() as Data | undefined;
  if (recipientUser && recipientUser.isActive !== false) {
    const names = (chat.participantNames as Data | undefined) ?? {};
    const from = typeof names[sender] === "string" ? (names[sender] as string) : "Someone";
    await db.collection("notifications").doc(`msg_${messageId}`).set({
      userId: recipient,
      title: `New message from ${from}`,
      body: previewOf(m),
      type: "message",
      payload: { chatId, messageId },
      referenceId: chatId,
      isRead: false,
      createdAt: FieldValue.serverTimestamp(),
    });
  }
  return "applied";
}

export const onChatMessageCreated = onDocumentCreated("chats/{chatId}/messages/{messageId}", async (event) => {
  const m = event.data?.data() as Data | undefined;
  if (!m) return;
  await applyNewMessage(admin.firestore(), event.params.chatId, event.params.messageId, m);
});
