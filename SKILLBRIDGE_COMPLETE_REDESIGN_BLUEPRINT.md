# SkillBridge — Complete Redesign Blueprint

**Prepared:** 5 November 2026 | **Scope:** Source-based reassessment of Flutter, Next.js admin, and Firebase | **Status:** Planning only; no application source, Firebase data, dependencies, routes, or deployed services were changed.

> **Audit boundary:** Repository/source audit only; not a rendered-device usability study. Inspected navigation, screens, shared widgets, providers/data sources/models, Firebase rules/functions, admin routes/services, project notes, and test inventory. Did not run app/tests, access production Firebase, or inspect device screenshots. Visual findings relate to patterns visible in source; validate clipping, spacing, contrast, and device behavior in later visual QA.

## Executive assessment

SkillBridge has a substantial two-sided marketplace foundation: role-based mobile shells; worker search/profile/map discovery; job posting, direct requests, proposals, contracts, chat, reviews, notifications, offline outbox/cache; English/Urdu translation resources; and a separate Next.js admin console for dashboard, users, workers, jobs, reports, audit and settings. Preserve those capabilities and Flutter + Next.js + Firebase.

The main problem is not a shortage of screens. Workflow/status semantics conflict across sources, localization is forced to English despite Urdu resources, design tokens vary across app surfaces, and Firestore rules allow broad reads and updates of sensitive marketplace data. The console also overstates some behavior (“Live Feed” backed by a limited server snapshot). Make behavior and access dependable first, then redesign shared patterns and connected journeys.

## 1. Current product and architecture

- **Flutter:** `lib/`; feature-based presentation, Riverpod providers/view models, domain entities, Firestore models/data sources; shared widgets in `lib/shared/widgets`.
- **Setup/navigation:** `lib/main.dart`, `lib/app.dart`, `lib/config/router/app_router.dart`, `route_names.dart`. Firebase/App Check, Hive, offline cache/outbox, analytics/crash reporting and notifications initialize at startup. Client shell has Home/Jobs/Chats/Profile; worker shell Home/Proposals/Contracts/Chats/Profile; extra routes cover auth, settings, job/proposal details, notification, map discovery, checkout status, reviews, terms and mobile admin. Redirects use authenticated Firestore-backed role, activity and profile-complete state.
- **Backend:** root Firebase config, Firestore/Storage rules, indexes and `functions/src`. Most mobile features flow presentation → provider → data source/model → Firestore. Jobs/chat have outbox paths; offline behavior is not uniform across other writes. Maps/Places/Routes use shared services/geolocation utilities.
- **Web admin:** `super_admin_web` Next.js App Router. Layout verifies HTTP-only Firebase session via `getAdminSession`; privileged API routes generally verify claims. Dashboard/operations use Firebase Admin. Mobile in-app admin (`lib/features/admin`) is a second surface and overlaps in users/jobs/verification.
- **Existing tests:** unit, widget, integration coverage under `test/`, including booking, outbox, localization, maps/tracking and shared widgets. This document recommends further testing but does not add or run tests.

### Data connections

| Record | Role in product flow |
|---|---|
| `users` + nested `workerProfile` | Auth/profile/role/activity/verification/rating/location; redirects, directory, discovery and admin. |
| `jobs` | Client request, category/budget/urgency/location/status; client list, worker discovery/direct request, proposals and admin. |
| `proposals` | Worker offer linked to job/client; acceptance leads to contract/job updates and notification. |
| `contracts` | Parties, agreed amount/commission, payment state, schedule/status/review eligibility; contract lists, chat/completion/reviews/admin metrics. |
| `chats/messages` | Participant conversation, optional job context, unread/last-message state. |
| `reviews` | Contract/job bilateral review; Cloud Function recalculates public rating aggregates. |
| `notifications` + FCM | In-app/push notices connect domain events to users and deep links. |
| `reports` / `auditLogs` | User reports, admin moderation and traceable privileged actions. |
| Storage | Profile/work/job imagery and private verification docs, with separate rules paths. |
| Cloud Functions | New-user default role/claim/profile, notification FCM, review rating aggregate. |

## 2. Critical findings before visual redesign

