# SkillBridge — Navigation Phase 10: end-to-end verification, review and final summary

Status: **verified locally. Nothing deployed, committed or pushed.** One backend bug was found and fixed in this phase (§2). No rules changed in this phase. You authorised Phase 10 in advance ("start next phase when phase 9 completes"). This is the last phase; I'm stopping here for your review.

## 1. Summary

| Check | Result |
|---|---|
| Backend end-to-end on the Firebase emulators, as real users (Auth, Firestore rules and the compiled Cloud Functions; demo project) | **30 / 30** after the fix in §2 |
| UI end-to-end: client and worker, two app instances side by side against the same emulators | **Passed**: pin → directions → share → live map → arrival → "I've arrived" → start → submit → sharing removed (§3) |
| Security and privacy review | No blocking issue. Three production notes on third-party map services (§4) |
| Performance and battery review | Within the Phase 1 targets (§5) |
| Full regression (tests, analyzer, builds) | **All green**: app 461/461, functions 54/54, rules 125/125, analyzer no new issues, APK and web builds passed (§6) |

## 2. Bug found and fixed: pinning the place failed on the real Functions runtime

- **Symptom:** on the emulator, "Share with the worker" **with a pin** failed with `INTERNAL`. The function log showed `admin.firestore.GeoPoint is not a constructor`. Text-only addresses still worked.
- **Why the tests missed it:** the function unit tests use a fake database and passed (54/54). Only the real runtime exposed it: the Functions emulator wraps the namespaced `admin.firestore`, and the `GeoPoint` constructor is missing there.
- **Fix** (`functions/src/contracts.ts`, 3 lines): import `GeoPoint` from the modular `firebase-admin/firestore`, which the file already used for `FieldValue`. I didn't test whether production Cloud Functions has the same gap. The modular import works in both, and it's the documented form.
- **Re-checked:** function tests 54/54; emulator probe 30/30; pin set from the real app UI (§3).
- Pre-fix copy: `design/nav/.snapshot/nav10/functions/src/contracts.ts`.

## 3. End-to-end runs

### 3.1 Backend probe (`scratchpad/e2e/probe.py`, test only, outside the repo)
Three real emulator accounts (client, hired worker, unrelated worker) with random passwords, plus a seeded job and active contract. All 30 checks passed:
- **Pin:** the client sets it with the address and it's saved as a GeoPoint with a server time. The worker can't set it. Out-of-range, `0,0`, string and malformed pins are refused. A text-only update (from an older app) keeps the pin. The client can remove it.
- **Contract:** readable by the hired worker; refused to the unrelated worker.
- **Live position:** the worker writes position, accuracy, heading and speed. A missing heading or speed is cleared, so no stale arrow is left behind. Refused: heading over 360, speed over 100 m/s, unknown fields, writes from the client or the unrelated worker, and writes without the server time. The client reads it, including heading and speed; the unrelated worker and signed-out requests can't.
- **Rest of the job:** "I've arrived" posts once, and the same request id again posts nothing. Start and submit work. **Submitting deletes the live position, and no new position is accepted afterwards.**

### 3.2 UI run (real app, web release build of a test entry point outside the repo)
The test entry point uses a demo project (`demo-skillbridge`, fake API key), so nothing can reach the real project. It talks only to the emulators, keeps sign-in in memory, and starts no App Check, Crashlytics or push. **The GPS was simulated at browser level (test only)**: a fake position source walked the real OSRM road route at 14 m/s. The app code ran unchanged. Screenshots are in `design/nav/nav10/screens/`.

