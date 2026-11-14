import * as admin from "firebase-admin";
import { FieldValue, GeoPoint } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";

/**
 * Hiring and the work lifecycle, decided on the server.
 *
 * Clients cannot write contract status or lifecycle fields (see
 * firestore.rules); every change goes through these callable functions, each
 * in one transaction that checks who is asking, the current state, and keeps
 * the job, proposals, contract, chat and notifications consistent.
 *
 * Contract status values are the existing ones (pending, active, completed,
 * cancelled, rejected). Within `active`, the stage comes from stored
 * timestamps: not started → `workStartedAt` → `submittedAt`.
 */

type Data = Record<string, unknown>;
type Db = admin.firestore.Firestore;
type Tx = admin.firestore.Transaction;

export const COMMISSION_RATE = 0.1;
export const CANCEL_REASONS = ["schedule_conflict", "no_longer_needed", "agreed_with_other_party", "safety_concern", "other"];
export const MAX_EVIDENCE = 3;
/** Revision rounds a client may ask for (approved Phase 4B rule). */
export const MAX_REVISIONS = 3;

/**
 * Submissions so far. Phase 4A contracts have no counter: a set
 * `submittedAt` counts as one submission.
 */
export function submissionsOf(c: Data): number {
  if (typeof c.submissionCount === "number") return c.submissionCount;
  return c.submittedAt ? 1 : 0;
}

export function revisionsOf(c: Data): number {
  return typeof c.revisionCount === "number" ? c.revisionCount : 0;
}

/**
 * Stage of a contract, from stored fields. Within `active`: not started →
 * in progress (`workStartedAt`) → submitted (more submissions than revision
 * requests). A revision request puts it back in progress.
 */
export function stageOf(c: Data): "requested" | "not_started" | "in_progress" | "submitted" | "completed" | "cancelled" | "rejected" | "unknown" {
  switch (c.status) {
    case "pending": return "requested";
    case "completed": return "completed";
    case "cancelled": return "cancelled";
    case "rejected": return "rejected";
    case "active":
      if (submissionsOf(c) > revisionsOf(c)) return "submitted";
      if (c.workStartedAt) return "in_progress";
      return "not_started";
    default: return "unknown";
  }
}

function fail(code: "failed-precondition" | "permission-denied" | "not-found" | "invalid-argument" | "unauthenticated", message: string): never {
  throw new HttpsError(code, message);
}

async function activeUser(tx: Tx, db: Db, uid: string): Promise<Data> {
  const snap = await tx.get(db.collection("users").doc(uid));
  const user = snap.data() as Data | undefined;
  if (!user) fail("permission-denied", "No profile for this account.");
  if (user.isActive === false) fail("permission-denied", "This account is suspended.");
  return user;
}

function notification(userId: string, title: string, body: string, type: string, contractId: string, jobId: string): Data {
  return {
    userId, title, body, type,
    payload: { contractId, jobId },
    referenceId: contractId,
    isRead: false,
    createdAt: FieldValue.serverTimestamp(),
  };
}

// ── Accept a proposal (creates the contract) ──────────────────────────────

export type AcceptResult = { contractId: string; alreadyAccepted: boolean };

/**
 * The job owner accepts a pending proposal on their public open job. One
 * transaction: proposal accepted, job assigned, other pending proposals
 * closed as "filled", the contract created at `contracts/{proposalId}`, the
 * job chat opened, and the worker notified. Repeating the call returns the
 * same contract and changes nothing, so duplicates are impossible.
 */
