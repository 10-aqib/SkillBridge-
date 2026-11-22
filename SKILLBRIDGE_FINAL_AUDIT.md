# SkillBridge — Final audit (Track G, 22 Nov 2026)

Branch `ui-improvements-2026`, **uncommitted** working tree (nothing committed, pushed or deployed during Track G). Phase reports: `design/G0_DISCOVERY_REPORT.md` … `design/G6_ACCOUNT_SAVED_SETTINGS_REPORT.md`, plus G7 verification in §8 below. Setup and deploy steps: `SKILLBRIDGE_SETUP_GUIDE.md`. File-level changes: `SKILLBRIDGE_IMPLEMENTATION_LOG.md`.

## ⚠️ Read first: what is not live yet
1. **Nothing from Track G is deployed.** Production still runs the v1.1.0 rules and has **no Cloud Functions and no Storage** (Cloud Functions API was disabled on 21 Nov). Everything below is built and tested locally and on emulators; it goes live only after the account owner:
   - (a) turns on **Blaze** with a budget alert;
   - (b) enables the Maps/Routes/Places/Geocoding APIs and creates the restricted keys;
   - (c) sets the `MAPS_SERVER_KEY` secret;
   - (d) enables **Storage**;
   - (e) deploys functions, then rules, then releases the app (setup guide §7).
