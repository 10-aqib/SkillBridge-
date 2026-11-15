# SkillBridge — Free plan, Phase S2: identity and public profiles

Status: **implemented and tested locally. Nothing deployed, committed or pushed.** These rules aren't deployed on purpose: the new rules go live together with the new app in S8, because they only fit the new app. Production still runs the old rules plus the 14 Nov admin hotfix. Awaiting your approval for Phase S3.

## 1. Summary

| Area | Result |
|---|---|
| Roles | **No change needed.** Client/worker roles were already read from the protected `users` document. Admin comes from a sign-in claim, which staff set with the Admin SDK script (`functions/scripts`) **without Blaze**, because custom claims don't need Cloud Functions. The plan expected more work here. |
| Public profiles | Each person's app now **writes their own** `publicProfiles/{uid}` (`PublicProfileSync`, started once at the app root). It writes only when the public view changes. On first launch it also **creates profiles for existing accounts**, which never got one because the functions never ran. |
| What the rules allow in a public profile | Only allowlisted fields, so nothing private can be published: no phone, email, address, push token, CNIC, earnings or verification status. Role, active status, CNIC badge, rating, review count, account date, and the worker's verified badge, average rating, review count and **jobs completed** must equal the private account. "Email/phone verified" is accepted only when the sign-in token confirms it. Locations must be at ~1 km precision. A client can't publish a worker profile. Only the owner can write or remove their profile; anyone signed in can read. |
| **Reputation hardening** | Found while doing this. The private account let an owner **add any rating or review count** if none was stored, and `totalJobsCompleted` wasn't protected at all. That was harmless while the account was private, but the public profile now shows these values. New accounts must now start at the app's defaults (rating 5 or 0, no reviews, no completed jobs). Owners can never change, add, remove or reset these numbers, and can't delete the worker profile (deleting and recreating it would reset the stats). In S5, reviews will update them in a checked transaction. |
| `liveLocations` | Not used by the app (live tracking uses the contract's own live document), and nothing writes it now. Kept closed, with a comment explaining why. |

## 2. Trade-off (stated plainly)
Self-description (name, headline, bio, skills, rates, availability, photos) was always the owner's own text. The function only copied it, so nothing is lost there. **The coarse location and geohash are now computed by the owner's app.** A worker could publish a different ~1 km area than their real one, but they could already set their own location to anything. Everything other people *rely on* is still enforced by the rules.

## 3. Tests

| Check | Result |
|---|---|
| Rules tests (emulator) | **130 / 130 passed.** The old "only the function writes public profiles" test was replaced by 4 tests: owner writes with no private fields; no faked role, status, reputation or badges, while token-confirmed badges and matching reputation are accepted; ~1 km locations only, and clients can't publish a worker profile; owner delete. Plus 2 new reputation tests: new accounts start empty; no change, add, remove or reset. |
| App unit tests (new) | **13 / 13**: the public view keeps only allowlisted fields; ~1 km location with geohash; hidden location stays hidden; certificates trimmed to name, issuer and year; badges need confirmation; clients publish no worker data; the sync creates, skips unchanged, doesn't rewrite after restart, repairs stale profiles, writes changes, survives a refused write and retries, and writes nothing without an account. |
| Full `flutter test` | **474 / 474 passed** (461 before + 13 new) |
| `dart analyze lib test` | 0 errors, 5 warnings, 28 infos: **no new issues** |

## 4. Files
- `firestore.rules`: public profile rules; reputation protection on `users`.
- New: `lib/core/services/public_profile_sync.dart`, `test/unit/public_profile_sync_test.dart`.
- `lib/app.dart`: starts the sync.
- Comments only: `firestore_paths.dart`, `worker_profile_provider.dart`, `worker_remote_datasource.dart`.
- `rules-tests/rules.test.js`: 6 tests changed or added.
- Snapshot: `design/spark/.snapshot/s2/`.

## 5. Notes for later phases
- **Existing production data:** accounts created under the old permissive rules may already hold odd values (for example a self-set rating). The new rules keep whatever is stored; they don't clean it. Check `users` in the console before S8, along with the admin check from S1.
- S5 (reviews) must update the reviewee's `users` stats **and** public profile in one transaction. The rules for that come in S5.
