// Keeps copies of a person's name and photo fresh (Phase G5).
//
// Jobs, proposals, contracts and chats store the client's / worker's name
// and photo link so lists don't need an extra read per row. When someone
// changes their profile photo or name, this trigger updates those copies on
// records that are still in use, so cards and conversations show the new
// photo without anyone signing out. Finished records keep their history,
// and chat messages keep the name they were sent with.
//
// Server-side (Admin SDK) because the copies live in other people's records,
// which the person's own app may not write.

import { logger } from "firebase-functions/v2";
import { onDocumentUpdated } from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type Db = any;
type Data = Record<string, unknown>;

const OPEN_JOB = new Set(["open", "assigned", "in_progress"]);
const LIVE_PROPOSAL = new Set(["pending", "accepted", "shortlisted"]);
const LIVE_CONTRACT = new Set(["active", "pending"]);

const str = (v: unknown) => (typeof v === "string" ? v : "");

export interface ProfileChange {
  uid: string;
  name: string | null;
  photo: string | null;
  nameChanged: boolean;
  photoChanged: boolean;
}

/** What changed between two snapshots of users/{uid}, or null if nothing relevant. */
export function profileChange(uid: string, before: Data | undefined, after: Data | undefined): ProfileChange | null {
  if (!after) return null;
  const nameBefore = str(before?.displayName), nameAfter = str(after.displayName);
  const photoBefore = before?.photoUrl ?? null, photoAfter = after.photoUrl ?? null;
  const nameChanged = nameAfter !== "" && nameAfter !== nameBefore;
  const photoChanged = photoAfter !== photoBefore;
  if (!nameChanged && !photoChanged) return null;
  return {
    uid,
    name: nameAfter || null,
    photo: typeof photoAfter === "string" && photoAfter ? photoAfter : null,
    nameChanged,
    photoChanged,
  };
}

/** Applies [c] to the copies; returns how many records were updated. */
export async function refreshCopies(db: Db, c: ProfileChange): Promise<number> {
  const writes: Array<{ ref: unknown; data: Data }> = [];
  const add = (ref: unknown, data: Data) => {
    if (Object.keys(data).length) writes.push({ ref, data });
  };
  const fields = (nameKey: string, photoKey: string): Data => ({
    ...(c.nameChanged && c.name ? { [nameKey]: c.name } : {}),
    ...(c.photoChanged ? { [photoKey]: c.photo } : {}),
  });

  const jobs = await db.collection("jobs").where("clientId", "==", c.uid).get();
  for (const d of jobs.docs) if (OPEN_JOB.has(str(d.data().status))) add(d.ref, fields("clientName", "clientPhotoUrl"));

  const props = await db.collection("proposals").where("workerId", "==", c.uid).get();
  for (const d of props.docs) if (LIVE_PROPOSAL.has(str(d.data().status))) add(d.ref, fields("workerName", "workerPhotoUrl"));

  for (const [side, nameKey, photoKey] of [["clientId", "clientName", "clientPhotoUrl"], ["workerId", "workerName", "workerPhotoUrl"]]) {
    const cs = await db.collection("contracts").where(side, "==", c.uid).get();
    for (const d of cs.docs) if (LIVE_CONTRACT.has(str(d.data().status))) add(d.ref, fields(nameKey, photoKey));
  }

  const chats = await db.collection("chats").where("participantIds", "array-contains", c.uid).get();
  for (const d of chats.docs) add(d.ref, fields(`participantNames.${c.uid}`, `participantPhotos.${c.uid}`));

  // Batches of at most 400 writes.
  for (let i = 0; i < writes.length; i += 400) {
    const batch = db.batch();
    for (const w of writes.slice(i, i + 400)) batch.update(w.ref, w.data);
    await batch.commit();
  }
  return writes.length;
}

export const refreshProfileCopies = onDocumentUpdated(
  { document: "users/{uid}", retry: false, maxInstances: 5, memory: "256MiB" },
  async (event) => {
    const change = profileChange(event.params.uid, event.data?.before.data(), event.data?.after.data());
    if (!change) return;
    try {
      const n = await refreshCopies(admin.firestore(), change);
      if (n) logger.info(`[profileCopies] ${event.params.uid}: ${n} record(s) updated`);
    } catch (e) {
      logger.error(`[profileCopies] ${event.params.uid}: failed (${(e as { code?: unknown })?.code ?? "error"})`);
    }
  },
);
