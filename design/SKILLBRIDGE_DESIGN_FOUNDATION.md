# SkillBridge Design Foundation

**Status:** Phase 1 — proposed, awaiting approval. Nothing here is wired into live screens yet.
**Brand philosophy:** *Local expertise, made easier to trust.*

One system for the Flutter app (client, worker, in-app admin) and the Next.js admin console. The values live in one file — [`design/tokens/skillbridge.tokens.json`](tokens/skillbridge.tokens.json) — and are mirrored by hand in:

| Surface | Tokens | Components |
|---|---|---|
| Flutter | `lib/config/theme/sb/sb_tokens.dart`, `sb_typography.dart`, `sb_theme.dart` | `lib/shared/design_system/` (import `design_system.dart`) |
| Admin web | `super_admin_web/src/styles/sb-tokens.css` (Tailwind `sb-*` utilities) | `super_admin_web/src/components/sb/` |
| Prototypes | `design/prototypes/assets/sb.css` | HTML prototypes in `design/prototypes/` |

After any colour change run `node design/tools/check-contrast.mjs` (fails on any pairing below WCAG 2.2 AA).

---

## 1. Brand identity

| Idea | How it shows up |
|---|---|
| **Trust is evidence, not decoration** | Verified, rating, review count, completed jobs and rate basis appear in a fixed order on every worker surface. Nothing is shown unless the backend says so: no default ratings, no "verified" inferred, no fake counts. |
| **Local and practical** | PKR with rate basis ("Rs 800 / hour", "Rs 2,000 · fixed"), Pakistani areas (G-11, F-7/3), approximate distance ("≈ 2 km"), Urdu as a first-class language. |
| **Calm operations** | Warm off-white canvas, white surfaces, borders instead of shadows, one primary action per decision area, no decorative gradients, no oversized KPI cards. |
| **Honest states** | Payment shows "not collected in app" until a provider exists; dashboards say "Firestore snapshot · loaded 14:02" instead of "Live"; offline and queued are never presented as sent. |

Voice: short, plain, second person. Verbs on buttons name the action ("Send proposal", "Request booking"), never "OK"/"Submit".

## 2. Colour

### Brand palette (approved)
| Role | Light | Use |
|---|---|---|
| Primary — Ink blue | `#174A8B` | Primary buttons, selected nav, links, focus ring |
| Accent — Craft amber | `#E4A33A` | Star ratings, "needs attention" markers, small highlights. **Fill only — never small text on white** (2.2:1). Text on amber uses `onAccent #18232F`. |
| Success — Trust teal | `#167A63` | Verified, available, completed — always with an icon and label |
| Canvas — Warm background | `#F7F8F6` | Page background |

### Semantic roles (light / dark)
| Token | Light | Dark | Contrast (light) |
|---|---|---|---|
| canvas | `#F7F8F6` | `#0F151B` | — |
| surface | `#FFFFFF` | `#161E26` | — |
| surfaceSunken | `#EEF1EE` | `#0B1116` | — |
| surfaceRaised (sheets) | `#FFFFFF` | `#1D2731` | — |
| text | `#18232F` | `#E8EDF1` | 15.9:1 |
| textSecondary | `#596779` | `#A4B1BE` | 5.8:1 |
| textDisabled | `#8C97A3` | `#6C7986` | disabled only |
| border | `#DCE3E8` | `#2A3642` | dividers / card edges |
| borderStrong | `#B4C0CA` | `#3D4B58` | secondary button, chips |
| borderInput | `#7D8995` | `#6E7B88` | 3.6:1 (WCAG 1.4.11) |
| primary / onPrimary | `#174A8B` / `#FFF` | `#8FB6EC` / `#0C2747` | 8.8:1 |
| primarySubtle / on | `#E7EEF7` / `#123D73` | `#1A2D45` / `#C3D8F5` | 9.3:1 |
| success / successSubtle / on | `#167A63` / `#E2F2ED` / `#0E5545` | `#5CC4A6` / `#12302A` / `#8FDCC5` | 5.3 / 7.6:1 |
| warning / warningSubtle / on | `#8A5A00` / `#FDF2DD` / `#6B4500` | `#E9B65C` / `#33270F` / `#F5CF8E` | 5.9 / 7.6:1 |
| error / errorSubtle / on | `#B42318` / `#FCE8E6` / `#8F1C13` | `#F2A39C` / `#3A1714` / `#F7C2BD` | 6.6 / 7.6:1 |
| accentSubtle / on | `#FBF0DC` / `#6E4708` | `#33270F` / `#F5CF8E` | 7.2:1 |

