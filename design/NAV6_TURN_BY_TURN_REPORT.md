# SkillBridge — Navigation Phase 6: turn-by-turn navigation screen

Status: **implemented and checked locally. Nothing deployed, committed or pushed.** No Firestore rules, functions or data changed. No existing screen or route changed: the navigation screen isn't linked from the app yet. Phase 9 adds the "Start navigation" button on the accepted job, along with the check that only the hired worker can open it. Awaiting your approval for Phase 7.

## 1. Summary

| Area | Result |
|---|---|
| Navigation engine | `domain/navigation_engine.dart` (pure Dart). Each GPS position is placed on the route, giving: <br>• the step being driven and the next maneuver; <br>• road metres to it; <br>• road distance and time left, from the engine's own step times; <br>• the arrival time; <br>• how far you are from the route (Phase 7 off-route detection uses this); <br>• arrival. <br>It searches forward from your last position, so a route that comes back along the same road after a U-turn is followed correctly. GPS jitter of up to 25 m backwards doesn't undo progress, and a maneuver counts as passed only 8 m after its point, so the instruction doesn't flicker at junctions. |
| Arrival | Arrived when ≤ 30 m of road is left. "As the crow flies" arrival counts only near the end of the route (≤ 150 m of road left), close to the route, allowing for GPS error. Once arrived, it stays arrived. |
| Directions text | `presentation/nav_text.dart`. Text is built from the routing engine's maneuver data, in **English and Urdu**: <br>• turn, bear and sharp turns; U-turn; continue; merge; ramps; exits; keep left/right; end of road; <br>• roundabouts and rotaries with the exit number and the chowk's name ("At Hussain Chowk, take exit 3 onto MM Alam Road"); <br>• "Head west"; arrive left/right; <br>• road names kept as given (Urdu names too). <br>Distances: 10 m steps to 300 m, 50 m steps to 1 km, then km. Times: rounded up, "Under 1 min", "3 h 2 min". 76 new strings in en + ur. |
| Arrows | Material maneuver icons. **U-turns and roundabouts follow Pakistan's keep-left traffic**. The public OSRM server labels Lahore steps "right", which is wrong, so the app trusts a step's own value only when it says left. |
| Controller | `navigation_controller.dart` (one session per screen). States: **initializing → locating → calculating → ready → navigating ⇄ paused → arrived**, plus **cancelled** and **error**; **rerouting** is reserved for Phase 7. <br>• The route always starts from the **real GPS position**. <br>• Errors are told apart: no destination, permission denied, blocked, GPS off, no fix in 25 s, no road route, too far from a road, offline, routing unavailable. <br>• Background pauses guidance and the foreground resumes it; a lost signal is flagged while guidance continues. <br>• The screen is kept on only while guiding. <br>• GPS stops on arrival and on End. |
| Screen | `navigation_screen.dart`, a full-screen map: <br>• **Before starting:** the route(s) framed above a sheet with each option's time, distance and roads ("Via …"), "Fastest"/"Alternative", the estimate note, and Start. <br>• **Guiding:** the instruction card on top (arrow, distance or "Now", instruction, and a "Then …" hint when the next maneuver follows within 150 m); the map follows you **course-up** with you low on the screen; a navigation arrow puck; the bottom panel with time left, distance left, arrival time and **End** (asks first). <br>• Moving the map by hand stops following until Recenter. <br>• Banners for lost signal, approximate location, and resuming after the background. <br>• **Arrived** panel; **problem** panel with the right fix (Try again / Open settings, never offered on the web); back button guarded while guiding. <br>• Coming back from Settings retries by itself. |

## 2. Problems found while building (all fixed, with tests)

1. **The screen could stay on after leaving mid-trip.** When the session was disposed without End, releasing the keep-awake read a provider during disposal, which Riverpod forbids (it asserted). The handle is now kept from when it was switched on. Test: closing mid-trip lets the screen sleep.
2. **End didn't close the screen.** The back guard still saw the "guiding" state for one more frame, so `maybePop` was refused and the confirm sheet would have come back. Closing now uses `pop`. Test added.
3. **The heading arrow vanished in course-up mode.** The dot's heading cone pointed straight up along the route line, in the same blue (seen in the browser check). While navigating the position is now an **arrow on a white disc**, which stays visible.
4. **Urdu arrival time read "12:12 p".** The `intl` package's Urdu 12-hour format ends in a bare "p". Urdu now uses 24-hour time ("12:12", "17:40"). Test added. The same `intl` format is used in the Phase 4B live-location panel for updates older than an hour (unchanged here).
5. **Hardening: early "arrival" when a road passes behind the destination.** Not seen on the recorded routes (the closest earlier approach is 131 m), but possible on others. Straight-line arrival now also needs ≤ 150 m of road left. Test on a route that passes 20 m from its end at the start.

