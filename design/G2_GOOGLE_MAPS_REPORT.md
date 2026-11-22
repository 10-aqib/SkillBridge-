# SkillBridge — Track G, Phase G2: Google Maps in the app

Status: **done, awaiting your approval for G3 (server routing + places, needs Blaze).** Nothing committed, deployed or pushed. Firestore rules, functions and the data model are untouched.

Date: 21 Nov 2026 · Branch `ui-improvements-2026` · Snapshot of files before G2: `design/nav/.snapshot/g2/`

---

## 1. What was built

| Piece | What it does |
|---|---|
| `google_maps_flutter ^2.18.1` (Android SDK plugin 2.21.0, iOS 2.18.7, web 0.6.5) | The official Google Maps package. `web ^1.1.1` became a direct dependency for the web loader. No other map package. |
| `lib/core/map/sb_google_map.dart` | **The one map widget** every screen uses. Screens pass plain data (`SbMarker`, `SbCircle`, `SbPolyline` in `GeoCoord`s); only this file touches Google types. States: no key → "Map unavailable" (never a grey, unauthorised map); invalid centre (0,0) → unavailable; a loading cover until the map is ready; an offline notice. SkillBridge's own zoom and recenter buttons. The blue "you are here" dot shows only when location is **already** allowed (maps never prompt). A night style in dark mode. Previews have no gestures (the page scrolls over them), and Android lite mode is used for the static pin preview. `SbMapController.fit()` frames points with a zoom cap, so two close points don't fill the screen. |
| Marker colours | Destination/pin red · person azure · selected person orange · chosen search centre green · out-of-date positions faded. |
| `lib/core/map/maps_config.dart` + `maps_platform_io.dart` / `maps_platform_web.dart` | `mapsAvailableProvider`: on mobile, whether the build has `GOOGLE_MAPS_API_KEY`. On web, the Maps JavaScript API is **loaded at start-up** with a separate `GOOGLE_MAPS_WEB_API_KEY`, so no key is ever written into `web/index.html`. A rejected key (`gm_authFailure`) switches maps to "unavailable". Conditional imports keep the Android key out of web builds. |
| Android key | `android/app/build.gradle.kts` reads `GOOGLE_MAPS_API_KEY` **only from the build's dart-defines** (`--dart-define-from-file=.env`) into a manifest placeholder. The manifest holds `${mapsApiKey}`, never a key. A build without the env file contains an empty key (checked in the merged manifest). |
| iOS key (code only, can't be built here) | `AppDelegate.swift` calls `GMSServices.provideAPIKey` with `Info.plist` `GoogleMapsApiKey = $(GOOGLE_MAPS_API_KEY)`, which comes from the git-ignored `ios/Flutter/GoogleMaps.local.xcconfig` (template: `GoogleMaps.local.xcconfig.example`, included by Debug/Release xcconfig). This is the same pattern the app used before NAV3. |
| `.env.example` | `GOOGLE_MAPS_API_KEY` and `GOOGLE_MAPS_WEB_API_KEY`, with the exact restrictions to apply. Names only. |

## 2. Screens now on Google Maps

| Screen | Map |
|---|---|
| **Location picker** (worker profile area, nearby-workers centre, contract address pin) | Move the map under a fixed pin, with a hint chip ("Move the map…" / "Zoom in…"). It starts at the GPS fix (zoom 17) or the kept place, otherwise a whole-Pakistan view. Confirm works only at street zoom (≥ 13). All permission, GPS-off and failure banners are kept. **Without a key it falls back to the G1 GPS-only picker**, so job/profile flows never break. Address search comes in G3 (Places API, server key). |
| **Worker directions** | Destination marker, blue dot if allowed, zoom buttons. "Directions in Google Maps" handles the driving. No pin → no map, with an explanation. |
| **Client tracking** | Worker marker (faded when not live), pin marker, accuracy circle. The camera follows each live update until the client touches the map; recenter resumes following. |
| **Contract details** | Pinned-place preview (lite mode) and the live-position preview, which follows updates. Both have "View on map" / "Open in maps" links to Google Maps. |
| **Nearby workers (map view)** | Search-radius circle, worker markers (tap to select; the selected one turns orange and the camera frames centre + worker), green marker for a chosen centre, blue dot for the device centre. |

Also fixed: the "Tell the client I've arrived" confirmation is now inline on the button. The snack bar that covered "Start work" (found in G1) is gone.

## 3. Verification actually done

| Check | Result |
|---|---|
| `dart analyze lib test` | **0 errors**. The same 5 old warnings in files G2 didn't touch. New map files: "No issues found". |
| `flutter test` (full suite) | **427 passed, 0 failed** (3 min 37 s; G1 had 409). |
| New tests | A fake map view (`test/helpers/fake_map.dart`) records exactly what each screen asks Google to draw and where it moves the camera. **SbGoogleMap:** no key → unavailable, (0,0) refused, markers/circles passed, loading cover, offline notice, controls only when asked, no controls on previews, blue dot only when allowed, dark style. **Picker with map:** GPS moves the camera, confirm returns the centre with GPS accuracy, panning picks a new spot with unknown accuracy, can't confirm while zoomed out, denied permission explained, kept place without GPS. **Directions/tracking:** destination marker, no map without a pin, worker/pin/accuracy, follows updates, stops after a touch, recenter resumes, stale marker faded. **Hygiene:** key only via dart-defines and placeholder, iOS xcconfig git-ignored, no key or Maps script in `web/index.html`, no `AIza` in tracked config. |
| Android debug APK, no key | **Built.** The first attempt failed: the Kotlin build script couldn't resolve `java.util.Base64`. Fixed with an import, then rebuilt OK. Merged manifest: `com.google.android.geo.API_KEY` = empty. |
| Web release, no key | **Built** (`dart2js` accepts the JS-interop loader). |
| **On a real phone, with your restricted key** | Test build (a harness entrypoint kept **outside the repo**, sample points, no Firebase) installed on your phone over adb. **Maps rendered:** the SDK loaded the latest renderer with no authorization errors, so the key and its restriction accept this PC's debug signing. Screenshots checked: tracking map with all marker kinds, accuracy circle, a polyline, camera fit, zoom/recenter buttons, Google logo visible; **dark mode** night style; **location picker** with the fixed pin, hint chip and Confirm enabled. The previews page wasn't captured because you were using the phone; it uses the same widget (lite mode is the only difference). |

**Your phone:** it now has the test build in place of SkillBridge. Reinstall your normal build (GitHub release v1.1.0), or ask me and I'll build and install this branch's real app.

## 4. Not done / open
- **Address search and reverse geocoding:** G3, through the Places API (New) behind a callable function with the server key in Secret Manager. Until then the picker returns coordinates as the address, as before.
- **Road distance/ETA and route lines on real screens:** G3 (Routes API). `SbPolyline` is ready and drawn on the device test.
- **Job location before applying (D6, new):** jobs store only city + area. The exact place is pinned **after hiring** (privacy by design since S3/S4). The rules already allow a job `location` field, but the app never sets it. Your call: (a) keep it as is (recommended for privacy); (b) let clients optionally pin an *approximate* spot (about 500 m) that workers see on the job page; (c) an exact pin visible to every worker.
- **Marker heading:** default pins don't rotate, so the worker's direction isn't drawn. A custom arrow icon could come later if you want it.
- **iOS:** wired, not built or tested (needs a Mac).
- **Web:** loader built but not run with a real web key (you'd need a referrer-restricted key; only for emulator testing).
- **Release APK** with the key: G7.

## 5. Decisions for you
1. Approve G3? It needs **Blaze confirmed (D1)** plus a **server key** (Routes API + Places API (New) only) that you enter with `firebase functions:secrets:set`. I write the functions and client code either way; deploying needs Blaze and your go-ahead.
2. D6 above (job location before applying).
3. Still open from G0: D3 (Storage instead of Cloudinary), D4 (saved jobs / account deletion).
