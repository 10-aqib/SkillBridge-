# SkillBridge — Track G, Phase G6: account deletion, saved jobs, settings

Status: **code done and tested locally; NOT deployed.** Part of the approved overnight run. Nothing committed or deployed.

Date: 22 Nov 2026

## 1. Account deletion (Google Play requires it)
| Piece | What |
|---|---|
| `functions/src/account.ts`, callable `deleteAccount` | Only for yourself, and only **within 10 minutes of signing in** (an unattended phone can't delete the account). **Refused while a contract is active**, so the other party is never left mid-job. Deletes your own data: account + private/verification/saved-jobs subcollections, public profile, notifications, push tokens, live location, rating ledger, maps usage counter, **Storage folder `users/{uid}/`**, and finally the **sign-in**. Keeps other people's history but **anonymises** you as "Deleted user" (no photo) on jobs, proposals, contracts, reviews and chats. Open jobs are cancelled (`closedReason: account_deleted`), pending proposals withdrawn. If something fails midway, the sign-in is still there, so you can retry. |
| App | Settings → **Delete account** → a clear explanation sheet → progress → on success, signed out and back at Welcome. Every refusal is explained: sign in again (with a button), active contracts, not available yet (function not deployed), offline, failed. |

## 2. Saved jobs
- `users/{uid}/savedJobs/{jobId}`: owner only. Rules allow only a small snapshot (title, city, budget, `savedAt` at server time), require the id to match a **job that exists**, and refuse extra fields.
- **Bookmark** button on the job page (workers, not the job's owner) and a **Saved jobs** screen (`/worker/saved-jobs`, opened from the job feed's app bar): newest first, tap opens the job as it is now, remove with one tap, plus empty/loading/error states. Kept across sessions and devices.

## 3. Settings
- **Notifications:** Push on/off; New messages; Jobs, proposals and contracts. Stored as `users/{uid}.notificationPrefs` (rules: only these three, true/false). Read by the G5 push function; the in-app list always works.
- **Change password** (email accounts only): emails a reset link.
- **Delete account** (above). Sign out unchanged.

## 4. Tests run
| Check | Result |
|---|---|
| Functions | **27 / 27** (3 new: recent sign-in required; refused with an active contract and nothing touched; full deletion: own data gone, others' data kept, shared history anonymised, open work closed, Storage then sign-in last). |
| Rules (emulators) | **171 / 171** (new: saved jobs own-only / real job / id match / snapshot fields / server time; notification switches bool-only, known keys, own only). |
| Flutter | **469 / 469**. New: settings switches save all three and disable when push is off; no password change without a password account; delete-account cancel/confirm/sign-out/Welcome; three refusal messages; sign-in-again path; error-code mapping; no-Firebase fallback; saved jobs empty/list/remove/open; snapshot parsing. |
| `dart analyze` | 0 errors. |

**Not verified:** deleting a real account (needs the deployed function). Strings are English + Urdu.
