# Phase 2B: Acceptance Audit

**Date:** 9 November 2026 · **Branch:** `ui-improvements-2026`

**Status:** audit complete. Phase 2B now works end to end, after 7 bugs found and fixed during this audit. Nothing is committed, pushed or deployed, no keys were rotated, and Phase 3 has not started.

## Summary

| Check | Result |
|---|---|
| Flutter tests | **154 / 154 pass** (147 before the audit + 7 regression tests added) |
| Analyzer | **0 errors**, 10 warnings, 42 info (52 total). Phase 2A ended at 65 (0 / 16 / 49). **No new issues; 13 resolved.** |
| Firestore/Storage rules (emulator) | **28 / 28 pass** |
| Role-claim function tests | **4 / 4 pass** |
| Web release build | **Pass** (final code) |
| Android debug APK | **Pass** (final code) |
| Live auth and profile flows | Run in the **real web app against local Firebase emulators**. All Phase 2B flows pass after the fixes (§4). |
| Admin claims | No user-controlled Firestore field can grant admin rights (§6). Two hardening notes. |
| Screenshots | 54 real captures, light and dark, plus 4 contact sheets (§7) |

### Production contact during testing

While setting up the live test harness, a page reload in the test browser made the app's Firebase **Auth** SDK talk to the **production** project instead of the emulator. Before I noticed, three requests reached production:
- one `accounts:lookup`, using an emulator-issued token;
- two `accounts:signInWithPassword` for the fake address `client.audit@skillbridge.test`. One used a deliberately wrong password; the other used an emulator-only test password.

**Both sign-ins failed, because no such account exists in production.** No account was created and no data was read or written in production. Firestore and Storage stayed on the emulator throughout.

I then relaunched the test browser with the production Auth, Firestore and Storage hostnames blocked at DNS level, and confirmed they were unreachable. I discarded the one screenshot taken from that attempt. No action is needed beyond noting the three failed attempts if they appear in Auth usage.

## 1. What "tested" means here

| Kind | What it covers | Count |
|---|---|---|
| Mocked Flutter tests | Screen logic, validation, navigation and stored data shapes. Fake repositories, no network. | 154 |
| Emulator rules tests | The real `firestore.rules` and `storage.rules` in the Firebase emulators | 28 |
| Function unit tests | `nextRoleClaim()` decisions | 4 |
| **Live run (new)** | The **real release web app**, built from a separate entrypoint that only points Firebase at local Auth, Firestore and Storage emulators running the real rules. Driven like a user in headless Chrome at 412 × 915. | §4 |

The emulator entrypoint and harness live in the session scratchpad, not the repo. Test accounts are emulator-only. The uploaded images are labelled `TEST` / `SAMPLE ONLY – NOT A REAL CNIC`, and the CNIC used was `00000-0000000-0`.

## 2. Bugs found and fixed in this audit

| # | Bug | Effect | Fix | Regression test |
|---|---|---|---|---|
| 1 | Upload file names used `Random().nextInt(1 << 32)`. On the web `1 << 32` is 0, so it threw. | **Every web upload failed** (profile photo, portfolio, verification) with "Upload failed". Android was unaffected. | `ProfileMediaService.uniqueSuffix()` uses a range that's valid everywhere. | `media_upload_name_test.dart`; confirmed live |
| 2 | Verification uploads listened to `snapshotEvents` for progress. On the web the upload then never completed. | **Identity verification couldn't be submitted on web**: stuck at "Uploading… 100%". | Progress is read from the task's latest snapshot on a 200 ms timer. | Confirmed live (the Flutter web test runner hangs on this machine) |
| 3 | `routerProvider` watched the auth stream, which re-emits on every profile save, so a new `GoRouter` was built each time. *(Pre-existing.)* | Every save reset navigation: Edit profile → Save landed on Home, and "I've verified" jumped to Home. | Router built once. Redirects re-run (via `refreshListenable`) only when something they depend on changes, using `authRedirectKey`. Re-running on every save duplicated pushed pages, so it's limited to these changes. | `router_stability_test.dart` (4); confirmed live |
| 4 | Email card: after "not verified yet", a successful resend kept showing "Not verified yet". | No confirmation that the email was sent. | A send now clears the earlier result. | `profile_flows_test.dart` (+1) |
| 5 | The sign-in view model's error stayed after leaving the screen. | "Email or password is incorrect" appeared on **Create account**. | Sign-in and sign-up clear old errors when opened. | `auth_screens_test.dart` (+1); confirmed live |
| 6 | Worker profile availability control | "Available" wrapped to "Availabl / e" on phones | Icons shown only when there's room (≥ 420 px) | Confirmed live (light and dark) |
| 7 | Public profile action bar used fixed shares | "Message" was cut to "Mess…" on phones | Message takes its natural width; booking takes the rest | `worker_profile_responsive_test.dart` (truncation check) |

