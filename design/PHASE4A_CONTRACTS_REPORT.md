# SkillBridge — Phase 4A report: contracts, hiring confirmation and the work lifecycle

Branch `ui-improvements-2026`. Nothing is committed, pushed, merged or deployed, and the profile backfill was not run. All live testing used the **local Firebase Emulator Suite** (Auth, Firestore, Storage, Functions). The test browser blocked the production Firebase hosts, including `*.cloudfunctions.net`. **Nothing was verified against production.**

## Status at a glance

| | |
|---|---|
| **Completed** | Trusted hiring: a callable function accepts a proposal and creates exactly one contract (idempotent). Trusted direct-request acceptance. Every lifecycle step runs through a callable function: start, submit with up to 3 photos, client confirmation, cancellation with reason, accepting or declining booking requests, sharing the exact address privately. Rules stop users writing contract status, lifecycle fields, prices, ownership, hiring and job status. Contracts dashboard for clients and workers; contract details with history from stored timestamps; submit-work and completion-review views; chat entry point; client tracking entry point. Server-side notifications for every event. Trusted "jobs completed" statistic. en + ur strings. Rules, Storage, function and widget tests. Full regression and both builds. Emulator end-to-end runs in light and dark. |
| **Partially completed** | Booking requests from Nearby Workers (the older booking sheet) are still *created* by the client as a rules-checked write (pending only, no lifecycle data); every later step uses the functions. Push delivery (FCM) was not exercised, because only Firestore notification documents exist in the emulator. |
| **Not done (outside the approved scope; documented as future)** | Disputes. Progress updates. "Return for revision". Payments. Redesign of the legacy assigned-job tracking view and the EasyPaisa button (see §18). Deployment. |

---

## 1. Initial architecture findings

- **Contracts existed** (`contracts/{id}`) with:
  - agreed rate and rate type;
  - totals, a 10% commission and worker earnings;
  - payment fields;
  - service address and phone (bookings only);
  - status values `pending` / `active` / `completed` / `disputed` / `cancelled` / `rejected`;
  - `startDate` / `endDate` / `completedAt` and review flags.
- **Three hiring paths existed**, all client-side:
  1. **Proposal acceptance** (the Phase 3B client batch; contract ID = proposal ID).
  2. **Direct requests**: the "Request booking" button on a worker's profile opens the job form for an open job with `selectedWorkerId`. The worker accepted it by updating the job, and no contract was created.
  3. **Booking sheet** (Nearby Workers): job `assigned` plus a `pending` contract, which the worker accepted or declined.
- **The lifecycle was unsafe:**
  - the rules let either party write any contract status (an existing test even asserted that a worker could mark their own contract `completed`);
  - the assigned worker could mark the job `completed`;
  - the owner could complete or cancel assigned work with no contract change;
  - the job page had legacy "Start Work" / "Mark as Complete" buttons;
  - the contract card had a client "Mark as Completed".
- **Nothing recorded the work itself:** there were no start or submission timestamps, no submission and no history.
- **Clients had no Contracts screen;** workers had a legacy one.
- **Notifications** are `notifications/{id}` documents. The existing `onNotificationCreated` function sends FCM. Any signed-in user can create one (pre-existing).
- **Live location** (Phase 3B remediation) goes through `liveLocations/{workerId}`, readable only by clients of the worker's active jobs. It is foreground-only and started explicitly by the worker.
- **Disputes, progress updates and revisions are not implemented** anywhere: only the enum value `disputed` and a collection-name constant exist. They are out of scope and documented as future work.
- **The app had no package for callable functions** (`cloud_functions`).

## 2. Implementation plan (as approved)

The lifecycle keeps the existing contract status values; the stage within `active` comes from stored timestamps.

**Decision (asked and approved).** Add `cloud_functions` 6.5.1. Every compatible release also moves `firebase_core` from 4.12.1 to 4.15.2 (plus its platform and web packages). In exchange, hiring and every lifecycle step are decided on the server, in a transaction, and users can no longer write contract state.

