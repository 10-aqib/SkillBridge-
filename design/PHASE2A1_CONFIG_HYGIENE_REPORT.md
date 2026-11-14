# Phase 2A.1 — Configuration Hygiene: Report

**Date:** 8 November 2026 · **Branch:** `ui-improvements-2026` · **Status:** complete, awaiting approval before Phase 2B. Nothing committed, deployed or rotated.

## Summary

| Issue | Status |
|---|---|
| `.env` bundled as a public asset | **Fixed.** `.env` is no longer an asset. The Maps key is supplied at build time (`--dart-define-from-file=.env`), with no new dependency (`flutter_dotenv` removed). |
| Exposed credentials | **Action needed by you.** The current Maps key and a second Google key are in the **public GitHub history**, not just the asset. **Rotate both** (§4). |
| App Check placeholder site key | **Fixed in code.** Debug providers in debug builds; Play Integrity / DeviceCheck / reCAPTCHA v3 in release. Web release with no site key now skips App Check instead of using a fake key. **No enforcement or console setting changed.** |
| Crashlytics on web | **Fixed.** No longer touches Crashlytics on unsupported platforms. Web start-up and sign-in no longer throw. Android/iOS behaviour unchanged. |

## 1. Root causes

### 1.1 `.env` exposure
- `pubspec.yaml` listed `.env` under `flutter: assets:`. Flutter copies assets verbatim into every build: `assets/flutter_assets/.env` in APK/IPA, and `/assets/.env` on web, where it's directly downloadable.
- It was there so `flutter_dotenv` could read `GOOGLE_MAPS_API_KEY` at runtime for `GoogleMapsService` (Geocoding, Places API (New), Routes REST calls).
- Your existing `build/app/outputs/.../app-release.apk` and `app-debug.apk` (built before this fix) contain `.env` as a plain file.

### 1.2 App Check
`main.dart` called `activate(webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'), …)`. That literal string is a placeholder, not a real site key, so every web token request failed (the 400 responses seen in Phase 2A). The code also used Play Integrity / DeviceCheck in **debug** builds, which can't attest emulators or sideloaded builds, and used deprecated parameters (3 analyzer infos).

### 1.3 Crashlytics
`CrashlyticsService`'s constructor read `FirebaseCrashlytics.instance` in its initializer list, outside the `try` in `init()`. Crashlytics has no web implementation, so on web this threw:
- at start-up, as an uncaught error in the `Future.microtask` in `main.dart`;
- **on every sign-in and sign-out**, because `auth_providers.dart` calls `crashlyticsServiceProvider` to set the user ID and role.

## 2. Files

### Modified
| File | Change |
|---|---|
| `pubspec.yaml` | Removed the `.env` asset entry (comment explains why). Removed the now-unused `flutter_dotenv` dependency; `pubspec.lock` updated by `pub get`. |
| `lib/main.dart` | Removed `dotenv.load`. App Check start-up moved to `AppCheckSetup.activate()`. Non-critical start-up (Crashlytics, push) wrapped so failures are logged, never uncaught. |
| `lib/core/services/google_maps_service.dart` | Key read from `String.fromEnvironment('GOOGLE_MAPS_API_KEY')`. Same exception type when missing, with a clearer message. |
| `lib/core/services/crashlytics_service.dart` | Instance resolved lazily; all methods are no-ops on web, Windows and Linux. Unchanged on Android/iOS/macOS. Public API unchanged (one optional test parameter added). |
| `.gitignore` | `!.env.example` so the template can be committed (`.env` stays ignored). |
| `.vscode/launch.json` | Added "SkillBridge (debug/release)" configs that pass `--dart-define-from-file=.env`. The existing browser config is kept. |

### Created
| File | Purpose |
|---|---|
| `lib/core/services/app_check_setup.dart` | Provider choice per build (debug / production / web without site key). Pure `modeFor()` for tests. |
| `.env.example` | Template documenting `GOOGLE_MAPS_API_KEY`, `RECAPTCHA_V3_SITE_KEY`, `APP_CHECK_DEBUG_TOKEN` and which values may live in a client build. |
| `test/unit/config_hygiene_test.dart` | 8 tests: `.env` not an asset, key absent without build define, App Check modes, placeholder gone, Crashlytics safe when unsupported. |

