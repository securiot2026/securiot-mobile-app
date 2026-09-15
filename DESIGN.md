# Design

<!-- impeccable:design-schema 1 -->

**Superseded.** Replaces the light Material 3 direction below with the dark direction locked by Centinela Labs' `SecurIOT Visual Direction.pdf`. Page 4 ("En pantalla — móvil") is this surface's direct visual reference: the field guard's phone screens, dark ground with the brand color bloom behind the splash/hero moment, flat un-grained status components everywhere data needs to be read exactly. This file records the target; the app still ships the prior light theme (see "Known gaps").

## Platform

adaptive (Flutter, Material 3 widgets, uniform across Android/iOS) — unchanged.

## World

This surface resolves the **Guardia de Campo** persona from the brief: receives alerts, locates the event, responds — distinct from the Operador/Administrador/Gerente who use the web dashboard for monitoring, history, and KPIs. That persona split is now explicit in PRODUCT.md and should shape what this app prioritizes (alert-first, action-first) versus what stays web-only (historical trend views, indicators).

## Color

Seven tokens total (brand system, shared verbatim with Landing and Web App):

| Token | Value | Usage here |
|---|---|---|
| `--marca` | `#1FD3C4` | Primary buttons, active nav indicator, focus ring, brand mark, splash/login bloom |
| `--senal` | `#6C7CE8` | Status: validating |
| `--verificado` | `#22DD66` | Status: authorized / zone or device OK |
| `--alerta` | `#FF5C6C` | Status: intrusion, any severity |
| `--noche` | `#0B0E14` | Scaffold background |
| `--texto` | `#EEF0F4` | Primary text, app bar, bottom nav — never `#FFFFFF` |
| `--texto-mute` | `#8B93A3` | Secondary text, timestamps' surrounding labels, disabled states |

Same extension as the Web App, disclosed once and applied identically across both Operate surfaces so they don't drift into two different offline/severity conventions:
- **Offline** → `--texto-mute` + `remove_circle_outline`, neutral rather than colored.
- **Alert severity** (low/medium/high) → single `--alerta` red, differentiated by icon (`info_outline` / `error_outline` / `warning_amber_rounded`) and an explicit severity label, never a second red.

Two jobs, per the brief: the splash/login screen gets the one radial bloom (grain-baked background image, matching the PDF's mobile splash comp exactly — teal-to-blue bloom, "SecurIoT · Detecta. Valida. Responde en el instante." over it); every screen after that is flat state components on `--noche`, no bloom, no grain, because that's where the guard needs to read data fast.

Contrast to re-verify once applied (computed, not eyeballed): `--texto` (#EEF0F4) and `--texto-mute` (#8B93A3) against `--noche` (#0B0E14); white text on `--marca` (#1FD3C4) buttons — the prior light-theme pairs no longer apply since the ground inverted from light to dark.

## Typography

Per brand, replacing Roboto:

| Role | Font | Size / Weight | Line height |
|---|---|---|---|
| Display (splash title, login title) | Sora | 700, 24–28 | 1.2 |
| Heading (section titles) | Sora | 700, 20 | 1.2 |
| Body | Schibsted Grotesk | 400, 16 | 1.5 |
| Label / Caption | Schibsted Grotesk | 400, 14 | 1.5 |
| Data (zone status line, timestamps, device IDs) | Martian Mono | 400, 15 | 1.5 |

Translated onto Flutter's `TextTheme` in place of the current single-family Roboto scale; the mono face is new to this surface and is specifically for the alert/status detail rows a guard scans under time pressure — it did not exist as a distinct role in the prior design.

## Spacing

Unchanged: 8pt scale (`lib/core/theme/app_spacing.dart`), 44px minimum touch target — the brief doesn't specify spacing or touch targets, so this carries forward.

## Navigation

Unchanged structurally: bottom `NavigationBar`, three destinations (Zones, Devices, Alerts), pushed-route drill-down with back navigation. Only the visual theme (dark ground, brand accent) changes, not the IA.

## Components

- **Splash / activation screen**: the one bloom moment on this surface — matches the PDF mobile comp (brand mark centered, "Activar perímetro" pill CTA, white-fill button on the bloom).
- **Status badges** (`lib/widgets/status_badge.dart`): pill-shaped, icon + text + tinted background — now on dark surfaces, so tint values need re-tuning for dark-ground contrast (light-theme tint math doesn't transfer).
- **List state views**: unchanged pattern (loading/error/empty), retheme only.
- **Language switcher**: unchanged (`SegmentedButton`, visible EN/ES labels).
- **Cards**: retheme from white-surface/12px-radius/elevation-1 to a dark surface one step lighter than `--noche` (matching the PDF's "Planta Norte" card comp — a slightly raised dark panel, not a floating white card), same radius and elevation logic.

## Motion

Unchanged except the brief adds one specific permitted loop: the "en vivo" status dot on a live zone card — everything else stays action-driven, no orchestrated load sequences, matching Operate-mode guidance already in place.

## Accessibility (A11Y.md, mobile-adapted)

All prior commitments carry forward unchanged and are now binding on the dark retheme too: `Semantics` labels + 44×44 targets on every icon-only control, color-never-alone status badges, `liveRegion: true` on loading/error transitions, visible field labels on Login, reactive language switch, session-expiry pop-to-root. The one addition: dark-ground contrast must be re-verified by computation before shipping, since every ratio in the prior file assumed a light `#F5F7FA` surface.

## Known gaps / next-pass candidates

- This file records the target dark/brand retheme; the app still ships the prior light Material theme. Applying it is a retheme, not a structural redesign — separate follow-up work, not done in this pass.
- No app icon or splash art exists yet; the icon pack in `SecurIOT (1).zip` (`icono-2.svg`/`icono-12.svg`, the brand mark icon-solo lockup) is the source for the eventual app icon — still needs export to platform icon sizes, not done here.
- Visual/on-device QA (contrast as actually rendered, VoiceOver/TalkBack pass) is still owed, unchanged from before.
- `flutter build` (apk/ipa) confirmation on a machine with the full toolchain is still owed, unchanged from before.
