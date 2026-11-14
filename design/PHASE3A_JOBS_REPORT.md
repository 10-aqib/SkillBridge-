# Phase 3A: Job Posting & Job Discovery

**Date:** 9 November 2026 · **Branch:** `ui-improvements-2026`

**Status:** complete, awaiting approval. Nothing is committed, pushed or deployed (no rules, indexes, functions or app). Phase 3B has not started.

**Definition of done (verified on the Firebase Emulator Suite, not production):** a real client published, edited, closed and managed their own jobs. A real worker discovered, searched, filtered, sorted and opened published jobs. All of it ran against Firestore under the new security rules.

## Summary

| Area | Result |
|---|---|
| Client: create, publish, edit, close, reopen | **Completed** |
| Client: My Jobs | **Completed**: Open / Active / Completed / Closed tabs, real proposal counts |
| Worker: job feed, search, filters, sort, paging, details | **Completed** |
| Firestore and Storage security | **Completed**: job rules rewritten, 27 new emulator tests (55 / 55 total) |
| Tests | **210** Flutter tests pass; 55 / 55 rules; 4 / 4 functions |
| Analyzer | **0 errors**, 0 new issues (49 total, against 52 after Phase 2B) |
| Builds | Web release **Pass** · Android debug **pass** |
| Live run (emulators) | All workflows pass; 2 bugs found and fixed during the run (§11) |

## 1. Files created

**App code** (`lib/features/jobs/`):
- `domain/job_search.dart`: search keywords, budget bands, feed query and query plan (pure Dart).
- `data/job_feed_source.dart`: Firestore query builder and cursor pager.
- `presentation/providers/job_feed_controller.dart`: feed state, paging and error kinds.
- `presentation/screens/job_feed_screen.dart`: the worker "Find work" feed.
- `presentation/widgets/job_ui.dart`: shared labels, status badge, job card and skeleton.
- `presentation/widgets/job_actions.dart`: close and reopen (with confirmation), proposal count.
- `presentation/widgets/job_lifecycle_actions.dart`: the pre-existing hiring and work actions, moved unchanged out of the old details screen.

**Tests:**
- unit: `test/unit/job_search_test.dart`, `job_feed_pager_test.dart`;
- widget: `test/widget/post_job_test.dart`, `jobs_screens_test.dart`;
- helpers: `test/helpers/fake_job_feed_source.dart`, `fake_job_datasource.dart`, `job_fixtures.dart`.

**Docs:** this report and `design/phase3a/` (screenshots and contact sheets).

## 2. Files modified

| File | Change |
|---|---|
| `jobs/domain/entities/job_entity.dart` | `searchKeywords` field; `isPublicOpen` |
| `jobs/data/models/job_model.dart` | Derived `searchKeywords` and `budgetBand`; `toCreateMap()` (server timestamps); `toEditMap()` (content only) |
| `jobs/data/datasources/job_remote_datasource.dart` | Server-timestamped create; `editJob`, `setJobStatus`, `watchJob`, `countProposals`; open-job queries exclude direct requests |
| `jobs/presentation/providers/job_providers.dart` | `jobByIdProvider` (no retry on permission denial); `jobProposalCountProvider` |
| `jobs/presentation/viewmodels/post_job_viewmodel.dart` | Rewritten: client-role and active checks, duplicate-submit guard, edit support |
| `jobs/presentation/screens/post_job_screen.dart` | Rewritten create/edit form; `EditJobScreen` |
| `jobs/presentation/screens/my_jobs_screen.dart` | Rewritten My Jobs |
| `jobs/presentation/screens/job_details_screen.dart` | Rewritten; loads the job live by id; one screen for both roles |
| `config/router/app_router.dart`, `route_names.dart` | `/jobs/:jobId`, `/jobs/:jobId/edit`, `/worker/jobs`; old `/client/jobs/:jobId` kept and pointed at the new screen |
| `worker/presentation/screens/worker_home_screen.dart` | "See all" and "Browse jobs" go to the feed (they went to My Proposals); job taps use `/jobs/:id` (workers were blocked from `/client/...`) |
| `worker/presentation/screens/worker_profile_setup_screen.dart` | Uses the shared skill list |
| `core/constants/pakistan_constants.dart` | `skillSuggestions` (moved, shared), `categoryById` |
| `core/services/profile_media_service.dart` | `uploadJobPhoto` → `users/{uid}/jobPhotos/` |
| `shared/design_system/sb_job_card.dart` | Optional `summary`, `tags`, `byline` (existing uses unchanged) |
| `contracts/data/datasources/contract_remote_datasource.dart` | Contract → job status mapping; server `createdAt` for direct-hire jobs |
| `chat/data/datasources/chat_remote_datasource.dart` | Stores `relatedJobId` / `relatedJobTitle` (previously written under literal `'?relatedJobId'` keys) |
| `l10n/app_en.arb`, `app_ur.arb`, `generated/l10n/*` | 153 new keys in each language |
| `firestore.rules`, `storage.rules`, `firestore.indexes.json` | §5, §6 |
| `rules-tests/rules.test.js` | 27 job and Storage tests |
| `test/unit/arb_parity_test.dart` | Placeholder check no longer mistakes plural text for placeholders |

