# GoMode Architecture

GoMode is a Flutter app using Material 3, GoRouter, and Riverpod. The app is split by app shell, shared infrastructure, and feature modules so the local discovery modes can grow without turning `main.dart` into the application.

## Layers

- `lib/main.dart` boots Flutter and installs Riverpod's `ProviderScope`.
- `lib/app/` owns the root `MaterialApp.router` and top-level routing.
- `lib/core/` holds cross-cutting constants and app primitives that are independent of a feature.
- `lib/features/` contains user-facing flows. The bootstrap milestone includes `features/home`.
- `lib/data/` holds simple data models and repositories. Remote/local data sources can be added here as APIs are chosen.
- `lib/services/` contains infrastructure adapters such as Firebase callable transport, HTTP-compatible local transport, local preferences, and device location.
- `lib/shared/` contains reusable UI and theme code.
- `functions/` contains the isolated TypeScript/Node.js 22 backend for validated Google API calls. It is a separate Firebase Functions codebase named `gomode`.
- `assets/images/` and `assets/icons/` are reserved for production visual assets.
- `docs/` and `tools/` hold project documentation and developer utilities.

## Dependency Direction

Features may depend on `core`, `data`, `services`, and `shared`. Shared/core code should not import feature modules. Services expose small provider-backed adapters so implementations can be swapped in tests. Repositories translate normalized backend payloads into app models and own the explicit demo fallback behavior.

## Location And Maps

Location permission is requested only when a user action needs nearby results. If location services, permission, or lookup fails, the app uses Austin, Texas (`30.2672, -97.7431`) and marks it as a fallback. The current map surface remains a local placeholder, so the secure API milestone does not require a client Maps SDK key.

## Secure Google API Boundary

Production requests use Firebase Functions v2 callable functions in `us-central1`. App Check enforcement happens before endpoint logic. Each callable validates and clamps its input, calls one narrowly scoped Google API with the backend-only `GOMODE_GOOGLE_MAPS_API_KEY`, and returns a bounded, documented payload assembled from fixed upstream fields.

The callable boundary covers Places search/details/autocomplete, Routes, bounded road-trip stop discovery, Air Quality, Pollen, and Solar. `placePhoto` is a callable that creates a five-minute signed URL. That URL is consumed by the separate `placePhotoProxy` HTTPS function, which validates its signature and expiry before fetching a canonical Google photo resource. The signing secret never reaches Flutter, and photo attribution metadata stays attached so the UI can display it with every live photo.

Functions use 256 MiB memory, a 15-second global timeout, `minInstances: 0`, `maxInstances: 3`, and global `concurrency: 10` to avoid idle instances and bound simultaneous compute. `roadTripStops` lowers concurrency to 2 because each invocation can issue three Places searches after its Routes call. Road-trip, Air Quality, Solar, and signed photo proxy operations use a 30-second timeout; other callables retain 15 seconds. Road-trip searches cap categories, route sample points, and results per sample because one user request can produce several billable upstream calls.

Flutter selects its data source at runtime:

1. When Firebase is initialized, the app uses callable Functions and App Check.
2. A compatible HTTP transport is available for a local proxy or emulator.
3. When neither is configured, or a repository receives a transient backend failure, it returns typed demo data marked as fallback.

Invalid requests and failed verification are not silently presented as live results. UI state can distinguish live, unavailable, and demo sources.

## Firebase Project Isolation

The backend targets the existing `wingman-interactive-live` project, but GoMode app registration and deployment are deferred. Existing Firebase apps and Gen2 Functions in that project are unrelated. `firebase.json` assigns the backend the `gomode` codebase, and any future deployment must use `--only functions:gomode` so unrelated Functions are not considered for deletion or replacement.

Server secrets are bound from Secret Manager as `GOMODE_GOOGLE_MAPS_API_KEY` and `GOMODE_PHOTO_PROXY_SIGNING_KEY`. `ENABLE_SOLAR_API` and `ENABLE_AIR_QUALITY_FORECAST` are non-secret feature flags. Platform Firebase files, local emulator secrets, API keys, and service-account credentials remain untracked.

See `api_contract.md`, `google_cloud_setup.md`, and `secrets.md` for the concrete protocol and activation gates.
