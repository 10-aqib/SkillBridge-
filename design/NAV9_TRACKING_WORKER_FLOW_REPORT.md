# SkillBridge — Navigation Phase 9: hirer live tracking and worker integration

Status: **implemented and checked locally. Nothing deployed, committed or pushed.** No rules or functions changed in this phase. Following your instruction, Phase 10 starts straight after this report.

## 1. Summary

| Area | Result |
|---|---|
| Worker: directions from the job | On an accepted, active contract the worker's "Live location" card has **Start navigation**. It's enabled only when the client has pinned the place; otherwise it's disabled with "Directions need the place pinned on the map. Ask {client} to pin it." It opens `/contracts/:id/navigate`. |
| Worker navigation screen | `ContractNavigationScreen`. **Guards:** only the hired worker ("Only the worker hired for this job…") and only while the job is active ("This job is no longer active…"); nothing starts otherwise, GPS included. It uses the Phase 6–8 navigation screen with the **client's pin as the destination** and the exact address as the place name. <br>**On the map:** a **share-location toggle** under the voice button, with the same consent sheet as on the contract; green while sharing; tap to stop; the specific reason if it can't start. <br>**On arrival:** "**Tell {client} I've arrived**" posts the existing progress update once (one request id, so a retry never posts twice), and "**Start work**" appears if work hasn't started. Then Done. |
| View on map | Both parties see a small map of the **pinned place** on the contract, with "View on map", which opens the device's maps app (Android `geo:`, Apple Maps, OpenStreetMap on web). |
| Client: live map | The client's Live location card gets **Open live map**, which opens `/contracts/:id/track`. |
| Client tracking screen | `ContractTrackingScreen`. **Guards:** only the client of the job ("Only the client…"); only while active. <br>**Shows:** the worker's position with an **amber direction arrow** while moving, the accuracy circle, the pinned place, and the **road route** from the worker (OSRM). <br>**Panel:** the worker's name and **Live / Not live**, "Updated … · Accurate to about … m", "**3.6 km by road · about 11 min**", "Arrives about …", and the estimate note. <br>**A new route** is fetched only after the worker moves 150 m or the route is 2 minutes old; in between, distance and time left come from the current route. <br>**States:** not sharing; **stale** (dimmed, "not live" warning, **no route and no time**, never shown as live); offline; loading error with Try again; no pin ("Pin the place…"); within 60 m of the pin ("{worker} is at the place."); route unavailable. <br>The camera frames worker and pin and follows until the map is moved; Recenter restores it. |
| Routes | `/contracts/:contractId/navigate` and `/contracts/:contractId/track` (new). No existing route changed. Firestore rules still decide who can read the contract and the live position; the screens add the role check. |
| Navigation screen | Optional `guidingAction` and `arrivalActions`, so the job flow plugs in without the generic screen knowing about contracts. |
| Strings | 18 new en + ur keys. The Urdu arrival button is worded gender-neutrally ("…کو اپنے پہنچنے کی اطلاع دیں"). |

## 2. Problems found in the browser check (fixed)

1. **Spoken directions were switched off on the web when guidance started right after the page loaded.** Browsers load their voice list asynchronously; at that moment it was empty, so the app decided "no voice" for the whole session (screenshot 04). The voice setup now checks once more after 1.5 s before giving up, and only then shows the notice. Verified: the page had 0 voices at load, and "In 950 metres, turn left" was still spoken. Test added for voices that load late.
2. **The worker's direction arrow on the client map was invisible.** It pointed along the route in the route's blue, and then sat half under the pin. It's now amber with a white outline and clear of the pin.

## 3. Checks

| Check | Result |
|---|---|
| `flutter test` | **461 / 461 passed**: 451 + 10 new. Worker screen 3 (guards; no pin; full flow with sharing from the map, arrival tell and Start work). Client screen 4 (live with route and time; stale with no route or time; not sharing, no pin, at the place; guard). Contract page 2 (Start navigation disabled or enabled, plus the preview; no live map without a live position). Voice 1 (late voices). The Phase 4B client test also checks "Open live map". |
| `dart analyze lib test` | 0 errors, 5 warnings, 28 infos: **no new issues**. |
| `flutter build apk --debug` | **passed** (385 s) |
| `flutter build web --release` | **passed** (246 s) |
| **Browser** (harness outside the repo: real screens, real OSRM and tiles; **fake contract data and a simulated moving worker**, test only) | **Client:** the live map with the worker moving on the real road, Live, "3.6 km by road · about 11 min", arrival time; the amber arrow after the fix. **Worker:** "Route to Badshahi Mosque, Fort Road", 12 min · 3.7 km; guidance with the voice and share buttons; speech recorded. Screenshots in `design/nav/nav9/screens/`. |

**Not done here:** the two-device run against the Firebase emulators (client pins, worker navigates and shares, client follows). That's the first item of Phase 10.

## 4. Notes
- Tapping "Tell … I've arrived" sends a progress update, so it appears in the contract history and notifies the client, through the existing `contractActionCall` (no new backend).
- The route on the client's map is fetched by the client's app. With the public OSRM server, that's at most one request per 150 m moved or per 2 minutes.

## 5. Builds
Both passed, with temporary files on drive F:.

## 6. Files

New:
- `lib/features/navigation/presentation/screens/contract_navigation_screen.dart`
- `lib/features/navigation/presentation/screens/contract_tracking_screen.dart`
- `test/widget/contract_navigation_test.dart`
- `design/nav/nav9/screens/`, snapshot `design/nav/.snapshot/nav9/`, this report

Changed:
- Router: `route_names.dart`, `app_router.dart` (2 routes).
- Contracts:
  - `contract_details_screen.dart`: Start navigation, pin preview.
  - `live_location_ui.dart`: Open live map, `PinnedPlacePreview`.
- Navigation:
  - `navigation_screen.dart`, `nav_panels.dart`: extension points.
  - `voice_guidance.dart`: retry for late voices.
- `core/map/map_markers.dart`: the person pin's direction arrow.
- ARB files and generated l10n.
- Tests: `contracts_screens_test.dart` (2 tests and stub routes), `contracts_4b_test.dart`, `voice_and_reroute_test.dart`.
