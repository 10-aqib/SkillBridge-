# SkillBridge — Phase 4B report: communication, work coordination and location sharing

Status: **implemented and tested locally; nothing deployed, committed or pushed.** All changes are uncommitted on `ui-improvements-2026`. Awaiting your approval.

## 1. Summary

| Area | Result |
|---|---|
| A. Messaging | Conversations are opened only by a trusted function (`openChatCall`). Messages are written once under a client-chosen id (create-only rule), at server time. Previews, ordering time, unread counts and notifications are kept by a trigger (`onChatMessageCreated`). New list and room screens cover loading, empty, error, offline, unavailable and suspended states. The room has pages of older messages, Sending / Sent / Seen / Not sent states with retry that never duplicates, and private photo attachments. Notification taps open the conversation or contract. The fake voice-note feature is gone. |
| B. Work coordination | "Where things stand" steps, progress updates (worker → client, saved once per request id), and **return for revision** (approved): the client sends work back with a note, up to 3 rounds; every submission is kept in a history. All of it goes through `contractActionCall`. |
| C. Location sharing | From the active contract only. The worker must explicitly agree, and can start and stop sharing. The position is written to `contracts/{id}/live/location`, which only the two parties can read. It is shown as "Live" only if updated in the last 2 minutes, otherwise as "Not live / may be out of date". It is deleted on submit, completion, cancellation and sign-out, and the rules refuse new positions after submit. Denied permission, GPS off and offline are each explained. Without a configured Maps key the position is shown as text with an "Open in Google Maps" link. |
| D. Completion | The worker gets a clear "submitted" confirmation, the submission history, notes and photos, and a "client confirmed on {date}" message. The client gets the review state, can inspect evidence, confirms in a sheet, and sees a success state. The misleading payment UI ("Pay with EasyPaisa", "Payment processed successfully!", "Completed & Paid") is removed. Reviews are unchanged and stay one per party. |

## 2. What changed

### Cloud Functions (`functions/src`)
- **New `chats.ts`**
  - `openChat` / `openChatCall`:
    - checks that both accounts exist and are active;
    - job chats `{jobId}_{workerId}` need a real link: a worker asking about a public open job, a proposal, or being the selected or hired worker;
    - direct chats `direct_{clientId}_{workerId}` are client → worker only (approved decision);
    - opening is idempotent, and an older conversation (random id) with the same two people is reused.
  - `applyNewMessage` / `onChatMessageCreated`:
    - **recounts** the recipient's unread count from their `lastReadAt` (not an increment, so duplicate trigger runs are harmless);
    - moves the preview only forward in time;
    - creates notification `msg_{messageId}` (fixed id, so one per message) unless the recipient is suspended.
- **`contracts.ts`**
  - Stage now comes from counters: submitted means `submissionCount > revisionCount`. Phase 4A contracts with `submittedAt` and no counters count as one submission.
  - `submit` allows resubmission after a revision and writes `submissions/{n}`.
  - New `requestRevision` (client, submitted work, at most 3 rounds, note of 10–1000 characters; the job stays `in_progress`) and `progressUpdate` (hired worker, before submission, `requestId` matching `^[A-Za-z0-9_-]{8,64}$`, a no-op if repeated).
  - `contracts/{id}/live/location` is deleted in the same transaction on submit, confirm, cancel and declined requests.
- `index.ts` exports `./chats`.

### Firestore rules (`firestore.rules`)
- **Chats**
  - create: staff / Admin SDK only;
  - update: a member may only mark **their own** read (`lastReadAt.{me} == request.time`, `unreadCount.{me} == 0`); previews, counts and participants can't be edited.
- **Messages**
  - create-only, as yourself, at `request.time`, `isRead == false`, field allowlist;
  - `text` (non-blank) or `image` with 1–3 attachments, each under `chats/{chatId}/{me}/{messageId}/…jpg|jpeg|png|webp`;
  - message id 8–64 safe characters;
  - refused if the sender or recipient is suspended or deleted.
- **`contracts/{id}/live/{doc}`**
  - read: the two parties and staff;
  - write: the hired worker only, while the contract is active and not waiting for review, at `request.time`, with a key allowlist;
  - `startedAt` is either kept or reset to `request.time`;
  - delete: the worker or staff.
