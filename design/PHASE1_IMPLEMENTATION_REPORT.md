# Phase 1 — Design Foundation: Implementation Report

**Date:** 8 November 2026 · **Branch:** `ui-improvements-2026` · **Status:** complete, awaiting approval before Phase 2.

## Summary

Phase 1 adds one design system for the Flutter app and the Next.js admin, plus reviewed prototypes of five representative screens. Everything is **additive**: no existing screen, provider, route, Firestore query, rule, function, ARB file or dependency was changed, and nothing was deployed. The only edit to an existing file is one `@import` line in `super_admin_web/src/app/globals.css`, which defines new `sb-*` tokens without changing any current colours.

The full specification is in [`SKILLBRIDGE_DESIGN_FOUNDATION.md`](SKILLBRIDGE_DESIGN_FOUNDATION.md).

## What I found in the current code

| Area | Finding | Effect |
|---|---|---|
| Flutter colour | Three colour sources: `AppColors` ("Guild Modernist" blue `#003FB1`), `OutdoorThemeColors`, plus 94 hardcoded `Color(0x…)` literals in screens; ~440 `AppColors.*` call sites | Inconsistent blues/greens across screens; dark mode only partly applied |
| Flutter widgets | `EmptyStateCard` and `ShimmerLoadingCard` hardcode `AppColors.darkCard`, so they render dark in light mode; two empty-state widgets and two shimmer widgets duplicate each other | Visual bugs and duplication |
| Flutter type | Three fonts (Sora, Inter, JetBrains Mono), none with Urdu glyphs | Urdu falls back to a system font with unpredictable metrics |
| Localization | `app.dart` pins `Locale('en')`; `LanguageNotifier` and `AppL10n` are English-only no-ops; `app_ur.arb` is intact | Urdu resources exist but can't be reached |
| Admin web | shadcn variables exist, but screens use `#2F80ED` literals (37×) and ~400 Tailwind palette classes; `.dark` variables are effectively unused | Admin brand differs from app; dark mode not real |
| Admin honesty | Dashboard metric scopes differ without labels; failed queries can show as 0 / empty | Covered by `Kpi(scope, unavailable)`, `FreshnessNote`, `DataState error` |

## What was built

### Single source of truth
- `design/tokens/skillbridge.tokens.json` — brand, colour (light/dark/category), type scale incl. Urdu adjustments, spacing, layout/breakpoints, radius, border, elevation, motion, target sizes, icon sizes.
- `design/tools/check-contrast.mjs` — checks 62 text/background and UI pairings against WCAG 2.2 AA. **It caught one real issue during the work:** input borders at `#B4C0CA` were 1.85:1; a dedicated `borderInput` token (`#7D8995`, 3.6:1) fixed it without darkening dividers. Now all pairings pass.

### Flutter (new files only)
- `lib/config/theme/sb/sb_tokens.dart` — `SbBrand`, `SbColors` (a `ThemeExtension`, read with `context.sb`), `SbTone`, `SbCategoryTone` (English + Urdu category matching), `SbSpace`, `SbRadius`, `SbElevation`, `SbMotion` (reduced-motion aware), `SbTarget`, `SbWindowSize`, `SbLayout`.
- `lib/config/theme/sb/sb_typography.dart` — Noto Sans + Noto Nastaliq Urdu with mutual fallback, Urdu size/line-height/tracking rules, tabular numerals.
- `lib/config/theme/sb/sb_theme.dart` — complete light and dark Material 3 themes (buttons, inputs, chips, navigation bar/rail, tabs, list tiles, sheets, dialogs, snackbars, progress, switch, checkbox, radio, tooltip).
- `lib/shared/design_system/` — `SbButton`, `SbStatusBadge`, `SbTextField`, `SbWorkerCard`, `SbJobCard`, `SbAvatar`, `SbSectionHeader`, `SbStateView`, `SbInlineBanner`, `SbSkeleton`, `SbListRowSkeleton`, `SbAdaptiveScaffold`, `SbReadableWidth`, `showSbConfirmSheet`, and the `design_system.dart` barrel.
- `test/widget/design_system_test.dart` — 13 tests.

Components accept already-localized strings and hide every optional field that is null, so they cannot introduce placeholder data.

### Admin web (new files + one import)
- `super_admin_web/src/styles/sb-tokens.css` — same tokens as CSS variables (light + `.dark`), exposed as Tailwind utilities (`bg-sb-surface`, `text-sb-on-success-subtle`, `rounded-sb-card`…), focus ring, Urdu `[lang="ur"]` rules, tabular numerals, reduced motion.
- `super_admin_web/src/components/sb/` — `PageHeader`, `FreshnessNote`, `Kpi`, `StatusBadge`/`StatusDot`/`statusTone`, `DataState`, `TableSkeleton`, `RecordTable`, `SbButton`.
- `globals.css` — one added line: `@import "../styles/sb-tokens.css";`.

### Prototypes and screenshots
`design/prototypes/` (static HTML using the same tokens and component anatomy) and `design/prototypes/screenshots/`:

| File | Shows |
|---|---|
| `0-foundation.png` | Palette with contrast ratios, type scale (incl. Urdu), buttons, chips, fields, badges, spacing, shape, breakpoints |
| `1-client-home.png` | Light, dark, and Urdu RTL |
| `2-worker-home.png` | Light and dark |
| `3-worker-profile.png` | Light and dark |
| `4-job-discovery.png` | Light list, dark offline with cached results + queued proposal, loading/empty/error/success states |
| `5-admin-dashboard-light.png`, `-dark.png` | 1440 px desktop |
| `5-admin-dashboard-mobile-tablet.png` | 390 px and 768 px |

