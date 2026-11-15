# SkillBridge — Free plan, Phase S3: jobs and proposals

Status: **implemented and tested locally. Nothing deployed, committed or pushed.** As with S2, these rules go live with the new app in S8. Awaiting your approval for Phase S4 (contracts).

## 1. What replaced the two functions

| Was (Cloud Function) | Now (app write + rules check) |
|---|---|
| `syncJobProposalCount` recounted a job's proposals after every change | Sending, re-sending or withdrawing a proposal now changes the job's `totalProposals` **in the same write**: +1 when a proposal is sent or re-sent, −1 when it's withdrawn. **The rules tie the two together.** A proposal is refused unless the count moves by exactly one in that write, and the count can only move when that worker's own proposal changes the same way. Nothing else on the job can change, and the count never goes below 0. Several workers applying at once is safe, because the app uses Firestore's atomic `increment`. |
| `syncJobRelations` copied the job's status onto every proposal (`jobStatus`), so applicants can follow a job they can no longer read | When the client closes or reopens a job, their app updates the job **and** its proposals' `jobStatus` in one write. **The rules accept only the job's real status**, and only from that job's client, changing only that field. Workers still can't touch it. |
| `syncJobRelations` also closed other pending proposals once someone was hired | Moves to **S4**, because hiring is part of accepting a proposal (contract creation). |
| Live-location viewer list | Not used by the app (see S2); nothing to replace. |

## 2. Edge cases handled
- **Jobs whose count was never kept.** Every job in production so far has `totalProposals = 0`, because the functions never ran. Withdrawing a proposal on such a job keeps the count at 0 instead of failing. The app tries the counted withdraw first, and if the rules refuse it, withdraws without touching the count.
- **Duplicate or replayed writes:** a second "send" for the same proposal is refused, because the proposal id is fixed per worker per job. A bump can't ride on an unchanged proposal.
- **Large jobs:** the status copy covers up to 450 proposals per change, which stays inside Firestore's 500-write limit.

## 3. Limits (stated plainly)
- **Old counts stay wrong.** Existing production jobs show 0 proposals even where some exist. They'll correct as proposals change, but won't jump to the true number. A one-time recount can be run locally with the Admin SDK, which doesn't need Blaze (`functions/scripts` already has this kind of script). That's for S8, with your approval.
- **Closing or reopening is now two reads plus one write.** The app reads the job's client id, then lists that job's proposals before writing.

## 4. Tests

| Check | Result |
|---|---|
| Rules tests (emulator) | **134 / 134 passed**: 4 existing tests updated to send the count with the proposal, plus 4 new ones. (1) A proposal must count itself exactly once: no count, +2, −1, or extra job fields are all refused. (2) Nobody can move a count without their own proposal changing, including clients and other workers. (3) A count that was never kept stays at 0 on withdraw. (4) The client copies only the job's real status; a wrong status, extra fields, workers and other clients are all refused. |
| Full `flutter test` | **474 / 474 passed** (no regressions) |
| `dart analyze lib test` | 0 errors, 5 warnings, 28 infos: **no new issues** |

These app write paths call Firestore directly, and the project has no Firestore fake for unit tests. The rules tests cover the exact write shapes the app sends. The S7 end-to-end run will exercise the real app code against the emulator.

## 5. Files
- `firestore.rules`: count and status-copy rules.
- `lib/features/proposals/data/datasources/proposal_remote_datasource.dart`: count on send, re-send and withdraw.
- `lib/features/jobs/data/datasources/job_remote_datasource.dart`: status copy on close and reopen.
- `rules-tests/rules.test.js`: tests.
- Snapshot: `design/spark/.snapshot/s3/`.