- **`contracts/{id}/updates` and `/submissions`**: read by the parties, never written by users.
- **Notifications**: types `message`, `revision_requested` and `progress_update` can no longer be created by apps (server only).
- **Bug fix found while testing**: `isValidGeoPoint` read `point.latitude` as a field. In rules, latlng exposes `latitude()`/`longitude()` as methods, so **every** GeoPoint write to `users` or `jobs` `location` was refused. It now calls the methods, which accepts only valid points. New test added.

### Storage rules (`storage.rules`)
- `chats/{chatId}/{senderId}/{messageId}/{file}`:
  - read by the two members and staff;
  - create by a member into their **own** folder only: JPEG, PNG or WebP under 5 MB, safe names, never overwriting (`resource == null`);
  - kept once uploaded.
- Work evidence: uploads are allowed again after a revision (same "waiting for review" rule as the server); overwriting is now refused (`resource == null`).

### Indexes (`firestore.indexes.json`)
- `messages (senderId ASC, createdAt ASC)`, for the trigger's unread recount.

### App (`lib/`)
- **Chat**
  - `chat_remote_datasource.dart`: callable open, fixed-id send, duplicate-safe `deliverMessage`, own-only mark read, paged live window, `getData()` photos.
  - `chat_list_screen.dart`, `chat_room_screen.dart`, `chat_ui.dart`, models.
  - The `/chat/:chatId` route opens by id; it no longer needs an object passed in.
  - Unread badge on the client and worker Messages/Chats tabs.
  - The worker profile's "Message" button now really opens a direct chat (clients only). Before, it just went to the chat list.
- **Notifications**
  - Taps in the list, on pushes and on local notifications open the conversation or contract (`notification_routes.dart`, checked ids).
  - The raw exception text in the list error was replaced.
- **Contracts**
  - Entity and model counters.
  - `contract_activity.dart` (updates, submissions).
  - Details screen: steps, revision for both sides, updates, earlier submissions, submitted and confirmed notices.
  - Submit screen handles resubmission.
  - Evidence is read with `getData()`: no download URLs are created any more.
- **Location**
  - `location_tracking_service.dart` rewritten:
    - `LiveLocationController` with a pluggable source and sink;
    - consent first, at most one write every 15 s plus a 60 s heartbeat;
    - offline fixes are skipped, so an old position is never stamped as new;
    - stops itself when a write is refused;
    - stops on account change.
  - It **no longer writes `users/{uid}.location`**, which had been overwriting the worker's service area.
  - `live_location.dart` and `live_location_ui.dart`: worker and client panels.
  - Sign-out first stops sharing and removes the position (`SignOutUseCase.beforeSignOut`, with a 3 s limit).
- **Jobs**: `job_lifecycle_actions.dart` no longer has payment UI, the job-level tracking map, or the old location card (which used Islamabad fallback coordinates). Open and in-progress jobs show the contract card.
- **Maps**: `GoogleMapsService.isConfigured` (never exposes the key).
- **Strings**: 113 new en + ur ARB keys. One value updated: `contractSubmitBody` no longer says the work "can't be changed".

### Tests
- **New**
  - `functions/test/chats.test.js` (10);
  - Phase 4B blocks in `functions/test/contracts.test.js` (6), on a shared `fake_db.js`;
  - rules tests: the chat block rewritten, plus Phase 4B live location, updates and submissions, chat photos, GeoPoint;
  - `test/widget/chat_screens_test.dart` (22), `test/widget/contracts_4b_test.dart` (23), `test/unit/sign_out_live_location_test.dart` (2);
  - helpers `test/helpers/fake_chats.dart` and an extended `fake_contracts.dart`.
- **Changed on purpose**
  - Two Phase 4A expectations now check the new, clearer completed and submitted messages (`contracts_screens_test.dart` 7 and 8).
  - Phase 3B/4A rules tests that let clients create chats now assert that clients **can't**, because only the function creates them.

## 3. Test results

Kinds of test:
- **Mocked**: Flutter widget and unit tests with in-memory fakes; function unit tests on an in-memory Firestore fake.
- **Emulator**: rules tests on the Firestore and Storage emulators.
- **End-to-end**: the real web app, the emulators, the real functions and rules.

