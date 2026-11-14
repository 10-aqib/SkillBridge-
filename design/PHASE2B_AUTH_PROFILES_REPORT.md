# Phase 2B — Authentication & Profiles: Report

> **Superseded in part by [PHASE2B_ACCEPTANCE_REPORT.md](PHASE2B_ACCEPTANCE_REPORT.md)** (9 Nov 2026): the acceptance audit ran the app live against Firebase emulators, fixed 7 more bugs, and has the current test counts.

**Date:** 8 November 2026 · **Branch:** `ui-improvements-2026` · **Status:** complete, awaiting approval. Nothing is committed or deployed: no rules, no functions, no credentials rotated. Phase 3 has not been started.

## Summary

| Area | Status |
|---|---|
| Auth flows (email, Google, role choice, login/logout, reset, email verification, OTP) | Redesigned and tested. Two bugs fixed (§3). |
| Profiles (client onboarding, client edit/profile, worker setup, worker own profile, public worker profile, settings) | Rebuilt on the Phase 1 design system, light and dark, en/ur. |
| Identity verification | New private workflow: owner/staff-only Storage folder and `users/{uid}/private/verification`. Nothing public, nothing auto-approved. |
| Security rules + role-claim function | Fixed in the repo and tested against the emulator (28 tests). **Not deployed.** |
| Tests | 147 Flutter tests, 28 emulator rules tests and 4 functions tests pass. The analyzer has 0 errors. |
| Builds | Web release and Android debug: see §7. |

## 1. Previous work vs this session

**Earlier Phase 2B session (recovered, not redone):**
- Auth data layer: role validation, `needs-role` flow, email verification, profile completion.
- Redesigned auth screens: Welcome, Login, Signup, Role selection, Forgot password, Splash, OTP.
- Shared auth widgets.
- Rule and function changes you approved: "Approve rule edits", "Fix in repo".

**This session:**
- **Recovery:** git state and snapshots inspected. Line endings were restored per line on the 5 rewritten auth screens. No code was reverted, nothing was committed, and no destructive git command was used.
- **Security verification (8 points):** see §2.
- **Auth testing:** found and fixed the forgot-password resend bug and the router-guard bug (§3). Auth test files rewritten for the new screens and wording.
- **Profiles:**
  - New screens: client onboarding, edit client profile, client profile, settings with a sign-out confirmation.
  - Rewritten: worker setup (5 steps), worker own profile, public worker profile.
  - Integrated the profile photo picker, portfolio manager and email-verification card.
- **Verification workflow:** screen, service, private storage, and the matching rules and tests.
- **Fixes found by the new tests:**
  - Settings list ripples were invisible.
  - Choosing the "System" theme reverted to Light after a restart.
- **Final testing:** see §4–§7.

## 2. Security and backend verification

| # | Requirement | Result |
|---|---|---|
| 1 | Users can't self-assign admin | **Enforced.** Create allows role `''`, `client` or `worker` only. Tested. |
| 2 | Initial client/worker choice allowed only once | **Enforced.** `roleChangeAllowed()`: a role may move from `''` to client/worker once. Tested, including legacy `''` profiles. |
| 3 | Existing roles can't change | **Enforced.** Tested: a client can't switch to worker or admin. |
| 4 | Admin claims only from trusted server code | **Yes.** The function never writes staff claims, and staff rights come from the custom claim, not Firestore. |
| 5 | `syncUserRoleClaim` doesn't trust an unverified Firestore role | **Fixed (repo).** `nextRoleClaim()` mirrors only `client`/`worker` and never replaces or removes a staff claim. A forged `admin` in Firestore is ignored. 4 unit tests. |
| 6 | Verification docs readable by owner/staff only | **Enforced** in Firestore (`private/verification`) and Storage (`verificationDocuments/`). Tested. |
| 7 | CNIC only in the private doc | **Fixed.** The public profile can't gain or change `cnicNumber`. A legacy value can be kept or removed by its owner. Tested. |
| 8 | Storage wildcard doesn't expose verification docs | **Fixed.** The `{folder}` wildcard excludes `verificationDocuments`. Tested: not publicly readable. |

Private verification entries are also checked:
- keys are restricted;
- the status must be `pending`;
- the CNIC must match `^\d{5}-\d{7}-\d$`;
- 1–3 documents, each a file in the owner's own folder.

Rule and function files: `firestore.rules`, `storage.rules`, `functions/src/auth.ts` (also `onUserCreated`, which no longer writes Firestore and sets a default `client` claim only when none exists).

## 3. Auth test results

All of these use **mocked** Firebase (fake repositories, mocktail). They test app logic and UI, not live Firebase.

