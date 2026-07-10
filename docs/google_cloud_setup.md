# Google Cloud and Firebase Setup

This guide is an activation runbook, not a record of completed cloud work. The secure backend source is reviewable and testable locally, but live Google calls must remain disabled until every cost and security gate below is satisfied.

## Reviewed Target

- Google Cloud and Firebase project: `wingman-interactive-live`
- Functions region: `us-central1`
- Firebase Functions codebase: `gomode`
- Runtime: Node.js 22
- Runtime limits: 256 MiB, 15-second global timeout, `minInstances: 0`, `maxInstances: 3`, global `concurrency: 10`; `roadTripStops` concurrency 2; road-trip, Air Quality, Solar, and photo proxy timeout 30 seconds
- Production protocol: Firebase Functions v2 callable functions with App Check enforcement

The July 10, 2026 read-only audit found:

- The target project is active and billing-enabled.
- Places API (New), Routes API, Air Quality API, Pollen API, and Solar API are disabled.
- Secret Manager is enabled and contains an unrelated `OPENWEATHER` secret. GoMode must not reuse or modify it.
- The project has two automatically managed Firebase client keys, neither of which is an appropriate GoMode server key.
- Existing Firebase apps and Gen2 Functions are unrelated to GoMode.
- The Cloud Billing Budget API was unavailable to the active CLI quota project, so existing budgets were not verified or changed.

No APIs, Firebase apps, API keys, secrets, quotas, budgets, or Functions were created or changed during implementation.

## Deployment Isolation

`firebase.json` assigns `functions/` to codebase `gomode`. Always scope a future deployment to that codebase:

```sh
firebase deploy \
  --only functions:gomode \
  --project wingman-interactive-live
```

Do not use an unscoped `firebase deploy`, `firebase deploy --only functions`, or `--force`. Those forms can compare this repository with unrelated Functions in the shared project. Also do not use `firebase deploy --dry-run` before approval: the CLI warns that a dry run may still enable APIs on the target project.

## Gate 1: Reconfirm Identity and Existing State

The `authuser=2` parameter in a Console URL does not select a CLI account. Before any future mutation, run these read-only checks and verify the expected account in their output:

```sh
gcloud auth list --filter=status:ACTIVE --format='value(account)'
gcloud config get-value project
firebase login:list
firebase projects:list
gcloud projects describe wingman-interactive-live
gcloud billing projects describe wingman-interactive-live
gcloud services list --enabled --project wingman-interactive-live
gcloud functions list --v2 --regions us-central1 --project wingman-interactive-live
firebase functions:list --project wingman-interactive-live
firebase apps:list --project wingman-interactive-live
gcloud secrets list --project wingman-interactive-live --format='value(name)'
gcloud services api-keys list \
  --project wingman-interactive-live \
  --format='table(name,displayName,restrictions)'
```

List secret metadata only. Do not access secret values or print API key strings during inspection.

## Gate 2: Budget and Alert Review

Resolve the billing account without changing it:

```sh
gcloud billing projects describe wingman-interactive-live \
  --format='value(billingAccountName)'
```

With the returned billing account ID, the reviewed budget-list command is:

```sh
gcloud billing budgets list --billing-account BILLING_ACCOUNT_ID
```

If this reports that the Cloud Billing Budget API is disabled, stop. Do not enable that API automatically. An authorized billing administrator should inspect or create a narrowly scoped budget in Cloud Billing first.

Budget alerts are notifications, not hard spending caps. Suggested alert thresholds are 50%, 75%, 90%, and 100% of a deliberately small monthly pilot budget, with a monitored notification destination. A budget alone does not make API activation safe.

## Gate 3: Reviewed API Enablement Plan

Enabling these APIs can permit billable requests. Print and review this exact command with the project owner before running it:

```sh
gcloud services enable \
  places.googleapis.com \
  routes.googleapis.com \
  airquality.googleapis.com \
  pollen.googleapis.com \
  --project wingman-interactive-live
```

This core activation deliberately excludes `solar.googleapis.com`. Keep both the Solar API and `ENABLE_SOLAR_API` disabled until the separate Solar gate below. Do not add Geocoding API for `solarCheck`; the implementation resolves an address through the already planned Places API and then calls Solar with coordinates.

