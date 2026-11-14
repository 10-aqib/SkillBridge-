# SkillBridge — Phase 4B implementation plan

Branch `ui-improvements-2026`. All Phase 1–4A work is uncommitted on this branch (233 entries in `git status`) and must be preserved. Nothing will be deployed or committed.

## 1. Current implementation findings

### Messaging (`lib/features/chat`)

**Schema**
- `chats/{chatId}` holds `participantIds[2]`, `participantNames`, `participantPhotos`, `lastMessage`, `lastMessageSenderId`, `lastMessageAt`, `unreadCount{uid:n}`, and `relatedJobId` / `relatedJobTitle` (optional).
- Job chats use the fixed ID `{jobId}_{workerId}`; older and non-job chats use random IDs.
- `chats/{chatId}/messages/{id}` holds `chatId`, `senderId`, `senderName`, `senderPhotoUrl`, `content`, `type` (`text` / `image` / `system`), `isRead`, `createdAt`.
- **There are no attachment fields.** `type: image` exists in the enum but nothing writes or renders images.

**Sending**
- A client-side batch writes the message, updates the chat's `lastMessage`, *increments the other person's unread count*, and *creates the other person's notification*.
- The message ID is a fresh UUID per tap, so a retry after an unclear failure can create a duplicate.
- On network errors the batch is queued in the app's offline outbox.

**Rules (Phase 3B)**
- Only members read; a sender can only post as themselves.
- Chat creation is limited to job-linked relationships, or client ↔ worker for non-job chats.
- **Weakness:** a member may set *any* value in `unreadCount` (including the other person's) and may write `lastMessage` freely. Previews and unread counts are therefore not trustworthy.
- **Weakness:** any client can open a non-job chat with any worker, and vice versa, entirely client-side.

**UI**
- `chat_room_screen.dart` has no date separators, no sending/sent/failed states, no retry, no pagination (it streams the entire history), and no handling of suspended or missing accounts.
- **A fake voice-note button**: the mic icon sends the text "[Voice Note — 0:24", draws a made-up waveform and shows "Voice note sent". It must be removed.
- The chat room needs the `ChatModel` passed in as `extra`, so opening `/chat/:id` directly (from a notification or a link) crashes.
- `chat_list_screen.dart` uses the legacy theme with a gradient header. Sorting is client-side on `lastMessageAt`, and the loading, empty and error states are basic.

**Notifications**
- Message notifications are created by the *sender's* app (spoofable, and the trusted rule can't check them).
- Tapping a notification only marks it read; it doesn't open the chat or contract.

### Work coordination (Phase 4A)

- The contract lifecycle runs through `contractActionCall`: respond, start, submit, confirm, cancel and share address. Each is a transaction with role, stage and duplicate checks.
- The stage comes from timestamps: not started → `workStartedAt` → `submittedAt` → `completed` / `cancelled`.
- History (`ContractTimeline`) is built from stored timestamps only.
- **There are no progress updates and no "return for revision".**
- The single `submission {note, attachments}` field is overwritten if a second submission were ever allowed, so there is no submission history.

### Location and maps

- The worker starts sharing from a switch on the **job page** (`_WorkerLocationSharingCard`), not from the contract.
- `LocationTrackingService` streams GPS in the foreground (10 m filter) and writes the **precise position into `users/{uid}.location`**. That is the same field as the worker's *service area*, so live GPS overwrites the service area, and the public profile's coarse location (Phase 3B mirror) moves with the worker. This is a privacy bug.
- `syncUserMirrors` copies it to `liveLocations/{workerId}`, readable by the clients of the worker's assigned or in-progress jobs. The client map (`WorkerLiveTrackingMap`) reads that.
- **No expiry on the device:** when a contract completes or is cancelled, the server removes the `liveLocations` mirror, but the worker's phone keeps streaming GPS into their account until they switch it off.
- **No staleness handling:** the map treats any stored coordinate as live, apart from a small "updated" label.
- **Maps key handling is already safe:**
  - Android reads `GOOGLE_MAPS_API_KEY` from `.env` into a manifest placeholder;
  - iOS uses a build setting;
  - Dart uses `--dart-define`.
