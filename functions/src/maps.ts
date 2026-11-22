// Google Maps Platform behind callable functions (Phase G3).
//
// The server key (Routes API, Places API (New), Geocoding API only) lives in
// Secret Manager as MAPS_SERVER_KEY and never reaches the app. Each call:
//   * needs a signed-in user,
//   * is validated (coordinates in range, not 0,0, sane distances/lengths),
//   * is served from a short in-memory cache when possible,
//   * otherwise counts against a per-user hourly limit (mapsUsage/{uid},
//     server-only: the Firestore rules give clients no access),
//   * asks Google for only the fields the app shows (field masks).
// Logs carry error codes only: never the key, coordinates or search text.

import * as admin from "firebase-admin";
import { defineSecret } from "firebase-functions/params";
import { logger } from "firebase-functions/v2";
import { HttpsError, onCall } from "firebase-functions/v2/https";

export const MAPS_SERVER_KEY = defineSecret("MAPS_SERVER_KEY");

type Code = ConstructorParameters<typeof HttpsError>[0];
const fail = (code: Code, message: string): never => {
  throw new HttpsError(code, message);
};

// ── Shapes ────────────────────────────────────────────────────────────────

export interface LatLng {
  lat: number;
  lng: number;
}

export interface RouteResult {
  distanceMeters: number;
  durationSeconds: number;
  /** Google encoded polyline (precision 5). */
  polyline: string;
}

export interface PlaceResult {
  name: string;
  label: string;
  city: string;
  lat: number;
  lng: number;
}

/** What the pure functions need; tests pass fakes. */
export interface MapsDeps {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  db: any;
  fetch: typeof fetch;
  key: string;
  now: () => number;
  cache?: TtlCache;
}

// ── Limits ────────────────────────────────────────────────────────────────

export const LIMITS = {
  /** Calls per user per hour that reach Google (cache hits are free). */
  perHour: { routes: 120, places: 60, geocode: 120 } as Record<Kind, number>,
  /** Longest straight-line trip worth routing for a local marketplace. */
  maxRouteKm: 300,
  queryMin: 3,
  queryMax: 100,
  maxResults: 5,
};

type Kind = "routes" | "places" | "geocode";
const HOUR = 60 * 60 * 1000;

// ── Validation ────────────────────────────────────────────────────────────

export function parseLatLng(v: unknown, what: string): LatLng {
  const o = v as { lat?: unknown; lng?: unknown } | null;
  const lat = o?.lat;
  const lng = o?.lng;
  if (typeof lat !== "number" || typeof lng !== "number" || !Number.isFinite(lat) || !Number.isFinite(lng) ||
      Math.abs(lat) > 90 || Math.abs(lng) > 180 || (lat === 0 && lng === 0)) {
    fail("invalid-argument", `A valid ${what} is required.`);
  }
  return { lat: lat as number, lng: lng as number };
}

export function straightKm(a: LatLng, b: LatLng): number {
  const r = (d: number) => (d * Math.PI) / 180;
  const h = Math.sin(r(b.lat - a.lat) / 2) ** 2 +
    Math.cos(r(a.lat)) * Math.cos(r(b.lat)) * Math.sin(r(b.lng - a.lng) / 2) ** 2;
  return 2 * 6371.0088 * Math.asin(Math.min(1, Math.sqrt(h)));
}

const round = (n: number, dp: number) => n.toFixed(dp);

// ── Cache ─────────────────────────────────────────────────────────────────

/** Small per-instance cache; entries expire and the oldest are dropped. */
export class TtlCache {
  private items = new Map<string, { at: number; value: unknown }>();
  constructor(private max = 500) {}
  get<T>(key: string, ttlMs: number, now: number): T | undefined {
    const hit = this.items.get(key);
    if (!hit) return undefined;
    if (now - hit.at > ttlMs) {
      this.items.delete(key);
      return undefined;
    }
    return hit.value as T;
  }
  set(key: string, value: unknown, now: number) {
    if (this.items.size >= this.max) this.items.delete(this.items.keys().next().value as string);
    this.items.set(key, { at: now, value });
  }
}