| Suite | Kind | Result |
|---|---|---|
| Flutter tests (`flutter test`) | mocked | **312 / 312 passed** (265 at the end of Phase 4A + 47 new) |
| Cloud Function tests (`npm test`) | mocked Firestore | **52 / 52 passed** (36 before + 16 new) |
| Firestore + Storage rules (`rules-tests`, `npm test`) | **real emulators** | **124 / 124 passed** (113 before + 11 new) |
| Emulator API checks as real users (`e2e4b_probe_*.py`) | **real emulators + functions** | **36 / 36 passed** (19 messaging, 12 coordination/location, 5 after completion) |
| Emulator UI run (web app, two browsers) | **end-to-end** | all flows below completed |
| `flutter analyze` | static | **0 errors**; 46 issues, the same 46 info/warnings as at the end of Phase 4A (none new) |
| Web release build | build | **passed** (`flutter build web --release`, no Maps key) |
| Android debug APK | build | **passed** (`flutter build apk --debug`) |
| Functions type check (`tsc --skipLibCheck`) | static | passes; plain `tsc` fails only inside `node_modules` type definitions (from before Phase 4B) |
| ESLint (functions) | static | **not run**: no ESLint config and no local install in `functions/` (from before Phase 4B) |

### End-to-end flows run on the emulators
The browser had production Firebase hosts blocked, and every one was checked as unreachable before each sign-in. The data was created as real users through the rules and the real `acceptProposalCall`.

1. **Client messaging**
   - The list shows the job chat; the empty room invites a first message.
   - A text message was sent; the server time was set and the trigger updated the preview and unread count (2) and created one notification per message.
   - A photo went into `chats/{chat}/{client}/{msgId}/p1.png`; the preview reads "Photo: …".
2. **Worker messaging**
   - The Chats badge showed 1; notifications were listed; tapping one opened the chat.
   - The chat was marked read (unread 0, `lastReadAt` at server time) and the client's message then showed "Seen".
   - The worker replied.
   - **Offline**: a message sent offline showed "Waiting for connection", then "Sent" after reconnecting, and **exactly one copy** exists on the server.
3. **Coordination**
   - A progress update was posted and appears on both sides and in the history.
   - Start work moved the steps on.
4. **Live location**
   - The consent sheet appeared first, then "Sharing".
   - The position went only to `contracts/{id}/live/location`, and `users.location` was not touched.
   - The client saw "Live · Updated 1 min ago". After 2 minutes without updates it showed "Not live" and the warning; it was never labelled live.
   - In two browsers at once, moving the worker's position 1 km updated the client's view live.
   - Sign-out removed the position, and the client immediately saw "isn't sharing".
5. **Submit and revision**
   - Submitting deleted the live position, and a later write was refused.
   - The client inspected the evidence (full-screen viewer) and sent the work back with a note: `revisionCount` 1, job still `in_progress`.
   - The worker saw the note and "Submit changes" and resubmitted with a new photo: `submissionCount` 2, both rounds kept.
6. **Completion and review**
   - The client confirmed in a sheet: contract and job `completed`, worker completed count 1, `paymentStatus` still `unpaid`, and no payment claim on screen.
   - The worker saw "Ayesha Khan confirmed…".
   - A review was saved once under `{contract}_{client}`; a second one, and one under another id, were refused.
7. **Security, as real users**
   - Refused:
     - another client reading the chat;
     - a client creating a chat document;
     - posting with a fake sender, a client-chosen time, or a reused message id;
     - editing the preview, or someone else's unread count;
     - a forged "message" notification;
     - a worker starting a direct chat, or an unrelated worker opening the job chat;
     - live location after submit, or written by the client;
     - progress updates after submit;
     - the worker sending back or confirming their own work;
     - an unrelated client asking for changes;
     - outsiders reading updates or submissions;
     - direct writes to history or counters;
     - any revision, submission or location after completion.
   - Allowed: everything the two parties should be able to do.

Screenshots are in `design/phase4b/screens/`: 36 light and 13 dark. Contact sheets: `design/phase4b/phase4b-contact-light.png` and `phase4b-contact-dark.png`. Screens 12–17 were captured before the three UI fixes in §4. All the others are from the final build.

## 4. Problems found during the emulator run (all fixed and re-tested)

1. **Restarting location sharing was refused.** If an old position document existed (for example after the app was closed), the first write is an update, and the rule required `startedAt` to stay the same. The app then wrongly said "Sharing stopped because the work was submitted". Fix: the rule also accepts a new `startedAt` equal to `request.time`. Rules test added.
2. **A worker's last position stayed visible after they signed out** (until the contract closed). Fix: sign-out first stops sharing and deletes the position. Verified end to end; unit test added.
3. **"Post an update" appeared twice**, inline and in the bottom bar. The inline copy was removed.
4. **The progress spinner showed on "Start work"** while an update was posting. Updates now have their own busy state.

