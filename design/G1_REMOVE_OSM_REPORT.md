# SkillBridge — Track G, Phase G1: remove the OpenStreetMap stack

Status: **done, awaiting your approval for G2 (Google Maps in the app).** Nothing committed, deployed or pushed. Firestore rules, functions and the data model are untouched.

Date: 21 Nov 2026 · Branch `ui-improvements-2026` · Snapshot of every touched file: `design/nav/.snapshot/g1/`

Your choices from G0 applied here: **D2 (a)**. In-app turn-by-turn navigation (voice, rerouting, turn list) is removed; driving directions now hand off to Google Maps.

---

## 1. What was removed

| Kind | Removed |
|---|---|
| Packages | `flutter_map`, `latlong2`, `flutter_tts`, `wakelock_plus` (`pubspec.lock`: 16 dependencies gone, −128 lines). `http` stays, because the image upload client uses it. |
| Map core | `lib/core/map/sb_map.dart` (OSM tile map), `map_markers.dart`, `map_config.dart` (tile, OSRM and Nominatim settings), `geocoding.dart` (Nominatim client), `lib/core/utils/request_spacer.dart` (Nominatim/OSRM rate limiter, no other users) |
| Routing + navigation | `osrm_routing_service.dart`, `routing_service.dart`, `nav_route.dart`, `route_geometry.dart`, `navigation_engine.dart`, `off_route_detector.dart`, `announcement_planner.dart`, `navigation_controller.dart`, `routing_providers.dart`, `voice_guidance.dart`, `screen_awake.dart`, `nav_text.dart`, `navigation_screen.dart`, `nav_panels.dart`, `route_layer.dart` |
| Tests | `fake_map_tiles.dart`, `fake_navigation.dart`, `geocoding_test`, `map_config_test`, `navigation_controller_test`, `navigation_engine_test`, `routing_test`, `voice_and_reroute_test`, `navigation_screen_test`, `nearby_workers_route_test` |
| Android | The text-to-speech `<queries>` entry in `AndroidManifest.xml` (only `flutter_tts` needed it). Location permissions are kept. |
| Config | `MAP_TILE_*`, `ROUTING_*` and `GEOCODING_*` from `.env.example`, plus the old "Google Maps is no longer used" note |
| Strings | 86 English / 73 Urdu turn-by-turn strings (maneuvers, compass points, voice, rerouting, OSM attribution). Strings that G2/G3 reuse were kept: distance and time formats, route errors, search hints, "arrives about". |
| Stray key | `ios/Flutter/GoogleMaps.local.xcconfig` (git-ignored, never committed, an old key) **moved out of the repo** to my session scratchpad rather than deleted. **Please delete or restrict that key in Google Cloud console.** |

Total: 59 files changed, +354 / −7,830 lines.

Verified gone: `git grep` finds no `flutter_map`, `latlong2`, `flutter_tts`, `wakelock`, `osrm`, `nominatim` or `openstreetmap` outside `design/` and third-party `node_modules` data. The new hygiene test enforces this for `lib/`, `pubspec.yaml` and `.env.example`.

## 2. What was added or changed

