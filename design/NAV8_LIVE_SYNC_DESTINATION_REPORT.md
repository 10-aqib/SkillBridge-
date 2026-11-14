# SkillBridge — Navigation Phase 8: job destination pin and live location sync

Status: **implemented and tested locally. Nothing deployed, committed or pushed.** The rules change and the function change were tested on the emulators and with the function tests only. You accepted this phase in advance ("accept and continue next phase when finished"), so Phase 9 follows straight on.

## 1. Summary

| Area | Result |
|---|---|
| Destination pin (function) | `contractActionCall` → `shareAddress` takes an optional `location` `{lat, lng}`. It's validated as a real map position (numbers, in range, not 0,0) and saved as `contracts/{id}.serviceLocation` (GeoPoint) with `serviceLocationSetAt`. `null` removes the pin; **leaving it out keeps it**, so older app versions that send only the text can't wipe a pin. Only the client, and only while the contract is open (unchanged rule). Contracts are already readable only by the two parties and staff, and users can't write contracts, so **no rules change was needed for the pin**. |
| Destination pin (app) | `ContractEntity.serviceLocation` (`LatLng`) / `serviceLocationSetAt`. The data source sends the pin only when it changed, or a clear when removed. <br>**Client's address sheet:** "Place on the map" with privacy help ("Only the worker you hired sees it"), "Pin it on the map" (the Phase 3 picker: search, move the map, confirm), the pinned coordinates, Change pin and Remove pin. An empty address is filled from the map's address, never from bare coordinates. <br>**Contract details:** "Pinned on the map", or for the worker "The client hasn't pinned the place on the map yet." 7 new en + ur strings. |
| Live location: direction and speed | **Rules** (approved in NAV1): `contracts/{id}/live/location` also accepts optional `heading` (0–360) and `speed` (0–100 m/s). The key allowlist, the hired-worker-only write, the server-time stamp, the active and not-submitted window and the parties-only read are all unchanged. <br>**Writer:** direction only while moving (reliable heading), speed when reported; both are **removed** on the next update when not available, so the client never sees a stale arrow. <br>**`LiveLocation`** reads both. |
| One GPS stream | The tracker is now **shared by name**: navigation asks as "navigation", live sharing as "sharing". One stream runs with the most demanding profile among them. Ending navigation drops back to the sharing profile **without stopping sharing**; GPS stops only when the last one releases it. Live sharing now gets its positions from this stream instead of opening its own, which halves GPS use when both are on. The first write still uses an immediate fix, and the 60 s heartbeat is unchanged. |
| Standing still is not "signal lost" (fix of a Phase 4 bug) | Phones send **no updates while not moving** (distance filters), and the tracker treated that silence as a lost signal. Stopped at a traffic light for 12 s, navigation would have shown "GPS signal lost". Before marking the signal lost, the tracker now asks the device for **one fresh fix**: standing still carries on, and only a failed fix (tunnel, indoors) counts as lost. While lost it keeps asking now and then, so it recovers even without moving. |

## 2. Checks

| Check | Result |
|---|---|
| `flutter test` | **451 / 451 passed**: 444 + 7 new. Tracker 3 (shared stream; standing still; real loss then recovery); navigation 1 (ending navigation keeps sharing's GPS); contract screen 3 (pin shown or missing; remove sends a clear; text-only update keeps the pin). The Phase 4B sharing tests now run through the shared tracker and all pass. |
| Cloud Function tests (`functions`, `npm test`) | **54 / 54 passed** (2 new): set, keep on a text-only update, clear with null; bad pins refused (out of range, 0/0, strings, NaN, missing), and nothing saved; workers can't pin. |
| Firestore and Storage rules (`rules-tests`, `npm test`) | **125 / 125 passed on the real emulators** (1 new): heading and speed accepted in range and clearable; out-of-range, negative and text values refused; still only the hired worker. The old "unknown field" check now uses `battery` (since `speed` is allowed). |
| `dart analyze lib test` | 0 errors, 5 warnings, 28 infos: **no new issues**. |
| `flutter build apk --debug` | **passed** (524 s) |
| `flutter build web --release` | **passed** (456 s) |
| Line endings | All edited files kept LF. |

**Not done:** a live end-to-end run with two browsers on the emulators (client pins, worker sees, positions with direction). That is part of Phase 10's full end-to-end pass, along with Phase 9's screens.

## 3. Deployment order (for when you decide to deploy; nothing done)

1. **Functions** (`contractActionCall`): accepts the optional pin. Older apps keep working (no pin sent means unchanged).
2. **Firestore rules:** they accept `heading`/`speed`. **Deploy these before releasing the app.** A new app writing heading/speed under the old rules has its writes refused, and sharing stops ("ended"). Older apps write neither field, so they are fine under the new rules.
3. **The app release.**

No backfill is needed. Contracts without a pin simply have none, and the worker sees "not pinned yet".

## 4. Builds
Both passed, with temporary files on drive F:.

## 5. Files

Backend (local only):
- `functions/src/contracts.ts`: optional `location` on `shareAddress`, `pin()` validation.
- `functions/test/contracts.test.js` (+2 tests); `functions/test/fake_db.js`: supports field deletes.
- `firestore.rules`: `heading`/`speed` on the live doc.
- `rules-tests/rules.test.js` (+1 test, 1 adjusted).

App:
- **Contracts:**
  - `contract_entity.dart`, `contract_model.dart`, `contract_remote_datasource.dart`: the pin.
  - `contract_details_screen.dart`: pin status, and the pin step in the address sheet.
  - `live_location.dart`: heading and speed.
- **Location:**
  - `core/services/location_tracking_service.dart`: sharing on the shared tracker; heading and speed written and cleared.
  - `core/location/device_location_tracker.dart`: `request`/`release`, and the fresh-fix check before "lost".
- **Navigation:** `navigation_controller.dart` uses the tracker as "navigation".
- **Strings:** ARB files and generated l10n.

Tests:
- `test/helpers/fake_contracts.dart`, `fake_location.dart` (one-shot fix control)
- `contracts_4b_test.dart`, `contracts_screens_test.dart`, `device_location_test.dart`, `navigation_controller_test.dart`

Snapshot: `design/nav/.snapshot/nav8/` (23 files, taken before editing).

## 6. Next: Phase 9 (hirer live tracking and worker integration)
- **Worker, on an accepted job:** View on map, Start navigation (only with a pin; otherwise explained), share and stop live location from the navigation screen too, and "I've arrived" (posts the existing progress update) with Start work.
- **Client:** a full-screen live tracking screen. It shows the worker's live position with direction, the destination, the road route from the worker with distance and time left, "updated … ago", accuracy, and a clear stale or offline state; never old positions shown as live.
- **Routes:** `/contracts/:id/navigate` and `/contracts/:id/track`, opened from the contract and checked against the signed-in party (worker or client).