| Step | Seen |
|---|---|
| Client: share address and **pin it on the map** (01–02) | The picker opened at the device position. Nominatim filled in the address. "Pinned on the map" with Change/Remove, then "Address shared with the worker" with a pin preview. The contract on the emulator holds the exact GeoPoint. |
| Worker: contract | **Start navigation** enabled as soon as the pin arrived (live Firestore update). |
| Worker: route choice (03) | "Route to House 12, Street 4, near Hazuri Bagh…": **7 min · 4.5 km** (fastest) and 7 min · 6.2 km (alternative), from the real OSRM server. |
| Worker: guidance + **share toggle** (04) | Turn card ("160 m, Turn right onto…"), heading-up map, the consent sheet, then a green share button. The live document held position, accuracy, **heading 303°, speed 14**. |
| Client: contract card (07) | Changed from **Not live · 4 min ago** to **Live · Updated just now** without a reload. |
| Client: **Open live map** (05, 08) | Worker pin with the amber direction arrow, the pinned place, and the road route. **"4.3 km by road · about 6 min"**, then 3.7, 2.8 and 1.5 km as the worker drove; "Arrives about 7:42 PM", the same as the worker's own estimate. |
| Stale (06) | With the worker's app closed for over 2 min: grey pin, **Not live**, warning, **no route and no time**. |
| Arrival (09) | Worker: "You have arrived", with **Tell Ayesha Khan I've arrived**, Start work and Done. Client, at the same moment: "**Bilal Ahmed is at the place.**" |
| Tell + Start work (10) | "Ayesha Khan has been told you've arrived." The client sees the progress update "I've arrived at the place." and **In progress**. |
| Submit work | Live document **deleted** (404), and still deleted later. The Live location card is gone on both sides; the client sees Confirm completion / Ask for changes. The pin stays on the contract. |

**Harness limitation (not an app bug):** the browser pane stalls background tabs, so the worker's tab stopped publishing whenever the client's tab was in front. The final run therefore had both app instances side by side in one visible page. Real phones run each app in the foreground on separate devices.

**Expected console noise (test build only):** Firebase Analytics rejects the fake demo API key ("API key not valid"). No user data is involved, and the real app has a real key.

Not covered by the UI run (covered elsewhere):
- The unrelated user opening `/navigate` or `/track`: covered by widget tests (Phase 9) and the rules probe (§3.1).
- Voice output: covered by tests (Phases 7 and 9) and the browser check in Phase 9.
- Real device GPS and Android/iOS permission prompts: not available here (§7).

## 4. Security and privacy review

| Area | Finding |
|---|---|
| Who sees the live position | Only the two parties to the contract and admins can read it. Only the hired worker can write it, only while the contract is active and not awaiting review, with an allowlist of 7 fields, range checks and server time. It's deleted on submit. Tested on the emulator (§3.1) and by 125 rules tests. |
| Who sees the pin | It's stored only on the contract (parties and admins), and only the client can set it, through `contractActionCall`. It isn't copied to the public job. The function validates the range and refuses `0,0`. |
| Screens | Navigation only for the hired worker on an active job. Tracking only for the client. Both stop before any GPS or network use otherwise. |
| Consent | Sharing always starts with an explicit sheet that says who sees it and when it stops. It stops on Stop, on submit and when the contract ends. Foreground only (decision D). |
| Logs | No coordinates or tokens in app logs; the scan found no `print`/`debugPrint` in the navigation code. `GeoFix.toString` is safe (Phase 4). |
| Secrets | None in the navigation code. The Google Maps key and its build wiring were removed (Phase 3). OSM, OSRM and Nominatim need no key. |
| Retention | The live document is deleted on submit or end. A stale document from a closed app is shown as **Not live** and never as current. |
| **Third-party services (production note)** | The defaults are the public OSM/OSRM servers. (1) **Routing** sends the worker's position and the pinned place to `router.project-osrm.org`, a demo server with no privacy or uptime guarantee. (2) **Tiles** from `tile.openstreetmap.org` fall under its usage policy, which is not for heavy app traffic. (3) **Nominatim** gets the pin for the reverse address lookup; release builds default to no search (Phase 2). All three are switchable at build time (`ROUTING_BASE_URL`, `MAP_TILE_URL`, `GEOCODING_PROVIDER`/`GEOCODING_BASE_URL`). **Recommendation before a public release:** a self-hosted or commercial OSRM and tile provider, and a mention in the privacy policy. Not a code change. |

## 5. Performance and battery

