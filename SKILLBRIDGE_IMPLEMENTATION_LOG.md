# SkillBridge — Implementation log (Track G, 21–22 Nov 2026)

Working tree on `ui-improvements-2026`, **not committed**. Totals (excluding recovery snapshots in `design/nav/.snapshot/`): 100 tracked files changed, +3,035 / −10,224 lines, plus 36 new files. `.claude/launch.json` was already modified before Track G and was not touched.

## Phases
| Phase | Report | Summary |
|---|---|---|
| G0 | `design/G0_DISCOVERY_REPORT.md` | Discovery, feature inventory, decisions D1–D6 |
| G1 | `design/G1_REMOVE_OSM_REPORT.md` | OpenStreetMap/OSRM/Nominatim/TTS removed; neutral `GeoCoord`; Google Maps links |
| G2 | `design/G2_GOOGLE_MAPS_REPORT.md` | Google Maps on every map screen; key wiring; verified on a phone |
| G3 | `design/G3_ROUTES_PLACES_REPORT.md` | Routes/Places/Geocoding through functions; routes, distance, ETA, search, addresses |
| G4 | `design/G4_STORAGE_PHOTOS_REPORT.md` | Photos in Firebase Storage; profile photo upload/replace/delete |
| G5 | `design/G5_NOTIFICATIONS_PUSH_REPORT.md` | Trusted notification text, push, per-device tokens, profile copies; legacy functions removed; Node 22 |
| G6 | `design/G6_ACCOUNT_SAVED_SETTINGS_REPORT.md` | Account deletion, saved jobs, notification settings, change password |
| G7/G8 | this log, `SKILLBRIDGE_FINAL_AUDIT.md`, `SKILLBRIDGE_SETUP_GUIDE.md` | Verification, builds, documents |

## Files created
- **App:**
  - `lib/core/location/geo_coord.dart`
  - `lib/core/map/{map_unavailable, maps_links, maps_config, maps_platform_io, maps_platform_web, sb_google_map, maps_api, route_format}.dart`
  - `lib/features/account/account_deletion_service.dart`
  - `lib/features/jobs/data/saved_jobs_repository.dart`
  - `lib/features/jobs/presentation/screens/saved_jobs_screen.dart`
- **Functions:**
  - `functions/src/{maps, notify, profileCopies, account}.ts`
  - `functions/test/{maps, notify, account}.test.js`
- **Tests:**
  - `test/helpers/{fake_map, fake_maps_api}.dart`
  - `test/unit/maps_api_test.dart`
  - `test/widget/{notification_center, profile_photo, saved_jobs}_test.dart`
- **Config:** `ios/Flutter/GoogleMaps.local.xcconfig.example`
- **Docs:** `design/G0…G6_*.md`, `SKILLBRIDGE_FINAL_AUDIT.md`, `SKILLBRIDGE_IMPLEMENTATION_LOG.md`, `SKILLBRIDGE_SETUP_GUIDE.md`

## Files modified (main ones)
- **Maps screens:**
  - `shared/widgets/location_picker_screen.dart`
  - `features/contracts/presentation/widgets/live_location_ui.dart`
  - `features/navigation/presentation/screens/contract_{navigation,tracking}_screen.dart`
  - `features/client/presentation/screens/nearby_workers_screen.dart`
  - contract model, entity and datasource (`GeoCoord`)
  - `core/location/device_location.dart`
- **Photos:**
  - `core/media/image_host.dart` (rewritten for Storage)
  - `core/services/profile_media_service.dart`
  - `shared/widgets/profile/profile_media_widgets.dart`
- **Notifications:**
  - `features/notifications/data/{datasources/notification_remote_datasource, services/push_notification_service}.dart`
  - `presentation/{notification_routes, screens/notification_screen}.dart`
  - `features/auth/data/datasources/auth_remote_datasource.dart` (sign-out removes the device token)
- **Settings / saved jobs:**
  - `shared/widgets/profile/settings_view.dart`
  - `features/jobs/presentation/screens/{job_details,job_feed}_screen.dart`
  - `config/router/{app_router,route_names}.dart`
- **Startup:** `main.dart` (web Maps loader)
- **Strings:** `l10n/app_{en,ur}.arb` plus the generated localizations (−86 turn-by-turn strings; +about 45 new strings in each language).
- **Platform:**
  - `android/app/build.gradle.kts` (key from dart-defines)
  - `AndroidManifest.xml` (Maps meta-data placeholder; TTS query removed)
  - `ios/Runner/{AppDelegate.swift, Info.plist}`
  - `ios/Flutter/{Debug,Release}.xcconfig`
