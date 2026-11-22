# SkillBridge — Track G (Blaze + Google Maps), Phase G0: discovery

Status: **discovery only. No code, rules, config or Firebase project was changed.** Awaiting your decisions (§6) and approval to start G1.

Date: 21 Nov 2026 · Branch `ui-improvements-2026` (HEAD `f809344`, v1.1.1+3) · Firebase project `skill-bridge-c68c3`

---

## 1. What the project actually is today (verified, not assumed)

| Area | Real state |
|---|---|
| Stack | Flutter (Dart SDK ^3.12.2), Riverpod 3, go_router 17, freezed, Hive offline cache/outbox. ~54k lines in `lib/`. |
| Platforms | Android (`com.skillbridge.skill_bridge`) is the real target. `ios/` and `web/` exist and have Firebase app IDs. iOS can't be built on this Windows PC. Web is used for emulator testing. |
| Backend design | **Free (Spark) plan architecture**, released as v1.1.0 on 15 Nov (S1–S8). Contracts, proposals, chats, ratings and public profiles are written by the app in **transactions**, and a 1,302-line `firestore.rules` state machine checks them. These rules are **live in production**. |
| Cloud Functions | `functions/src` (8 files, gen-2 triggers and callables) is the **pre-Spark** code. The app no longer calls it. **Production check today: the Cloud Functions API is disabled** (`SERVICE_DISABLED`), so nothing is deployed. |
| Blaze | **Not confirmed.** The brief says Blaze is active, but my notes say payment failed on 14 Nov. The CLI can't read billing status from here. Functions and Storage stay unusable until billing is on **and** their APIs are enabled. |
| Storage | `storage.rules` exists (117 lines) but has never been deployed. The app uploads images to **Cloudinary**, which is unconfigured (`CLOUDINARY_*` not set), so uploads are off. |
| Maps | **OpenStreetMap stack** from NAV1–NAV10: `flutter_map`, `latlong2`, OSRM routing, Nominatim search, in-app turn-by-turn with voice (`flutter_tts`), rerouting, `wakelock_plus`, and live location sharing. No Google Maps code. `config_hygiene_test.dart` even asserts that Google Maps is absent. |
| Push | `PushNotificationService` (FCM + local notifications, a channel and tap routing) is initialised in `main.dart`, but **no server sends pushes**. Notifications are written **by the sender's app** (`job_remote_datasource.dart` ×4, chat send batch), and the rules limit them. |
| Admin | Next.js `super_admin_web` (Admin SDK through API routes). One prod staff account with the `SUPER_ADMIN` claim. Not hosted, because framework hosting needs Blaze. |
| Tests | 51 Flutter test files; 217 rules tests (`rules-tests/rules.test.js`); 5 function unit-test files (fake DB). |

## 2. Feature inventory

| Feature | Status | Evidence / gap |
|---|---|---|
| Email + Google sign-in, sign-up, role choice | COMPLETE | S2 report, rules tests, emulator runs |
| Password reset, email verification | COMPLETE | `sendPasswordResetEmail` / `sendEmailVerification` wired (6 files each) |
| **Account deletion** | **MISSING** | No flow exists. Google Play requires one for apps with accounts. |
| Profiles (private + public mirror) | COMPLETE | S2. Protected fields (role, verified, rating) rule-locked. |
| **Profile pictures** | **BLOCKED / PARTIAL** | Code uploads to Cloudinary, which is unconfigured, so nothing uploads. The app **can't delete** images on Cloudinary. No crop step. |
| Admin via custom claims | COMPLETE | `SUPER_ADMIN` claim; the 14 Nov hotfix stopped self-promotion. |
| Jobs: post, edit, close, browse, search, filter | COMPLETE | S3; real Firestore queries. Location set with the OSM picker. |
| **Saved jobs** | **MISSING** | No code. Not in the earlier scope; your call (§6). |
| Proposals / applications, accept / reject, duplicate guard | COMPLETE | S3–S4 transactions + rules. |
| Contracts (13 actions, state machine) | COMPLETE | S4, rules-tested. |
| Reviews + rating average | COMPLETE | S5, transaction + rules check. |
| Chat: real-time, unread counts, read receipts (`lastReadAt`), paging by `limit` | COMPLETE (text) | S5. Photo messages are blocked by Cloudinary. |
| In-app notification centre | COMPLETE | Live list and badge. **Weakness:** the sender's app writes the text (rules limit recipient, type and length). |
| **Push notifications** | **PARTIAL** | Client side done; no sender (no functions). Foreground, background and terminated states never verified end to end. |
| **Maps / location / routing / navigation** | COMPLETE on OSM, **to be replaced** | NAV10 verified. Everything here must move to Google (§3). |
| Live location sharing (consent, stop, stale) | COMPLETE on OSM | NAV8/NAV9. Rules restrict it to contract parties. Only the map layer changes. |
| Nearby workers map | COMPLETE on OSM | Commit `bbe1be6`. |
| EasyPaisa "Payment status" screen | PARTIAL (by design) | Display only; no payment API. I'd leave it as is and label it clearly. |
| App Check | PARTIAL | Activated (Play Integrity / debug); enforcement off (correct while the APK ships outside Play). |
| Reports (moderation) | COMPLETE | `reports` collection + rules; admin web reads it. |

