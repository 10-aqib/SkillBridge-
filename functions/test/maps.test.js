// Maps proxy (functions/src/maps.ts) against a fake Google (fetch) and the
// in-memory fake DB. No network, no real key.
const test = require("node:test");
const assert = require("node:assert/strict");
const maps = require("../.test-build/maps.js");
const { fakeDb, rejects: rejectsWith } = require("./fake_db");

const rejects = (p, code) => rejectsWith(assert, p, code);

const lahore = { lat: 31.5204, lng: 74.3587 };
const pin = { lat: 31.5497, lng: 74.3436 };
const KEY = "test-key-not-real";

/** A fake fetch: answers with [reply] and records each request. */
function fakeGoogle(reply) {
  const calls = [];
  const fetch = async (url, init = {}) => {
    calls.push({ url: String(url), init, body: init.body ? JSON.parse(init.body) : undefined });
    const r = typeof reply === "function" ? reply(calls.length) : reply;
    if (r instanceof Error) throw r;
    const status = r.status ?? 200;
    return { status, ok: status >= 200 && status < 300, json: async () => r.json };
  };
  return { fetch, calls };
}

let clock = 1_000_000;
const deps = (google, db = fakeDb({})) => ({
  db, fetch: google.fetch, key: KEY, now: () => clock, cache: new maps.TtlCache(),
});

const routeReply = {
  json: { routes: [{ distanceMeters: 4210, duration: "754s", polyline: { encodedPolyline: "_p~iF~ps|U_ulLnnqC_mqNvxq`@" } }] },
};

// ── computeRoute ───────────────────────────────────────────────────────────

test("route: asks Routes API for only distance, duration and polyline; returns them", async () => {
  const g = fakeGoogle(routeReply);
  const r = await maps.computeRouteFor(deps(g), "u1", { origin: lahore, destination: pin });
  assert.deepEqual(r, { distanceMeters: 4210, durationSeconds: 754, polyline: "_p~iF~ps|U_ulLnnqC_mqNvxq`@" });
  const c = g.calls[0];
  assert.equal(c.url, "https://routes.googleapis.com/directions/v2:computeRoutes");
  assert.equal(c.init.headers["X-Goog-FieldMask"], "routes.distanceMeters,routes.duration,routes.polyline.encodedPolyline");
  assert.equal(c.init.headers["X-Goog-Api-Key"], KEY);
  assert.equal(c.body.travelMode, "DRIVE");
  assert.equal(c.body.routingPreference, "TRAFFIC_UNAWARE");
  assert.deepEqual(c.body.origin.location.latLng, { latitude: lahore.lat, longitude: lahore.lng });
  assert.equal(c.body.computeAlternativeRoutes, false);
});

test("route: bad input is refused before Google is called", async () => {
  const g = fakeGoogle(routeReply);
  const d = deps(g);
  await rejects(maps.computeRouteFor(d, "u1", {}), "invalid-argument");
  await rejects(maps.computeRouteFor(d, "u1", { origin: { lat: 0, lng: 0 }, destination: pin }), "invalid-argument");
  await rejects(maps.computeRouteFor(d, "u1", { origin: { lat: 91, lng: 74 }, destination: pin }), "invalid-argument");
  await rejects(maps.computeRouteFor(d, "u1", { origin: { lat: "31", lng: 74 }, destination: pin }), "invalid-argument");
  await rejects(maps.computeRouteFor(d, "u1", { origin: lahore, destination: { lat: NaN, lng: 1 } }), "invalid-argument");
  await rejects(maps.computeRouteFor(d, "u1", { origin: lahore, destination: pin, mode: "FLY" }), "invalid-argument");
  // Lahore → Karachi is over 300 km in a straight line.
  await rejects(maps.computeRouteFor(d, "u1", { origin: lahore, destination: { lat: 24.8607, lng: 67.0011 } }), "invalid-argument");
  assert.equal(g.calls.length, 0);
});