- No Maps key is hardcoded in `lib/`, `android/`, `ios/` or `web/`. The only `AIza…` strings are the Firebase client config in `firebase_options.dart`, which are public identifiers rather than secrets.
- **Web has no Maps JavaScript loader**, so the web map shows grey tiles.
- The local `.env` has a Maps key set. It may be the previously exposed key, **which still needs rotating; that has not happened**. I won't print or reuse it, and won't add it anywhere new.

### Completion and payments

- Phase 4A already shows the submitted note and photos, confirmation, a completed banner and "Write a review".
- Evidence photos are shown via `getDownloadURL()`: a **bearer URL that works for anyone who has it**. That falls short of "do not expose private files through public URLs".
- The job page still has the legacy **"Pay with EasyPaisa"** button, a **"Payment processed successfully!"** message and **"Job Completed & Paid"** wording. The checkout screen itself is honest ("No payment was taken"), but the button and labels mislead.
- Reviews are rules-checked (completed contract only, one per party, deterministic ID).

## 2. Existing functionality to preserve

- Every Phase 4A contract action, timestamp, rule and test.
- Existing chats and messages: random-ID chats stay readable and writable by their members, and old message documents render as before.
- Phase 3B chat creation relationships:
  - a worker contacting the client of a public open job;
  - an applicant;
  - the hired worker.
- Phase 3B profile privacy (`publicProfiles`) and the hired-worker protections.
- The review flow and its rules.
- Proposal submission, acceptance, direct requests, booking requests.

## 3. Proposed changes

### A. Messaging

1. **Trusted conversation creation.** A new callable `openChatCall({otherUserId, jobId?})` replaces client-side chat creation. It verifies a real relationship on the server:
   - **job chats** (`{jobId}_{workerId}`):
     - the worker on a public open job;
     - an applicant;
     - the selected or hired worker;
     - a contract party;
   - **direct chats** (`direct_{clientId}_{workerId}`): only an active *client* starting a conversation with an active *worker* (the existing "Message" on a worker profile). Workers can't cold-message clients.
   - It returns the existing chat if one is already there, so it's idempotent.
   - The rules then make chat creation server-only.
2. **Duplicate-safe sending.**
   - The app generates one message ID per send and reuses it on retry. The rules allow *create only*, so a second write of the same ID can't create a copy; a retry checks whether the message already exists.
   - Message rules add:
     - `createdAt == request.time`;
     - an allowlist of fields;
     - an active sender;
     - an active, existing recipient;
     - validated attachments.
3. **Server-side side effects.** A trigger `onChatMessageCreated`:
   - sets `lastMessage` (a short preview, "Photo" for images), `lastMessageSenderId`, `lastMessageAt` (server time) and `lastMessageType`;
   - **recounts** the recipient's unread messages (idempotent, so retries can't inflate it);
   - creates the recipient's notification (`type: message`, `payload.chatId`).

   Members can then only update their own `lastReadAt.{me}` and `unreadCount.{me} = 0` (mark read). Previews and other people's counts become server-only.
4. **Attachments** (secure design; the current schema has none):
   - **Storage path:** `chats/{chatId}/{senderUid}/{messageId}/{file}`.
   - **Storage rules:**
     - write by that sender only if they're a chat member;
     - images only, under 5 MB, safe file name, at most 3 per message;
     - read by the two members;
     - no update or delete (staff only).
   - **Message field:** `attachments: [{path, contentType, size}]`, with every path checked by the Firestore rules to sit under the sender's own folder for that message.
   - **Displayed with `getData()`** through the Storage rules, so **no public download URLs** are created. Phase 4A evidence photos will be switched to the same method.
5. **Chat room UI** (rebuilt on SbTheme):
   - sender and receiver bubbles, times, date separators;
   - sending / sent / failed states with **Retry**, from Firestore's pending-write metadata;
   - live latest page plus "Load earlier messages" pagination;
   - loading skeleton, empty, offline and error states;
   - "account unavailable" banner, with the composer disabled for suspended, deleted or inaccessible accounts;
   - opens by `chatId` alone, so notifications and direct links work;
   - the job and contract shown in the header, linking to the contract;
   - photo attach and send (picker → upload → message);
   - **fake voice-note button removed**.
6. **Chat list UI:**
   - SbTheme, no gradient;
   - server-sorted previews with unread badges;
   - "You:" prefix on your own last message;
   - the job title;
   - loading skeleton, empty (honest copy) and error-with-retry states.
