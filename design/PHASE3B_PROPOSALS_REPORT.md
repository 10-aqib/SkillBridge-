# SkillBridge — Phase 3B report: proposals, application management and client review

Branch `ui-improvements-2026`. Nothing is committed, pushed, merged or deployed. All live testing ran on the **local Firebase Emulator Suite** (Auth, Firestore, Storage, Functions). The Chrome browser used for testing blocked the production Firebase hosts. **Nothing has been verified against production.**

## Status at a glance

| | |
|---|---|
| **Completed** | Proposal submission (validation, duplicate and eligibility guards, progress, confirmation, re-send after withdrawal). Trusted proposal count (Cloud Function). Worker "My proposals". Client "Proposals" screen, compare sheet, proposal review, accept and decline. Atomic acceptance with rule cross-checks. Chat hardening. Budget-sort fix. en + ur strings. 16+ emulator rules tests. Function unit tests. Full regression. Emulator end-to-end runs for both roles, light and dark. |
| **Partially completed** | Acceptance is a client-side atomic batch guarded by the rules, not a callable Cloud Function (see §5). Dark-mode screenshots cover the main screens, not every state. |
| **Not done (out of scope or needs approval)** | Deployment of rules, indexes and functions. Running the profile backfill on production. Redesign of the legacy Contracts screens and the "assigned job" tracking view. A production check. |

The two privacy issues in the first version of this report (§16 items 1 and 2) are now fixed and enforced by the rules. See the next section.

---

## Final security remediation (added after review)

### R1. Public and private profile information

**Problem.** Any signed-in user could read every full `users/{uid}` document: phone number, email, push token, home and service addresses, exact location, worker earnings, verification status and document path.

**Fix: data separation, enforced by the rules.**

| Collection | Contents | Who can read | Who can write |
|---|---|---|---|
| `users/{uid}` (unchanged data) | Full account | **The owner and staff only** (was: any signed-in user) | The owner (existing rules), staff |
| `publicProfiles/{uid}` (new) | Allowlisted public view (see below) | Any signed-in user | **Nobody**: Cloud Function only |
| `liveLocations/{workerId}` (new) | The hired worker's live position | The worker, staff, and the clients of jobs currently assigned to that worker (`viewerIds`) | **Nobody**: Cloud Function only |

**Public fields.**
- Account: `displayName`, `photoUrl`, `role`, `isActive`, `city`, the email, phone and CNIC *verified* flags (booleans only), `createdAt` (member since), `rating`, `totalReviews`.
- Workers also get: headline, bio, category, skills, experience, rates, availability, verified badge, service radius, jobs completed, average rating, reviews, cover image, languages, response time, and work photos.
- Certifications keep only name, issuer and year; the certificate image is dropped.

**Never public.**
- Phone number, email, CNIC, push token, home address, service address.
- Exact location, live-sharing state, heading.
- Earnings, verification status and document path, onboarding flags.

**Location.**
- A worker's location is rounded to 2 decimals (about 1.1 km) and its geohash is recomputed from the rounded point, so "near you" discovery and distances still work. This matches the profile screen's existing promise: "Approximate area. Exact locations are shared only for booked jobs."
- Clients never have a public location.
- A worker with `locationVisibility` set to anything other than `public` shows no area.

**Trusted functions** (`functions/src/profiles.ts`):
- `syncUserMirrors` (`onDocumentWritten("users/{uid}")`) rebuilds the public profile.
  - It compares against the stored mirror, so a write that doesn't change the public view (a push token, a GPS update within the same ~1 km cell) costs one read and no write.
  - A mirror left stale by an earlier failed run is corrected on the next write. This came from a bug found in the emulator run (see R4).
  - Deleting a user removes both mirrors.
- Live location:
  - It is rebuilt when location fields change, and when a job is hired, reassigned or finished (`syncJobRelations`).
  - Viewers are the clients of the worker's `assigned` or `in_progress` jobs.
  - The exact position is included only while the worker is sharing.
  - With no active job the record is deleted, not left readable.

**App changes.** Every cross-user read now uses the public or live mirrors:
- `workerProfileProvider` (worker profile page, proposal cards, client card on job pages, My proposals) reads `publicProfiles`.
- Worker discovery and nearby workers (`worker_remote_datasource.dart`) query `publicProfiles`, with the same filters as before.
- The client's live-tracking map reads `liveLocations`. It retries for up to about 2 minutes if the record isn't written yet right after a hire.
- The signed-in user's own account, profile editing and location sharing still use `users/{uid}`, unchanged.
- The admin dashboard and Cloud Functions use the Admin SDK and are unaffected.

**Backfill.** `functions/scripts/backfill-mirrors.js` (calls `backfillMirrors()`) is additive. It reads `users/*` and writes only the two mirror collections; it never modifies or deletes `users`. It refuses to run against a real project without `--confirm-production`. It was tested on the emulator: it restored a deleted public profile and wrote 4 profiles with no private fields.