No hard-coded jobs, users or fake chats are in production code paths. Test fakes live only under `test/helpers`.

## 3. Old map provider: what replacement means

These files and packages belong to the OSM stack. In G1–G2 they are removed or rewritten:

- **Packages to remove:** `flutter_map`, `latlong2`; likely `flutter_tts` and `wakelock_plus` (see decision D2).
- **Core:** `lib/core/map/{sb_map, map_config, map_markers, geocoding}.dart`. Keep `lib/core/location/*` (plain GPS via `geolocator`), only swapping its `latlong2` types.
- **Navigation feature:** `osrm_routing_service.dart`, `routing_service.dart`, `navigation_engine.dart`, `off_route_detector.dart`, `announcement_planner.dart`, `route_geometry.dart`, `navigation_controller.dart`, `voice_guidance.dart`, `screen_awake.dart`, `navigation_screen.dart`, `route_layer.dart`, `contract_tracking_screen.dart`.
- **Screens using the map:** `location_picker_screen.dart`, `nearby_workers_screen.dart`, `contract_details_screen.dart`, `live_location_ui.dart`, plus the contract model/entity `LatLng` types.
- **Tests:** 15 map, navigation and routing test files and helpers (`fake_map_tiles`, `fake_navigation`), plus `config_hygiene_test.dart`, which asserts Google Maps is absent.
- **Config:** the `MAP_TILE_*`, `ROUTING_*` and `GEOCODING_*` entries in `.env.example`.

