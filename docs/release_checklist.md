# GoMode Release Checklist

Use this checklist for every internal, preview, and store release. A checked box
means the item was verified for the exact commit and build number being shipped.

## Release scope

- [ ] Confirm the release commit, version, and build number in `pubspec.yaml`.
- [ ] Review the diff and confirm it contains no credentials, `.env` files,
      service-account files, signing files, or unrelated generated output.
- [ ] Record material product or technical decisions in `docs/decisions.md`.
- [ ] Confirm the app identity is `GoMode` / `com.mleikam.gomode` on Android and
      iOS.

## Configuration and secrets

- [ ] Start from `.env.example`; keep concrete values in an approved untracked
      local or CI secret store.
- [ ] Keep `GOMODE_GOOGLE_MAPS_API_KEY` and
      `GOMODE_PHOTO_PROXY_SIGNING_KEY` in Google Secret Manager only.
- [ ] Restrict native Maps SDK keys by application ID or bundle ID and signing
      identity. Never pass the server Maps key as a Dart define.
- [ ] Confirm Firebase App Check registrations and enforcement for the release
      applications.
- [ ] Review `FEATURE_ADS_ENABLED`, `FEATURE_PREMIUM_ENABLED`, and their
      `GOMODE_*` runtime equivalents. They default to `false`.
- [ ] Review enabled Google APIs, quotas, budget alerts, and expected traffic
      before enabling any paid integration.

## Verification

- [ ] Run `tools/check.sh`.
- [ ] Run `tools/build_android_debug.sh` and smoke-test the APK on a supported
      physical device or emulator.
- [ ] Run `flutter build ios --simulator --no-codesign` and smoke-test on an iOS
      simulator when macOS/Xcode is available.
- [ ] Exercise Home, Modes, Date Night, Road Trip, Map, Saved, Profile, location
      denial, offline/fallback, and error states.
- [ ] Verify the deep-navy launch screen, GoMode wordmark, launcher icon, app
      label, and package/bundle identifiers.
- [ ] Re-run accessibility checks with large text, screen reader semantics,
      reduced motion, narrow phone width, and tablet width.

## Signed artifacts

- [ ] Replace the temporary Android debug-signing fallback with the protected
      release keystore configuration; never commit the keystore or passwords.
- [ ] Build the Android App Bundle with `tools/build_android_release.sh` and
      verify its application ID, version code, signing certificate, and size.
- [ ] Archive iOS with the approved distribution team/profile and verify the
      bundle ID, version, build number, entitlements, privacy manifest, and size.
- [ ] Install the exact signed candidate distributed to testers; do not rely
      only on a debug build.

## Backend deployment

- [ ] Run `FIREBASE_PROJECT_ID=<project> tools/firebase_deploy_preview.sh`.
- [ ] Inspect existing project resources and confirm the target before any
      deployment.
- [ ] Deploy only `functions:gomode`; never run an unscoped Functions deploy or
      use `--force` in the shared project.
- [ ] Smoke-test App Check-protected callables and verify logs contain no
      credential values or sensitive payloads.

## Store and rollout

- [ ] Reconcile `docs/app_store_listing_draft.md` with the shipped feature set,
      screenshots, support URL, privacy policy, and age/content declarations.
- [ ] Complete current Google Play Data safety and Apple App Privacy forms from
      the final SDK and data-flow inventory.
- [ ] Confirm venue, route, weather/environment, pricing, availability, and
      safety disclaimers are visible where needed.
- [ ] Publish to an internal track first, monitor crashes and backend errors,
      then use a staged production rollout with a named rollback owner.
- [ ] Tag the released commit and record artifact hashes, store submission IDs,
      release notes, rollout status, and any follow-up work.