| Flow | Covered by | Result |
|---|---|---|
| Email registration (client/worker), validation, verification email sent | `auth_flow_test`, `auth_screens_test` | Pass |
| Google sign-in: new user → role choice; existing account without profile → role choice; existing profile → home | `auth_flow_test`, `google_auth_login_screen_test` | Pass |
| Role selection (once, client/worker only, no admin) | `auth_screens_test`, `auth_flow_test` | Pass |
| Login / logout, localized errors, duplicate-submit guard | `google_auth_login_screen_test`, `auth_flow_test` | Pass |
| Password reset, including resend | `auth_screens_test` | Pass, **after fix**: resend didn't send because the cleared form failed validation. |
| Email verification card (resend once, "still pending" check) | `profile_flows_test` | Pass |
| OTP send / verify / resend cooldown | `auth_screens_test` | Pass |
| Navigation guards | `auth_flow_test` (`resolveAuthRedirect`) | Pass, **after fix**: clients were bounced away from `/worker-profile/:id` because of a prefix match. Now matched by path segment. |
| New client → onboarding once | `auth_flow_test` | Pass |

Files: `test/unit/auth_flow_test.dart` (21), `test/widget/auth_screens_test.dart` (18), `test/widget/google_auth_login_screen_test.dart` (14), `test/widget_test.dart` (splash).

## 4. Profile and upload test results (mocked)

| Area | File | Tests |
|---|---|---|
| Worker setup:<br>• 5 steps with per-step saves and validation<br>• honest starting values (`isVerified` false, rating 0, reviews 0)<br>• no CNIC written, no default rate (the old flow saved Rs 1,500)<br>• editing keeps verification, ratings and earnings<br>• failed save stays on the step | `worker_profile_setup_test.dart` | 3 |
| Worker own profile and public profile:<br>• light/dark, 360 px width, no overflow<br>• public preview link<br>• own-profile preview has no booking or report actions<br>• no invented rating or price | `worker_profile_responsive_test.dart` | 7 |
| Client onboarding: finish saves only what was entered; invalid phone blocks; skip; failed save | `profile_flows_test.dart` | 4 |
| Settings sign-out: cancel does nothing; confirm signs out and goes to Welcome | `profile_flows_test.dart` | 2 |
| Email verification card | `profile_flows_test.dart` | 2 |
| Verification screen:<br>• required CNIC, front/back and consent<br>• pending shows only a masked CNIC<br>• "verified" only when staff set it<br>• rejected shows the form again<br>• legacy CNIC removed only after confirmation | `profile_flows_test.dart` | 5 |
| Helpers:<br>• CNIC formatter, pattern and mask<br>• submit rejects bad input before writing<br>• upload content types and 5 MB limit | `profile_flows_test.dart` | 4 |
| ARB parity: same keys, no empty Urdu, matching placeholders (434 keys each) | `arb_parity_test.dart` | 3 |

**Not covered by automated tests:** real uploads to Firebase Storage (image picking needs a device). The upload code path is covered by the Storage rules tests and code review only.

## 5. Emulator results (real Firebase rules)

`rules-tests/` runs the **actual** `firestore.rules` and `storage.rules` in the Firebase emulators (firebase-tools 13.35.1, Java 17). **28 / 28 pass:**
- role assignment (9);
- protected flags (3);
- CNIC never public (3);
- private verification (7);
- Storage (6).

`functions/` role-claim unit tests (`npm test`): **4 / 4 pass.**

## 6. Design quality

- Phase 1 tokens and components throughout: `SbButton`, `SbTextField`, `SbInlineBanner`, `SbStateView`, `showSbConfirmSheet`, `SbReadableWidth`.
- Light and dark both tested.
- Loading, empty and error states for reviews, profile load and verification.
- No dummy data: ratings appear only when reviews exist; rates read "on request" when unset; "Verified" appears only when staff set it. The fake Share button was removed.
- ARB: 434 keys in en and ur, parity enforced by a test. The global locale setup is unchanged.

## 7. Build and analyzer results

| Check | Result |
|---|---|
| `flutter analyze` | **0 errors.** 54 warnings/infos, all in files this phase didn't change (e.g. `nearby_workers_screen.dart`, `worker_earnings_chart.dart`). Files changed this phase: no issues. |
| `flutter test` | **147 / 147 pass** |
| `flutter build web --release --dart-define-from-file=.env` | **Pass**, written to a temporary folder outside the repo. |
| `flutter build apk --debug --dart-define-from-file=.env` | **Pass**, `build/app/outputs/flutter-apk/app-debug.apk`. Only the existing Gradle/Kotlin plugin deprecation notices. |
| Rules / functions tests | 28 / 28 emulator, 4 / 4 functions (§5) |
| Line endings | Every edited file matches its original per-line endings (checked against the pre-phase snapshot). |

## 8. Screenshots

Captured from the **release web build of the real app** at 412 × 915, reached by tapping through the app as a user would. Files are in `design/phase2b/`.

