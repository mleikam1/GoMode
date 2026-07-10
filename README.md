# GoMode

Pick your mood. Find your move.

GoMode is a Flutter local discovery app organized around the question: "What mode are you in today?" It uses local demo data by default and includes an optional Firebase Functions boundary for live Google Maps Platform and Google Environment data.

## Current Stack

- Flutter stable 3.44.4 and Dart 3.12.2
- Material 3
- GoRouter for navigation
- Riverpod for state management and dependency injection
- Dio for networking
- Shared preferences for lightweight local storage
- Geolocator and Google Maps Flutter for location and future map experiences
- Firebase callable Functions and App Check for the optional secure backend
- TypeScript Functions on Node.js 22 for Places, Routes, Air Quality, Pollen, and Solar adapters

The backend source targets the existing `wingman-interactive-live` project in `us-central1`, but no APIs, secrets, Firebase app registrations, quotas, or Functions were created or changed as part of the code milestone. Live calls remain disabled until the reviewed setup gates in `docs/google_cloud_setup.md` are completed.

## Getting Started

```sh
flutter pub get
dart format .
flutter analyze
flutter test
flutter run
```

Build and test the backend without live Google calls:

```sh
cd functions
npm ci
npm run lint
npm run build
npm test
```

To run on an Android emulator:

```sh
flutter emulators --launch Medium_Phone_API_36.1
flutter run -d emulator-5554
```

## Secrets

Never commit API keys, signing credentials, generated service-account keys, platform Firebase configuration, local `.env` files, or `functions/.secret.local`. Production backend secrets belong in Google Secret Manager through Firebase Functions secret bindings. See `docs/secrets.md`.

The Flutter app starts in demo mode. Firebase initialization is opt-in through build-time configuration and is intentionally deferred until GoMode-specific Firebase apps are registered. The production transport is Firebase callable Functions; the HTTP base URL setting exists only for compatible local proxies and emulators.

Configured builds receive public Firebase client identifiers through Dart defines: `GOMODE_FIREBASE_API_KEY`, `GOMODE_FIREBASE_APP_ID`, `GOMODE_FIREBASE_MESSAGING_SENDER_ID`, and `GOMODE_FIREBASE_PROJECT_ID`, plus optional auth-domain, storage-bucket, and measurement identifiers. App-registration-specific values remain uncommitted; the non-sensitive target project and region defaults are documented. These values are distinct from `GOMODE_GOOGLE_MAPS_API_KEY`, which is a backend-only Secret Manager value and must never enter a Flutter build.

## Docs

- [Architecture](docs/architecture.md)
- [API contract](docs/api_contract.md)
- [Functions backend](functions/README.md)
- [Google Cloud and Firebase setup](docs/google_cloud_setup.md)
- [Secrets and rotation](docs/secrets.md)
- [Product and technical decisions](docs/decisions.md)
- [Approved design references](docs/design_refs/approved/)