| Area | Value |
|---|---|
| GPS while navigating | `bestForNavigation`, 5 m filter, 1 s interval. Only while the navigation screen is open; the screen stays awake while it is. |
| GPS while only sharing | `high`, 10 m filter, 5 s interval. One shared tracker serves navigation and sharing, so there's never a second GPS stream (Phase 8). |
| Firestore writes while sharing | At most one per 15 s, plus a 60 s heartbeat while standing still: **≤ 4 writes/min**. The client listens to one document. |
| Routing requests | Worker: one per start, plus reroutes with a 15 s cooldown. Client: at most one per 150 m moved or per 2 min. Spaced to 1 req/s on the public server. |
| Tiles | flutter_map's built-in HTTP caching. No tiles are downloaded for offline use. |
| Background | None (decision D). Everything stops when the screen closes or the app is backgrounded. |

## 6. Regression

| Check | Result |
|---|---|
| `flutter test` | **461 / 461 passed** |
| `functions` `npm test` | **54 / 54 passed** (includes the 2 pin tests) |
| `rules-tests` `npm test` (emulator) | **125 / 125 passed** |
| `dart analyze lib test` | 0 errors, 5 warnings, 28 infos: **no new issues** (same as Phase 9) |
| `flutter build apk --debug` | **passed** |
| `flutter build web --release` | **passed**; the bundle has 0 Google Maps references |

## 7. Not verified here
- Real Android/iOS devices: GPS quality, permission prompts, the platform TTS voices, and the screen staying awake. Only the web build and the debug APK build were checked.
- Production Firebase: nothing deployed (on purpose).
- Heavy load on the public OSM/OSRM servers (see §4).

## 8. Deployment order (for when you decide to deploy; nothing done)
1. **Cloud Functions** (`contractActionCall`: optional pin, with the §2 fix). Older apps keep working.
2. **Firestore rules** (optional `heading`/`speed` on the live document). **Deploy these before releasing the app**, or a new app's live writes are refused and sharing stops.
3. **App release.** If you're going public, set `ROUTING_BASE_URL`, `MAP_TILE_URL` and the geocoding settings to production providers first (§4).

No data migration or backfill is needed.

## 9. Files changed in Phase 10
- `functions/src/contracts.ts`: the GeoPoint import (§2).
- New: this report and `design/nav/nav10/screens/` (10 screenshots); snapshot at `design/nav/.snapshot/nav10/`.
- No other repo files changed. The test entry point, probe, seed, GPS simulator and emulator config are in the session scratchpad, outside the repo. `.claude/launch.json` was restored to its original content.

---

# Final summary: Navigation Phases 1–10

| Phase | Delivered |
|---|---|
| 1 Architecture | Inspection and plan. Your decisions: the client pins the place; replace Google Maps everywhere; add heading/speed; foreground only. |
| 2 Dependencies | flutter_map, latlong2, flutter_tts, wakelock_plus; configurable tile, routing and geocoding providers; platform settings. |
| 3 OSM maps | Every Google map replaced with `SbMap` (OSM); Google Maps package, key and build wiring removed; new location picker. |
| 4 GPS | `DeviceLocationTracker`: accuracy profiles, freshness and signal-loss checks, safe errors. |
| 5 Routing | OSRM service: alternatives, snap-distance guard, honest errors; road route on the nearby-workers map. |
| 6 Turn-by-turn | Navigation screen: states, instruction card, trip panel, route choice, arrival, End. |
| 7 Voice + rerouting | Spoken guidance in English and Urdu, mute, off-route detection, rerouting with cooldown. |
| 8 Live sync + pin | Destination pin through `contractActionCall`; live position with heading/speed; one shared GPS tracker. |
| 9 Job integration | Worker: Start navigation, share toggle, tell-client on arrival. Client: live tracking screen. |
| 10 Verification | Emulator end-to-end (backend 30/30, two-device UI), review, regression; one backend fix. |

**Not changed anywhere:** Firebase, authentication, roles, existing job and contract workflows, collections. Rules got one additive change (Phase 8). No dummy data and no simulated location in the app: the GPS simulator exists only in the test harness outside the repo.