const sharedCache = new TtlCache();

// ── Per-user limit ────────────────────────────────────────────────────────

/** Counts one Google call for [uid]; refuses once the hourly limit is hit. */
export async function takeQuota(deps: MapsDeps, uid: string, kind: Kind): Promise<void> {
  const ref = deps.db.collection("mapsUsage").doc(uid);
  const now = deps.now();
  try {
    await runQuota(deps, ref, now, kind);
  } catch (e) {
    if (e instanceof HttpsError) throw e;
    logger.warn(`[maps] quota check failed: ${(e as { code?: unknown })?.code ?? "unknown"}`);
    fail("unavailable", "The map service is busy. Try again later.");
  }
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
async function runQuota(deps: MapsDeps, ref: any, now: number, kind: Kind): Promise<void> {
  await deps.db.runTransaction(async (tx: any) => {
    const snap = await tx.get(ref);
    const d = snap.exists ? snap.data() : {};
    const fresh = typeof d.windowStart !== "number" || now - d.windowStart >= HOUR;
    const used = fresh ? 0 : (typeof d[kind] === "number" ? d[kind] : 0);
    if (used >= LIMITS.perHour[kind]) fail("resource-exhausted", "Too many map requests. Try again later.");
    const next = fresh ? { windowStart: now, routes: 0, places: 0, geocode: 0 } : { ...d };
    next[kind] = used + 1;
    tx.set(ref, next);
  });
}

// ── Google calls ──────────────────────────────────────────────────────────

async function google(deps: MapsDeps, url: string, init: RequestInit, kind: Kind): Promise<any> {
  let res: Response;
  try {
    res = await deps.fetch(url, init);
  } catch (e) {
    logger.warn(`[maps] ${kind}: network error`);
    return fail("unavailable", "The map service could not be reached.");
  }
  if (res.status === 403 || res.status === 401) {
    logger.error(`[maps] ${kind}: key rejected (${res.status}); check the API is enabled and the key restrictions`);
    return fail("failed-precondition", "The map service is not set up.");
  }
  if (res.status === 429) {
    logger.warn(`[maps] ${kind}: Google quota hit`);
    return fail("resource-exhausted", "The map service is busy. Try again later.");
  }
  if (!res.ok) {
    logger.warn(`[maps] ${kind}: HTTP ${res.status}`);
    return fail("unavailable", "The map service failed.");
  }
  try {
    return await res.json();
  } catch {
    logger.warn(`[maps] ${kind}: bad JSON`);
    return fail("unavailable", "The map service failed.");
  }
}

/** "123s" / "12.5s" → seconds. */
export function parseDuration(v: unknown): number | null {
  if (typeof v !== "string") return null;
  const m = /^(\d+(?:\.\d+)?)s$/.exec(v);
  return m ? Number(m[1]) : null;
}

const MODES = new Set(["DRIVE", "TWO_WHEELER", "WALK"]);

export async function computeRouteFor(deps: MapsDeps, uid: string, data: unknown): Promise<RouteResult> {
  const d = (data ?? {}) as Record<string, unknown>;
  const origin = parseLatLng(d.origin, "start point");
  const destination = parseLatLng(d.destination, "destination");
  const mode = d.mode === undefined ? "DRIVE" : d.mode;
  if (typeof mode !== "string" || !MODES.has(mode)) fail("invalid-argument", "Unknown travel mode.");
  if (straightKm(origin, destination) > LIMITS.maxRouteKm) fail("invalid-argument", "These places are too far apart to route.");

  const cache = deps.cache ?? sharedCache;
  const key = `r:${mode}:${round(origin.lat, 4)},${round(origin.lng, 4)}>${round(destination.lat, 4)},${round(destination.lng, 4)}`;
  const cached = cache.get<RouteResult>(key, 5 * 60 * 1000, deps.now());
  if (cached) return cached;

  await takeQuota(deps, uid, "routes");
  const body = {
    origin: { location: { latLng: { latitude: origin.lat, longitude: origin.lng } } },
    destination: { location: { latLng: { latitude: destination.lat, longitude: destination.lng } } },
    travelMode: mode,
    // Basic SKU: no live-traffic pricing tier.
    routingPreference: mode === "WALK" ? undefined : "TRAFFIC_UNAWARE",
    polylineQuality: "OVERVIEW",
    polylineEncoding: "ENCODED_POLYLINE",
    computeAlternativeRoutes: false,
    languageCode: "en",
    units: "METRIC",
  };
  const json = await google(deps, "https://routes.googleapis.com/directions/v2:computeRoutes", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "X-Goog-Api-Key": deps.key,
      "X-Goog-FieldMask": "routes.distanceMeters,routes.duration,routes.polyline.encodedPolyline",
    },
    body: JSON.stringify(body),
  }, "routes");

  const route = Array.isArray(json?.routes) ? json.routes[0] : undefined;
  if (!route) return fail("not-found", "No road route was found.");
  // Routes omits distanceMeters when it is 0.
  const distance = route.distanceMeters === undefined ? 0 : route.distanceMeters;
  const duration = parseDuration(route.duration);
  const polyline = route.polyline?.encodedPolyline;
  if (typeof distance !== "number" || !Number.isFinite(distance) || distance < 0 || distance > 2_000_000 ||
      duration === null || duration < 0 || duration > 7 * 24 * 3600 ||
      typeof polyline !== "string" || polyline.length === 0 || polyline.length > 200_000) {
    logger.warn("[maps] routes: unexpected response shape");
    return fail("unavailable", "The map service returned an unusable route.");
  }
  const result: RouteResult = { distanceMeters: Math.round(distance), durationSeconds: Math.round(duration), polyline };
  cache.set(key, result, deps.now());
  return result;
}

