# SkillBridge — Free-plan (no Blaze) release: plan

Status: **plan only, plus one security hotfix already live (§1).** Nothing else is changed. Awaiting your approval to start Phase S2.

## 1. Done now: security hotfix on the live rules (14 Nov 2026)

The live Firestore rules (the old, permissive set) let **any signed-in user give themselves admin**: they could write `role: 'admin'` on their own `users` document, and the rules trust that field.

- **Fix:** people may only pick `client` or `worker` for themselves, and only while their account has no role yet. Only staff can set `admin`. Nothing else in the live rules changed.
- **Tested:** 9 emulator tests passed. Sign-up (email and Google), choosing a role, profile edits, no admin by sign-up or edit, no client↔worker switch, staff still set roles, other rules unchanged.
- **Deployed:** `firestore:rules` only, to `skill-bridge-c68c3`.
- **Record:** `design/spark/LIVE_HOTFIX_2026-11-14.rules` and `live_hotfix.test.js`.
- **Not checked:** whether anyone already used the hole. In the Firebase console, filter `users` by `role == admin`, check each account is yours, and set any others back to `client`/`worker`.
- **Still permissive in the live rules** (fixed properly in S2–S6): anyone signed in can read every user document (phone and email included), edit any contract they're a party to however they like, create any chat, and create notifications for anyone.

## 2. The problem

Without Blaze there are **no Cloud Functions** and, for a project this new, **no Firebase Storage**. The redesigned app relies on both:

| Server piece | What it does today | Free-plan replacement |
|---|---|---|
| `acceptProposalCall`, `directRequestCall`, `contractActionCall` (13 actions) | Contract creation and every contract step | App writes in a **transaction**; the rules check each step (who, from which status to which, which fields, amounts, times) |
| `openChatCall`, `onChatMessageCreated` | Create a chat; last message and unread counts | App creates the chat with a fixed id; each message is sent in one batch with the chat summary; the rules check both |
| `onUserCreated`, `syncUserRoleClaim` | Role as a sign-in claim (rules and admin web use it) | Rules read the role from the protected `users` document (as the hotfix does) |
| `syncUserMirrors` | Public profiles and live-location viewer lists | App writes its own public profile; the rules allow only the public fields and require them to match the private document |
| `syncJobProposalCount`, `syncJobRelations` | Proposal counts and job links | Done in the same transaction as the proposal/contract write; the rules check the count changes by exactly 1 |
| `aggregateReviewRating` | Rating average | Same transaction as the review; the rules check the new average is computed correctly |
| `onNotificationCreated` | Push alerts | **In-app only** (your choice): live list and badge while the app is open. Rules allow notifications only to the other party of a shared job, contract or chat. |
| Firebase Storage | Profile photos, chat attachments, work-evidence photos | **Free external image host** (your choice; plan uses Cloudinary, §4) |

**Security trade-off, stated plainly:** checks in Firestore rules are enforced by Google's servers, so a modified app can't bypass them. Almost every check the functions did can be expressed in rules. Two things weaken:
- A notification's wording comes from the sender's app. The rules still limit who can be notified, the allowed types, and the length.
- Uploaded images are public on the image host to anyone who has the link.

Where the rules can't cover a check, I'll say so in that phase's report.

## 3. Phases (each ends with a report and a stop for approval, as before)

| Phase | Work |
|---|---|
| **S2 Identity and profiles** | Role from the `users` document instead of claims (rules, app, admin web). Public profiles written by the owner. Private fields (phone, email, CNIC, addresses) stay private. |
| **S3 Jobs and proposals** | Proposal counts and job relations in transactions, with rules. |
| **S4 Contracts** | Accept proposal, direct request, and all 13 contract actions (start, submit, confirm, revisions, cancel, address pin, progress updates…) as transactions with a rules state machine. Includes live location. |
| **S5 Chats, reviews, notifications** | Chat creation and messages; rating average; in-app notifications. FCM push code switched off cleanly. |
| **S6 Images** | Upload to the image host (§4); the app stores only the returned link. Old Storage code paths switched off. |
| **S7 Verification** | Full rules tests (rewritten for the new model), app tests, a two-user emulator run of every flow, analyzer, builds. |
| **S8 Release** | Deploy the new rules and indexes (allowed on the free plan) **together with** a new app version, because the new rules only fit the new app. Publish **v1.1.0** on GitHub (replacing v1.0.0, which needs functions). Prepare the Play Store bundle (§5). |

Rough size: the functions are 1,342 lines of TypeScript, and their logic moves into the app and the rules. Expect S4 to be the largest phase.

## 4. Image host: what you need to set up (when we reach S6)
1. Create a free **Cloudinary** account yourself (I can't create accounts).
2. Settings → Upload → add an **unsigned upload preset** that is limited to: images only (jpg, png, webp), max 2 MB, folder `skillbridge/`, and a size cap on incoming images.
3. Send me the **cloud name** and the **preset name**. Neither is a secret. The API secret must **never** go into the app.

Limits to know:
- Anyone holding the preset name can upload images into that folder (abuse is capped by the preset limits).
- The app can't delete uploads; deleting needs the secret, so it's done from the Cloudinary dashboard.
- Image links are public.

## 5. Play Store: what's needed (S8)
- **Your own upload key.** Your answer about the key was blank, so this is still open. Either I create one on this PC (you must back it up; lose it and you can't update the app), or you give me an existing one.
- **Play Console developer account.** A one-time payment of US$25 in your name. If your card fails there too, Play isn't possible yet; GitHub releases still work.
- **App bundle (.aab).** Built and signed with the upload key; version numbers increase with each release.
- **Privacy policy URL.** Required, because the app uses location, contacts info and accounts. I can draft the text; it has to be hosted at a public URL (GitHub Pages works for free).
- **Data safety form and location permission declaration.** Foreground location only. I'll prepare the answers.
- **App Check.** The Android release uses Play Integrity, which works fully only for apps installed from Play. Leave App Check enforcement **off** in the Firebase console while the GitHub APK is in use.

## 6. What happens to GitHub release v1.0.0
It works for sign-in, profiles, jobs and browsing. It needs the missing functions for proposals, contracts, chats and reviews. After S8, v1.1.0 replaces it, and I'll mark v1.0.0 as superseded.
