# SkillBridge Privacy Policy and Data Handling

| | |
|---|---|
| Version | 2026-11-22 (v2.0) |
| Effective date | 22 November 2026 |
| Applies to | SkillBridge Android app, SkillBridge web app, iOS build (when released), and the SkillBridge staff admin website |
| In-app copy | Settings → Privacy policy, the side menu, and the sign-up screen (`lib/shared/screens/privacy_policy_screen.dart`) |

> **About this document.** It describes what SkillBridge actually does with personal data, based on the app code, the Firestore and Storage security rules and the Cloud Functions in this repository as of the date above. It covers every feature, including some that are built but not switched on in production yet (see [Appendix D](#appendix-d-feature-status-and-items-to-confirm-before-public-launch)). SkillBridge is a final-year project. **Before a public launch, a qualified lawyer should review this policy against Pakistani law and the app-store rules.**

---

## Contents
1. [Who we are](#1-who-we-are)
2. [Key words used in this policy](#2-key-words-used-in-this-policy)
3. [Summary at a glance](#3-summary-at-a-glance)
4. [Information we collect](#4-information-we-collect)
5. [How we use information](#5-how-we-use-information)
6. [Why we are allowed to use it (legal bases)](#6-why-we-are-allowed-to-use-it-legal-bases)
7. [Who can see your information inside SkillBridge](#7-who-can-see-your-information-inside-skillbridge)
8. [Service providers and other sharing](#8-service-providers-and-other-sharing)
9. [International transfers](#9-international-transfers)
10. [How we protect information](#10-how-we-protect-information)
11. [How long we keep information](#11-how-long-we-keep-information)
12. [Deleting your account](#12-deleting-your-account)
13. [Your rights and choices](#13-your-rights-and-choices)
14. [Device permissions](#14-device-permissions)
15. [Location in detail](#15-location-in-detail)
16. [Identity verification in detail](#16-identity-verification-in-detail)
17. [Messages, photos and files](#17-messages-photos-and-files)
18. [Notifications and emails](#18-notifications-and-emails)
19. [Payments](#19-payments)
20. [Analytics, crash reports and app integrity](#20-analytics-crash-reports-and-app-integrity)
21. [Data stored on your device, cookies and the web app](#21-data-stored-on-your-device-cookies-and-the-web-app)
22. [Staff access, moderation and reports](#22-staff-access-moderation-and-reports)
23. [Children](#23-children)
24. [Your responsibilities toward other people's data](#24-your-responsibilities-toward-other-peoples-data)
25. [Security incidents](#25-security-incidents)
26. [Links and other apps](#26-links-and-other-apps)
27. [Changes to this policy](#27-changes-to-this-policy)
28. [Contact us](#28-contact-us)
- [Appendix A: Data inventory](#appendix-a-data-inventory)
- [Appendix B: What happens to each kind of data when you delete your account](#appendix-b-what-happens-to-each-kind-of-data-when-you-delete-your-account)
- [Appendix C: A–Z index of policies](#appendix-c-az-index-of-policies)
- [Appendix D: Feature status and items to confirm before public launch](#appendix-d-feature-status-and-items-to-confirm-before-public-launch)

---

## 1. Who we are
SkillBridge is a local services marketplace for Pakistan. **Clients** post jobs (for example electrical, plumbing or cleaning work) and hire **workers**; workers create a professional profile, send proposals and carry out the work. The app handles sign-in, profiles, jobs, proposals, contracts, chat, live location during a job, reviews and notifications.

SkillBridge (the project team) decides how and why personal data in the app is used, so for this policy it is the **data controller**. Contact details are in [section 28](#28-contact-us).

## 2. Key words used in this policy
| Word | Meaning |
|---|---|
| **Personal data** | Any information about an identifiable person: name, phone number, photo, location, messages, and so on. |
| **Account** | Your private SkillBridge record (`users/{your id}`). Only you and SkillBridge staff can read it. |
| **Public profile** | A limited copy of your account that other signed-in users can see (`publicProfiles/{your id}`). |
| **Contract** | A job a client has hired a worker for, from hiring to completion or cancellation. |
| **Contract parties** | The client and the worker on a contract. |
| **Staff** | SkillBridge administrators. Staff status is a server-side permission on the sign-in account (a "custom claim"), never a field anyone can edit. |
| **Service provider** | A company that runs part of the service for us, mainly Google (Firebase and Google Maps Platform). |
| **CNIC** | Pakistan's Computerised National Identity Card number. |

## 3. Summary at a glance
- We collect what the marketplace needs to work: your account details, your profile, jobs, proposals, contracts, messages, reviews, photos you upload, and location when you allow it.
- **Your phone number, email, exact address, exact location, CNIC and earnings are never shown on your public profile.** Other users see a limited public profile, and worker locations there are rounded to about 1.1 km. Only after hiring does the hired worker get the service address (and, for a direct booking, the phone number the client entered) so the job can be done.
- **Live location is shared only during an active job, only by the worker, only when they turn it on, and only with that job's client.** It is deleted when that stage of the job ends.
- **We never collect or store fingerprints,** fingerprint templates or biometric hashes. NADRA fingerprint verification is not active.
- **We do not sell personal data** and we show no advertising.
- Our main service provider is **Google** (Firebase and Google Maps Platform). Their servers may be outside Pakistan.
- You can **delete your account inside the app** (Settings → Delete account). Your own data is deleted; records other people keep (a shared chat, a contract, a review) stay with them, but your name and photo are removed from them.
- You control location permission, live sharing, push notifications and your notification preferences at any time.

## 4. Information we collect

### 4.1 Account and sign-in
| Data | Source | Notes |
|---|---|---|
| Email address | you | used to sign in and for account emails |
| Password | you | handled by Firebase Authentication. **SkillBridge never sees or stores your password.** |
| Google account name, email and profile photo | Google, if you choose "Continue with Google" | only the basic profile Google shares |
| Full name (display name) | you | |
| Phone number | you | required for clients and workers: you confirm it with a one-time SMS code (sent through Firebase Authentication) before using SkillBridge, including after Google sign-in. The confirmed number is linked to your sign-in account, and one number can belong to only one account. |
| Role (client or worker) | you | |
| Email/phone verified flags | Firebase Authentication | |
| Account status (active or suspended), created/updated times | system | |

### 4.2 Profile
**Clients:** name, phone, profile photo, address, city, and a location pin if you set one (for example to post jobs nearby).

**Workers:** in addition to the above: professional title (headline), bio, service category, skills, years of experience, hourly and daily rates, languages, availability (available, busy, offline), service radius, certifications (name, issuer, year), portfolio photos, before/after photos, a cover image, response time, and job statistics (jobs completed, average rating, earnings totals).

### 4.3 Location
- **Profile location:** a point you set or allow from GPS, plus your city and address. A worker can choose whether their location appears on their public profile; when it does, it is rounded to about 1.1 km.
- **Current location on maps:** used on your device to show where you are and to sort or measure distance to nearby workers or jobs. The blue dot appears only if you have already granted permission.
- **Live location (workers, during an active contract only):** position, accuracy, direction of travel, speed and timestamps. See [section 15](#15-location-in-detail).
- **Address search, routes and distances:** the text you type in address search, and the start and end points of a route, are sent through our server to Google Maps Platform to get results.

### 4.4 Jobs, proposals and contracts
- **Jobs:** title, description, category, skills needed, budget, city and area, photos, status, and dates. The exact service address is shared with the hired worker only after hiring.
- **Proposals:** cover note, price, timing, status (pending, shortlisted, accepted, rejected, withdrawn).
- **Contracts:** agreed price and terms, the service address and map pin, the client's phone number when the client books a worker directly, every status step (from hired, through travelling, arrived and work in progress, to completion), progress notes, work submissions, evidence photos, revision requests, cancellation reasons and notes, and dates.
- **Saved jobs (workers):** a bookmark with the job's title, city and budget.

### 4.5 Messages
Text and photos you send in chat, the time sent, and when each person last read the conversation (used for "seen" status). Each conversation is linked to its two members and, where relevant, to a job.

### 4.6 Reviews and ratings
Your star rating and written review of the other party after a contract, the reviewer's and reviewee's names and photos, and your overall rating and review count.

### 4.7 Photos and files you upload
Profile photos, cover images, portfolio and before/after photos, job photos, chat photos and contract evidence photos. Photos are resized on your device (up to 1024 px) and must be JPEG, PNG or WebP under 2 MB. See [section 17](#17-messages-photos-and-files).

### 4.8 Identity verification
- **ID document review ("Get verified", workers and clients):** your CNIC number and photos of the front and back of your card (workers may add a trade certificate), which SkillBridge staff review by hand. Once approved, your profile shows the "Verified" badge.
- **NADRA fingerprint verification:** **not active**. If it is switched on in the future, the data it uses is described in [section 16](#16-identity-verification-in-detail). It never stores fingerprints.

### 4.9 Notifications
In-app notifications (for example "new proposal" or "new message"), whether each has been read, your push-notification settings, and push tokens: an identifier for each of your devices (up to 10) so we can deliver push notifications.

### 4.10 Reports and support
- **Reports:** if you report a user, we store who reported whom, the reason and details you give, and the report's status.
- **Support:** if you contact support by email or WhatsApp, we receive what you send through those services, plus your email address or phone number.

### 4.11 Device, usage and diagnostic information
- **Usage events** (Firebase Analytics): screens viewed, and events such as sign-in, sign-up, job posted, proposal sent and contract created, linked to your SkillBridge user ID. Google also collects device model, operating-system version, app version, approximate region (from IP address) and an app-instance identifier.
- **Crash reports** (Firebase Crashlytics, mobile only): what went wrong, device model, operating-system version, app version, and your user ID.
- **App integrity** (Firebase App Check): a token from Google Play Integrity (Android) or reCAPTCHA (web) that tells our backend the request comes from the genuine app.

### 4.12 Information other people give about you
Reviews about you, messages people send you, proposals or jobs that involve you, and reports made about you.

### 4.13 What we do **not** collect
- No fingerprints, face scans, fingerprint templates or biometric hashes.
- No payment card, bank account or wallet details (see [section 19](#19-payments)).
- No contacts, call logs, SMS content, microphone recordings or files outside what you choose to upload.
- No location in the background: location is read only while the app is open and in use.
- No advertising identifiers used for ads, and no data sold to anyone.

## 5. How we use information
| Purpose | Data used |
|---|---|
| Create and secure your account; sign you in; reset passwords | account and sign-in data |
| Show your public profile so clients can find workers and workers can see who they work for | public profile fields only |
| Match clients and workers: search, categories, "near me", distances | profile, approximate location, skills, availability |
| Run jobs, proposals and contracts, including each step's rules (who may do what, when) | job, proposal and contract data |
| Let contract parties find each other: directions, live location, ETA | locations, routes |
| Chat between the people working together | messages and photos |
| Build trust: ratings, reviews, verification badges | reviews, verification status |
| Send in-app and push notifications you have not turned off | notification data, push tokens, preferences |
| Prevent fraud, abuse and spam; enforce limits; handle reports and disputes | account status, reports, contract history, audit logs, App Check |
| Fix bugs and improve the app | crash reports, usage events (aggregated) |
| Meet legal obligations and respond to lawful requests | as the request requires |

We do **not** use your data for advertising, to build marketing profiles, or for automated decisions with legal or similarly significant effects. Sorting workers by distance or rating is a convenience; you always choose whom to hire or work for.

## 6. Why we are allowed to use it (legal bases)
SkillBridge is operated from Pakistan and aims to follow applicable Pakistani law, including the Prevention of Electronic Crimes Act 2016, and widely recognised data-protection principles. We rely on:
- **Contract:** to provide the service you signed up for (account, profiles, jobs, contracts, chat, notifications).
- **Consent:** for device location, live location sharing, push notifications and identity verification. You can withdraw consent at any time ([section 13](#13-your-rights-and-choices)); this doesn't affect use before you withdrew it.
- **Legitimate interests:** keeping the platform safe and working (fraud prevention, abuse handling, security logs, crash reports, aggregated analytics), balanced against your rights.
- **Legal obligation:** where the law requires us to keep or disclose information.

## 7. Who can see your information inside SkillBridge
These limits are enforced by the server's security rules, not just by the app's screens, and are covered by automated tests.

| Information | Who can see it |
|---|---|
| Private account: email, phone, exact address, exact location, CNIC, push tokens, earnings, verification details, settings | **you and staff only** |
| Public profile: name, photo, role, city, verified badges, rating, member since; for workers also title, bio, category, skills, experience, rates, languages, availability, service radius, certifications (name, issuer, year), portfolio, approximate location (~1.1 km, if you allow it) | **signed-in users** |
| Open jobs (without the exact location) | signed-in users (mainly workers) |
| Service address, map pin and (for direct bookings) the client's phone number | the client, and the hired worker after hiring (stored on the contract) |
| A proposal | the worker who sent it and the job's client |
| A contract, its steps, notes, submissions and evidence photos | the two contract parties and staff |
| Live location | the client of that active contract, the worker, and staff |
| Chat messages and chat photos | the two members of the conversation (and staff when investigating a report or dispute) |
| Reviews | signed-in users (they are public on profiles) |
| Notifications | the recipient only |
| Saved jobs, notification preferences | you only |
| Reports | the person who made the report and staff |
| ID documents | you and staff |
| Identity verification sessions | you and staff (audit events: staff only) |

Signed-out visitors can see only the welcome, sign-in and sign-up screens and the legal pages.

## 8. Service providers and other sharing
**We do not sell, rent or trade personal data.** We share it only as follows.

| Recipient | What | Why |
|---|---|---|
| **Google Firebase** (Authentication, Cloud Firestore, Cloud Storage, Cloud Functions, Cloud Messaging, App Check, Analytics, Crashlytics) | the data described in section 4, as each service needs | hosting the database and files, sign-in, server logic, push notifications, app integrity, diagnostics |
| **Google Maps Platform** (Maps SDK, Routes, Places, Geocoding) | map views, address search text, route start/end points, coordinates for addresses | maps, address search, routes, distance and ETA. Requests are made through our server where a secret key is needed. |
| **Google Sign-In** | your Google basic profile | only if you choose it |
| **Google Maps app** | the destination you open | when you tap "Directions", the trip opens in Google Maps under Google's own terms |
| **Email and WhatsApp** | what you choose to send support | only if you contact us |
| **NADRA** | CNIC and fingerprint capture, sent directly for a single verification | **not active.** Only if the feature is authorised and switched on, and only with your explicit consent each time |
| **Other users** | what [section 7](#7-who-can-see-your-information-inside-skillbridge) lists | that's how the marketplace works |

Google processes data under its own terms and privacy policies (Firebase and Google Cloud data processing terms, and the Google Maps Platform terms).

We may also disclose information:
- **when required by law**, a court order or a lawful request from authorities, after checking the request is valid, and sharing only what is required;
- **to protect people:** to prevent fraud, threats to someone's safety, or serious harm;
- **in a restructuring:** if SkillBridge is merged, transferred or acquired, under this policy or one at least as protective, and we'll tell you first.

## 9. International transfers
Google's servers may be outside Pakistan. Our Cloud Functions run in the United States (`us-central1`), and Firebase may store and process data in other countries. Google applies its own security and contractual safeguards to those transfers.

## 10. How we protect information
- **Encryption:** all traffic between the app and Firebase/Google uses HTTPS (TLS). Google encrypts stored data at rest.
- **Server-enforced access rules:** Firestore and Storage security rules deny everything by default and allow only what each role needs (sections 7 and 17). Rules are tested automatically (177 emulator tests at the time of writing).
- **Private versus public split:** other users never read your private account; they read a public profile limited to an allowlist of fields.
- **Protected fields:** you can't give yourself a verified badge, a better rating, staff powers or a fake identity result. Only trusted server code or staff can change those, and staff can never set an identity-verification result.
- **Staff access:** staff permission is a server-side custom claim. Staff actions in the admin website are written to an audit log.
- **Server code:** functions require you to be signed in, validate every input, apply per-user rate limits and caps, and keep secrets (such as the Maps server key) in Google Secret Manager.
- **Logs:** our server logs don't contain message text, coordinates, push tokens, API keys, CNICs or capture data.
- **Sensitive actions:** deleting your account or starting identity verification needs a recent sign-in.
- **App integrity:** Firebase App Check is active (enforcement is planned before a public launch).

No system is perfectly secure. Use a strong password, don't share your account, and sign out on shared devices.

## 11. How long we keep information
| Data | How long |
|---|---|
| Account, profile, settings, saved jobs | until you delete your account (or staff delete it) |
| Public profile | until you delete your account |
| Jobs, proposals, contracts, reviews, chats | kept as a record for the other people involved. When you delete your account, your name and photo are removed from them ("Deleted user"). |
| Live location | only while the worker shares during an active contract. It is deleted when that stage ends (work submitted, completed or cancelled), and the worker can stop sharing and delete it at any time. Positions older than 2 minutes are shown as out of date. |
| In-app notifications | until you delete them or your account (the app shows your latest 100) |
| Push tokens | until you sign out on that device, the token stops working, or you delete your account |
| ID documents and CNIC number (document review) | until you delete them before review, staff remove them, or you delete your account |
| Identity verification sessions (masked CNIC, consent record, status, audit events) | while your account exists; deleted with the account. If NADRA access is granted, any retention period NADRA requires will be added here. |
| Reports | as long as needed to handle the report and protect users, then deleted by staff |
| Maps usage counters (for fair-use limits) | short-term counters; deleted with your account |
| Analytics and crash data | according to Firebase's retention settings, then deleted by Google |
| Data on your device | removed when you sign out or another account signs in on the device: your sign-in, cached listings, recent searches and queued actions not yet sent. Your theme choice stays. The Firebase database library's own offline copy stays until you clear the app's data or uninstall. |

Google may keep deleted data in backups or logs for a limited time under its own policies before it is permanently removed.

## 12. Deleting your account
**Where:** Settings → Account → Delete account.

**How it works:**
1. You confirm, and you must have signed in within the last 10 minutes (so nobody with your unlocked phone can delete your account).
2. Deletion is refused while you have an **active contract**: finish or cancel it first, so the other person isn't left with work in progress.
3. The server then:
   - **anonymises** what other people keep: your name becomes "Deleted user" and your photo is removed on jobs, proposals, contracts, reviews and chats;
   - **cancels** your open jobs and **withdraws** your pending proposals;
   - **deletes** your account, private documents, ID documents, public profile, saved jobs, notifications, push tokens, live location, rating summary, maps usage counters, identity-verification records, your photos in Storage, and finally your sign-in.

You can also ask support to delete your account ([section 28](#28-contact-us)). Uninstalling the app does **not** delete your account.

Full detail per data type: [Appendix B](#appendix-b-what-happens-to-each-kind-of-data-when-you-delete-your-account).

## 13. Your rights and choices
You can:
- **See and correct** your data: edit your profile at any time; ask support for anything you can't change in the app.
- **Get a copy:** ask support for a copy of your personal data. We'll reply within 30 days.
- **Delete:** delete your account in the app ([section 12](#12-deleting-your-account)), or delete individual items: photos, notifications, saved jobs, and ID documents before review.
- **Withdraw consent or object:**
  - device location: turn it off in your phone's settings (map features then ask you to pick a place by hand);
  - live location: stop sharing at any time from the job screen;
  - public location (workers): choose not to show your location on your public profile;
  - push notifications: turn them off in Settings (all, messages only, or jobs and contracts) or in your phone's settings;
  - identity verification: you can cancel before submitting.
- **Complain:** contact us first. If you're not satisfied, you can complain to the relevant Pakistani authority.

We may need to confirm your identity before acting on a request, and we may keep information the law requires us to keep.

## 14. Device permissions
| Permission | Used for | If you say no |
|---|---|---|
| **Location** (precise/approximate, while using the app) | your position on maps, nearby workers or jobs, directions, live location during a job | you can still use the app and pick places by hand |
| **Camera and photos** (system picker) | profile, job, chat and evidence photos | you can't upload photos |
| **Notifications** (Android 13+, iOS) | push notifications | you still see in-app notifications |
| **Internet** | everything online | the app works offline only partly (cached data and queued actions) |

SkillBridge doesn't ask for background location, contacts, microphone, SMS, call logs or phone-fingerprint (biometric) permissions.

## 15. Location in detail
- **When location is read:** only while the app is open and you're using a screen that needs it, and only if you've allowed it.
- **Profile location:** stored privately on your account. On a worker's public profile it is rounded to two decimal places (about 1.1 km) so others can see roughly how far away you are, never your doorstep. Workers can hide it.
- **Job location:** before hiring, workers see the city and area. The service address and pin are shared with the hired worker on the contract.
- **Live location:**
  - available only to the **worker** on an **active contract**, only after they turn it on, and never while the job waits for review;
  - updated while sharing is on, with position, accuracy, direction and speed;
  - visible only to that contract's client, the worker and staff;
  - stops when the worker stops it, signs out or switches account, or when the contract stage ends. The live position is then **deleted**;
  - positions older than 2 minutes are marked as out of date.
- **Routes and address search:** our server sends Google only what's needed (search text, start and end coordinates) and doesn't write coordinates to logs. Results may be cached briefly to reduce repeated requests.
- **Directions:** turn-by-turn navigation opens in the Google Maps app.

## 16. Identity verification in detail
**ID document review (current, the CNIC step of "Get verified"):** a worker or client can submit a CNIC number and photos of their card. They are stored privately (only that person and staff can read them) and reviewed by staff. Once added, a document can be removed by its owner before submission, or by staff. Approval gives the "Verified" badge (on detail screens: "ID documents reviewed"). It is not a NADRA check. The fingerprint step of "Get verified" shows "Coming soon" and collects nothing.

**NADRA fingerprint verification (built, not active):**
- **Status:** turned off. SkillBridge has no NADRA access yet, so the app shows "NADRA verification isn't available yet". No data goes to NADRA.
- **If it's activated in the future:** only with an approved, certified fingerprint scanner and NADRA's authorisation, after you read and accept a separate consent screen (which shows its version).
- **What would be stored:**
  - the CNIC masked (for example `35202-*******-1`);
  - a keyed one-way code of the CNIC, so one CNIC can't verify several accounts;
  - consent version, time and purpose;
  - status, attempt count, result category, the provider's reference, and an audit trail.
- **Never stored or logged:** the full CNIC number, fingerprint images, fingerprint templates, biometric hashes, the scanner's capture data, or the provider's raw response. The capture is held only in memory for a single request and then cleared.
- **Limits:** recent sign-in required; at most 5 sessions a day and 3 attempts per session; sessions expire after 15 minutes.
- **Phone sensors:** SkillBridge never uses your phone's fingerprint sensor or face unlock for identity verification.
- **Test mode:** a simulator exists only for developers on a local test environment with made-up CNICs. Its results are labelled "TEST" and never count as verified.
- **Retention and deletion:** records last while your account exists and are deleted with it.

## 17. Messages, photos and files
- **Chat:** visible only to the two members. Messages aren't end-to-end encrypted; they're encrypted in transit and at rest by Google, and staff can access them only when needed to investigate a report, dispute or legal request.
- **Photos:** resized on your device before upload, and checked to be a real image file (JPEG, PNG or WebP) under 2 MB.
- **Who can open a photo:**
  - profile, cover, portfolio and job photos are meant to be seen by others, and **anyone who has the photo's link can open it**;
  - chat photos are limited to the conversation's members;
  - contract evidence to the contract parties and staff;
  - ID documents to you and staff.
- **Replacing or deleting:** when you replace or delete a profile photo, the old file is deleted from storage.
- **Before you upload:** photos can contain details you might not want to share (faces, house numbers, documents, location data embedded by your camera). Check them first.

## 18. Notifications and emails
- **In-app notifications:** about proposals, hiring, contract steps, messages, reviews and verification. Their text is checked and rewritten by our server so nobody can send you a fake or misleading notification. They never include your CNIC or other sensitive details.
- **Push notifications:** delivered through Firebase Cloud Messaging to the devices you're signed in on (up to 10), following your Settings choices. Push tokens are removed when you sign out of a device.
- **Emails:** only account emails sent by Firebase Authentication (email verification, password reset). **No marketing emails or newsletters.**
- **SMS:** only one-time verification codes, when you add or change your phone number.

## 19. Payments
Payment between client and worker is arranged between them (for example cash or a mobile wallet). The EasyPaisa screen in the app only **shows** payment instructions: SkillBridge doesn't process payments or collect card, bank or wallet credentials. Agreed prices and earnings totals are kept as part of contract records and statistics.

## 20. Analytics, crash reports and app integrity
- **Firebase Analytics:** screen views and a small set of events, linked to your user ID, used in aggregate to understand which features work. We don't use it for advertising or share it with advertisers.
- **Firebase Crashlytics** (Android/iOS): crash details and your user ID, so we can fix the problem you hit.
- **Firebase App Check:** a device-integrity token from Play Integrity or reCAPTCHA. It contains no profile information.
- **Opting out:** you can limit analytics in your device's settings (for example Android's "Delete advertising ID" or "Usage & diagnostics"). If you want analytics disabled for your account, ask support.

## 21. Data stored on your device, cookies and the web app
- **On your device the app keeps:**
  - your signed-in session (Firebase Authentication);
  - cached copies of screens you've viewed, so the app works on poor connections;
  - a queue of actions waiting for the network (for example a message to resend);
  - your settings (theme) and recent searches.
- **When you sign out, or another account signs in on the same device,** the app removes your sign-in, cached listings, recent searches and any actions still waiting to be sent (an unsent job post is discarded, so make sure you're online before signing out), and push notifications to that device stop. Your theme choice stays because it's a device setting.
- The Firebase database library also keeps its own offline copy of data you viewed, inside the app's private storage. It is removed when you clear the app's data or uninstall the app. On a shared device, clear the app's data after signing out.
- **Web app:** uses your browser's storage (IndexedDB and local storage) for the same purposes. Firebase Analytics on the web may set analytics cookies. **There are no advertising cookies or third-party trackers.**

## 22. Staff access, moderation and reports
- **What staff can do:** read private accounts, contracts, chats, ID documents and verification sessions **only when needed** to review verification, handle reports and disputes, prevent fraud, or meet legal obligations.
- **Audit:** staff actions in the admin website are recorded in an audit log (who, what, when, and the reason).
- **Limits:** staff can suspend accounts, but can't set an identity-verification result.
- **Reporting a user:** the reported person isn't told who reported them.

## 23. Children
SkillBridge is for adults. **You must be at least 18** to create an account, because using it involves contracts, payments and visits to homes. We don't knowingly collect data from children. If you believe a child has an account, contact us and we'll delete it.

## 24. Your responsibilities toward other people's data
- Use other users' contact details, addresses and locations only for the job you're doing together.
- Don't copy, publish or misuse other people's information, messages or photos.
- Don't upload photos of other people, documents or private spaces without their permission.
- Workers visiting a home must respect the client's privacy and property.

Misuse can lead to suspension and may be reported to authorities.

## 25. Security incidents
If a security incident affects your personal data, we will:
- investigate and contain it;
- tell affected users without undue delay, saying what happened, what data was involved, and what to do;
- notify authorities where the law requires.

## 26. Links and other apps
Opening directions in the Google Maps app, emailing support, or opening WhatsApp takes you to services with their own privacy policies. We're not responsible for their practices.

## 27. Changes to this policy
When we change this policy, we update the version and effective date at the top. For important changes, such as new data use or new sharing, we'll tell you in the app before they take effect and ask for consent again where needed. The in-app policy always shows the current version.

## 28. Contact us
Questions, requests and complaints about privacy:
- **In the app:** Settings → Help & legal → Customer support (email or WhatsApp).
- **Email:** aqibk1051@gmail.com (subject line "Privacy request").

We reply within 30 days. To protect your account, we may ask you to confirm your identity first.

---

## Appendix A: Data inventory
| Data | Stored in | Read by | Changed by | Kept until |
|---|---|---|---|---|
| Sign-in (email, password hash, Google link, phone) | Firebase Authentication | the system | you, Firebase | account deletion |
| Private account | Firestore `users/{uid}` | you, staff | you (except protected fields), trusted functions, staff | account deletion |
| Public profile | Firestore `publicProfiles/{uid}` | signed-in users | your app (checked by rules) | account deletion |
| Saved jobs | `users/{uid}/savedJobs` | you | you | you remove them, or account deletion |
| Notification preferences | `users/{uid}.notificationPrefs` | you, staff, push function | you | account deletion |
| ID verification submission | `users/{uid}/private/verification` | you, staff | you (pending only), staff | account deletion |
| ID documents | `users/{uid}/verificationDocs` | you, staff | you add/remove; staff | account deletion |
| Identity verification sessions | `identityVerifications/{id}` (+ `events`) | you, staff (events: staff) | trusted functions only | account deletion |
| CNIC uniqueness index, provider refs, key | `identityCnicIndex`, `identityTransactions`, `serverSecrets` | no user or staff app access | trusted functions only | account deletion (key: kept) |
| Jobs | `jobs/{id}` | signed-in users | the client | kept; anonymised on deletion |
| Proposals | `proposals/{id}` | the worker, the client | the worker, the client (accept/reject) | kept; anonymised on deletion |
| Contracts and steps | `contracts/{id}` (+ `updates`, `submissions`) | contract parties, staff | contract parties, by the rules' step order | kept; anonymised on deletion |
| Evidence photos | `contracts/{id}/evidence`, Storage `contracts/{id}/evidence` | contract parties, staff | the worker (create), staff | kept with the contract |
| Live location | `contracts/{id}/live/location` | contract parties, staff | the worker | deleted when the stage ends |
| Chats and messages | `chats/{id}` (+ `messages`, `media`), Storage `chats/{id}/…` | the two members | the members | kept; anonymised on deletion |
| Reviews | `reviews/{id}` | signed-in users | the reviewer (once) | kept; anonymised on deletion |
| Rating summary | `ratings/{uid}` | signed-in users | review transactions | account deletion |
| Notifications | `notifications/{id}` | the recipient | the sender's action; trusted function; recipient (read/delete) | recipient deletes, or account deletion |
| Push tokens | `fcmTokens/{uid}` | push function | your devices | sign-out, invalid token, or account deletion |
| Maps usage counters | `mapsUsage/{uid}` | server only | maps functions | account deletion |
| Reports | `reports/{id}` | the reporter, staff | the reporter (create), staff | handled, then deleted by staff |
| Categories | `categories/{id}` | everyone signed in | staff | n/a (not personal data) |
| Profile, job, portfolio photos | Storage `users/{uid}/…`, `jobs/{id}/…` | anyone with the link | the owner | owner deletes, or account deletion (user folder) |
| Analytics events | Google Analytics for Firebase | project owners | — | Firebase retention setting |
| Crash reports | Firebase Crashlytics | project owners | — | Firebase retention setting |
| Staff audit log | `auditLogs` (admin website) | staff | the admin website | kept for accountability |
| Device cache and queued actions | Hive boxes on your device | you | the app | sign-out or account switch; clear data; uninstall |
| Firebase database offline copy | app-private storage on your device | the app | the Firebase SDK | clear data; uninstall |

## Appendix B: What happens to each kind of data when you delete your account
| Data | Result |
|---|---|
| Sign-in account | deleted |
| Private account and protected fields | deleted |
| Public profile | deleted |
| Saved jobs, notification preferences | deleted |
| ID verification submission and ID documents | deleted |
| Identity verification sessions, audit events, CNIC index entry, provider refs | deleted |
| Notifications addressed to you | deleted |
| Push tokens | deleted |
| Live location | deleted |
| Rating summary | deleted |
| Maps usage counters | deleted |
| Your photos under your Storage folder | deleted |
| Your open jobs | cancelled ("account deleted"); name and photo removed |
| Your pending proposals | withdrawn; name and photo removed |
| Your contracts (none may be active) | kept for the other party; name and photo removed |
| Reviews you wrote or received | kept; name and photo removed |
| Chats | kept for the other member; your name and photo removed |
| Reports you made or that concern you | kept by staff as long as needed for safety, then deleted |
| Analytics and crash data | deleted by Google on its retention schedule |
| Data on your device | sign-in, cached listings, recent searches and unsent actions removed when you sign out; the database library's offline copy when you clear the app's data or uninstall |

## Appendix C: A–Z index of policies
| Topic | Section |
|---|---|
| **A**ccount creation and sign-in | [4.1](#41-account-and-sign-in) |
| **A**ccount deletion | [12](#12-deleting-your-account), [Appendix B](#appendix-b-what-happens-to-each-kind-of-data-when-you-delete-your-account) |
| **A**dvertising (none) | [3](#3-summary-at-a-glance), [5](#5-how-we-use-information) |
| **A**nalytics | [20](#20-analytics-crash-reports-and-app-integrity) |
| **A**pp Check / app integrity | [20](#20-analytics-crash-reports-and-app-integrity) |
| **A**udit logs | [10](#10-how-we-protect-information), [22](#22-staff-access-moderation-and-reports) |
| **B**ackground location (not used) | [4.13](#413-what-we-do-not-collect), [14](#14-device-permissions) |
| **B**iometrics (never stored) | [16](#16-identity-verification-in-detail) |
| **B**reach notification | [25](#25-security-incidents) |
| **C**amera and photos permission | [14](#14-device-permissions) |
| **C**hat messages | [4.5](#45-messages), [17](#17-messages-photos-and-files) |
| **C**hildren | [23](#23-children) |
| **C**NIC | [4.8](#48-identity-verification), [16](#16-identity-verification-in-detail) |
| **C**onsent and withdrawing it | [6](#6-why-we-are-allowed-to-use-it-legal-bases), [13](#13-your-rights-and-choices) |
| **C**ontact | [28](#28-contact-us) |
| **C**ontracts | [4.4](#44-jobs-proposals-and-contracts) |
| **C**ookies | [21](#21-data-stored-on-your-device-cookies-and-the-web-app) |
| **C**rash reports | [20](#20-analytics-crash-reports-and-app-integrity) |
| **D**ata controller | [1](#1-who-we-are) |
| **D**ata inventory | [Appendix A](#appendix-a-data-inventory) |
| **D**evice storage / offline cache | [21](#21-data-stored-on-your-device-cookies-and-the-web-app) |
| **D**irections (Google Maps app) | [15](#15-location-in-detail), [26](#26-links-and-other-apps) |
| **D**isclosure to authorities | [8](#8-service-providers-and-other-sharing) |
| **E**mails | [18](#18-notifications-and-emails) |
| **E**ncryption | [10](#10-how-we-protect-information) |
| **E**xport (copy of your data) | [13](#13-your-rights-and-choices) |
| **F**ingerprints | [16](#16-identity-verification-in-detail) |
| **F**irebase | [8](#8-service-providers-and-other-sharing) |
| **G**oogle Maps Platform | [8](#8-service-providers-and-other-sharing), [15](#15-location-in-detail) |
| **G**oogle Sign-In | [4.1](#41-account-and-sign-in) |
| **I**D document review | [16](#16-identity-verification-in-detail) |
| **I**nternational transfers | [9](#9-international-transfers) |
| **J**obs | [4.4](#44-jobs-proposals-and-contracts) |
| **L**egal bases | [6](#6-why-we-are-allowed-to-use-it-legal-bases) |
| **L**ive location | [15](#15-location-in-detail) |
| **L**ocation (all) | [4.3](#43-location), [15](#15-location-in-detail) |
| **L**ogs | [10](#10-how-we-protect-information) |
| **M**arketing (none) | [18](#18-notifications-and-emails) |
| **M**oderation | [22](#22-staff-access-moderation-and-reports) |
| **N**ADRA | [16](#16-identity-verification-in-detail) |
| **N**otifications and push | [4.9](#49-notifications), [18](#18-notifications-and-emails) |
| **O**ther users' data, your duties | [24](#24-your-responsibilities-toward-other-peoples-data) |
| **P**asswords | [4.1](#41-account-and-sign-in) |
| **P**ayments | [19](#19-payments) |
| **P**ermissions | [14](#14-device-permissions) |
| **P**hotos and files | [4.7](#47-photos-and-files-you-upload), [17](#17-messages-photos-and-files) |
| **P**olicy changes | [27](#27-changes-to-this-policy) |
| **P**ublic profile | [7](#7-who-can-see-your-information-inside-skillbridge) |
| **P**urposes of use | [5](#5-how-we-use-information) |
| **R**eports about users | [4.10](#410-reports-and-support), [22](#22-staff-access-moderation-and-reports) |
| **R**etention | [11](#11-how-long-we-keep-information) |
| **R**eviews and ratings | [4.6](#46-reviews-and-ratings) |
| **R**ights | [13](#13-your-rights-and-choices) |
| **S**ale of data (never) | [8](#8-service-providers-and-other-sharing) |
| **S**ecurity | [10](#10-how-we-protect-information) |
| **S**ervice providers | [8](#8-service-providers-and-other-sharing) |
| **S**MS codes | [18](#18-notifications-and-emails) |
| **S**taff access | [22](#22-staff-access-moderation-and-reports) |
| **S**upport requests | [4.10](#410-reports-and-support), [28](#28-contact-us) |
| **T**hird-party apps and links | [26](#26-links-and-other-apps) |
| **U**sage data | [4.11](#411-device-usage-and-diagnostic-information) |
| **V**erification badges | [16](#16-identity-verification-in-detail) |
| **V**isibility (who sees what) | [7](#7-who-can-see-your-information-inside-skillbridge) |
| **W**eb app | [21](#21-data-stored-on-your-device-cookies-and-the-web-app) |
| **W**hatsApp support | [8](#8-service-providers-and-other-sharing), [28](#28-contact-us) |

## Appendix D: Feature status and items to confirm before public launch
**Built but not live in production yet** (they need the Blaze plan, then Cloud Functions, Storage and rules deployed). This policy already describes how each one works:
- account deletion;
- photo uploads to Cloud Storage;
- push notifications and server-checked notification text;
- routes, address search and reverse geocoding.

**Not active:** NADRA fingerprint verification (no NADRA access).

**Before a public launch:**
1. Have a lawyer review this policy, the Terms & Conditions and the consent texts.
2. Publish this policy at a public URL. Google Play requires one in the store listing, along with an account-deletion URL.
3. Fill in Google Play's Data safety form to match sections 4, 8 and 11 (data collected, shared, encrypted in transit, deletable).
4. Set and record the Firebase Analytics data-retention period, and decide whether to offer an in-app analytics opt-out.
5. Set a retention period for staff-reviewed ID documents and for reports.
6. If NADRA access is granted, add NADRA's required retention, security terms and any extra disclosures to section 16, and update the consent version.
7. Enable App Check enforcement once genuine app traffic is confirmed.
8. Translate the in-app policy into Urdu when the app's Urdu language is switched on.
9. Decide whether to also wipe the Firebase database library's offline copy on sign-out (it needs the database connection to be shut down and restarted).