All 62 checked pairings pass AA in both themes (see `check-contrast.mjs`).

**Category tones** (ink, teal, amber, clay, plum, slate) colour only the small icon tile beside a category name. `SbCategoryTone.forCategory()` maps English and Urdu category names to a stable tone. This replaces the current `AppColors.getCategoryColor` (which uses raw purples/oranges).

**Rules**
- Screens never use hex literals or Tailwind palette classes (`slate-500`, `blue-50`). Flutter: `context.sb.<role>`. Web: `bg-sb-surface`, `text-sb-text-secondary`, etc.
- Status is never colour alone — always icon + text.
- Dark mode is a full token set, not an inversion. Dark primary is a lighter ink (`#8FB6EC`) with dark text on top.

## 3. Typography

One family: **Noto Sans** (Latin) + **Noto Nastaliq Urdu**, each the other's fallback so an Urdu name in English UI (and vice versa) renders correctly. Replaces the current three fonts (Sora, Inter, JetBrains Mono). Numbers use tabular figures (`SbTypography.numeric`, `.sb-tabular`) so prices and ratings align without a monospace font.

| Role | Flutter `TextTheme` | Size / line | Weight | Use |
|---|---|---|---|---|
| display | `displaySmall` | 32 / 40 | 700 | Hero numbers only |
| headline | `headlineSmall` | 24 / 32 | 700 | Screen title |
| titleLg | `titleLarge` | 20 / 28 | 600 | App bar, sheet title |
| title | `titleMedium` | 17 / 24 | 600 | Section title, names, card titles |
| titleSm | `titleSmall` | 15 / 22 | 600 | Compact card titles |
| bodyLg | `bodyLarge` | 16 / 24 | 400 | Inputs, long text |
| body | `bodyMedium` | 14 / 20 | 400 | Default body |
| caption | `bodySmall` | 12 / 16 | 400 | Meta, helper (secondary colour) |
| label | `labelLarge` | 14 / 20 | 600 | Buttons, field labels |
| labelSm | `labelMedium` | 12 / 16 | 600 | Badges, nav labels |

**Urdu:** +1 size step, ×1.35 line height, letter-spacing 0 (tracking breaks Nastaliq joins). Verified in the prototype RTL frame: no clipping at these metrics.

**Text scaling:** the app currently clamps OS text scale to 1.2 (`app.dart`). Components are built to reflow (no fixed heights on text containers, `Wrap` for meta rows), so Phase 2 can raise the clamp after the home banner carousel is fixed.

**Offline note:** `google_fonts` fetches fonts at runtime. Phase 2 should bundle the Noto TTFs under `assets/fonts/` so first launch on a poor connection still renders correctly (google_fonts picks up bundled files automatically).

## 4. Space, layout, shape, elevation

- **Spacing:** 4-pt base, 8-pt rhythm — `SbSpace.s1…s16` = 4, 8, 12, 16, 20, 24, 32, 40, 48, 64.
- **Edges:** mobile 20, tablet 24, admin 32 (16 on admin phone width).
- **Max widths:** forms 560, app content 1200, admin 1440.
- **Radius:** controls 8, cards 12, sheets/dialogs 20, pills full.
- **Borders:** hairline 1 for grouping, 2 for focus.
- **Elevation:** none for content. `overlay` shadow for menus/popovers, `sheet` for bottom sheets and dialogs only.

## 5. Responsive behaviour

| Size class | Width | App navigation | Admin |
|---|---|---|---|
| Compact | < 600 | Bottom `NavigationBar` | Drawer behind menu button; tables become stacked label/value records (< 760) |
| Medium | 600–1023 | `NavigationRail` with labels | Drawer; tables scroll inside their card |
| Expanded | ≥ 1024 | Extended rail; content capped at 1200 | Sidebar + 12-column grid, max 1440 |