Other incidents:
- **Storage emulator crash**: its temporary blob folder (`%TEMP%\firebase\storage\blobs`) was missing. This was an emulator environment problem. I recreated the folder, restarted, and redid the whole run on fresh data.
- **First trigger check timing**: the first run of the messaging check waited only 4 s and caught the trigger's cold start. The script now polls; all 19 checks pass.
- **Disclosure**: after the crash, one failed setup run printed the **emulator-only** test account password in a local tool traceback, because it was passed on the command line. It is not a production credential. The setup script no longer prints its command on failure. You may want to change that emulator test password.

## 5. Maps configuration

- No Maps key was added. The emulator and release web builds were made **without** `--dart-define-from-file=.env`. **Correction:** the Android Gradle build always copies `GOOGLE_MAPS_API_KEY` from `.env` into the manifest, so the regression `app-debug.apk` does contain that key (it stayed on this PC and wasn't run). Later Pixel 7 test builds were made with `.env` set aside so they carry no key.
- Mobile builds show a map only when a key is supplied at build time (`GoogleMapsService.isConfigured`).
- Web has no Maps JavaScript script, so it always shows the text-and-link view. The link needs no key.
- **Key rotation has not happened.** Two git-ignored local files still hold the same, possibly exposed, key: `.env` and `ios/Flutter/GoogleMaps.local.xcconfig`. Neither has ever been committed, and the value was not printed. After rotating, put the new restricted key in both, and restrict it per platform (Android package and SHA-1, iOS bundle id). Restrict web keys by referrer if a web map is added later.

## 6. Deployment sequence (not done — for when you approve)

1. Deploy the functions: `openChatCall`, `onChatMessageCreated`, the updated `contractActionCall`.
2. Deploy the indexes (messages `senderId + createdAt`); wait until it is built.
3. Release the app (new chat data source, mark-read and live location paths).
4. Only then deploy `firestore.rules` and `storage.rules`. Older app versions write chat previews and unread counts and create chats themselves, and the new rules refuse that. Until users update, **older app versions cannot send chat messages**, so plan a forced update or a short overlap.
5. No backfill is needed. Phase 4A contracts are read as one submission, and older random-id chats keep working and are reused.

## 7. Known limitations and follow-ups

- **Pagination** is a growing live window: "Show earlier messages" adds 30 at a time and re-queries. That is simple and real-time, but very long chats re-read more.
- **Unread counts** cost one count query per message, and the **push** fires on every message (no grouping or muting yet).
- **Live location only works while the app is open.** There is no background location service, so the client correctly sees "Not live" after 2 minutes. Live versus stale is judged with the client device's clock, so a badly wrong clock shifts the 2-minute threshold.
- **Attachments are photos only** (JPEG, PNG or WebP, at most 3, under 5 MB each). No documents or voice notes; the fake voice note was removed.
- The **notifications** rule still lets apps create other notification types for any user. That predates Phase 4B (reviews, jobs, proposals and bookings still create them client-side); only the server-only types are now blocked.
- **Cancelling** is still allowed while work is in progress again after a revision request, the same rule as Phase 4A.
- After a Phase 4A hire, the worker sees 1 unread with no message (from the hire preview). It clears when the chat is opened.
- No longer used by the app, but left in place (not deleted): the Phase 3B `liveLocations` mirror and the `worker_live_tracking_map.dart` widget and its test.
- Seen, not changed (outside Phase 4B):
  - `push_notification_service.dart` logs the FCM token;
  - the worker home cards show "+0.2 this month" / "+2 this month" figures that don't come from data;
  - the functions lint setup is missing.

## 8. Restrictions kept

- Nothing was deployed (rules, functions or indexes), no backfill was run, nothing was released, committed or pushed, and Firebase Auth configuration is unchanged.
- No payments and no dispute system were added.
- No dummy conversations, fake locations or simulated successes in the app. Test data exists only in the local emulators.
- Phase 2B, 3 and 4A protections are kept. Where rules changed, they became stricter, except two: the GeoPoint fix, which accepts only valid points, and the new restart rule, which allows a server-time start only.
- Global locale and RTL are unchanged; every new string exists in en and ur.
- Line endings match the pre-Phase-4B snapshot (0 mismatches); no secrets in changed files (51 files scanned).

**Please review and approve Phase 4B, or tell me what to change.**
