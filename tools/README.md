# GoMode Tools

Run these scripts from any working directory; each resolves the repository root
before invoking Flutter or Firebase tooling.

```sh
tools/check.sh
tools/run_android.sh -d emulator-5554
tools/build_android_debug.sh
tools/build_android_release.sh
```

`build_android_release.sh` produces an Android App Bundle. The current Android
project still uses Flutter's temporary debug-signing fallback for release builds;
complete the signing items in `docs/release_checklist.md` before uploading an
artifact to a store.

Because this repository contains the `gomode` Firebase Functions codebase,
`firebase_deploy_preview.sh` performs a local install, type check, and test run,
then prints the only approved scoped deployment command. It does not contact or
change Firebase:

```sh
FIREBASE_PROJECT_ID=your-project-id tools/firebase_deploy_preview.sh
```

# Design screenshots

Capture the five approved GoMode surfaces from a running Android emulator:

```sh
tools/capture_screenshots.sh emulator-5554
```

The integration driver writes `home.png`, `modes.png`, `date-night.png`,
`road-trip.png`, and `saved.png` to `docs/screenshots/current/`.
