# SkillBridge — Navigation Phase 2: dependencies and platform configuration

Status: **implemented and checked locally. Nothing deployed, committed or pushed.** No screen, rule, function or existing behaviour changed. Awaiting your approval for Phase 3.

## 1. Summary

| Area | Result |
|---|---|
| Snapshot | Files copied before their first edit to `design/nav/.snapshot/nav2/`, same relative paths. `pubspec.yaml` and `pubspec.lock` are stored as `*.snapshot` (see §5). The folder name starts with a dot so the analyzer skips it. |
| Dependencies | Added `flutter_map` 8.3.2, `latlong2` 0.10.1, `flutter_tts` 4.2.5, `wakelock_plus` 1.5.2. `http` 1.6.0 became a direct dependency (it was used but only resolved transitively). **No existing package changed version**; 16 packages were added in total. `google_maps_flutter` stays until the Phase 3 migration. |
| Configuration | New `lib/core/map/map_config.dart`: tiles, routing and address search are build-time settings (`--dart-define` or `.env`), with no keys. Blank means the default. Invalid values are detected so later phases can show "unavailable" instead of failing. Riverpod providers let tests override them. |
| Platform | Android: `TTS_SERVICE` added to `<queries>` (needed by flutter_tts on Android 11+). iOS: the location-use text now says what location is used for (map, directions, optional sharing while the app is open). No background location permission or foreground service, as decided. |
| `.env.example` | Documents every new setting, its default, and the public-service policies. |

## 2. Settings and defaults

| Setting | Default | Notes |
|---|---|---|
| `MAP_TILE_URL` | `https://tile.openstreetmap.org/{z}/{x}/{y}.png` | Needs `{z}` `{x}` `{y}`; https, or http only for localhost / `10.0.2.2`. |
| `MAP_TILE_SUBDOMAINS` | none | Required only if the URL uses `{s}`. |
| `MAP_TILE_ATTRIBUTION` / `_URL` | © OpenStreetMap contributors / osm.org/copyright | Shown on every map (Phase 3). |
| `MAP_TILE_MAX_ZOOM` | 19 | Clamped to 1–22. |
| `ROUTING_BASE_URL` | `https://router.project-osrm.org` | Public demo: car only, ≤ 1 request/s, no uptime guarantee. Flagged by `isPublicDemo`. |
| `ROUTING_PROFILE` | `driving` | Letters, `_` and `-` only (it goes into the URL path). |
| `GEOCODING_PROVIDER` | debug builds: `nominatim`; **release builds: `none`** | See below. |
| `GEOCODING_BASE_URL` | `https://nominatim.openstreetmap.org` | Any Nominatim-compatible server. |
| `GEOCODING_COUNTRY_CODES` | `pk` | |

**Why release builds don't search by default:** the public Nominatim policy forbids autocomplete, allows at most 1 request/s, and requires that an app can switch to another service *without a software update*. A compiled-in address can't do that. So release builds use map selection unless a provider is set explicitly, preferably your own or a commercial endpoint. If you want switchable search in production, the cleanest option is a small cached Cloud Function proxy. That would be a Phase 8 decision, and nothing is built for it now.

## 3. Checks

| Check | Result |
|---|---|
| Baseline before changes: `flutter test` | 312 / 312 passed |
| After: `flutter test` | **326 / 326 passed** (312 + 14 new in `test/unit/map_config_test.dart`) |
| Baseline `dart analyze lib test` | 0 errors, 7 warnings, 36 infos |
| After | **0 errors, 7 warnings, 35 infos**: no new issues. One old info is gone (`http` not a declared dependency). |
| `flutter build apk --debug` | **passed** (built with `.env` set aside, so the APK has an empty Maps key; `.env` restored and checked unchanged). Merged manifest: TTS query present; no background location or foreground service. |
| `flutter build web --release` | **passed** (no `.env`). |
| Live check of the public defaults | Tiles: HTTP 200 PNG. OSRM: real route recorded (below). Nominatim status: HTTP 200. |
| Line endings | All 7 edited or new text files are CRLF throughout, matching the originals. |
| Secrets scan of touched files | none found |

**Recorded fixture:** `test/fixtures/osrm/lahore_route.json`, a real OSRM response between two public landmarks in Lahore (Minar-e-Pakistan area → Badshahi Mosque area). It is 3.7 km, about 11 minutes, with 151 points and 9 maneuvers (depart, turns incl. sharp/slight, arrive), with Urdu and English road names. Phase 5's parser tests use it, so they don't need the network.

## 4. Problems found

1. **Drive C: was full (0.08 GB free).** Flutter's test runner writes temporary files to `%TEMP%` on C:, and test runs hung at the end of a file (`tearDownAll`) twice. That includes the first baseline attempt, which ran before any Dart or dependency change. After I removed only the three temp folders left by the test runs I had stopped (about 256 MB) and stopped my Gradle daemons, the suite passed. C: later showed 2.06 GB free. **Older temp data from earlier sessions is still there** (Chrome test profiles in old Claude scratchpads, `sbcap-*` capture folders, older `flutter_tools.*`, about 1.5 GB). I didn't delete it; tell me if you want it removed. F: has about 3.4 GB free.
2. **`flutter analyze` hung** in its language-server mode on this machine. Before I stopped it, it had reported diagnostics and then waited forever. `dart analyze lib test` works (about 1 minute) and is what I used for both baseline and after. My snapshot first contained a nested `pubspec.yaml`, which may have contributed; it's now stored as `pubspec.yaml.snapshot`.
3. **`wakelock_plus` version.** 1.6.1 and later need `win32` 6, which the existing `share_plus` 10.1.4 doesn't allow. I didn't upgrade `share_plus` (an unrelated feature), so 1.5.2 is used. Its API (`WakelockPlus.enable/disable`) is the same.
4. **Windows `curl` can't reach the OSRM hosts** (TLS handshake error from Windows 10's schannel). Python/OpenSSL reaches them fine. The app uses Dart's own TLS, so this shouldn't affect it; Phase 5 will confirm it from Dart.
5. **Kotlin Gradle Plugin warning.** Flutter warns that plugins applying KGP will stop building in a future Flutter version. This warning already existed for the Firebase plugins and `share_plus`. `flutter_tts`, `wakelock_plus` and `package_info_plus` (pulled in by `wakelock_plus`) join the list. The build works today.

## 5. Files

New:
- `lib/core/map/map_config.dart`
- `test/unit/map_config_test.dart`
- `test/fixtures/osrm/lahore_route.json`
- `design/nav/.snapshot/nav2/` (snapshot)
- this report

Changed:
- `pubspec.yaml`: new "Maps & navigation" group; `http` made direct
- `pubspec.lock`: additions only
- `.env.example`: new settings
- `android/app/src/main/AndroidManifest.xml`: TTS query
- `ios/Runner/Info.plist`: location-use text

## 6. Next: Phase 3 (OpenStreetMap integration)

- Shared `SbMap`: themed tiles (dark-mode tile filter), attribution, recenter and compass buttons, and loading, offline, tile-error and invalid-config states.
- Markers: animated current location with heading; destination; person.
- Migrate the location picker (worker profile setup, nearby-workers search), the nearby-workers map and the client's live-location map to flutter_map. The Google Routes polyline on nearby workers becomes "no route" until Phase 5 provides OSRM.
- Remove `google_maps_flutter` and the key wiring (Gradle placeholder, manifest meta-data, `AppDelegate`), and update `config_hygiene_test`.
