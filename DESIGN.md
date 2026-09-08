# Design

<!-- impeccable:design-schema 1 -->

Recorded from the built Mobile App (`feature/mobile-auth-dashboard`), not written ahead of it. This is a native Operate-mode surface for a brand world already established by the sibling Web App and Landing Page (`.planning/phases/03-web-dashboard-landing-page/UI-SPEC.md`); this file records how that world was translated into Flutter/Material 3, not a new world invented for this surface.

**Process note (disclosed once, here, not buried):** this build had no browser-servable decision page and no image-generation tool available, so the concept-seed dice round and comp-led visualization new-work.md prescribes could not run. Structure was chosen directly from Operate-mode conventions and the established brand tokens (see `.impeccable/surfaces/mobile-app.md`'s Direction contract, FORM block). No screenshots exist either, no simulator/emulator/device was available in the build environment, so this record and every fix pass rest on code-level review (contrast math, spacing tokens, Semantics/touch-target audit), not visual inspection. Visual confirmation on a real device or simulator is still owed and is Juan's to do.

## Platform

adaptive (Flutter, Material 3 widgets, uniform across Android/iOS, no Cupertino idiom branching this pass)

## Color

Inherited verbatim from the shared brand palette (not reselected for this surface):

| Role | Value | Usage |
|------|-------|-------|
| Surface (60%) | `#F5F7FA` | Scaffold background |
| Ink / secondary (30%) | `#101B33` | App bar, bottom navigation bar, body text |
| Accent (10%) | `#0E7C86` | Primary buttons, active nav indicator, focus ring, links |
| Destructive | `#B3261E` | Reserved for destructive actions (none implemented yet, no delete flows exist on this surface) |

Status vocabulary, never color-alone (icon + text + color on every occurrence):

| Status | Color | Icon |
|--------|-------|------|
| Online | `#1E7B34` | `check_circle` |
| Offline | `#5F6368` | `remove_circle_outline` |
| Alert, low | `#1A56B3` | `info_outline` |
| Alert, medium | `#B36A00` | `error_outline` |
| Alert, high/critical | `#B3261E` | `warning_amber_rounded` |

Contrast verified by computation (not eyeballed) for the pairs this surface actually renders: white text on `#0E7C86` accent buttons ≈ 4.96:1 (passes AA normal text); `#101B33` ink on `#F5F7FA` surface is a very high-contrast pair well above 4.5:1. The remaining pairs (white on `#101B33`, status colors on `#F5F7FA`) are unchanged from the Web App's already-verified UI-SPEC pairs.

## Typography

Roboto (Material default), fixed rem-equivalent scale per Operate-mode guidance (no fluid clamp sizing, product UI is viewed at consistent DPI):

| Role | Size | Weight | Line height |
|------|------|--------|-------------|
| Body | 16 | 400 | 1.5 |
| Label/Caption | 14 | 400 | 1.5 |
| Heading (titleLarge/Medium) | 20 | 600 | 1.2 |
| Display (headlineSmall, login title) | 28 | 600 | 1.2 |

One family, four sizes, two weights, matches the shared UI-SPEC exactly, translated onto Flutter's `TextTheme`.

## Spacing

8pt scale (`lib/core/theme/app_spacing.dart`): 4 / 8 / 16 / 24 / 32 / 48 / 64, plus a 44px minimum-touch-target constant applied to every icon button, filter chip, and interactive row.

## Navigation

Bottom `NavigationBar` with three destinations (Zones, Devices, Alerts), the native phone-scale translation of the Web App's sidenav (`ios.md`/`android.md`'s tab-bar/navigation-bar idiom). Zone → device drill-down uses a pushed route with its own app bar and back navigation, not a nested tab.

## Components

- **Status badges** (`lib/widgets/status_badge.dart`): pill-shaped, icon + text + tinted background, one shared shape for both online/offline and alert severity.
- **List state views** (`lib/widgets/list_state_views.dart`): shared loading (spinner + `Semantics(liveRegion: true)` text), error (icon + message + retry button), and empty (icon + heading + body) treatments reused across Zones/Devices/Alerts, one vocabulary, not three ad hoc screens.
- **Language switcher** (`lib/widgets/language_switcher.dart`): `SegmentedButton` with visible EN/ES text labels and a `Semantics` group label, never a flag or bare globe icon.
- **Cards**: white surface, 12px corner radius, elevation 1 (soft offset shadow, not a flat colored halo).

## Motion

Material defaults only (page transitions, `NavigationBar` selection, `RefreshIndicator`). No orchestrated load sequences or decorative motion was added, Operate-mode guidance treats that as budget better spent on task clarity.

## Accessibility (A11Y.md, mobile-adapted)

- Every icon-only control (password visibility toggle, logout, language segments) carries a `Semantics` label and meets the 44×44 minimum touch target.
- Status and severity are never color-only: `OnlineStatusBadge`/`SeverityBadge` always pair icon + text + color, and expose one merged `Semantics` label rather than three separate announcements.
- Loading and error states use `Semantics(liveRegion: true)` so a screen reader announces the transition, not just a silent spinner.
- Visible field labels on Login (`labelText`, never placeholder-only), matching the shared Web App contract's SC 1.3.1 requirement.
- Language switch recomputes every visible string and label reactively (Provider-driven), including inside status badges and empty states.
- Session-expiry (401) forces logout and unwinds any pushed route back to the app root (`AppNavigator.popToRoot`) rather than leaving a stale authenticated screen on top of a cleared session.

## Known gaps / next-pass candidates

- No app icon or splash art exists yet, Flutter defaults ship in this pass; PRODUCT.md records this as evidence not yet on hand rather than inventing brand assets nobody approved.
- Visual/on-device QA (contrast as actually rendered, real touch behavior, VoiceOver/TalkBack pass) has not happened, no simulator/emulator/device existed in the build environment. This is the load-bearing gap before shipping.
- `flutter build` (apk/ipa) has not been confirmed in this environment (no Android SDK, no complete Xcode), confirmed on a machine with the toolchain installed is still owed.