function cityFromComponents(components: unknown, longKey: string): string {
  if (!Array.isArray(components)) return "";
  const pick = (type: string) => components.find((c: any) => Array.isArray(c?.types) && c.types.includes(type));
  const c = pick("locality") ?? pick("administrative_area_level_3") ?? pick("administrative_area_level_2");
  const name = c?.[longKey];
  return typeof name === "string" ? name.slice(0, 80) : "";
}

export async function searchPlacesFor(deps: MapsDeps, uid: string, data: unknown): Promise<{ places: PlaceResult[] }> {
  const d = (data ?? {}) as Record<string, unknown>;
  const query = typeof d.query === "string" ? d.query.trim().replace(/\s+/g, " ") : "";
  if (query.length < LIMITS.queryMin || query.length > LIMITS.queryMax) fail("invalid-argument", "Search text must be 3 to 100 characters.");
  const near = d.near === undefined || d.near === null ? null : parseLatLng(d.near, "search area");

  const cache = deps.cache ?? sharedCache;
  const key = `p:${query.toLowerCase()}@${near ? `${round(near.lat, 2)},${round(near.lng, 2)}` : "-"}`;
  const cached = cache.get<{ places: PlaceResult[] }>(key, 24 * 3600 * 1000, deps.now());
  if (cached) return cached;

  await takeQuota(deps, uid, "places");
  const body: Record<string, unknown> = {
    textQuery: query,
    regionCode: "PK",
    languageCode: "en",
    maxResultCount: LIMITS.maxResults,
  };
  if (near) body.locationBias = { circle: { center: { latitude: near.lat, longitude: near.lng }, radius: 50000 } };
  const json = await google(deps, "https://places.googleapis.com/v1/places:searchText", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "X-Goog-Api-Key": deps.key,
      "X-Goog-FieldMask": "places.displayName,places.formattedAddress,places.location,places.addressComponents",
    },
    body: JSON.stringify(body),
  }, "places");

  const places: PlaceResult[] = [];
  for (const p of Array.isArray(json?.places) ? json.places : []) {
    const lat = p?.location?.latitude;
    const lng = p?.location?.longitude;
    if (typeof lat !== "number" || typeof lng !== "number" || !Number.isFinite(lat) || !Number.isFinite(lng) ||
        Math.abs(lat) > 90 || Math.abs(lng) > 180 || (lat === 0 && lng === 0)) continue;
    const name = typeof p?.displayName?.text === "string" ? p.displayName.text.slice(0, 120) : "";
    const label = typeof p?.formattedAddress === "string" ? p.formattedAddress.slice(0, 200) : name;
    if (!label) continue;
    places.push({ name, label, city: cityFromComponents(p.addressComponents, "longText"), lat, lng });
    if (places.length >= LIMITS.maxResults) break;
  }
  const result = { places };
  cache.set(key, result, deps.now());
  return result;
}

