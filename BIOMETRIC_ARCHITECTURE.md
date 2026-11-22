# Biometric identity verification: architecture

Same model for **workers and hirers**. A NADRA-verified result can come only from an authentic NADRA response processed by the trusted functions. Today that path is gated off (see `NADRA_INTEGRATION_REQUIREMENTS.md`); a clearly labelled simulator runs in the emulator only.

## 1. Components
| Layer | Component | File |
|---|---|---|
| Flutter screens | IdentityVerificationScreen (hub + flow) | `lib/features/identity/presentation/identity_verification_screen.dart` |
| | CnicInputScreen | `…/cnic_input_screen.dart` |
| | BiometricConsentScreen | `…/biometric_consent_screen.dart` |
| | FingerprintCaptureScreen | `…/fingerprint_capture_screen.dart` |
| | VerificationProcessingScreen | `…/verification_processing_screen.dart` |
| | VerificationResultScreen | `…/verification_result_screen.dart` |
| | VerificationHistoryScreen | `…/verification_history_screen.dart` |
| | VerificationStatusWidget (`IdentityBadges`, `IdentityStatusCard`) | `…/verification_status_widget.dart` |
| Flutter services | IdentityVerificationService (callables), VerificationStatusService (`identityHistoryProvider`), VerificationSession (flow in the hub) | `lib/features/identity/data/identity_verification_service.dart` |
| | BiometricCaptureService (`NoApprovedCaptureService`, `SimulatedCaptureService`; the approved SDK adapter later) | `…/data/biometric_capture_service.dart` |
| | CNICValidationService (`CnicValidation`, `CnicInputFormatter`), status/badge rules | `lib/features/identity/domain/identity_models.dart` |
| Functions | `getIdentityVerificationConfig`, `createIdentityVerificationSession`, `submitIdentityFingerprint`, `cancelIdentityVerificationSession` | `functions/src/identity/index.ts` |
| | Session logic (consent, expiry, attempts, idempotency, replay, one-CNIC-one-account, audit, results) | `functions/src/identity/sessions.ts` |
| | Provider layer: `BiometricProvider`, `NadraBiometricProvider` (gated, refuses), `SimulatorProvider` (emulator only) | `functions/src/identity/providers.ts` |
| | CNIC helpers (digits, mask, HMAC digest, synthetic range) | `functions/src/identity/cnic.ts` |
| | Notifications: server-written, pushed by `onNotificationCreatedV2` | `functions/src/identity/index.ts`, `functions/src/notify.ts` |
| Admin | Identity Verification page + `POST /api/admin/identity/action` (review / ask to retry; no "verify") | `super_admin_web/src/app/adminpanel/identity/*`, `…/api/admin/identity/action/route.ts`, `…/lib/services/identity.service.ts` |
| Rules | Firestore (sessions owner/staff read-only; `identityVerification` server-only; index/transactions/pepper denied) and Storage (no identity files) | `firestore.rules`, `storage.rules` |

## 2. Data model
- `identityVerifications/{sessionId}`:
  - `userId`, `userRole`, `provider` (`nadra`|`simulator`), `test`, `verificationMethod` (`fingerprint`), `status`;
  - `maskedCnic`, `cnicDigest` (HMAC);
  - `consentVersion`, `consentAcceptedAt`, `consentPurpose`;
  - `attempts`, `maxAttempts`, `lastRequestId`, `transactionReference`, `resultCode`, `failureCategory`;
  - `createdAt`, `updatedAt`, `expiresAt`, `completedAt`.
  - Subcollection `events/{id}`: type, actor, time, codes only.
- `identityCnicIndex/{digest}` (one CNIC → one account; `test_` prefix for the simulator) · `identityTransactions/{provider_ref}` (a result is used once) · `serverSecrets/identityPepper` (random HMAC key). All server-only.
- `users/{uid}.identityVerification`: `{status, verified, method, provider, test, verifiedAt}`. Server-managed; copied verbatim to `publicProfiles/{uid}`. Kept separate from `isEmailVerified`, `isPhoneVerified`, `isCnicVerified`/`workerProfile.isVerified` (staff document review) and `isActive`.
- **Never stored:** full CNIC, fingerprint images, templates, biometric hashes, capture payloads, provider responses, CNIC images.

Status values: `not_started`, `consent_pending`, `pending`, `capturing`, `submitted`, `processing`, `verified`, `rejected`, `failed`, `manual_review`, `expired`, `cancelled`. `capturing` and `consent_pending` are client-side steps; the server stores the rest. A technical failure (`failed`, or `pending` with `poor_quality`/`service_unavailable`/`timeout`) is never an identity mismatch (`rejected`).

## 3. Lifecycle
1. Signed-in user opens Identity verification. The app asks the server for config: provider `nadra` (all readiness checks pass), `simulator` (emulator + demo project only), or `null` (not available: Case A).
2. CNIC entered (13 digits, masked input; format only).
3. Consent screen (separate, explicit checkbox, version shown).
4. `createIdentityVerificationSession`: recent sign-in (≤ 15 min), consent at the current version, CNIC valid (simulator: synthetic only), active account with a role, not already verified, one open session (same CNIC → reused), ≤ 5 sessions/day, CNIC not verified on another account. Writes the session, consent record and audit events; status `pending`; expires in 15 min.
5. Capture through `BiometricCaptureService`: states waiting → connected → ready → finger detected → capturing → success, or poor quality / no finger / failed / scanner disconnected / expired. "Captured" ≠ "verified".
6. `submitIdentityFingerprint` (idempotent `requestId`):
   - checks ownership, state, expiry, the CNIC digest and the attempt limit (3 per session);
   - claims `submitted`, then calls the provider;
   - maps the outcome; checks the provider ref is unused;
   - on a match, claims the CNIC index (else `manual_review`);
   - updates the session, the account status and the audit trail;
   - notifies.
   - The capture payload is never stored and is dropped from memory after the call.
7. Result screen: verified (NADRA) / TEST pass / not confirmed / review / try again (same session) / failed / expired.
8. Cancel before submitting → `cancelled`.

## 4. Security controls (summary)
Auth on every callable; recent sign-in for starting; server-side decisions only; Firestore rules forbid any client (and staff) from setting `identityVerification`; replay protection (provider refs, `requestId`, session state machine, expiry); rate limits (sessions/day, attempts/session, `maxInstances`); PII-free logs and notifications; the simulator is hard-blocked outside the emulator; the NADRA adapter refuses until implemented to NADRA's spec; account deletion removes identity records. Details: `IDENTITY_VERIFICATION_SECURITY_AUDIT.md`.

## 5. Failure workflows
| Case | Behaviour |
|---|---|
| A. No NADRA approval | Banner "NADRA verification isn't available yet"; nothing collected; app otherwise unchanged. |
| B. Scanner unavailable | Capture screen explains (no approved scanner / scanner disconnected); retry or cancel; never falls back to phone unlock. |
| C. Poor quality | Device-side: rescan. Provider-side: `pending` + `poor_quality`, "Scan again (n left)"; never counted as a mismatch. |
| D. NADRA unavailable/timeout | `pending` + `service_unavailable`/`timeout`; request kept; retry within limits; never granted automatically. |
| E. Mismatch | `rejected`, neutral wording, support link; a new session may be started (daily limit). |
| F. Document review | The existing staff review of CNIC documents (workers) shows **"ID documents reviewed"**, never "NADRA verified". |
| G. FYP demo | Simulator on the emulator, synthetic CNICs `99999-0000001-1` … `-6-6`, **TEST** labels everywhere, `verified` stays false. |