### P0 — Trust, permissions and integrity

1. **Broad Firestore reads:** any authenticated user can read all `users`, `jobs`, and `proposals`. User docs may carry CNIC/profile information and jobs carry precise location. Revisit least-privilege access/field separation before claiming privacy. Plan compatible rules and query changes; do not casually migrate collections.
2. **Broad writes:** qualifying job/proposal users can change arbitrary fields; contract participants can change most contract fields as long as `paymentStatus` is unchanged. Any authenticated user can create a notification for arbitrary `userId`, enabling spoofed in-app/push notices. Restrict changed keys and valid transitions; make privileged/financial transitions server-authoritative.
3. **Role split:** mobile routing reads Firestore user role; admin rules check custom claims; `onUserCreated` sets default client claim/profile. Separate user role selection from admin claims and define suspension/role sync end-to-end.
4. **Worker verification divergence:** web API updates only `workerProfile.isVerified`; mobile admin updates `isVerified`, `verificationStatus`, and `verifiedAt`. Use one authorized action and aligned audit trail.
5. **Hire state complexity:** proposal acceptance, contract creation, direct hire and worker accept/reject touch multiple records. Define one canonical transition table and atomic writes; handle duplicate acceptance/races and ensure job/contract states agree.
6. **Payment unavailable:** `EasyPaisaCheckoutScreen` says payment is unavailable and no payment was taken; contract stores `paymentProviderState: not_configured`. Do not style this as checkout success. Keep booking and payment states distinct until provider integration.
7. **Deletion semantics:** web API deletes Auth account + user document, but related jobs, proposals, contracts, chats, reviews, reports and storage are not visibly cascaded. Decide disable/anonymize/erase policy before presenting delete as routine.
8. **Verification document mismatch:** Storage rules allow verification-document reads only to the owner; admin integration note implies admin access, but rules do not grant that client path. Design a safe server-mediated review path before an evidence-review control.

### P1 — UX credibility and product behavior

- `app.dart` pins locale/supported locales to English; `LanguageNotifier` is no-op English-only despite `app_en.arb`, `app_ur.arb`. Preserve Urdu resources/configuration intent and restore deliberate locale/RTL behavior before claiming bilingual support.
- EasyPaisa is a status placeholder. Worker profile share says “coming soon”; chat voice action reports “voice note sent” via snackbar without audio delivery. Avoid implying nonexistent capability.
- Central themes exist, but `AppColors`, `OutdoorThemeMode`, hardcoded screen colors, custom component styles, and web CSS/Tailwind literals diverge. Consolidate semantic tokens.
- Large home/profile/detail source files indicate dense compositions and mixed responsibilities. Split into reusable sections only after IA approval; preserve providers/actions.
- Admin jobs says “Live Feed” but `getJobs(100)` is a bounded server snapshot filtered client-side. Users/workers are also limited. Add honest freshness/count language and server-side pagination/filtering.
- Dashboard period range filters only some metrics; totals/city/category/recent jobs use different scopes. Label scope. City/category scans whole collections and methods silently fall back to empty/zero on failure; provide error state and scaling plan.
- Reports currently use the real `reports` collection (keep this); audit-log read errors currently resemble an empty ledger. Distinguish unavailable vs empty.
- Mobile and web admin overlap. Define staff capability matrix and one canonical, audited moderation pathway.

## 3. Design direction and system

### A. Philosophy

**“Local expertise, made easier to trust.”** Ground the marketplace in real Pakistan service contexts. Help clients decide with evidence (identity/status, relevant skills, work examples, clear price basis, availability, verified-contract reviews); help workers respond and manage work. Use a warm editorial layer for people/categories and calm operational UI for forms and status. Avoid decorative gradients, oversized KPI cards, and card grids where lists or timelines are clearer.

