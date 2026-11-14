# SkillBridge — Navigation Phase 7: voice guidance, off-route detection and rerouting

Status: **implemented and checked locally. Nothing deployed, committed or pushed.** No Firestore rules, functions or data changed. The navigation screen is still not linked from the app (Phase 9). Awaiting your approval for Phase 8.

## 1. Summary

| Area | Result |
|---|---|
| Voice | `voice_guidance.dart`: `Speaker` (flutter_tts behind an interface) and `NavigationVoice`. <br>• Spoken in the **screen's language** from the same en/ur texts as the screen ("In 500 metres, turn left onto Ravi Road" / "500 میٹر بعد، بائیں مڑیں"). <br>• Distances in words ("metres", "kilometres") so voices don't read "m" as a letter. <br>• **Audio:** device media volume; Android asks for audio focus so music ducks; iOS uses the navigation prompt mode, mixing with and ducking other audio. <br>• **Language:** Urdu voice if the phone has one, otherwise English speech with a one-time notice, otherwise screen only with a notice. |
| When things are said | `announcement_planner.dart` (pure Dart): <br>• the first instruction on Start; <br>• each maneuver **early** (500 m, only after long stretches), **near** (about 10 s ahead: 80–250 m by speed) and **at the turn** (30 m); <br>• a turn that follows within 150 m is said together with it ("…, then turn right") and isn't warned about again; <br>• "You are approaching your destination" (150 m) and "You have arrived" once each; <br>• "New route found." once per reroute. <br>**Never** said twice, never stacked when you first appear already close to a turn, nothing while not navigating, and **nothing about the route while you're more than 50 m off it**. |
| Mute | A speaker button on the map while guiding (tooltip "Mute voice" / "Turn voice on"). It's **remembered on the device** (in the existing Hive settings box). Muted, guidance continues on screen and nothing is queued up. Unmuting says the next instruction once. |
| Off-route detection | `off_route_detector.dart` (pure Dart): <br>• the allowance is 35 m, widened for rough fixes (×1.5 accuracy + 10 m, up to 80 m); <br>• fixes rougher than 50 m, or taken while the signal is lost, are **ignored**; <br>• "off route" needs **3 fixes and 5 seconds** beyond the allowance; <br>• it clears only well inside (70 %), so it doesn't flap at the edge; <br>• driving back along the route the wrong way (progress dropping by more than 60 m) also counts. |
| Rerouting | In `NavigationController`: navigating → **rerouting** → navigating, with a **new route from the latest position**. <br>• One request at a time; automatic requests at most every **15 s**. <br>• If it fails, guidance **continues on the old route** with the reason shown ("offline", "no road route from here", or "couldn't get a new route" with **Try again**). It retries automatically after the cooldown, and the notice clears when you rejoin the route. <br>• The screen shows "Off route. Finding a new route…" in place of the instruction while it works. |
| Strings | 14 new en + ur keys. |

## 2. Problems found (all fixed, with tests)

1. **False "You have arrived" while far from the route** (found in the browser drive, screenshot 03). The engine counted ≤ 30 m of road left as arrived without checking how far from the route you were. Off the route, the route's end can be its nearest point, so the car was declared arrived about 300 m away. Arrival now also requires being on the route (≤ 40 m plus GPS error). Test: 300 m past the end of a route is not arrived; 10 m is.
2. **"Approaching your destination" spoken while off the route**, for the same reason. The voice now says nothing about a route you're well off. Test added.
3. **"Wrong way" faked after an off-route stretch.** Positions far off the route matched a distant part of it (this route circles Iqbal Park) and pushed up the furthest-progress mark. After coming back, progress looked as if it had dropped, so a failed-reroute notice never cleared. Furthest progress now only advances while on the route. Test added.
4. **"Then" turns repeated.** An 8 m step was announced as "…, then turn right", and "turn right" was warned about again moments later. The planner now skips the early and near warnings for a maneuver already said as the "then" part.

## 3. Checks