Prototype names, amounts and counts are sample layout content and exist only in these HTML files. No sample data was added to the app or admin code.

To view them live, run `npx http-server@14.1.1 design/prototypes -p 4173` (also saved as the `design-prototypes` launch config) and open `http://localhost:4173/client-home.html`. To re-capture, run `bash design/tools/capture.sh <page> <out.png> <w> <h>`.

## Design decisions

1. **Ink blue leads, teal means trust, amber is a highlight.** Primary actions and selection use ink blue. Teal appears only for evidence (verified, available, completed, verified booking). Amber appears on stars, "needs attention" markers and the one soft prompt on client home, and never as small text on white.
2. **Trust order is fixed on every worker surface:** identity → verification → rating with count → completed jobs → rate *with basis* → approximate distance/area → availability. A worker with no reviews shows "New profile · no reviews yet" (Nadia, client home) rather than a 0 or 5 star placeholder.
3. **Client home puts the task first.** Location and search sit above the fold, then eight category shortcuts, then the client's own open job with its proposal count ("3 proposals to review"), because that is usually the next step. The single "Post a job" prompt sits at the end as an alternative, not a banner competing with search.
4. **Worker home separates "respond" from "apply".** Direct requests have Decline / View & respond. Matching open jobs go to proposals. The active contract states "payment not collected in app" to match the `not_configured` payment state. Earnings are labelled "agreed value", because collected payments don't exist yet.
5. **Worker profile protects privacy.** It shows the service area as an approximate zone with "exact location is shared only after you book". Share is omitted because it doesn't work yet, and report sits in the overflow menu. The sticky bar keeps Message (secondary) and Request booking (primary) reachable.
6. **Discovery is list-first with honest states.** The Map view is a toggle. The offline frame shows cached jobs with their save time, disables "Send proposal" with the reason shown, and separates "queued" from "sent".
7. **Admin opens with what needs attention.** Verification queue, reports and disputes come first, then metrics that each state their scope. The city chart says it covers all time. The header reads "Firestore snapshot · loaded 14:02 · Refresh" instead of "Live". "View as table" gives the chart a text alternative.
8. **Borders over shadows, lists over grids.** Cards share one 1 px border and a 12 px radius. Shadows are reserved for sheets and menus. This keeps dense marketplace screens calm and makes dark mode straightforward.
9. **One font family.** Noto Sans and Noto Nastaliq Urdu replace three fonts and actually cover Urdu. Tabular figures replace the monospace font for prices.

## Validation performed

| Check | Result |
|---|---|
| `node design/tools/check-contrast.mjs` | All 62 pairings pass WCAG 2.2 AA (light + dark) |
| `flutter analyze` on new Flutter files and test | No issues |
| `flutter test test/widget/design_system_test.dart` | 13/13 passed: theme extension in both modes, brand values, Urdu metrics, breakpoints, ≥ 48 dp buttons, loading blocks taps, all variants in light and dark, null fields hidden, verified only when labelled, Urdu RTL cards at 320 px with no overflow and a mirrored avatar, distinct empty/error/offline states, bottom bar → rail at 600 dp |
| `tsc --noEmit` (admin) | No errors |
| `eslint src/components/sb` | No errors |
| `next build` (admin) | Succeeds; the `sb-*` tokens appear in the compiled CSS |
| Visual review of every screenshot | Issues found and fixed: frames cut off content, a clipped service-area shape, the admin period selector wrapping, admin overflow at phone width, a cramped sidebar and table at 768 px, and the chart not scaling. The final screenshots reflect the fixes. |

## Not done / limitations

- **Not applied to live screens** (by design for this phase). The app and admin look exactly as before.
- **Urdu is still unreachable in the app.** The design system supports it and was tested in RTL, but enabling it means changing `app.dart`, `LanguageNotifier` and `AppL10n`. That is behaviour work for Phase 2 sign-off.
- **Prototypes are HTML, not running Flutter.** The Flutter components were verified by widget tests, not on a device or emulator. Nastaliq rendering, safe areas and large-text behaviour still need device QA.
- **Fonts load at runtime** through `google_fonts`. Bundling the Noto TTFs for offline-first use is recommended for Phase 2.
- **Outdoor high-contrast mode** (`OutdoorThemeColors`) is not yet re-expressed as a third token set.
- The full-project `flutter analyze` and the existing test suite were not re-run. No existing Dart files changed; only the new files were analyzed and tested.

## Proposed Phase 2 entry steps (each behaviour-neutral)

1. Install `SbTheme` in `app.dart` and alias legacy `AppColors` to the new values.
2. Re-implement `AppButton`, `AppBadge`, `AppTextField`, empty/error/shimmer widgets as wrappers over `Sb*` with the same APIs. This also fixes the dark-only empty and shimmer widgets.
3. Admin: map shadcn variables to `--sb-*`, switch to Noto Sans, migrate the shell/sidebar.
4. Decide locale enablement (Urdu on/off, persisted choice), then wire `SbTheme(locale:)`.
5. Then migrate the client home, worker home, worker profile, discovery and admin dashboard to match the approved prototypes, keeping all providers and actions.
