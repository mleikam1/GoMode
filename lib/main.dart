import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/gomode_app.dart';
import 'services/api_client.dart';
import 'services/runtime_config.dart';

const _firebaseEnabled = bool.fromEnvironment('GOMODE_FIREBASE_ENABLED');
const _firebaseApiKey = String.fromEnvironment('GOMODE_FIREBASE_API_KEY');
const _firebaseAppId = String.fromEnvironment('GOMODE_FIREBASE_APP_ID');
const _firebaseMessagingSenderId = String.fromEnvironment(
  'GOMODE_FIREBASE_MESSAGING_SENDER_ID',
);
const _firebaseAuthDomain = String.fromEnvironment(
  'GOMODE_FIREBASE_AUTH_DOMAIN',
);
const _firebaseStorageBucket = String.fromEnvironment(
  'GOMODE_FIREBASE_STORAGE_BUCKET',
);
const _firebaseMeasurementId = String.fromEnvironment(
  'GOMODE_FIREBASE_MEASUREMENT_ID',
);
const _recaptchaSiteKey = String.fromEnvironment('GOMODE_RECAPTCHA_SITE_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeFirebaseBackend();

  runApp(const ProviderScope(child: GoModeApp()));
}

Future<void> _initializeFirebaseBackend() async {
  if (!_firebaseEnabled) {
    return;
  }

  try {
    final hasPublicOptions =
        _firebaseApiKey.isNotEmpty &&
        _firebaseAppId.isNotEmpty &&
        _firebaseMessagingSenderId.isNotEmpty &&
        firebaseProjectId.isNotEmpty;
    await Firebase.initializeApp(
      options: hasPublicOptions
          ? FirebaseOptions(
              apiKey: _firebaseApiKey,
              appId: _firebaseAppId,
              messagingSenderId: _firebaseMessagingSenderId,
              projectId: firebaseProjectId,
              authDomain: _optional(_firebaseAuthDomain),
              storageBucket: _optional(_firebaseStorageBucket),
              measurementId: _optional(_firebaseMeasurementId),
            )
          : null,
    );
    if (kDebugMode && functionsEmulatorHost.isNotEmpty) {
      firebaseBackendReady = true;
      return;
    }
    if (kIsWeb) {
      if (_recaptchaSiteKey.isEmpty) {
        return;
      }
      await FirebaseAppCheck.instance.activate(
        providerWeb: ReCaptchaV3Provider(_recaptchaSiteKey),
      );
      firebaseBackendReady = true;
      return;
    }
    await FirebaseAppCheck.instance.activate(
      providerAndroid: kDebugMode
          ? const AndroidDebugProvider()
          : const AndroidPlayIntegrityProvider(),
      providerApple: kDebugMode
          ? const AppleDebugProvider()
          : const AppleAppAttestWithDeviceCheckFallbackProvider(),
    );
    firebaseBackendReady = true;
  } catch (_) {
    // Firebase is optional at startup. Repositories use local demo data when
    // platform configuration or App Check is unavailable.
  }
}

String? _optional(String value) => value.isEmpty ? null : value;
