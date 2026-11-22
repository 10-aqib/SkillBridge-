// Notifications and push (Phase G5).
//
// The app writes a notification in the same batch/transaction as the action
// it is about (message sent, proposal, contract step, review), and the
// Firestore rules already require a real link between sender and recipient
// (same chat, same contract, or a job between its client and an applicant
// or the hired worker). What the rules cannot check is the wording, and the
// app cannot send a push. This trigger is the trusted part:
//
//   1. re-checks the link against the current records;
//   2. rewrites the title and body from server templates and the real
//      records (sender name, job title, message text), so a modified app
//      can't put its own words in someone else's notification centre;
//   3. deletes notifications that don't check out;
//   4. sends the push to every device the recipient registered
//      (fcmTokens/{uid}.tokens), respecting their notification settings,
//      and removes tokens Firebase reports as dead.
//
// Idempotent: a retried event sees `pushedAt` and does nothing.
// Logs carry ids and error codes only, never message text or tokens.

import * as admin from "firebase-admin";
import { logger } from "firebase-functions/v2";
import { onDocumentCreated } from "firebase-functions/v2/firestore";

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type Db = any;
type Data = Record<string, unknown>;

export interface PushMessage {
  title: string;
  body: string;
  data: Record<string, string>;
  /** Groups a conversation's pushes on Android. */
  tag?: string;
}

/** Sends [message] to [tokens]; returns the tokens Firebase says are dead. */
export type PushSender = (tokens: string[], message: PushMessage) => Promise<string[]>;

export interface NotifyDeps {
  db: Db;
  send: PushSender;
  now: () => Date;
}

const str = (v: unknown): string => (typeof v === "string" ? v : "");
const clip = (s: string, n: number) => (s.length > n ? `${s.slice(0, n - 1)}…` : s);
const quoted = (title: string) => (title ? `"${clip(title, 60)}"` : "your job");

async function get(db: Db, path: string): Promise<Data | null> {
  const snap = await db.doc(path).get();
  return snap.exists ? (snap.data() as Data) : null;
}

const nameOf = (u: Data | null, fallback: string) => clip(str(u?.displayName).trim(), 60) || fallback;

/** Kinds a person can switch off for push (in-app always shows). */
export type PushCategory = "messages" | "work";
export const categoryOf = (type: string): PushCategory => (type === "message" ? "messages" : "work");
// Identity verification results count as "work" (account) notifications.

interface Built {
  title: string;
  body: string;
  type: string;
  data: Record<string, string>;
  tag?: string;
}

const CONTRACT_TITLES: Record<string, string> = {
  booking: "New booking request",
  booking_accepted: "Booking accepted",
  booking_declined: "Booking declined",
  request_declined: "Request declined",
  contract_created: "Contract ready",
  contract_cancelled: "Contract cancelled",
  work_started: "Work started",
  work_submitted: "Work submitted",
  revision_requested: "Changes requested",
  completion_confirmed: "Completion confirmed",
  address_shared: "Address shared",
  progress_update: "Progress update",
  review_received: "New review",
};

const CONTRACT_BODIES: Record<string, (who: string, job: string) => string> = {
  booking: (w, j) => `${w} sent you a booking request for ${j}.`,
  booking_accepted: (w, j) => `${w} accepted the booking for ${j}.`,
  booking_declined: (w, j) => `${w} declined the booking for ${j}.`,
  request_declined: (w, j) => `${w} declined ${j}.`,
  contract_created: (w, j) => `${w} and you have a contract for ${j}.`,
  contract_cancelled: (w, j) => `${w} cancelled the contract for ${j}.`,
  work_started: (w, j) => `${w} started work on ${j}.`,
  work_submitted: (w, j) => `${w} submitted the work for ${j}. Please review it.`,
  revision_requested: (w, j) => `${w} asked for changes to ${j}.`,
  completion_confirmed: (w, j) => `${w} confirmed ${j} is complete.`,
  address_shared: (w, j) => `${w} shared the address for ${j}.`,
  progress_update: (w, j) => `${w} posted an update on ${j}.`,
  review_received: (w, j) => `${w} reviewed ${j}.`,
};

/**
 * Checks a notification against the current records and builds its trusted
 * text, or returns null when it doesn't check out (it is then deleted).
 */