All edited files keep their original line endings (checked against a pre-phase snapshot). Git status went from 193 to 206 entries; all of your earlier uncommitted work is untouched.

## 3. Existing functionality reused

- `jobs` collection, `JobModel` / `JobEntity`, `JobRemoteDataSource`, routes and screen names.
- Statuses `open / assigned / in_progress / completed / cancelled`. "Closed" is shown for `cancelled`.
- `reports` collection, as already used for worker profiles. Job reports use `targetType: 'job'` and the admin queue already lists by type.
- Chat room creation, for "Message client".
- `PakistanConstants` categories and cities; `PakistaniTradeSynonyms` (Roman-Urdu search terms).
- `ProfileMediaService`, `pickProfileImage`, `CityDropdown`.
- Phase 1/2 design system (`SbJobCard`, `SbStatusBadge`, `SbButton`, `SbTextField`, `SbStateView`, `SbSkeleton`, `showSbConfirmSheet`).
- The old details screen's hiring and work actions: direct-request accept/decline, received proposals, live tracking, start, complete and pay. These are kept as `JobLifecycleActions`.

**Not added, because outside the FYP scope or not supported by the schema:**
- Drafts (no draft status exists).
- Remote work (SkillBridge is local services).
- PDF attachments (job photos only).

## 4. Firestore schema changes (additive, no migration)

| Field | Type | Why |
|---|---|---|
| `searchKeywords` | string[] (≤ 300) | Firestore has no full-text search. It holds lower-case words from the title, category (plus Roman-Urdu synonyms) and skills with their prefixes, plus whole description and city words, so `array-contains` can search on the server. |
| `budgetBand` | string | `under_2k`, `2k_5k`, `5k_15k`, `15k_50k`, `over_50k`. Firestore can't range-filter on budget while sorting by date, so equality on a band works with every sort. |

Behaviour changes:
- `createdAt` and `updatedAt` are now server timestamps; the rules require `createdAt == request.time`.
- New jobs no longer store an exact map pin. The form asks for city and area only, in line with Phase 2B's "exact addresses are shared only for booked jobs". The old `location` field is kept for compatibility.

**Backward compatibility:**
- Jobs created before this phase lack the two new fields. They still appear in the feed and sort correctly, but don't match keyword search or budget-band filters until edited.
- A one-off backfill (read each job, write the two derived fields) would fix that. It needs your approval; nothing was migrated.
- Open jobs must have `selectedWorkerId: null` to appear in the feed. The app has always written that field.

