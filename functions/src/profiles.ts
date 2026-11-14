import * as admin from "firebase-admin";
import { FieldPath, GeoPoint } from "firebase-admin/firestore";
import { onDocumentWritten } from "firebase-functions/v2/firestore";

/**
 * Public and private profile data.
 *
 * `users/{uid}` holds the whole account (phone, email, push token, home
 * address, earnings, verification fields) and is readable only by its owner
 * and staff. Other people read two mirrors kept by these trusted functions:
 *
 * - `publicProfiles/{uid}`: what discovery and profile pages need, and
 *   nothing else. Worker locations are coarsened to about 1 km.
 * - `liveLocations/{workerId}`: a worker's live position, readable only by
 *   the worker and the clients of jobs currently assigned to them.
 *
 * Users cannot write either mirror (see firestore.rules).
 */

type Data = Record<string, unknown>;
type LatLng = { latitude: number; longitude: number };

/** Account fields that are safe to show to any signed-in user. */
export const PUBLIC_USER_FIELDS = [
  "displayName", "photoUrl", "role", "isActive", "city",
  "isEmailVerified", "isPhoneVerified", "isCnicVerified",
  "createdAt", "rating", "totalReviews",
] as const;

/** Worker profile fields shown on public profiles and in discovery. */
export const PUBLIC_WORKER_FIELDS = [
  "headline", "bio", "categoryId", "categoryName", "skills", "experience",
  "hourlyRate", "dailyRate", "availability", "isVerified", "city",
  "serviceRadius", "totalJobsCompleted", "averageRating", "totalReviews",
  "coverImage", "languages", "responseTime", "portfolioImages", "beforeAfterImages",
] as const;

/** Jobs during which the client may follow the hired worker's live position. */
export const TRACKABLE_JOB_STATUSES = ["assigned", "in_progress"];

/** About 1.1 km: enough for "near you" and distance, not a doorstep. */
export function coarse(value: number): number {
  return Math.round(value * 100) / 100;
}

const BASE32 = "0123456789bcdefghjkmnpqrstuvwxyz";

/** Standard geohash, identical to the app's GeohashUtil.encode. */
export function geohashEncode(latitude: number, longitude: number, precision = 9): string {
  let isEven = true;
  let minLat = -90, maxLat = 90, minLng = -180, maxLng = 180;
  let bit = 0, ch = 0, hash = "";
  while (hash.length < precision) {
    if (isEven) {
      const mid = (minLng + maxLng) / 2;
      if (longitude > mid) { ch |= 1 << (4 - bit); minLng = mid; } else { maxLng = mid; }
    } else {
      const mid = (minLat + maxLat) / 2;
      if (latitude > mid) { ch |= 1 << (4 - bit); minLat = mid; } else { maxLat = mid; }
    }
    isEven = !isEven;
    if (bit < 4) {
      bit++;
    } else {
      hash += BASE32[ch];
      bit = 0;
      ch = 0;
    }
  }
  return hash;
}

function asLatLng(v: unknown): LatLng | null {
  if (!v || typeof v !== "object") return null;
  const p = v as Partial<LatLng>;
  return typeof p.latitude === "number" && typeof p.longitude === "number"
    ? { latitude: p.latitude, longitude: p.longitude }
    : null;
}

function geoPoint(lat: number, lng: number): unknown {
  // Modular import: the namespaced admin.firestore.GeoPoint is not a
  // constructor inside the Functions runtime.
  return new GeoPoint(lat, lng);
}

/** A worker opted out of showing their area (older profiles: shown). */
function locationHidden(user: Data): boolean {
  const v = user.locationVisibility;
  return typeof v === "string" && v !== "public";
}

/**
 * The public view of a user document. Everything not listed above is left
 * out: phone, email, CNIC, push token, home and service addresses, exact
 * location, earnings, verification documents and status, onboarding flags.
 */
export function publicProfileOf(uid: string, user: Data): Data {
  const out: Data = { uid };
  for (const f of PUBLIC_USER_FIELDS) {
    if (user[f] !== undefined) out[f] = user[f];
  }
  const isWorker = user.role === "worker";
  const exact = isWorker && !locationHidden(user) ? asLatLng(user.location) : null;
  if (exact) {
    const lat = coarse(exact.latitude);
    const lng = coarse(exact.longitude);
    out.location = geoPoint(lat, lng);
    out.geohash = geohashEncode(lat, lng);
    out.locationAccuracy = "approximate";
  }
  const wp = user.workerProfile;
  if (isWorker && wp && typeof wp === "object") {
    const src = wp as Data;
    const pub: Data = {};
    for (const f of PUBLIC_WORKER_FIELDS) {
      if (src[f] !== undefined) pub[f] = src[f];
    }
    if (Array.isArray(src.certifications)) {
      // Name, issuer and year only; certificate images can be documents.
      pub.certifications = src.certifications
        .filter((c) => c && typeof c === "object")
        .map((c) => {
          const cert = c as Data;
          const keep: Data = {};
          for (const f of ["name", "issuedBy", "year"]) if (cert[f] !== undefined) keep[f] = cert[f];
          return keep;
        });
    }
    const area = locationHidden(user) ? null : asLatLng(src.location) ?? exact;
    if (area) {
      const lat = coarse(area.latitude);
      const lng = coarse(area.longitude);
      pub.location = geoPoint(lat, lng);
      pub.geohash = geohashEncode(lat, lng);
      pub.locationAccuracy = "approximate";
    }
    out.workerProfile = pub;
  }
  return out;
}

/** Order-independent comparison of two plain Firestore-ish values. */
export function sameValue(a: unknown, b: unknown): boolean {
  return stableJson(a) === stableJson(b);
}