**Files changed in this audit:**
- `lib/core/services/profile_media_service.dart`
- `lib/config/router/app_router.dart`
- `lib/config/router/auth_redirect.dart`
- `lib/features/auth/presentation/viewmodels/auth_viewmodels.dart`
- `lib/features/auth/presentation/screens/login_screen.dart`
- `lib/features/auth/presentation/screens/signup_screen.dart`
- `lib/features/worker/presentation/screens/worker_profile_screen.dart`
- `lib/features/client/presentation/screens/worker_profile_detail_screen.dart`
- Tests: new `test/unit/media_upload_name_test.dart` and `test/unit/router_stability_test.dart`; additions to `test/widget/profile_flows_test.dart`, `auth_screens_test.dart` and `worker_profile_responsive_test.dart`
- Screenshots in `design/phase2b/acceptance/`

Every edited file keeps its original per-line endings (checked against the pre-phase snapshot).

## 3. Analyzer vs Phase 2A

| | Errors | Warnings | Info | Total |
|---|---|---|---|---|
| Before Phase 2A | 0 | 19 | 49 | 68 |
| End of Phase 2A | 0 | 16 | 49 | 65 |
| **Now** | **0** | **10** | **42** | **52** |

There are no new issues by (severity, rule, file). Resolved since Phase 2A:
- unused imports and elements in `login_screen.dart` and both settings screens;
- 3 deprecations in `main.dart` and 1 in `client_profile_screen.dart`;
- 2 const suggestions;
- 1 underscore info.

The 10 remaining warnings are all in files outside Phase 2B's scope:
- unused imports in `app.dart`, `language_provider.dart`, `worker_profile_provider.dart` and `proposal_remote_datasource.dart`;
- unnecessary `!` in `nearby_workers_screen.dart` (×2) and `worker_earnings_chart.dart`;
- unused elements in `home_drawer.dart` and `booking_payment_sheet.dart`;
- one in the root `script.dart`.

## 4. Live workflow verification (real app + emulators)

| Workflow | Result | Evidence |
|---|---|---|
| Email/password sign-up (client) | Pass | Profile created under the real rules: role `client`, rating 0, no CNIC, `onboardingCompleted: false`, `authProvider: password`. Verification email queued. |
| Sign-up validation | Pass | Required fields, phone format, password match and terms agreement all checked |
| Wrong password | Pass | Localized "Email or password is incorrect"; both buttons locked while signing in (duplicate-submit guard) |
| Sign in | Pass | Unfinished client → onboarding; finished client → home |
| Client onboarding (photo, phone, city, area) | Pass | Stored exactly what was entered; `onboardingCompleted: true` |
| Profile photo upload | Pass (after fix 1) | Stored at `users/<uid>/profile/…`, `photoUrl` saved, image shown |
| Email verification | Pass (after fix 4) | "Not verified yet" → resend (second email queued) → emulator link opened → "I've verified" → badge shown, `isEmailVerified: true` |
| Edit client profile | Pass (after fix 3) | Saved, returned to Profile with "Profile saved" |
| Sign out | Pass | Confirmation sheet; Cancel keeps the session; Sign out → Welcome, no stored session |
| Password reset | Pass | Emulator recorded `PASSWORD_RESET`; "Check your email" screen with resend cooldown |
| Google sign-in, new account | Pass | Emulator's Google provider page → role selection. **No profile is created until a role is chosen.** |
| Role selection → worker | Pass | Profile created with role `worker`, provider `google`, no CNIC. Opens worker setup. |
| Google sign-in, existing account | Pass | Straight to worker home |
| Google sign-in timeout | Pass | Localized "This is taking too long" |
| Worker setup, 5 steps | Pass (after fix 3) | Each step saved and moved on without restarting. Skills, custom skill, languages, rate and city stored. `isVerified: false`, rating 0, reviews 0, no CNIC. |
| Portfolio upload and removal | Pass (after fix 1) | Two uploads stored and listed. Removal asks first and deletes from the profile **and** Storage. |
| Section edit (Rates & area) | Pass | Saved and returned. Verification, ratings and earnings untouched. |
| Availability toggle | Pass | Saved `busy` / `available` |
| Identity verification | Pass (after fix 2) | Validation for CNIC, both documents and consent. Live progress. Submitted: private doc `status: pending` with the CNIC and 2 **storage paths** (no URLs). Public profile has no CNIC, `isVerified: false`, `verificationStatus: pending`. Screen shows only `00000-•••••••-0`. |
| Private data access over HTTP | Pass | Verification image: **403** signed out, **403** as another user. Private Firestore doc: **403** as another user. Public profile photo: 200. |
| Public profile, own preview | Pass | "This is how clients see your profile". No booking or report actions. "New / No reviews yet". |
| Public profile, client view | Pass (after fix 7) | Message, Request booking and Report (localized reasons; dismissed without filing) |
| Dark / light switching | Pass | Settings → Appearance, applied instantly |

