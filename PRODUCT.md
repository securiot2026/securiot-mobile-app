# Product

<!-- impeccable:product-schema 1 -->

## Platform

adaptive

Flutter (Material widgets) targeting Android and iOS from one codebase. No per-OS idiom branching (Cupertino widgets) is built in this pass, Material is used uniformly, matching Flutter's default cross-platform convention and the course's cross-platform stack requirement. *Inferred, not interviewed*: this session had no interactive question mechanism (no AskUserQuestion-equivalent tool and no browser-servable decision page), so this and every other labeled inference below were derived from the task brief and `securiot-report/README.md` rather than confirmed live with Juan. Flagging this substitution here, in the first reply, per the skill's own directive.

## Stack

Flutter/Dart (rubric-approved cross-platform stack for this course; matches the project's `STACK.md` recommendation and is a hard non-negotiable from the task brief, not a choice offered this session).

## Users

*Primary:* security administrators at medium-sized industrial/logistics companies in Lima Metropolitana, the same user as the Web App dashboard, but away from their desk (walking the floor, off-site, checking in from home). Their job on this surface: confirm zone/device status and review alerts without needing a laptop.

*Secondary (not this surface's primary target, but sharing the underlying data):* on-site security personnel, who receive and act on alerts in the field, and company managers/owners, who care about aggregate incident reporting more than day-to-day operation. (Source: `securiot-report/README.md` §1.2.2.2 User Assumptions.)

## Product Purpose

SecurIoT (Centinela Labs) is an industrial/perimeter security IoT platform: embedded devices at access points and perimeters, edge computing for low-latency local decisions, and a centralized cloud that does real-time threat identification, automatic access validation, and automatic response-protocol activation (alarms, notifications, traceable event logs). This Mobile App extends the existing Web App dashboard's core monitoring capability to a phone, so an administrator is not tied to a desk to know a zone or device went down, or that an alert fired. Success on this surface specifically: an administrator can, from a phone, log in, see which zones/devices need attention, and review/filter alerts as fast as they could on the web dashboard.

## Positioning

Centinela Labs' claim (from the startup's own positioning) is being the accessible Peruvian alternative to high-end patrimonial security systems that are priced and designed only for large corporations, proactive, scalable, and within reach of industrial/logistics pymes. The Mobile App's specific angle within that claim: multi-site remote supervision from a single account, from wherever the administrator actually is, not only from an office desk.

## Operating Context

- The administrator is often walking a facility floor, in a vehicle, or off-site, one-handed use, variable lighting (indoor warehouse, outdoor perimeter, low light at night shifts), intermittent connectivity.
- Consumes the same Cloud API (NestJS, JWT-guarded) as the Web App: `POST /api/v1/auth/login`, zones, devices (online/offline + last reading), alerts (filterable by zone/device/status).
- Sits alongside two sibling surfaces on the same brand: the Web App (Angular Material dashboard) and the Landing Page (static marketing site), both already built against the shared 60/30/10 palette and type/spacing scale recorded in the Web App/Landing UI-SPEC.

## Capabilities and Constraints

- Screens in scope for this pass: Login, Zones list, Devices list (online/offline + last reading), Alerts list (filterable by zone/device/status), language switcher.
- JWT persisted via `flutter_secure_storage` so the session survives app restarts while the token is valid; expired/invalid tokens route back to Login.
- i18n: `en_US` / `es_419`, toggle persisted, every visible string translated in both, a hard requirement, not optional polish.
- No device/emulator exists in this build environment. Verification this pass is `flutter analyze`, `flutter test`, and `flutter build`; visual/on-device confirmation is Juan's to do, stated explicitly rather than claimed.
- GitFlow branch `feature/mobile-auth-dashboard`, Conventional Commits, no AI/Claude authorship trailer in any commit message (overrides this session's default attribution behavior), no em-dashes in code/comments/commits.
- Config values that would normally go in `.env*` (e.g. API base URL) are documented in README.md instead, since sandboxed `.env*` writes may be denied.

## Brand Commitments

Inherited from the sibling Web App / Landing Page surfaces (already built, not invented here):

- 60/30/10 palette: dominant `#F5F7FA` (near-white cool gray), secondary `#101B33` (dark navy), accent `#0E7C86` (teal), destructive `#B3261E` (red).
- Semantic status colors, never used alone (always paired with icon + text): online `#1E7B34`, offline `#5F6368`, alert low `#1A56B3`, alert medium `#B36A00`, alert high/critical `#B3261E`.
- Roboto typeface (Material default) across both existing surfaces.
- 8pt spacing scale (4/8/16/24/32/48/64), 44×44px minimum touch target.
- Product name "SecurIoT" / startup "Centinela Labs", factual, not to be reworded.

## Evidence on Hand

- `.planning/phases/03-web-dashboard-landing-page/UI-SPEC.md`, the shared design contract (palette, type, spacing, copy, a11y) the Web App and Landing Page already build against.
- `securiot-web-app` (Angular), reference for what data/interaction each screen needs; not for visual/code patterns (different platform).
- Cloud API summaries under `.planning/phases/01-cloud-edge-telemetry-spine-auth/` and `.planning/phases/02-zones-devices-alerting/`, exact request/response contracts this app must consume.
- No app icon, splash art, or other native-specific brand assets exist yet; this pass uses Flutter defaults for those rather than inventing brand assets nobody approved.

## Product Principles

- Familiarity over novelty: this is a task tool for someone mid-shift, not a marketing surface, earned familiarity (native Material idioms, obvious status states) beats an inventive UI.
- One brand, three surfaces: the palette, status vocabulary, and copy the administrator already knows from the Web App must feel like the same product on a phone, translated into native idioms, not reinvented.
- Status is never color-only: every online/offline/severity state pairs an icon and text with its color, since a warehouse floor is not a controlled viewing environment.
- The phone is the on-the-go complement to the desk dashboard, not a lesser copy: monitoring tasks (status check, alert triage) that matter one-handed and in motion get full support here.

## Accessibility & Inclusion

Same standard the sibling surfaces already committed to: A11Y.md (github.com/fecarrico/A11Y.md), adapted to mobile since that document has no mobile-specific section, Flutter `Semantics` widgets, 44×44px minimum touch targets, contrast verified (not eyeballed) against the palette above, no status conveyed by color alone, screen-reader-friendly labels recomputed on language switch.
