import * as admin from "firebase-admin";
import { onDocumentUpdated, onDocumentWritten } from "firebase-functions/v2/firestore";
import { syncLiveLocation } from "./profiles";

/** Proposals that count towards a job's `totalProposals` (not withdrawn). */
export const COUNTED_STATUSES = ["pending", "accepted", "rejected"];

type ProposalData = { jobId?: unknown; status?: unknown } | undefined;
type JobData = { status?: unknown } | undefined;
type Data = Record<string, unknown>;

export function isCounted(status: unknown): boolean {
  return typeof status === "string" && COUNTED_STATUSES.includes(status);
}

/**
 * Jobs whose proposal count may have changed after a proposal write.
 * Nothing to do when the job and counted-ness are unchanged (e.g. a
 * "viewed" mark), so ordinary edits cost no reads.
 */
export function jobsToRecount(before: ProposalData, after: ProposalData): string[] {
  if (
    before && after &&
    before.jobId === after.jobId &&
    isCounted(before.status) === isCounted(after.status)
  ) {
    return [];
  }
  const ids = new Set<string>();
  for (const d of [before, after]) {
    if (d && typeof d.jobId === "string" && d.jobId.length > 0) ids.add(d.jobId);
  }
  return [...ids];
}

/**
 * Sets `jobs/{jobId}.totalProposals` to the number of counted proposals.
 * It recounts instead of incrementing, so retried or duplicate events can
 * never inflate the number; the last run always writes the true value.
 */
export async function recountJobProposals(db: admin.firestore.Firestore, jobId: string): Promise<number | null> {
  const snap = await db
    .collection("proposals")
    .where("jobId", "==", jobId)
    .where("status", "in", COUNTED_STATUSES)
    .count()
    .get();
  const count = snap.data().count;
  const jobRef = db.collection("jobs").doc(jobId);
  return db.runTransaction(async (tx) => {
    const job = await tx.get(jobRef);
    if (!job.exists) return null;
    if (job.get("totalProposals") !== count) tx.update(jobRef, { totalProposals: count });
    return count;
  });
}

export const syncJobProposalCount = onDocumentWritten("proposals/{proposalId}", async (event) => {
  const jobIds = jobsToRecount(event.data?.before?.data(), event.data?.after?.data());
  const db = admin.firestore();
  for (const jobId of jobIds) {
    try {
      await recountJobProposals(db, jobId);
    } catch (error) {
      console.error(`syncJobProposalCount: ${jobId}`, error);
      throw error; // let the platform retry; recounting is safe to repeat
    }
  }
});

/** A job just filled (left "open" for assigned/in progress). */
export function jobJustFilled(before: JobData, after: JobData): boolean {
  return before?.status === "open" && (after?.status === "assigned" || after?.status === "in_progress");
}

/**
 * Closes proposals still pending once someone was hired, including any that
 * arrived just before the client's accept was committed. Safe to repeat.
 */
export async function closePendingProposals(db: admin.firestore.Firestore, jobId: string): Promise<number> {
  const pending = await db
    .collection("proposals")
    .where("jobId", "==", jobId)
    .where("status", "==", "pending")
    .get();
  if (pending.empty) return 0;
  const batch = db.batch();
  const now = admin.firestore.FieldValue.serverTimestamp();
  for (const doc of pending.docs) {
    batch.update(doc.ref, { status: "rejected", closedReason: "filled", decidedAt: now, updatedAt: now });
  }
  await batch.commit();
  return pending.size;
}

/**
 * Copies the job's status onto each of its proposals (`jobStatus`), so a
 * worker can follow a job they applied to without being able to read the job
 * itself once it is no longer public (that would reveal who was hired).
 * Only proposals whose copy differs are written. Safe to repeat.
 */
export async function mirrorJobStatus(db: admin.firestore.Firestore, jobId: string, status: unknown): Promise<number> {
  if (typeof status !== "string") return 0;
  const snap = await db.collection("proposals").where("jobId", "==", jobId).get();
  const stale = snap.docs.filter((d) => d.get("jobStatus") !== status);
  for (let i = 0; i < stale.length; i += 400) {
    const batch = db.batch();
    for (const doc of stale.slice(i, i + 400)) batch.update(doc.ref, { jobStatus: status });
    await batch.commit();
  }
  return stale.length;
}

/** Workers whose live-location viewers may change with this job update. */
export function workersToRefresh(before: Data | undefined, after: Data | undefined): string[] {
  if (before?.status === after?.status && before?.selectedWorkerId === after?.selectedWorkerId) return [];
  const ids = new Set<string>();
  for (const d of [before, after]) {
    const w = d?.selectedWorkerId;
    if (typeof w === "string" && w.length > 0) ids.add(w);
  }
  return [...ids];
}

/**
 * After a job changes: close proposals still pending once someone is hired,
 * copy the job status to its proposals, and update who may follow the hired
 * worker's live location.
 */
export const syncJobRelations = onDocumentUpdated("jobs/{jobId}", async (event) => {
  const before = event.data?.before?.data();
  const after = event.data?.after?.data();
  const db = admin.firestore();
  const jobId = event.params.jobId;
  if (jobJustFilled(before, after)) await closePendingProposals(db, jobId);
  if (before?.status !== after?.status) await mirrorJobStatus(db, jobId, after?.status);
  for (const workerId of workersToRefresh(before, after)) await syncLiveLocation(db, workerId);
});
