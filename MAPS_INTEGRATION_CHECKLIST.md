# Maps integration checklist (Google Maps, Track G, 22 Nov 2026)

Full details: `design/G1_REMOVE_OSM_REPORT.md`, `design/G2_GOOGLE_MAPS_REPORT.md`, `design/G3_ROUTES_PLACES_REPORT.md`, and `SKILLBRIDGE_SETUP_GUIDE.md` §3.

## Configuration and security
- [x] Old OpenStreetMap/OSRM/Nominatim stack removed; a hygiene test keeps it out.
- [x] Android key only from `--dart-define-from-file=.env` → manifest placeholder; never in tracked files (test-enforced).
- [x] iOS key from the git-ignored `ios/Flutter/GoogleMaps.local.xcconfig` (template `.example`).
- [x] Web key loaded at runtime (`GOOGLE_MAPS_WEB_API_KEY`); `web/index.html` has no key (test-enforced).
- [x] Server key (Routes, Places (New), Geocoding) only in Secret Manager (`MAPS_SERVER_KEY`); the app calls functions.
- [x] Android key restricted (package + SHA-1, Maps SDK for Android): done by the owner on 21 Nov.
- [ ] Delete/restrict the old key from the former `GoogleMaps.local.xcconfig` (owner).
- [ ] Create the server key, enable the 3 APIs, set quotas, `firebase functions:secrets:set MAPS_SERVER_KEY` (owner).

## Map features
- [x] One map widget (`SbGoogleMap`): no-key, loading and offline states; zoom/recenter; dark style; blue dot only when allowed.
- [x] Picker: move the map under a pin; GPS start; denied/blocked/GPS-off/failed explained; GPS-only fallback without a key.
- [x] Address search (submit only) and the pin's address via Places/Geocoding functions; coordinates as a fallback.
- [x] Road route, distance and ETA (Routes API) on tracking, directions and nearby workers; stale positions get no route.
- [x] Driving guidance hands off to Google Maps (no in-app turn-by-turn, per Google's terms).
- [x] Live location: consent, stop, stale, contract parties only.
- [x] Real rendering on an Android phone with the restricted key (G2).
- [ ] Real routes/search on a phone after the functions are deployed (setup guide §8).
- [ ] iOS build on a Mac.