### R2. Hired-worker identity

**Problem.** `selectedWorkerName` and `selectedWorkerId` stay on the job. Phase 3B let any applicant read a job they had applied to, even after someone else was hired.

**Fix: enforced by the rules.**
- The job read rule no longer includes "applied to this job". Once a job is no longer public, only its owner, the hired (selected) worker and staff can read it, and with it `selectedWorkerName`.
- Public open jobs never carry a selected worker. The rules already require `selectedWorkerId == null` for them.
- Applicants follow the job through `proposals/{id}.jobStatus`, which `syncJobRelations` copies from the job whenever its status changes. Users can't set or change `jobStatus`: it is refused on create and on every update path.
- Contracts remain readable only by the two parties. The unsuccessful applicant was refused (403) both in the rules tests and live.
- The app shows the copied status ("Job filled · Assigned") on My proposals and the proposal page. "View job" is hidden when the job can't be read. The owner and the hired worker still see "Hired: <name>".

`closeProposalsWhenJobFilled` is replaced by `syncJobRelations`, which does three things on a job update:
1. closes proposals still pending once someone is hired (as before);
2. copies the job status to the job's proposals;
3. refreshes live-location viewers for the old and new selected worker.

### R3. Tests added

- **Rules** (+16, 101 total):
  - owner reads their own account;
  - other users, workers and signed-out users can't read someone else's account;
  - non-staff can't list or search accounts;
  - staff can read and query accounts;
  - any signed-in user reads public profiles and runs discovery queries; signed-out users can't;
  - nobody can write a public profile (create, update, verified-badge forgery, delete);
  - owners can still update their own account;
  - live location is readable by the worker, the client of their active job and staff, and not by other clients, other workers, signed-out users or for missing records;
  - nobody can add themselves as a viewer or write a position;
  - after a hire only the owner, the hired worker and staff can read the job;
  - the unsuccessful applicant and other users are refused, including a query by `selectedWorkerId`;
  - contracts are refused to the unsuccessful applicant;
  - `jobStatus` can't be forged on create or update;
  - withdraw and re-send still work on proposals carrying `jobStatus`;
  - public open jobs stay readable.
  
  Phase 3B test 11 was updated: the other applicant is now refused the job and reads their proposal instead.
- **Cloud Functions** (+12, 22 total):
  - no private field leaks;
  - location coarsening and geohash;
  - geohash matches the standard reference value (`u4pruydqqvj`);
  - clients have no location; hidden areas stay hidden;
  - rewrite only on public changes;
  - stale-mirror correction;
  - live viewers are only `assigned` and `in_progress` clients, and the record is removed when the job ends;
  - no position without sharing;
  - only location writes refresh the live record;
  - job status copied to proposals (only stale ones);
  - viewer refresh on hire or reassignment;
  - backfill is additive and never writes `users`.
- **Flutter** (+3, 244 total):
  - My proposals and the proposal page show the copied status without the job, with no "View job" and no hired name;
  - the copied status parses from the proposal document.

### R4. Emulator re-verification (local emulators only; production hosts blocked)

The proposal, acceptance, rejection, withdrawal, contract and chat workflows were repeated with the profile-mirror functions running. Two bugs turned up and were fixed:
1. `admin.firestore.GeoPoint is not a constructor` inside the Functions runtime, although it worked in unit tests. It appears only when a worker has a location. Fixed by using the modular `firebase-admin/firestore` import.
2. The "skip if unchanged" check compared old and new user documents. After bug 1 crashed a run, the mirror stayed without its location. It now compares against the stored mirror and self-corrects; a regression test was added.

**Verified:**
- All 4 seeded accounts got public profiles with no phone or email.
- A worker's exact location (31.520367, 74.358749) appears publicly as 31.52, 74.36, "approximate", with no address.
- Discovery (client home) and the worker profile page render from public profiles, identical to before.
- Proposals, acceptance and contract work as before.
- After the hire, both proposals carry `jobStatus: assigned` and a live-location record was created with only the client as viewer.
- A simulated GPS update put the exact position in the live record while the public profile stayed coarse. The client's tracking map showed "Live Tracking · live en route · Updated just now".
- Send → withdraw → re-send (count 1 → 0 → 1); decline (`rejected / client`).
- Job chat before the hire; messages in both directions; the client's chat list shows both chats.

**Direct requests with real emulator user tokens:**

