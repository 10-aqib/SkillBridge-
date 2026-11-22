# Identity verification: security and privacy audit (22 Nov 2026)

Scope: the NADRA fingerprint identity-verification code (app, functions, rules, admin web). Not deployed. NADRA path disabled; simulator emulator-only.

## Data collected
| Data | When | Purpose |
|---|---|---|
| CNIC number | typed by the user | sent to the server for the session and for the provider call |
| Consent (version, time, purpose) | before capture | consent record |
| Fingerprint capture (SDK output) | only with an approved SDK, which doesn't exist yet. The simulator yields a placeholder string, never a fingerprint. | one provider call |
| No CNIC images | — | the design needs none |

## Data transmitted
- App → functions over HTTPS (Firebase callables, signed-in): CNIC, consent flag/version, capture payload, request id.
- Functions → provider: only inside `NadraBiometricProvider.verify()`, which has no implementation and refuses. Nothing is sent to NADRA or to any third party today.
- Notifications/push: titles and bodies without CNIC or biometric data (checked by tests and the e2e run).

## Data stored
| Where | What | Who can read |
|---|---|---|
| `identityVerifications/{id}` | masked CNIC, HMAC digest, status, consent version/time, attempts, category, provider ref | owner, staff (rules) |
| `…/events/{id}` | event type, actor, time, codes | staff only |
| `identityCnicIndex`, `identityTransactions`, `serverSecrets` | digest→user, ref→session, HMAC key | no client (default deny); Admin SDK only |
| `users/{uid}.identityVerification` + public profile copy | status, verified, method, provider, test, verifiedAt | owner/staff; public copy signed-in users |

**Never stored or logged:** full CNIC, fingerprint images, templates, biometric hashes, capture payloads, provider responses. Logs use ids, statuses and categories only (`logger` calls reviewed). The capture string is cleared after the provider call.

## Data deleted
- Account deletion (`deleteAccount`) deletes sessions, their events, CNIC index entries and transaction refs (tested).
- Capture data: never persisted. On the app side it's held only in screen state and cleared on dispose.
- Retention: records last while the account exists (stated in the consent text). **A NADRA-mandated retention period, if any, must be confirmed and implemented when access is granted.**

## Access permissions (rules, tested on emulators)
- Users read only their own sessions and status. They cannot create, edit or delete sessions; cannot set, change or remove `identityVerification` (including `provider: nadra, verified: true`); cannot publish a forged badge on their public profile; cannot read another user's sessions, the CNIC index, transactions, the pepper or audit events. Signed-out users get nothing.
- **Staff** (`SUPER_ADMIN`/admin custom claim, never a Firestore field) can read sessions and audit events. They **cannot** change `identityVerification` or session results through the rules. The admin API offers only "mark for review" and "ask to verify again", both audited (`auditLogs` + session events); no action sets verified.
- Storage: no path accepts identity, fingerprint or CNIC files (`identity/…`, `users/{uid}/identity/…`, `users/{uid}/cnic/…` denied; tested).

## Consent handling
Separate screen, explicit checkbox, version shown and sent; the server refuses sessions without `consentAccepted: true` at the current `CONSENT_VERSION` (`2026-11-22.v1`), and records consent version, time and purpose (`identity_verification`) with an audit event. Consent covers identity verification only.

## Audit controls
Session events (`session_created`, `consent_recorded`, `capture_submitted`, `result`, `session_expired`, `session_cancelled`, `admin_*`). Admin actions are also in `auditLogs` with actor, target, previous/new status and reason.

## Abuse and integrity controls
- Recent sign-in (≤ 15 min) to start; ≤ 5 sessions/day; ≤ 3 attempts/session; 15-minute expiry; one open session.
- Idempotent submit (`requestId`); a provider reference completes only one session; the session state machine refuses double submits.
- One CNIC → one account (HMAC index; collision → `manual_review`).
- A genuine verification is never overwritten by later attempts (tested).
- Client success flags are ignored; the app only displays the server's result, and `IdentityState` also requires `provider == nadra && !test` for "verified".
- **Simulator:** emulator + `demo-` project only (production project hard-blocked; tested). Synthetic CNICs only. `verified` always false. TEST labels on every screen and notification.
- `maxInstances: 5` on identity callables (cost and abuse cap).

## App Check
Not enforced (unchanged project-wide decision). Recommended before a real launch: enable App Check enforcement for the identity callables (`enforceAppCheck: true`) once Play Integrity traffic is verified.

## Remaining risks
| Risk | Severity | Note / mitigation |
|---|---|---|
| No authorised NADRA integration | Blocking | the feature can't produce real verification until NADRA access exists |
| NADRA response authentication unknown | High (future) | must be implemented from NADRA's spec; adapter refuses until then |
| HMAC pepper in Firestore (server-only) | Low | staff with console access could read it; move to Secret Manager when NADRA goes live |
| Full CNIC in transit to functions | Low | HTTPS plus auth; never logged or stored. NADRA may prescribe extra encryption. |
| Existing staff document review stores CNIC document images (workers) | Medium | pre-existing S6 feature (private, owner/staff only). Labelled "ID documents reviewed". Add a retention/deletion policy if it is kept. |
| App Check off | Medium | see above |