- **Config:**
  - `.env.example` (Maps keys documented; OSM settings removed)
  - `functions/.gitignore` (`.secret.local`)
  - `functions/package.json` (Node 22)
  - `functions/src/index.ts`
  - `functions/test/fake_db.js` (doc/batch)
- **Rules:**
  - `firestore.rules`: notifications read-only except `isRead/readAt`; `fcmTokens` shape; `savedJobs`; `notificationPrefs`.
  - `storage.rules`: public photo folders tightened; wide rules removed.
- **Tests:** `rules-tests/rules.test.js` (+11 tests) and the widget/unit tests listed in the phase reports.

## Files removed
- **OSM / navigation** (G1):
  - `lib/core/map/{sb_map,map_markers,map_config,geocoding}.dart`
  - `lib/core/utils/request_spacer.dart`
  - all of `lib/features/navigation/{data,domain}`
  - `presentation/{nav_text, providers/*, widgets/*, screens/navigation_screen}.dart`
  - 10 test files
- **Stray key:** `ios/Flutter/GoogleMaps.local.xcconfig` (git-ignored key file; moved to the session scratchpad, not deleted).
- **Legacy functions** (G5):
  - `functions/src/{auth,chats,contracts,notifications,profiles,proposals,reviews}.ts`
  - their 5 test files
  - `functions/scripts/backfill-mirrors.js`
- **App:** `lib/core/providers/push_notification_provider.dart` (unused; would double-initialise push).

Every removed or changed file is in git (HEAD `f809344`) and in `design/nav/.snapshot/g1…g5/`.

## Packages
| Added | Removed |
|---|---|
| `google_maps_flutter ^2.18.1` (plus transitive `google_maps*`, `sanitize_html`, `html`, `csslib`) | `flutter_map`, `latlong2`, `flutter_tts`, `wakelock_plus` (16 packages left the lock) |
| `web ^1.1.1` (was transitive) | — |
| dev: `image_picker_platform_interface ^2.11.1` (was transitive) | — |
No other locked version changed (checked against the pre-G2 lock).

## Firebase / database changes (in code; none deployed)
- **New collections:**
  - `mapsUsage/{uid}` (server-only)
  - `fcmTokens/{uid}.tokens` (per device; replaces `users.fcmToken`, which is still read for old installs)
  - `users/{uid}/savedJobs/{jobId}`
  - `users/{uid}.notificationPrefs`
- **New notification fields** (server-set): `verifiedAt`, `pushedAt`, `readAt`.
- **Storage paths:** `users/{uid}/{profile,portfolio,jobPhotos}/…`
- **Secret:** `MAPS_SERVER_KEY` (Secret Manager).
- **Indexes:** no new composite indexes needed (notifications `userId+createdAt` already exists; the other new queries use single fields or equality only).
- **Migration:** none needed (no destructive change; old notification/token shapes still work).

## Cloud Functions (gen 2, Node 22, us-central1)
`computeRoute`, `searchPlaces`, `reverseGeocode` (callables, `MAPS_SERVER_KEY`, max 5 instances) · `onNotificationCreatedV2` (Firestore trigger, max 10) · `refreshProfileCopies` (Firestore trigger, max 5) · `deleteAccount` (callable, max 5).

## Bugs fixed
Listed in `SKILLBRIDGE_FINAL_AUDIT.md` §8.

## Tests executed (latest runs, 22 Nov 2026)
| Suite | Result |
|---|---|
| `dart analyze lib test` | 0 errors |
| `flutter test` | 469 passed |
| `npm --prefix functions test` | 27 passed |
| `npm --prefix rules-tests test` | 171 passed |
| Functions emulator e2e (maps callables; notify + profileCopies) | passed |
| On-device (user's phone, G2 harness) | Google map rendered with the restricted key |

## Builds
| Build | Result |
|---|---|
| Android debug APK, no key (G1, G2) | built; merged manifest has an empty Maps key |
| **Android release APK with `.env`** (G7, 22 Nov) | **built: `app-release.apk`, 72.3 MB**. The release manifest carries the restricted Maps key (checked without printing it). Signed with the debug key (no upload key yet). Not installed anywhere. |
| Web release, no key (G2, G7) | built; the bundle contains only the public Firebase web key, **not** the Maps key |
| Functions `tsc` build | builds (`functions/lib` restored to its tracked state afterwards) |
| iOS | not built (Windows PC) |

## Deployment results
**None.** No `firebase deploy`, no commit, no push during Track G (the overnight approval didn't cover deploying or committing). Exact steps: `SKILLBRIDGE_SETUP_GUIDE.md` §7.
