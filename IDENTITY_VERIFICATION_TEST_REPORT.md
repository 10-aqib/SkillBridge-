# Identity verification: test report (22 Nov 2026)

**No real NADRA test has been performed.** There is no NADRA access, sandbox or approved capture device. Every result below uses the simulator or fakes, and **nothing here shows SkillBridge is NADRA-integrated.**

## Unit / function tests (`npm --prefix functions test`): 49 passed, 0 failed (identity: 21 + account deletion 4 + notify 13 + maps 12; counts include earlier tracks)
Identity cases:
- CNIC parsing, masking and keyed digest.
- NADRA adapter not ready by default, **and not ready even with every flag on** (no official adapter); `verify()` refuses; no callback accepted; synthetic CNICs never go to NADRA.
- Simulator only on the emulator with a demo project (deployed demo project, emulator pointed at production, and production all refused); synthetic identities only.
- Session creation: recent sign-in, consent and version, CNIC format, synthetic-only, inactive account, provider missing.
- Session contents: masked CNIC, no full CNIC, consent and audit events; reuse; daily limit.
- Worker simulated match: TEST verified, `verified` stays false, notifications, capture payload not stored. Hirer: same model.
- Mismatch → rejected. Poor quality and service unavailable → retryable, then success in the same session. Attempt limit → failed (not rejected). Manual review.
- Idempotency (one provider call for a repeated `requestId`).
- Security: another user's session, a different CNIC, invalid or oversized capture, expired session, finished session.
- Invalid capture format → failed `invalid_request`.
- One CNIC, one account. Provider reference replay → failed `invalid_response`.
- Cancel (own only). A real verification is never overwritten.
- Server notifications labelled TEST and free of CNIC. Account deletion removes identity records.

## Firebase emulator rules tests (`npm --prefix rules-tests test`): 177 passed, 0 failed
Identity block mapped to the brief's list:
1. A user can view their own status and session.
2. A user cannot change their status.
3. A user cannot set `provider: nadra, verified: true`, cannot remove the field, cannot create with it.
4. A user cannot view another user's record.
5. A user cannot read the CNIC index, transactions or pepper.
6. Staff can read but cannot set a NADRA result; normal moderation still works.
7. Fake result documents can't be created.
8. Expired sessions can't be finalised (function test plus client writes denied).
9. No identity, fingerprint or CNIC uploads to Storage.
10. Backend-only updates enforced (session writes denied to users and staff).

Plus: the public profile must copy the server status exactly (forged and hidden badges refused).

## Integration (emulator, real callables, simulator, demo project): passed
`firebase emulators:exec --only functions,firestore`, unsigned emulator tokens:
- config → provider `simulator`, `test: true`, NADRA checks all false;
- **worker** (`99999-0000001-1`) → `verified` with `verified=false`, `test=true`, no full CNIC stored;
- **hirer** (`99999-0000002-2`) → `rejected` / `fingerprint_mismatch`, role `client`;
- signed out → `UNAUTHENTICATED`; stale sign-in → `recent-login-required`; real-looking CNIC in test → `synthetic-cnic-required`; no consent → `consent-required`; same CNIC on a second account → `cnic-in-use`; another user's session → `PERMISSION_DENIED`;
- notifications `identity_submitted`, `identity_verified`, with no CNIC in the text.

## Flutter widget/unit tests (`flutter test`): 485 passed, 0 failed (identity: 16)
- "Not available" state (nothing startable, nothing sent); TEST banner in test mode.
- Worker flow end to end with a TEST result and never the NADRA title; hirer flow; invalid CNIC blocked before sending.
- Consent button disabled until ticked; cancel sends nothing.
- Scanner unplugged / no finger / capture failure / poor quality each explained, nothing submitted, session cancelled on exit.
- Retry in the same session after a retryable answer; no retry after a mismatch.
- Server refusal messages.
- Display rules: forged or test maps never count as verified; badges distinct (NADRA / TEST / ID documents reviewed).
- CNIC formatter; error-code mapping; no-SDK capture service; no-Firebase fallback.

## Device compatibility
| Item | Result |
|---|---|
| Approved NADRA scanner / SDK | **none available**, not tested |
| Android phone fingerprint sensor | deliberately **not used** (it can't produce a NADRA-verifiable capture) |
| iOS | not tested (Windows PC); no approved capture exists for iPhone |
| UI on Android | built in the Track G release APK earlier; the identity screens were not separately run on the phone in this track |

## Not tested / failed tests
- Real NADRA sandbox: **not available**. Production verification: **not available**.
- Admin web identity page: type-checked and linted (`tsc`, `eslint` pass); **not run** against a live admin session.
- No failing tests remain. During development, failures were found and fixed: CNIC/consent/capture buttons out of reach on small screens (moved into bottom bars), a missing flags file making the emulator prompt, and test-only issues.
