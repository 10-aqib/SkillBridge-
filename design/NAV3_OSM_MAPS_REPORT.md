# SkillBridge — Navigation Phase 3: OpenStreetMap maps (Google Maps removed)

Status: **implemented and checked locally. Nothing deployed, committed or pushed.** No Firestore rules, functions or data changed. Awaiting your approval for Phase 4.

## 1. Summary

| Area | Result |
|---|---|
| Shared map | `SbMap` (`lib/core/map/sb_map.dart`) draws tiles from the build-time tile settings, with the attribution always visible (tap opens the licence page). It has recenter, zoom and compass buttons; the compass appears only when the map is rotated, and tapping it turns the map north. The dark theme uses a darkened tile filter. Every screen uses it. |
| Map states | **Unavailable** (bad tile settings: a clear panel instead of a broken map). **Offline** (notice over the map). **Tiles failing** (after 4 failed tiles with none loaded: notice plus "Try again"; it clears when tiles arrive). Previews in scrolling pages take no gestures. |
| Markers | `lib/core/map/map_markers.dart`: <br>• current location: pulsing dot (no pulse with reduced motion) and a heading arrow when a heading is known; <br>• destination pin, with its tip on the point; <br>• person (initial; selected; dimmed when out of date); <br>• accuracy circle in metres. |
| Address search | `lib/core/map/geocoding.dart`: `GeocodingService` interface with a Nominatim-compatible implementation and a "none" one. <br>• Searches only on submit, never as autocomplete. <br>• At most 1 request per second, cached, identifies the app. <br>• English names, to match the app's city list. <br>• Errors come back as "network" or "unavailable"; reverse lookups never throw. |
| Location picker (rewritten) | You move the map under a fixed pin, and the address is looked up once the map stops. Search runs on submit. <br>• Confirm needs zoom ≥ 13, so the whole-country view can't be confirmed. <br>• Without an address, the coordinates are used as the address, so nothing breaks when search is off. <br>• GPS denied, blocked, off or timed out is each explained, and the map stays usable. <br>• Accuracy is reported only while the pin is still where GPS put it. <br>• All text is in en + ur. |
| Nearby workers | Its Google map is replaced: the same circle, worker pins (tap to select) and recenter, and tapping a worker's name chip frames both points. The rest of this older screen is untouched. |
| Client's live-location card | A small OSM preview that follows each update, dims the worker's pin when out of date, and draws the accuracy circle. "Open in a maps app": Android `geo:` (any maps app), Apple Maps on iOS, OpenStreetMap on the web, with an OSM fallback. |
| Google Maps removed | <br>• **Package and wiring:** the `google_maps_flutter` package (9 packages left the lock file); the Gradle `.env` key reading and manifest placeholder; the manifest key meta-data; `AppDelegate` `GMSServices`; the Info.plist key; the xcconfig includes; `GoogleMaps.local.xcconfig.example`. <br>• **Unused Google-only code:** `google_maps_service`, `geocoding_service`, `places_service`, `routes_service`, and the dead `worker_live_tracking_map` widget and its test. <br>All of it is snapshotted, and the git-tracked files can also be restored from git. |
| Strings | 28 new keys in en + ur. Two values updated, `liveOpenInMaps` and `liveMapUnavailable`, which no longer mention Google Maps. |

## 2. Decisions made while building (tell me if you want them changed)

1. **The road route on nearby workers is gone until Phase 5.** It used Google Routes. Tapping a worker now frames the two points; the route comes back with the OSRM routing service.
2. **The old Islamabad fallback on nearby workers is unchanged.** It existed before this phase: when GPS fails, that screen still searches around Islamabad. It no longer draws "your location" there, so a made-up position is never shown as yours. Replacing the fallback itself is a separate fix to that screen.
3. **"Open settings" is hidden on the web** in the picker, because browsers have no settings page an app can open. Found in the visual check. The same button exists in the Phase 4B worker sharing panel (`live_location_ui.dart`, unchanged here). On web it does nothing; that's worth a small follow-up.
4. **`liveMapUnavailable`** was reworded but is currently unused; the shared "Map unavailable" panel covers that case.

## 3. Checks

| Check | Result |
|---|---|
| `flutter test` | **345 / 345 passed**: 326, minus the 2 deleted tracking-widget tests, plus 21 new (6 geocoding, 15 maps/picker/link). Tests use a no-network tile source (`test/helpers/fake_map_tiles.dart`), installed by default in `testApp`/`testRouterApp`. |
| `dart analyze lib test` | **0 errors, 5 warnings, 28 infos** (it was 7 and 36). No new issues; 10 old ones went with the deleted code. |
| `flutter build apk --debug` | **passed.** The merged manifest has no Maps key, and the APK has no Google Maps code. (Built before the last small picker change in §2.3; that change is Dart only and is covered by the web build and tests.) |
| `flutter build web --release` | **passed.** The bundle has **0** Google Maps references. |
| Config hygiene test | Now asserts that no Google Maps package or key wiring remains in pubspec, Gradle, the manifest, `AppDelegate`, Info.plist or the xcconfigs. |
| Line endings | Every edited file keeps its original style (LF, CRLF or mixed per line). `AppDelegate.swift` is now all CRLF because its only LF lines were the removed Maps lines. New files are LF, like recent new Dart files. |
| Secrets scan | none found |