export async function acceptProposal(db: Db, uid: string, proposalId: string): Promise<AcceptResult> {
  if (typeof proposalId !== "string" || proposalId.length === 0) fail("invalid-argument", "proposalId is required.");
  return db.runTransaction(async (tx) => {
    const proposalRef = db.collection("proposals").doc(proposalId);
    const contractRef = db.collection("contracts").doc(proposalId);
    const [pSnap, cSnap] = [await tx.get(proposalRef), await tx.get(contractRef)];
    const p = pSnap.data() as Data | undefined;
    if (!p) fail("not-found", "Proposal not found.");
    if (p.clientId !== uid) fail("permission-denied", "Only the job owner can accept this proposal.");
    if (cSnap.exists) {
      // Idempotent: the same hire was already made.
      if (cSnap.get("clientId") !== uid) fail("permission-denied", "Not your contract.");
      return { contractId: contractRef.id, alreadyAccepted: true };
    }
    if (p.status !== "pending") fail("failed-precondition", "This proposal is no longer pending.");
    const jobId = p.jobId as string;
    const workerId = p.workerId as string;
    if (proposalId !== `${jobId}_${workerId}`) fail("failed-precondition", "Proposal does not belong to this job.");

    const jobRef = db.collection("jobs").doc(jobId);
    const jSnap = await tx.get(jobRef);
    const job = jSnap.data() as Data | undefined;
    if (!job) fail("not-found", "Job not found.");
    if (job.clientId !== uid) fail("permission-denied", "Only the job owner can accept proposals.");
    if (job.status !== "open" || (job.selectedWorkerId !== null && job.selectedWorkerId !== undefined)) {
      fail("failed-precondition", "This job is no longer open.");
    }
    const client = await activeUser(tx, db, uid);
    if (client.role !== "client") fail("permission-denied", "Only clients can hire.");
    const worker = (await tx.get(db.collection("users").doc(workerId))).data() as Data | undefined;
    if (!worker || worker.isActive === false) fail("failed-precondition", "This worker can no longer be hired.");

    const others = await tx.get(db.collection("proposals").where("jobId", "==", jobId).where("status", "==", "pending"));
    const chatRef = db.collection("chats").doc(`${jobId}_${workerId}`);
    const chat = await tx.get(chatRef);

    const now = FieldValue.serverTimestamp();
    const rate = Number(p.proposedRate);
    const commission = Math.round(rate * COMMISSION_RATE);
    const clientName = (client.displayName as string) || (job.clientName as string) || "";
    const clientPhoto = (client.photoUrl as string | undefined) ?? (job.clientPhotoUrl as string | undefined) ?? null;
    const workerName = (p.workerName as string) || (worker.displayName as string) || "";
    const workerPhoto = (p.workerPhotoUrl as string | undefined) ?? (worker.photoUrl as string | undefined) ?? null;

    tx.update(proposalRef, { status: "accepted", decidedAt: now, updatedAt: now });
    tx.update(jobRef, { status: "assigned", selectedWorkerId: workerId, selectedWorkerName: workerName, updatedAt: now });
    for (const d of others.docs) {
      if (d.id === proposalId) continue;
      tx.update(d.ref, { status: "rejected", closedReason: "filled", decidedAt: now, updatedAt: now });
    }
    tx.set(contractRef, {
      jobId,
      jobTitle: job.title ?? p.jobTitle ?? "",
      jobDescription: job.description ?? "",
      proposalId,
      clientId: uid,
      clientName,
      clientPhotoUrl: clientPhoto,
      workerId,
      workerName,
      workerPhotoUrl: workerPhoto,
      agreedRate: rate,
      rateType: p.rateType ?? "fixed",
      estimatedDuration: p.estimatedDuration ?? "",
      totalAmount: rate,
      commissionRate: COMMISSION_RATE,
      commissionAmount: commission,
      workerEarnings: rate - commission,
      paymentStatus: "unpaid",
      paymentProviderState: "not_configured",
      serviceCity: job.city ?? null,
      serviceArea: job.address ?? null,
      status: "active",
      acceptedAt: now,
      startDate: now,
      workStartedAt: null,
      submittedAt: null,
      completedAt: null,
      cancelledAt: null,
      clientReviewed: false,
      workerReviewed: false,
      createdAt: now,
      updatedAt: now,
    });
    const opener = "Proposal accepted. You can now message each other.";
    if (chat.exists) {
      tx.update(chatRef, {
        lastMessage: opener, lastMessageSenderId: uid, lastMessageAt: now,
        [`unreadCount.${workerId}`]: FieldValue.increment(1),
      });
    } else {
      tx.set(chatRef, {
        participantIds: [uid, workerId],
        participantNames: { [uid]: clientName, [workerId]: workerName },
        participantPhotos: { [uid]: clientPhoto, [workerId]: workerPhoto },
        lastMessage: opener, lastMessageSenderId: uid, lastMessageAt: now,
        unreadCount: { [uid]: 0, [workerId]: 1 },
        relatedJobId: jobId,
        relatedJobTitle: job.title ?? "",
      });
    }
    tx.set(db.collection("notifications").doc(), notification(workerId, "Proposal accepted",
      `${clientName || "The client"} hired you for "${job.title}". Your contract is ready.`, "contract_created", proposalId, jobId));
    return { contractId: contractRef.id, alreadyAccepted: false };
  });
}