`SbAdaptiveScaffold` implements the app column. It only does layout, so it can wrap the existing client/worker shells (IndexedStack, go_router state, deep links) unchanged. `SbWindowSize.of(context)` replaces raw `MediaQuery.width` checks.

## 6. Iconography & motion

- Flutter: Material Symbols **Rounded** (`Icons.*_rounded`), 24 default / 20 in buttons / 16 in meta rows. Web: Lucide at the same sizes, 1.75–2 stroke.
- Directional icons (back, chevrons, arrows, logout) mirror in RTL; Flutter does this automatically for `Icons.arrow_back` etc.; web uses `rtl:rotate-180`.
- Icon-only buttons always carry a semantic label and a 48 dp hit area.
- Motion: 120 ms (press/hover), 200 ms (state change), 320 ms (sheets, route). Standard easing `cubic-bezier(0.2,0,0,1)`. `SbMotion.of(context, …)` returns zero when the OS requests reduced motion; skeletons stop pulsing.

## 7. Components

### Flutter (`lib/shared/design_system/`)
| Component | Purpose | Replaces / consolidates |
|---|---|---|
| `SbTheme.light/dark(locale:)` | Full Material 3 theme from tokens, incl. buttons, inputs, chips, nav bar, rail, tabs, sheets, dialogs, snackbars, switches | `AppTheme`, `OutdoorThemeMode` colours |
| `SbButton` | primary / secondary / quiet / destructive; 48 dp regular, 40 dp compact; loading keeps width and announces a label | `AppButton` |
| `SbStatusBadge` | Icon + text tones: verified, pending, available, unavailable, urgent, info, error | `AppBadge`, `RatingBadge` styling |
| `SbTextField` | Persistent label, required/optional marker, helper → error, merged semantics | `AppTextField` |
| `SbWorkerCard` | Identity → trust → rate basis → distance/availability; every optional field hidden when null | Ad-hoc worker cards in home/nearby |
| `SbJobCard` | Category tile, title, area, posted, budget basis, urgency, proposals, role-specific footer | `JobCard` styling |
| `SbAvatar` | Photo with initials fallback, no stock people | `AppAvatar` |
| `SbSectionHeader` | Heading semantics + quiet "See all" | Per-screen `_buildSectionHeader` |
| `SbStateView` | empty / error / offline / permission / success, each with distinct icon and tone, one action | `AppEmptyState`, `EmptyStateCard`, `AppErrorWidget` |
| `SbInlineBanner` | Offline-with-cache, queued, stale, non-blocking error | Parts of `ConnectivityBanner`, `OutboxStatusPill` text |
| `SbSkeleton`, `SbListRowSkeleton` | Content-shaped loading, reduced-motion aware | `AppShimmerCard`, `ShimmerLoadingCard` |
| `SbAdaptiveScaffold`, `SbReadableWidth` | Bottom nav ↔ rail ↔ extended rail; readable form width | Client/worker shell layout |
| `showSbConfirmSheet` | Consequential actions: hire, decline, cancel, report | Assorted `showDialog` confirmations |

### Admin web (`super_admin_web/src/components/sb/`)
| Component | Purpose |
|---|---|
| `PageHeader` | Breadcrumb, single h1, purpose line, scope/freshness slot, actions |
| `FreshnessNote` | "Latest 100 jobs · loaded 14:02" — replaces "Live Feed" wording on snapshot data |
| `Kpi` | Label, value, **required scope**, optional link; `unavailable` instead of silent 0; amber marker for "needs attention" |
| `StatusBadge`, `StatusDot`, `statusTone()` | One mapping from Firestore status strings to tones, used on every admin screen |
| `DataState`, `TableSkeleton` | empty vs no-results vs **error** vs permission — failed queries can no longer look like empty ledgers |
| `RecordTable` | Real `<table>` with caption from md up; stacked records on narrow screens |
| `SbButton` | primary / secondary / quiet / destructive, 40 px (44 px `lg`), loading with `aria-busy` |

The existing shadcn primitives (`dialog`, `select`, `dropdown-menu`, `tabs`, `toast`, `sheet`) stay; Phase 2 points their CSS variables (`--primary`, `--background`, `--border`…) at the `--sb-*` tokens so they inherit the brand without rewrites.

## 8. Interaction standards