Directional references, not templates: Thumbtack presents local search → profiles/reviews → chat → hire ([How Thumbtack works](https://www.thumbtack.com/how-it-works)); Airbnb describes profile/identity verification as trust mechanism ([Airbnb verification](https://www.airbnb.com/help/article/3937)). Use adaptive parent navigation and rail at wider app widths ([Android adaptive navigation](https://developer.android.com/design/ui/mobile/guides/layout-and-content/layout-and-nav-patterns)). Target WCAG 2.2 AA for web and comparable mobile inclusion ([WCAG 2.2](https://www.w3.org/TR/WCAG22/)).

### B. Initial brand/design tokens

| Token | Direction | Use |
|---|---|---|
| Primary | Ink blue `#174A8B` | Primary actions, selected nav, links. |
| Accent | Craft amber `#E4A33A` | Small category/highlight/attention accents, never small text on white. |
| Trust success | Teal `#167A63` | Verified/complete, with icon and label. |
| Canvas / surface | Warm off-white `#F7F8F6` / white | Page background / forms and list sections. |
| Text / secondary / border | `#18232F` / `#596779` / `#DCE3E8` | Contrast-tested semantic roles. |
| Error / warning | Accessible dark red / ochre pairs | Destructive/validation/urgent state. |

- **Type:** one readable sans with Latin/Urdu support (e.g., Noto Sans family after rendering validation); semantic display/title/body/label/caption scale and line heights. Verify Urdu shaping, mirrored order and metrics.
- **Space/grid:** 4-point base, 8-point rhythm; 20–24 dp mobile edges, 24–32 px admin; mobile single column, admin 12-column/max-width layout. Tables become readable stacked records at narrow widths.
- **Shape/elevation:** controls 8 dp, cards 12 dp, sheets/dialogs 20 dp; borders group, elevation reserved for overlays.
- **Buttons/forms:** primary/secondary/quiet/destructive hierarchy; one primary per decision area; mobile 48 dp targets, admin practical 40–44 px. Persistent labels, helper/error, correct keyboard/type, Pakistan-aware phone/city/PKR; no placeholder-only labels.
- **Cards/lists:** worker rows prioritize identity, trust/fit, rate basis, distance/availability; jobs show service, location, budget basis, urgency and proposal count. Admin tables prioritize scanning, filters, pagination and row actions.
- **Icons/motion/dark:** consistent Material/Lucide mapping with labels for critical actions; short purposeful motion, reduced-motion support. Apply semantic tokens fully to light/dark (web currently declares dark variables but screens are mostly light literals).

## 4. Information architecture and user journeys

### G. Mobile navigation

**Client:** Home/Find workers → My jobs → Chats → Profile; global notifications in app bar. Home begins with service/location search, categories, nearby/recommended preview and restrained Post Job action. Nearby has map/list and filters; job detail owns applicants/hire decision; contracts own active booking status; chat remains contextual.

**Worker:** Home/Find work → Proposals → Contracts → Chats → Profile; notifications global. Home prioritizes availability/profile completeness, relevant open jobs and direct requests, with distinct “respond” vs “apply”. Settings/setup secondary. Preserve indexed-stack state/deep links; use rail/expanded layout at tablet widths.

### F. Admin web

Desktop sidebar and mobile drawer; header exposes current section, identity, account actions. Overview; Users; Worker verification; Jobs & contracts; Reports & disputes; Audit log; Settings/security. Make detail views directly linkable/history-friendly, not modal-only. URL-backed filters/pagination. Distinguish account settings from platform settings.

### D. Client journey

1. Splash → sign in/up → client role → optional phone verification; explain role and verification steps, retain Firebase/email/Google/OTP/reset.
2. Home search/category/location → nearby list/map + filters → worker profile with trust/rates/service area/reviews/privacy-safe location → contact or booking request.
3. Post-job guided form: category/scope/photos → location/time → budget → review → submit; preserve form on recoverable failure; acknowledge queued offline state.
4. Job detail/applicants → compare proposal scope/rate/duration/profile → accept with explicit terms, stale-state handling and confirmation.
5. Contract timeline → contextual chat/schedule/address → completion/OTP where implemented → payment status honestly unconfigured → eligible review once per contract.

### E. Worker journey

1. Signup → worker role → profile setup (headline, bio, category/skills/rates/service area/experience/portfolio) → preview/completeness → verification state.
2. Home feed/direct requests → filter/detail → submit proposal (cover note/rate basis/duration) or accept/decline; guard stale/closed job and confirm submission.
3. Proposal/contract list → accepted contract timeline → chat/schedule/location/status/completion; distinguish pending decision, accepted, in progress, completed and unpaid/not configured.
4. Profile/reviews/replies, availability, earnings only if backed by data, notification/privacy/language/theme settings, support and sign-out.

## 5. Screen-by-screen strategy

“Exists” means source route/screen or relevant implementation exists, not that all backend behavior is proven. Preserve every implemented action/data path unless separately approved.

### Mobile

| Screen family | Present / weakness | Redesign hierarchy and behavior; preserve |
|---|---|---|
| Splash, login, signup, role, OTP, reset | Auth routes/providers for Firebase email/Google, role, OTP/reset; localization/role state clarity gaps. | Quiet branded entry, one form/action per step, progress/field errors, accessible OTP/password, explain role and phone requirements. Preserve auth/routes. |
| Client home | Large home with marketplace sections; risk of competing cards/long scroll. | Search/location first, category shortcuts, trusted worker preview, job state, one Post Job CTA; new-user/empty state. Preserve providers/links. |
| Client jobs | Job list/status/actions; needs clearer status-specific tasks. | Open/Assigned/Completed/Closed tabs, concise rows, proposal count, timeline and contextual detail/applicant CTA. Preserve stream/actions. |
| Post job | Category, scope/budget/date/location/images and optional direct worker. | Guided service → scope → place/time → budget → review; pin/address summary, validation, form retention, offline queued acknowledgment. Preserve `PostJobScreen` and outbox. |
| Job detail | Shared role-specific details/actions, proposals/direct requests. | Title/status/location/budget, scope/photos, timeline, then role-specific actions; stale-state guard and location privacy. Preserve role actions. |
| Nearby workers | Map pins/search/filter and maps services; permission/network fallback to improve. | Search/filter; list-first fallback; map/list toggle; selected-worker preview; approximate public location. Handle denied GPS/manual pin/offline/no results. Preserve matching/privacy. |
| Public worker profile | Profile, ratings, direct booking/report/contact; share unavailable. | Identity/trust evidence, services/rate/availability, work examples, verified-contract reviews, area, persistent CTA. Do not imply share works; preserve report/contact/booking. |
| Client profile/settings | Profile/settings, language/theme/support; locale no-op. | Profile completion/edit sections; settings grouped account/privacy/location/language/appearance/notifications/support/legal. Preserve updates; restore functional locale before language control. |
| Worker home | Job feed/direct actions/earnings chart. | Availability/profile cue, direct requests with response actions, matching jobs, active contract and backed earnings only. Preserve streams/chart data. |
| Worker setup/profile | Large forms/profile; clarity on saved/verified states. | Previewable profile, category/skills/rates/area/experience/portfolio, verification explanation, save draft/validation. Preserve nested fields/uploads. |
| Proposals/details/applicants | Worker proposal list/details; client applicant management embedded in job details. | Status tabs; quote/rate basis/duration/date; consistent comparison cards, profile evidence, accept/decline confirmation and updated state. Preserve proposal stream/acceptance/notifications. |
| Contracts | Worker destination; client path through booking/job flow. | Shared timeline: parties/scope/amount/schedule/address/privacy/chat/payment state; align status vocabulary. Preserve contract provider. |
| Chat list/room | Realtime text/image/unread/context; voice action is false success. | Last activity/unread list; job context; composer with delivery/error/offline status. Remove false voice success; preserve participant-scoped chat and outbox. |
| Notifications | In-app list + push. | Recent/unread grouping, deep links, permission opt-in/denied, stale payload fallback. Preserve FCM/Firestore read state. |
| Review | Contract-linked review and aggregation. | Eligibility context, rating/narrative/photos, verified marker, submit/retry; one per eligible contract/party. Preserve stable review ID/rules/function. |
| EasyPaisa status | Explicitly says unavailable/no payment taken. | Honest not-configured state, booking reference and next step/support if backed; no fake checkout. Preserve no-charge guarantee. |
| Settings, terms, shared location picker | Existing; permission/offline/private location checks outstanding. | Group settings, readable legal, searchable pin/address confirmation and permission/offline help. Preserve routes/coordinates. |
| In-app admin dashboard/users/jobs | Separate Flutter admin surface, overlaps web. | If retained, role-appropriate summary/search/table/detail/loading/error states and audited actions. Decide staff scope; do not silently remove. |

### Admin web

| Screen | Present / weakness | Redesign and preserve |
|---|---|---|
| Login | Email/Google/reset, loading/errors, session API. | Staff identity, accessible focus/keyboard, clear recovery/error; no self-registration. Preserve Firebase auth/session. |
| Dashboard | Real Firestore stats/charts/city/category/recent jobs/queue; card-heavy; metric scopes differ, scans/error fallbacks. | Operational exceptions first, trends with explicit period, queues/recent activity with links; label freshness/scope and errors. Preserve real aggregation, no samples. |
| Users directory/detail | Auth+Firestore merge, client search/actions, detail route; limited first set. | Server search/filter/pagination, role/status, linked detail/audit; safe suspend/restore; decide delete semantics first. Preserve Auth disabled as source of truth. |
| Worker verification | Real list and API; only boolean updated in web. | Pending/verified/follow-up queue, evidence checklist, profile context, reason/time/admin. Align fields/storage access before evidence review. |
| Jobs & contracts | Table/search/status/inspect; only first 100, not live; inspect modal lacks full contract operations. | Paged workspace with status/city/amount basis/proposals/parties/timeline and safe moderation; honest refresh. Preserve records. |
| Reports | Real queue, search/status, notes/status API + audit transaction. | Queue/age, detail/reporter/target/reason/history, allowed transitions, save/error; preserve records/audit. |
| Audit log | Latest 50 entries; failure appears empty. | Filter/search actor/action/target/reason/time, detail/export; distinguish loading/empty/permission/failure. Preserve server-authoritative append-only intent. |
| Settings | Admin email/UID/role, account/security. | Session/security/help/role; keep platform configuration separate and restricted. Preserve identity. |

## 6. Component and interaction strategy

### I. Reusable components

**Mobile:** page scaffold/safe-area frame; semantic buttons/fields/selects/status badges/filter chips/avatars/image frames; section heading/list row; empty/error/offline/retry/skeleton; confirmation sheet/toast/status announcement. Marketplace patterns: WorkerCard, JobCard, ProposalSummary, ContractTimeline, ReviewItem, NotificationRow, LocationSummary, PriceRange, TrustBadge. Existing `app_*`, job card, shimmer, empty/error, connectivity and location widgets are starting points. Audit duplicates (`app_shimmer_card`/`shimmer_loading_card`; `app_empty_state`/`empty_state_card`) before adding more.

**Admin:** page header/breadcrumb; URL-backed filter bar; meaningful KPI; responsive table/pagination; badge; detail panel/page; confirmation; toast; audit detail. Existing shell/sidebar/header, shadcn-style UI, charts/table/toast are a base; align literals with semantic CSS tokens.

### J. Interaction and animation

Every action needs precondition, disabled/progress/result/retry policy. Confirm hire/report resolve/suspend/delete/verify/end contract. Keep job→proposal→contract→chat context visible; deep links handle missing/inaccessible/stale records. Snackbars supplement—not replace—field validation and persistent state. Preserve form input on recoverable failures. Short state/route motion only, reduced motion honored.

### K. Responsive behavior

- **<600 dp:** single column, bottom navigation, sticky CTA only when it does not obscure content, short contextual sheets, list-first maps.
- **600–1023 dp:** navigation rail, centered wider forms, readable two-column discovery only when usable.
- **≥1024 dp:** responsive detail/context columns; admin sidebar + 12-column/max-width grid; table or stacked record at narrow view. Never stretch forms across full viewport.
- Validate landscape/short height, small Android, tablets, browser zoom, keyboard and safe areas; app allows landscape.

### L. Loading, empty, success, error

- Loading skeletons match content; keep prior data on refresh; label refresh when useful.
- Empty state explains why and one relevant next action. Separate zero data from chart failure.
- Success confirms the domain event and next step; queued offline ≠ server confirmed.
- Errors: inline field validation, network retry preserving input, permission/help, stale conflict refresh, backend unavailable separate from empty. Never show raw exception strings.
- Offline cache reads; queue only safe/idempotent writes. Do not queue financial/admin transitions without server authority.

### M. Accessibility

Target WCAG 2.2 AA web and analogous Flutter accessibility: 4.5:1 normal text contrast (3:1 large); no color-only states; keyboard and visible focus; meaningful icon/chart labels; heading order; async announcements; target size at least 24×24 CSS px under WCAG exceptions (prefer 44–48 px practical touch); reduced motion, scalable text, no clipping. See https://www.w3.org/TR/WCAG22/. Flutter currently clamps OS text scale to 1.2; test larger settings and avoid dependence on clamping. Urdu RTL needs reading/focus order validation. Charts need textual/table summaries.

## 7. Preservation checklist (N)

- [ ] Email/Google auth, register, role, OTP/reset/sign-out, active/suspended and worker-complete redirects.
- [ ] Client/worker indexed nav, deep links/back-stack.
- [ ] Worker profile/setup, skills/rates/area/images, location privacy and verification status.
- [ ] Job create/update/list/direct request/discovery/location/category, offline outbox/sync indicator.
- [ ] Proposal submit/list/details/applicant review/accept/reject and aligned job/contract state.
- [ ] Contract list/detail/schedule/location/status/completion/OTP where implemented; payment explicitly unconfigured.
- [ ] Chat participant access, text/images/unread/read/order/offline failure; notifications/FCM/read/deep links.
- [ ] Eligible bilateral reviews, verified-customer rule, replies, rating aggregation.
- [ ] Map/list discovery, picker/geocoding, GPS fallback, privacy-safe location/tracking/routes.
- [ ] English + Urdu resources/config, theme modes, support/legal/terms, connectivity, analytics/crash reporting.
- [ ] Admin sessions/claims/RBAC, users/workers/jobs/reports/audit/export/settings; Storage privacy, indexes, paths/statuses, generated l10n and existing test intent.

## 8. Technical dependencies and constraints

Keep Flutter/Next.js/Firebase; no schema migration assumed. Inventory fields/statuses and write compatibility matrix first; propose schema only if rules cannot safely support behavior. Create canonical job/proposal/contract/review/payment transition table aligned across enums, strings, UI, rules and APIs. Treat auth, PII, location precision, verification docs, deletion and payment as product/security requirements. Use server authority for atomic/privileged transitions.

Validate rules with Emulator/security tests before rollout; never deploy rules/functions in redesign phase. Preserve indexes; add only for concrete server-side filters/pagination. Bound dashboard queries as data grows. Preserve Urdu resources; decide locale, RTL/font/date/currency conventions before locale UI. Keep session verification in layouts/APIs; proxy cookie check is only a fast redirect. Never expose `.env` values. Maps checklist still has key rotation/restriction and physical/offline tests outstanding.

## 9. Implementation roadmap and order

| Phase | Work | Dependency / exit gate |
|---|---|---|
| 0. State/security contract | Field/status inventory, role matrix, job/proposal/contract/payment transitions, delete/verification policies; rules plan. | Before UI implies hire/payment/verification/moderation; emulator coverage before rules rollout. |
| 1. Design foundation | Approve brand/tokens, typography, components, accessibility and locale; prototype representative patterns. | Before screen-by-screen polish. |
| 2. Auth/profiles | Auth, role/OTP/reset, client/worker profile/setup/settings/location. | Depends on role, locale, profile field and privacy contract. |
| 3. Discovery/request | Home, search/map/list, public profile, post job, worker feed/direct requests. | Depends on profile/location/job queries and privacy. |
| 4. Decision loop | Job/applicants, proposal, acceptance, contract, chat/notifications. | Depends on canonical state + atomic permission design. |
| 5. Completion/reputation | Timeline/OTP, truthful payment status, reviews/replies, reports/support. | Depends on contract state/provider decision. |
| 6. Admin operations | Dashboard, users/detail, verification, jobs/contracts, reports, audit, settings. | Depends on role/RBAC/audited APIs and paged data. |
| 7. Stabilization | Responsive, RTL, accessibility, offline, rules emulator, device and performance regression. | Release gate; no Firebase deploy without separate authorization. |

**Recommended redesign order:** 1) state/role/privacy/security; 2) design tokens/components; 3) auth/profiles; 4) discovery/profile/job create; 5) applicants/proposal/contract/chat/notifications; 6) completion/reviews/payment truth; 7) admin; 8) global responsive/accessibility polish.

