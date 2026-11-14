# Phase 2A — Live Design System Integration: Report

**Date:** 8 November 2026 · **Branch:** `ui-improvements-2026` · **Status:** complete, awaiting approval before Phase 2B (Authentication and Profiles). Nothing committed, nothing deployed.

## Summary

The Flutter app and the Next.js admin now run on the approved SkillBridge design system:

- **Flutter:**
  - `SbTheme` light and dark replace `AppTheme`. Theme selection and its Hive persistence are unchanged.
  - Legacy `AppColors` / `AppTextStyles` names now carry the token values.
  - `AppButton`, `AppBadge`, `AppTextField` and the empty/error/skeleton widgets are thin wrappers around the `Sb*` components, with unchanged constructors.
  - Noto Sans and Noto Nastaliq Urdu are bundled locally.
- **Admin:**
  - The shadcn variables point at the `sb-*` tokens.
  - Noto Sans replaces a broken font setup.
  - The shell, sidebar and header are migrated.
  - Literal colours across admin pages are replaced with tokens (colour only).
  - A light/dark/system switch is added; the default stays light.

No providers, routes, Firestore queries, rules, schemas, Firebase/Auth config, localization config or ARB files were changed. All 54 pre-existing Flutter tests and the admin type check, lint and production build pass. The analyzer shows 65 issues against 68 at baseline, with none new.

## 1. Baseline (before any change)

| Check | Result |
|---|---|
| Branch / working tree | `ui-improvements-2026`; 134 uncommitted entries of yours (84 modified, 19 deleted, 31 untracked). Preserved: files I touched were snapshotted first and verified afterwards (see §6). |
| `flutter test` (full) | 67/67 pass (54 existing + 13 Phase 1 design-system tests) |
| `flutter analyze` (full) | 68 issues: **0 errors**, 19 warnings, 49 info, all pre-existing |
| Admin `tsc --noEmit` | pass |
| Admin `eslint .` | pass |
| Admin `next build` | pass |

## 2. Files created and modified

### Flutter: modified
| File | Change |
|---|---|
| `lib/app.dart` | `theme`/`darkTheme` → `SbTheme.light/dark(locale: en)`. `themeMode` provider and the pinned locale are untouched. |
| `lib/main.dart` | Registers the bundled fonts' OFL licence (`LicenseRegistry`). No startup logic changed. |
| `pubspec.yaml` | Adds the `assets/fonts/` asset folder. No dependency changes. |
| `lib/config/theme/app_colors.dart` | Same names, all still `const`, now token values (ink blue, trust teal, craft amber, warm canvas, dark set). `getCategoryColor` uses `SbCategoryTone`. |
| `lib/config/theme/app_text_styles.dart` | Same names, sizes and weights; Sora/Inter/JetBrains Mono → Noto Sans with tabular figures for numbers. |
| `lib/core/extensions/context_extensions.dart` | `scaffoldBg`, `surfaceColor`, `textColor`, `mutedColor`, `borderColor`, `accentColor` (469 call sites) read the active token set. |
| `lib/shared/widgets/app_button.dart` | Wrapper over `SbButton`: solid → primary, outline → secondary, text → quiet, error background → destructive; other custom colours applied through a scoped token override. |
| `lib/shared/widgets/app_badge.dart` | Factories (`verified`, `urgent`, `available`, `busy`) → `SbStatusBadge` tones; plain constructor keeps caller colours. |
| `lib/shared/widgets/app_text_field.dart` | Wrapper over `SbTextField`. Keeps the password toggle and **keeps validate-on-submit** (no new as-you-type errors). |
| `lib/shared/widgets/app_empty_state.dart`, `empty_state_card.dart` | Both → `SbStateView` (empty). Fixes `EmptyStateCard` always rendering dark. |
| `lib/shared/widgets/app_error_widget.dart` | → `SbStateView` (error); title and retry use the existing ARB keys `somethingWentWrong` / `tryAgain`. |
| `lib/shared/widgets/app_shimmer_card.dart`, `shimmer_loading_card.dart` | → `SbSkeleton` / `SbListRowSkeleton`. Fixes skeletons always rendering dark; they now respect reduced motion. |
| `lib/shared/widgets/app_chip.dart` | Theme-aware token colours (was light-only). |
| `lib/config/theme/sb/sb_typography.dart`, `lib/shared/design_system/sb_text_field.dart` | Font fallback order fix (see §5); configurable `autovalidateMode`; empty labels omit the label row. |
| `test/widget/design_system_test.dart` | +1 regression test for the font fallback order. |

### Flutter: created
`assets/fonts/` holds NotoSans and NotoNastaliqUrdu in Regular, Medium, SemiBold and Bold (8 TTFs, 4.2 MB), plus `OFL.txt`. The files were downloaded unmodified from `fonts.gstatic.com`, and each SHA-256 was verified against the hashes pinned in `google_fonts` 8.2.0.

Left in place, unused by the app now: `AppTheme` (`app_theme.dart`, which has your uncommitted edits) and `OutdoorThemeMode`. Nothing was deleted.