test("route: no route, unusable answers and Google errors map to clear codes", async () => {
  await rejects(maps.computeRouteFor(deps(fakeGoogle({ json: {} })), "u1", { origin: lahore, destination: pin }), "not-found");
  await rejects(maps.computeRouteFor(deps(fakeGoogle({ json: { routes: [{ duration: "abc", polyline: { encodedPolyline: "x" } }] } })), "u1",
    { origin: lahore, destination: pin }), "unavailable");
  await rejects(maps.computeRouteFor(deps(fakeGoogle({ status: 403, json: {} })), "u1", { origin: lahore, destination: pin }), "failed-precondition");
  await rejects(maps.computeRouteFor(deps(fakeGoogle({ status: 429, json: {} })), "u1", { origin: lahore, destination: pin }), "resource-exhausted");
  await rejects(maps.computeRouteFor(deps(fakeGoogle({ status: 500, json: {} })), "u1", { origin: lahore, destination: pin }), "unavailable");
  await rejects(maps.computeRouteFor(deps(fakeGoogle(new Error("offline"))), "u1", { origin: lahore, destination: pin }), "unavailable");
});

test("route: a zero-length route (Google omits distanceMeters) is distance 0", async () => {
  const g = fakeGoogle({ json: { routes: [{ duration: "0s", polyline: { encodedPolyline: "_p~iF~ps|U" } }] } });
  const r = await maps.computeRouteFor(deps(g), "u1", { origin: lahore, destination: { lat: 31.5205, lng: 74.3588 } });
  assert.equal(r.distanceMeters, 0);
  assert.equal(r.durationSeconds, 0);
});

test("route: nearby repeats are served from cache without a Google call or quota", async () => {
  const g = fakeGoogle(routeReply);
  const db = fakeDb({});
  const d = deps(g, db);
  await maps.computeRouteFor(d, "u1", { origin: lahore, destination: pin });
  // 0.00001° (about 1 m) away rounds to the same cache key.
  await maps.computeRouteFor(d, "u1", { origin: { lat: 31.52041, lng: 74.35871 }, destination: pin });
  assert.equal(g.calls.length, 1);
  assert.equal(db.data.mapsUsage.u1.routes, 1);
  clock += 6 * 60 * 1000; // past the 5-minute cache
  await maps.computeRouteFor(d, "u1", { origin: lahore, destination: pin });
  assert.equal(g.calls.length, 2);
});

test("quota: each user gets an hourly allowance per kind; it resets after the hour", async () => {
  const db = fakeDb({ mapsUsage: { u1: { windowStart: clock, routes: maps.LIMITS.perHour.routes, places: 0, geocode: 0 } } });
  const g = fakeGoogle(routeReply);
  const d = deps(g, db);
  await rejects(maps.computeRouteFor(d, "u1", { origin: lahore, destination: pin }), "resource-exhausted");
  assert.equal(g.calls.length, 0);
  // Another user is unaffected; so is another kind for the same user.
  await maps.computeRouteFor(d, "u2", { origin: lahore, destination: pin });
  await maps.reverseGeocodeFor({ ...d, fetch: fakeGoogle({ json: { status: "ZERO_RESULTS", results: [] } }).fetch }, "u1", { point: lahore });
  assert.equal(db.data.mapsUsage.u1.geocode, 1);
  clock += 61 * 60 * 1000;
  await maps.computeRouteFor({ ...d, cache: new maps.TtlCache() }, "u1", { origin: lahore, destination: pin });
  assert.equal(db.data.mapsUsage.u1.routes, 1, "new window");
});

// ── searchPlaces ───────────────────────────────────────────────────────────

const placesReply = {
  json: {
    places: [
      {
        displayName: { text: "Liberty Market" },
        formattedAddress: "Liberty Market, Gulberg III, Lahore, Pakistan",
        location: { latitude: 31.5106, longitude: 74.3448 },
        addressComponents: [{ longText: "Lahore", types: ["locality", "political"] }],
      },
      { displayName: { text: "Broken" }, formattedAddress: "Nowhere", location: { latitude: 0, longitude: 0 } },
      { displayName: { text: "No location" }, formattedAddress: "Somewhere" },
    ],
  },
};