## 3. Checks

| Check | Result |
|---|---|
| `flutter test` | **423 / 423 passed**: 392 + 31 new (12 engine/text, 12 controller, 7 screen). |
| `dart analyze lib test` | **0 errors, 5 warnings, 28 infos**: no new issues. |
| `flutter build apk --debug` | **passed** (331 s) |
| `flutter build web --release` | **passed** (539 s) |
| **Visual: simulated drive** (built-in browser; harness outside the repo; real OSRM route and real tiles; **only the GPS simulated by the harness**) | Minar-e-Pakistan → Badshahi Mosque: <br>• route choice, then Start; <br>• guidance course-up with the arrow ("850 m · Turn left", 11 min, 3.6 km, arrival time); <br>• counting down ("200 m · Turn left", 9 min, 2.9 km); <br>• "You have arrived". <br>In Urdu, RTL: "850 میٹر · بائیں مڑیں" (the left-turn arrow doesn't mirror). Screenshots in `design/nav/nav6/screens/`. Screenshot 06 shows the "p" time from problem 4, before the fix. |
| Line endings | All new and edited files LF, matching the originals. |

What the tests cover:
- **Engine** (on the three recorded Lahore routes):
  - starting values;
  - a full drive with GPS noise, where steps never go back, distance left never grows, and every maneuver is reached;
  - the countdown to a turn and the reset after it;
  - jitter at a junction;
  - far from the route;
  - arrival, and arrival sticking;
  - the U-turn road followed correctly;
  - no early arrival on a route passing behind the destination.
- **Text:**
  - the English for every recorded maneuver, including the U-turn, ramps, merge, end of road, roundabout and the Hussain Chowk rotary;
  - Urdu for every step, never left in English;
  - compass words, distances, times, arrows.
- **Controller:** every state and error; a full trip with the screen held and released; offline vs service trouble; choosing an alternative; background pause and resume; lost signal; End; closing mid-trip.
- **Screen:** route choice; guiding; arrival; End confirm; no destination; location blocked; no route then Try again; Urdu.

## 4. Notes and limits
- **Not yet reachable in the app.** Phase 9 adds "Start navigation" to the accepted job, using the destination the client pins (Phase 8).
- **No voice, no automatic rerouting yet.** If you leave the route now, the distance from the route is tracked, but the route isn't recalculated. Phase 7 adds spoken instructions, off-route detection and rerouting; the `rerouting` state and the busy panel are already in place.
- **The end of the route is the nearest road to the destination.** In the check, OSRM placed the end on the access road about 98 m from the mosque pin. Arrival is announced there. Phase 9 can add "walk the last X m".
- **Times are car times without live traffic**, labelled as estimates on screen.
- The map jumps to each new fix (about once a second) rather than gliding; smoothing can come later if wanted.

## 5. Builds
Both passed, with temporary files on drive F:; Gradle daemons were stopped afterwards.

## 6. Files

New (`lib/features/navigation/`):
- `domain/navigation_engine.dart`
- `presentation/nav_text.dart`
- `presentation/providers/navigation_controller.dart`, `screen_awake.dart`
- `presentation/screens/navigation_screen.dart`
- `presentation/widgets/nav_panels.dart`

New tests and other:
- `test/unit/navigation_engine_test.dart`, `navigation_controller_test.dart`
- `test/widget/navigation_screen_test.dart`
- `test/helpers/fake_navigation.dart`, `fake_location.dart` (the latter moved out of the Phase 4 test)
- `design/nav/nav6/screens/`, snapshot `design/nav/.snapshot/nav6/`, this report

Changed:
- `nav_route.dart` and `osrm_routing_service.dart`: driving side.
- `lib/core/map/map_markers.dart`: dimmed and arrow options.
- ARB files and generated l10n.
- `test/unit/device_location_test.dart`: uses the shared fake.

## 7. Next: Phase 7 (voice guidance and rerouting)
- **Voice** with flutter_tts:
  - announcements at sensible distances (early, near, at the turn), each said once;
  - "approaching" and "arrived";
  - mute/unmute;
  - only while navigating;
  - Urdu voice where the device has one, otherwise a one-time notice.
- **Off-route detection:** sustained and accuracy-aware, ignoring GPS loss.
- **Rerouting** from the latest position, with a cooldown and an announcement.
