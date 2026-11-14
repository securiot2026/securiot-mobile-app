# SecurIoT Mobile App

Flutter mobile client for SecurIoT (Centinela Labs): a security administrator's
on-the-go companion to the Web App dashboard, sign in, check zone/device
status, and review alerts from a phone.

See `PRODUCT.md` for the full product context and `.impeccable/surfaces/mobile-app.md`
for this surface's design direction contract.

## Screens

- **Login**, email/password against `POST /api/v1/auth/login`, JWT persisted
  via `flutter_secure_storage` so the session survives app restarts.
- **Zones**, every zone the account owns; tap a zone to see its devices.
- **Devices**, online/offline status (icon + text + color, never color
  alone) and last reading; filterable by zone via the Zones tap-through.
- **Alerts**, filterable by zone, device, and status.
- **Language switcher**, `en_US` / `es_419`, persisted, visible on every
  screen's app bar.

## Configuration

There is no `.env` file: this sandbox's permission settings deny writes to
any `.env*` path (the same constraint hit by `securiot-cloud-api` in this
monorepo), so the one configuration value this app needs is documented here
instead, as the project's own convention already establishes.

### `API_BASE_URL`

The Cloud API base URL (including the `/api/v1` prefix). Passed at build or
run time with `--dart-define`, never hardcoded:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1
flutter build apk --dart-define=API_BASE_URL=https://api.securiot.example/api/v1
```

Default (`lib/core/api/api_config.dart`) is `http://10.0.2.2:3000/api/v1`.
`10.0.2.2` is the Android emulator's alias for the host machine's
`localhost`, matching a local `securiot-cloud-api` running on port 3000. On
a physical device or iOS simulator, pass the host machine's real LAN IP or
the deployed API URL via `--dart-define` instead.

## Development

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --debug   # requires the Android SDK
```

No device or emulator exists in the environment this app was built in.
`flutter analyze` and `flutter test` are verified clean/passing there;
`flutter build` could not be run in that sandbox (no Android SDK, no
complete Xcode install) and needs to be confirmed on a machine with the
Android/iOS toolchain installed. Visual/on-device behavior has not been
confirmed on a simulator or real hardware, that verification is still
pending.

## App icon and name

The launcher, splash and web icons are generated from `assets/brand/icono-2.svg`
on the `#0B0E14` ground. To regenerate them (needs `rsvg-convert` from
`brew install librsvg` and `pip install pillow`):

```bash
python3 tool/generate_icons.py
```

The script rewrites the Android mipmaps and splash drawables, the iOS
`AppIcon` and `LaunchImage` sets and the web icons. The 1024 px master is
`tool/brand/app-icon-1024.png`. The app name is "SecurIoT" on every platform.

## CI/CD

| Workflow | Trigger | What it does |
| --- | --- | --- |
| `.github/workflows/ci.yml` | push and pull request to `develop` and `main` | Flutter 3.44.2: `flutter pub get`, `flutter analyze`, `flutter test`, then `flutter build apk --debug` with a dummy `android/app/google-services.json` created inside the job. |
| `.github/workflows/cd.yml` | push to `develop` | Builds the release APK with `API_BASE_URL=https://securiot-api.juan-tech.com/api/v1`, build name from `pubspec.yaml` and build number from the run number, uploads it as a workflow artifact, and distributes it to the `testers` group of Firebase App Distribution (app `1:470589923206:android:b4712e383a58142b6dd607`, project `securiot-centinela-labs`). Release notes come from the merge commit message. |

Secrets used (repository secrets, names only): `GOOGLE_SERVICES_JSON` (base64 of `android/app/google-services.json`, already set) and `FIREBASE_SERVICE_ACCOUNT_JSON` (service account key, see below). Without `FIREBASE_SERVICE_ACCOUNT_JSON` the CD workflow skips the distribution step with a notice and still uploads the APK as an artifact.

`android/app/google-services.json` is git-ignored and never committed. To refresh the secret from a machine that has the file:

```bash
base64 < android/app/google-services.json | gh secret set GOOGLE_SERVICES_JSON --repo securiot2026/securiot-mobile-app
```

### Add `FIREBASE_SERVICE_ACCOUNT_JSON`

1. Open the Firebase console, project `securiot-centinela-labs`, Project settings, Service accounts.
2. Open the Google Cloud service accounts page from there and pick (or create) a service account with the role **Firebase App Distribution Admin**.
3. Keys tab, Add key, Create new key, JSON. The file downloads to your machine.
4. Store it as a secret, then delete the file:

   ```bash
   gh secret set FIREBASE_SERVICE_ACCOUNT_JSON --repo securiot2026/securiot-mobile-app < key.json
   rm key.json
   ```

### Manual distribution (what was done by hand before CD)

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://securiot-api.juan-tech.com/api/v1
firebase appdistribution:distribute build/app/outputs/flutter-apk/app-release.apk \
  --app 1:470589923206:android:b4712e383a58142b6dd607 \
  --project securiot-centinela-labs \
  --groups testers \
  --release-notes "Describe the change"
```

Release builds are signed with the debug configuration until a release keystore exists (see `android/app/build.gradle.kts`). Testers can install them, but they are not suitable for the Play Store.

## Architecture

- `lib/core/`, theme (shared SecurIoT palette/type/spacing, translated to
  Material 3), i18n (dependency-free string-table localization), API client
  and per-resource repositories, secure token/language storage.
- `lib/models/`, plain Dart models mapping the Cloud API's JSON shapes
  (`Zone`, `Device`, `Reading`, `Alert`).
- `lib/providers/`, `AuthProvider` (session lifecycle) and `LocaleProvider`
  (persisted language), both via `package:provider`.
- `lib/screens/`, one folder per screen/tab (`auth`, `shell`, `zones`,
  `devices`, `alerts`).
- `lib/widgets/`, shared UI: status/severity badges (icon + text + color),
  loading/error/empty state views, the language switcher, and the Astryx
  inspired set (`StatusTile`, `FilterChipsBar`, `SearchField`, `EmptyState`,
  `SectionHeader`).

## Design system

Palette, type scale, spacing scale, and status-color vocabulary are
inherited from the sibling Web App / Landing Page surfaces
(`.planning/phases/03-web-dashboard-landing-page/UI-SPEC.md`), translated
into native Material 3 idioms (bottom navigation instead of a sidenav,
Material components instead of Angular Material). See `DESIGN.md` for the
as-built record of this surface's system.
