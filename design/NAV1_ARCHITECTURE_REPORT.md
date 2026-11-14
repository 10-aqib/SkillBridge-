# SkillBridge — Navigation Phase 1: project inspection and architecture report

Status: **inspection only. No code, rules, functions or dependencies were changed.** Nothing committed or deployed. The four decisions in §4 are answered; awaiting your approval to start Phase 2.

This track (maps, turn-by-turn navigation, live tracking) is separate from the redesign phases (1–4B). Its reports are named `design/NAV<n>_*.md`.

## 1. What the project already has

| Area | Finding |
|---|---|
| Stack | Flutter 3.44.4 / Dart 3.12.2. Riverpod 3 (`Notifier`, `StreamProvider`), go_router 17. Feature folders `features/<x>/{data,domain,presentation}`. Design system in `lib/shared/design_system` (`SbButton`, `SbInlineBanner`, `SbStatusBadge`, `showSbConfirmSheet`, `context.sb` tokens, `SbSpace`/`SbRadius`/`SbTypography`). Strings in en + ur ARB, with a parity test. |
| Backend | **Firestore only** (no Realtime Database). Firebase Auth, Storage, Cloud Functions (TypeScript, callable `contractActionCall` etc.), App Check, FCM. |
| Who can see a job's place | Since Phase 3A, **jobs store no exact map pin** (`jobs.location` is kept but new jobs write `null`). The job has only city + area. The exact address is `contracts/{id}.serviceAddress`: **free text**, shared privately by the client through `contractActionCall` → `shareAddress`. **There are no destination coordinates anywhere.** |
| Accepted-job workflow | `contracts/{id}`: `pending` → `active` (not started → in progress) → submitted → `completed`, or cancelled/declined. Written only by functions. `ContractEntity.stage` mirrors the server. The worker's and client's place for an accepted job is `ContractDetailsScreen`. |
| Live location (Phase 4B) | Already built and tested: `LiveLocationController` (`core/services/location_tracking_service.dart`) with pluggable `LocationSource` / `LiveLocationSink`, explicit consent, start/stop, ≤1 write per 15 s + 60 s heartbeat, skips offline fixes, stops when refused, stops on sign-out. Writes `contracts/{id}/live/location` = `{workerId, position, accuracy, updatedAt, startedAt}`. Rules: read by the two parties + staff; write by the hired worker only while active and not submitted, server time, key allowlist. Deleted by the function on submit/confirm/cancel/decline. The client panel shows "Live" only if updated < 2 min ago. |
| Google Maps today | `google_maps_flutter` is used in 4 places: `location_picker_screen.dart` (worker service-area setup, nearby-workers search), `nearby_workers_screen.dart` (map + Google Routes polyline), `live_location_ui.dart` (client's small map, only when a key exists), and the unused `worker_live_tracking_map.dart`. REST helpers `google_maps_service.dart`, `geocoding_service.dart`, `places_service.dart`, `routes_service.dart` all need `GOOGLE_MAPS_API_KEY`. **Without a key the picker shows a blank map with no working search**, so worker profile setup's "pick location" is effectively broken today. Android Gradle injects the key into the manifest; iOS `AppDelegate` calls `GMSServices.provideAPIKey`. |
| Location code | `LocationService` (static Geolocator wrapper with permission/timeout errors), `GeoLocationUtil` (haversine, accuracy levels, *straight-line* ETA), `location_provider.dart`, `LocationAccuracyBadge`. geolocator 13.0.4. |
| Platform | Android: `INTERNET`, `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`; no background location, no foreground service. iOS: `NSLocationWhenInUseUsageDescription` only. Debug manifest allows cleartext to localhost (emulator testing). |
| Dependencies to note | `http` is used by the Maps helpers but is **not** a direct dependency (it resolves transitively, 1.6.0). Not present: `flutter_map`, `latlong2`, `flutter_tts`, `wakelock_plus`. |
| Leftovers | Phase 3B `liveLocations/{workerId}` mirror (`profiles.ts`) and `worker_live_tracking_map.dart` + its test: unused since 4B, left in place. |
| Tests | 312 Flutter tests, 52 function tests, 124 rules tests (emulator) at the end of Phase 4B. Rules tests live in `rules-tests/`. |
| Working tree | ~250 uncommitted files on `ui-improvements-2026` (Phases 1–4B). |

## 2. Conflicts and gaps found

1. **No destination coordinates (blocker).** Navigation and the "destination" marker need a lat/lng. Inventing one from the city or area would be fake. A text address can't be routed without geocoding, and free Pakistani addresses geocode poorly. → Decision A.
2. **Google Maps in other screens.** The brief says "Google Maps-free" but also "don't change unrelated screens". The picker and nearby-workers map can't work without a key. → Decision B.
3. **The live-location schema has no heading or speed.** The rules' key allowlist refuses extra fields. Adding them needs a (small, still strict) rules change. → Decision C.
4. **Background tracking.** Today sharing works only while the app is open. Navigation keeps the app in the foreground anyway. Background location means `ACCESS_BACKGROUND_LOCATION`, an Android foreground service and a Play Store declaration. → Decision D.
5. **Public infrastructure limits.** The public OSRM server (`router.project-osrm.org`) is a demo with no availability guarantee, and has a car profile only. Public OSM tiles (`tile.openstreetmap.org`) require attribution, a real app identifier, and no heavy or offline use. The public Nominatim service forbids autocomplete and allows at most 1 request/s. All three will be **configurable at build time** (`--dart-define`), with the public endpoints as development defaults only.
6. **Git checkpoint vs your standing rule.** The brief asks for a git checkpoint; your rule is no commits. I'll do what earlier phases did: copy every file before its first edit to `design/nav/snapshot/` (same paths, line endings kept). Nothing touches git history.
7. **Urdu voice.** Instructions will be built from OSRM's maneuver data in our own en/ur strings (not OSRM's English text). Many phones have no Urdu TTS voice. Then the app says so once and continues visually (or in English if you prefer).

