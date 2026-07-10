import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/monetization_models.dart';

final monetizationServiceProvider = Provider<MonetizationService>((ref) {
  return const MockMonetizationService();
});

final premiumStatusProvider = FutureProvider<PremiumStatus>((ref) {
  return ref.watch(monetizationServiceProvider).loadPremiumStatus();
});

final sponsoredPlacementProvider = FutureProvider.autoDispose
    .family<SponsoredPlacement?, String>((ref, placementId) {
      return ref
          .watch(monetizationServiceProvider)
          .loadSponsoredPlacement(placementId);
    });

abstract interface class MonetizationService {
  bool get isMock;

  bool get leadCaptureConfigured;

  Future<SponsoredPlacement?> loadSponsoredPlacement(String placementId);

  Future<RewardedUnlockResult> requestRewardedUnlock(RewardedUnlock unlock);

  Future<PremiumStatus> loadPremiumStatus();

  Future<PremiumUpgradeResult> startPremiumUpgrade();

  Future<LeadCaptureSubmissionResult> submitLeadCapture(LeadCapture capture);
}

class MockMonetizationService implements MonetizationService {
  const MockMonetizationService({
    this.premiumStatus = const PremiumStatus.free(),
  });

  @override
  bool get leadCaptureConfigured => false;

  final PremiumStatus premiumStatus;

  @override
  bool get isMock => true;

  @override
  Future<SponsoredPlacement?> loadSponsoredPlacement(String placementId) async {
    return SponsoredPlacement(
      id: placementId,
      title: 'A thoughtfully matched local partner',
      description:
          'Mock native placement. No ad request, tracking, or destination is active.',
      ctaLabel: 'Preview only',
      link: const SponsoredLinkMetadata(partnerName: 'GoMode demo partner'),
      isMock: true,
    );
  }

  @override
  Future<RewardedUnlockResult> requestRewardedUnlock(
    RewardedUnlock unlock,
  ) async {
    return RewardedUnlockResult.granted;
  }

  @override
  Future<PremiumStatus> loadPremiumStatus() async => premiumStatus;

  @override
  Future<PremiumUpgradeResult> startPremiumUpgrade() async {
    return PremiumUpgradeResult.unavailable;
  }

  @override
  Future<LeadCaptureSubmissionResult> submitLeadCapture(
    LeadCapture capture,
  ) async {
    // The mock deliberately discards the payload. A production implementation
    // must not report configured until storage and privacy language are ready.
    return LeadCaptureSubmissionResult.unavailable;
  }
}
