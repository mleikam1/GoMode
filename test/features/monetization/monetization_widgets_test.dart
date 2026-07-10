import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gomode/features/monetization/data/monetization_service.dart';
import 'package:gomode/features/monetization/domain/monetization_feature_flags.dart';
import 'package:gomode/features/monetization/domain/monetization_models.dart';
import 'package:gomode/features/monetization/presentation/monetization_widgets.dart';
import 'package:gomode/features/modes/data/generic_mode_results_service.dart';

void main() {
  const enabledFlags = MonetizationFeatureFlags(
    adsEnabled: true,
    premiumEnabled: true,
    leadFormsEnabled: true,
    sponsoredCardsEnabled: true,
  );

  testWidgets('feature flags hide all monetization widgets', (tester) async {
    await _pumpWidgets(
      tester,
      flags: const MonetizationFeatureFlags.disabled(),
    );

    expect(
      find.byKey(const ValueKey('sponsored-card-test-placement')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('rewarded-unlock-extra-hidden-gems')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('lead-capture-form-solarChecker')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('premium-upsell-sheet')), findsNothing);
  });

  testWidgets('feature flags show mock monetization widgets in debug', (
    tester,
  ) async {
    await _pumpWidgets(tester, flags: enabledFlags);

    expect(
      find.byKey(const ValueKey('sponsored-card-test-placement')),
      findsOneWidget,
    );
    expect(find.text('MOCK PREVIEW'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('rewarded-unlock-extra-hidden-gems')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('lead-capture-form-solarChecker')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('premium-upsell-sheet')), findsOneWidget);
  });

  testWidgets('premium no-ads status suppresses ad-backed surfaces', (
    tester,
  ) async {
    await _pumpWidgets(
      tester,
      flags: enabledFlags,
      service: const MockMonetizationService(
        premiumStatus: PremiumStatus(isPremium: true, adsRemoved: true),
      ),
    );

    expect(
      find.byKey(const ValueKey('sponsored-card-test-placement')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('rewarded-unlock-extra-hidden-gems')),
      findsNothing,
    );
    expect(find.text('GoMode Premium is active'), findsOneWidget);
  });

  testWidgets(
    'lead form validates locally and stores nothing when unconfigured',
    (tester) async {
      final service = _RecordingMonetizationService(configured: false);
      await _pumpLeadForm(tester, service);

      await tester.tap(find.byKey(const ValueKey('lead-submit-button')));
      await tester.pump();

      expect(find.text('Enter your name.'), findsOneWidget);
      expect(find.text('Enter your email.'), findsOneWidget);
      expect(find.text('Enter a valid postal code.'), findsOneWidget);
      expect(find.text('Consent is required.'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('lead-name-field')),
        'Taylor',
      );
      await tester.enterText(
        find.byKey(const ValueKey('lead-email-field')),
        'taylor@example.com',
      );
      await tester.enterText(
        find.byKey(const ValueKey('lead-postal-code-field')),
        '78701',
      );
      await tester.tap(find.byKey(const ValueKey('lead-privacy-consent')));
      await tester.tap(find.byKey(const ValueKey('lead-submit-button')));
      await tester.pump();

      expect(service.submitCalls, 0);
      expect(
        find.text(
          'Lead capture is not configured. Nothing was sent or stored.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('lead form submits only through a configured service', (
    tester,
  ) async {
    final service = _RecordingMonetizationService(configured: true);
    await _pumpLeadForm(tester, service);

    await tester.enterText(
      find.byKey(const ValueKey('lead-name-field')),
      'Taylor',
    );
    await tester.enterText(
      find.byKey(const ValueKey('lead-email-field')),
      'taylor@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('lead-postal-code-field')),
      '78701',
    );
    await tester.tap(find.byKey(const ValueKey('lead-privacy-consent')));
    await tester.tap(find.byKey(const ValueKey('lead-submit-button')));
    await tester.pumpAndSettle();

    expect(service.submitCalls, 1);
    expect(service.lastCapture?.type, LeadCaptureType.solarChecker);
    expect(service.lastCapture?.email, 'taylor@example.com');
    expect(find.text('Request received.'), findsOneWidget);
  });

  test('result-card sponsorship metadata is disabled by default', () {
    const result = ModeResultItem(
      id: 'result',
      title: 'Result',
      subtitle: 'Subtitle',
      detail: 'Detail',
      distanceLabel: 'Nearby',
      imageSemanticName: 'place',
      tags: [],
    );
    const link = SponsoredLinkMetadata(partnerName: 'Example partner');

    expect(result.sponsoredLink, isNull);
    expect(link.enabled, isFalse);
    expect(link.canOpen, isFalse);
  });

  test('Flutter source contains no AdMob unit IDs', () {
    final dartFiles = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    for (final file in dartFiles) {
      expect(
        file.readAsStringSync(),
        isNot(contains('ca-app-pub-')),
        reason: 'Ad unit ID found in ${file.path}',
      );
    }
  });
}

Future<void> _pumpWidgets(
  WidgetTester tester, {
  required MonetizationFeatureFlags flags,
  MonetizationService service = const MockMonetizationService(),
}) async {
  tester.view.physicalSize = const Size(900, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        monetizationFeatureFlagsProvider.overrideWithValue(flags),
        monetizationServiceProvider.overrideWithValue(service),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                SponsoredCard(placementId: 'test-placement'),
                RewardedUnlockButton(unlock: RewardedUnlock.extraHiddenGems()),
                LeadCaptureForm(type: LeadCaptureType.solarChecker),
                PremiumUpsellSheet(),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpLeadForm(
  WidgetTester tester,
  MonetizationService service,
) async {
  tester.view.physicalSize = const Size(600, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        monetizationFeatureFlagsProvider.overrideWithValue(
          const MonetizationFeatureFlags(
            adsEnabled: false,
            premiumEnabled: false,
            leadFormsEnabled: true,
            sponsoredCardsEnabled: false,
          ),
        ),
        monetizationServiceProvider.overrideWithValue(service),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: LeadCaptureForm(type: LeadCaptureType.solarChecker),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _RecordingMonetizationService implements MonetizationService {
  _RecordingMonetizationService({required this.configured});

  final bool configured;
  int submitCalls = 0;
  LeadCapture? lastCapture;

  @override
  bool get isMock => false;

  @override
  bool get leadCaptureConfigured => configured;

  @override
  Future<SponsoredPlacement?> loadSponsoredPlacement(String placementId) async {
    return null;
  }

  @override
  Future<PremiumStatus> loadPremiumStatus() async {
    return const PremiumStatus.free();
  }

  @override
  Future<RewardedUnlockResult> requestRewardedUnlock(
    RewardedUnlock unlock,
  ) async {
    return RewardedUnlockResult.unavailable;
  }

  @override
  Future<PremiumUpgradeResult> startPremiumUpgrade() async {
    return PremiumUpgradeResult.unavailable;
  }

  @override
  Future<LeadCaptureSubmissionResult> submitLeadCapture(
    LeadCapture capture,
  ) async {
    submitCalls += 1;
    lastCapture = capture;
    return LeadCaptureSubmissionResult.accepted;
  }
}