export async function buildNotification(db: Db, n: Data): Promise<Built | null> {
  const userId = str(n.userId);
  if (!userId) return null;
  const recipient = await get(db, `users/${userId}`);
  if (!recipient || recipient.isActive === false) return null;

  const p = (n.payload && typeof n.payload === "object" ? n.payload : {}) as Data;
  const chatId = str(p.chatId), messageId = str(p.messageId), contractId = str(p.contractId);
  const jobId = str(p.jobId), proposalId = str(p.proposalId);
  const type = str(n.type);
  const data: Record<string, string> = {};
  for (const [k, v] of Object.entries({ chatId, messageId, contractId, jobId, proposalId })) if (v) data[k] = v;

  // ── A message in a conversation ──
  if (chatId) {
    const chat = await get(db, `chats/${chatId}`);
    const ids = Array.isArray(chat?.participantIds) ? (chat!.participantIds as unknown[]).map(str) : [];
    if (!ids.includes(userId)) return null;
    const senderId = ids.find((id) => id !== userId) ?? "";
    if (!senderId) return null;
    const sender = await get(db, `users/${senderId}`);
    let body = "Sent you a message.";
    if (messageId) {
      const m = await get(db, `chats/${chatId}/messages/${messageId}`);
      if (!m || str(m.senderId) !== senderId) return null;
      const text = str(m.content).replace(/\s+/g, " ").trim();
      body = str(m.type) === "image" || (!text && Array.isArray(m.attachments)) ? "📷 Photo" : clip(text, 140) || body;
    }
    return { title: nameOf(sender, "New message"), body, type: "message", data: { ...data, type: "message" }, tag: `chat_${chatId}` };
  }

  // ── A contract step ──
  if (contractId) {
    const c = await get(db, `contracts/${contractId}`);
    if (!c) return null;
    const clientId = str(c.clientId), workerId = str(c.workerId);
    if (userId !== clientId && userId !== workerId) return null;
    const senderId = userId === clientId ? workerId : clientId;
    const sender = await get(db, `users/${senderId}`);
    const t = CONTRACT_TITLES[type] ? type : "contract_update";
    const who = nameOf(sender, userId === clientId ? "The worker" : "The client");
    const job = quoted(str(c.jobTitle));
    return {
      title: CONTRACT_TITLES[t] ?? "Contract update",
      body: (CONTRACT_BODIES[t] ?? ((w: string, j: string) => `${w} updated the contract for ${j}.`))(who, job),
      type: t,
      data: { ...data, type: t },
    };
  }

  // ── A job: proposal, direct request reply, job update ──
  if (jobId) {
    const job = await get(db, `jobs/${jobId}`);
    if (!job) return null;
    const clientId = str(job.clientId), chosen = str(job.selectedWorkerId);
    let senderId = "";
    if (proposalId) {
      const prop = await get(db, `proposals/${proposalId}`);
      if (!prop || str(prop.jobId) !== jobId) return null;
      const workerId = str(prop.workerId);
      if (userId === clientId) senderId = workerId;
      else if (userId === workerId) senderId = clientId;
      else return null;
    } else if (userId === clientId) {
      senderId = chosen; // may be '' (an applicant): then no name is shown
    } else if (userId === chosen) {
      senderId = clientId;
    } else {
      return null;
    }
    const sender = senderId ? await get(db, `users/${senderId}`) : null;
    const jobTitle = quoted(str(job.title));
    if (proposalId && userId === clientId) {
      return {
        title: "New proposal",
        body: `${nameOf(sender, "A worker")} sent a proposal for ${jobTitle}.`,
        type: "proposal",
        data: { ...data, type: "proposal" },
      };
    }
    if (CONTRACT_TITLES[type]) {
      return {
        title: CONTRACT_TITLES[type],
        body: CONTRACT_BODIES[type](nameOf(sender, "The other person"), jobTitle),
        type,
        data: { ...data, type },
      };
    }
    return { title: "Job update", body: `There's an update on ${jobTitle}.`, type: "job", data: { ...data, type: "job" } };
  }

  return null;
}

/** All push tokens registered for [uid] (per device, plus the old single field). */
export async function tokensFor(db: Db, uid: string, user: Data | null): Promise<string[]> {
  const doc = await get(db, `fcmTokens/${uid}`);
  const map = doc?.tokens && typeof doc.tokens === "object" ? Object.keys(doc.tokens as Data) : [];
  const legacy = str(user?.fcmToken);
  return [...new Set([...map, ...(legacy ? [legacy] : [])])].filter((t) => t.length > 20 && t.length < 4096).slice(0, 20);
}

/** Whether the recipient allows a push of this category. */
export function pushAllowed(user: Data | null, type: string): boolean {
  const prefs = (user?.notificationPrefs && typeof user.notificationPrefs === "object" ? user.notificationPrefs : {}) as Data;
  if (prefs.push === false) return false;
  return prefs[categoryOf(type)] !== false;
}