7. **Notifications:** tapping a message notification opens that chat; tapping a contract notification opens that contract.

### B. Work coordination

1. **"Where things stand" panel** at the top of the contract: a four-step tracker (Hired → Started → Submitted → Completed, or Cancelled), "What happens next" and whose turn it is. It's built from the existing stored fields, with no new timeline system.
2. **Progress updates.** `contractActionCall` gains action `progressUpdate {requestId, note, attachments?}`:
   - **hired worker only**, while the work is in progress;
   - stored at `contracts/{id}/updates/{requestId}`, so the same `requestId` twice is a no-op;
   - stamped with server time;
   - the client is notified;
   - readable by the two parties, written only by the server;
   - merged into the existing contract history.
3. **Return for revision.** It needs lifecycle and schema changes, so it's **an approval gate** (see §9). It is not implemented unless approved.

### C. Location sharing

1. **Contract-scoped, consented live sharing.**
   - The worker shares from the contract while it's not started or in progress, after a consent sheet that explains who sees it and when it stops.
   - Positions go to **`contracts/{id}/live/location`**, with no more writes into the account's service-area field. Fields: `location`, `accuracy`, `heading`, `sharing`, `updatedAt == request.time`, `startedAt`.
   - The rules allow writes only by the contract's worker, while the contract is active and not submitted. Reads are the two parties only.
2. **Expiry.**
   - When the contract is submitted, completed or cancelled, a trigger deletes the live document.
   - The rules refuse further writes.
   - The worker's app stops GPS when the contract leaves an active stage, when they tap Stop, or when they sign out.
3. **Client view:**
   - the map when a Maps key is configured for that platform; otherwise a clear card with last update time, accuracy and an "Open in Maps" link;
   - **stale data is never shown as live**: "Live" only under 2 minutes, then "Last seen X min ago — may be out of date", and "Not sharing" when stopped;
   - denied permission, GPS off and offline each have their own message on the worker side.
4. **Retire the old path.**
   - `LocationTrackingService` stops writing `users/{uid}.location`.
   - The client map reads the contract live document.
   - The `liveLocations` mirror and function stay for backward compatibility, but the app no longer uses them. They'll be documented as superseded.

### D. Completion experience