| Screen | Light | Dark |
|---|---|---|
| Welcome | `welcome-light.png` | `welcome-dark.png` |
| Sign in | `login-light.png` | `login-dark.png` |
| Create account (client) | `signup-light.png` | `signup-dark.png` |
| Create account (worker) | `signup-worker-light.png` | `signup-worker-dark.png` |
| Reset password | `forgot-password-light.png` | `forgot-password-dark.png` |

- The yellow "No internet connection" banner is the app's real offline banner. Headless Chrome can't reach Firestore, so it appears in some captures and not others.
- **Not captured:** role selection, OTP, onboarding, profiles, settings and verification. These need a signed-in account, and you chose to skip signed-in shots. They are covered by widget tests in light and dark (§4), not visually.

## 9. Files changed

**Rules / backend:**
- `firestore.rules`, `storage.rules`, `functions/src/auth.ts`, `functions/package.json` (test script), `functions/.gitignore`;
- new: `functions/test/role-claim.test.js`, `rules-tests/` (package.json, firebase.json, rules.test.js, .gitignore).

**Auth:**
- `core/errors/failure.dart`;
- `auth/domain/entities/user_entity.dart`, `user_roles.dart` (new);
- `auth/data/models/user_model.dart`, `auth/data/datasources/auth_remote_datasource.dart`;
- repository, interface, `auth_usecases.dart`, `login_with_google_usecase.dart`, `auth_providers.dart`, `auth_viewmodels.dart`;
- screens: `welcome_screen.dart` (new), `login`, `signup`, `role_selection`, `forgot_password`, `splash`, `otp`;
- `auth/presentation/widgets/` (new).

**Routing:** `config/router/auth_redirect.dart` (new), `app_router.dart`, `route_names.dart`.

**Profiles:**
- `core/services/profile_media_service.dart` (new);
- `shared/widgets/profile/` (new): sections, media widgets, reviews, settings;
- `client_onboarding_screen.dart` (new), `edit_client_profile_screen.dart` (new), `client_profile_screen.dart`, `client_settings_screen.dart`, `worker_settings_screen.dart`;
- `worker_profile_setup_screen.dart`, `worker_profile_screen.dart`, `worker_profile_detail_screen.dart`;
- `core/providers/shared_providers.dart` (one line: "System" theme now persists).

**Verification:** `worker/data/verification_service.dart` (new), `worker/presentation/screens/verification_screen.dart` (new).

**Strings:** `l10n/app_en.arb`, `app_ur.arb`, regenerated `generated/l10n/*`.

**Tests:**
- `test/helpers/test_app.dart` (new);
- rewritten: `google_auth_login_screen_test.dart`, `worker_profile_setup_test.dart`, `worker_profile_responsive_test.dart`, `widget_test.dart`;
- new: `auth_flow_test.dart`, `auth_screens_test.dart`, `profile_flows_test.dart`, `arb_parity_test.dart`.

**Report:** this file.

## 10. Outstanding issues

1. **Rules and functions are not deployed.** Until they are, production still runs the old rules: public CNIC writes and self-assigned roles are possible there.
2. **No admin review UI yet.** To approve or reject, staff must:
   - read `users/{uid}/private/verification` (`cnicNumber`, `documents`, `status`, `submittedAt`) and the Storage paths in `documents` with the Admin SDK or staff claims;
   - set `status` to `verified`/`rejected`;
   - set `workerProfile.isVerified` (true only on approval) and `workerProfile.verificationStatus`.

   Signed URLs should be short-lived and never saved to a public field.
3. **Legacy public CNICs** stay until each owner removes them (a banner offers this). A one-off admin migration would need your approval.
4. **Worker exact location is still public** (existing data shape). Phase 3 item.
5. **Mobile router still treats a Firestore role of `admin` as admin.** The rules now block self-assignment, but the router should move to the custom claim. Admin phase.
6. **`UserModel.fromMap` defaults a missing rating to 5.0** for legacy docs. The UI hides ratings without reviews, but the default should become 0 in a data-model pass.
7. **PDF verification upload isn't possible** with `image_picker` (images only). Rules and service accept PDF; a file picker would need a new dependency.
8. **Signed-in screens not visually captured** (you chose to skip signed-in shots). Covered by widget tests only.
9. **Minor UX:**
   - On web, deep links such as `/#/login` land on Welcome for signed-out users, because the splash always continues to Welcome. Tapping through works.
   - The `+92` prefix on the mobile-number field only shows once the field is focused (standard Material behaviour). The hint shows the expected format.

## 11. Manual actions for you

1. Review, then deploy when ready: `firebase deploy --only firestore:rules,storage,functions`. Run `cd rules-tests && npm test` first.
2. Rotate the Google Maps keys (from Phase 2A.1). Still outstanding.
3. App Check: register the reCAPTCHA v3 site key and debug tokens in the console before enforcing.
4. Decide on admin review (in the admin phase) and the legacy CNIC cleanup.
5. Commit when you're happy. Nothing is committed.
