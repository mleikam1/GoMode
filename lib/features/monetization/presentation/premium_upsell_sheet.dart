import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../data/monetization_service.dart';
import '../domain/monetization_feature_flags.dart';
import '../domain/monetization_models.dart';

class PremiumUpsellSheet extends ConsumerStatefulWidget {
  const PremiumUpsellSheet({super.key});

  @override
  ConsumerState<PremiumUpsellSheet> createState() => _PremiumUpsellSheetState();
}

class _PremiumUpsellSheetState extends ConsumerState<PremiumUpsellSheet> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final flags = ref.watch(monetizationFeatureFlagsProvider);
    final service = ref.watch(monetizationServiceProvider);
    if (!flags.premiumEnabled || (service.isMock && !kDebugMode)) {
      return const SizedBox.shrink();
    }
    final status = ref
        .watch(premiumStatusProvider)
        .maybeWhen(
          data: (value) => value,
          orElse: () => const PremiumStatus.free(),
        );

    return SafeArea(
      child: Padding(
        key: const ValueKey('premium-upsell-sheet'),
        padding: EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.xl,
          AppSpacing.page,
          AppSpacing.xl + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              child: Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: AppColors.navy900,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: AppColors.amber,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              status.isPremium ? 'GoMode Premium is active' : 'GoMode Premium',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              status.isPremium
                  ? 'Sponsored placements and rewarded ads are removed.'
                  : 'A future optional upgrade for an ad-free experience. Core GoMode features remain free.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceTint,
                borderRadius: AppRadius.largeCard,
              ),
              child: const Column(
                children: [
                  _PremiumBenefit('No sponsored cards'),
                  _PremiumBenefit('No rewarded ad prompts'),
                  _PremiumBenefit('No core feature restrictions'),
                ],
              ),
            ),
            if (!status.isPremium) ...[
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                key: const ValueKey('premium-upgrade-button'),
                onPressed: _loading ? null : _startUpgrade,
                icon: const Icon(Icons.lock_open_rounded),
                label: Text(_loading ? 'Loading…' : 'Preview upgrade'),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Debug preview only. No purchase flow or product ID is configured.',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _startUpgrade() async {
    setState(() => _loading = true);
    final result = await ref
        .read(monetizationServiceProvider)
        .startPremiumUpgrade();
    if (!mounted) {
      return;
    }
    setState(() => _loading = false);
    if (result == PremiumUpgradeResult.started) {
      ref.invalidate(premiumStatusProvider);
    }
    final message = switch (result) {
      PremiumUpgradeResult.started => 'Premium upgrade started.',
      PremiumUpgradeResult.cancelled => 'Premium upgrade cancelled.',
      PremiumUpgradeResult.unavailable =>
        'Premium checkout is not configured in the MVP.',
    };
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _PremiumBenefit extends StatelessWidget {
  const _PremiumBenefit(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: AppColors.success,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}
