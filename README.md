# GoMode

Pick your mood. Find your move.

GoMode is a Flutter local-discovery MVP organized around the question “What
mode are you in today?” It is fully usable with clearly labeled local demo data
and has an optional Firebase Functions boundary for live Google Maps Platform
and Google Environment data.

## What is built

- Responsive Flutter app with Home, Modes, Map, Saved, and Profile navigation.
- A 20-mode catalog with search, category filters, detail/setup screens, result
  states, saving, and mode-specific interactions.
- Polished Date Night planning and Road Trip Stops flows.
- Local Saved plans, places, routes, quests, collections, and persisted profile
  preferences.
- Foreground-location handling with a usable Austin fallback when permission is
  denied, disabled, or unavailable.
- Optional native Google Maps widget plus a functional placeholder when native
  Maps SDK keys are absent.
- Optional Firebase callable backend with App Check, validation, bounded
  payloads, minimal Google API field masks, retries, caching, and disclosed demo
  fallback.
- TypeScript adapters for Places, Routes, Air Quality, Pollen, Solar, Place
  Autocomplete, and a signed Place Photo proxy.
- Offline Flutter and backend tests, screenshot tooling, CI checks, branding,
  and release-preparation scripts.

Current reference captures are in [docs/screenshots/current](docs/screenshots/current/).

## Prerequisites

- Flutter stable 3.44.4 or a compatible newer stable release
- Dart 3.12.2 or the version bundled with Flutter
- Android Studio/SDK or Xcode for a mobile target
- Node.js 22 for the optional Functions backend
- Firebase CLI only when testing or deploying Firebase Functions

## Run in demo mode

Demo mode is the default and requires no credentials or cloud project.

```sh
flutter pub get
flutter run
```

For the checked Android emulator:

```sh
flutter emulators --launch Medium_Phone_API_36.1
flutter run -d emulator-5554
```

The app will use local results, mark fallback content as demo data, and make no
Google Cloud calls while Firebase and the development proxy are unconfigured.

## Configure Google Cloud and Firebase

Cloud activation is intentionally opt-in. No Google APIs, API keys, Firebase
apps, secrets, quotas, budgets, or Functions are created by running the app.
Follow the reviewed, ordered gates in
[docs/google_cloud_setup.md](docs/google_cloud_setup.md) before enabling live
traffic.

At a high level:

1. Reconfirm the Firebase/Google Cloud project, billing alerts, and conservative
   quotas.
2. Enable only the APIs required by approved features.
3. Create a dedicated, API-restricted server key and stream it directly into
   the `GOMODE_GOOGLE_MAPS_API_KEY` Firebase secret. Create the independent
   `GOMODE_PHOTO_PROXY_SIGNING_KEY` secret the same way.
4. Register new GoMode Firebase apps; do not reuse unrelated registrations.
5. Configure App Check for each platform.
6. Deploy only the isolated Functions codebase:

   ```sh
   firebase deploy --only functions:gomode --project wingman-interactive-live
   ```

7. Supply the public Firebase app identifiers to Flutter at build time and
   explicitly enable Firebase:

   ```sh
   flutter run \
     --dart-define=GOMODE_FIREBASE_ENABLED=true \
     --dart-define=GOMODE_FIREBASE_PROJECT_ID=YOUR_PROJECT_ID \
     --dart-define=GOMODE_FIREBASE_API_KEY=YOUR_PUBLIC_FIREBASE_CLIENT_KEY \
     --dart-define=GOMODE_FIREBASE_APP_ID=YOUR_FIREBASE_APP_ID \
     --dart-define=GOMODE_FIREBASE_MESSAGING_SENDER_ID=YOUR_SENDER_ID
   ```

Public Firebase client configuration is not the Maps server credential. Never
pass `GOMODE_GOOGLE_MAPS_API_KEY` to Flutter.

To use the native map widget, configure a separate platform-restricted Maps SDK
key through `GOMODE_GOOGLE_MAPS_ANDROID_SDK_KEY` (Gradle property) or
`GOMODE_GOOGLE_MAPS_IOS_SDK_KEY` (Xcode build setting), then add
`--dart-define=GOMODE_MAPS_WIDGET_ENABLED=true`. The complete platform and
App Check instructions are in the setup guide.

## Add secrets safely

- Never commit `.env`, service-account JSON, signing files, API keys, Firebase
  platform config, App Check debug tokens, or `functions/.secret.local`.
- `.env.example` contains names and safe defaults only. Flutter does not load a
  repository `.env` automatically.
- Store production backend secrets in Google Secret Manager through Firebase
  Functions secret bindings.
- Store public build configuration and native platform keys in the protected CI
  secret/build-settings system. Keep local equivalents ignored or outside the
  repository.
- Use `functions/.secret.local` only for an explicitly approved Functions
  emulator test with a restricted development key and low quotas. Confirm it is
  ignored with `git check-ignore functions/.secret.local` and delete it after
  use.
- Do not create or download service-account JSON; deployed Functions use their
  managed runtime identity.

See [docs/secrets.md](docs/secrets.md) for rotation and incident handling.

## Run tests and checks

Run the complete Flutter repository check:

```sh
tools/check.sh
```

Equivalent individual commands are:

```sh
flutter pub get
dart format .
flutter analyze
flutter test
```

Build and test the backend without credentials or live Google calls:

```sh
cd functions
npm ci
npm run lint
npm run build
npm test
```

See [docs/final_qa_report.md](docs/final_qa_report.md) for the final MVP QA
evidence and results.

## Current limitations

- Live Google/Firebase traffic remains disabled until the cloud activation
  gates, app registration, App Check, quotas, and secrets are completed.
- The native map uses a local interactive placeholder unless separate,
  platform-restricted Maps SDK keys and the map feature flag are configured.
- Saved content and profile settings are local to the device; there is no user
  account or cross-device sync in the MVP.
- Monetization surfaces are disabled abstractions/debug previews only; no real
  ads, purchases, affiliate links, or lead storage are connected.
- Android store signing is not configured. The debug build is installable, but
  a protected release keystore and store workflow are required before release.
- Solar and Air Quality forecast are independently disabled until their cost,
  quota, and product gates are approved.
- Flutter currently reports upstream future-migration warnings for FlutterFire
  plugins that still apply the Kotlin Gradle Plugin. They do not block the
  current Android build.

## Documentation

- [Architecture](docs/architecture.md)
- [API contract](docs/api_contract.md)
- [Functions backend](functions/README.md)
- [Google Cloud and Firebase setup](docs/google_cloud_setup.md)
- [Secrets and rotation](docs/secrets.md)
- [Product and technical decisions](docs/decisions.md)
- [Approved design references](docs/design_refs/approved/)
- [Final QA report](docs/final_qa_report.md)