### Not changed
Your `.env` (left as is), Android Gradle reading `../.env` for the manifest key, the iOS `GoogleMaps.local.xcconfig`, `firebase_options.dart`, Firestore/Storage rules, Auth, schemas, and the admin app. Every file was snapshotted before editing.

## 3. Classification of every value

### `.env` (Flutter app)
| Key | Kind | Verdict |
|---|---|---|
| `GOOGLE_MAPS_API_KEY` | Google Maps Platform API key | **Client credential.** Google designs Maps keys to sit in client apps *if restricted*. Not a server secret, but abuse-prone (billing) when unrestricted. It's the only value in the file. |

### Other configuration reviewed
| Value | Kind | Verdict |
|---|---|---|
| `apiKey`, `appId`, `projectId`… in `lib/firebase_options.dart`, `google-services.json` | Firebase client config | **Public by design.** Not secrets; access is protected by Security Rules and App Check. No action. These are different keys from the Maps key. |
| `NEXT_PUBLIC_FIREBASE_*` in `super_admin_web/.env.local` | Firebase web client config | Public by design. |
| `FIREBASE_PRIVATE_KEY`, `FIREBASE_CLIENT_EMAIL` (admin `.env.local`) | Service-account credential | **Real secret.** Server-only (no `NEXT_PUBLIC_` prefix), git-ignored, never committed, not referenced by any client component. No exposure found. |
| `SETUP_SECRET` (admin `.env.local`) | Server secret | Server-only, git-ignored, never committed. No exposure found. |
| reCAPTCHA v3 site key (to be added) | Public site key | Public by design (the *secret* key stays in the Firebase console). |
| App Check debug token (optional) | Debug credential | Keep out of git; revoke in the console when no longer needed. |

## 4. Were secrets exposed? Is rotation required?

**Yes, through git history, not only the asset.** The repository `github.com/10-aqib/SkillBridge-` is **public**. Scanning all commits, without printing values, found:

| Where | Commit (on `origin/main`) | Key | Exposure |
|---|---|---|---|
| `ios/Runner/AppDelegate.swift` (hardcoded) | `f3fd108` "Version Update", 27 Aug 2026 | **The current `GOOGLE_MAPS_API_KEY`** (identical to `.env`) | Public on GitHub since then |
| `android/app/src/main/AndroidManifest.xml` | `690aa72` "Initial commit" (8 Aug 2026) and `f3fd108` | **A different Google API key** (not a Firebase key) | Public on GitHub since then |
| `.env` asset | in APK/IPA builds | Current Maps key | Anyone with a distributed APK/IPA. Web: not hosted (Hosting serves only the admin), so `/assets/.env` was likely never public. |

The working tree no longer contains either key in source (they were already moved to `.env`/xcconfig). Removing them from future builds doesn't undo public history.

**Rotation required (manual: I did not rotate anything):**
1. Google Cloud console → APIs & Services → Credentials, project `skill-bridge-c68c3`.
2. **Current Maps key:** create a new key, restrict it (below), put it in your local `.env` and `ios/Flutter/GoogleMaps.local.xcconfig`, rebuild, confirm maps work, then **delete the old key**.
3. **The other key in `AndroidManifest.xml` history:** check its usage (Metrics). If unused, delete it; if used, replace it the same way.
4. Check billing/usage for unexpected traffic since August.
5. Rewriting git history isn't necessary once keys are rotated (the old values become useless). If you still want it, that's a separate, destructive step needing your approval.

**Restrictions for the new key(s)** (Google recommends separate keys):
- *Android Maps SDK key:* application restriction Android apps → `com.skillbridge.skill_bridge` + SHA-1 of the debug and release certificates; API restriction **Maps SDK for Android**.
- *iOS key:* iOS apps → your bundle ID; **Maps SDK for iOS**.
- *REST key* (Geocoding, Places API (New), Routes, called from Dart): API restriction to exactly those three APIs. These calls send no Android/iOS identity headers, so app restrictions would block them. The robust long-term fix is to move these REST calls behind a Cloud Function and keep this key server-side (later phase; needs approval).

## 5. App Check configuration