After an approved enablement, repeat `gcloud services list --enabled` and verify that no unexpected API was enabled.

## Gate 4: Enumerate and Lower Quotas

Quota metric identifiers are service- and project-specific and cannot safely be guessed before each API is enabled. After approved API enablement, but before creating a key, secret, or Function, enumerate every adjustable quota in Google Cloud Console under **IAM & Admin > Quotas & System Limits**, filtered to `wingman-interactive-live` and each enabled service. Record the exact metric ID, unit, current limit, proposed limit, and whether Google allows a decrease.

The installed Cloud CLI did not have the beta quota command group available, so this runbook intentionally does not provide a speculative quota-override command. Do not install a component or submit an override until the exact metric IDs are reviewed.

Conservative pilot targets, where matching adjustable metrics exist, are:

| Service or operation | Initial target |
| --- | ---: |
| Places search, details, and autocomplete | 60 requests/minute each |
| Place Photo | 30 requests/minute |
| Routes Compute Routes | 30 requests/minute |
| Air Quality | 10 requests/minute |
| Pollen | 10 requests/minute |
| Solar, after its separate gate | 10 requests/minute |

These are review targets, not commands. Apply only the metrics that actually exist. Road-trip requests can fan out to one route request plus several bounded place searches, so its callable-level traffic must be lower than the raw Places quota.

Stop if a sufficiently conservative quota cannot be applied. Continue only after the owner records the quota changes and confirms the budget notification path.

## Gate 5: Create a Dedicated Restricted Server Key

Do not reuse either Firebase-managed client key. After quotas are in place, create a new key with API restrictions applied atomically:

```sh
gcloud services api-keys create \
  --display-name='GoMode Functions Google APIs' \
  --api-target=service=places.googleapis.com \
  --api-target=service=routes.googleapis.com \
  --api-target=service=airquality.googleapis.com \
  --api-target=service=pollen.googleapis.com \
  --project wingman-interactive-live \
  --format='value(name)'
```

Save the returned resource name as `KEY_RESOURCE`; it is metadata, not the key string. Gen2 Functions do not have a stable outbound IP by default, so do not invent an IP allowlist. Static egress would require separately reviewed networking resources and cost. API restrictions, Secret Manager, App Check, quotas, and runtime limits are the controls for this stage.

Move the key value directly into Secret Manager without printing it:

```sh
gcloud services api-keys get-key-string KEY_RESOURCE \
  --format='value(keyString)' \
  | firebase functions:secrets:set GOMODE_GOOGLE_MAPS_API_KEY \
      --data-file=- \
      --project wingman-interactive-live
```

Create an independent signing secret without writing it to disk:

```sh
openssl rand -base64 48 \
  | firebase functions:secrets:set GOMODE_PHOTO_PROXY_SIGNING_KEY \
      --data-file=- \
      --project wingman-interactive-live
```

See `secrets.md` for local emulation, rotation, and incident handling.

## Gate 6: Separate Solar Activation

Leave this gate incomplete for the initial deployment. Before Solar activation, review product behavior, likely address coverage, budget notifications, and an exact adjustable Solar quota metric. Then print and approve this command separately:

```sh
gcloud services enable \
  solar.googleapis.com \
  --project wingman-interactive-live
```

Enumerate the newly available Solar quota metric IDs as required by Gate 4 and lower the applicable limit before updating the key. Add Solar while preserving every existing API restriction:

```sh
gcloud services api-keys update KEY_RESOURCE \
  --api-target=service=places.googleapis.com \
  --api-target=service=routes.googleapis.com \
  --api-target=service=airquality.googleapis.com \
  --api-target=service=pollen.googleapis.com \
  --api-target=service=solar.googleapis.com \
  --project wingman-interactive-live \
  --format='value(name)'
```

Only after the API, quota, restriction, no-coverage UI, and low-volume smoke-test plan are approved should `ENABLE_SOLAR_API` be set true for a narrowly scoped `functions:gomode` deployment. No Geocoding API is required.

## Gate 7: Feature Flags

Keep both non-secret flags false for the first deployment review:

```text
ENABLE_SOLAR_API=false
ENABLE_AIR_QUALITY_FORECAST=false
```