## 3. Files created and modified

**Created**
- `functions/src/contracts.ts`: `acceptProposalCall`, `directRequestCall`, `contractActionCall`, and the pure logic they call.
- `functions/test/contracts.test.js`: 14 tests.
- `lib/features/contracts/presentation/screens/contract_details_screen.dart`
- `lib/features/contracts/presentation/screens/submit_work_screen.dart`
- `lib/features/contracts/presentation/widgets/contract_ui.dart`: stage badge, price label, party card, history.
- `lib/features/contracts/presentation/widgets/open_contract_card.dart`
- `lib/features/contracts/presentation/widgets/direct_request_actions.dart`
- `test/helpers/fake_contracts.dart`
- `test/widget/contracts_screens_test.dart`: 21 tests.
- `design/phase4a/screens/*.png` (39 files) and `design/phase4a/phase4a-contact-{light,dark}.png`
- This report.

**Rewritten**
- `lib/features/contracts/data/datasources/contract_remote_datasource.dart`:
  - streams for a contract and for a job's contract;
  - `ContractActions` (callables and evidence upload);
  - the direct status writes were removed.
- `lib/features/contracts/presentation/providers/contract_providers.dart`
- `lib/features/contracts/presentation/screens/my_contracts_screen.dart`: the dashboard for both roles.

**Modified**
- `lib/features/contracts/domain/entities/contract_entity.dart`, `.../data/models/contract_model.dart`: new optional lifecycle fields and `stage`. Existing fields are unchanged.
- `lib/features/proposals/data/datasources/proposal_remote_datasource.dart`: acceptance now calls the function. `.../providers/proposal_providers.dart` and `.../screens/proposal_details_screen.dart` gain "Open contract".
- `lib/features/jobs/presentation/widgets/job_lifecycle_actions.dart`:
  - the legacy Start/Complete buttons became the "Open contract" card;
  - direct-request Accept/Decline now use the function.
- `lib/features/jobs/presentation/screens/my_jobs_screen.dart`: Contracts entry for clients.
- `lib/core/providers/firebase_providers.dart`: functions provider.
- `lib/config/router/app_router.dart`, `route_names.dart`:
  - `/contracts/:id`;
  - `/contracts/:id/submit`;
  - `/client/contracts`.
- `lib/l10n/app_en.arb`, `app_ur.arb`: +130 keys each, plus the generated files.
- `functions/src/index.ts`: exports the contract functions.
- `firestore.rules`, `storage.rules`, `firestore.indexes.json` (+2 contract indexes).
- `rules-tests/rules.test.js`
- `test/helpers/fake_proposal_datasource.dart`
- `pubspec.yaml` (+1 line: `cloud_functions: ^6.5.1`) and `pubspec.lock`:
  - `cloud_functions` and the `firebase_core` move;
  - the other FlutterFire plugins moved to their matching releases within the existing `^` constraints (auth 6.7.1, Firestore 6.10.2, Storage 13.6.1, messaging 16.7.1, analytics 12.6.1, Crashlytics 5.4.1, App Check 0.4.9), because Android would not build with mixed versions (§14).

All earlier uncommitted work is preserved, from a snapshot of 479 files taken before Phase 4A. Line endings match the originals.

## 4. Existing functionality reused

- **Contract model and fields:** none renamed; new fields are optional.
- **Contract ID scheme** (`contracts/{proposalId}`) and the 10% commission logic.
- **Job chat** with fixed ID `{jobId}_{workerId}`, via `openJobChat`, and the chat rules.
- **Live tracking:** `WorkerLiveTrackingMap`, `liveLocations`, the worker's existing location-sharing card.
- **Notifications:** `notifications` documents and the existing FCM function.
- **Reviews:** review screen, rules and rating aggregation. The contract flag write is still allowed, narrowly (see §8).
- **Public profiles** (Phase 3B remediation) for the other party's card.
- **Design system:** `SbTheme`, `SbButton`, `SbStatusBadge`, `SbStateView`, `SbInlineBanner`, `showSbConfirmSheet`, `SbTextField`, job skeletons.
- **Direct-request and booking flows:** kept; their acceptance moved to the server.