function stableJson(v: unknown): string {
  if (v === null || typeof v !== "object") return JSON.stringify(v) ?? "undefined";
  if (Array.isArray(v)) return `[${v.map(stableJson).join(",")}]`;
  const o = v as Data;
  // GeoPoint / Timestamp expose their values through getters.
  const ll = asLatLng(o);
  if (ll) return `geo(${ll.latitude},${ll.longitude})`;
  if (typeof (o as { toMillis?: unknown }).toMillis === "function") {
    return `ts(${(o as { toMillis: () => number }).toMillis()})`;
  }
  return `{${Object.keys(o).sort().map((k) => `${JSON.stringify(k)}:${stableJson(o[k])}`).join(",")}}`;
}

const LIVE_FIELDS = ["role", "location", "isLocationSharing", "heading", "locationUpdatedAt"];

/** Whether a user write can change what the live-location mirror shows. */
export function liveFieldsChanged(before: Data | undefined, after: Data | undefined): boolean {
  if (!before || !after) return true;
  return LIVE_FIELDS.some((f) => !sameValue(before[f], after[f]));
}

/**
 * The live-location mirror. The exact position is included only while the
 * worker is sharing; otherwise viewers just see that sharing is off.
 */
export function liveLocationOf(workerId: string, user: Data, viewerIds: string[]): Data {
  const sharing = user.isLocationSharing === true;
  const at = sharing ? asLatLng(user.location) : null;
  return {
    workerId,
    viewerIds,
    isLocationSharing: sharing,
    location: at ? geoPoint(at.latitude, at.longitude) : null,
    heading: sharing && typeof user.heading === "number" ? user.heading : null,
    locationUpdatedAt: user.locationUpdatedAt ?? null,
  };
}

/** Clients whose jobs are currently assigned to (or in progress with) this worker. */
export async function activeClientIds(db: admin.firestore.Firestore, workerId: string): Promise<string[]> {
  const snap = await db
    .collection("jobs")
    .where("selectedWorkerId", "==", workerId)
    .where("status", "in", TRACKABLE_JOB_STATUSES)
    .get();
  const ids = new Set<string>();
  for (const doc of snap.docs) {
    const clientId = doc.get("clientId");
    if (typeof clientId === "string" && clientId.length > 0 && clientId !== workerId) ids.add(clientId);
  }
  return [...ids].sort();
}

/**
 * Rebuilds `liveLocations/{workerId}`. With no active job there are no
 * viewers, so the mirror is removed rather than left readable.
 */
export async function syncLiveLocation(
  db: admin.firestore.Firestore,
  workerId: string,
  user?: Data,
): Promise<"written" | "removed" | "skipped"> {
  const data = user ?? ((await db.collection("users").doc(workerId).get()).data() as Data | undefined);
  const ref = db.collection("liveLocations").doc(workerId);
  const viewers = data && data.role === "worker" ? await activeClientIds(db, workerId) : [];
  if (!data || viewers.length === 0) {
    const existing = await ref.get();
    if (!existing.exists) return "skipped";
    await ref.delete();
    return "removed";
  }
  await ref.set(liveLocationOf(workerId, data, viewers));
  return "written";
}

/**
 * Keeps `publicProfiles/{uid}` in step with `users/{uid}`. It compares with
 * the stored mirror (not the previous user document), so a mirror left stale
 * by an earlier failed run is corrected on the next write. A write that does
 * not change the public view (e.g. a push token or a GPS update within the
 * same ~1 km) costs one read and no write.
 */
export async function syncPublicProfile(
  db: admin.firestore.Firestore,
  uid: string,
  after: Data | undefined,
): Promise<"written" | "removed" | "unchanged"> {
  const ref = db.collection("publicProfiles").doc(uid);
  if (!after) {
    await ref.delete();
    return "removed";
  }
  const next = publicProfileOf(uid, after);
  const current = await ref.get();
  if (current.exists && sameValue(current.data(), next)) return "unchanged";
  await ref.set(next);
  return "written";
}

export const syncUserMirrors = onDocumentWritten("users/{uid}", async (event) => {
  const uid = event.params.uid;
  const before = event.data?.before?.data() as Data | undefined;
  const after = event.data?.after?.data() as Data | undefined;
  const db = admin.firestore();
  await syncPublicProfile(db, uid, after);
  if (!after) {
    await db.collection("liveLocations").doc(uid).delete();
  } else if (liveFieldsChanged(before, after)) {
    await syncLiveLocation(db, uid, after);
  }
});

/**
 * One-off, additive backfill for accounts created before the mirrors existed.
 * Writes only `publicProfiles` and `liveLocations`; never changes `users`.
 * Run manually with approval (see functions/scripts/backfill-mirrors.js).
 */
export async function backfillMirrors(db: admin.firestore.Firestore, pageSize = 300): Promise<{ profiles: number; live: number }> {
  let profiles = 0;
  let live = 0;
  let last: admin.firestore.QueryDocumentSnapshot | undefined;
  for (;;) {
    let q = db.collection("users").orderBy(FieldPath.documentId()).limit(pageSize);
    if (last) q = q.startAfter(last);
    const page = await q.get();
    if (page.empty) break;
    for (const doc of page.docs) {
      const data = doc.data() as Data;
      await db.collection("publicProfiles").doc(doc.id).set(publicProfileOf(doc.id, data));
      profiles++;
      if (data.role === "worker" && (await syncLiveLocation(db, doc.id, data)) === "written") live++;
    }
    last = page.docs[page.docs.length - 1];
    if (page.size < pageSize) break;
  }
  return { profiles, live };
}
