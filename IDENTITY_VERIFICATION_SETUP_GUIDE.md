# Identity verification: setup guide

No credentials or biometric data in this file. The general project setup is in `SKILLBRIDGE_SETUP_GUIDE.md`.

## 1. Firebase
- Blaze, Firestore, Auth, Cloud Functions (Node 22) as in the main guide.
- Rules: `firebase deploy --only firestore:rules,storage` after functions (main guide §7).
- Indexes: none extra needed (sessions are queried by `userId` equality only; the admin page orders by `createdAt`, a single-field index).

## 2. Cloud Functions configuration
Non-secret flags live in `functions/.env.<projectId>` (committed, all `false`):
```
NADRA_BIOMETRIC_ENABLED=false
NADRA_ACCESS_APPROVED=false
NADRA_CREDENTIALS_CONFIGURED=false
NADRA_CAPTURE_SDK_APPROVED=false
NADRA_ENVIRONMENT=none
```
- `functions/.env.skill-bridge-c68c3`: production; `functions/.env.demo-skillbridge`: emulator.
- Deploy: `firebase deploy --only functions` (deploys the identity callables with the NADRA path off).
- After deployment, production shows "NADRA verification isn't available yet". That's correct until NADRA access exists.

## 3. NADRA API configuration (only after authorisation)
1. Get eligibility, agreements, documentation, sandbox credentials and an approved capture SDK/device (`NADRA_INTEGRATION_REQUIREMENTS.md`).
2. Store credentials: `firebase functions:secrets:set <NAME>` for each value NADRA issues (names to match their documentation); bind them in `functions/src/identity/index.ts`.
3. Implement `NadraBiometricProvider.verify()` / `parseCallback()` from the official spec; set `NADRA_ADAPTER_IMPLEMENTED = true` in `providers.ts` in the same change.
4. Move the CNIC HMAC pepper from `serverSecrets/identityPepper` to Secret Manager.
5. Set the flags for the sandbox (`NADRA_ENVIRONMENT=sandbox`, others `true`), deploy, run the sandbox tests, then production.

## 4. Approved scanner / Android SDK integration
- Implement `BiometricCaptureService` with the approved SDK (official Flutter plugin, or a platform channel to its native Android SDK), returning `CaptureResult(format, payload, quality)` exactly as the SDK outputs. Select it in `biometricCaptureServiceProvider` for provider `nadra`.
- Add Android permissions (USB host / Bluetooth) **only** if the approved hardware needs them.
- Document the device model, manufacturer, SDK version, OS versions, connection method and quality requirements in `IDENTITY_VERIFICATION_TEST_REPORT.md` after real testing.
- Never use `local_auth`/BiometricPrompt for this.

## 5. Test simulator (FYP demonstration)
Runs only on the emulator with a `demo-` project.
```bash
npm --prefix functions run build
```
```bash
firebase emulators:start --only auth,functions,firestore --project demo-skillbridge
```
Point a test build of the app at the emulators (as in earlier phases: demo `FirebaseOptions`, `useAuthEmulator`/`useFirestoreEmulator`/`useFunctionsEmulator`). Synthetic CNICs:

| CNIC | Simulated outcome |
|---|---|
| 99999-0000001-1 | successful match (shown as **TEST verification**) |
| 99999-0000002-2 | fingerprint mismatch |
| 99999-0000003-3 | CNIC mismatch |
| 99999-0000004-4 | NADRA service unavailable (retryable) |
| 99999-0000005-5 | NADRA timeout (retryable) |
| 99999-0000006-6 | additional review |

On the capture screen, the "Test scenario" chips simulate good capture, poor quality, no finger, scanner unplugged, or capture failure. A real CNIC is refused in test mode.

## 6. Tests
```bash
npm --prefix functions test
```
```bash
npm --prefix rules-tests test
```
```bash
flutter test test/widget/identity_verification_test.dart
```

## 7. Troubleshooting
| Symptom | Cause |
|---|---|
| "NADRA verification isn't available yet" in production | expected: the NADRA path is gated off |
| Emulator asks "Enter a boolean value for NADRA_BIOMETRIC_ENABLED" | missing `functions/.env.<projectId>` for that project |
| `recent-login-required` | sign out, sign in again (≤ 15 min) |
| `synthetic-cnic-required` | test mode accepts only the CNICs above |
| `cnic-in-use` | that CNIC is already verified on another account (support) |
| Simulator not used on the emulator | project id must start with `demo-`; `FUNCTIONS_EMULATOR` must be set (the emulator does this) |