| File | Change |
|---|---|
| `lib/core/location/geo_coord.dart` (new) | `GeoCoord`: a lat/lng type that belongs to no map SDK. Includes validity checks (finite, in range, not 0,0), haversine `distanceMetres`, `bearingBetween`, and the `lat,lng` URL form. Contracts, the location picker and GPS fixes use it instead of `latlong2.LatLng`. In G2 the Google map widget converts it at its edge. |
| `lib/core/map/maps_links.dart` (new) | `GoogleMapsLinks.place()` / `.directions()`: the documented Google **Maps URLs** (no key), opened in the Google Maps app if installed, otherwise the browser. Replaces the old `geo:` / Apple Maps / openstreetmap.org links. |
| `lib/core/map/map_unavailable.dart` (new) | `SbMapUnavailable` (moved out of the deleted `sb_map.dart`), plus a standard variant with the existing "Map unavailable" wording. |
| `contract_navigation_screen.dart` | The worker's **Directions** screen. It shows the destination and its coordinates, a **"Directions in Google Maps"** button (disabled when the client hasn't pinned a place), the live-sharing toggle (same consent flow), and "Tell the client I've arrived" + "Start work". No GPS stream runs unless sharing is on. |
| `contract_tracking_screen.dart` | The client's view of the worker: live/not-live badge, last update, accuracy, an "arrived" banner (within 60 m of the pin), and **Open in Google Maps**. The OSRM road distance and ETA are gone; G3 brings them back from the Google Routes API. |
| `live_location_ui.dart` | Live-position and pinned-place previews keep their coordinates and the "Open in maps" / "View on map" buttons, now pointing at Google Maps. |
| `location_picker_screen.dart` | **Interim GPS-only picker:** it uses the device's position, or keeps the place already chosen. Every permission, GPS-off and failure state is explained, and invalid fixes are refused. Picking on a map arrives in G2; address search in G3. |
| `nearby_workers_screen.dart` | List view unchanged. The map view shows the placeholder above the worker strip. The distance chip shows straight-line distance only (no made-up travel time). |
| ARB files | New `navOpenGoogleMaps` ("Directions in Google Maps" / "گوگل میپس میں راستہ"); generated localizations rebuilt. |
| `config_hygiene_test.dart` | The old "Google Maps must be absent" test became two tests. One forbids OSM, OSRM, Nominatim, TTS and wakelock; the other forbids any Google API key (`AIza…`) in tracked platform config, so keys only ever come from the git-ignored `.env`. |

**Interim state, on this branch only:** every map area shows "Map unavailable" until G2. No screen is broken, no button does nothing, and directions still work through Google Maps.

## 3. Tests actually run

| Check | Result |
|---|---|
| `flutter pub get` | OK; 16 dependencies removed |
| `flutter gen-l10n` | OK |
| `dart analyze lib test` | **0 errors.** 5 warnings plus infos, all in files G1 didn't touch (they were there before). One unused import that G1 created was fixed. |
| `flutter test` (full suite) | **409 passed, 0 failed** (2 min 34 s) |
| Rewritten tests | Picker: GPS confirm with accuracy, kept place, 4 permission/GPS states, (0,0) refused, retry. Google Maps link format. `GeoCoord` validity and distance. Worker directions: guard, no-pin disabled, consent → sharing, arrival note, start work. Client tracking: live, stale, not sharing, no pin, arrived, client-only. |
| Android debug APK | See §5 |
| Line endings | Every touched file keeps its original CRLF/LF style (checked against the snapshot). |

One real issue found while testing: the "Sent to the client" snack bar briefly covers the "Start work" button on the directions screen. The test waits it out; G2's layout pass can move the confirmation inline.

## 4. Not done in G1 (by plan)
- No Google Maps yet (G2), no Routes/Places (G3, needs Blaze + server key).
- Docs still describing OSM (`README.md`, `MAPS_INTEGRATION_CHECKLIST.md`, NAV reports) are updated in the final docs phase (G8). The NAV reports stay as history.
- Firestore `liveLocations` still accepts heading and speed; that's harmless, and G2 can draw heading on the marker.

## 5. Android debug build
`flutter build apk --debug`: **built** (`build/app/outputs/flutter-apk/app-debug.apk`, 181 MB). The native side compiles without the removed plugins. Not run on a device or emulator in G1; there's nothing new to see on screen until G2 adds the map. A release build wasn't made; it comes in G7.

## 6. Next: G2 needs from you
1. An **Android Maps key** restricted to package `com.skillbridge.skill_bridge` + your debug (and later release) SHA-1, API: *Maps SDK for Android* only. Is the key already in `.env` that one? If so, restrict it before G2's first build, because the build compiles it into the APK.
2. D1 (Blaze active?), D3 (Storage instead of Cloudinary) and D4 (saved jobs / account deletion) are still open, but G2 doesn't depend on them.