## 5. Contract schema and relationships

`contracts/{id}`. The ID is the proposal ID for hired proposals, `{jobId}_{workerId}` for direct requests, and auto-generated for booking-sheet requests.

| Field | Set by | Notes |
|---|---|---|
| `jobId`, `proposalId`, `clientId`, `workerId` | function (or the booking-sheet create) | `proposalId` = proposal ID, `direct_request` or `direct_hire`; can't change |
| `jobTitle`, `jobDescription` | function | the agreed work, copied at hiring |
| `clientName`/`Photo`, `workerName`/`Photo` | function | display only |
| `agreedRate`, `priceMin`, `rateType`, `estimatedDuration` | function | `priceMin` only when a direct request had a budget range |
| `totalAmount`, `commissionRate`, `commissionAmount`, `workerEarnings` | function | users can never change them |
| `paymentStatus` (`unpaid`), `paymentProviderState` (`not_configured`) | function | no payment is taken |
| `serviceCity`, `serviceArea` | function | general area from the job |
| `serviceAddress`, `addressSharedAt` | client, via function | exact address, on the private contract only |
| `status` | function | existing values only |
| `acceptedAt`, `respondedAt`, `startDate`, `workStartedAt`, `submittedAt`, `completedAt`, `endDate`, `cancelledAt` | function | server timestamps only |
| `submission {note, attachments[], submittedAt}` | worker, via function | note 10–1000 characters; up to 3 photos in `contracts/{id}/evidence/` |
| `cancelledBy`, `cancelledByRole`, `cancelReason`, `cancelNote` | function | reason from a fixed list |
| `clientReviewed`, `workerReviewed` | each party, after completion | rules-checked; see §8 |

**Relationships:**
- job → contract (`jobId`);
- proposal → contract (same ID, `proposalId`);
- contract → chat (`chats/{jobId}_{workerId}`, `relatedJobId`);
- contract → evidence (Storage `contracts/{id}/evidence/*`);
- contract → reviews (`reviews/{contractId}_{uid}`);
- the proposal's `jobStatus` copy (Phase 3B) follows the job.

## 6. Contract lifecycle and transition matrix

Stage within `active`: **not started** (`workStartedAt` empty) → **in progress** (`workStartedAt` set) → **awaiting review** (`submittedAt` set).

| From | Action (callable) | Who | Contract → | Job → |
|---|---|---|---|---|
| proposal `pending`, job public `open` | accept proposal (`acceptProposalCall`) | job owner (active client) | **created** `active` (once) | `assigned` (other pending proposals → `rejected / filled`) |
| job `open`, sent to one worker | accept direct request (`directRequestCall`) | that worker | **created** `active` | `assigned` |
| job `open`, sent to one worker | decline direct request | that worker | — | `cancelled` |
| `pending` (booking sheet) | respond: accept / decline | worker | `active` / `rejected` | `assigned` / `cancelled` |
| `active`, not started | start | hired worker | `+workStartedAt` | `in_progress` |
| `active`, in progress | submit (note + photos) | hired worker | `+submittedAt`, submission | (`in_progress`) |
| `active`, awaiting review | confirm completion | client | `completed` `+completedAt` | `completed`; worker `totalJobsCompleted` +1 |
| `pending`, not started or in progress | cancel (reason; confirmation) | either party | `cancelled` + who / why / when | `cancelled` |
| `pending` or `active` (not completed or cancelled) | share exact address | client | `+serviceAddress` | — |
| `completed` / `cancelled` / `rejected` | — | — | final (review flags only) | final |