## 3. Proposed architecture

New feature folder `lib/features/navigation/`, using Riverpod and the existing conventions:

```
core/map/                       shared by every map in the app
  map_config.dart               tile URL, subdomains, attribution, user agent (dart-define)
  sb_map.dart                   FlutterMap wrapper: themed tiles, attribution, recenter, compass
  map_markers.dart              CurrentLocationMarker (animated, heading), DestinationMarker, PersonMarker
features/navigation/
  domain/
    route.dart                  NavRoute, RouteLeg, RouteStep, Maneuver (type, modifier, exit)
    geo_math.dart               point-to-polyline distance, progress along route, bearing
    navigation_engine.dart      pure Dart: step advance, remaining distance/ETA, off-route
                                (sustained + accuracy-aware), arrival, which line to speak when
  data/
    routing_service.dart        abstract RoutingService {getRoute, getAlternativeRoutes, ...}
    osrm_routing_service.dart   OSRM /route/v1 (steps, geojson, overview=full, alternatives),
                                timeouts, error types, response validation
    geocoding_service.dart      abstract; Nominatim-compatible impl (search on submit only,
                                throttled) and a "none" impl → map pick only
  presentation/
    navigation_controller.dart  Notifier: Initializing → Locating → Calculating → Ready →
                                Navigating ⇄ Rerouting/Paused → Arrived | Cancelled | Error
    voice_guidance.dart         flutter_tts wrapper: mute, de-duplication, locale, no speech
                                unless navigating
    navigation_screen.dart      top instruction card, map, bottom panel (distance, time, ETA, End)
    live_tracking_screen.dart   client: worker marker, destination, route, live/stale state
    widgets/                    instruction card, maneuver icon, route layer, state views
```

- **GPS**: one `LocationSource` (extends the existing one) gives position, accuracy, heading and speed. Navigation uses a 5 m distance filter. Sharing keeps its 15 s write limit. Nothing polls when no screen needs it. The screen stays awake only while navigating (`wakelock_plus`).
- **Sharing during navigation** reuses `LiveLocationController` (same consent, same stop button). It isn't a second system.
- **Arrival confirmation** reuses the existing `progressUpdate` action ("I've arrived"), and offers "Start work" if work hasn't started. No new backend action is needed.
- **Hirer route/progress**: the client's app asks OSRM for the worker→destination route itself, at most every 2 minutes or after 150 m of movement. Nothing extra is stored.
- **Routes**: two new go_router routes under contracts (navigate, track). No existing route changes.