// ── Direct requests (a job sent to one worker) ────────────────────────────

export type DirectResult = { contractId: string | null; status: string; alreadyAnswered: boolean };

/**
 * The requested worker answers a direct request (an open job with
 * `selectedWorkerId` set by the client). Accepting assigns the job and
 * creates the contract at `contracts/{jobId}_{workerId}` in one transaction,
 * with the client's stated budget as the price (a range stays a range).
 * Declining cancels the job. Repeating an accept returns the same contract.
 */
export async function respondToDirectRequest(db: Db, uid: string, jobId: string, accept: boolean): Promise<DirectResult> {
  if (typeof jobId !== "string" || jobId.length === 0) fail("invalid-argument", "jobId is required.");
  return db.runTransaction(async (tx) => {
    const jobRef = db.collection("jobs").doc(jobId);
    const contractRef = db.collection("contracts").doc(`${jobId}_${uid}`);
    const [jSnap, cSnap] = [await tx.get(jobRef), await tx.get(contractRef)];
    const job = jSnap.data() as Data | undefined;
    if (!job) fail("not-found", "Job not found.");
    if (job.selectedWorkerId !== uid) fail("permission-denied", "This request was not sent to you.");
    if (cSnap.exists) return { contractId: contractRef.id, status: "active", alreadyAnswered: true };
    if (job.status !== "open") fail("failed-precondition", "This request was already answered or closed.");
    const worker = await activeUser(tx, db, uid);
    if (worker.role !== "worker") fail("permission-denied", "Only workers answer requests.");
    const clientId = job.clientId as string;
    const client = (await tx.get(db.collection("users").doc(clientId))).data() as Data | undefined;
    const chatRef = db.collection("chats").doc(`${jobId}_${uid}`);
    const chat = await tx.get(chatRef);
    const now = FieldValue.serverTimestamp();
    const title = (job.title as string) || "your job";
    const workerName = (worker.displayName as string) || (job.selectedWorkerName as string) || "";

    if (!accept) {
      tx.update(jobRef, { status: "cancelled", updatedAt: now });
      tx.set(db.collection("notifications").doc(), notification(clientId, "Request declined",
        `${workerName || "The worker"} declined "${title}".`, "request_declined", "", jobId));
      return { contractId: null, status: "cancelled", alreadyAnswered: false };
    }

    const max = Number(job.budgetMax ?? 0);
    const min = Number(job.budgetMin ?? max);
    const commission = Math.round(max * COMMISSION_RATE);
    const clientName = (job.clientName as string) || (client?.displayName as string) || "";
    const clientPhoto = (job.clientPhotoUrl as string | undefined) ?? (client?.photoUrl as string | undefined) ?? null;
    const workerPhoto = (worker.photoUrl as string | undefined) ?? null;
    tx.update(jobRef, { status: "assigned", selectedWorkerName: workerName, updatedAt: now });
    tx.set(contractRef, {
      jobId,
      jobTitle: job.title ?? "",
      jobDescription: job.description ?? "",
      proposalId: "direct_request",
      clientId,
      clientName,
      clientPhotoUrl: clientPhoto,
      workerId: uid,
      workerName,
      workerPhotoUrl: workerPhoto,
      agreedRate: max,
      // The client's budget was a range: the final price is agreed in chat.
      priceMin: min < max ? min : null,
      rateType: job.budgetType ?? "fixed",
      estimatedDuration: "",
      totalAmount: max,
      commissionRate: COMMISSION_RATE,
      commissionAmount: commission,
      workerEarnings: max - commission,
      paymentStatus: "unpaid",
      paymentProviderState: "not_configured",
      serviceCity: job.city ?? null,
      serviceArea: job.address ?? null,
      status: "active",
      acceptedAt: now,
      startDate: now,
      workStartedAt: null,
      submittedAt: null,
      completedAt: null,
      cancelledAt: null,
      clientReviewed: false,
      workerReviewed: false,
      createdAt: now,
      updatedAt: now,
    });
    const opener = "Request accepted. You can now message each other.";
    if (chat.exists) {
      tx.update(chatRef, {
        lastMessage: opener, lastMessageSenderId: uid, lastMessageAt: now,
        [`unreadCount.${clientId}`]: FieldValue.increment(1),
      });
    } else {
      tx.set(chatRef, {
        participantIds: [clientId, uid],
        participantNames: { [clientId]: clientName, [uid]: workerName },
        participantPhotos: { [clientId]: clientPhoto, [uid]: workerPhoto },
        lastMessage: opener, lastMessageSenderId: uid, lastMessageAt: now,
        unreadCount: { [clientId]: 1, [uid]: 0 },
        relatedJobId: jobId,
        relatedJobTitle: job.title ?? "",
      });
    }
    tx.set(db.collection("notifications").doc(), notification(clientId, "Request accepted",
      `${workerName || "The worker"} accepted "${title}". Your contract is ready.`, "contract_created", contractRef.id, jobId));
    return { contractId: contractRef.id, status: "active", alreadyAnswered: false };
  });
}

