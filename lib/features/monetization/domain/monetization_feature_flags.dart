import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _adsEnabled = bool.fromEnvironment('GOMODE_ADS_ENABLED');
const _premiumEnabled = bool.fromEnvironment('GOMODE_PREMIUM_ENABLED');
const _leadFormsEnabled = bool.fromEnvironment('GOMODE_LEAD_FORMS_ENABLED');
const _sponsoredCardsEnabled = bool.fromEnvironment(
  'GOMODE_SPONSORED_CARDS_ENABLED',
);
const _debugMockUiEnabled = bool.fromEnvironment(
  'GOMODE_MONETIZATION_DEBUG_UI',
  defaultValue: false,
);

@immutable
class MonetizationFeatureFlags {
  const MonetizationFeatureFlags({
    required this.adsEnabled,
    required this.premiumEnabled,
    required this.leadFormsEnabled,
    required this.sponsoredCardsEnabled,
  });

  const MonetizationFeatureFlags.disabled()
    : adsEnabled = false,
      premiumEnabled = false,
      leadFormsEnabled = false,
      sponsoredCardsEnabled = false;

  const MonetizationFeatureFlags.debugPreview()
    : adsEnabled = true,
      premiumEnabled = true,
      leadFormsEnabled = true,
      sponsoredCardsEnabled = true;

  final bool adsEnabled;
  final bool premiumEnabled;
  final bool leadFormsEnabled;
  final bool sponsoredCardsEnabled;
}

final monetizationFeatureFlagsProvider = Provider<MonetizationFeatureFlags>((
  ref,
) {
  if (kDebugMode && _debugMockUiEnabled) {
    return const MonetizationFeatureFlags.debugPreview();
  }
  return const MonetizationFeatureFlags(
    adsEnabled: _adsEnabled,
    premiumEnabled: _premiumEnabled,
    leadFormsEnabled: _leadFormsEnabled,
    sponsoredCardsEnabled: _sponsoredCardsEnabled,
  );
});
