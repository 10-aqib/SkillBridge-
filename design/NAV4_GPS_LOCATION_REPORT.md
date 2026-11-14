# SkillBridge — Navigation Phase 4: GPS location services

Status: **implemented and checked locally. Nothing deployed, committed or pushed.** No Firestore rules, functions, data or screens changed, apart from one button fix (§1, last row). Awaiting your approval for Phase 5.

## 1. Summary

| Area | Result |
|---|---|
| One location source | `lib/core/location/device_location.dart`. The Phase 4B `LocationSource` now gives everything navigation needs: <br>• access check without asking, and with asking; <br>• precise vs approximate location (Android 12+, iOS 14+); <br>• one fix with a time limit; a continuous stream per profile; <br>• GPS switched on/off events; <br>• whether settings can be opened at all (not in a browser). <br>Live sharing and the new tracker use the same source (`locationSourceProvider`), so there is no second location system. |
| Fix model | `GeoFix`: position, accuracy, heading, heading accuracy, speed, speed accuracy, altitude, time, mock flag. <br>• Invalid platform values (iOS −1; Android "0° accuracy 0" while still) become "unknown", not numbers. <br>• Heading counts as reliable only above about 5 km/h and with an accuracy of 45° or better. <br>• Impossible coordinates (NaN, out of range, 0/0) are invalid. |
| Battery profiles | **display** (maps): high accuracy, 15 m, every 5 s. **sharing**: high accuracy, 10 m, every 5 s (the 15 s write limit is unchanged). **navigation**: best accuracy, 5 m, every 1 s; on iOS the driving mode, never paused. <br>Every profile is **foreground only**. On iOS background updates are switched off explicitly; geolocator's default is *on*. On the web, cached browser positions are refused. |
| Tracker | `lib/core/location/device_location_tracker.dart` (`deviceLocationProvider`), used from Phase 6 by the map and navigation screens. <br>• Asks for permission and reports denied, blocked, GPS off or unavailable. <br>• Follows GPS being switched off and back on while in use. <br>• Drops invalid, out-of-order, long-cached and impossible fixes (faster than 250 km/h beyond both error circles). <br>• Marks the signal **lost** when no fix arrives in time (12 s while navigating), so the last position is kept but never shown as current. <br>• Restarts once if the platform ends the stream. <br>• Pauses in the background and resumes in the foreground. <br>• Stops when no screen uses it. |
| Live sharing hardened | Positions are written only if valid and taken in the last **30 s**. Before, a cached fix from minutes ago could be written, and because the server stamps each write with its own time, it would show as "Live". Sharing uses the `sharing` profile. |
| "Open settings" on the web | The Phase 4B sharing panel no longer shows an "Open settings" button in a browser, where it couldn't do anything. This was the follow-up noted in NAV3. |

## 2. Checks

| Check | Result |
|---|---|
| `flutter test` | **371 / 371 passed**: 345 + 24 new location tests + 2 new sharing tests (an old cached fix is never written; no settings button where settings can't open). |
| `dart analyze lib test` | **0 errors, 5 warnings, 28 infos**: no new issues. |
| `flutter build apk --debug` | **passed** (219 s) |
| `flutter build web --release` | **passed** (189 s) |
| Real web plugin (built-in browser, harness outside the repo) | Location is blocked in the pane. The real Geolocator web plugin reported `deniedForever`. The tracker went to `permissionBlocked` with no fix and no position shown, and no settings button is offered on the web. No console errors. Screenshot: `design/nav/nav4/screens/01-web-blocked-location-tracker-state.png`. |
| Line endings | All edited files kept LF; new files are LF. |

What the tests cover, all with a fake device source and the test framework's fake clock:
- every access result;
- fixes appearing;
- approximate-only location reported;
- signal lost after the profile window, then restored;
- glitch, out-of-order and invalid fixes dropped;
- GPS off and on mid-use;
- the "services disabled" stream error;
- background pause and resume;
- the platform ending the stream (one restart);
- `stop()`, and auto-dispose when the last screen leaves;
- switching profiles;
- platform settings per profile (Android interval, iOS background off and driving mode, web no cache);
- GeoFix parsing and bearings.

**Not verified:** a real phone's GPS (no device is attached, and the browser pane blocks location). Real movement, heading and signal loss will be exercised in Phase 10 on the Android emulator with a GPX route; that movement comes from the test tool, not from the app.

## 3. Problems found
1. **`GeoFix.toString` crashed on an infinite accuracy value.** The tracker logs every dropped fix, so one bad reading from a device would have thrown. Found by a test; fixed so it is safe for any value.
2. **Old cached positions could reach live sharing** (§1). Fixed, with a test.

## 4. Not changed (noted for later)
- `location_provider.dart` (used only by nearby workers) and the static `LocationService` (used by the picker) still do their own permission checks. They work; folding them into the shared source is a small cleanup that doesn't change behaviour, best done when those screens are next touched.
- Live sharing still writes only position and accuracy. Heading and speed are added in Phase 8, together with the rules change you approved.

## 5. Builds
Both builds and the tests ran with temporary files on drive F: (`build/nav_tmp`, deleted afterwards), because drive C: keeps filling up (see NAV3 §4.4). Gradle daemons were stopped after the build to free memory.

## 6. Files

New:
- `lib/core/location/device_location.dart`, `device_location_tracker.dart`
- `test/unit/device_location_test.dart`
- `design/nav/nav4/screens/`, snapshot `design/nav/.snapshot/nav4/`, this report

Changed:
- `lib/core/services/location_tracking_service.dart`: the source moved out, re-exported for existing imports; fix age and validity checks; `sharing` profile.
- `live_location_ui.dart`: settings button only where it works.
- `test/widget/contracts_4b_test.dart`: fakes updated to the new interface; 2 tests added.

## 7. Next: Phase 5 (routing)
`RoutingService` with an OSRM implementation:
- route geometry, distance, duration, legs, steps and maneuvers, alternatives;
- network, unavailable and malformed-response errors;
- parser tests against the recorded Lahore route, and a live check from Dart (to confirm the Windows `curl` TLS issue doesn't affect the app);
- the route line on the map, and the nearby-workers road route restored.
