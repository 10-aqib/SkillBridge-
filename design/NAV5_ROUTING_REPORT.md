# SkillBridge — Navigation Phase 5: routing service and route on the map

Status: **implemented and checked locally. Nothing deployed, committed or pushed.** No Firestore rules, functions or data changed. Awaiting your approval for Phase 6.

## 1. Summary

| Area | Result |
|---|---|
| Route model | `lib/features/navigation/domain/entities/nav_route.dart`: <br>• `NavRoute`: line, metres, seconds, legs, summary; <br>• `RouteLeg`; <br>• `RouteStep`: maneuver, distance, time, geometry, road name or number, destinations, roundabout name; <br>• `Maneuver`: type, modifier, location, roundabout exit, bearings; <br>• `RouteResult`: primary route, alternatives, and how far each end was moved to reach a road. <br>All 16 OSRM maneuver types and 8 modifiers are mapped; anything new becomes `unknown` instead of breaking. |
| Routing interface | `RoutingService` (pure Dart) with `getRoute()`, `getAlternativeRoutes()`, `parseRouteSteps()`, `calculateDistance()` (road distance left along the route, never a straight line) and `estimateArrival()` (uses each step's own time). Errors are typed: invalid input, no route, too far from a road, network, timeout, unavailable, malformed; plus `isTransient`, which says whether retrying makes sense. |
| OSRM client | `OsrmRoutingService`: <br>• requests `steps=true`, `geometries=geojson`, `overview=full`, `alternatives=true` (lng,lat order); <br>• 15 s timeout, identifies the app; <br>• **at most 1 request a second to the public demo server** (its policy), unthrottled for a self-hosted server; <br>• 5-minute cache of the last 10 answers; <br>• reads OSRM's refusal codes from the body before the HTTP status. <br>The address and profile come from the build-time settings; if they're invalid, routing reports "unavailable". |
| Route geometry | `route_geometry.dart`: <br>• `RouteLine` snaps a position onto the route (distance off the route, distance along it, segment); <br>• it can search forward from the current segment, so a route that doubles back after a U-turn doesn't snap you backwards; <br>• `remainingDurationAt`, `estimateArrival`. <br>Phases 6–7 (progress, off-route) build on this. |
| On the map | `SbRouteLayer`: the chosen route in the primary colour with a casing, alternatives underneath in grey; readable in light and dark. |
| Nearby workers | Tapping a worker (chip or pin) draws the **road route** from OSRM again, and the card shows **"3.7 km by road · ~12 min"**. If routing fails, no line is drawn. Distances that aren't road distances now read only "500 m away". |

## 2. Problems found (fixed and tested)

1. **Points far from any road were "routed".** OSRM always moves a point to the nearest road, however far. In a live test a point in the Arabian Sea was moved **571 km**, producing a 1,451 km "route". The client now reads OSRM's own snap distances and refuses a route when either end had to move more than **2 km** ("too far from a road"). The recorded Lahore routes moved their points 91 m and 98 m.
2. **Nearby workers showed a made-up travel time.** The distance chip said "800 m • ~3 min away", worked out from the straight-line distance. The brief rules that out. Now it shows the road distance and the engine's time when a road route has loaded, and otherwise only "800 m away".
3. **Nearby workers restarted its data on every rebuild** (an older bug that this phase's test exposed). `GeoPointLocation` had no value equality, so the provider key (`NearbyWorkerParams`) changed on every build. The workers stream re-subscribed and the screen went back to "loading". In the app, tapping a worker (and now the route arriving) would have flashed the map back to the spinner and lost its position. Added `==`/`hashCode`; test added.
4. **The new road-distance label overflowed** the narrow worker card on a phone-width screen (by 1 px). It now wraps.

## 3. Checks

| Check | Result |
|---|---|
| `flutter test` | **392 / 392 passed**: 371 + 17 routing + 4 nearby-workers. |
| `dart analyze lib test` | **0 errors, 5 warnings, 28 infos**: no new issues. |
| `flutter build apk --debug` | **passed** (733 s) |
| `flutter build web --release` | **passed** (627 s) |
| **Live, from Dart** (a plain Dart script outside the repo using the app's OSRM client) | Model Town → Johar Town: 2 routes, 7,548 m, 9.9 min, 15 steps, in 0.94 s. Maneuvers and road names correct. Arabian Sea point refused as "too far from a road". This confirms the Windows `curl` TLS issue doesn't affect the app. |
| **Visual** (built-in browser, harness outside the repo, real OSRM and tiles) | The route and its alternative on real Lahore roads, framed to fit, in light and dark. Screenshots in `design/nav/nav5/screens/`. |
| Line endings | Kept: `nearby_workers_screen.dart` CRLF; the others LF; new files LF. |

The tests use three **real recorded OSRM answers** in Lahore (`test/fixtures/osrm/`):
- Minar-e-Pakistan → Badshahi Mosque: 9 steps, Urdu road names.
- Model Town → Johar Town: 2 alternatives, U-turn, on/off ramps, merge, roundabout, end of road.
- Gulberg → DHA: rotary "Hussain Chowk", exit 3.

They cover:
- every maneuver mapping and the lng/lat order;
- the request parameters and the cache;
- the 1-per-second limit on the demo server only;
- each error kind (NoRoute, NoSegment, InvalidQuery, 429, 502, bad JSON, no connection, timeout, far from road);
- the route line's length matching the engine's distance;
- snapping on and beside the route (50 m off);
- forward-only snapping on the doubled-back road;
- time left by step;
- arrival time;
- the nearby-workers route and failure UI.

## 4. Notes and limits
- **Times are car times without live traffic** (OSRM). Lahore traffic is often slower, so screens will say "about", and the arrival time will be labelled as an estimate (Phase 6).
- The public demo routes **cars only**. A motorbike profile needs a self-hosted OSRM (`ROUTING_PROFILE`).
- `GeoLocationUtil.formatInDriveDistanceEta` / `calculateEtaMinutes` (straight-line ETA) are no longer used by any screen. They're left in place because their own unit tests use them; they could be deleted later.
- The map reported in §3 was framed correctly. During the check you clicked in that tab, and the first screenshot showed it zoomed in; after a reload it was framed as expected.

## 5. Builds
Both passed, with temporary files on drive F: as in Phase 4. They were slower than last time (12 and 10 minutes) because the PC was short of memory; Gradle daemons were stopped afterwards.

## 6. Files

New:
- `lib/features/navigation/`:
  - `domain/entities/nav_route.dart`
  - `domain/route_geometry.dart`
  - `data/routing_service.dart`
  - `data/osrm_routing_service.dart`
  - `presentation/providers/routing_providers.dart`
  - `presentation/widgets/route_layer.dart`
- `lib/core/utils/request_spacer.dart`
- `test/unit/routing_test.dart`, `test/widget/nearby_workers_route_test.dart`
- `test/fixtures/osrm/gulberg_to_dha.json`, `model_town_to_johar_town.json`
- `design/nav/nav5/screens/`, snapshot `design/nav/.snapshot/nav5/`, this report

Changed:
- `nearby_workers_screen.dart`: road route, honest distance chip, wrapping.
- `nearby_worker_entity.dart`: value equality.
- `lib/core/map/geocoding.dart`: uses the shared request spacer (same behaviour; its tests pass).

## 7. Next: Phase 6 (turn-by-turn navigation screen)
- The navigation engine: progress along the route, current and next step, distance to the maneuver, remaining distance and time, arrival.
- The controller states: initializing, locating, calculating, ready, navigating, paused, arrived, cancelled, error.
- Instruction text from maneuvers in en + ur.
- The navigation screen: instruction card with arrow, map following the user with the heading arrow, bottom panel with distance, time, arrival time and End.
- Started from a test entry point until Phase 9 connects it to the job workflow.