### Screen dependencies

Profile setup → worker profile/directory → proposal quality. Location permissions/privacy → map/list → job address → contract navigation. Job → worker feed → proposal → compare → accept → contract → chat/notification → completion → review/rating. Direct hire must converge on same contract states. Admin session/RBAC → all admin reads/actions; secure verification access → worker review; report action → audit event; deletion policy → Auth and dependent records. Payment provider readiness → only then payment/receipt/paid labels.

## 10. Testing and release quality strategy

Planning only; not running/adding tests now.

1. **Models/states:** legacy/null fields, serialization/timestamps, rate units, transition validity, duplicate review, locale/currency/RTL.
2. **Widgets:** buttons/forms/cards/filters/dialogs/loading/empty/error/offline, large text, keyboard, semantics, light/dark and representative sizes.
3. **Journeys:** client signup→discover→post→worker proposal→accept→contract/chat→complete→mutual review; direct-hire path; duplicate/race/stale job cases.
4. **Security (Firebase Emulator):** anonymous/client/worker/admin/super-admin access; cross-party reads/writes; notification spoof; protected payment/contract fields; verification docs; location privacy; suspension/session revoke.
5. **Admin:** pagination/filter, empty vs failure, report+audit transaction, verify field consistency, suspend/restore/delete policy, safe CSV export, responsive tables.
6. **Platform:** physical map keys, denied GPS/offline/manual pin, weak network/outbox idempotency, push failures, large text/screen reader, keyboard-only web, reduced motion, zoom/breakpoints.
7. **Release gates:** Flutter analyze/build + existing tests and Next lint/build/tests in approved implementation phase; no production rules/functions deployment until emulator/access review passes. Record payment limitation.

