# GoMode Firebase Functions

This isolated Firebase Functions codebase keeps Google Maps Platform credentials
on the server. The Flutter app calls App Check-protected callable functions; it
never receives a Google API key.

## Runtime and safeguards

- Node.js 22, TypeScript, Firebase Functions generation 2 in `us-central1`.
- Codebase name: `gomode` (so deploying it does not delete unrelated functions).
- App Check is enforced on every callable function.
- Default capacity is zero warm instances, three maximum instances, and
  concurrency 10. `roadTripStops` uses concurrency 2 because it fans out.
- Request validation rejects unknown fields and applies strict coordinate,
  radius, category, result, photo-size, and forecast limits.
- Google calls use explicit field masks, a six-second per-attempt timeout, and at
  most two attempts. Upstream error payloads are never returned or logged.
- Air Quality forecast and Solar calls are off by default to avoid surprise
  billable requests.

No Google APIs were enabled and no cloud resources or secrets were created as
part of this implementation.

## Functions

The callable functions are `searchPlaces`, `placeDetails`, `placePhoto`,
`computeRoute`, `roadTripStops`, `airQuality`, `pollen`, `solarCheck`, and
`autocomplete`. Callable handlers return their payload directly; the Firebase
SDK handles the outer callable protocol envelope.

`placePhoto` returns `{url, expiresAt}`. The URL is valid for five minutes and
targets `placePhotoProxy`, which verifies an HMAC token, resolves the Google
photo metadata server-side, allowlists the resulting `googleusercontent.com`
host and image MIME type, and streams bounded image bytes. Neither URL contains
the Google API key. Any UI displaying a Places photo must also display the
`authorAttributions` delivered with the place result.

`roadTripStops` decodes the overview route polyline and searches at no more than
three distance-interpolated quartile points, with at most three categories and
five results per point. It deduplicates to at most 15 stops. If decoded route
geometry is unavailable and both endpoints are coordinates, it falls back to
coordinate interpolation.

## Local verification

```sh
cd functions
npm ci
npm run lint
npm test
```

Tests use mocked `fetch` responses and never make live Google API calls.

The Functions emulator can be started from the repository root after the
Firebase CLI is installed:

```sh
firebase emulators:start --only functions --project wingman-interactive-live
```

Callable requests still require the Firebase callable protocol. Production
App Check enforcement must not be disabled to simplify local testing; use an
App Check debug token in a configured development client instead.

## Secrets and nonsecret parameters

Set secrets interactively so their values never appear in shell history or a
tracked file:

```sh
firebase functions:secrets:set GOMODE_GOOGLE_MAPS_API_KEY --project wingman-interactive-live
firebase functions:secrets:set GOMODE_PHOTO_PROXY_SIGNING_KEY --project wingman-interactive-live
```

`GOMODE_PHOTO_PROXY_SIGNING_KEY` must be a random value of at least 32 bytes and
must be distinct from the Google API key. The nonsecret Boolean parameters are:

- `ENABLE_AIR_QUALITY_FORECAST=false`
- `ENABLE_SOLAR_API=false`

Keep both false until the corresponding APIs, quota ceilings, billing alerts,
and expected request volume have been reviewed. Do not create `.env`, commit a
secret, or add a Maps key to Flutter configuration.

## Deployment

Before deployment, inspect the existing project, enabled APIs, quotas, budgets,
App Check registrations, and unrelated functions. A scoped deployment command
for the already-configured project is:

```sh
firebase deploy --only functions:gomode --project wingman-interactive-live
```

This repository does not run that command automatically. Deployment also does
not authorize enabling a paid Google API; API enablement and quota changes are
separate, reviewed operations.
