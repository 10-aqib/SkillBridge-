# SkillBridge — Track G, Phase G5: trusted notifications and push

Status: **code done, tested locally and on emulators; NOT deployed.** Part of the approved overnight run. Nothing committed or deployed.

Date: 22 Nov 2026 · Snapshot of files before G5: `design/nav/.snapshot/g5/`

## 1. Design (and why)
The app writes a notification **in the same batch/transaction as the action** (message, proposal, contract step, review). The rules already require a real link between sender and recipient. Moving notification creation entirely to the server would have meant re-implementing about a dozen event types, including the 13-step contract state machine, as triggers. That would also break the installed v1.1.0 app, whose batches include the notification write.

Instead, a **trusted trigger** does what the rules can't:
1. **Re-checks the link** against the current records: chat members, contract parties, the job's client and an applicant or the hired worker; for a message, the message exists and was sent by the other member. If it fails, the notification is **deleted**.
2. **Rewrites the title and body** from server templates and real data (sender's name from their account, job title, the actual message text or "📷 Photo"). A modified app can't put its own words, links or "system" messages in anyone's notification centre or on their lock screen. Unknown types get neutral server text.
3. **Sends the push** to every registered device, respecting the recipient's settings (push off, or messages/work off), and removes tokens FCM reports as dead.
4. **Idempotent:** a retried event sees `verifiedAt`/`pushedAt` and stops. Logs hold ids and codes, never text or tokens.

## 2. Server (`functions/`)
| File | What |
|---|---|
| `src/notify.ts` | `onNotificationCreatedV2` (gen 2, no retry, max 10 instances): checks the link, rewrites, pushes. FCM: high priority, Android channel `high_importance_channel` (same as the app), chat pushes grouped per conversation; APNs sound/thread. **In the emulator no push is sent.** |
| `src/profileCopies.ts` | `refreshProfileCopies`: when someone's **photo or name** changes, the copies on open jobs, live proposals, active contracts and their chats (`participantPhotos/Names`) are updated in batches of ≤ 400. Finished records keep their history. This finishes the "new photo shows everywhere" part of G4. |
| `src/index.ts` | Exports **only** maps (G3), notify and profileCopies. |
| **Removed** | The pre-free-plan functions `auth.ts`, `chats.ts`, `contracts.ts`, `notifications.ts`, `profiles.ts`, `proposals.ts`, `reviews.ts`, their tests, and `scripts/backfill-mirrors.js`. **None were ever deployed.** The app does their work in transactions checked by the rules, so deploying them would have double-counted unread messages, proposal counts and ratings. The old callables (`contractActionCall`, …) were also an alternative path around the rules' contract state machine. Everything is in git and the snapshot. |
| `package.json` | **Runtime moved from Node.js 20 to Node.js 22.** The Firebase CLI's own table lists Node 20 as **decommissioned on 31 Oct 2026**, so a deploy with Node 20 would have failed. |

## 3. Rules (`firestore.rules`)
- `notifications`: the recipient may **only** change `isRead`/`readAt` (before: any field of their own notification). Sender can't read or edit it after sending. Clients can't set `verifiedAt`/`pushedAt` (create allow-list). Recipient may delete.
- `fcmTokens/{uid}`: owner/staff only; shape `{tokens: map ≤ 10, updatedAt}`.

## 4. App
| Area | Change |
|---|---|
| Push tokens | **Per device** in `fcmTokens/{uid}` (was a single `users.fcmToken` that each new phone overwrote). Up to 10 devices (oldest dropped). A refreshed token replaces the old one, and **sign-out removes this phone's token**, so the next person signing in on it won't get the previous account's pushes. The token is no longer written to logs. |
| Background / terminated | A registered background handler; taps from background (`onMessageOpenedApp`) and from a closed app (`getInitialMessage`) open the right screen. Foreground pushes show as a local notification on the same channel. Web: no push (in-app list only). |
| Tap destinations | message → chat · contract step → contract · new proposal → the job's proposals · other job update → the job. Ids are validated; the opened screen still checks access. |
| Notification centre | Latest 100, newest first (server-sorted, existing index); **Mark all as read**; **swipe to delete**; error state with **Try again**; icons for the new types; mark-read sets `readAt`. Removed the unused helper that let the app create arbitrary notifications. |
| Removed | Unused `pushNotificationServiceProvider`. If anything had ever read it, it would have started a second set of listeners and shown every push twice. |

## 5. Tests run
| Check | Result |
|---|---|
| Functions unit tests | **24 / 24** (maps 12 + notify/profileCopies 12). Notify: message text rebuilt, photo message, forged sender deleted, 7 kinds of missing links deleted, contract wording, unknown type, proposal wording, push settings, idempotency, dead tokens removed (map and old field), no devices. Profile copies: change detection, open vs finished records, chat maps. |
| Rules (emulators) | **168 / 168**: new tests for read-only notifications (client can't claim verified/pushed, recipient can't rewrite, sender can't read/edit, recipient can delete) and the token document (own only, ≤ 10, no extra fields, signed-out denied). |
| **End to end on emulators** (Firestore + Functions, demo project) | A notification written with the app's own wording ("FREE PRIZE / click evil.example") → rewritten to **"Ayesha Khan" / "See you at 5"**, push step reached (not sent in the emulator). A notification to someone not in the chat → **deleted**. Photo changed → the chat's `participantPhotos` **updated**. |
| Flutter | **457 / 457** (new: notification routes, token pruning, notification centre: empty state, mark all read, swipe delete, error retry). `dart analyze`: 0 errors. |

**Not verified:** a real push on a phone. That needs Blaze, the functions deployed, and the release app installed. The setup guide has the exact checks for foreground, background and closed app.

## 6. Deploy order (account owner, with Blaze)
1. `firebase deploy --only functions` is **now safe**: the folder contains only the five new functions.
2. Then `firebase deploy --only firestore:rules,storage`.
3. Then release the new app version. Old v1.1.0 installs keep working: their notification writes still pass the rules and get rewritten. They just don't register per-device tokens until updated.