| Check | Result |
|---|---|
| `flutter test` | **444 / 444 passed**: 423 + 21 new. Detector 4; planner 5; spoken sentences 1; session (reroute and voice) 8; screen 2; engine 1 (arrival far from route). |
| `dart analyze lib test` | **0 errors, 5 warnings, 28 infos**: no new issues. |
| `flutter build apk --debug` | **passed** (528 s) |
| `flutter build web --release` | **passed** (451 s) |
| **Browser drive with a detour** (harness outside the repo; real OSRM and tiles; **GPS simulated by the harness only**; speech recorded by wrapping the browser's `speechSynthesis.speak` from the test tools) | Final run, in order: <br>• "In 950 metres, turn left" (Start); <br>• "New route found." (after the 150 m detour, about 6 s off route); <br>• "New route found." again 16 s later (the scripted car keeps to the old line, so it leaves the new route; the 15 s cooldown held); <br>• "In 140 metres, turn left"; <br>• "Turn left". <br>No false arrival, no false "approaching". On-screen, the trip changed from 3.4 km to a new 700 m route via Fort Road. |
| **Urdu screen on a browser with only English voices** | Showed the notice "اس فون میں اردو آواز موجود نہیں…", and the speech was English ("In 950 metres, turn left"). Screenshot 04. |
| Line endings | All new and edited files LF, as before. |

The tests use fake speech, routing and GPS (and the real recorded Lahore routes). They cover:
- **Detector:** single far fix; 3 fixes and 5 s; rough fixes and lost signal ignored; allowance growth; edge hysteresis; wrong way.
- **Planner:** a whole drive with every band once; nothing stacked when starting close; speed-based near distance; a new route announced once; quiet off route.
- **Sentences:** English and Urdu wording.
- **Session:** reroute from the latest position and announced once; the cooldown; rough fixes never rerouting; a failed reroute keeping the old route and clearing on return; automatic retry after the cooldown; Try again; mute and unmute; an Urdu voice; English fallback; no voice; End stopping speech.
- **Screen:** speech on Start; the mute button; the reroute-failed banner, then Try again.

## 4. Notes and limits
- **I can't hear the audio.** The tests and the browser check confirm what's sent to the speech engine and when. How it sounds on a real phone (voice quality, volume, ducking music) isn't verified.
- **Urdu voices** depend on the phone. Many Android phones have Google's Urdu voice, but not all. The fallback is tested.
- The detour check in the browser rerouted in about 6 s; real GPS noise will make it a little slower by design (3 fixes and 5 s).
- Reroutes use the same public OSRM server (1 request a second; the 15 s cooldown keeps well within that).
- **Snapshot:** the ARB files were edited before this phase's snapshot was taken. Since the change only appended 14 keys, the before-state was rebuilt exactly (the 14 keys removed) into `design/nav/.snapshot/nav7/lib/l10n/`.

## 5. Builds
Both passed, with temporary files on drive F:; Gradle daemons were stopped afterwards.

## 6. Files

New (`lib/features/navigation/`):
- `domain/off_route_detector.dart`, `domain/announcement_planner.dart`
- `presentation/providers/voice_guidance.dart`

New tests and other:
- `test/unit/voice_and_reroute_test.dart`
- `design/nav/nav7/screens/`, `design/nav/.snapshot/nav7/`, this report

Changed:
- `navigation_engine.dart`: arrival needs being on the route.
- `navigation_controller.dart`: rerouting, route version, reroute problems, on-route progress.
- `navigation_screen.dart`: mute button, voice language, notices, rerouting card, reroute banner.
- `nav_panels.dart`: `NavReroutingCard`.
- ARB files and generated l10n.
- Test helpers (`FakeSpeaker`), `navigation_engine_test.dart`, `navigation_screen_test.dart`.

## 7. Next: Phase 8 (live sharing and the job's destination)
- **Destination pin:** the client pins the exact place when sharing the address. `shareAddress` gets an optional validated `location`, saved as `contracts/{id}.serviceLocation` (function change + tests). The pin is picked with the Phase 3 picker.
- **Live sharing:** heading and speed added to `contracts/{id}/live/location` (rules allowlist change + rules tests, as you approved). Navigation and sharing share one GPS stream.
- Nothing deployed: the rules and functions are tested on the emulators only.