| Request | Result |
|---|---|
| Unsuccessful applicant reads the filled job | **403** |
| Hired worker reads the job | 200 |
| Owner reads the job | 200 |
| Applicant reads own proposal (`jobStatus=assigned`, no hired name) | 200 |
| Worker reads a client's account | **403** |
| Client reads a worker's account | **403** |
| Worker reads own account | 200 |
| Another client reads the worker's public profile (no phone, email or address in it) | 200 |
| Client of the active job reads live location | 200 |
| Another client reads live location | **403** |
| Another worker reads live location | **403** |
| Client lists all users | **403** |
| Worker writes own public profile | **403** |
| Client adds self to live viewers | **403** |
| Applicant forges `jobStatus` | **403** |

**Screenshots** are in `design/phase3b/remediation/` (14 light, 3 dark, plus contact sheets). The screens look the same as before; the data now comes from the mirrors.

### R5. Remaining risks

1. **Deployment order matters.** If the rules go out before the functions and the backfill, discovery and profile pages will show nobody, because `publicProfiles` will be empty. Follow §18.
2. **Older app builds** read `users/{uid}` for other people and will lose profile pages, discovery and the live map once the new rules are live. They also can't start job chats (from Phase 3B). Ship the rules with the new app release.
3. **Mirror lag.** Public profiles and live viewers update about a second after a change (emulator: 50–1250 ms warm; 6 s cold start). Right after a hire the tracking map may retry briefly.
4. **Function cost.** Each user write costs one mirror read. Location writes also run one jobs query to find viewers. A worker who shares location continuously therefore triggers one function call per GPS write; the existing service already throttles GPS writes.
5. **Fields not yet covered by the split** (pre-existing, unchanged):
   - Job documents carry `clientName`, `clientPhotoUrl` and the job `address`, readable by any active user while the job is open. This is by design for job discovery.
   - Chats store participant names.
   - The old "Call Ustad" button passes an empty phone number (unchanged; the phone is not exposed).
6. **No public location for clients.** Public profiles never include a client's location; nothing currently uses it.
7. **The hired worker's identity is still visible to the two parties** (job, contract, chat), as required. Staff see everything through the Admin SDK.
8. **The backfill must be run once on production**, with approval, after the functions are deployed. It is additive and idempotent.

## 1. Implementation summary

- **Submitting.** Workers send a proposal from the job page through a new form: rate type (fixed, per hour, per day), price, estimated time (quick chips or free text), and a note to the client (30–2000 characters). A confirmation sheet shows exactly what the client will see. Progress and failures are shown, and a second send is blocked while one is in flight. The page refuses clients, suspended workers, the job's owner, closed, assigned or direct-request jobs, and a second proposal. Instead of the form it explains the reason.
- **One proposal per worker per job.** Each proposal's ID is `{jobId}_{workerId}`, so duplicates are impossible at the database level. A withdrawn proposal can be re-sent: the same document is updated, and its original sent date is kept.
- **Trusted count.** The job's `totalProposals` is maintained only by a Cloud Function. The function recounts from the source on every change, so retries and duplicate events can't inflate it. Users can't write the field.
- **Worker "My proposals".** Tabs for Pending (including "Viewed"), Accepted, Not selected and Withdrawn, with counts. Each card shows the job title, the client's public name, photo and city, the price, the sent date, the proposal status and the job status (the copy on the proposal when the job can no longer be read, see R2). Actions: Withdraw (with confirmation), View job, View proposal. The list opens on the first tab that has proposals. Loading, empty and error states are included.
- **Client "Proposals" (new screen).** It replaces the old "View Received Proposals" button and sheet. The owner panel on the job page now has "View proposals (n)", which stays available after a hire. The screen shows a job summary, tabs (Active, Accepted, Not selected; withdrawn proposals are hidden), sorting (newest, oldest, lowest price within a rate type), and a compare sheet grouped by rate type. Each card shows the worker's real profile (photo, name, verified badge, headline, experience, city), price, duration, the start of the note, the date and the status.
- **Proposal review.** One screen serves both roles. The client sees the worker's profile with skills, work photos and a link to the full profile. A rating appears only when real reviews exist; otherwise it says "New". The client can accept (the confirmation explains that the job is assigned, a contract is created, the other proposals close, and no payment is taken) or decline (with confirmation). Opening a pending proposal marks it "Viewed" once, with a server timestamp. The worker can withdraw, send again or message the client. A history section lists sent, viewed, accepted or closed, and withdrawn dates.
- **Acceptance** is one atomic write: proposal accepted, job assigned to that worker, other pending proposals closed as "filled", contract created (unpaid, payment provider "not configured"), worker notified, job chat created or updated. The rules check every part against the others.
- **Chat** creation, membership and messages are locked down (§7). Job chats use a fixed ID `{jobId}_{workerId}`.
- **Budget sort** compares one pay type at a time (§8).
- **Bugs found and fixed during the emulator run:**
  1. **Account switch:** after one account signed out and another signed in, an open job showed "no longer available". The previous user's refused read was kept. Job and proposal listeners now restart when the signed-in account changes. A regression test fails without this fix.
  2. **Send race:** the local echo of a just-sent proposal could replace the form with "already sent" before the server confirmed, which skipped the redirect. The form now stays on screen until the send finishes.
  3. **Privacy:** on a filled job, an unsuccessful applicant saw "Requested from <hired worker>", a Phase 3A label meant for direct requests. It is now shown only for direct requests. The hired worker's name is shown only to the client and the hired worker.
  4. **Layout:** "Message client" was truncated next to the main button, price and duration ran into each other, the sort label overflowed on a phone, and the duration wasn't aligned in received-proposal cards. All fixed.
  5. **Copy and UX:** the client now sees "Your budget", not "Client's budget". The compare sheet shows amounts under a rate-type heading. A worker who wasn't selected is no longer offered a chat about the filled job.

