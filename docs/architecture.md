# GoMode Architecture

GoMode is a Flutter app using Material 3, GoRouter, and Riverpod. The app is split by app shell, shared infrastructure, and feature modules so the local discovery modes can grow without turning `main.dart` into the application.

## Layers

- `lib/main.dart` boots Flutter and installs Riverpod's `ProviderScope`.
- `lib/app/` owns the root `MaterialApp.router` and top-level routing.
- `lib/core/` holds cross-cutting constants and app primitives that are independent of a feature.
- `lib/features/` contains user-facing flows. The bootstrap milestone includes `features/home`.
- `lib/data/` holds simple data models and repositories. Remote/local data sources can be added here as APIs are chosen.
- `lib/services/` contains infrastructure adapters such as HTTP, local preferences, and device location.
- `lib/shared/` contains reusable UI and theme code.
- `assets/images/` and `assets/icons/` are reserved for production visual assets.
- `docs/` and `tools/` hold project documentation and developer utilities.

## Dependency Direction

Features may depend on `core`, `data`, `services`, and `shared`. Shared/core code should not import feature modules. Services expose small provider-backed adapters so implementations can be swapped in tests and future milestones.

## Location And Maps

Location and map packages are installed, but the home screen does not request location yet. Runtime prompts should appear only after a user action clearly needs nearby results. Google Maps keys belong in local or platform-specific secret configuration, not directly in source files.

## Firebase

Firebase is deferred until a real Firebase project is selected. Do not add generated Firebase or Google config files without reviewing whether they are safe to commit for the chosen release process.
