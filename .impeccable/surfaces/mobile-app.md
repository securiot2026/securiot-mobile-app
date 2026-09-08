---
version: 1
slug: "mobile-app"
primary_target: "mobile-app"
related_targets: []
---

## Direction contract

THESIS: A shift-floor monitoring tool, not a mini dashboard, the phone's job is a fast status glance and alert triage, one-handed, so the page refuses the "port the web table" default and leads with scannable status cards over dense grids.

OWN-WORLD: Inherited from the established SecurIoT brand (Web App + Landing, `UI-SPEC.md`), translated to Material 3 native idioms per the platform's own vocabulary: `#F5F7FA` surface, `#101B33` app bar/nav rail ink, `#0E7C86` accent (FABs, active nav, links, focus), `#B3261E` destructive; Roboto; 8pt spacing; status vocabulary (online green, offline gray, alert low/medium/high blue/amber/red) always icon+text+color, never color alone. Bottom navigation bar (3 destinations: Zones, Devices, Alerts) replaces the Web App's sidenav, the native phone-scale translation of that same navigation model.

STORY: The administrator opens the app already authenticated (or logs in once), lands on a status overview, sees at a glance whether anything needs attention, and can drill into a zone/device or filter alerts without leaving one-handed reach.

FIRST VIEWPORT: Login screen at first run: centered form, SecurIoT wordmark, email/password fields with visible labels, primary teal CTA "Iniciar sesión" full-width above the thumb zone. Post-login, Zones list is the landing tab: full-width status cards (zone name, device count, an aggregate online/offline indicator with icon+text), pull-to-refresh, bottom nav bar persistent underneath.

FORM: No concept-seed dice round was run this session, there is no browser-servable decision page or image-generation tool available in this headless build environment, so the structural-variation ceremony new-work.md prescribes could not run. Structure was chosen directly from Operate-mode conventions (bottom nav + status cards + filterable list) and the established brand world; this substitution is disclosed here rather than silently skipped. No seed key.

FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, DESIGN.md, and every shipping raster carrying its provenance.
