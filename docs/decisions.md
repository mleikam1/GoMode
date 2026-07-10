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

## 2026-07-10 Clean Date Night Planner

- Routed `date-night` to a dedicated setup and generated-plan flow before the generic `:modeId` route so existing mode cards and deep links open the custom planner without changing catalog URLs.
- Kept the setup screen intentionally limited to budget, vibe, time, and three toggles; the archived sliders and long preference chip list were not restored.
- Added `DateNightPlanningService` as the CTA boundary. The default provider uses local demo generation now and can be replaced by a Google-backed implementation without changing the screen.
- Added a session-local generated-plan store for the first Save Plan behavior. Durable saved-plan persistence can replace this provider when the Saved feature becomes data-backed.
- Generated a dedicated high-resolution Date Night hero asset from the approved art direction and kept all titles, controls, and icons as native Flutter UI for accessibility and interaction.
- Kept Date Night inside the existing Modes shell branch, so the bottom navigation correctly reflects Modes as the active app section even though the visual reference shows a Home-origin state.

## 2026-07-10 Road Trip Stops Results

- Routed `road-trip-stops` directly to a dedicated results experience inside the existing Modes shell branch; legacy `/road-trip` and `/modes/road-trip-stops/results` URLs redirect to the same custom screen.
- Added a `RoadTripRouteService` boundary backed by local Austin-to-San Antonio demo data. A Routes API plus Places route-search implementation can replace the provider without changing presentation widgets.
- Persisted saved stop identifiers with SharedPreferences under `road_trip.saved_stop_ids`; Save and favorite heart actions intentionally share the same durable saved state.
- Kept Navigate and full-map actions inside GoMode's existing map branch until a destination-aware in-app map or external Google Maps URL strategy is selected.
- Used a polished non-Google map placeholder for the Map segment because API-backed map configuration is not required for this milestone.
- Generated three project-local, high-resolution raster assets for Buc-ee's New Braunfels, the scenic overlook, and the local BBQ stop to match the approved result-card art direction without a network dependency.

## 2026-07-10 Saved Items and Local Persistence

- Added a domain-level `SavedItem` model for plans, places, routes, and quests, plus a `SavedCollection` model. Presentation code depends on a `SavedRepository` contract rather than SharedPreferences so a Firestore-backed repository can replace the local implementation later.
- Stored versioned JSON payloads behind a minimal `SavedLocalStorage` abstraction. SharedPreferences is the current adapter; no backend, account, or network dependency is required.
- Seeded the four approved Saved cards as plan entries on the first repository initialization. A separate persisted seed-complete flag prevents the demo items from returning after a user removes them all.
- Classified newly saved generic result cards from their mode query strategy: generic plan generators become plans, nearby/text/environmental/solar results become places, route searches become routes, and game quests become quests.
- Kept Date Night's session store and Road Trip's saved-stop store as compatibility boundaries for their existing screens, while also writing every user action to the unified Saved repository. Their controls update optimistically before the durable local write completes.
- Created four project-local raster thumbnails from the approved Saved art direction instead of reusing code-drawn placeholder illustrations.
- Reduced the shared bottom-navigation height to the approved mobile proportions and tightened its internal icon/label rhythm. The same five destinations and navigation behavior remain unchanged.

## 2026-07-10 Complete Mode Flows

- Restored Open Now as the twentieth catalog mode, replacing Outdoor Ideas, so the product set matches the requested 20-mode list while keeping every catalog entry discoverable.
- Kept Date Night and Road Trip Stops on their existing custom screens. The other 18 modes use one configurable setup/results flow with no more than five filters, a mode-specific CTA, a mode-accent hero, shared save/navigation actions, and explicit loading, empty, error, and retry states.
- Added a replaceable `GenericModeResultsService` boundary. It currently returns local fallback content because Places, Routes, pollen, AQI, charger, Solar, and neighborhood backends are not connected.
- Show fallback labels only in debug builds. Production builds do not present fallback content as live data: current hours, ratings, pet policies, charger availability, pollen, AQI, prices, solar suitability, housing costs, and commute details are either omitted or called out as unverified.
- Solar Checker requires an address but returns only a lead-style next-step placeholder; it does not claim roof, shade, production, savings, or installation analysis.
- Allergy Map and Clean Air Planner show that live environmental data is unavailable before offering neutral indoor/outdoor planning ideas. Dog-Friendly Spots, EV Charge & Chill, Open Now, and Road Rescue include verification or safety caveats.
- Weekend Plan generates five ordered stops, Tourist Mode generates four self-guided stops, Food Wheel animates and selects one result, and Food Challenge plus Local Quest share local progress controls.
- Generic result saves use the unified Saved repository and stable mode/result identifiers. Navigate currently opens the existing in-app Map tab until destination-aware map routing is connected.

