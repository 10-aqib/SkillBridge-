# SkillBridge — Free plan, Phase S4: hiring and contracts without Cloud Functions

Status: **implemented and tested locally, including a run of the real app code against the real rules on the emulator. Nothing deployed, committed or pushed.** The rules go live with the new app in S8. Awaiting your approval for Phase S5 (chats, reviews, notifications).

## 1. What changed

The three callable functions (`acceptProposalCall`, `directRequestCall`, `contractActionCall` with its 8 actions) are replaced by **Firestore transactions in the app** (`contract_transactions.dart`), and **`firestore.rules` now holds the contract state machine** the functions used to enforce. The app's screens and providers are unchanged: they call the same `ContractActions` methods as before.

| Step | Who / when (enforced by the rules) | Written together, in one transaction |
|---|---|---|
| **Accept a proposal** | Job owner; public open job; pending proposal | Proposal → accepted; job → assigned to that worker; other pending applicants → rejected "filled", with the job status copied; **contract created with terms taken from the proposal and job**: rate, 10% commission rounded to whole rupees, worker's share, names, title, area. Wrong price, commission, worker, title, status or payment fields are all refused. |
| **Answer a direct request** | The requested worker, while the job is open | Job → assigned; contract at the client's budget (a range stays a range: `priceMin`). Declining cancels the job. |
| **Booking request** (client books a worker) | Client, own job | Unchanged, except new bookings now use the shared id `{jobId}_{workerId}` so the rules can link job and contract. |
| Respond to a booking | The worker, while pending | Contract active or rejected; on decline the job is cancelled with it. |
| Start | The hired worker, once, job assigned to them | `workStartedAt` at server time; job → in progress. |
| Submit | The hired worker, after starting | Submission record `submissions/{n}` (same note and photos), contract counters, live location removed. Note 10–1000 characters, up to 3 photos. |
| Request changes | Client, on submitted work, **at most 3 rounds** | Revision count +1, note, recorded on that submission. |
| Confirm | Client, only after submission | Contract completed; job completed; **worker's completed-jobs count +1, naming this contract**. A contract completes once, so it's credited once; the client can't touch anything else on the worker's account. |
| Cancel | Either party, before submission, with a listed reason | Contract cancelled with who and why; job cancelled; live location removed. |
| Share address / pin | Client, while open | Address 5–200 characters; the pin is a real map position (not 0,0) with its server time, or removed together with that time. |
| Progress update | Hired worker, before submission | `updates/{id}` plus the contract's update counter and id; the same id again is a no-op. |

Every step: only the listed fields may change, all times are server times, and suspended accounts are refused.

## 2. Problems found (fixed)
- **A job could get out of step with its contract.** As first written, confirming, cancelling or declining didn't require the job to move in the same write. A rules test caught it. The rules now require the job to follow its contract.
- **Old processes left from the Phase 10 run** were still holding the emulator ports. I identified them as my own demo-project emulators and stopped them. This run's emulators were shut down fully.

## 3. Trade-offs (stated plainly)
- **Notifications:** most steps notify the other party in the same transaction. "Changes requested" and "Progress update" notifications are still blocked by the current notification rule, which predates this work, so they're sent best-effort afterwards and won't be delivered until S5 updates that rule. The step itself always succeeds.
- **The job chat is no longer opened by the hire.** It opens when either party first messages (S5, replacing `openChatCall`).
- **Race on hiring:** the other pending proposals are read just before the hire is written. A proposal sent in that same moment could stay "pending" on a filled job. The rules stop any new proposal once the job is assigned, so this can only affect one that arrives in that exact window.
- **Older bookings** with random contract ids, if any exist in production, can still be read. Their job-linked steps (start, cancel and so on) will be refused, because the rules look contracts up as `{jobId}_{workerId}`.

## 4. Tests

| Check | Result |
|---|---|
| Rules tests (emulator) | **152 / 152 passed**: 134 before plus 18 new S4 tests. They cover hiring (the right write; 13 kinds of wrong terms; each missing half; wrong person or stage; no repeat), direct requests (price, range, job step, other worker), start, submit, confirm (with credit: none, +2, wrong contract, missing job, a second credit), cancel (role label, reason, stranger, after submission), address and pin (0,0, missing time, worker, short address, removal), revisions (worker refused, 4th round refused), progress updates (each half alone, client, bad id, duplicate id), bookings (accept, decline with job, random id refused). The two earlier booking tests now use the shared id. |
| **Real app code vs real rules** (probe app, emulator, demo project) | **28 / 28 passed**: S2 public profiles; S3 send, withdraw, re-send, second applicant, count = 2, closing a job copies the status; S4 accept (terms, other applicant "filled"), accept again returns the same contract, pin, progress update and its retry, submit before start refused, start, submit, worker can't confirm, revision, resubmit, confirm (job completed, worker count 1, public profile follows), direct request (range kept), worker cancel, booking with the new id, booking accept, client cancel. |
| App unit tests (new) | **13 / 13**: stage logic matching the rules; commission rounding; bad input refused before sending (notes, photos, reasons, address, pin, request id, empty ids). |
| Full `flutter test` | **487 / 487 passed** (474 + 13 new) |
| `dart analyze lib test` | 0 errors, 5 warnings, 28 infos: **no new issues** |

## 5. Files
- New: `lib/features/contracts/data/datasources/contract_transactions.dart`, `test/unit/contract_transactions_test.dart`.
- `contract_remote_datasource.dart`: `ContractActionsImpl` now uses the transactions; booking id.
- `proposal_remote_datasource.dart`: accept via the transaction.
- `contract_providers.dart`, `proposal_providers.dart`: pass Firestore and Auth instead of Functions.
- `firestore.rules`: contract state machine; job hire and contract-following steps; proposal accept; "filled" may carry the job status; worker credit on confirm; live-location removal by the client in the closing step; updates and submissions writable only together with their step.
- `rules-tests/rules.test.js`: 18 new tests, 2 updated.
- Probe (outside the repo): `scratchpad/e2e/entry/s4_probe.dart`, `s4seed.py`. Snapshot: `design/spark/.snapshot/s4/`.
