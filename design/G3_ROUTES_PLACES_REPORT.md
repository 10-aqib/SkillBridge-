# SkillBridge — Track G, Phase G3: road routes, place search and addresses

Status: **code done and tested locally; NOT deployed** (needs Blaze + your go-ahead + a server key). Awaiting approval for G4. Nothing committed or pushed; production rules and data untouched.

Date: 21 Nov 2026 · Branch `ui-improvements-2026` · Snapshot of files before G3: `design/nav/.snapshot/g3/`

---

## 1. Server: three callable functions (`functions/src/maps.ts`)

| Function | Google API | Returns |
|---|---|---|
| `computeRoute` | **Routes API** `computeRoutes`. Field mask `routes.distanceMeters,routes.duration,routes.polyline.encodedPolyline`; `TRAFFIC_UNAWARE` (basic SKU), no alternatives | `{distanceMeters, durationSeconds, polyline}` |
| `searchPlaces` | **Places API (New)** Text Search. Field mask `places.displayName,places.formattedAddress,places.location,places.addressComponents`; region PK, English, max 5, biased within 50 km of the device or map | `{places: [{name, label, city, lat, lng}]}` |
| `reverseGeocode` | **Geocoding API** (latlng → address) | `{place: {label, city, …} | null}` |

How each call is protected:
- **Sign-in first.** Unsigned calls get `unauthenticated` before anything else, verified on the emulator. The first version checked the key first; the emulator check caught that and it was fixed.
- **Validation:** coordinates finite, in range and not 0,0; routes at most 300 km straight-line; search text 3–100 chars; travel mode DRIVE / TWO_WHEELER / WALK only. Bad input never reaches Google.
- **Key:** `MAPS_SERVER_KEY` from **Secret Manager** (`defineSecret`). It is never in the app, the repo or logs. Without it the functions answer `failed-precondition`, and the app hides these features.
- **Cost control:**
  - A per-user hourly limit (routes 120, places 60, geocode 120) is stored in `mapsUsage/{uid}`. That collection is server-only: a new rules test proves clients can't read or write it, even their own.
  - A per-instance cache: routes 5 min (about 10 m rounding), search and addresses 24 h. Cache hits don't count toward the limit or call Google.
  - `maxInstances: 5`, 256 MiB, 20 s timeout.
- **Errors:**
  - Google 401/403 → `failed-precondition` (logged as "check the API is enabled and the key restrictions").
  - 429 → `resource-exhausted`. Network or 5xx → `unavailable`. No route → `not-found`.
  - Unusable responses are rejected (bad duration, negative distance, empty polyline).
  - A Firestore failure in the quota step → `unavailable` (found on the emulator, fixed).
- **Logs** hold status codes only: never the key, coordinates or search text.

## 2. App

| Piece | Change |
|---|---|
| `lib/core/map/maps_api.dart` | `MapsApi` with `route`, `search`, `reverse`, calling the functions. It decodes Google's polyline and keeps small client caches (routes 2 min, addresses 1 h). Errors map to plain reasons (not available, offline, no route, busy, invalid). **If the functions aren't deployed** (or Firebase is missing), the first call turns the features off for the session and every screen falls back to its G2 behaviour. |
| `lib/core/map/route_format.dart` | Distance (10 m / 50 m steps, then km) and time (rounded up, h + min) in English and Urdu, using the existing strings. |
| **Client tracking** | Road route from the worker's **live** position to the pin: polyline, "4.2 km by road · about 13 min", "Arrives about 3:42 PM", and the estimate note. Re-asked only after a 150 m move or 2 minutes; never for a stale position; after a failure it waits 2 minutes, and "The road distance isn't available right now" is shown. |
| **Worker directions** | If location is **already allowed** (the screen never asks), one GPS fix → the route from there: polyline, camera frames the whole route, "x km by road · about y min" in the panel. "Directions in Google Maps" still does the driving. |
| **Nearby workers** | Selecting a worker asks for the road route from the search centre: polyline, camera fit, and the chip shows "x km by road · ~n min" (otherwise straight-line "x km away"). |
| **Location picker** | Search box (submit only, ≥ 3 chars) → up to 5 Google results with the required "Results from Google Maps" attribution (new string, English and Urdu). Choosing one moves the map and fills the address. The pin's address is looked up **once the map settles** (700 ms, and not again for the same spot), and confirming returns Google's address and city. The old address is never reused after the map moves. Without the server: no search box, coordinates stand in for the address, as before. |

