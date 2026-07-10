# GoMode MVP Final QA Report

Date: 2026-07-10

Branch: `codex/final-qa`

Android target: Medium Phone API 36.1, Android 16 (API 36), arm64

## Result

The GoMode Flutter MVP is buildable, documented, and ready for review. Flutter
formatting, analysis, all 87 Flutter tests, the repository check script, the
Android debug build/install/launch, TypeScript lint/build, and all 23 backend
tests passed. Manual emulator inspection found no broken navigation, Flutter
layout overflow, assertion, or unhandled-exception signatures.

## Completed features

- Home discovery, mode shortcuts, persistent five-tab navigation, and responsive
  approved-design styling.
- Searchable/filterable catalog of exactly 20 modes; every card opens a useful
  destination.
- Date Night preferences, generated itinerary, save/map actions, and disclosed
  demo fallback.
- Road Trip Stops result/map tabs, route summary, stop filtering, save and
  navigation actions, and disclosed demo data.
- Map aggregation, location-permission states, Austin fallback, saved pins, route
  preview, and optional native map integration.
- Saved plans, places, routes, quests, and collections backed by local
  persistence.
- Profile location/preferences, privacy/legal screens, local maintenance
  actions, and debug-only integration health details.
- Optional Firebase callable backend for Places, Routes, Air Quality, Pollen,
  Solar, autocomplete, and signed Place Photo delivery.
- App Check enforcement, strict request validation, minimal field masks,
  bounded fan-out, response caching, and resilient demo fallback.

## Security and configuration review

- No tracked Google API keys, private keys, service-account payloads, signing
  files, or credential bundles were found.
- No local `.env` is present or tracked. `.env.example` is intentionally tracked
  with blank values and safe explanatory text.
- Firebase platform files, service-account patterns, signing files, local
  Functions secrets, generated Firebase options, caches, and `.env*` files are
  ignored.
- Machine-specific paths occur only in `docs/decisions.md`, where they record
  historical local setup; no committed runtime or build config contains a local
  machine path.
- Ignored build caches contain third-party Firebase package example config files;
  none are tracked or used as GoMode configuration.
- The Maps server key is backend-only. The client selects
  `UnconfiguredBackendApiClient` when Firebase or the debug proxy is absent, so
  a default build makes no external backend or Google API request.

## Commands run and results

| Command | Result |
| --- | --- |
| `dart format .` | Passed; no tracked file changes were required. The command also visited ignored generated package caches. |
| `flutter analyze` | Passed; no issues found. |
| `flutter test` | Passed; 87 tests. |
| `tools/check.sh` | Passed: dependency resolution, formatting check, analysis, and 87 tests. |
| `flutter run -d emulator-5554 --debug` | Built `app-debug.apk`, installed, and launched successfully on Android 16. |
| `npm run lint` in `functions/` | Passed. |
| `npm run build` in `functions/` | Passed. |
| `npm test` in `functions/` | Passed; 23 tests. |

The first streamed APK install reported insufficient emulator storage. Flutter
automatically uninstalled the older app instance, retried, and installed the
new debug build successfully. The emulator also displayed a crash dialog for
its preinstalled Digital Wellbeing process; it was dismissed and was unrelated
to GoMode.

## Emulator inspection

Visually inspected:

- Home
- Modes
- Date Night setup
- Date Night generated plan after location denial
- Road Trip Stops
- Saved
- Map after location denial and without native Maps SDK configuration
- Profile

The Map remained usable after permission denial, explained the Austin fallback,
offered Settings, and showed the configured-state placeholder. Date Night
generated a visibly labeled `Demo fallback` plan. Road Trip Stops displayed a
visibly labeled demo route and stop set. Scrollable bottom actions were verified
to move fully above the persistent navigation.

Each catalog item was searched, tapped, and validated by destination title on
the emulator:

1. Date Night
2. Weekend Plan
3. Food Wheel
4. Patio Finder
5. Cheap Date
6. Food Challenge
7. Kids Bored Button
8. Rainy Day Ideas
9. Dog-Friendly Spots
10. Road Trip Stops
11. EV Charge & Chill
12. Road Rescue
13. Open Now
14. Allergy Map
15. Clean Air Planner
16. Solar Checker
17. Neighborhood Check
18. Where Should I Live?
19. Local Quest
20. Tourist Mode

The current app log was checked for `RenderFlex`, overflow, GoRouter/navigation,
assertion, fatal, and unhandled-exception signatures; none were found.

## Google call discipline

- Default demo builds do not initialize a usable backend client and therefore
  make no Google Cloud calls.
- Configured idempotent discovery calls use bounded TTL caches and coalesce
  matching in-flight requests.
- Autocomplete is debounced by 350 ms and uses one session token closed by the
  selected Place Details request.
- Solar and Air Quality forecast are separately disabled by default.
- Road Trip search caps categories and route-point fan-out.
- Backend tests verify minimal Places/Routes/Environment field masks, that only
  Patio Finder requests ranking fields, that Solar makes no request while
  disabled, and that keys never appear in returned URLs.

## Known limitations

- Live Google/Firebase service activation and deployment are intentionally
  incomplete pending budget, quota, App Check, app-registration, and secret
  gates.
- The default map is a polished local placeholder until platform-restricted
  native Maps SDK keys are provided.
- Saved data and profile settings are device-local; accounts and sync are not
  included.
- Real monetization, lead storage, and purchase flows are not connected.
- Android production signing and store release automation remain to be set up.
- Solar and Air Quality forecast stay disabled until separately approved.
- FlutterFire emits a non-blocking warning about future Kotlin Gradle Plugin
  migration.

## Recommended next steps

1. Review and merge the MVP branch.
2. Complete the ordered cloud gates in `docs/google_cloud_setup.md`, starting
   with billing alerts and conservative quotas.
3. Register dedicated GoMode Firebase apps and configure App Check.
4. Add protected Android/iOS release signing and run store release builds.
5. Run a small, monitored live-backend smoke test after scoped deployment.
6. Add physical-device accessibility, large-text, offline, and poor-network
   testing before public release.
7. Monitor FlutterFire releases and migrate when the upstream Kotlin warning is
   resolved.