## 2026-07-10 Secure Google API Backend

- Chose Firebase Functions v2 with TypeScript on the supported Node.js 22 runtime and callable functions so Flutter can use Firebase App Check without storing a server credential. All production callables enforce App Check and return bounded GoMode payloads.
- Assigned the backend the isolated Firebase codebase name `gomode`, region `us-central1`, zero minimum instances, a maximum of three instances, and global concurrency of ten per instance. `roadTripStops` overrides concurrency to two because its bounded route workflow can fan out to three Places calls. Road-trip, Air Quality, Solar, and photo proxy operations use 30-second timeouts; other callables retain 15 seconds. Future deploys must target `functions:gomode` because the selected project already contains unrelated Gen2 Functions.
- Kept the Google server API key exclusively in the project-isolated `GOMODE_GOOGLE_MAPS_API_KEY` Secret Manager binding. Added a separate `GOMODE_PHOTO_PROXY_SIGNING_KEY` for five-minute photo proxy URLs so neither secret nor a key-bearing Google photo URL reaches Flutter.

- Added non-secret `ENABLE_SOLAR_API` and `ENABLE_AIR_QUALITY_FORECAST` flags. Disabled integrations return structured unavailable states instead of prompting an accidental API enablement or claiming missing data is live.
- Used fixed minimal Google field masks and bounded response objects. Search requests include identity, location, type, and attributed photo metadata; details add rating, current open state, the Google Maps URI, and only the phone/website contact fields used by place actions. Price and broad place payloads are not requested.
- Implemented road-trip stop discovery as a bounded best-effort route plus Places workflow. It samples a limited number of points, deduplicates place IDs, and does not claim an exact detour unless it was computed.
- Made live Firebase initialization optional in Flutter. Repositories fall back to typed Austin-based demo data when backend setup is absent or a transient call fails, while keeping the data source visible to the UI.
- Confirmed the existing `wingman-interactive-live` project is active and billing-enabled. Places, Routes, Air Quality, Pollen, and Solar were disabled; Secret Manager contained only an unrelated secret; the existing Firebase apps, automatic client keys, and deployed Functions were unrelated to GoMode.
- Did not enable APIs, create or modify keys or secrets, register Firebase apps, change quotas or budgets, or deploy Functions. Budget visibility was unavailable without enabling the Cloud Billing Budget API for the active CLI quota project, and budget alerts would not be spending caps in any case.
- Deferred GoMode-specific Firebase Android, Apple, and web app registration. The current map remains a local placeholder, so no client Maps SDK key is needed for this milestone.
- Kept all backend and repository tests offline by mocking the Google/Firebase boundary. Live Google API calls are not required by CI.
- Recorded, but did not force-fix, nine moderate transitive UUID advisories reported by `npm audit --omit=dev` through stable `firebase-functions` 7.2.5, `firebase-admin` 13.10, and Google libraries. The available automated fix would unsafely downgrade Functions to 4.9; monitor for a stable Firebase Functions release with Admin 14 or a patched dependency graph instead.
- Raised the iOS deployment target from 13.0 to 15.0 because the resolved FlutterFire Swift packages declare iOS 15 as their minimum supported platform. macOS remains at 10.15, which matches the resolved packages.
- Gated the Functions emulator and custom HTTP transport behind Flutter's debug build mode so production builds fail closed onto App Check-protected callables even if a development define is supplied accidentally.
- Narrowed Air Quality partial-response selectors to fields normalized by Flutter and reject malformed upstream route metrics rather than presenting fabricated zero-distance live routes.

## 2026-07-10 Live Core Mode Data

- Replaced Date Night's default local generator with three concurrent, bounded Places searches for dinner, an activity, and dessert or drinks. Any missing or fallback category switches the whole plan to the disclosed local fixture instead of mixing live and demo venues.
- Built Weekend Plan from four role-specific searches—food, activity, coffee/dessert, and a scenic local stop—rather than five unrelated calls. Food Wheel uses category-only Nearby Search unless its open-now filter requires Text Search. Kids Bored Button uses one intent-sensitive text query with only documented `park` or `museum` type filters where they fit.
- Kept Patio Finder transparent: “patio” remains a text-search lead, not structured truth. Only this mode pays for rating, review-count, and attributed photo search fields, and it ranks those signals plus patio-style name matches before reminding users to verify outdoor seating.
- Combined Pollen or current Air Quality with one bounded Places suggestion request. Mold is explicitly outside the Pollen API signal. Solar's disabled state now says to connect Solar API and keeps local home/shade inputs as a no-estimate placeholder; it makes no roof, shade, production, savings, or installation claim.
- Continued the bounded route-polyline midpoint strategy for Road Trip Stops. Results mean “near sampled route points,” never an exact detour, and gas-station results never include or imply live fuel prices.
- Added a versioned 32-entry local response cache for configured, idempotent backend calls. Search uses a 10-minute TTL, route/AQI 15 minutes, pollen 6 hours, and Solar 24 hours. Matching in-flight calls coalesce; autocomplete, Place Details, and photos bypass the cache.
- Added 350 ms address autocomplete debouncing and a single Places session token that is closed by the selected Place Details request. Location denial and lookup failures continue to use the visibly marked Austin fallback.
- Validated every hardcoded request type against the current Places API (New) Table A and added a backend allowlist so clients cannot proxy arbitrary type strings. The allowlist is intentionally narrower than Google's full catalog.