**Not run live:**
- **Phone OTP**: needs reCAPTCHA or SMS; covered by widget tests only.
- **Real Google accounts**: the emulator's provider page was used.
- **Completing a password reset**: that happens on Firebase's hosted page.
- **"Set on map"**: uses the Google Maps API.
- **Android device runs**: only the APK build was checked.

## 5. Navigation wiring (every Phase 2B screen is reachable)

| Screen | Route | Reached from |
|---|---|---|
| Welcome | `/welcome` | Splash, sign-out, redirect when signed out |
| Sign in | `/login` | Welcome, Sign-up, Forgot password |
| Create account | `/signup?role=` | Welcome, Sign in |
| Forgot password | `/forgot-password` | Sign in |
| Role selection | `/role-selection` | Redirect when no role is set; Google sign-in for a new account |
| OTP | `/otp` | Client profile → mobile "Verify" (**no worker entry point yet**) |
| Client onboarding | `/client/onboarding` | Redirect for new clients |
| Client profile | `/client/profile` | Bottom navigation |
| Edit client profile | `/client/profile/edit` | Client profile → Edit |
| Client / worker settings | `/client/settings`, `/worker/settings` | Profile gear icon; client home drawer |
| Worker setup (5 steps / single section) | `/worker/profile/setup[?step=n]` | Redirect for incomplete workers; worker profile section Edit links |
| Worker profile | `/worker/profile` | Bottom navigation |
| Identity verification | `/worker/verification` | Worker profile, setup step 5, completeness card |
| Public worker profile | `/worker-profile/:id` | Client home, nearby workers, worker profile (eye icon) |

## 6. Admin custom-claim audit

**No user-controlled Firestore field can grant admin privileges:**
- Firestore and Storage rules use only `request.auth.token.role` (`admin` / `SUPER_ADMIN`) for staff rights.
- Users can create profiles only with role `''`, `client` or `worker`, choose once, and never change it afterwards (emulator-tested).
- `onUserCreated` sets a default `client` claim only when none exists. `syncUserRoleClaim` mirrors only `client`/`worker` and never grants, replaces or removes staff claims; a forged Firestore `admin` is ignored (unit-tested).
- Staff claims come only from server code holding credentials: `super_admin_web/create-admin.js` (service account) and the `/api/setup-admin` route, which is protected by a timing-safe `SETUP_SECRET` comparison.
- The admin web session requires a staff claim in a verified ID token.

**Hardening notes (no change made):**
1. `/api/setup-admin` grants `SUPER_ADMIN` to **any email** if `SETUP_SECRET` is known. Unset the secret (or remove the route) in production once the first admin exists.
2. The admin web also accepts a lowercase `super_admin` claim, which the rules and `STAFF_ROLES` don't recognise. Such an account would have no rules-level staff rights. If its Firestore role were ever `client`/`worker`, the sync could replace that claim (a demotion, not an escalation). Standardise on `admin` / `SUPER_ADMIN`.
3. The mobile app's admin screens are routed by the Firestore `role == 'admin'`. The rules prevent self-assignment, and every admin data read is gated by the claim, but the router should move to the claim in the admin phase.