**Admin compatibility:** the admin dashboard reads `title`, `clientName`, `categoryName`, `city`, `budgetMin/Max`, `status`, `totalProposals` and `createdAt`. All are unchanged. It uses the Admin SDK, so the new rules don't affect it.

## 5. Security-rule changes (repo only — not deployed)

**Jobs, rewritten** (`firestore.rules`):
- **Read:** owner, the selected worker, staff, or any **active** user for **public open** jobs (`status == 'open'` and `selectedWorkerId == null`). Closed jobs, other workers' direct requests and assigned jobs are not readable by others.
- **Create:**
  - client role, active, `clientId == auth.uid`, `createdAt == request.time`;
  - `totalProposals == 0`, not paid, and a field allowlist (no unknown or staff fields);
  - content validation: title 5–100, description 10–2000, ≤ 15 skills, budget type, `0 ≤ min ≤ max ≤ 10,000,000`, valid status, ≤ 6 images, ≤ 300 keywords;
  - either public-open, or a direct request / direct hire to another user.
- **Update, owner:**
  - can never change `clientId`, `createdAt`, `totalProposals` or `isPaid`;
  - may edit content only while open;
  - may close (open → cancelled) or reopen (cancelled → open, public jobs only), changing status alone;
  - may hire (open → assigned with a worker);
  - may start, finish or cancel assigned work.
- **Update, selected worker:** status only, with listed transitions (accept or decline a direct request, start, complete).
- **Delete:** staff only. Published jobs are kept for history; clients close them instead.
- Each operation has exactly **one** `allow` statement, so no broader rule can widen it.

**Supporting changes:**
- `isValidLocationUpdate` now allows `location: null`; without that, every job without a pin was refused.
- Plain `selectedWorkerId` comparisons replace `.get('selectedWorkerId', null)`. During testing, the `.get()` form let the emulator accept a status-only query that **returned another worker's private direct request**. Now refused (tested).

**Storage:**
- The legacy `jobs/{jobId}/**` path let **any** signed-in user overwrite any job's files. It was unused and is now write-denied.
- Job photos go to `users/{uid}/jobPhotos/` (owner-only writes, public reads; existing rule).

Phase 2 protections are unchanged. All 28 earlier rules tests still pass.

## 6. Search, filters and sorting

All results come from **Firestore queries with cursor pagination** (15 per page). The list never just filters jobs already on screen.

| Feature | How it runs |
|---|---|
| Base | `status == open` and `selectedWorkerId == null` (required by the rules) |
| Search | Words are normalised. The **longest word** is sent as `searchKeywords array-contains`, and any other words are checked against each fetched page. Prefixes work for title, category and skills ("socket" finds "sockets"); Roman-Urdu category words work ("bijli" finds electrician jobs). |
| Category / rate type / budget band | Equality filters |
| Skills (up to 10) | `requiredSkills array-contains-any`. When combined with a search, the skills are checked per page (Firestore allows one array filter per query). |
| Posted within | `createdAt >=` with date sorts. With budget sorts it's checked per page (Firestore can't range on date and sort by budget). |
| Sort | Newest / oldest (`createdAt`), budget low/high (`budgetMax`) |
| Per-page checks | The pager keeps reading up to 4 server pages per load until it has 15 matches, then offers "Load more", so results cover all jobs. |

**Limitations:**
- Search is word/prefix based, not fuzzy or ranked. Description words match whole words only.
- Budget sort compares raw amounts, so a Rs 1,000/hour job sorts below a Rs 1,500 fixed job.
- There's no city filter; it wasn't in the brief, and the area is shown on every card.
- Older jobs need the backfill (§4) to be searchable.
- No dedicated search service was added.

**Composite indexes:** 24 were added to `firestore.indexes.json`. Each is `status, selectedWorkerId, [one of none / categoryId / budgetBand / budgetType / searchKeywords (contains) / requiredSkills (contains)], sort field`, for the 4 sorts. Multi-filter combinations rely on Firestore's index merging. **The emulator doesn't check indexes, so none of this has been verified in production.** Any missing index shows a clear "being set up" message in the app, and the Firebase console error link creates it.