**Important constraint (Google's terms):** the Google Maps Platform terms forbid using Routes API data for real-time turn-by-turn guidance synced to the device's position. Only the paid **Navigation SDK** is licensed for that. So the in-app turn-by-turn navigation built in NAV6–NAV7 (voice, rerouting, turn list) **can't simply be pointed at Google**. It would have to be dropped and replaced by a route preview + "Open in Google Maps" (decision D2).

## 4. Security findings (no action taken)

1. **Stray Google Maps key on disk:** `ios/Flutter/GoogleMaps.local.xcconfig` holds a key. It is git-ignored and was **never committed**. It is **not** the key in `.env`, so it is probably the old one from before NAV3. Delete or restrict that key in Google Cloud console; I'll remove the file in G1.
2. **Client-written notifications:** any party to a job, contract or chat can make the app show the other party any wording (within length limits). With functions available, notification creation moves to server triggers, and the rules forbid client creates.
3. **The `.env` Maps key** gets compiled into the APK if builds use `--dart-define-from-file=.env`. It must be restricted (Android package + SHA-1 fingerprints, Maps SDK for Android only) **before** any build that includes it.
4. Live rules are the reviewed S8 rules (not permissive). I found no broad `allow read, write: if request.auth != null` rules.

## 5. Proposed phases (each ends with a report and a stop, as before)

| Phase | Work | Needs Blaze? |
|---|---|---|
| **G1 Remove OSM** | Remove OSM, OSRM, Nominatim and the in-app turn-by-turn stack; neutral `GeoPoint` types; delete the stray key file; update `.env.example` and the hygiene test. App still builds (map screens show a temporary "map unavailable" state only inside this branch). | No |
| **G2 Google Maps (client)** | `google_maps_flutter`; one `SbGoogleMap` widget with markers, camera fit, current location and loading/error states; job location preview; location picker; nearby workers; contract live-location map; "Open in Google Maps" deep link. Android key through a Gradle manifest placeholder from `.env` (never committed). | No (needs a restricted Android key) |
| **G3 Server routing + places** | Callable functions `computeRoute` (Routes API, field mask, validation, cache) and `searchPlaces`/`geocode` (Places API New). Server key in **Secret Manager**. Client draws the polyline + distance/ETA. | **Yes** |
| **G4 Firebase Storage** | Replace Cloudinary: profile picture (gallery/camera, resize, validate, progress, cancel, replace, delete), chat photos, work evidence. Rewrite and test `storage.rules` (owner-only, ≤2 MB, image MIME types). | **Yes** |
| **G5 Notifications on the server** | Firestore triggers create notifications for messages, proposals, contract steps and reviews (idempotent by event id); FCM send with token cleanup; per-device tokens in `fcmTokens/{uid}/devices/{id}`. Rules: **no client notification creates**; clients may only flip `read`. Check foreground, background and terminated taps. | **Yes** |
| **G6 Remaining features** | Account deletion (callable, cascades the user's own data and Storage, keeps the other party's contract records anonymised); saved jobs if you want them; notification preferences. | Partly |
| **G7 Verification** | Rules tests (Firestore + Storage), functions on the emulator, `dart analyze`, full `flutter test`, two-user emulator runs of scenarios A–E, debug + release APK builds. | Emulator only |
| **G8 Release** | Deploy functions **with** the matching rules and app version (lockstep, as in S8), only with your explicit go-ahead; final `SKILLBRIDGE_FINAL_AUDIT.md`, `SKILLBRIDGE_IMPLEMENTATION_LOG.md`, `SKILLBRIDGE_SETUP_GUIDE.md`. | **Yes** |

I recommend **keeping the S2–S5 transaction + rules design** (it is live, tested, and safe against modified apps). Functions get only the jobs the client must not do: notifications/push, the Routes/Places proxy with a secret key, Storage clean-up and account deletion. Moving all contract logic back into functions would mean rewriting working, deployed code for no security gain.

## 6. Decisions I need from you

- **D1 Blaze:** is billing actually active on `skill-bridge-c68c3` now (Firebase console → Usage and billing)? If not, G1–G2 can proceed, but G3–G5 stop at "code done, not deployed".
- **D2 Turn-by-turn:** (a) **recommended:** drop in-app voice/turn-by-turn; keep the route preview with polyline, distance and ETA, plus an "Open in Google Maps" button for driving. (b) Keep the OSM navigation screen alongside Google Maps (conflicts with "remove the old provider completely"). (c) Google Navigation SDK (separate paid licence and approval; large effort).
- **D3 Images:** move to Firebase Storage and drop Cloudinary (recommended, once Blaze is on)?
- **D4 Scope extras:** saved jobs — add or skip? Account deletion — add (recommended, Play requires it)?
- **D5 Keys:** you create in Google Cloud (I can't): an **Android key** restricted to `com.skillbridge.skill_bridge` + debug/release SHA-1, Maps SDK for Android only; and a **server key** (Routes API + Places API New only) that goes into Secret Manager through `firebase functions:secrets:set`. You type it at the prompt; it never goes in chat or files. Is the key in `.env` meant to be the Android key?

## 7. What I did in G0
- Read the repo, reports SPARK1/SPARK8, configs, rules outline, functions, and map/chat/notification/media code.
- Read-only production check: `firebase functions:list` → Cloud Functions API disabled.
- Checked the stray iOS key file: git-ignored, never committed, differs from `.env`. Neither key was printed.
- Nothing committed, deployed or edited apart from this report.