test("places: text search in Pakistan, biased near a point, only the needed fields; bad entries dropped", async () => {
  const g = fakeGoogle(placesReply);
  const r = await maps.searchPlacesFor(deps(g), "u1", { query: "  liberty   market ", near: lahore });
  assert.deepEqual(r.places, [
    { name: "Liberty Market", label: "Liberty Market, Gulberg III, Lahore, Pakistan", city: "Lahore", lat: 31.5106, lng: 74.3448 },
  ]);
  const c = g.calls[0];
  assert.equal(c.url, "https://places.googleapis.com/v1/places:searchText");
  assert.equal(c.init.headers["X-Goog-FieldMask"], "places.displayName,places.formattedAddress,places.location,places.addressComponents");
  assert.equal(c.body.textQuery, "liberty market");
  assert.equal(c.body.regionCode, "PK");
  assert.equal(c.body.maxResultCount, 5);
  assert.deepEqual(c.body.locationBias.circle.center, { latitude: lahore.lat, longitude: lahore.lng });
});

test("places: query length is checked; empty results are fine", async () => {
  const g = fakeGoogle({ json: {} });
  await rejects(maps.searchPlacesFor(deps(g), "u1", { query: "ab" }), "invalid-argument");
  await rejects(maps.searchPlacesFor(deps(g), "u1", { query: "x".repeat(101) }), "invalid-argument");
  await rejects(maps.searchPlacesFor(deps(g), "u1", { query: 42 }), "invalid-argument");
  await rejects(maps.searchPlacesFor(deps(g), "u1", { query: "cafe", near: { lat: 200, lng: 0 } }), "invalid-argument");
  assert.equal(g.calls.length, 0);
  assert.deepEqual(await maps.searchPlacesFor(deps(g), "u1", { query: "zzzz nothing" }), { places: [] });
});

// ── reverseGeocode ─────────────────────────────────────────────────────────

test("geocode: address and city for a point; nothing found is null; errors are mapped", async () => {
  const g = fakeGoogle({
    json: {
      status: "OK",
      results: [{
        formatted_address: "Mall Rd, Lahore, Pakistan",
        address_components: [{ long_name: "Lahore", types: ["locality", "political"] }],
      }],
    },
  });
  const r = await maps.reverseGeocodeFor(deps(g), "u1", { point: lahore });
  assert.deepEqual(r.place, { name: "", label: "Mall Rd, Lahore, Pakistan", city: "Lahore", lat: lahore.lat, lng: lahore.lng });
  const url = new URL(g.calls[0].url);
  assert.equal(url.origin + url.pathname, "https://maps.googleapis.com/maps/api/geocode/json");
  assert.equal(url.searchParams.get("latlng"), `${lahore.lat},${lahore.lng}`);
  assert.equal(url.searchParams.get("language"), "en");

  assert.deepEqual(await maps.reverseGeocodeFor(deps(fakeGoogle({ json: { status: "ZERO_RESULTS", results: [] } })), "u1", { point: lahore }), { place: null });
  await rejects(maps.reverseGeocodeFor(deps(fakeGoogle({ json: { status: "REQUEST_DENIED" } })), "u1", { point: lahore }), "failed-precondition");
  await rejects(maps.reverseGeocodeFor(deps(fakeGoogle({ json: { status: "OVER_QUERY_LIMIT" } })), "u1", { point: lahore }), "resource-exhausted");
  await rejects(maps.reverseGeocodeFor(deps(fakeGoogle({ json: { status: "UNKNOWN_ERROR" } })), "u1", { point: lahore }), "unavailable");
  await rejects(maps.reverseGeocodeFor(deps(fakeGoogle({ json: {} })), "u1", { point: { lat: 0, lng: 0 } }), "invalid-argument");
});

test("helpers: duration parsing and straight-line distance", () => {
  assert.equal(maps.parseDuration("754s"), 754);
  assert.equal(maps.parseDuration("12.5s"), 12.5);
  assert.equal(maps.parseDuration("12"), null);
  assert.equal(maps.parseDuration(5), null);
  assert.ok(Math.abs(maps.straightKm(lahore, { lat: 33.6844, lng: 73.0479 }) - 270) < 6);
});

test("quota: a Firestore failure reads as 'try again' (unavailable), not a server bug", async () => {
  const g = fakeGoogle(routeReply);
  const brokenDb = { collection: () => ({ doc: () => ({}) }), runTransaction: async () => { throw Object.assign(new Error("down"), { code: 14 }); } };
  await rejects(maps.computeRouteFor({ db: brokenDb, fetch: g.fetch, key: KEY, now: () => clock, cache: new maps.TtlCache() }, "u1",
    { origin: lahore, destination: pin }), "unavailable");
  assert.equal(g.calls.length, 0);
});