The Functions code supplies safe false defaults. Do not use deprecated `firebase functions:config:set`, and do not commit a Functions `.env` file. If a future deployment prompt persists parameter values locally, confirm the generated file is ignored before entering values.

Enable Solar only after Solar API quota, address-resolution behavior, and unavailable/no-coverage UI have been verified. Enable Air Quality forecast only after its additional request volume and forecast horizon are approved. Current conditions remain separately supported.

## Gate 8: Register GoMode Firebase Apps and App Check

Current apps in the project are unrelated. Do not attach GoMode to an existing registration. When the owner approves registration, review these exact creation commands first:

```sh
firebase apps:create ANDROID 'GoMode Android' \
  --package-name com.mleikam.gomode \
  --project wingman-interactive-live

firebase apps:create IOS 'GoMode iOS' \
  --bundle-id com.mleikam.gomode \
  --project wingman-interactive-live

firebase apps:create WEB 'GoMode Web' \
  --project wingman-interactive-live
```

Then configure App Check for each new app in Firebase Console:

- Android release: Play Integrity
- Apple release: App Attest with DeviceCheck fallback
- Web: a dedicated reCAPTCHA v3 site key with domain restrictions
- Debug builds: local App Check debug tokens only; never commit or share them

Platform Firebase configuration contains public client identifiers, but repository policy keeps generated config files and API keys untracked. Supply them through the approved build/CI process. Do not substitute the server key for any platform configuration.

The Flutter build expects the following public defines when Firebase is enabled: `GOMODE_FIREBASE_API_KEY`, `GOMODE_FIREBASE_APP_ID`, `GOMODE_FIREBASE_MESSAGING_SENDER_ID`, and `GOMODE_FIREBASE_PROJECT_ID`. Optional values are `GOMODE_FIREBASE_AUTH_DOMAIN`, `GOMODE_FIREBASE_STORAGE_BUCKET`, and `GOMODE_FIREBASE_MEASUREMENT_ID`. `GOMODE_FIREBASE_FUNCTIONS_REGION` defaults to `us-central1`; web also needs the restricted public `GOMODE_RECAPTCHA_SITE_KEY`. Keep concrete app-registration values outside Git even though they are public client identifiers; documenting the target project and region is safe. Never supply the Maps server secret as a Dart define.

### Native map widget (optional)

The map screen works without a native SDK key by rendering the interactive
fallback canvas. To enable `GoogleMap`, create a separate client-side Maps SDK
key restricted to the Android package/signing certificate or iOS bundle ID and
enable only the platform Maps SDK it needs. Do not reuse the server-side
`GOMODE_GOOGLE_MAPS_API_KEY`.

- Android: pass `GOMODE_GOOGLE_MAPS_ANDROID_SDK_KEY` as a Gradle property.
- iOS: define `GOMODE_GOOGLE_MAPS_IOS_SDK_KEY` in an untracked or CI-provided
  Xcode build setting.
- Flutter: launch with
  `--dart-define=GOMODE_MAPS_WIDGET_ENABLED=true` only after native setup is
  complete.

## Gate 9: Local Verification and Narrow Deployment

Backend tests use mocks and require no live secret:

```sh
cd functions
npm ci
npm run lint
npm run build
npm test
cd ..
dart format .
flutter analyze
flutter test
```

Before deployment, run a secret scan and inspect the exact diff. Confirm the Functions exports, codebase, region, secret bindings, flags, memory and per-function timeout values, `minInstances: 0`, `maxInstances: 3`, global `concurrency: 10`, the `roadTripStops` concurrency override of 2, and App Check enforcement.

Only after every prior gate is recorded and approved should the owner run:

```sh
firebase deploy \
  --only functions:gomode \
  --project wingman-interactive-live
```

After deployment, verify only GoMode function names changed, perform low-volume smoke tests, inspect request/error counts, and keep Solar and Air Quality forecast disabled until their separate gates are approved.

## Rollback

Do not delete shared-project Functions as an ad hoc rollback. First disable live backend configuration in the client or feature flags, then redeploy a known-good `gomode` codebase if needed. Revoke the dedicated API key and rotate both secrets immediately if either may have been disclosed. Coordinate any Function deletion with the project owner and always scope it to the known GoMode function names.
