# Secrets and Credential Handling

GoMode has two backend secrets. Neither belongs in Flutter source, Dart defines, native manifests, repository files, CI logs, screenshots, issue trackers, or chat messages.

| Name | Purpose | Storage |
| --- | --- | --- |
| `GOMODE_GOOGLE_MAPS_API_KEY` | Backend-only credential for approved Google Maps Platform and Environment APIs | Google Secret Manager through a Firebase Functions secret binding |
| `GOMODE_PHOTO_PROXY_SIGNING_KEY` | HMAC key for short-lived `placePhotoProxy` URLs | Google Secret Manager through a Firebase Functions secret binding |

`ENABLE_SOLAR_API` and `ENABLE_AIR_QUALITY_FORECAST` are feature flags, not secrets. They default to false and must not be used to carry credentials.

## Server Key Rules

- Create a dedicated GoMode key; never reuse a Firebase-managed client key or the unrelated `OPENWEATHER` secret.
- Initially restrict the key to `places.googleapis.com`, `routes.googleapis.com`, `airquality.googleapis.com`, and `pollen.googleapis.com`. Add `solar.googleapis.com` only through the separately reviewed Solar gate, preserving all four existing restrictions.
- Do not add the server key to `.env.example`; examples contain names and non-sensitive defaults only.
- Read the key only through the Functions secret binding. Do not accept a key from a callable request or expose it in a response.
- Send the key to Google in the expected server-side header or query parameter only. Never interpolate it into a client-visible photo URL.
- Do not log request headers, secret values, upstream URLs containing a key, full signed photo URLs, autocomplete session tokens, full addresses, or precise coordinates.
- Do not download or create service-account JSON. Functions use their managed runtime identity and the explicit secret bindings.

The reviewed creation and transfer commands are in `google_cloud_setup.md`. They stream the key directly into Firebase secret storage without writing it to disk or printing it in the normal command output.

## Photo Signing Key

`placePhoto` validates a canonical Google photo resource name and returns a GoMode proxy URL signed with `GOMODE_PHOTO_PROXY_SIGNING_KEY`. The URL expires after five minutes. `placePhotoProxy` verifies the signature and expiry before it contacts Google.

The signature is a temporary bearer capability, not a substitute for App Check on the callable that mints it. Treat a complete signed URL as sensitive operational data:

- Do not persist it as a saved-place identifier.
- Do not include it in analytics or crash breadcrumbs.
- Do not extend its expiry in the client.
- Do not permit an arbitrary upstream URL, host, size, or content type.
- Rotate the signing key if signed URLs could have been forged. Rotation immediately invalidates outstanding URLs, which is acceptable because their lifetime is only five minutes.

## Local Development

Unit and CI tests mock Google and require no real credentials. That is the preferred development path.

If an explicitly approved local emulator test needs secrets, Firebase supports an ignored `functions/.secret.local` file. Never commit it. Use only a dedicated restricted development key with its own low quotas, and remember that emulator requests can still be billable Google API calls.

Example shape, with placeholders only:

```text
GOMODE_GOOGLE_MAPS_API_KEY=<dedicated-restricted-development-key>
GOMODE_PHOTO_PROXY_SIGNING_KEY=<random-value-of-at-least-32-bytes>
```

Before starting an emulator, verify the file is ignored:

```sh
git check-ignore functions/.secret.local
```

Delete the file after the approved test. Do not use a production secret in an emulator, and do not add credentials to a Functions `.env` file.

## Firebase Client Configuration and App Check

Firebase client configuration contains public project identifiers and a Firebase client API key rather than the Google Maps server key. Those values cannot authorize calls to the server-restricted Google APIs. Even so, repository policy keeps app-registration-specific values uncommitted; the public target project ID and region can be documented as defaults.

Flutter reads these public values through Dart defines:

| Define | Required when Firebase is enabled |
| --- | --- |
| `GOMODE_FIREBASE_ENABLED` | Yes; set to `true` only for a configured build |
| `GOMODE_FIREBASE_API_KEY` | Yes; Firebase client key, never the Maps server key |
| `GOMODE_FIREBASE_APP_ID` | Yes |
| `GOMODE_FIREBASE_MESSAGING_SENDER_ID` | Yes |
| `GOMODE_FIREBASE_PROJECT_ID` | Yes; expected production value is `wingman-interactive-live` |
| `GOMODE_FIREBASE_AUTH_DOMAIN` | Optional |
| `GOMODE_FIREBASE_STORAGE_BUCKET` | Optional |
| `GOMODE_FIREBASE_MEASUREMENT_ID` | Optional |
| `GOMODE_FIREBASE_FUNCTIONS_REGION` | Optional; defaults to `us-central1` |
| `GOMODE_RECAPTCHA_SITE_KEY` | Required for App Check on web; a restricted public site key |
| `GOMODE_FUNCTIONS_EMULATOR_HOST` / `GOMODE_FUNCTIONS_EMULATOR_PORT` | Local emulator only |

Concrete app-registration values remain outside Git and are supplied by the approved local or CI build configuration. Do not put any `GOMODE_GOOGLE_MAPS_API_KEY` value into a Dart define.

Generated files that may also contain Firebase client configuration remain untracked:

- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- `macos/Runner/GoogleService-Info.plist`
- generated Dart Firebase option files containing API keys

Provide client configuration through the approved local/CI build path after GoMode-specific Firebase apps are registered. Existing project app registrations are unrelated and must not be reused.

App Check debug tokens are also credentials. Keep them in developer-local or CI secret storage, revoke them when no longer needed, and never put them in a Dart define committed to a script. Release builds use Play Integrity, App Attest with DeviceCheck fallback, or restricted reCAPTCHA as appropriate.

## Rotation

Rotate `GOMODE_GOOGLE_MAPS_API_KEY` without an outage:

1. Review quotas and create a second key restricted to the same currently approved API set.
2. Write it as a new `GOMODE_GOOGLE_MAPS_API_KEY` secret version without `--force`.
3. Review and deploy only `functions:gomode` so new revisions bind the new version.
4. Perform low-volume smoke tests and verify Google API errors and billing telemetry.
5. Disable, then delete, the old API key after all serving revisions have moved off it.
6. Destroy only the unused old secret version after confirming the active version metadata.

Rotate `GOMODE_PHOTO_PROXY_SIGNING_KEY` the same way, accepting that URLs created by an older revision become invalid. Do not use `firebase functions:secrets:prune --force` in the shared project; inspect names and versions individually.

Safe metadata-only inspection commands are:

```sh
firebase functions:secrets:get GOMODE_GOOGLE_MAPS_API_KEY \
  --project wingman-interactive-live

firebase functions:secrets:get GOMODE_PHOTO_PROXY_SIGNING_KEY \
  --project wingman-interactive-live
```

These return metadata, not secret values. Avoid commands that access or print the secret payload.

## Suspected Disclosure

If either secret may have leaked:

1. Stop sharing the output and preserve only non-secret incident metadata.
2. Disable the affected API key immediately or add a new signing secret version.
3. Disable live client configuration or the affected feature if abuse is ongoing.
4. Inspect Google API usage by service, Function invocations, App Check failures, and billing anomalies.
5. Rotate and narrowly redeploy `functions:gomode`.
6. Revoke old key/secret versions and any leaked App Check debug token.
7. Search the current tree and Git history before declaring containment.

Never attempt to fix a leak by merely deleting the local file or making a follow-up commit. A committed or logged credential must be treated as compromised and revoked.