Additional rules:
- Submitted work can't be cancelled: the client confirms it. With no dispute process yet, staff resolve disagreements through the admin dashboard (§17).
- A worker can never confirm their own work.
- Proposal history is kept: the accepted proposal stays `accepted`.

## 7. Cloud Function changes

**New in `functions/src/contracts.ts`** (callable, v2, `us-central1`). Each runs in one Firestore transaction that reads everything first.
- `acceptProposalCall({proposalId})` returns `{contractId, alreadyAccepted}`. It is idempotent: a repeat returns the same contract and writes nothing.
- `directRequestCall({jobId, accept})` returns `{contractId, status, alreadyAnswered}`.
- `contractActionCall({contractId, action, …})` with actions `respond`, `start`, `submit`, `confirm`, `cancel` and `shareAddress`.
- **Checks on every call:**
  - signed in, and the caller's account is active;
  - the caller is the right party;
  - the current stage allows the action;
  - the job is consistent (for example, start requires the job `assigned` to that worker);
  - inputs are valid (note length, reason list, evidence paths only inside `contracts/{id}/evidence/`).
- Errors use standard codes (`permission-denied`, `failed-precondition`, `invalid-argument`, `not-found`, `unauthenticated`), and the app turns them into clear messages.

**Existing functions keep working unchanged:**
- `syncJobRelations` copies job status to proposals and refreshes live-location viewers on every job change, including those made by the new functions.
- `syncJobProposalCount` and `syncUserMirrors` are unchanged.

Nothing is deployed.

## 8. Firestore and Storage rule changes

**Firestore:**
- **Contracts:**
  - Users can't create proposal contracts; only the function can.
  - A client may still create a booking-sheet request, but only `status: 'pending'`, `proposalId: 'direct_hire'`, unpaid, with no lifecycle fields, and for their own job assigned to that worker.
  - Contract updates are staff-only, except one narrow case: after completion, each party may set *their own* review flag from false to true, once, and nothing else.
  - Reads are unchanged: the two parties and staff.
- **Jobs:**
  - Owners can no longer hire (`open → assigned`) or move assigned work (start, complete, cancel).
  - Assigned workers can no longer start or complete.
  - A worker may only decline an older direct request (`open → cancelled`).
  - Closing, reopening and editing open jobs are unchanged.
- **Proposals:** the client-side "accept" path was removed; acceptance happens only in the function. Decline, withdraw, re-send and "viewed" are unchanged.

**Storage:** new `contracts/{contractId}/evidence/{file}`.
- **Upload:** only the contract's worker, only images under 5 MB with a safe file name, and only while the work is in progress (started, not submitted). This is checked against the contract with a cross-service Firestore read.
- **Read:** the two parties and staff.
- **Kept:** update and delete are staff-only.

**Unchanged:** Phase 2 and Phase 3 protections. All earlier tests still pass. The Phase 3A and 3B hiring tests were updated to show the client-side paths are now refused.

## 9. Chat integration

- Every contract has a Message button: "Message worker" for the client, "Message client" for the worker. It reuses the existing job chat with fixed ID `{jobId}_{workerId}`, created or updated by the hiring function with an opening line.
- Phase 3B chat rules are unchanged:
  - only the two participants read or write;
  - participants can't change;
  - outsiders can't create or join;
  - unsuccessful applicants have no access to the hired worker's chat (their own chat ID differs).
- **Verified live:** messages work in both directions. An unsuccessful worker and an unrelated client got 403 reading the chat and its messages.

## 10. Location privacy handling

- **Public job listings** show only the general area and city. The job form already tells clients not to enter a house number.
- **The exact address** is shared by the client after hiring, through the function, onto the private contract. Only the two parties can read it. It is never copied to the job and is shown only on open contracts. Booking-sheet contracts keep the address entered in that sheet, also on the private contract.
- **Live location:**
  - only the clients of the worker's currently `assigned` / `in_progress` jobs can read it (`liveLocations`);
  - the worker starts sharing explicitly from the job page; it runs in the foreground only, with no background tracking;
  - no history is kept: each update overwrites the last;
  - the record is removed when the job ends.