**Buttons:** one primary per decision area (a card, a sheet, a sticky bar). Secondary for the alternative, quiet for navigation-like actions, destructive only behind `showSbConfirmSheet`. Disabled buttons explain why nearby (e.g. offline banner).

**Forms:** label above every field; placeholder is only an example. Validate on blur/interaction, show the error under the field, keep input on any recoverable failure. Correct keyboard types; `+92` prefix for phones; `Rs` prefix for amounts; city/area from `PakistanConstants`.

**Cards & lists:** whole card is the tap target for "open"; explicit buttons for actions. Lists over card grids. Meta in `Wrap`, never fixed-width rows.

**Navigation:** client Home / My jobs / Chats / Profile; worker Home / Proposals / Contracts / Chats / Profile; notifications in the app bar. Unread counts as badges. Back always returns to the previous state.

**Feedback:** snackbars supplement, never replace, inline errors or persistent state. Success messages name the event and next step ("Proposal sent to Sana. You'll be notified when she replies.").

## 9. States

| State | Pattern | Rule |
|---|---|---|
| Loading | `SbSkeleton` shaped like the content | Keep previous data on refresh |
| Empty | `SbStateView.empty` | Say why, offer one next action |
| No results | Empty + filter hint | Offer to widen the filter |
| Error | `SbStateView.error` / `DataState error` | Never show raw exceptions; retry keeps filters/input |
| Offline | `SbInlineBanner` warning above cached content | Actions that need the server are disabled with reason |
| Queued | `SbInlineBanner` info | "Will send when online" ≠ sent |
| Permission | `SbStateView.permission` | Explain value, link to settings; manual fallback (e.g. pick area) |
| Success | Inline banner or confirmation | Only after server confirmation |

## 10. Localization & RTL

- English and Urdu ARB files are untouched. Phase 1 adds no new user-facing strings to the app — components take already-localized labels from callers.
- Components use `EdgeInsetsDirectional`, `AlignmentDirectional`, `Row` (auto-mirrors) and directional icons; the widget tests render cards in Urdu RTL at 320 px and assert the avatar moves to the right with no overflow.
- `SbTheme.light(locale: Locale('ur'))` switches the font and metrics.
- **Not done (needs Phase 2 decision):** `app.dart` still pins `locale: Locale('en')` and `LanguageNotifier`/`AppL10n` are English-only no-ops. Restoring Urdu means enabling `supportedLocales: [en, ur]`, making `LanguageNotifier` persist the choice, and passing the locale to `SbTheme`. Admin web stays English with `[lang="ur"]` styles ready for Urdu user content.

## 11. Accessibility checklist

- Contrast: all text pairings ≥ 4.5:1, input borders and focus ≥ 3:1 (scripted).
- Targets: 48 dp mobile (tested), 40–44 px admin.
- Never colour-only: badges, urgency and availability carry icon + text.
- Semantics: section headers marked `header`, field label merged with input, icon buttons labelled, state views are live regions for error/success, avatars excluded (name is read once).
- Focus: visible 2 px ring on web (`.sb-focus`); Flutter theme focus border is 2 px primary.
- Reduced motion honoured in Flutter (`SbMotion`, `SbSkeleton`) and web (`prefers-reduced-motion`).
- Charts: SVG `role="img"` with a text summary plus a "View as table" option.

## 12. Migration map (Phase 2)

1. Swap `AppTheme.lightTheme/darkTheme` → `SbTheme.light/dark(locale:)` in `app.dart`.
2. Point legacy `AppColors` constants at `SbColors.light` values (keeps ~440 existing screen call sites compiling while screens migrate), then replace `AppColors.*`/hex literals with `context.sb.*` screen by screen.
3. Re-implement `AppButton`, `AppBadge`, `AppTextField`, `AppEmptyState`, `EmptyStateCard`, `AppErrorWidget`, `ShimmerLoadingCard` as thin wrappers over the `Sb*` components (same constructor APIs), then retire duplicates.
4. Retire `OutdoorThemeColors`; if high-contrast outdoor mode stays, derive it as a third `SbColors` set.
5. Admin: map shadcn variables to `--sb-*`, swap Geist for Noto Sans in `layout.tsx`, replace literal colours page by page starting with the shell/sidebar.

Each step is behaviour-neutral: no providers, routes, Firestore queries or rules change.
