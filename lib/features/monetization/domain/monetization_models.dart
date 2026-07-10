import 'package:flutter/foundation.dart';

@immutable
class SponsoredLinkMetadata {
  const SponsoredLinkMetadata({
    required this.partnerName,
    this.disclosureLabel = 'Sponsored',
    this.destination,
    this.isAffiliate = false,
    this.enabled = false,
  });

  final String partnerName;
  final String disclosureLabel;
  final Uri? destination;
  final bool isAffiliate;

  /// A destination is never actionable unless this is explicitly enabled.
  final bool enabled;

  bool get canOpen => enabled && destination != null;
}

@immutable
class SponsoredPlacement {
  const SponsoredPlacement({
    required this.id,
    required this.title,
    required this.description,
    required this.ctaLabel,
    required this.link,
    this.isMock = false,
  });

  final String id;
  final String title;
  final String description;
  final String ctaLabel;
  final SponsoredLinkMetadata link;
  final bool isMock;
}

enum RewardedUnlockType {
  extraDateNightPlan,
  extraHiddenGems,
  extraRoadTripStops,
}

@immutable
class RewardedUnlock {
  const RewardedUnlock({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
  });

  const RewardedUnlock.extraDateNightPlan()
    : id = 'extra-date-night-plan',
      type = RewardedUnlockType.extraDateNightPlan,
      title = 'Reroll one extra plan',
      description = 'Optional reward preview — your current plan stays usable.';

  const RewardedUnlock.extraHiddenGems()
    : id = 'extra-hidden-gems',
      type = RewardedUnlockType.extraHiddenGems,
      title = 'Reveal extra hidden gems',
      description = 'Optional reward preview — current results stay unlocked.';

  const RewardedUnlock.extraRoadTripStops()
    : id = 'extra-road-trip-stops',
      type = RewardedUnlockType.extraRoadTripStops,
      title = 'Unlock extra road trip stops',
      description =
          'Optional reward preview — core route stops stay available.';

  final String id;
  final RewardedUnlockType type;
  final String title;
  final String description;
}

enum RewardedUnlockResult { granted, unavailable, cancelled }

enum LeadCaptureType {
  solarChecker('Solar Checker'),
  neighborhoodCheck('Neighborhood Check'),
  whereShouldILive('Where Should I Live?');

  const LeadCaptureType(this.label);

  final String label;
}

@immutable
class LeadCapture {
  const LeadCapture({
    required this.type,
    required this.name,
    required this.email,
    required this.postalCode,
    required this.privacyConsent,
  });

  final LeadCaptureType type;
  final String name;
  final String email;
  final String postalCode;
  final bool privacyConsent;
}

enum LeadCaptureSubmissionResult { accepted, unavailable, rejected }

@immutable
class PremiumStatus {
  const PremiumStatus({
    required this.isPremium,
    required this.adsRemoved,
    this.expiresAt,
  });

  const PremiumStatus.free()
    : isPremium = false,
      adsRemoved = false,
      expiresAt = null;

  final bool isPremium;
  final bool adsRemoved;
  final DateTime? expiresAt;
}

enum PremiumUpgradeResult { started, unavailable, cancelled }