- **Worker:**
  - a submitted confirmation state;
  - a **submission history** (each submission's note, photos and time, plus progress updates);
  - a clear "Client confirmed completion" success state, with a review prompt.
- **Client:**
  - a "Your review is needed" state with inspectable notes and full-screen evidence (private `getData()`);
  - a confirmation sheet (existing);
  - a success state with a review prompt.
- **Both:**
  - after you've reviewed, "You reviewed this contract" (reviews are unchanged, so no duplicates);
  - links to chat and the other person's profile.
- **Remove misleading payment wording on the job page:** the "Pay with EasyPaisa" button, "Payment processed successfully!" and "Completed & Paid". Completed jobs link to their contract instead. No payment processing is added.

## 4. Firestore and Storage changes

| Change | Backward compatible | Backfill |
|---|---|---|
| `chats/{id}`: new server-maintained `lastMessageType`; members' `lastReadAt.{uid}` | yes (optional fields) | none |
| `chats/{id}/messages/{id}`: optional `attachments[]`, `clientSentAt` | yes; old messages render unchanged | none |
| Chat create → server only (`openChatCall`) | existing chats untouched | none |
| `contracts/{id}/updates/{requestId}` (new) | yes | none |
| `contracts/{id}/live/location` (new) | yes | none |
| `users/{uid}.location` no longer written by live tracking | yes (service area stays as set by the profile) | none |
| Storage `chats/{chatId}/{uid}/{messageId}/{file}` (new) | yes | none |
| Indexes: none needed (single-collection queries ordered by `createdAt`; counts use single-field indexes) | — | — |

## 5. Cloud Functions

| Function | Type | Purpose |
|---|---|---|
| `openChatCall` (new) | callable | validated, idempotent conversation creation |
| `onChatMessageCreated` (new) | Firestore trigger | preview, server timestamp, unread recount, recipient notification |
| `contractActionCall` (modified) | callable | + `progressUpdate` (and revision actions only if approved) |
| `syncJobRelations` / a new contract trigger (modified or new) | trigger | delete live location when a contract is submitted, completed or cancelled |
| Phase 4A and 3B functions | unchanged | — |

## 6. Security implications

- **Conversations:** only server-validated relationships can create them; no-one adds themselves, and participants are immutable.
- **Messages:** only members read and post; only as themselves; only while both accounts are active; server timestamps; create-only (no edits apart from the recipient's read flag); no impersonation; attachments only in the sender's own folder.
- **Previews and unread counts** can't be forged by members.
- **Private files:** attachments and evidence are shown via authenticated `getData()`, never public URLs. Storage CORS must be configured for web (§8 of the report).
- **Location:** consent, two-party access, writes only by the worker while active, server time, automatic expiry, no history kept, no public exposure.
- **Unchanged and still enforced:** Phase 2B (verification privacy), Phase 3 (proposals, public profiles, hired-worker identity) and Phase 4A (contract lifecycle) protections.
- **Deployment risk:** old app builds create chats and update previews client-side. After the new rules they can't start chats, and their message batches (message plus chat update) will be refused. Rules and app must ship together.

## 7. Test plan

- **Rules (emulator):**
  - members read and post; outsiders can't;
  - impersonation, forged timestamps, unknown fields and oversized text are refused;
  - a duplicate create of the same message ID is refused;
  - a member can't change another person's unread count or the preview;
  - chat creation is refused for all users;
  - messages to or from suspended accounts are refused;
  - attachment paths outside your own folder are refused;
  - live location: worker writes only while active; client reads; others denied; writes refused after completion or cancellation; server time required;
  - progress updates and the live document can't be written by users;
  - Storage chat attachments (member write and read, outsider denied, size and type);
  - every earlier suite still passes.
- **Functions (unit):**
  - `openChatCall` (each allowed relationship, refusals, idempotency, deterministic IDs);
  - `onChatMessageCreated` (preview, recount idempotency, notification, suspended recipient);
  - `progressUpdate` (worker only, stage, duplicate `requestId` no-op, history intact);
  - live-location expiry.
- **Flutter (mocked, no Firebase):**
  - chat room (bubbles, date separators, sending/failed/retry without duplicates, pagination, unavailable account, offline);
  - chat list (sorting, unread, preview);
  - contract status panel, progress updates, submission history;
  - location panel (live, stale, not sharing, permission denied, expired);
  - completion states;
  - payment wording removed.
- **Emulator end-to-end:**
  - two accounts exchange messages (unread and preview update, retry, photo attachment);
  - progress update;
  - worker shares location (browser geolocation override), client sees live, then stale, then stopped, then expired on completion;
  - completion and review;
  - light and dark screenshots.
- **Regression:** full Flutter suite, rules, functions, analyzer, web release build, Android debug build.

## 8. Screens to be redesigned or added

- **Redesigned:**
  - chat list;
  - chat room (composer, bubbles, separators, states, attachments).
- **Added:**
  - photo viewer (private);
  - location consent sheet;
  - live-location panel (worker and client);
  - contract "Where things stand" panel;
  - progress update sheet;
  - submission history section.
- **Adjusted:**
  - the completed job card (payment wording removed);
  - notification taps.

## Decisions (approved)

1. **Return for revision: approved.** It is implemented as described in §9.
2. **Conversations outside a job:** only an active **client → active worker** (the worker-profile "Message"), verified by `openChatCall`. Workers can't start non-job conversations. Job and contract chats work as before.

## 9. Return for revision (approved; originally an approval gate)

**Return for revision** (not in the Phase 4A lifecycle):
- **New action** `requestRevision {note}`, by the client, only while awaiting review. It records `revisionRequestedAt`, `revisionNote` and `revisionCount`.
- **Stage rule:** the stage goes back to *in progress*. Submitted would mean `submittedAt > revisionRequestedAt`.
- **Resubmitting:** the worker may submit again. Each submission is stored in `contracts/{id}/submissions/{n}`, so none is lost; the existing `submission` field keeps the latest one.
- **Limit:** at most 3 revision rounds. After that, only confirm or contact support remain.
- **Effect on the job and on cancelling:** the job stays `in_progress`. Cancelling is still refused while work is awaiting review.
- **Changed definitions:** "submitted" and the cancellation window. Everything else is unchanged.