## 7. Screens and routes

| Screen | Route | Reached from |
|---|---|---|
| Post a job / direct request | `/client/post-job` | My Jobs (+), empty state, worker profile "Request booking" |
| Edit job | `/jobs/:jobId/edit` | My Jobs card, job details (owner) |
| My Jobs | `/client/jobs` (Bookings tab) | Bottom navigation |
| Find work (feed) | `/worker/jobs` | Worker home "See all" / "Browse jobs" |
| Job details (both roles) | `/jobs/:jobId` (and the old `/client/jobs/:jobId`) | Feed, My Jobs, worker home |

**Worker primary action:** "Message client" opens a real chat linked to the job. Report job files a report. Proposal submission is **not shown**: the old "Submit proposal" write is refused by the rules and belongs to Phase 3B. The screen says so honestly.

**Hidden actions:**
- The owner gets no message or report actions.
- Closed jobs give workers nothing; they can't read them.
- Suspended users see a notice and no actions.
- Workers are redirected away from the client job screens.

## 8. Tests executed

| Suite | Kind | Result |
|---|---|---|
| Full `flutter test` | Mocked (fake data sources and providers) | **210 pass** |
| Of which, Phase 3A unit | Search keywords, query plans, budget bands, model maps, status mapping, pager (cursor, per-page checks, scan limit), controller (paging, errors, retry) | 29 |
| Of which, Phase 3A widget | Form validation, budget rules, confirmation, publish data, duplicate-submit guard, failure, non-client, direct request, edit; My Jobs tabs, counts, close, reopen, empty and error; feed list, paging, search, no-match, filters and chips, clear-all, sort, empty, error retry, navigation; details for worker / owner / closed / suspended / unavailable, plus hiding a cached copy after refusal | 27 |
| `rules-tests` (`npm test`) | **Real rules in the Firebase emulator** | **55 / 55** (27 new: the 10 required cases plus transitions, protected fields, direct requests, feed queries, Storage) |
| `functions` (`npm test`) | Role-claim unit tests | 4 / 4 |

## 9. Analyzer

`flutter analyze`: **49 issues: 0 errors, 10 warnings, 39 info.**
- After Phase 2B: 52 (0 / 10 / 42).
- **No new issues.** Three were resolved, in the rewritten post-job screen.
- All remaining warnings are in files this phase didn't touch.

## 10. Builds

| Build | Result |
|---|---|
| `flutter build web --release --dart-define-from-file=.env` | **Pass** |
| `flutter build apk --debug --dart-define-from-file=.env` | **Pass** (`build/app/outputs/flutter-apk/app-debug.apk`) |

## 11. Emulator verification (not production)

The real release web app was built with a separate entrypoint pointing at local Auth, Firestore and Storage emulators that run the new rules, and driven like a user at 412 × 915.
- **Production Firebase hosts were blocked in the test browser** and confirmed unreachable.
- Profiles for three test accounts (two clients, one worker) were seeded in the emulator.
- **All five jobs were created through the app UI.**

| Workflow | Result |
|---|---|
| Client posts a job (validation, skills, budget, area, urgency, photo, confirmation) | Pass. Stored with the right owner, `open`, no worker, 0 proposals, unpaid, **server** `createdAt`, band `2k_5k`, 87 keywords, 1 photo in `users/<uid>/jobPhotos/`, no map pin. |
| Four more jobs (plumber fixed, AC per hour, painter in Karachi, electrician) from two clients | Pass |
| My Jobs (tabs, counts, "No proposals yet" from the proposals collection) | Pass |
| Close (confirmation) and live list update; reopen offered | Pass |
| Edit (rate 900 → 1,000/hour) | Pass: saved, returned; `createdAt` and owner unchanged; band recalculated |
| Worker feed (4 open jobs, closed one excluded) | Pass |
| Search "socket", "tap"; Roman-Urdu "bijli" | Pass |
| Budget filter; category + skill filter; chips; clear all; no-match state | Pass |
| Sort by budget high → low | Pass |
| Worker job details; client public card (name, member since, city, email-verified) | Pass |
| Message client: chat created and linked to the job | Pass |
| Report job → `reports` (`targetType: 'job'`) | Pass |
| Worker opens a closed job by link | Pass **after fix** |
| Worker opens client job screens | Pass: redirected to worker home |
| Server check with the worker's token: closed job 403, open job 200 | Pass |