// ── Lifecycle actions ─────────────────────────────────────────────────────

export type ContractActionInput = {
  contractId: string;
  action: "respond" | "start" | "submit" | "confirm" | "cancel" | "shareAddress" | "requestRevision" | "progressUpdate";
  /** Client-generated id for progressUpdate, so a retry is a no-op. */
  requestId?: string;
  accept?: boolean;
  note?: string;
  attachments?: string[];
  reason?: string;
  address?: string;
  /**
   * shareAddress: the exact place pinned on the map (Navigation phase 8).
   * A value sets it, null clears it, absent leaves it unchanged (older app
   * versions send no pin and must not wipe one).
   */
  location?: { lat?: unknown; lng?: unknown } | null;
};

/**
 * A real map position, or invalid-argument. GeoPoint comes from the modular
 * "firebase-admin/firestore" import: the Functions emulator wraps the
 * namespaced `admin.firestore`, where the GeoPoint constructor is missing
 * (found in the Navigation phase 10 emulator run).
 */
function pin(v: unknown): GeoPoint {
  const o = (v ?? {}) as { lat?: unknown; lng?: unknown };
  const lat = typeof o.lat === "number" ? o.lat : NaN;
  const lng = typeof o.lng === "number" ? o.lng : NaN;
  if (!Number.isFinite(lat) || !Number.isFinite(lng) || Math.abs(lat) > 90 || Math.abs(lng) > 180 || (lat === 0 && lng === 0)) {
    fail("invalid-argument", "Location must be a valid map position.");
  }
  return new GeoPoint(lat, lng);
}

function text(v: unknown, min: number, max: number, field: string): string {
  const s = typeof v === "string" ? v.trim() : "";
  if (s.length < min || s.length > max) fail("invalid-argument", `${field} must be ${min}–${max} characters.`);
  return s;
}

