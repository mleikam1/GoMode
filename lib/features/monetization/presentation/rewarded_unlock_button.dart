import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../data/monetization_service.dart';
import '../domain/monetization_feature_flags.dart';
import '../domain/monetization_models.dart';

class RewardedUnlockButton extends ConsumerStatefulWidget {
  const RewardedUnlockButton({
    required this.unlock,
    this.onUnlocked,
    super.key,
  });

  final RewardedUnlock unlock;
  final VoidCallback? onUnlocked;

  @override
  ConsumerState<RewardedUnlockButton> createState() =>
      _RewardedUnlockButtonState();
}

class _RewardedUnlockButtonState extends ConsumerState<RewardedUnlockButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final flags = ref.watch(monetizationFeatureFlagsProvider);
    final service = ref.watch(monetizationServiceProvider);
    if (!flags.adsEnabled || (service.isMock && !kDebugMode)) {
      return const SizedBox.shrink();
    }
    final premium = ref
        .watch(premiumStatusProvider)
        .maybeWhen<bool?>(
          data: (status) => status.isPremium,
          orElse: () => null,
        );
    if (premium == null || premium) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Container(
        key: ValueKey('rewarded-unlock-${widget.unlock.id}'),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.lavender.withValues(alpha: 0.07),
          borderRadius: AppRadius.largeCard,
          border: Border.all(color: AppColors.lavender.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            const Icon(Icons.ondemand_video_rounded, color: AppColors.lavender),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.unlock.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    widget.unlock.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            OutlinedButton(
              key: ValueKey('rewarded-unlock-button-${widget.unlock.id}'),
              onPressed: _loading ? null : _requestUnlock,
              child: Text(_loading ? 'Loading…' : 'Watch'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _requestUnlock() async {
    setState(() => _loading = true);
    final result = await ref
        .read(monetizationServiceProvider)
        .requestRewardedUnlock(widget.unlock);
    if (!mounted) {
      return;
    }
    setState(() => _loading = false);
    final message = switch (result) {
      RewardedUnlockResult.granted => 'Mock reward granted. No ad was shown.',
      RewardedUnlockResult.cancelled => 'Reward cancelled.',
      RewardedUnlockResult.unavailable =>
        'Rewarded unlocks are not configured yet.',
    };
    if (result == RewardedUnlockResult.granted) {
      widget.onUnlocked?.call();
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
