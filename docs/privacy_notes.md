# GoMode Privacy Notes

These notes describe the current MVP behavior and are not a substitute for a
release-ready privacy policy reviewed for the launch regions and distribution
channels.

## Location and permissions

- GoMode requests only foreground/while-in-use location access.
- Location is used to center nearby place results, map suggestions, and route
  planning. The MVP does not request background location.
- If permission is denied, denied permanently, location services are disabled,
  or a position cannot be obtained, the app explains the state and falls back
  to Austin. A user can instead choose Austin, Chicago, or Denver as a default
  city without sharing device location.
- iOS declares `NSLocationWhenInUseUsageDescription`. Android declares coarse
  and fine location permissions. Permission denial must never block the rest of
  the app.

## API keys and backend data

- Google Places, Routes, Air Quality, Pollen, and Solar API keys remain in the
  server-side secret manager and are never returned to Flutter.
- When the native Google Maps display widget is enabled, its Android/iOS SDK key
  is a separate client key restricted to the app package/bundle and relevant
  Maps SDK. It is supplied through local or CI platform build settings and is
  never committed.
- The app requests only the Google API fields needed for the active feature.
  Place details request contact fields only because the place sheet can expose
  Website and Call actions when those fields exist.

## Local data

- Saved places, plans, routes, collections, profile settings, and bounded API
  response caches are stored locally on the device.
- Cloud sync is not part of the current MVP. If it is added, the product must
  disclose what is uploaded, provide an appropriate user choice, and update the
  in-app privacy screen before release.
- “Clear cache” removes local cached API responses. “Reset demo data” restores
  sample saved content and road-trip choices without changing profile settings.

## Personal data

- GoMode does not sell personal data in the current MVP.
- No analytics or advertising data sale is implemented by this repository.
- Data practices, third-party SDK use, retention, deletion behavior, and this
  document must be reviewed again before a production release.
