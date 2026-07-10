# GoMode Tools

Project-specific scripts and developer utilities belong here.
# Design screenshots

Capture the five approved GoMode surfaces from a running Android emulator:

```sh
tools/capture_screenshots.sh emulator-5554
```

The integration driver writes `home.png`, `modes.png`, `date-night.png`,
`road-trip.png`, and `saved.png` to `docs/screenshots/current/`.