- **The client's "Track the worker" sheet** explains that the location is shown only while the worker chooses to share it.
- **No new location collection** was added.

## 11. Notification implementation

The functions write `notifications/{id}` (`userId`, `title`, `body`, `type`, `payload {contractId, jobId}`, `isRead`, server `createdAt`) for real events only. Types:
- `contract_created` (proposal or direct request accepted);
- `booking_accepted` / `booking_declined` / `request_declined`;
- `work_started`;
- `work_submitted`;
- `completion_confirmed`;
- `contract_cancelled`;
- `address_shared`.

In the emulator run each step produced exactly one notification. The existing `onNotificationCreated` function turns these into FCM pushes once deployed. That needs FCM configured (§19); it was not run in the emulator.

## 12. Exact test results

| Suite | Result |
|---|---|
| Flutter unit and widget tests (`flutter test`) | **265 / 265 passed** (Phase 3B final: 244; +21 contract tests) |
| Firestore and Storage emulator rules tests (`rules-tests`, `npm test`) | **113 / 113 passed** (+12 Phase 4A; Phase 3A/3B hiring tests updated) |
| Cloud Function tests (`functions`, `npm test`) | **36 / 36 passed** (+14 contract tests) |

**The 13 required cases:**

| # | Case | Where verified |
|---|---|---|
| 1 | acceptance creates exactly one contract | function test 1; live (1 contract) |
| 2 | repeated acceptance creates no duplicate | function test 2 (no writes on repeat); live (`alreadyAccepted: true`); rules: client can't create or overwrite |
| 3 | only participants read contract details | rules "3."; live 403 for an unrelated worker |
| 4 | unrelated users can't access contracts | rules "4." (get, query, list, signed out) |
| 5 | only the hired worker starts | function test 5; rules "5–6."; live (client and others refused) |
| 6 | only the hired worker submits | function test 6; rules; Storage evidence tests; widget test |
| 7 | only the client confirms completion | function tests 7–8; widget test; live |
| 8 | workers can't self-confirm | function test; rules "7–8."; live (`permission-denied`) |
| 9 | prices can't be modified | rules "9–10." (both parties, every money field) |
| 10 | ownership can't change | rules "9–10." (`clientId`, `workerId`) |
| 11 | job and contract statuses stay consistent | function tests (job follows every step); rules "11."; live checks after each step |
| 12 | unauthorised users can't access contract chat | rules "12." (read, messages, post, join); live 403 |
| 13 | Phase 2 and 3 workflows still work | all earlier Flutter, rules and function suites pass; live proposal flow, review and chat |

## 13. Analyzer results

`flutter analyze`: **46 issues, 0 errors**, the same count as the end of Phase 3B (46). Two new warnings from Phase 4A (an unused import and an unused test variable) were fixed. Everything left is a pre-existing info or warning in older modules.

## 14. Build results

- **Web release** (`flutter build web --release`, production config): **passed**, after the plugin alignment.
- **Android debug APK** (`flutter build apk --debug`): **passed** after the alignment.
  - The first attempt **failed**. `firebase_app_check` 0.4.5+2 and `firebase_auth` 6.5.6 did not compile against the newer `firebase_core` that `cloud_functions` brings in.
  - Moving the FlutterFire plugins to their matching releases (lock file only, within existing constraints) fixed it.
  - The full Flutter suite (265/265), the analyzer and the web build were re-run after that change.
- **Emulator-connected web build** (scratchpad only): passed. It was rebuilt after the alignment for a live smoke test: accept created the contract, start moved the job to `in_progress`.

## 15. Emulator verification