/** Evidence must sit in this contract's own Storage folder (rules: only the worker writes there). */
export function validEvidence(contractId: string, paths: unknown): string[] {
  if (paths === undefined) return [];
  if (!Array.isArray(paths) || paths.length > MAX_EVIDENCE) fail("invalid-argument", `Up to ${MAX_EVIDENCE} photos.`);
  const prefix = `contracts/${contractId}/evidence/`;
  const out = paths.map((p) => {
    if (typeof p !== "string" || !p.startsWith(prefix) || p.includes("..") || !/^[\w./-]+$/.test(p)) {
      fail("invalid-argument", "Photos must be uploaded to this contract.");
    }
    return p;
  });
  return [...new Set(out)];
}

/**
 * Runs one lifecycle step for the signed-in user. Who may do what:
 *  - respond (accept or decline a booking request): the worker, while pending;
 *  - start: the hired worker, once, before submitting;
 *  - submit: the hired worker, once, after starting;
 *  - confirm: the client, only after the work was submitted;
 *  - cancel: either party, while pending or active and not yet submitted;
 *  - shareAddress: the client, while pending or active (private to the two),
 *    optionally with the exact place pinned on the map (serviceLocation),
 *    the destination for the worker's turn-by-turn navigation;
 *  - requestRevision: the client, while the work awaits review, at most
 *    MAX_REVISIONS times (back to in progress; the submission is kept);
 *  - progressUpdate: the hired worker, before submitting; one per requestId.
 *
 * Live location (contracts/{id}/live/location) ends with the work: it is
 * deleted when work is submitted, completed or cancelled, or a request is
 * declined, and the rules refuse new positions then.
 */