### Admin: modified
| File | Change |
|---|---|
| `src/app/globals.css` | shadcn variables (`--primary`, `--background`, `--card`, `--border`, `--ring`, `--sidebar*`, charts…) → `var(--sb-*)` for light and dark. Fixes `--font-sans: var(--font-sans)`, a self-reference that made the console fall back to a **serif** font. |
| `src/app/layout.tsx` | Geist → Noto Sans (+ Noto Nastaliq Urdu loaded only when used) via `next/font/google`. Adds a pre-paint theme script, so there is no light/dark flash. |
| `src/styles/sb-tokens.css` | Font variables wired to `next/font`; doc comments. |
| `src/components/layout/sidebar.tsx` | Rebuilt to the approved shell: brand mark, grouped nav (People / Marketplace / Governance), identity and sign-out at the bottom, theme switch in the phone drawer. **Same routes, labels, active logic and sign-out sequence.** |
| `src/components/layout/header.tsx` | Tokens; theme switch added; gradient avatar removed. Export, reports bell and the account menu items are unchanged. |
| `src/components/layout/admin-shell.tsx` | Tokens; drawer overlay and close button use 40 px targets. |
| `src/components/dashboard/overview-chart.tsx`, `category-donut-chart.tsx`, `src/lib/services/analytics.service.ts` | Chart and tooltip colours → `--sb-chart-*` / surface tokens (follow light/dark). Only colour strings changed; no query changes. |
| `src/app/admin-login/page.tsx` | Colour tokens; logo mark recoloured to the ink-blue family. |
| The page and component files under `src/app/adminpanel/**`, plus `src/components/dashboard/moderation-summary.tsx` | **Colour classes only**: 639 literal colours (`#2F80ED`, `slate-*`, `emerald-*`…) → `sb-*` tokens by a deterministic mapping. No layout, spacing, markup or logic change. |