**Environment:**
- Auth 9099, Firestore 8181, Storage 9198, Functions 5001.
- Functions ran from a scratch copy that loads only the Phase 3B and 4A functions, with no push notifications.
- Headless Chrome blocked identitytoolkit, securetoken, firestore, firebasestorage, `www.googleapis.com`, `*.cloudfunctions.net` and `*.run.app`, confirmed with "blocked" at load.
- Emulator-only accounts: two clients and two workers. All jobs, proposals and contracts were created through the app.

**Flow 1, proposal → contract → completion (light):**
- client posts a job, worker proposes, client accepts;
- contract created; job `assigned`; proposal `accepted` with `jobStatus: assigned`; worker notified;
- the dashboards for both roles show it;
- client shares the exact address: it lands on the contract only, and the job keeps "Gulberg III";
- worker starts: job `in_progress`;
- worker submits a note and photo: stored in `contracts/{id}/evidence/`;
- client reviews and confirms: contract and job `completed`; `jobStatus` copied; worker `totalJobsCompleted` 0 → 1, mirrored to the public profile;
- the review is written and the contract gets `clientReviewed: true`;
- chat messages in both directions.

**Flow 2, direct request → contract → cancellation (light):**
- client sends worker B a direct request (Rs 1,500–2,500);
- worker B accepts: contract `direct_request` with `priceMin` 1500; job `assigned`;
- worker cancels with reason "Schedule conflict" and a note: recorded as worker, reason and note; job `cancelled`.

**Flow 3, direct request → completion (dark):** accept, start, submit with photo, client confirms; both end `completed`.

**Smoke test after the plugin alignment:** post → propose → accept (contract created, job `assigned`) → start (job `in_progress`). Screenshots 50–51.

**Refused requests** (real tokens, sent directly to the emulator):
- `acceptProposalCall` by another client, by the worker, and signed out;
- a direct proposal `accepted` write (403);
- start by the client, by another worker and by another client;
- a direct contract status write by the worker (403);
- an unrelated worker reading the contract (403);
- a second start, a second submit, and a second confirm;
- the worker self-confirming; another client confirming;
- the client cancelling after submission; cancelling a completed contract;
- the client or another worker answering a direct request; the worker assigning the job directly (403);
- evidence photo read by an unrelated worker, an unrelated client or signed out (403);
- an upload after submission (403);
- chat and messages read by outsiders (403).

**Allowed:** both parties reading the evidence photo (200).

**Logs:** the function logs show no errors. The very short `contractActionCall` runs are browser CORS preflights, not actions.

**Not verified:** production Firebase, FCM delivery, the Android build on a device, and live map tiles (the emulator build has no Maps key).

## 16. Screenshots

`design/phase4a/screens/` (27 light, 14 dark) with contact sheets `design/phase4a/phase4a-contact-light.png` and `phase4a-contact-dark.png`.

- **Light:**
  - accept confirm and accepted: 00–01
  - My Jobs Contracts entry: 02
  - client dashboard: 03
  - client details: 04
  - share address: 05
  - worker dashboard: 06
  - worker details: 07
  - Start Work confirmation: 08
  - active work: 09–10
  - submit work: 11
  - submit confirm: 12
  - submitted: 13
  - client completion review: 14
  - confirm sheet: 15
  - completed: 16–17
  - contract chat: 18–19
  - direct request: 20–21
  - cancel sheet: 22–23
  - cancelled: 24
  - smoke test after the plugin alignment: 50–51
- **Dark:**
  - worker dashboard: 30
  - cancelled: 31
  - client dashboard: 32
  - direct request: 33
  - not started: 34
  - Start Work confirmation: 35
  - active work: 36
  - submit work: 37
  - submitted: 38
  - client completion review: 39
  - confirm sheet: 40
  - completed: 41
  - job "Open contract" card: 42
  - completed tab: 43

Evidence photos are generated test images labelled "TEST WORK PHOTO".

## 17. Incomplete functionality (by design, documented as future scope)