| Build | Android | iOS | Web |
|---|---|---|---|
| Debug (`kDebugMode`) | `AndroidDebugProvider` | `AppleDebugProvider` | `WebDebugProvider` |
| Release / profile | `AndroidPlayIntegrityProvider` | `AppleDeviceCheckProvider` | `ReCaptchaV3Provider(RECAPTCHA_V3_SITE_KEY)`, or **not started** if no key was provided |

Production providers are the same ones the app used before; only the placeholder web key and the debug-build behaviour changed. **Enforcement was not touched.** Its current state can only be checked in the console.

### Manual console steps (when you're ready; none were performed)
1. **Firebase console → App Check → Apps**:
   - **Android:** register Play Integrity and add the **SHA-256** of the debug and release signing certificates (`cd android && ./gradlew signingReport`). Release attestation also needs the app linked in Play Console.
   - **iOS:** register DeviceCheck (or App Attest) with your Apple Team ID and a DeviceCheck key.
   - **Web:** create a **reCAPTCHA v3** site key at <https://www.google.com/recaptcha/admin> for your web domains (add `localhost` for testing). Register its **secret** in App Check → Web. Put the **site** key in `.env` as `RECAPTCHA_V3_SITE_KEY`.
2. **Debug tokens:** run a debug build. The SDK logs a debug token (Android logcat, Xcode console, browser console on web). Add it under App Check → Apps → ⋮ → Manage debug tokens, or set `APP_CHECK_DEBUG_TOKEN` in `.env`.
3. **Enforcement (needs your separate approval):** first watch App Check **metrics** for each product (Firestore, Storage, Functions) until "verified" traffic is close to 100%. Only then enable enforcement product by product. Enforcing early would lock out current app versions that don't send valid tokens.

## 6. Crashlytics behaviour

| Platform | Before | After |
|---|---|---|
| Android / iOS release | Collection on, Flutter and platform errors recorded | **Unchanged** |
| Android / iOS debug | Collection off | **Unchanged** |
| Web | Uncaught error at start-up and on each sign-in/out | Silent no-op; logs "Crashlytics not available on this platform" |
| Windows / Linux desktop | Would throw | Silent no-op |

## 7. How to run now

```
flutter run --dart-define-from-file=.env
flutter build apk --release --dart-define-from-file=.env
flutter build web --release --dart-define=RECAPTCHA_V3_SITE_KEY=<site key>
```
Running without `--dart-define-from-file`, the app still starts. Maps REST features (address search, geocoding, routes) report "key not provided", as they did before when `.env` was missing. The new VS Code launch configs pass the flag automatically. **For web builds, don't pass `GOOGLE_MAPS_API_KEY`:** web has no Maps setup, and the key would be compiled into public JavaScript.

## 8. Test results

| Check | Result |
|---|---|
| `flutter test` (full) | **76/76 pass** (68 previous + 8 new) |
| `flutter analyze` (full) | **62 issues, 0 errors, 0 new** (was 65). The 3 App Check deprecation infos are resolved. |
| `flutter build web --release` | Pass. Build output contains **no `.env`**, no Maps key, no placeholder site key. |
| Web runtime check | Release build started in headless Chrome: renders the login screen; **no uncaught errors or console errors** (previously an uncaught `Error` on every start). |
| `flutter build apk --debug --dart-define-from-file=.env` | Pass (443 s). APK has **no `assets/.env`**. The key is compiled into the Dart code, as expected for a client key, plus the manifest via Gradle (by design). Gradle shows pre-existing Kotlin-plugin migration warnings from third-party plugins. |
| iOS build | Not available on Windows. |

Note: this replaced `build/app/outputs/flutter-apk/app-debug.apk`. The older `app-release.apk` still contains `.env`; rebuild it before sharing.

## 9. Remaining manual steps
1. **Rotate both Google keys** and restrict the replacements (§4). Highest priority.
2. Rebuild any APK/IPA you distribute; delete old builds that contain `.env`.
3. App Check console setup (§5, steps 1–2), then add `RECAPTCHA_V3_SITE_KEY` to `.env` for web release builds.
4. Decide on App Check enforcement only after the metrics look healthy (separate approval).
5. Later phase (approval needed): move the Maps REST calls behind a Cloud Function so no REST key ships in the app.
6. Commit `.env.example` along with this work. `.env` stays local.

Stopping here. Waiting for approval before **Phase 2B: Authentication and Profiles**.