### Visual check in the built-in browser (real tiles, real Nominatim)
I used a preview harness kept outside the repo: no Firebase, fixed sample positions for display only. Screenshots are in `design/nav/nav3/screens/`.
- **01**: real OSM tiles of Lahore, with: <br>• the current location with its heading arrow (135°); <br>• the destination pin on Badshahi Mosque; <br>• a selected worker and an out-of-date (dimmed) one; <br>• the attribution; the controls; the live-location preview.
- **02**: dark theme with Urdu (RTL). Tiles are readable, controls and attribution move to the leading side, and the credit stays left-to-right.
- **03–05**: the picker with browser location blocked, then "Badshahi Mosque Lahore" searched on submit, the result chosen, and the map dragged. The address updated after the drag ("Sarai of Aurangzeb, …"). The confirmed result had the address, city "Lahore", the coordinates, and accuracy "unknown" (correct: the pin wasn't placed by GPS). The whole session made **exactly 2 Nominatim requests**: one search and one reverse lookup. Typing sent nothing, and choosing a result sent no extra lookup. Screenshot 03 was taken before the fix in §2.3.
- **06–07**: phone width (375 × 812). Everything fits; the picker on web has no "Open settings".

**Not checked:** a real phone's GPS (the browser had location blocked), iOS (no Mac here), and the nearby-workers screen inside the running app (it needs a signed-in client and Firebase; its map code is the shared widget checked above). The full emulator end-to-end run is planned for Phase 10.

## 4. Problems found

1. **The picker's "Open settings" did nothing on the web:** fixed (§2.3).
2. **After choosing a place, the "location blocked" notice stayed up:** fixed. It clears once the person searches or moves the map. Test added.
3. **Web build failed on a stale Flutter build cache** (`.dart_tool/flutter_build/<hash>/web_plugin_registrant.dart` still imported the removed Google Maps web plugin). I removed those cache folders (11, all cache only) and rebuilt. The next `flutter run` on web would have hit the same error.
4. **Drive C: filled up again** (0.12 GB), and a test run hung. Cause: Windows' page file has grown to about 6 GB during builds on this 7.7 GB-RAM PC. I removed only my own leftovers (a stopped test run's temp folder, the preview build) and ran the tests and build with temporary files on drive F: (`build/nav_tmp`, deleted afterwards). C: later read 2.95 GB free. Nothing of yours was deleted.
5. **Correction to the NAV2 report:** it said every edited file was CRLF. A Git Bash check gave wrong results. The real endings (checked with Python) are: `pubspec.yaml`, `pubspec.lock` and `.env.example` are LF, and they kept LF; the plist and manifest are CRLF, and they kept CRLF. So no file's style changed, but I had written the two new Phase 2 Dart files as CRLF. They're now LF.

## 5. For you to do (outside the code)
- Your local `.env` and `ios/Flutter/GoogleMaps.local.xcconfig` still hold the old, possibly exposed Maps key. Nothing reads them any more. Delete the key from both, and **delete or restrict that key in Google Cloud console**. I didn't touch either file.

## 6. Files

New:
- `lib/core/map/sb_map.dart`, `map_markers.dart`, `geocoding.dart`
- `test/unit/geocoding_test.dart`, `test/widget/maps_test.dart`, `test/helpers/fake_map_tiles.dart`
- `design/nav/nav3/screens/*`, snapshot `design/nav/.snapshot/nav3/`, this report

Changed:
- `lib/shared/widgets/location_picker_screen.dart` (rewritten; same `LocationResult` shape, so callers are unchanged)
- `nearby_workers_screen.dart` (map parts only)
- `live_location_ui.dart` (`LiveLocationMap`)
- `main.dart` (comment)
- `test/helpers/test_app.dart`, `test/unit/config_hygiene_test.dart`
- ARB files and generated l10n
- `pubspec.yaml`/`.lock`, `.env.example`
- Android: `build.gradle.kts`, `AndroidManifest.xml`
- iOS: `AppDelegate.swift`, `Info.plist`, `Debug.xcconfig`, `Release.xcconfig`

Deleted:
- `lib/core/services/{google_maps,geocoding,places,routes}_service.dart`
- `worker_live_tracking_map.dart` and its test
- `ios/Flutter/GoogleMaps.local.xcconfig.example`

## 7. Next: Phase 4 (GPS location services)
A navigation-grade location source: position, accuracy, heading and speed; time limits; stale-fix detection; distance filter and interval settings; GPS-off, permission and permanent-denial handling with settings links (not on web). It extends the existing `LocationSource` rather than adding a second one.