## 2026-07-10 — Supporting screens, settings, and privacy

- Profile settings are persisted as one versioned local JSON record so defaults
  can evolve without spreading unrelated keys across storage. The initial
  default-city choices are Austin, Chicago, and Denver; this avoids adding a
  geocoding request just to browse without device location.
- The map composes nearby place results, locally saved places that include
  coordinates, and the active Austin-to-San Antonio road-trip preview. Saved
  items created before coordinates were stored remain valid but are omitted
  from the map until they are saved again from a geocoded result.
- `google_maps_flutter` is gated by `GOMODE_MAPS_WIDGET_ENABLED` and separate,
  platform-restricted native SDK keys. Without both native setup and the flag,
  the app intentionally renders an interactive polished placeholder and a
  debug-only setup note.
- Only foreground location permission is requested. Denied, permanently denied,
  disabled-service, and unavailable states retain a usable Austin fallback and
  explain how to continue or change settings.
- Reset Demo Data clears Saved and Road Trip sample state but intentionally
  preserves profile settings. Clear Cache removes only bounded backend response
  cache entries.
- Developer health checks run only on demand in debug mode. They expose backend
  configuration, the non-secret Firebase project ID, fallback state, map-widget
  state, and a one-result Places probe without displaying credentials.

## 2026-07-10 — Monetization-ready abstractions

- Added one `MonetizationService` boundary for sponsored placements, rewarded
  unlocks, premium entitlement state, and lead capture. The app injects a mock
  implementation only; no ad, purchase, affiliate, or lead backend SDK was
  added.
- Kept all release monetization flags off by default. Debug builds render
  explicitly labeled mock previews so surface placement can be reviewed without
  network calls, tracking, purchases, real ad IDs, or real destinations.
- Reserved at most one sponsored slot after the first organic item in generic
  and Road Trip result lists. Premium ad-removal state suppresses sponsored and
  rewarded surfaces; core results and actions never depend on either.
- Modeled affiliate/sponsor metadata as disabled-by-default result data. A link
  requires both explicit metadata enablement and a presentation-provided opener,
  preventing a destination from becoming active through data alone.
- Kept lead capture fail-closed. Solar Checker, Neighborhood Check, and Where
  Should I Live? can preview and validate the form in debug, but the UI does not
  create or send a `LeadCapture` unless the injected service explicitly reports
  that storage and privacy configuration are ready. The current mock never
  reports ready and discards any direct payload.

## 2026-07-10 — Production UI polish and responsive behavior

- Kept the five files in `docs/design_refs/approved/` as the visual source of
  truth. Shared navy, blue, coral, teal, lavender, amber, radius, and elevation
  tokens remain the implementation boundary instead of screen-specific colors.
- Constrained core content to 840 logical pixels and focused setup surfaces to
  720 logical pixels. Header backgrounds still span wide windows, while text,
  controls, and cards retain readable tablet and web proportions.
- Treated widths below 390 logical pixels as compact phones. Home and Modes use
  tighter header rhythm there, while Date Night keeps its calm single-surface
  flow and remains vertically scrollable for larger text.
- Added reduced-motion-aware route fades/slides, card press scale, mode-wheel
  rotation, Food Wheel rotation, carousel dots, and shimmer skeletons. Motion is
  removed when the platform requests reduced animation.
- Kept production-like debug sessions free of monetization mock placements by
  default. Labeled mock sponsored, rewarded, premium, and lead UI is now opt-in
  with `GOMODE_MONETIZATION_DEBUG_UI=true` so approved-screen QA is not distorted.
- Decode local hero and result images near their rendered pixel size to reduce
  image-cache pressure. Data/service work remains outside widget build methods.
- Added an integration-driver screenshot workflow that captures Home, Modes,
  Date Night, Road Trip, and Saved into `docs/screenshots/current/`.
- Validated the polished build on Android 17 and iOS 26.3 simulators. Flutter
  currently warns that `cloud_functions` and `firebase_app_check` still apply
  the Kotlin Gradle Plugin, and that `google_maps_flutter_ios` does not yet
  support Swift Package Manager. Both platforms build and launch successfully;
  these are upstream future-migration warnings rather than current blockers.
