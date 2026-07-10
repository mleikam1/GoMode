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

## 2026-07-09 Design System Foundation

- Located the generated design reference package at `/Users/MattLeikam/Downloads/gomode_design_reference_package.zip`.
- Copied approved mockups into `docs/design_refs/approved/` and earlier iterations into `docs/design_refs/archive/`.
- Treated the mockups as documentation references only. Runtime UI uses Flutter widgets, gradients, icons, and lightweight `CustomPainter` illustrations.
- Centralized GoMode visual tokens under `lib/core/theme/` so screen code consumes named colors, spacing, radii, and shadows instead of local one-off values.
- Kept typography on system fonts because no safe custom font package or font asset is configured yet.
- Added shared widgets under `lib/shared/widgets/` to support the approved home, modes, date-night, road-trip, and saved layouts as composable Flutter pieces.

## 2026-07-10 Navigation Shell and Mode Catalog

- Used `StatefulShellRoute.indexedStack` for the five main tabs so each tab can keep its navigation state while the bottom navigation remains visible.
- Kept `/` as a redirect to `/home`; `/date-night` and `/road-trip` redirect to their catalog-backed mode detail routes so legacy/deep links do not become dead ends.
- Expanded the local `DiscoveryMode` model into the app-wide mode catalog instead of adding code generation, keeping the milestone reviewable while preserving typed enums for category and query strategy.
- Stored icon semantic names separately from Flutter `IconData` so the catalog can map cleanly to server payloads later without leaking widget concerns into API data.
- Added local demo results to every mode as temporary product data until Google Places, Routes, environmental, and Solar integrations are connected.

## 2026-07-10 Home Screen

- Implemented the approved Home screen with reusable shared widgets and catalog-backed navigation instead of static screenshots or route placeholders.
- Kept the Home weather signal as an injectable placeholder string until live weather or environmental data exists; the spin demo maps rainy placeholder values to Rainy Day Ideas.
- Used simple weighted demo rules for Spin My Mode with explicit user intent first: active Road Trip filter, rainy placeholder, evening Date Night, weekend Weekend Plan, then a local random fallback.

## 2026-07-10 Modes Discovery Screen

- Treated `02_modes_latest_large_category_carousels.png` as the current Modes reference and replaced the dense catalog layout with a featured `PageView` plus wider horizontal category carousels.
- Kept Popular as the default discovery landing so all 20 catalog modes remain discoverable; Nearby, Family, Road, Health, search, and category See all states narrow the visible mode set.
- Replaced the prior Open Now catalog slot with the approved Outdoor Ideas mode to match the latest Health & Outdoors section while preserving the 20-mode catalog size.
