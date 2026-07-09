# GoMode

Pick your mood. Find your move.

GoMode is a Flutter local discovery app organized around the question: "What mode are you in today?" The bootstrap milestone creates the production-ready project shell, core architecture folders, initial mode picker screen, and developer docs.

## Current Stack

- Flutter stable 3.44.4 and Dart 3.12.2
- Material 3
- GoRouter for navigation
- Riverpod for state management and dependency injection
- Dio for networking
- Shared preferences for lightweight local storage
- Geolocator and Google Maps Flutter for future location and map experiences

Firebase CLI and Google Cloud CLI are installed locally, but Firebase is not initialized yet because no project configuration was provided. GitHub CLI was not installed during bootstrap because it is not required for the local milestone.

## Getting Started

```sh
flutter pub get
dart format .
flutter analyze
flutter test
flutter run
```

To run on an Android emulator:

```sh
flutter emulators --launch Medium_Phone_API_36.1
flutter run -d emulator-5554
```

## Secrets

Copy `.env.example` to `.env` for local-only configuration. Never commit API keys, signing credentials, generated service account keys, or local `.env` files.

## Docs

- Architecture: `docs/architecture.md`
- Bootstrap decisions: `docs/decisions.md`
- Approved design references: `docs/design_refs/approved/`
