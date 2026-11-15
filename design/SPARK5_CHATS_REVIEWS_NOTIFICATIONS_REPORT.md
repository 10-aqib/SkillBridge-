# SkillBridge — Free plan, Phase S5: chats, reviews and notifications without Cloud Functions

Status: **implemented and tested locally, including the real app code against the real rules on the emulator. Nothing deployed, committed or pushed.** These rules go live with the new app in S8. With S5 done, **nothing in the app needs Cloud Functions any more, apart from photo uploads (Storage), which S6 replaces.** Awaiting your approval for Phase S6 (photos via the image host).

## 1. What replaced the functions

| Was | Now |
|---|---|
| `openChatCall` created conversations after checking a relationship | The member's app opens it, and **the rules check the same relationship**. A job conversation `{jobId}_{workerId}` is allowed for the job's client with a worker who is writing about a public open job, applied, or was selected or hired. A direct conversation `direct_{clientId}_{workerId}` can only be started by an active client with an active worker. The other account must be active. Names must be the people's real display names (or "SkillBridge user"), photos theirs or none, counters zero, no history, and no overwriting an existing conversation. Older conversations with random ids are still found and reused. |
| `onChatMessageCreated` kept the preview, ordering time and unread count, and notified the recipient | **Each message is one write with its summary**: the preview, last sender, time and type, plus the recipient's unread count +1 and their in-app notification. The rules refuse a message without its summary, a summary without its message, +2, your own count, or a spoofed sender. A retry of a sent message is still recognised as sent, never duplicated. |
| `aggregateReviewRating` recomputed averages after each review | A **rating ledger** per person, `ratings/{uid}` (count, sum, average to one decimal), **moves only together with a new review of that person, by exactly that review**. The rules check count +1, sum + rating, and the rounded average. Nobody writes it directly, not even its owner. Each person's app copies it onto their own account, and the rules accept only those values; the public profile then follows (S2). The reviewer never touches the other person's private account. |
| `onNotificationCreated` sent push notifications | **In-app only**, as you chose: the notification list and badges, live while the app is open. No alerts while it's closed. The **creation rule was rewritten**: a notification needs a real link to its recipient (a contract both are party to, a chat both are in, or a job between its client and a worker who applied or was chosen). It must be short, unread, at server time, and never to yourself. "Changes requested" and "Progress update" notifications, held back in S4, are now delivered. |

## 2. Trade-offs (stated plainly)
- **No alerts while the app is closed.** The app still asks for notification permission and stores its push token; both are harmless and unused without a server. If Blaze becomes possible, the old push function can be deployed again unchanged.
- **Notification wording comes from the sender's app.** The rules limit who it goes to, the length and the fields, but not the exact words. That's the cost of having no server.
- **A rating shows on someone's profile once their own app next opens.** The ledger itself is current immediately and can't be faked.
- **Chat preview text** is computed by the sender's app (up to 120 characters). It's their own message.

## 3. Tests

| Check | Result |
|---|---|
| Rules tests (emulator) | **159 / 159 passed**: 152 before plus 7 new. (1) Conversations open only for a real relationship: 3 allowed cases; worker-started direct chat, wrong client, no link, wrong id, suspended account and overwrite refused. (2) No faked names, counts, history, creator, photos or title. (3) A message needs its summary and vice versa (+2, own count and spoofed sender refused). (4) Notifications only between linked people (not in the chat, recipient not in it, no link, too long, to yourself, no proposal behind it, pre-read). (5) A review and its ledger step together, with the right count, sum and average. (6) Averages to one decimal. (7) No direct ledger writes; owners copy only the ledger's values. 5 older chat tests now send messages with their summary. The old "conversations only by the function" test became the S5 relationship tests, and the old notification test now refuses unlinked notifications. |
| **Real app code vs real rules** (probe app, emulator) | **14 / 14 passed**: worker opens a job chat; message with summary, unread count and notification; worker can't start a direct chat; the client finds the same chat with 1 unread and the preview; the client's notification; mark read and reply; client opens a direct chat; progress update and change request now delivered; the client reviews (ledger 1 at 4.0); a duplicate review refused; the worker reviews the client; the worker's app copies the ledger and the public profile shows rating 4 and 1 completed job. |
| App unit tests (new) | **8 / 8**: chat preview; ledger arithmetic matching the rules (e.g. 13 / 3 → 4.3); copying the ledger onto accounts. |
| Full `flutter test` | **495 / 495 passed** (487 + 8 new) |
| `dart analyze lib test` | 0 errors, 5 warnings, 28 infos: **no new issues** |

## 4. Files
- `firestore.rules`: chat creation and message summary rules; rating ledger; owners may copy their ledger; notification creation rule.
- `lib/features/chat/data/datasources/chat_remote_datasource.dart`: open conversations and send messages without functions; `chatPreviewOf`. CRLF kept.
- `lib/features/reviews/data/datasources/review_remote_datasource.dart`: review transaction with the ledger; `nextRatingLedger`. CRLF kept.
- `lib/core/services/public_profile_sync.dart`: copies the ledger onto the account (`ratingsCopyFor`).
- `lib/core/constants/firestore_paths.dart`: `ratings`.
- New tests: `test/unit/free_plan_s5_test.dart`; `rules-tests/rules.test.js` (7 new, 7 updated).
- Probe (outside the repo): `scratchpad/e2e/entry/s5_probe.dart`. Snapshot: `design/spark/.snapshot/s5/`.
