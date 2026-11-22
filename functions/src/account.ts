// Account deletion (Phase G6). Google Play requires that people can delete
// their account from inside the app.
//
// Runs on the server because it touches other people's records (their
// jobs, proposals, contracts, chats and reviews keep the history but must no
// longer show the deleted person's name or photo) and Storage, and because
// deleting the sign-in itself needs the Admin SDK.
//
// Rules:
//   * only the signed-in person, for themselves, and only within 10 minutes
//     of signing in (an unattended phone can't delete the account);
//   * refused while a contract is active (finish or cancel it first), so
//     the other party is never left with work in progress;
//   * history stays for the other party, anonymised as "Deleted user";
//   * the person's own data is deleted: account and private documents,
//     public profile, saved jobs, notifications, push tokens, live location,
//     usage counters, identity verification records, photos in Storage, and
//     finally the sign-in.

import * as admin from "firebase-admin";
import { logger } from "firebase-functions/v2";
import { HttpsError, onCall } from "firebase-functions/v2/https";

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type Db = any;
type Data = Record<string, unknown>;

export const DELETED_NAME = "Deleted user";
export const RECENT_LOGIN_SECONDS = 10 * 60;

export interface AccountDeps {
  db: Db;
  deleteStorageFolder: (prefix: string) => Promise<void>;
  deleteAuthUser: (uid: string) => Promise<void>;
  nowSeconds: () => number;
}

const str = (v: unknown) => (typeof v === "string" ? v : "");

/** Deletes [uid]'s account. [authTime] is the sign-in time from the ID token (seconds). */
export async function deleteAccountFor(deps: AccountDeps, uid: string, authTime: unknown): Promise<{ deleted: true; anonymised: number }> {
  if (typeof authTime !== "number" || deps.nowSeconds() - authTime > RECENT_LOGIN_SECONDS) {
    throw new HttpsError("failed-precondition", "recent-login-required");
  }
  const db = deps.db;

  // ── Refuse while work is in progress ──
  const active: Data[] = [];
  for (const side of ["clientId", "workerId"]) {
    const cs = await db.collection("contracts").where(side, "==", uid).get();
    for (const d of cs.docs) if (str(d.data().status) === "active") active.push(d.data());
  }
  if (active.length) throw new HttpsError("failed-precondition", "active-contracts");

  // ── Anonymise what other people keep ──
  const updates: Array<{ ref: unknown; data: Data }> = [];
  const anon = (doc: { ref: unknown; data: () => Data }, nameKey: string, photoKey: string, extra: Data = {}) => {
    const d = doc.data();
    const data: Data = { ...extra };
    if (nameKey in d) data[nameKey] = DELETED_NAME;
    if (photoKey in d) data[photoKey] = null;
    if (Object.keys(data).length) updates.push({ ref: doc.ref, data });
  };

  for (const d of (await db.collection("jobs").where("clientId", "==", uid).get()).docs) {
    const open = ["open", "assigned"].includes(str(d.data().status));
    anon(d, "clientName", "clientPhotoUrl", open ? { status: "cancelled", closedReason: "account_deleted" } : {});
  }
  for (const d of (await db.collection("proposals").where("workerId", "==", uid).get()).docs) {
    const pending = ["pending", "shortlisted"].includes(str(d.data().status));
    anon(d, "workerName", "workerPhotoUrl", pending ? { status: "withdrawn" } : {});
  }
  for (const [side, nameKey, photoKey] of [["clientId", "clientName", "clientPhotoUrl"], ["workerId", "workerName", "workerPhotoUrl"]]) {
    for (const d of (await db.collection("contracts").where(side, "==", uid).get()).docs) anon(d, nameKey, photoKey);
  }
  for (const d of (await db.collection("reviews").where("reviewerId", "==", uid).get()).docs) anon(d, "reviewerName", "reviewerPhotoUrl");
  for (const d of (await db.collection("reviews").where("revieweeId", "==", uid).get()).docs) anon(d, "revieweeName", "revieweePhotoUrl");
  for (const d of (await db.collection("chats").where("participantIds", "array-contains", uid).get()).docs) {
    updates.push({ ref: d.ref, data: { [`participantNames.${uid}`]: DELETED_NAME, [`participantPhotos.${uid}`]: null } });
  }

  // ── Delete the person's own data ──
  const deletes: unknown[] = [];
  for (const d of (await db.collection("notifications").where("userId", "==", uid).get()).docs) deletes.push(d.ref);
  const userRef = db.collection("users").doc(uid);
  for (const sub of ["private", "verificationDocs", "savedJobs"]) {
    for (const d of (await userRef.collection(sub).get()).docs) deletes.push(d.ref);
  }
  // Identity verification records (consent says they go with the account):
  // sessions and their audit events, the CNIC index entry, provider refs.
  for (const d of (await db.collection("identityVerifications").where("userId", "==", uid).get()).docs) {
    for (const e of (await d.ref.collection("events").get()).docs) deletes.push(e.ref);
    deletes.push(d.ref);
  }
  for (const d of (await db.collection("identityCnicIndex").where("userId", "==", uid).get()).docs) deletes.push(d.ref);
  for (const d of (await db.collection("identityTransactions").where("userId", "==", uid).get()).docs) deletes.push(d.ref);
  for (const path of [`publicProfiles/${uid}`, `fcmTokens/${uid}`, `mapsUsage/${uid}`, `liveLocations/${uid}`, `ratings/${uid}`]) {
    deletes.push(db.doc(path));
  }
  deletes.push(userRef); // last Firestore write: the account itself

  for (let i = 0; i < updates.length; i += 400) {
    const b = db.batch();
    for (const u of updates.slice(i, i + 400)) b.update(u.ref, u.data);
    await b.commit();
  }
  for (let i = 0; i < deletes.length; i += 400) {
    const b = db.batch();
    for (const r of deletes.slice(i, i + 400)) b.delete(r);
    await b.commit();
  }

  await deps.deleteStorageFolder(`users/${uid}/`);
  await deps.deleteAuthUser(uid);
  return { deleted: true, anonymised: updates.length };
}

export const deleteAccount = onCall({ maxInstances: 5, timeoutSeconds: 120, memory: "256MiB" }, async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Please sign in.");
  try {
    const result = await deleteAccountFor(
      {
        db: admin.firestore(),
        deleteStorageFolder: async (prefix) => {
          try {
            await admin.storage().bucket().deleteFiles({ prefix });
          } catch (e) {
            // No bucket yet (Storage not enabled) or nothing stored: fine.
            logger.warn(`[account] storage cleanup skipped (${(e as { code?: unknown })?.code ?? "error"})`);
          }
        },
        deleteAuthUser: async (id) => {
          await admin.auth().deleteUser(id);
        },
        nowSeconds: () => Math.floor(Date.now() / 1000),
      },
      uid,
      request.auth?.token?.auth_time,
    );
    logger.info(`[account] ${uid}: deleted (${result.anonymised} shared record(s) anonymised)`);
    return result;
  } catch (e) {
    if (e instanceof HttpsError) throw e;
    logger.error(`[account] ${uid}: failed (${(e as { code?: unknown })?.code ?? "error"})`);
    throw new HttpsError("internal", "The account could not be deleted. Nothing was removed from your sign-in; please try again.");
  }
});