### Admin: created
`src/components/sb/theme-toggle.tsx`: Light / Dark / System radio group, stored per browser in `localStorage`. The default is **light** (today's look); System follows the OS.

### Tooling and docs (created)
- `design/tools/capture.sh`: now takes full URLs and `SCHEME=light|dark`.
- `design/tools/capture-cdp.mjs`: real-time Chrome DevTools capture with optional taps and Hive theme seeding.
- `design/phase2a/`: before/after screenshots and comparison board.
- `.claude/launch.json`: `admin-web` and `flutter-web` dev-server configs.

## 3. Screenshots (actual running apps)

Captured from **release web builds of the real Flutter app** (before = the unmodified code, after = this phase) and the **running admin dev server**.

- `design/phase2a/compare-app.png`: before → after board.
- `design/phase2a/before/*`, `design/phase2a/after/*`: individual captures.

| Screen | Before | After |
|---|---|---|
| App · Create account (light/dark) | Royal blue `#003FB1`, Sora/Inter mix, borderless pale fields | Ink blue, Noto Sans, warm canvas, 3:1 input borders |
| App · Reset password (light/dark) | As above | As above |
| App · Sign in (light/dark) | Screen-specific dark design, Roboto fallback | Same screen design (Phase 2B), now Noto Sans |
| Admin · Sign in (desktop, phone) | Serif fallback font, `#2F80ED` | Noto Sans, ink-blue tokens; dark variant shown opted-in |

**Not captured:** signed-in screens (app homes, admin dashboard, users, jobs, reports). They need a real sign-in, which you chose to skip for now. The admin shell, sidebar and dashboard changes are verified by type check, lint and production build, but **not visually**.

The yellow "No internet connection" banner in the app captures is the app's real offline banner. Headless Chrome couldn't reach Firestore, and it appears identically before and after.

## 4. Test and build results (after)

| Check | Result |
|---|---|
| `flutter test` (full) | **68/68 pass** (54 existing + 14 design system) |
| `flutter test test/widget/design_system_test.dart` | 14/14 |
| `flutter analyze` (full) | **65 issues** (baseline 68): 0 errors, **0 new**. 3 resolved (unused imports in rewritten widgets); the 3 `main.dart` deprecation infos only moved down by 8 lines. |
| `flutter build web --release` | pass (before and after) |
| Admin `tsc --noEmit` / `eslint .` / `next build` | pass / pass / pass |
| Light/dark | App: login, sign-up and reset password in both themes via the persisted Hive theme key. Admin: login in light and dark; light default confirmed under a dark OS preference. |
| Responsive | Admin login at 1440 px and 500 px. App screens at 412 px. Signed-in admin layouts not visually checked. |

## 5. Regression found and fixed during QA

The first "after" build rendered the **login screen in a serif face**. The login screen requests `fontFamily: 'Inter'`/`'Sora'`, which were never registered fonts. Before, Flutter fell back to Roboto. My theme's fallback list started with Noto Nastaliq Urdu, whose Latin glyphs are serif, so Latin text fell through to them. The fix puts Noto Sans first in the fallback chain for both locales, so Latin goes to Noto Sans and Urdu to Nastaliq. A regression test now guards this.

Also fixed: my scripted edits had changed several files' line endings (Windows Python writes CRLF). Every touched file was restored line by line to its original endings, including mixed-ending files such as `main.dart`. Raw diffs now show only real changes.

## 6. Functionality preserved

- **Theme selection:** `ThemeModeNotifier` and its Hive key `theme_mode` are unchanged; dark mode still comes from the same setting.
- **Navigation:** no route, guard, redirect or shell change in the app. The admin keeps all 7 destinations, the same hrefs and the same active-state logic.
- **Data:** no change to providers, view models, data sources, Firestore queries, Cloud Functions, rules, indexes, storage or schemas.
- **Auth:** app sign-in and sign-up flows are unchanged. Admin sign-out runs the same `signOut(auth)` and `DELETE /api/auth/session` sequence; header sign-out is unchanged; session verification in layouts and API routes is untouched.
- **Legacy widget APIs:** every constructor and parameter is unchanged. Every file using them (15 with `AppButton`, 5 with `AppTextField`, 5 with `AppEmptyState`, 2 with `AppErrorWidget`, plus the shimmer users) compiles unchanged. Form validation timing is preserved.
- **Localization:** `app.dart` locale config, `LanguageNotifier`, `AppL10n` and both ARB files are untouched.
- **Your uncommitted work:** a snapshot of every file I'd touch was taken first. Afterwards, every snapshot file outside my intended list was byte-identical; for example, `app_theme.dart` and `booking_payment_sheet.dart` are unchanged. My changes to files that already held your edits (`app.dart`, `main.dart`, `pubspec.yaml`) are additions only.

## 7. Localization assessment (Step 3)

| Finding | Detail |
|---|---|
| ARB parity | `app_en.arb` and `app_ur.arb` both have **138 keys, 0 missing, 0 extra**, placeholders match, every Urdu value is in Urdu script. Only `currencySymbol` and `currencyFormat` are intentionally identical ("Rs"). |
| ARB usage in UI | Only **~8 keys** are referenced from code (`l10n.settings`, `logout`, `verified`…). |
| Inline pairs | **167** `AppL10n.select(en:, ur:)` pairs hold Urdu text but are hardwired to return English. |
| Hardcoded English | **≥189** `Text('…')` literals with no Urdu, across 37 files (e.g. 21 on worker profile detail, 20 on job details). |

**Recommendation: do not enable Urdu yet.** Turning it on today would give a mixed-language UI: ARB strings and the 167 inline pairs in Urdu, but most screen text, buttons and errors still in English. Suggested activation path, for a separate approval:
1. Move inline `AppL10n.select` pairs and hardcoded strings into the ARB files, screen by screen, as each screen is redesigned in Phase 2B+ (so strings aren't touched twice).
2. Then add `Locale('ur')` to `supportedLocales`, make `LanguageNotifier` persist the choice (the Hive key already exists), make `AppL10n` honour it, and pass the locale to `SbTheme`, which already handles Nastaliq metrics and RTL.
3. Gate on an RTL visual pass of each migrated screen.

Locale behaviour in this phase: **unchanged** (English, LTR).

## 8. Known issues and limitations

1. **Signed-in screens not visually verified** (app homes, admin dashboard and tables). They compile and pass tests and builds, but need a sign-in to check light, dark and responsive.
2. **Screen-level hardcoded colours remain.** About 94 `Color(0x…)` literals plus direct `AppColors.primary` uses on themed surfaces. In dark mode some icons and labels still use light-theme ink blue, for example the Reset Password icon and the selected "Client (Hire)" label on Create Account (both already low-contrast before). These will be fixed as each screen is redesigned (Phase 2B+). The token layer is ready for it.
3. **The login screen keeps its own dark-only design** (now with Noto Sans). It's scheduled for the Phase 2B auth redesign.
4. **Admin page content** has token colours but its original layout: large rounded cards, `figma-card` helpers (now flat and bordered). Restyling pages to the prototype is later admin-phase work.
5. **App size:** +4.2 MB for bundled fonts. Could drop the Medium weights (about 1.1 MB) if size matters.
6. **`AppErrorWidget` still shows whatever message callers pass**, sometimes `err.toString()`. That is existing behaviour, kept on purpose. Should be replaced with friendly copy per screen.

### Pre-existing issues found (not changed: outside this phase's scope)
- **`.env` is bundled as a public asset.** `pubspec.yaml` lists `.env`, so the web build serves it at `/assets/.env`, and APK/IPA builds include it. Any key in it is public. Recommend moving keys to build-time config or restricted platform keys before release.
- **App Check uses a placeholder reCAPTCHA site key** (`'recaptcha-v3-site-key'`), causing 400 responses on web.
- **Crashlytics initialises on web**, where it isn't supported, causing an uncaught (non-fatal) error at startup.
- Flutter web loads CanvasKit from Google's CDN by default. Offline or locked-down networks need `--no-web-resources-cdn` if web is a target.

## 9. Approval gate

Phase 2A is complete. Waiting for approval before **Phase 2B: Authentication and Profiles**.