export async function contractAction(db: Db, uid: string, input: ContractActionInput): Promise<{ status: string; stage: string }> {
  const { contractId, action } = input ?? ({} as ContractActionInput);
  if (typeof contractId !== "string" || contractId.length === 0) fail("invalid-argument", "contractId is required.");
  return db.runTransaction(async (tx) => {
    const ref = db.collection("contracts").doc(contractId);
    const snap = await tx.get(ref);
    const c = snap.data() as Data | undefined;
    if (!c) fail("not-found", "Contract not found.");
    const isClient = c.clientId === uid;
    const isWorker = c.workerId === uid;
    if (!isClient && !isWorker) fail("permission-denied", "You are not part of this contract.");
    await activeUser(tx, db, uid);
    const jobId = c.jobId as string;
    const jobRef = db.collection("jobs").doc(jobId);
    const job = (await tx.get(jobRef)).data() as Data | undefined;
    const stage = stageOf(c);
    const now = FieldValue.serverTimestamp();
    const other = isClient ? (c.workerId as string) : (c.clientId as string);
    const title = (c.jobTitle as string) || "your job";
    const name = isClient ? (c.clientName as string) || "The client" : (c.workerName as string) || "The worker";
    const notify = (t: string, b: string, type: string) =>
      tx.set(db.collection("notifications").doc(), notification(other, t, b, type, contractId, jobId));
    const jobUpdate = (status: string) => {
      if (job) tx.update(jobRef, { status, updatedAt: now });
    };
    const endLiveLocation = () => tx.delete(ref.collection("live").doc("location"));

    switch (action) {
      case "respond": {
        if (!isWorker) fail("permission-denied", "Only the worker can answer a booking request.");
        if (stage !== "requested") fail("failed-precondition", "This request was already answered.");
        if (input.accept === true) {
          tx.update(ref, { status: "active", respondedAt: now, acceptedAt: now, workStartedAt: null, submittedAt: null, updatedAt: now });
          jobUpdate("assigned");
          notify("Booking accepted", `${name} accepted your booking for "${title}".`, "booking_accepted");
          return { status: "active", stage: "not_started" };
        }
        tx.update(ref, { status: "rejected", respondedAt: now, updatedAt: now });
        jobUpdate("cancelled");
        endLiveLocation();
        notify("Booking declined", `${name} declined your booking for "${title}".`, "booking_declined");
        return { status: "rejected", stage: "rejected" };
      }
      case "start": {
        if (!isWorker) fail("permission-denied", "Only the hired worker can start work.");
        if (stage !== "not_started") fail("failed-precondition", "Work can't be started now.");
        if (!job || job.selectedWorkerId !== uid || job.status !== "assigned") {
          fail("failed-precondition", "The job is not assigned to you.");
        }
        tx.update(ref, { workStartedAt: now, updatedAt: now });
        jobUpdate("in_progress");
        notify("Work started", `${name} started work on "${title}".`, "work_started");
        return { status: "active", stage: "in_progress" };
      }
      case "submit": {
        if (!isWorker) fail("permission-denied", "Only the hired worker can submit work.");
        if (stage === "submitted") fail("failed-precondition", "Work was already submitted.");
        if (stage !== "in_progress") fail("failed-precondition", "Start the work before submitting it.");
        const note = text(input.note, 10, 1000, "Note");
        const attachments = validEvidence(contractId, input.attachments);
        const number = submissionsOf(c) + 1;
        // Every submission is kept; `submission` mirrors the latest (Phase 4A readers).
        tx.set(ref.collection("submissions").doc(String(number)), { number, note, attachments, submittedAt: now, submittedBy: uid });
        tx.update(ref, {
          submittedAt: now, submission: { note, attachments, submittedAt: now },
          submissionCount: number, updatedAt: now,
        });
        endLiveLocation();
        notify(number > 1 ? "Work resubmitted" : "Work submitted",
          `${name} ${number > 1 ? "resubmitted" : "submitted"} "${title}" for your review.`, "work_submitted");
        return { status: "active", stage: "submitted" };
      }
      case "confirm": {
        if (!isClient) fail("permission-denied", "Only the client can confirm completion.");
        if (stage !== "submitted") fail("failed-precondition", "There is no submitted work to confirm.");
        const workerRef = db.collection("users").doc(c.workerId as string);
        const worker = (await tx.get(workerRef)).data() as Data | undefined;
        tx.update(ref, { status: "completed", completedAt: now, endDate: now, updatedAt: now });
        jobUpdate("completed");
        endLiveLocation();
        if (worker?.workerProfile) {
          // Trusted statistic: once per contract (completion is final).
          tx.update(workerRef, { "workerProfile.totalJobsCompleted": FieldValue.increment(1) });
        }
        notify("Completion confirmed", `${name} confirmed "${title}" is complete.`, "completion_confirmed");
        return { status: "completed", stage: "completed" };
      }
      case "cancel": {
        if (!["requested", "not_started", "in_progress"].includes(stage)) {
          fail("failed-precondition", stage === "submitted"
            ? "Submitted work can only be confirmed by the client."
            : "This contract can no longer be cancelled.");
        }
        const reason = typeof input.reason === "string" ? input.reason : "";
        if (!CANCEL_REASONS.includes(reason)) fail("invalid-argument", "Choose a reason.");
        const note = input.note === undefined || input.note === "" ? "" : text(input.note, 1, 300, "Note");
        tx.update(ref, {
          status: "cancelled", cancelledAt: now, cancelledBy: uid,
          cancelledByRole: isClient ? "client" : "worker", cancelReason: reason, cancelNote: note, updatedAt: now,
        });
        jobUpdate("cancelled");
        endLiveLocation();
        notify("Contract cancelled", `${name} cancelled the contract for "${title}".`, "contract_cancelled");
        return { status: "cancelled", stage: "cancelled" };
      }
      case "shareAddress": {
        if (!isClient) fail("permission-denied", "Only the client can share the address.");
        if (!["requested", "not_started", "in_progress"].includes(stage)) fail("failed-precondition", "The contract is closed.");
        const address = text(input.address, 5, 200, "Address");
        const patch: Record<string, string | FieldValue | GeoPoint> = {
          serviceAddress: address, addressSharedAt: now, updatedAt: now,
        };
        if (input.location === null) {
          patch.serviceLocation = FieldValue.delete();
          patch.serviceLocationSetAt = FieldValue.delete();
        } else if (input.location !== undefined) {
          patch.serviceLocation = pin(input.location);
          patch.serviceLocationSetAt = now;
        }
        tx.update(ref, patch);
        notify("Address shared", `${name} shared the exact address for "${title}".`, "address_shared");
        return { status: c.status as string, stage };
      }
      case "requestRevision": {
        if (!isClient) fail("permission-denied", "Only the client can ask for changes.");
        if (stage !== "submitted") fail("failed-precondition", "There is no submitted work to send back.");
        const rounds = revisionsOf(c);
        if (rounds >= MAX_REVISIONS) fail("failed-precondition", "No more revision rounds are left. Confirm the work or contact support.");
        const note = text(input.note, 10, 1000, "Note");
        const number = submissionsOf(c);
        tx.update(ref, {
          revisionCount: rounds + 1, revisionRequestedAt: now, revisionNote: note,
          submissionCount: number, updatedAt: now,
        });
        // Recorded on the submission it answers; Phase 4A contracts get one created.
        tx.set(ref.collection("submissions").doc(String(number)), {
          number, revisionNote: note, revisionRequestedAt: now,
          ...(typeof c.submissionCount === "number" ? {} : {
            note: ((c.submission as Data | undefined)?.note as string) ?? "",
            attachments: ((c.submission as Data | undefined)?.attachments as string[]) ?? [],
            submittedAt: c.submittedAt ?? null,
          }),
        }, { merge: true });
        notify("Changes requested", `${name} asked for changes to "${title}".`, "revision_requested");
        return { status: "active", stage: "in_progress" };
      }
      case "progressUpdate": {
        if (!isWorker) fail("permission-denied", "Only the hired worker posts progress updates.");
        if (!["not_started", "in_progress"].includes(stage)) fail("failed-precondition", "Updates can be posted only while the work is open.");
        const requestId = typeof input.requestId === "string" ? input.requestId : "";
        if (!/^[A-Za-z0-9_-]{8,64}$/.test(requestId)) fail("invalid-argument", "requestId is required.");
        const updateRef = ref.collection("updates").doc(requestId);
        if ((await tx.get(updateRef)).exists) return { status: c.status as string, stage }; // retry: already saved
        const note = text(input.note, 2, 1000, "Update");
        tx.set(updateRef, { note, authorId: uid, authorRole: "worker", createdAt: now });
        tx.update(ref, { lastUpdateAt: now, updateCount: FieldValue.increment(1), updatedAt: now });
        notify("Progress update", `${name}: ${note.length > 80 ? note.slice(0, 77) + "…" : note}`, "progress_update");
        return { status: c.status as string, stage };
      }
      default:
        fail("invalid-argument", "Unknown action.");
    }
  });
}

// ── Callable endpoints ────────────────────────────────────────────────────

function caller(auth: { uid: string } | undefined): string {
  if (!auth?.uid) fail("unauthenticated", "Please sign in.");
  return auth.uid;
}

export const acceptProposalCall = onCall(async (request) => {
  const data = (request.data ?? {}) as { proposalId?: string };
  return acceptProposal(admin.firestore(), caller(request.auth), data.proposalId as string);
});

export const directRequestCall = onCall(async (request) => {
  const data = (request.data ?? {}) as { jobId?: string; accept?: boolean };
  return respondToDirectRequest(admin.firestore(), caller(request.auth), data.jobId as string, data.accept === true);
});

export const contractActionCall = onCall(async (request) => {
  return contractAction(admin.firestore(), caller(request.auth), (request.data ?? {}) as ContractActionInput);
});