**Bugs found during the live run and fixed:**
1. **Cached copy shown after refusal.** A client viewed a job, signed out, and a worker signed in on the same tab and opened the job's link. The details screen kept showing the copy from Firestore's in-memory cache after the server refused the read.
   - Fix: any error now replaces the copy with "no longer available".
   - Regression test added.
2. **Endless spinner on refusal.** Riverpod 3 retries failed providers automatically, so the refused read spun forever.
   - Fix: permission denials are no longer retried, and errors take precedence over loading.
   - Tested.

**Also found and fixed while writing tests:**
- The My Jobs action row overflowed on phones.
- The ARB parity check mis-read plural text.

## 12. Screenshots

Folder: `design/phase3a/screens/` (33 captures). Contact sheets (light on top, dark below) in `design/phase3a/`:
- `sheet-client-post-job.png`: form, validation, confirmation, edit, owner details, owner panel
- `sheet-client-my-jobs.png`: empty, list, close confirmation, closed job (owner)
- `sheet-worker-discovery.png`: feed, search, filters, skill filters, filtered, sorted, no match
- `sheet-worker-job-details.png`: details, chat from a job, report sheet, closed job (worker)

All signed-in screens are from the emulator-connected build; test images are labelled `TEST`. Some screens were captured in only one theme; the sheets mark these "no capture".

## 13. Known issues and incomplete features

**Partially completed:**
- **Proposal counts are real but always 0 for now.** Creating a proposal also increments the job's counter, and the rules (before and after this phase) refuse that write from a worker. The count comes from the proposals collection itself. Phase 3B must rework proposal submission (e.g. drop the client-side counter or use a Cloud Function).
- **Owner details still show the old "View Received Proposals" button** (old style). It's part of the kept hiring flow, to be redesigned in Phase 3B.

**Not implemented (by design or out of scope):**
- Drafts, remote jobs, PDF attachments, city filter.
- Fuzzy or ranked search.
- Backfill of older jobs.
- Proposal submission (Phase 3B).

**Other notes:**
- Budget sort mixes per-hour and fixed amounts.
- City has no `*` marker, though it's required and validated.
- Re-opening the job form doesn't remember a half-finished draft.
- Chat rules (pre-existing) let any signed-in user create a chat document. Review in Phase 3B.
- The Phase 2B items still stand: drawer sign-out without confirmation, made-up worker-home trend labels, and no admin review UI.

## 14. Manual Firebase Console actions

1. **Deploy** after review: `firebase deploy --only firestore:rules,firestore:indexes,storage`. Run `cd rules-tests && npm test` first. Deploying the indexes takes a while to build; the feed shows a clear message until they're ready.
2. Watch for any **missing-index** errors on uncommon filter combinations; open the console link to create them.
3. Decide on a one-off **backfill** of `searchKeywords` and `budgetBand` for existing jobs (needs your approval).
4. Storage **CORS** for the production bucket, so job and profile photos load on web (from Phase 2B).
5. Still outstanding from earlier phases:
   - Maps key rotation;
   - App Check registration;
   - Auth providers and authorised domains;
   - disabling `/api/setup-admin`.

## 15. Deployment steps still pending

Nothing has been deployed: Firestore rules and indexes, Storage rules, Cloud Functions (Phase 2B claim fix), the web app and the admin dashboard are all pending. Nothing is committed or pushed.