2. Until then the new app **degrades safely**: maps work (client key); routes, address search, push, photo uploads and account deletion say "not available" or hide themselves.
3. **Nothing is committed.** Review and commit the working tree yourself (about 90 changed/new files; the snapshots in `design/nav/.snapshot/g1…g5/` are only recovery copies and needn't be committed).
4. Your phone (adb `33221FDH20042E`) still has the **G2 map test build** installed in place of SkillBridge. Reinstall a normal build.

---

## 1. Project overview
| | |
|---|---|
| App | Flutter 3.44 (Dart 3.12), Riverpod 3, go_router 17, Hive offline cache/outbox. English + Urdu. Light/dark. |
| Platforms | **Android** (primary, built and run on a phone); **web** (compiles; used for emulator testing; no push); **iOS** (configured, not buildable on this Windows PC). |
| Backend | Firebase project `skill-bridge-c68c3`: Auth (email, Google), Firestore, **Storage** (G4), **Cloud Functions gen 2, Node 22** (G3/G5/G6), FCM (G5), App Check (activated, not enforced), Analytics, Crashlytics. |
| Design | Business actions (proposals, the 13-step contract state machine, chats, ratings, public profiles) are app **transactions checked by `firestore.rules`** (free-plan phases S2–S5, kept). Functions do only what an app must not: Google API calls with a secret key, trusted notification text and push, copies in other people's records, account deletion. |
| Admin | `super_admin_web` (Next.js, Admin SDK, `SUPER_ADMIN` claim). Unchanged in Track G. |

## 2. Feature completion matrix
Status words: COMPLETE = implemented and tested; PARTIAL = works with stated limits; BLOCKED = code done, needs an account-level step; MISSING = not built.

| Feature | Initial (G0) | Final | Implementation | Test evidence |
|---|---|---|---|---|
| Sign up / sign in (email, Google), role choice | COMPLETE | COMPLETE | unchanged | existing tests (469 total pass) |
| Password reset / email verification | COMPLETE | COMPLETE | + "Change password" in Settings (G6) | widget tests |
| **Account deletion** | MISSING | **BLOCKED** (needs functions deployed) | `deleteAccount` function + Settings flow (G6) | 3 function tests, 7 widget tests |
| Profiles, public profile mirror, protected fields | COMPLETE | COMPLETE | unchanged | rules tests |
| **Profile picture** upload/replace/delete | BLOCKED (Cloudinary unset) | **BLOCKED** (needs Storage enabled) | Firebase Storage, byte check, resize, progress, cancel, safe replace/delete (G4) | 11 unit + 6 widget + Storage rules tests |
| Photo shown everywhere after change | PARTIAL | **BLOCKED** (needs functions) | public profile (app) + `refreshProfileCopies` trigger (G5) | function tests + emulator e2e |
| Jobs: post, edit, close, browse, search, filter | COMPLETE | COMPLETE | unchanged | existing tests |
| **Saved jobs** | MISSING | **COMPLETE** (rules deploy needed in prod) | `users/{uid}/savedJobs`, bookmark, screen (G6) | 3 rules + 3 widget tests |
| Proposals, accept/reject, duplicate guard | COMPLETE | COMPLETE | unchanged | rules tests |
| Contracts (13 steps), live location | COMPLETE | COMPLETE | unchanged (map UI changed) | rules + widget tests |
| Reviews / ratings | COMPLETE | COMPLETE | unchanged | rules tests |
| Real-time chat, unread, read receipts, retry, paging | COMPLETE | COMPLETE | unchanged (S5) | existing tests |
| In-app notification centre | COMPLETE | COMPLETE | + mark all read, swipe delete, error retry, 100 limit, job/proposal taps (G5) | 6 widget tests |
| Trusted notification text | PARTIAL | **BLOCKED** (needs functions) | `onNotificationCreatedV2` rewrites/validates (G5) | 12 function tests + emulator e2e |
| **Push (FCM)** foreground/background/closed | PARTIAL (no sender) | **BLOCKED** (functions + device check) | per-device tokens, sign-out cleanup, background handler, tap routing, settings (G5/G6) | unit/widget tests; real delivery **not** verified |
| Notification preferences | MISSING | COMPLETE (rules deploy) | Settings switches, read by the push function | 2 rules + 1 widget test |
| **Maps** (Google) | OSM | **COMPLETE** | `SbGoogleMap` on all map screens (G1/G2) | widget tests + **rendered on the user's phone with the restricted key** |
| Location picker | OSM | COMPLETE (search/address BLOCKED) | Google map picker; GPS fallback without key; search + address via functions (G2/G3) | 15 widget tests |
| **Routes, distance, ETA** | OSRM | **BLOCKED** (needs functions + server key) | `computeRoute` (Routes API) on tracking, directions, nearby (G3) | 12 function tests, emulator, widget tests |
| Turn-by-turn navigation | in-app (OSM) | **Removed by decision (D2)** | hand-off to Google Maps app | link tests |
| Live location sharing (consent/stop/stale) | COMPLETE | COMPLETE | unchanged logic; Google map | widget tests |
| Admin web | COMPLETE | COMPLETE (not re-tested) | unchanged | — |
| EasyPaisa screen | display only | display only (by design) | unchanged | — |
| Job location before applying (D6) | city/area | city/area (kept by decision) | — | — |

## 3. Firebase security audit
- **Firestore rules** (live S8 set + G changes):
  - Least privilege; default deny; no `allow … if request.auth != null` catch-alls.
  - The users self-promotion hole was closed earlier (14 Nov).
  - G changes:
    - `mapsUsage` is server-only by default deny;
    - notifications can only be marked read (no rewriting) and can't be claimed verified/pushed by a client;
    - `fcmTokens` has a fixed shape with at most 10 devices;
    - `savedJobs` is owner-only and needs a real job;
    - `notificationPrefs` are bool-only.
  - **171 emulator rules tests pass.**
- **Storage rules:**
  - Public photo folders: owner-only create; JPEG/PNG/WebP; under 2 MB; safe names; no overwrite; owner delete.
  - The old wide rules (any folder, PDFs, files directly under `users/{uid}`) are removed.
  - The default rule is deny-all. Tested in the same suite.
- **Admin:** `SUPER_ADMIN` custom claim (Admin SDK script), never a Firestore field.
- **Functions:**
  - All callables need sign-in, checked first.
  - Inputs are validated.
  - Per-user hourly limits, plus `maxInstances` caps.
  - The secret is in Secret Manager.
  - Logs hold no keys, coordinates, message text or tokens.
- **Removed attack surface:** the undeployed legacy callables (`contractActionCall` etc.) that bypassed the rules' state machine.
- **Secrets scan** (tracked files, excluding `node_modules` and `design`):
  - No private keys or service accounts.
  - No Google keys except the **public Firebase client keys** in `lib/firebase_options.dart`; restrict those to Firebase APIs.
  - `.env` and `super_admin_web/.env.local` are git-ignored.
  - The stray iOS Maps key file was moved out of the repo; **delete that key in Cloud console**.
- **App Check:** active (debug/Play Integrity/reCAPTCHA); **enforcement off**, as it should be until attested traffic is confirmed and while the APK ships outside Play. Turning it on for Firestore/Storage/Functions is a later, console-only step.

**Remaining risks:**
- (1) Notification text from old app versions shows for about a second before the function rewrites it.
- (2) Public photo links are readable by anyone who has the link (by design for profile/job photos).
- (3) `functions/node_modules` (12,934 files) is committed to git. That's repo bloat, not a leak; untrack it with `git rm -r --cached functions/node_modules`.

## 4. Google Maps audit
- **Old provider removed** (G1):
  - packages `flutter_map`, `latlong2`, `flutter_tts`, `wakelock_plus`;
  - OSRM, Nominatim and tile code, the navigation engine, voice, rerouting;
  - 86 strings and 10 tests;
  - the TTS manifest query.
- **Verification:** `git grep` finds no OSM/OSRM/Nominatim in app code; a hygiene test enforces it.
- **Android:** `google_maps_flutter 2.18.1`. The key comes only from `--dart-define-from-file` through a manifest placeholder (a keyless build has an empty key, verified).
- **iOS:** AppDelegate + Info.plist + git-ignored xcconfig (not built).
- **Web:** Maps JS loaded at runtime with its own key (none in `index.html`).
- **APIs:** Maps SDK Android/iOS, Maps JS (optional), Routes, Places (New), Geocoding (setup guide §3).
- **Current location:** blue dot only when already allowed; screens that need GPS ask with explanations (denied, blocked, GPS off, failed handled).
- **Markers:** destination red, person azure, selected orange, centre green, stale faded.
- **Routing:** server-side Routes API (field mask, basic SKU, cache, quota), polyline, distance and ETA. Turn-by-turn is handed off to Google Maps (Google's terms forbid building guidance from Routes data).
- **Live location:** consent, stop, stale after 2 min, contract parties only (rules).
- **Tests:** widget tests with a fake map view (markers, camera, states). **Real rendering confirmed on the user's Android phone with the restricted key**: tracking, dark mode, picker.

## 5. Messaging and notifications
- **Messaging** (unchanged, S5): real-time Firestore streams; stable message ids (retry never duplicates); statuses sending / waiting for network / not sent / seen (from the other person's `lastReadAt`); no fake "delivered"; paging by raising the limit; unread counts; access limited to the two members by the rules.
- **Notifications** (G5): written with the action; the trusted function checks the link, rewrites the text, deletes forged items, pushes to all devices respecting settings, and cleans dead tokens. Tap targets: chat, contract, job, proposals. Notification centre: mark all read, delete, limit 100.
- **Emulator end-to-end:** forged text "FREE PRIZE" → rewritten to the sender's name and real message; unrelated recipient → deleted.

## 6. Profile pictures
Upload (camera/gallery, resized on the device to 1024 px), byte-level type check, under 2 MB, progress, cancel. Replace: upload → save → delete old. Delete: confirm → clear → delete file. Storage path `users/{uid}/profile/…` with owner-only rules. Firestore `photoUrl` → public profile (app) → copies on open records (trigger). Tests listed in §2. **Not verified against the real bucket** (Storage not enabled yet).

## 7. Application functionality
Authentication, roles, jobs, discovery, proposals, hiring/contracts, reviews, chat, admin: unchanged in Track G, so the S2–S8 verification stands (v1.1.0 released 15 Nov). New: saved jobs, notification settings, change password, account deletion, notification-centre actions, maps/route/search features as above.

## 8. Quality and reliability (G7, 22 Nov 2026)
| Check | Result |
|---|---|
| `dart analyze lib test` | 0 errors; 5 warnings, all in files Track G didn't touch (unused imports/elements) |
| `flutter test` | **469 passed, 0 failed** |
| Functions `npm test` | **27 passed** |
| Rules `npm test` (Firestore + Storage emulators) | **171 passed** |
| Functions emulator e2e | maps callables (auth/validation codes), notify (rewrite/delete), profile copies: all as expected |
| Android debug APK (no key) | built (G1, G2) |
| Android **release** APK with key | **built** (72.3 MB; key present in the manifest; debug-signed) |
| Web release (no key) | built (G2, again in G7); no Maps key in the bundle |
| On-device | Google Maps rendered on the user's phone (G2 harness build) |

**Defects found and fixed during Track G:**
- the Gradle script couldn't resolve `java.util.Base64`;
- callables checked the key before sign-in;
- a Firestore failure in the quota step surfaced as a server error;
- a snack bar covered "Start work";
- an unused push provider would have doubled every push;
- a single FCM token per account (a second phone overwrote the first);
- the push token was written to logs;
- notification recipients could rewrite their notifications;
- an unbounded notifications query;
- **Node 20 runtime** (decommissioned) would have made every functions deploy fail;
- legacy triggers would have double-counted unread messages, proposals and ratings if deployed.

## 9. Remaining work
| Priority | Item | Why open | Action | Who |
|---|---|---|---|---|
| **Critical** | Blaze + budget alert | billing is the owner's decision | console (guide §2) | account owner |
| **Critical** | Deploy functions → rules → app | needs the owner's go-ahead and Blaze | guide §7 | account owner (or ask me) |
| **Critical** | Server key + Routes/Places/Geocoding APIs | account-level | guide §3 | account owner |
| High | Enable Storage | Blaze | console | account owner |
| High | Real push check on phones (foreground/background/closed) | needs the deployed functions | guide §8 | developer |
| High | Delete the old stray Maps key; restrict Firebase client keys | console | Credentials | account owner |
| High | Commit the work | not authorized overnight | review `git status`, commit | developer |
| Medium | Play Store: own upload key, privacy policy URL, data-safety form, account-deletion URL | release decision | see S8 report | owner + developer |
| Medium | iOS build/test, APNs key | needs a Mac and Apple account | — | developer |
| Medium | Untrack `functions/node_modules` | repo hygiene | `git rm -r --cached functions/node_modules` and add to `.gitignore` | developer |
| Low | App Check enforcement | after attested traffic is confirmed | console | owner |
| Low | Marker heading arrow; job location before applying (D6 option b) | product choices | — | developer |