- **Disputes:** not in the approved FYP scope; only an enum value exists. Today, submitted work can only be confirmed, and disagreements need staff action through the admin dashboard (Admin SDK). A future phase needs a dispute record, evidence and a staff decision that sets `disputed` → `completed` / `cancelled`.
- **Progress updates and "return for revision":** not part of the existing workflow, so not added. The client is told to message the worker before confirming.
- **Payments:** not processed. Contracts say so clearly. The legacy "Pay with EasyPaisa" button on completed jobs (from an earlier phase) remains; the rules refuse its write (§18).
- **Booking-sheet request creation:** still a client write (rules-checked, pending only). Moving it into a function would finish the "everything trusted" goal.
- **Push delivery:** see §19.

## 18. Known risks

1. **Deployment order.** The new rules refuse every client-side hiring and lifecycle write. If the rules go live before the functions (and before the new app), hiring, start, submit and complete stop working. Older app builds lose all of these once the rules are deployed. See §20.
2. **Firebase plugins moved forward:** `firebase_core` 4.12.1 → 4.15.2 with `cloud_functions`, and the other FlutterFire plugins to matching minor releases (needed for Android). The full regression, a live smoke test and both builds pass, but iOS was not built here.
3. **Cross-service Storage rules** (evidence checks read Firestore) need the one-time Storage–Firestore permission grant on deploy (§19). Without it, evidence uploads and reads fail closed (refused, not exposed).
4. **The legacy EasyPaisa button** on completed jobs contradicts "payment is not processed in the app", and its `isPaid` write is refused by existing rules. Recommend removing or hiding it until a payment phase.
5. **Notifications can still be created by any signed-in user** (pre-existing rule; the old client code depends on it). Phase 4A notifications come only from the functions; tightening the rule needs the remaining client writers moved first.
6. **App Check is not enforced** on the callables (`app: MISSING` in the logs). Calls still require a signed-in user and every check runs on the server. App Check can be added later.
7. **Older contracts** (made before 4A) have no lifecycle timestamps. They show fewer history events (nothing invented), and an old `active` contract counts as "not started".
8. **The direct-request price** is the client's stated budget (a range stays a range). The final price is agreed in chat; there is no renegotiation step.
9. **Cold starts:** the first call after a deploy can take a few seconds (emulator: about 1–2 s). The UI shows progress.

## 19. Manual Firebase Console requirements (only when you approve deployment)

- **Blaze plan**, needed for 2nd-gen functions, including callables.
- **Callable function invocation:** v2 callables deploy with public invoker access by default, and the functions check sign-in themselves. Confirm the organisation policy allows `allUsers` invoker on Cloud Run, or grant it per function.
- **Storage cross-service rules:** on the first `storage` rules deploy, accept the prompt to grant the Storage service agent permission to read Firestore.
- **Composite indexes:** deploy `firestore.indexes.json`; 7 indexes are new since Phase 3B: 5 from Phase 3B plus contracts (`clientId`, `jobId`) and (`workerId`, `jobId`).
- **FCM (push):** a web VAPID key, APNs key for iOS and Android configuration. Without them, notifications appear in the app's list but no push is sent.
- **Optional:** App Check (Play Integrity / DeviceCheck / reCAPTCHA) for the callables.

## 20. Deployment dependencies

The order extends the approved sequence; every step needs your approval:
1. `firebase deploy --only firestore:indexes` and wait until built.
2. Deploy the functions:
   - Phase 3B: `syncJobProposalCount`, `syncJobRelations`, `syncUserMirrors`;
   - Phase 4A: `acceptProposalCall`, `directRequestCall`, `contractActionCall`.
3. Run the one-time additive profile backfill (Phase 3B).
4. Deploy Firestore **and** Storage rules **together with** the app release (which includes `cloud_functions`).

Before release, smoke-test on staging or with a test account:
- accept a proposal (exactly one contract);
- start, submit with a photo, confirm;
- cancel a second contract;
- confirm a second acceptance and a self-confirm are refused;
- check that a notification document appears for each step.

---

Phase 4A stops here. Phase 4B has not been started and waits for your approval.
