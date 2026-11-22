# SkillBridge — Setup, test, build and deploy guide

For the developer/account owner. **No secrets appear in this file.** Keys and passwords live only in git-ignored files (`.env`, `ios/Flutter/GoogleMaps.local.xcconfig`, `super_admin_web/.env.local`) or in Google Secret Manager.

Firebase project: **`skill-bridge-c68c3`** (`.firebaserc` default). Android package: `com.skillbridge.skill_bridge`. iOS bundle id: `com.skillbridge.skillBridge`.

---

## 1. Tools

| Tool | Version used | Notes |
|---|---|---|
| Flutter | 3.44.4 stable (Dart ^3.12) | `flutter doctor` must be clean for Android. |
| Node.js | 22 for Cloud Functions (`functions/package.json` engines) | The local test machine ran Node 24; functions run on Google's Node 22 runtime. **Node 20 was decommissioned on 31 Oct 2026; don't go back to it.** |
| Firebase CLI | 13.35.1 (`rules-tests/node_modules/.bin/firebase`) or a global `firebase-tools` ≥ 13.35 | `firebase login` once. |
| Java | 17+ (for Android builds and the Firestore emulator) | |

```bash
flutter pub get
```

```bash
npm --prefix functions ci
```

```bash
npm --prefix rules-tests ci
```

---

## 2. Firebase project (console, account owner)

1. **Blaze plan.** Firebase console → ⚙ → Usage and billing → Modify plan → Blaze. Cloud Functions and Storage need it. **Set a budget alert first** (Google Cloud console → Billing → Budgets & alerts, e.g. US$5/month with 50/90/100% emails). Blaze is pay-as-you-go; the free quotas still apply.
2. **Authentication:** Email/Password and Google sign-in enabled (already set up).
3. **Firestore:** already in use.
4. **Storage:** Firebase console → Storage → Get started. Default bucket `skill-bridge-c68c3.firebasestorage.app`.
5. **Cloud Messaging:** enabled by default. For iOS, upload an **APNs auth key** (Project settings → Cloud Messaging → Apple app configuration). That needs an Apple Developer account.
6. **App Check:** apps are registered; keep **enforcement OFF** until the console shows that verified requests are ~100% of traffic, and while the APK is also distributed outside Google Play. Play Integrity only attests Play-installed apps.

---

## 3. Google Maps Platform (Google Cloud console → APIs & Services, account owner)

Enable these APIs on the project:

| API | Used by |
|---|---|
| Maps SDK for Android | the map in the Android app |
| Maps SDK for iOS | the map in the iOS app (if you ship iOS) |
| Maps JavaScript API | the web build (testing only) |
| Routes API | `computeRoute` function: road route, distance, time |
| Places API (New) | `searchPlaces` function: address search |
| Geocoding API | `reverseGeocode` function: address of a pin |

Create **separate keys** (Credentials → Create credentials → API key) and restrict each one:

| Key | Application restriction | API restriction | Where it goes |
|---|---|---|---|
| Android | Android apps: `com.skillbridge.skill_bridge` + the **SHA-1** of every signing key you build with (debug and release, see below) | Maps SDK for Android | `.env` → `GOOGLE_MAPS_API_KEY` |
| iOS | iOS apps: `com.skillbridge.skillBridge` | Maps SDK for iOS | `ios/Flutter/GoogleMaps.local.xcconfig` (copy the `.example`) |
| Web (optional) | HTTP referrers, e.g. `http://localhost:*/*` | Maps JavaScript API | `.env` → `GOOGLE_MAPS_WEB_API_KEY` |
| **Server** | None (it never leaves Secret Manager) | Routes API, Places API (New), Geocoding API | Secret Manager (below), **never in a file** |

SHA-1 of the debug key on this PC:

```bash
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

Put the server key in Secret Manager (paste it at the prompt yourself; never on a command line or in chat):

```bash
firebase functions:secrets:set MAPS_SERVER_KEY
```

Also:
- **Delete or restrict the old key** that was in `ios/Flutter/GoogleMaps.local.xcconfig` before Phase G1 (moved out of the repo; it is not the key in `.env`).
- Set **quotas** per API (Cloud console → APIs → each API → Quotas), e.g. 500 requests/day for Routes, Places and Geocoding while testing. The functions also limit each user per hour (routes 120, places 60, geocode 120).
- **Firebase client keys** in `lib/firebase_options.dart` / `google-services.json` are public by design. In Credentials, restrict them to the Firebase APIs they need (Identity Toolkit, Token Service, Firestore, Firebase Installations, FCM Registration, Storage).

---

## 4. Local configuration

```bash
copy .env.example .env
```
Fill in `GOOGLE_MAPS_API_KEY` (Android key), optionally `GOOGLE_MAPS_WEB_API_KEY` and `RECAPTCHA_V3_SITE_KEY`. `.env` is git-ignored and is **not** bundled as an asset; values reach the app only through `--dart-define-from-file=.env`. They are compiled into the app, so only **restricted client keys** go there.

Optional build switches:
- `--dart-define=PHOTO_UPLOADS=off` hides photo uploads (for a build pointed at a project without Storage).

---

## 5. Tests

| What | Command | Expect |
|---|---|---|
| Analyzer | `dart analyze lib test` (on this PC `flutter analyze` can hang; `dart analyze` is equivalent) | 0 errors |
| App tests | `flutter test` | all pass (469 on 22 Nov 2026) |
| Functions | `npm --prefix functions test` | all pass (27) |
| Security rules (Firestore + Storage emulators) | `npm --prefix rules-tests test` | all pass (171) |

On this PC set `TEMP`/`TMP` to a folder on F: before long runs (drive C: is nearly full), and stop other emulators first (port 8080/8181 clashes).

Functions on the emulator (no real Google calls; push is skipped in the emulator):

```bash
npm --prefix functions run build
```

```bash
firebase emulators:start --only functions,firestore --project demo-skillbridge
```

Use the `demo-` project id so nothing can reach production. For a local `MAPS_SERVER_KEY`, create `functions/.secret.local` (git-ignored) with a **placeholder**; real Google calls need a real key and are not needed for testing. `functions/lib` is partly tracked in git: after a local build, run `git checkout -- functions/lib` and `git clean -f functions/lib` to avoid committing build output.

---

## 6. Builds

| Build | Command |
|---|---|
| Android debug (no Maps key → maps show "Map unavailable") | `flutter build apk --debug` |
| Android with maps | `flutter build apk --release --dart-define-from-file=.env` |
| Play Store bundle | `flutter build appbundle --release --dart-define-from-file=.env` (needs your own upload key: `android/app/build.gradle.kts` still signs release with the debug key) |
| Web (testing) | `flutter build web --release --dart-define-from-file=.env` (with a referrer-restricted web key) |
| iOS | `flutter build ios --dart-define-from-file=.env` on a Mac, plus `GoogleMaps.local.xcconfig` |

---

## 7. Deploy, in this order (account owner)

Check the target first:

```bash
firebase use
```
It must print `skill-bridge-c68c3`.

1. **Functions** (Blaze + APIs + `MAPS_SERVER_KEY` set). The folder contains only the 6 new functions (`computeRoute`, `searchPlaces`, `reverseGeocode`, `onNotificationCreatedV2`, `refreshProfileCopies`, `deleteAccount`):
   ```bash
   firebase deploy --only functions
   ```
2. **Rules and indexes** (Firestore + Storage):
   ```bash
   firebase deploy --only firestore:rules,firestore:indexes,storage
   ```
3. **Release the new app version** (bump `version:` in `pubspec.yaml`, build as in §6, publish).

Never run a bare `firebase deploy`. `firebase.json` also contains a Next.js **hosting** target for `super_admin_web`, which needs separate setup.

Why this order: the new rules only add restrictions that the new functions and app already respect. Installed v1.1.x apps keep working with the new rules: their notification writes still pass and are rewritten by the function. They just don't register per-device push tokens until updated.

**Rollback:** previous rules are in git (`git show HEAD:firestore.rules`, `git show HEAD:storage.rules`); redeploy with the commands above. A function can be removed with `firebase functions:delete <name>`.

---

## 8. Checks after deploying (on a phone)

1. Sign in as a worker on phone A and a client on phone B (Android 13+: allow notifications).
2. **Maps:** open a contract's directions (map, pin, blue dot, "x km by road · about y min") and the location picker (search an address, move the pin, the address appears).
3. **Photos:** Profile → change photo (camera and gallery), watch progress; check it appears on the other phone's chat/proposal list; remove it.
4. **Push:** with phone A in the foreground, background, and swiped away: send a message from B → a notification arrives with B's real name and text; tapping it opens the chat. Repeat for a proposal and a contract step.
5. **Notification centre:** mark all as read, swipe to delete.
6. **Saved jobs:** bookmark a job, find it under Saved jobs.
7. **Account deletion:** with a test account that has no active contract: Settings → Delete account → it signs out; the other party's old chat shows "Deleted user".
8. Firebase console → Functions → Logs: no errors; Usage: reasonable request counts.
