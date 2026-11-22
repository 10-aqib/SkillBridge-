# NADRA integration requirements (SkillBridge identity verification)

Status, 22 Nov 2026: **SkillBridge has NO authorised NADRA access.** No agreement, credentials, API documentation, sandbox or approved capture SDK/device exist. The NADRA provider in the code is disabled and cannot be enabled until everything below is in place. No NADRA endpoint, credential, SDK name or response format has been invented anywhere in the code.

This document lists what an organisation needs, based on public reporting. **Confirm every item directly with NADRA**; public sources are incomplete and change.

## 1. What NADRA offers (public information)
| Service | What it is (as publicly reported) | Source |
|---|---|---|
| **Nishan Pakistan** (NP) | Web portal launched by NADRA on 10 Feb 2026 as a single gateway for government entities and regulated private organisations to onboard, subscribe to and access NADRA identity services. Launched under the NADRA (Data Sharing) Regulations 2025 and NADRA (Identity Verification) Regulations 2026, within the Digital Economy Enhancement Project. | [ProPakistani](https://propakistani.pk/2026/02/10/nadra-introduces-nishan-pakistan-to-strengthen-secure-identity-verification/), [Biometric Update](https://www.biometricupdate.com/202602/nadra-launches-unified-platform-to-standardize-id-verification-services) |
| **Multi-biometric verification (MBVS) APIs** | Fingerprint and facial-recognition verification APIs for onboarded organisations, through Nishan Pakistan. | same |
| **Verisys** | Demographic and identity verification. | same |
| **BIOSYS / Biosys** | NADRA's earlier biometric verification system used by banks and other institutions; public sources don't say how it relates to Nishan Pakistan now. | [Dawn](https://www.dawn.com/news/186087) |
| Contactless (app-based) biometric verification | Announced in 2021 for banking and payments. | [Dawn](https://www.dawn.com/news/1645537/nadra-launches-contactless-biometric-verification-service-for-banking) |
| Facial recognition | Announced Dec 2025. | [ProPakistani](https://propakistani.pk/2025/12/31/nadra-introduces-facial-recognition-for-biometric-verification/) |
| Startup programme | A 2023 "Nishan Pakistan" offering was described as biometric verification for startups and young entrepreneurs (the name predates the 2026 platform). | [The News](https://thenews.com.pk/latest/1073829-nadras-new-platform-to-empower-startups-young-entrepreneurs) |

## 2. Eligibility (the main blocker)
- Public reporting describes onboarding for **banks, microfinance banks, EMIs, NBFIs, telecom companies and other regulated organisations**, plus government entities.
- **A university FYP is not a regulated organisation**, and having Firebase Blaze makes no difference.
- Possible routes to ask about: a registered company applying through Nishan Pakistan (if NADRA accepts marketplace platforms); NADRA's startup programme (if still offered); or a licensed intermediary approved by NADRA. None is confirmed.

## 3. Checklist to obtain before enabling anything
| # | Item | Status |
|---|---|---|
| 1 | Organisational eligibility confirmed in writing by NADRA | ❌ not started |
| 2 | Onboarding through the applicable channel (Nishan Pakistan or as NADRA directs) | ❌ |
| 3 | Registration documents (company registration, NTN, authorised signatory, regulator licence if required; exact list from NADRA) | ❌ unknown list |
| 4 | Agreements: service agreement, data-sharing agreement, NDA, acceptable-use terms | ❌ |
| 5 | Information-security requirements (audits, hosting/location rules, logging, retention, incident reporting, ban on independent biometric databases) | ❌ |
| 6 | API documentation: request/response formats, signing/encryption, callbacks, error codes | ❌ |
| 7 | Sandbox credentials | ❌ |
| 8 | Production credentials | ❌ |
| 9 | Fingerprint capture SDK documentation (format, quality scoring, licensing) | ❌ |
| 10 | Approved fingerprint scanner models (and whether Android USB/Bluetooth scanners are allowed) | ❌ |
| 11 | Supported operating systems / Android versions | ❌ |
| 12 | Transaction pricing | ❌ |
| 13 | Request limits / throttling | ❌ |
| 14 | Test procedures and certification before go-live | ❌ |
| 15 | Support and escalation contacts | ❌ |

Questions for NADRA: whether mobile apps may capture fingerprints at all, or whether capture must happen at approved locations/devices; whether CNIC images are required (the current design collects none); retention limits for transaction references; whether results arrive synchronously or by callback, and how callbacks are authenticated.

## 4. What is NOT allowed (and not done)
- No reverse-engineering of PakID or any NADRA app; no imitation of an official NADRA app.
- No unauthorised access to NADRA systems; no unofficial third-party "NADRA" APIs.
- A phone's fingerprint unlock (Android BiometricPrompt / `local_auth`, Touch ID) is never treated as NADRA verification.
- No fingerprint images, templates or biometric hashes are stored or logged.

## 5. How the code is gated
| Gate | Where | Current value |
|---|---|---|
| `NADRA_BIOMETRIC_ENABLED` | `functions/.env.skill-bridge-c68c3` | `false` |
| `NADRA_ACCESS_APPROVED`, `NADRA_CREDENTIALS_CONFIGURED`, `NADRA_CAPTURE_SDK_APPROVED`, `NADRA_ENVIRONMENT` | same | `false`, `false`, `false`, `none` |
| `NADRA_ADAPTER_IMPLEMENTED` | `functions/src/identity/providers.ts` (code constant) | `false`: set true only in the change that implements NADRA's official spec and passes sandbox tests |
| App capture | `lib/features/identity/data/biometric_capture_service.dart` | `NoApprovedCaptureService` (captures nothing) until an approved SDK is integrated |

All six checks must pass before the NADRA provider is used (`getIdentityVerificationConfig` reports each one). Until then production shows "NADRA verification isn't available yet". The test simulator runs only on the Firebase emulator with a `demo-` project.

## 6. Steps once access is granted (for the developer)
1. Store credentials in Secret Manager (names per NADRA's documentation) and bind them to the identity functions.
2. Implement `NadraBiometricProvider.verify()` (and `parseCallback()` if NADRA uses callbacks) exactly to NADRA's spec: request signing, transport, response authentication, error mapping to `ProviderOutcome`.
3. Integrate the approved capture SDK behind `BiometricCaptureService` (official plugin or platform channel per the SDK's own API).
4. Run the official sandbox tests (match, mismatch, poor quality, timeout, callback authenticity, data deletion), then set `NADRA_ADAPTER_IMPLEMENTED = true` and the flags.
5. Update `IDENTITY_VERIFICATION_TEST_REPORT.md` with real results before claiming SkillBridge is NADRA-integrated.