## 11. Risks and mitigation

| Risk | Mitigation |
|---|---|
| UI promises action backend cannot safely perform | Trace CTA → provider/API → rule/function → saved state; capability gate. |
| Rules changes break current clients/queries | Inventory + emulator regression + staged compatibility plan. |
| Admin surfaces diverge | Canonical API/role matrix/status maps; audit all privileged actions. |
| Legacy records render incorrectly | Known variants/safe defaults, validation; never invent data. |
| Lose localization/offline/deep links/accessibility | Preservation checklist and explicit Urdu/outbox/routes/semantics tests. |
| Misleading dashboard scope/failure | Label source/period/freshness; separate failure from empty; bound queries. |
| Location/privacy/map outage | Approximate public location; exact only for authorized parties; list/manual/offline fallback; rotate/restrict keys. |
| Payment/verification overclaim | “Not configured/pending”; only confirmed backend state; do not infer verification. |
| Orphaned data on delete | Decide disable/anonymize/erase and dependencies; clear confirmation/audit. |
| Large files slow safe iteration | Approved refactor in vertical slices; keep routes/providers as compatibility boundaries. |

## 12. Critical priorities and approval gate

### Address first

1. Least-privilege Firestore/Storage and constrained field/state mutations.
2. Canonical job/proposal/contract/payment state; atomic acceptance and consistent statuses.
3. Role/custom-claim/session policy and shared admin permissions; audit privileged actions.
4. Align verification fields/document access and account deletion semantics.
5. Restore deliberate localization and privacy-safe map/location states.

### Features never to lose

Auth and role-aware routing; client/worker setup; local discovery in list/map; direct requests and open job posting; proposals/applicant review; contracts/completion; chat/notifications; verified-contract reviews/ratings; location/address/privacy; offline indicators; English/Urdu resources; themes/accessibility; support/legal; admin directory/verification/jobs/reports/audit/security; real Firestore state.

### Approval gate

This is planning only. Review the blueprint and approve phases before any source, Firebase rules/schema, packages, or deployment change. Recommended initial implementation slice: Phase 0 state/security contract + Phase 1 design foundation, then validate one complete client-to-worker booking journey.