## 2. Files created and modified (Phase 3B only)

**Created**
- `functions/src/proposals.ts`: count and close-out triggers.
- `functions/test/proposals.test.js`: function unit tests.
- *Remediation:*
  - `functions/src/profiles.ts` (public profile and live-location mirrors, backfill);
  - `functions/scripts/backfill-mirrors.js`;
  - `functions/test/profiles.test.js`;
  - `design/phase3b/remediation/*.png`.
- `lib/features/proposals/presentation/screens/submit_proposal_screen.dart`
- `lib/features/proposals/presentation/screens/received_proposals_screen.dart`
- `lib/features/proposals/presentation/widgets/proposal_ui.dart`: status badge, price label, worker card.
- `lib/features/chat/presentation/open_job_chat.dart`: shared "open job chat" helper.
- `test/widget/proposals_screens_test.dart` (33 tests, including 3 from the remediation)
- `test/helpers/fake_proposal_datasource.dart`
- `test/unit/account_switch_listeners_test.dart`
- `design/phase3b/screens/*.png` (43 screenshots), `design/phase3b/phase3b-contact-{light,dark}.png`
- This report.

**Rewritten**
- `lib/features/proposals/domain/entities/proposal_entity.dart`
- `lib/features/proposals/data/models/proposal_model.dart`
- `lib/features/proposals/data/datasources/proposal_remote_datasource.dart`
- `lib/features/proposals/presentation/providers/proposal_providers.dart`
- `lib/features/proposals/presentation/screens/my_proposals_screen.dart`
- `lib/features/proposals/presentation/screens/proposal_details_screen.dart`

