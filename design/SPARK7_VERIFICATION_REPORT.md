# SkillBridge — Free plan, Phase S7: full verification

Status: **verified locally. Nothing deployed, committed or pushed.** Two bugs and two UI issues were found and fixed in this phase (§2). Awaiting your approval for Phase S8 (release). §5 is the release checklist.

## 1. Summary

| Check | Result |
|---|---|
| Sweep for leftover server use | **None.** The app has no Cloud Functions calls and no Firebase Storage use. Two unused provider definitions remain, harmless. The old job-step methods that bypassed contracts have no callers. |
| Real app code vs final rules (3 probe apps, fresh emulator each) | **54 / 54**: S2–S4 28/28 (after the §2 fix), S5 14/14, S6 12/12 |
| **UI walkthrough of the real app**, client and worker side by side on the emulator | **Passed** end to end (§3) |
| Full regression | **All green**: rules 164/164, functions 54/54, app 504/504, analyzer no new issues, APK and web builds pass |

## 2. Problems found and fixed
1. **Booking a worker directly failed** ("permission denied"). The booking's notification was stamped with the phone's clock, and since S5 the notification rule requires server time. The other probes didn't catch it, because only the booking used device time. **Fix:** server time in `createDirectContract`. The rules suite now also has a test that refuses a notification with device time. Re-run: 28 / 28.
2. **A camera badge on the profile photo with uploads off.** Tapping it did nothing, so it was a control that didn't work. Now the avatar is plain when the image host isn't configured.
3. **Empty photo areas with uploads off.** The worker's "Work photos" now says "Photo uploads aren't available yet." instead of showing an empty grid. The job form hides its Photos section unless uploads are on or the job already has photos.

The "1,000 expressions" messages seen while debugging #1 came from the rules engine trying every other branch after the real failure, not from the limit itself. The final rules pass everywhere. As noted in S6, the contract step is close to that limit, so future additions should go in separate documents.

## 3. UI walkthrough (real app, real rules, emulator; screenshots in `design/spark/s7/screens/`)

| Step | Seen |
|---|---|
| Both sign in | Each app **created its own public profile** on sign-in, with no private fields. |
| Worker browses jobs, opens the job | The client's public profile is shown ("Member since Nov 2026"). |
| Worker sends a proposal (real form) | "Proposal sent". The client's job card shows **"1 proposal"** (S3 count). |
| Worker taps "Message client", sends a message | The chat was created by the app (S5). The client's list shows the preview, **unread 1** and a badge, live. The client opens it and replies; both see **"Seen"**. |
| Client reviews and **accepts and hires** | "Proposal accepted. Contract created." (S4 transaction). The worker's open chat gains the contract shortcut, live. The proposal card shows the worker's public details. |
| Worker posts a progress update, **starts**, **submits** | Each step works; the client's screen moves to "In progress", then "Awaiting review" ("rounds left: 3"), live. |
| Client **confirms** | "Completed" on both sides, live. |
| Client **reviews** (4 stars) | "Review submitted successfully". **Ledger: 1 review, average 4.** The worker's running app copied it onto their account and public profile: **rating 4, 1 review, 1 completed job.** |
| In-app notifications | Every one landed with the right person. Client: proposal, message, progress update, work started, work submitted. Worker: message, contract created, completion confirmed, review received. |
| Uploads off (default build) | Plain avatar with no camera badge; "Photo uploads aren't available yet." (after the §2 fixes). |

Not driven in the UI: photo picking (the browser harness can't operate the system file dialog; the S6 probe covered photos with the real code), live location and navigation (Navigation Phase 10, unchanged by S2–S6), and the admin tools.

## 4. Regression
| Check | Result |
|---|---|
| Rules tests (emulator) | **164 / 164 passed**, including the new device-time notification check |
| Function tests (kept, unused on the free plan) | **54 / 54 passed** |
| `flutter test` | **504 / 504 passed** |
| `dart analyze lib test` | 0 errors, 5 warnings, 28 infos: **no new issues** |
| `flutter build apk --debug` | **passed** |
| `flutter build web --release` | **passed** |

## 5. Release checklist for S8 (nothing done yet; each needs your go-ahead)

**A. Before deploying the rules: production data (Admin SDK scripts run on this PC; no Blaze needed)**
1. **Admins:**
   - **Why it matters:** the new rules recognise staff by a **sign-in claim** (`role: admin`), not by the `role` field on the account (the old rules used the field).
   - **What to do:** give each real admin account the claim with `functions/scripts` (the existing create-admin tooling), or they'll lose admin access when the rules change.
   - **Also check:** the S1 question of whether anyone set `role: admin` on themselves while the hole was open.
2. **Backfills (optional; I'll prepare scripts for your approval):**
   - **Public profiles:** for accounts that won't open the new app soon. The app creates them on sign-in anyway, but until then those people are invisible to others.
   - **Proposal counts:** a recount, because existing jobs show 0.
   - **Rating ledgers:** from any existing reviews.

**B. Deploy (free plan)**
1. **Deploy:** `firebase deploy --only firestore:rules,firestore:indexes`. Allowed on Spark, and no Functions or Storage involved.
2. **Same day, publish the new app version on GitHub.** The new rules don't fit v1.0.0: its contracts, chats and reviews would fail. **Mark v1.0.0 as superseded.**

**C. The app release**
1. **Version:** bump to 1.1.0 (pubspec), build the release APK, and publish GitHub release v1.1.0.
2. **Google Play (if you want it):**
   - **Upload key:** still undecided. Should I create it on this PC, or will you provide your own?
   - **Play Console account:** US$25.
   - **Privacy policy URL:** I can draft it; GitHub Pages hosts it free.
   - **Store listing:** a signed `.aab`, the data-safety answers, and the foreground-location declaration.
   - **App Check:** keep enforcement **off** while APKs are also distributed outside Play.
3. **Optional:** add the Cloudinary settings to turn on public photos.

**D. The admin web (`super_admin_web`)**
Its server routes use the Admin SDK. Firebase's framework hosting runs those on Cloud Functions, which needs Blaze. Options: run it locally with a service account, or host it on a free Next.js host (e.g. Vercel) with the service-account key kept as a server secret. This is your choice; I won't do it without your go-ahead.

## 6. Files changed in S7
- `lib/features/contracts/data/datasources/contract_remote_datasource.dart`: booking notification uses server time.
- `lib/shared/widgets/profile/profile_media_widgets.dart`: plain avatar and a "not available" note when uploads are off.
- `lib/features/jobs/presentation/screens/post_job_screen.dart` (CRLF kept): Photos section hidden when uploads are off.
- `rules-tests/rules.test.js`: +1 assertion (notification at device time refused).
- New: this report and `design/spark/s7/screens/` (8 screenshots).
- Outside the repo: the walkthrough seed `scratchpad/e2e/s7uiseed.py` and the rebuilt probes.
