# GoMode Decisions

## 2026-07-09 Bootstrap

- Used the current local repo at `/Users/MattLeikam/Documents/GoMode` and attached `https://github.com/mleikam1/GoMode` as `origin` because the folder had Git metadata but no remote.
- Created branch `codex/bootstrap-gomode` on the initial, empty repository history.
- Generated the Flutter app in the repo root with project name `gomode` and org `com.mleikam`, producing `com.mleikam.gomode` for Android and iOS.
- Chose Riverpod for state management because it matches the request default and provides lightweight dependency injection for services.
- Chose handwritten starter models instead of code generation for the bootstrap to keep the first milestone fast and reviewable.
- Added `go_router`, `dio`, `shared_preferences`, `geolocator`, and `google_maps_flutter` for the expected production surfaces.
- Did not initialize Firebase because no Firebase project or app config was provided. Firebase CLI is available locally, but generated config should be added in a dedicated milestone.
- Documented Google API key placeholders in `.env.example`; no real keys or secrets were added.
- GitHub CLI was not installed because it was missing and not required for this local bootstrap milestone.

## Tooling Observed

- Flutter stable 3.44.4 and Dart 3.12.2 are installed.
- Android Studio and the Android SDK are available through Flutter doctor.
- Java is available; Flutter doctor uses Android Studio's bundled JDK 21 for Android builds.
- Xcode command line tools are selected at `/Applications/Xcode.app/Contents/Developer`.
- CocoaPods 1.16.2 is installed.
- Firebase CLI 15.9.0 is installed, but its update check cannot write to `/Users/MattLeikam/.config` from the sandbox.
- Google Cloud SDK 565.0.0 is installed, with a warning that its Python 3.9 runtime is no longer officially supported.
- GitHub CLI was not found on `PATH`.