## 3. Verification actually done

| Check | Result |
|---|---|
| `functions`: `tsc --noEmit` + `npm test` | **65 passed / 0 failed** (11 new maps tests with a fake Google `fetch`: field masks, request bodies, validation, error mapping, zero-length routes, caching, hourly limits per user and kind, window reset, places filtering, geocode statuses, quota-store failure). |
| Rules tests (Firestore + Storage emulators) | **165 passed / 0 failed**, including the new `mapsUsage` server-only test. |
| Functions emulator (demo project, placeholder secret, **no Google call made**) | All three callables load. Results: signed out → 401 `UNAUTHENTICATED`; (0,0) / >300 km / 2-char search / lat 95 → 400 `INVALID_ARGUMENT` with clear messages; a missing function → 404 (the app treats this as "not deployed"); Firestore unreachable → 503 `UNAVAILABLE`. The placeholder secret file was deleted afterwards, and `.secret.local` is now git-ignored in `functions/`. |
| `dart analyze lib test` | **0 errors**; no new warnings. |
| `flutter test` (full suite) | **443 passed, 0 failed** (G2: 427). New tests: polyline decoding (Google's documented example + truncated input), no-Firebase fallback, invalid input never calls, distance/time formats. Picker: Google address for the GPS spot, re-lookup after moving, search on submit only with attribution, choose → move + confirm, no results / service down, no search box without the server. Tracking: route + distance + arrival time, reuse under 150 m, re-ask past 150 m, no route when stale, failure message. Directions: route from GPS when allowed, no GPS request when not allowed. |
| Build output | `npm run build` regenerated `functions/lib`, which is partly tracked; restored to its previous state. |
| **Not done** | No real Google responses: needs the deployed functions + server key. No APK rebuild in G3 (Dart-only changes, analyzer + tests cover them; G7 builds debug + release). Nearby-workers routing has no widget test (that screen needs a large provider setup; logic mirrors tracking). |

## 4. ⚠️ Deployment: what to know before anything goes live

1. **Blaze must actually be on.** The Cloud Functions API was still disabled on 21 Nov.
2. **Deploy only the three new functions:**
   ```
   firebase deploy --only functions:computeRoute,functions:searchPlaces,functions:reverseGeocode
   ```
   **Never `--only functions` on its own.** `functions/src/index.ts` still exports the old pre-free-plan triggers (`onChatMessageCreated`, `syncJobProposalCount`, `aggregateReviewRating`, …). The app now does that work in transactions, so deploying them would **double-count** unread messages, proposal counts and ratings. G5 decides what happens to them; until then they must not be deployed.
3. **Server key** (you create it; I can't). Google Cloud console → Credentials → API key:
   - API restrictions: **Routes API, Places API (New), Geocoding API** only. Enable those three APIs on the project.
   - Application restrictions: none (server key; it never leaves Secret Manager).
   - Then run `firebase functions:secrets:set MAPS_SERVER_KEY` and paste it at the prompt yourself, not in chat or any file.
4. **Budget alert:** set one in Cloud Billing (e.g. US$5 / month) before deploying.

## 5. Decisions for you
1. **Approve G4 (Firebase Storage for photos)?** Same Blaze dependency; it replaces the unconfigured Cloudinary path (D3).
2. Optional: deploy the three maps functions now (once Blaze, APIs and secret are ready), so G3 can be checked on your phone with real routes. That needs your explicit go-ahead at that point.
3. Still open: D4 (saved jobs / account deletion), D6 (job location before applying).