**Modified**
- `firestore.rules`
- `firestore.indexes.json` (3 indexes added)
- `functions/src/index.ts` (exports `./proposals`)
- `functions/package.json` (test glob for Node 24)
- `rules-tests/rules.test.js`
- `lib/config/router/app_router.dart`, `lib/config/router/route_names.dart` (propose route, proposals route, proposal by ID)
- `lib/l10n/app_en.arb`, `lib/l10n/app_ur.arb` (+106 keys each; removed the "proposals coming in the next update" string), generated `lib/generated/l10n/*`
- `lib/features/jobs/presentation/screens/job_details_screen.dart`: worker bar, owner "View proposals", hired-name privacy.
- `lib/features/jobs/presentation/screens/job_feed_screen.dart`, `lib/features/jobs/domain/job_search.dart`, `lib/features/jobs/presentation/job_feed_controller.dart`: budget sort.
- `lib/features/jobs/presentation/widgets/job_actions.dart`, `job_lifecycle_actions.dart`, `my_jobs_screen.dart`: count comes from the job; the old proposal sheets were removed.
- `lib/features/jobs/data/datasources/job_remote_datasource.dart`, `lib/features/jobs/presentation/providers/job_providers.dart`: client-side counting removed; the job listener restarts when the account changes.
- `lib/features/chat/data/datasources/chat_remote_datasource.dart`: fixed job-chat IDs, member-only lookup.
- *Remediation:*
  - `lib/core/constants/firestore_paths.dart`;
  - `lib/features/client/presentation/providers/worker_profile_provider.dart` and `lib/features/client/data/datasources/worker_remote_datasource.dart` (now read `publicProfiles`);
  - `lib/features/jobs/presentation/widgets/worker_live_tracking_map.dart` (now reads `liveLocations`, with retry);
  - the proposal entity and model (`jobStatus`), and `my_proposals_screen.dart` and `proposal_details_screen.dart` (copied status; no "View job" when the job can't be read);
  - `functions/src/proposals.ts` and `functions/src/index.ts`;
  - `firestore.rules`, `firestore.indexes.json` (+2 indexes), `rules-tests/rules.test.js`;
  - `test/helpers/fake_proposal_datasource.dart`, `test/widget/proposals_screens_test.dart`.
- `test/widget/jobs_screens_test.dart`, `test/helpers/job_fixtures.dart`, `test/helpers/fake_job_datasource.dart`

Storage rules are unchanged. All other uncommitted work from earlier phases is preserved, and line endings match the pre-3B snapshot (0 files drifted).

## 3. Proposal schema and relationships

`proposals/{jobId}_{workerId}`

| Field | Set by | Notes |
|---|---|---|
| `jobId`, `jobTitle` | worker at creation | must match the job; can't change afterwards |
| `workerId`, `workerName`, `workerPhotoUrl` | worker | `workerId` must be the sender; can't change |
| `clientId` | worker | must equal the job's `clientId`; can't change |
| `coverLetter` | worker | 30–2000 characters |
| `proposedRate`, `rateType` | worker | over 0 and up to 10,000,000; `fixed` / `hourly` / `daily` |
| `estimatedDuration` | worker | 2–60 characters |
| `status` | see §6 | `pending` / `accepted` / `rejected` / `withdrawn` (existing values, not renamed) |
| `createdAt` | server time | kept when re-sent |
| `updatedAt`, `resubmittedAt` | server time | |
| `viewedAt` | client, once | server time |
| `decidedAt`, `closedReason` | client or function | `client` (declined) or `filled` (another worker hired) |
| `withdrawnAt` | worker | cleared on re-send |
| `workerRating` | legacy | not written, not shown |

Relationships:
- Job → proposals: `jobId`.
- Proposal → contract: `contracts/{proposalId}`, with `proposalId` on the contract.
- Proposal → chat: `chats/{jobId}_{workerId}`, with `relatedJobId`.
- Notifications: `notifications` (`New Proposal Received` to the client, `Proposal accepted` to the worker).

## 4. Proposal-count architecture

- `syncJobProposalCount` (Firestore `onDocumentWritten("proposals/{id}")`) runs when a proposal's status or job changes. It recounts that job's proposals with a server-side `count()` aggregation over the statuses `pending`, `accepted` and `rejected` (withdrawn proposals are not counted). It writes `totalProposals` in a transaction, and only if the value differs.
- Because it **recounts** rather than increments, retried or duplicated events can't inflate the number, and any wrong value is corrected on the next change. A missing job is skipped.
- Users can't write `totalProposals`: the rules refuse it, and the emulator test tried a forged value of 99.
- The app no longer counts proposals on the client. My Jobs, the job page and the Proposals screen read `job.totalProposals`.
- Emulator run: the count went 0 → 1 → 2 as proposals arrived, dropped 1 → 0 on withdraw, and went back 0 → 1 on re-send. The first run took 5.6 s (cold start); later runs took 8–700 ms.

## 5. Acceptance and rejection logic

**Accept (client, job owner, pending proposal, public open job).** One Firestore batch:
1. proposal → `accepted`, with `decidedAt`;
2. job → `assigned`, with `selectedWorkerId` and `selectedWorkerName`;
3. every other pending proposal on the job → `rejected`, with `closedReason: filled`;
4. `contracts/{proposalId}` with the agreed rate, rate type, total, 10% commission, worker earnings, `paymentStatus: unpaid`, `paymentProviderState: not_configured`, `status: active`;
5. notification to the worker;
6. job chat created or updated with "Proposal accepted. You can now message each other."

The rules check these against each other with `getAfter()`:
- a proposal can become `accepted` only if, in the same write, the job moves from public open to assigned to that worker;
- the job can be assigned from a public open state only if that worker's proposal is accepted in the same write;
- the contract needs an accepted proposal from the same client.

So a second acceptance fails because the job is no longer open. This was verified in the rules tests and live (403).

**Late arrivals.** `syncJobRelations` (`onDocumentUpdated("jobs/{id}")`; called `closeProposalsWhenJobFilled` before the remediation) closes any proposal still pending when a job moves from open to assigned or in progress. This covers a proposal that landed between the client loading the list and accepting.

**Decline (client).** Pending → `rejected` with `closedReason: client`. This is final.

**Withdraw (worker).** Pending → `withdrawn`. It can be re-sent only while the job is still public and open.

**Why not a callable function.** The rules-guarded batch gives the same guarantees without a new deployed endpoint. Tightening it into a callable function is optional (§16).

## 6. Job / proposal status transition matrix

| Item | From → To | Who | Condition |
|---|---|---|---|
| Proposal | — → pending | worker | job public and open, not own job, ID `{jobId}_{uid}`, active worker |
| Proposal | pending → withdrawn | worker | — |
| Proposal | withdrawn → pending | worker | job still public and open (re-send) |
| Proposal | pending (viewed) | client | job owner; sets `viewedAt` once |
| Proposal | pending → rejected | client | job owner (`closedReason: client`) |
| Proposal | pending → rejected | function | job filled (`closedReason: filled`) |
| Proposal | pending → accepted | client | same write assigns the open job to this worker |
| Proposal | accepted, rejected | — | final; a rejected or withdrawn proposal can't be accepted |
| Job | open → assigned | owner | public job: only with that worker's accepted proposal |
| Job | other moves | — | unchanged from Phase 3A (direct requests, start, complete, close, reopen) |
| Contract | created | client | proposal accepted in the same write, or a direct hire of their own job |
| Contract | status, payment | — | existing rules; the parties can't change identity, money or payment fields |

Closed, completed, assigned and direct-request jobs can't receive proposals. No status values were renamed, and existing contract statuses are untouched.

## 7. Chat security changes

- **Create.** The creator must be one of exactly two participants, and only listed fields are allowed.
  - Job-linked chats must use ID `{relatedJobId}_{workerId}`, the client must be the job's owner, and the worker must be linked to the job: the job is public and open, the worker has a proposal, or the worker is the selected worker.
  - Non-job chats are allowed only between a client and a worker.
- **Read.** Members and staff only. The earlier "readable if it doesn't exist" allowance, which revealed whether a chat existed, was removed. The app finds chats with member-only queries.
- **Update.** Only `lastMessage`, `lastMessageSenderId` (must be yourself), `lastMessageAt` and `unreadCount`. Participants and the job link can't change, so nobody can add themselves.
- **Messages.** Readable by members. A member can create a message only as themselves, with a matching `chatId` and 1–5000 characters of content. Only the recipient can update a message, and only `isRead`. Only staff can delete.
- **Existing chats** keep working for their members: the existing chat screen was used live to send messages under the new rules. Old chats keep their random IDs.
- **Live probes as outsiders** (worker B, who wasn't hired): reading the job chat, adding themselves to it, and posting into it were all refused (403).

## 8. Budget sorting resolution

Fixed, hourly and daily budgets are different units, so they are never ranked together.
- Choosing a budget sort always applies one pay type. It defaults to fixed price, shown as a chip, and the sort label reads e.g. "Budget: high to low · Fixed price".
- Removing the pay-type chip while sorting by budget returns the sort to Newest.
- "Clear all" keeps the result valid.
- The filter sheet explains this rule.
- The same principle applies to received proposals: price sorting and the compare sheet group by rate type first.

Covered by unit and widget tests, and verified live.

## 9. Firestore and Storage rule changes

*Remediation:*
- `users/{uid}` read is now limited to the owner and staff.
- New `publicProfiles/{uid}`: signed-in users can read; nobody can write.
- New `liveLocations/{workerId}`: readable by the owner, staff and listed viewers; nobody can write.
- The job read rule no longer lets applicants read a job they applied to.
- Proposal `jobStatus` is allowed as a key but users can never set or change it.

The Phase 3B changes were:

Changes are in `firestore.rules` only; Storage is unchanged.
- **Proposals:** a create allowlist, content validation, eligibility and ownership checks, and the transition rules in §6. Reads are limited to the worker, the job's client and staff. Only staff can delete. `totalProposals` can't be written by users.
- **Jobs:** ~~a worker who applied can read the job, even after it closes or fills, to see its status~~ (removed in the remediation; applicants now use `jobStatus` on their proposal, see R2). The owner can assign a public job only together with an accepted proposal.
- **Contracts:** creation requires an accepted proposal (or a direct hire of the client's own job). Money and payment fields are locked for the parties.
- **Chats and messages:** see §7.
- **Indexes added to `firestore.indexes.json`:**
  - proposals (`jobId`, `clientId`, `status`)
  - proposals (`jobId`, `status`)
  - chats (`participantIds` CONTAINS, `relatedJobId`)
- Overlapping `allow` statements were reviewed. Phase 2 and Phase 3A protections are unchanged, and their tests still pass.

## 10. Cloud Function changes

- New:
  - `syncJobProposalCount` and `syncJobRelations` in `functions/src/proposals.ts`;
  - `syncUserMirrors` and `backfillMirrors` in `functions/src/profiles.ts`, with the runner `functions/scripts/backfill-mirrors.js`.
  - The three `sync…` functions are v2 Firestore triggers on firebase-functions 4.9. `backfillMirrors` is not a trigger; it runs only through the script.
- `syncJobRelations` replaces the earlier `closeProposalsWhenJobFilled` (see R2).
- `index.ts` exports them alongside the existing auth, notifications and reviews functions. The existing functions are unchanged.
- Not deployed.

## 11. Exact test results

| Suite | Result |
|---|---|
| Flutter unit and widget tests (`flutter test`) | **244 / 244 passed** (Phase 3A: 210; +34 new: 33 proposal screen tests, 1 account-switch test; existing job tests updated) |
| Firestore and Storage emulator rules tests (`rules-tests`, `npm test`) | **101 / 101 passed** (85 from Phase 3B + 16 remediation) |
| Cloud Function tests (`functions`, `npm test`) | **22 / 22 passed** (6 proposal + 12 profile and job-relation tests + 4 existing role-claim tests) |

The 16 required rules cases are numbered in `rules-tests/rules.test.js`:

| # | Case | Test |
|---|---|---|
| 1 | worker submits to an open job | "proposals: submitting" 1 |
| 2 | worker submits to a closed job | 2: closed, completed and direct-request jobs |
| 3 | client submits | 3 |
| 4 | unauthenticated user submits | 4 |
| 5 | duplicate proposal | 5 |
| 6 | modify another worker's proposal | 6 |
| 7 | change ownership | 7 |
| 8 | worker sets own proposal to accepted | 8 |
| 9 | client views proposals for own job | 9 |
| 10 | client views another client's proposals | 10 |
| 11 | client accepts an eligible proposal | 11: proposal, job, other proposals and contract together |
| 12 | client accepts for another client's job | 12 |
| 13 | two proposals both accepted | 13 |
| 14 | ordinary users change counts | 14 |
| 15 | unrelated users create or access job chats | 15 |
| 16 | existing participants keep using chat | 16 |

Extra rules tests:
- submitting on behalf of another worker, to a different client, or with forged ratings or decisions;
- invalid content;
- withdraw and re-send;
- a withdrawn or declined proposal can't be accepted;
- accepting without assigning, or assigning without accepting;
- only staff delete proposals;
- contract creation without an accepted proposal;
- a direct hire still works;
- money and payment fields are locked;
- participant tampering;
- message impersonation;
- a non-job chat between two clients.

Function tests:
- withdrawn proposals aren't counted;
- only relevant changes trigger a recount;
- the recount sets the true number and ignores forged values;
- retries and duplicate events never inflate the count;
- a missing job is skipped;
- filling a job closes only the proposals still pending, once.

## 12. Analyzer results

`flutter analyze`: **46 issues, 0 errors** after the remediation (Phase 3B: 47; Phase 3A baseline: 49). None of the remaining issues are new; all are pre-existing infos and warnings in older modules.

## 13. Build results

- **Flutter web release** (`flutter build web --release`, production config): **passed**.
- **Android** (`flutter build apk --debug`): **passed** (`build/app/outputs/flutter-apk/app-debug.apk`). The Gradle log has the existing "migrate to Built-in Kotlin" notice for plugin authors, which is not an error.
- **Emulator-connected web build** (scratchpad only, for testing): passed; rebuilt 5 times while fixing the issues the run found.
- **After the remediation:** web release **passed**, Android debug APK **passed**, emulator web build passed.

## 14. Emulator verification

**Environment.** Local emulators: Auth 9099, Firestore 8181, Storage 9198, Functions 5001.
- Functions ran from a scratch copy that loads only the proposal triggers (plus `syncUserMirrors` in the remediation run). Push-notification functions were left out so nothing could reach production messaging.
- Headless Chrome mapped `identitytoolkit`, `securetoken`, `firestore`, `firebasestorage` and `www.googleapis.com` to "not found". This was checked at every load ("blocked" ×4).
- Accounts were emulator-only: two clients and two workers. All jobs and proposals were created through the app's own UI; nothing was seeded into proposals or jobs.

**Worker.** Job discovery (feed) → job → details → send proposal (validation, confirm, sent) → My proposals → job chat with the client before the hire → status changes (Viewed, Accepted; and for the other worker, "Job filled") → withdraw → send again.

**Client.** My Jobs ("1 proposal" from the function) → owned job → View proposals → compare → review proposal (marked Viewed) → worker profile → accept, and in a second job, decline.

**Data checked after each step through the emulator's owner access:**
- Hire: job `assigned` to Bilal; his proposal `accepted`; Kamran's `rejected / filled`; contract Rs 2,500 fixed, commission Rs 250, earnings Rs 2,250, `unpaid`, `not_configured`, `active`; chat `jobId_workerId` with both members; worker notification.
- Decline: `rejected / client`; the job stays open.
- Withdraw then re-send: the count follows each change; `withdrawnAt` is cleared on re-send; the original `createdAt` is kept.
- Final counts match the real proposals: job 1 has 2 (accepted and rejected), job 2 has 2 (rejected and pending).

**Forged requests sent directly to the emulator with real user tokens, all refused (403):**
- a worker sets their own proposal to accepted;
- a worker writes `totalProposals: 99`;
- a worker reads another worker's proposal;
- the client accepts the already-closed second proposal;
- the client reassigns the job to another worker;
- an outsider reads, joins or posts in a job chat;
- another client reads the proposal.

The existing chat screen sent messages under the new message rules. Function logs show no errors.

**Not verified:** anything on production Firebase, push notifications, and the Android build on a device.

## 15. Screenshots

`design/phase3b/screens/` (43 files) with contact sheets `design/phase3b/phase3b-contact-light.png` and `phase3b-contact-dark.png`. Phone size 412×915.

- **Light:**
  - Worker:
    - job page with "Send a proposal": 02
    - form: 03
    - validation: 04
    - confirm: 05
    - sent: 21
    - My proposals: 06, 15
    - already sent: 07
    - filled: 13, 14
    - accepted: 16
    - contract: 17
    - chats: 18, 19, 42
    - withdraw: 22, 23
    - re-send: 24
    - discovery: 40, 41
  - Client:
    - job posted: 01
    - owner panel: 08
    - received: 09, 27, 44
    - compare: 10
    - review: 11, 45
    - accept: 12
    - decline: 25, 26
    - empty: 20
    - My Jobs count: 43
    - worker profile: 46
- **Dark:**
  - client received: 30
  - accepted review: 31
  - owner panel: 32
  - worker job page: 33
  - form: 34
  - confirm: 35
  - details: 36
  - My proposals: 37
  - feed budget sort: 38

Screenshots 05, 09, 10, 11 and 12 were taken before the layout and copy fixes in §1 (price and duration overlap, duration alignment, "Client's budget", compare amounts). The fixed versions show in 16, 27, 30, 31 and 45. There is no fresh screenshot of the compare sheet after its fix; that fix is in code and was analyzer-checked.

## 16. Outstanding issues

1. ~~**Hired worker's name on the job document.**~~ **Fixed**: unsuccessful applicants can no longer read the job; they follow it through `jobStatus` on their proposal (R2).
2. ~~**User profiles readable by any signed-in user.**~~ **Fixed**: `users/{uid}` is owner and staff only; others read `publicProfiles` and `liveLocations` (R1). Remaining risks are listed in R5.
3. **Acceptance is a rules-guarded client batch**, not a callable function. It is safe as tested. A callable function would add server-side logging and a single place to change the logic.
4. **Closing late proposals is eventual**, not atomic. A proposal that arrives just before a hire is closed by the function within about a second, not in the same write.
5. **Legacy screens not redesigned**, because they are out of scope:
   - the Contracts list;
   - the "assigned job" view (live map that falls back to default coordinates, hard-coded English or Urdu strings, "Start Work");
   - the chat list and chat room.
6. **Old app versions.** After the new rules are deployed, older app builds can't start job chats (they use random IDs) and still can't submit proposals (that was already broken).
7. **Functions toolchain warnings.** `firebase-functions` 4.9 is reported as outdated; `engines.node` says 20 while the test machine runs Node 24.
8. **Notification payloads** are written by the client, the existing pattern, and push delivery wasn't exercised (no production messaging in the emulator).

## 17. Required manual Firebase Console actions

None until you approve deployment. When you do:
- Confirm the project is on the **Blaze plan**; 2nd-gen Firestore triggers require it.
- Allow the Eventarc and Cloud Run service agents if the first v2 deploy asks for it.
- Create the five new composite indexes (deploying `firestore.indexes.json` does this) and wait until they finish building:
  - proposals (`jobId`, `clientId`, `status`)
  - proposals (`jobId`, `status`)
  - chats (`participantIds`, `relatedJobId`)
  - publicProfiles (`role`, `geohash`)
  - jobs (`selectedWorkerId`, `status`)
- No proposal-count backfill is needed: before this phase no proposal could be created, so all existing `totalProposals` values are 0.
- A **profile backfill is needed** (additive, once): existing accounts have no `publicProfiles` record until they next change. Run `functions/scripts/backfill-mirrors.js` with Admin credentials and `--confirm-production`, only with your approval.

## 18. Production deployment requirements

Recommended order, each step only with your approval:
1. `firebase deploy --only firestore:indexes` and wait for the build.
2. `firebase deploy --only functions:syncJobProposalCount,functions:syncJobRelations,functions:syncUserMirrors`
3. Run the profile backfill once (`npm run build`, then `node scripts/backfill-mirrors.js --project <id> --confirm-production`), and check that the `publicProfiles` count matches the `users` count.
4. `firebase deploy --only firestore:rules`
5. Release the app build.

Steps 4 and 5 should ship together:
- the new rules refuse older builds' cross-user profile reads and job-chat creation;
- the new app needs the mirrors, and the new rules for proposals.

Don't deploy the rules before steps 2 and 3, or discovery and profile pages will be empty.

Before releasing, smoke-test on a staging project or with a test account:
- send a proposal;
- confirm the count updates;
- accept a proposal;
- check the contract and chat;
- confirm a second acceptance is refused;
- open a worker profile and confirm no phone number is returned (DevTools network tab);
- confirm an unsuccessful applicant can't open the filled job.

---

Phase 3B stops here. Phase 4 has not been started and waits for your approval.