New dependencies (exact versions resolved in Phase 2): `flutter_map`, `latlong2`, `flutter_tts`, `wakelock_plus`, and `http` made direct.

## 4. Decisions needed before Phase 2

| | Question | My recommendation |
|---|---|---|
| A | Where does the navigation destination come from? | When the client shares the exact address they also drop a pin on the map. `shareAddress` gets an optional validated `location`, stored as `contracts/{id}.serviceLocation`. Only the function writes it, and only the two parties can read the contract, so **no rules change** is needed for this. If the client hasn't pinned it, the worker can pick the point on the map for their own navigation (kept on the device, never shared). |
| B | How far does "Google Maps-free" go? | Replace **all** `google_maps_flutter` maps (picker, nearby workers, live map) with the shared flutter_map widget. Then remove the package and the key wiring (Gradle placeholder, manifest meta-data, `AppDelegate`). This fixes the broken picker and ends the exposed-key risk in builds. Keep the Google REST helpers only if you want them as optional providers; otherwise delete them. |
| C | Live-location fields | Add optional `heading` (0–360) and `speed` (0–100 m/s) to the rules' allowlist for `contracts/{id}/live/location`, with rules tests. Everything else is unchanged and stays as strict. |
| D | Background tracking | No background location. Sharing and navigation run while the app is open, with the screen kept awake during navigation. When the app goes to the background, navigation pauses and the client sees "Not live" after 2 min, as today. |

**Your answers (13 Nov 2026): A, B, C and D as recommended.** The client pins the destination; all Google maps are replaced and the package and key wiring removed; heading and speed are added to the live-location allowlist; foreground only.

Optional (off unless you ask): a scheduled function that deletes live-location documents not updated for 6 hours, for apps that were killed while sharing. It needs Cloud Scheduler (Blaze plan) and a collection-group index.

## 5. Phase plan (Phases 2–10)

| Phase | Work | Backend changes (local only, never deployed) |
|---|---|---|
| 2 | Snapshot, dependencies, `MapConfig`/`RoutingConfig`/`GeocodingConfig` dart-defines, `.env.example` entries, Android/iOS location strings, `flutter analyze` + full test baseline | — |
| 3 | `SbMap`, markers, attribution, recenter, compass, loading/offline/tile-error states; migrate maps per decision B | — |
| 4 | Location source with heading/speed, accuracy and timeout handling, settings deep links, stale-fix detection | — |
| 5 | `RoutingService` + OSRM implementation, route layer, alternatives, distance/ETA. Unit tests on a recorded OSRM response | — |
| 6 | Navigation engine + controller + navigation screen and all states | — |
| 7 | Voice guidance (distance-based announcements, de-duplication, mute), off-route detection and rerouting with cooldown | — |
| 8 | Live sharing integration (heading/speed), geocoding search and map pick, `serviceLocation` | `shareAddress` location (function + tests); live rules keys (+ rules tests) |
| 9 | Hirer live tracking screen; worker contract actions (View on map, Start navigation, share/stop, arrived) | — |
| 10 | Security review, regression (all suites), emulator end-to-end, Android build, report | — |

Each phase ends with a short `design/NAV<n>_*.md` report and a stop for your approval, as before.

## 6. How it will be verified, and the limits

- **Unit tests** (pure Dart): OSRM parsing (from a recorded real response), geometry, step advance, off-route rules (noise, GPS loss, sustained deviation, cooldown), announcement scheduling, arrival.
- **Widget tests**: navigation and tracking screens, with fake location and routing sources, in every state.
- **Rules and function tests** on the emulators for the two backend changes, including outsiders being refused.
- **End to end** on the emulators (production hosts blocked, as before). It uses real tiles and real OSRM over the network. GPS movement is supplied **by the test harness only** (Chrome DevTools geolocation in the web build, a GPX route on the Android emulator). The app itself contains no simulated location.
- **Can't be verified by me**: real driving on a phone, real GPS noise, and spoken audio quality. I'll say exactly which checks were simulated.