/** Handles one new notification document. Returns what happened (for tests and logs). */
export async function processNotification(deps: NotifyDeps, id: string): Promise<"skipped" | "deleted" | "saved" | "pushed"> {
  const ref = deps.db.collection("notifications").doc(id);
  const box: { built: Built | null; userId: string } = { built: null, userId: "" };
  const outcome: "skipped" | "deleted" | "saved" = await deps.db.runTransaction(async (tx: Db) => {
    const snap = await tx.get(ref);
    if (!snap.exists) return "skipped";
    const n = snap.data() as Data;
    if (n.pushedAt) return "skipped"; // a retried event
    if (n.source === "server") {
      // Written by a trusted function (e.g. identity verification): its text
      // is already the server's own; only push it.
      const p = (n.payload && typeof n.payload === "object" ? n.payload : {}) as Data;
      const data: Record<string, string> = { type: str(n.type) };
      for (const [k, v] of Object.entries(p)) if (typeof v === "string" && v) data[k] = v;
      box.built = { title: str(n.title), body: str(n.body), type: str(n.type), data };
      box.userId = str(n.userId);
      return box.built.title && box.userId ? "saved" : "skipped";
    }
    if (n.verifiedAt) return "skipped"; // a retried event
    const built = await buildNotification(deps.db, n);
    box.built = built;
    box.userId = str(n.userId);
    if (!built) {
      tx.delete(ref);
      return "deleted";
    }
    tx.update(ref, { title: built.title, body: built.body, type: built.type, verifiedAt: deps.now() });
    return "saved";
  });
  const b = box.built;
  if (outcome !== "saved" || !b) {
    if (outcome === "deleted") logger.warn(`[notify] ${id}: link not valid, removed`);
    return outcome;
  }
  const userId = box.userId;
  const user = await get(deps.db, `users/${userId}`);
  if (!pushAllowed(user, b.type)) return "saved";
  const tokens = await tokensFor(deps.db, userId, user);
  if (tokens.length === 0) return "saved";
  const dead = await deps.send(tokens, { title: b.title, body: b.body, data: { ...b.data, notificationId: id }, tag: b.tag });
  await ref.update({ pushedAt: deps.now() });
  if (dead.length > 0) {
    // FCM tokens never contain '.', so "tokens.<token>" is a safe field path.
    const removal: Data = {};
    for (const t of dead) if (!t.includes(".")) removal[`tokens.${t}`] = admin.firestore.FieldValue.delete();
    if (Object.keys(removal).length) {
      await deps.db.collection("fcmTokens").doc(userId).update(removal).catch(() => undefined);
    }
    if (dead.includes(str(user?.fcmToken))) {
      await deps.db.collection("users").doc(userId).update({ fcmToken: admin.firestore.FieldValue.delete() }).catch(() => undefined);
    }
    logger.info(`[notify] ${id}: removed ${dead.length} dead token(s)`);
  }
  return "pushed";
}

const DEAD_CODES = new Set([
  "messaging/registration-token-not-registered",
  "messaging/invalid-registration-token",
  "messaging/invalid-argument",
]);

/** FCM through the Admin SDK. In the emulator nothing is sent. */
export const fcmSender: PushSender = async (tokens, m) => {
  if (process.env.FUNCTIONS_EMULATOR === "true") {
    logger.info(`[notify] emulator: push to ${tokens.length} device(s) not sent`);
    return [];
  }
  const res = await admin.messaging().sendEachForMulticast({
    tokens,
    notification: { title: m.title, body: m.body },
    data: m.data,
    android: {
      priority: "high",
      notification: { channelId: "high_importance_channel", tag: m.tag, clickAction: "FLUTTER_NOTIFICATION_CLICK" },
    },
    apns: { payload: { aps: { sound: "default", threadId: m.tag } } },
  });
  const dead: string[] = [];
  res.responses.forEach((r, i) => {
    if (!r.success) {
      const code = r.error?.code ?? "unknown";
      if (DEAD_CODES.has(code)) dead.push(tokens[i]);
      else logger.warn(`[notify] push failed: ${code}`);
    }
  });
  return dead;
};

export const onNotificationCreatedV2 = onDocumentCreated(
  { document: "notifications/{notificationId}", retry: false, maxInstances: 10, memory: "256MiB" },
  async (event) => {
    try {
      await processNotification({ db: admin.firestore(), send: fcmSender, now: () => new Date() }, event.params.notificationId);
    } catch (e) {
      logger.error(`[notify] ${event.params.notificationId}: failed (${(e as { code?: unknown })?.code ?? "error"})`);
    }
  },
);
