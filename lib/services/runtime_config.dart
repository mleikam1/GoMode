const firebaseProjectId = String.fromEnvironment('GOMODE_FIREBASE_PROJECT_ID');

/// The native Android/iOS Maps SDK key must also be configured before this is
/// enabled. This flag never contains a key and is safe to expose to Flutter.
const googleMapsWidgetEnabled = bool.fromEnvironment(
  'GOMODE_MAPS_WIDGET_ENABLED',
);