export async function reverseGeocodeFor(deps: MapsDeps, uid: string, data: unknown): Promise<{ place: PlaceResult | null }> {
  const d = (data ?? {}) as Record<string, unknown>;
  const point = parseLatLng(d.point, "location");

  const cache = deps.cache ?? sharedCache;
  const key = `g:${round(point.lat, 5)},${round(point.lng, 5)}`;
  const cached = cache.get<{ place: PlaceResult | null }>(key, 24 * 3600 * 1000, deps.now());
  if (cached) return cached;

  await takeQuota(deps, uid, "geocode");
  const url = "https://maps.googleapis.com/maps/api/geocode/json?" + new URLSearchParams({
    latlng: `${point.lat},${point.lng}`,
    language: "en",
    key: deps.key,
  }).toString();
  const json = await google(deps, url, { method: "GET" }, "geocode");

  const status = json?.status;
  if (status === "REQUEST_DENIED") {
    logger.error("[maps] geocode: request denied; check the Geocoding API is enabled for the key");
    return fail("failed-precondition", "The map service is not set up.");
  }
  if (status === "OVER_QUERY_LIMIT" || status === "OVER_DAILY_LIMIT") return fail("resource-exhausted", "The map service is busy. Try again later.");
  if (status !== "OK" && status !== "ZERO_RESULTS") {
    logger.warn(`[maps] geocode: status ${typeof status === "string" ? status : "?"}`);
    return fail("unavailable", "The map service failed.");
  }
  const first = Array.isArray(json?.results) ? json.results[0] : undefined;
  const label = typeof first?.formatted_address === "string" ? first.formatted_address.slice(0, 200) : "";
  const result = {
    place: first && label
      ? { name: "", label, city: cityFromComponents(first.address_components, "long_name"), lat: point.lat, lng: point.lng }
      : null,
  };
  cache.set(key, result, deps.now());
  return result;
}

// ── Callables ─────────────────────────────────────────────────────────────

const options = {
  secrets: [MAPS_SERVER_KEY],
  // Cost guard: a runaway client can't scale these out.
  maxInstances: 5,
  memory: "256MiB" as const,
  timeoutSeconds: 20,
};

function deps(): MapsDeps {
  const key = MAPS_SERVER_KEY.value();
  if (!key) fail("failed-precondition", "The map service is not set up.");
  return { db: admin.firestore(), fetch, key, now: Date.now };
}

const uidOf = (request: { auth?: { uid?: string } }): string => {
  const uid = request.auth?.uid;
  if (!uid) return fail("unauthenticated", "Please sign in.");
  return uid;
};

// Sign-in is checked before anything else (including the key).
export const computeRoute = onCall(options, async (request) => {
  const uid = uidOf(request);
  return computeRouteFor(deps(), uid, request.data);
});
export const searchPlaces = onCall(options, async (request) => {
  const uid = uidOf(request);
  return searchPlacesFor(deps(), uid, request.data);
});
export const reverseGeocode = onCall(options, async (request) => {
  const uid = uidOf(request);
  return reverseGeocodeFor(deps(), uid, request.data);
});