## 7. Screenshots

Folder: `design/phase2b/acceptance/`. All are captures of the real release web app at 412 × 915, in light and dark. Signed-in screens are from the emulator-connected build; the emulator notice was hidden for clarity.

**Contact sheets** (light on top, dark below):
- `sheet-auth.png`: welcome, sign-in, sign-in error, sign-up, reset, reset sent, role selection (and chosen state)
- `sheet-onboarding.png`: client onboarding steps 1–3 and worker setup steps 1–5
- `sheet-profiles.png`: client profile, after save, edit, worker profile, section edit, public preview, client view, report sheet
- `sheet-verification-settings.png`: verification errors, ready, form, pending, settings, sign-out confirmation

**Single-theme only:**
- light only: `client-profile-saved`, `forgot-password-sent`, `verification-errors`, `verification-ready`, and `worker-home-existing` (the pre-Phase 3 home);
- dark only: `role-selection-chosen`, `worker-edit-work`, `report-sheet`.

The light `client-profile` shot shows "Gulberg III, Lahore, Lahore" because I typed the city into the area field (see issue 13).

## 8. Outstanding issues

**Blocking for release:**
1. **Rules and functions not deployed.** Production still runs the old rules, which allow public CNIC writes and self-chosen roles.
2. **No admin review UI** for verification submissions. Requirements:
   - read `users/{uid}/private/verification` and the Storage paths, as staff;
   - set `status` and `workerProfile.verificationStatus`;
   - set `workerProfile.isVerified` (true on approval);
   - use short-lived signed URLs only.

**Should fix (outside Phase 2B, or minor):**
3. The client home drawer signs out **without confirmation** and has hard-coded English labels (Phase 3 home).
4. The worker home shows **made-up trend labels** ("+0.2 this month", "+2 this month") for a brand-new worker (Phase 3).
5. Re-opening worker setup starts at step 1 (data prefilled) rather than the first unfinished step.
6. Verification uploads abandoned by leaving the screen stay in the owner's private folder, unreferenced (one from testing). Replaced uploads are cleaned up.
7. A worker's exact map location stays public (existing data shape; Phase 3).
8. Old public CNICs remain until each owner removes them.
9. `UserModel.fromMap` defaults a missing rating to 5.0 for old docs (the UI hides it without reviews).
10. Verification accepts images only on mobile and web (`image_picker`); PDF would need a file picker.
11. OTP is reachable only from the client profile; workers have no phone-verify entry point.
12. Cosmetic: the selected category chip draws its icon on a grey circle.
13. Cosmetic: the area hint "e.g. G-11, Islamabad" invites typing the city, which then repeats ("…, Lahore, Lahore").

**Test-harness limits (not app bugs):**
- Reloading the emulator build with a saved session makes Auth use production endpoints; that's what caused the production contact above. Production builds don't use emulators.
- `flutter test --platform chrome` hangs on this machine, so the web-only bugs were confirmed in the live run instead.

## 9. Manual Firebase Console tasks

1. **Deploy** after review: `firebase deploy --only firestore:rules,storage,functions`. Rerun `cd rules-tests && npm test` first.
2. **Authentication:**
   - enable Email/Password and Google;
   - add the web hosting domain to *Authorized domains*;
   - add Android SHA-1/SHA-256 fingerprints for Google sign-in;
   - check the iOS reversed client ID.
3. **Email templates:** sender name and action URL for verification and password-reset emails.
4. **Phone auth:** enable it, set the SMS region policy (Pakistan) and add test numbers.
5. **Storage CORS:** Flutter web (CanvasKit) loads profile and portfolio images with `fetch`, so the production bucket likely needs a CORS policy (`gsutil cors set cors.json gs://skill-bridge-c68c3.firebasestorage.app`). The emulator doesn't enforce this, so check after deploying.
6. **App Check:**
   - register the reCAPTCHA v3 site key, Play Integrity, DeviceCheck/App Attest and debug tokens;
   - monitor before enforcing.
7. **Rotate the Google Maps keys** (still outstanding from Phase 2A.1).
8. **Admin setup:** unset `SETUP_SECRET` / disable `/api/setup-admin` once the first admin exists.
9. **Commit** when ready. Nothing is committed.
