import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../data/monetization_service.dart';
import '../domain/monetization_feature_flags.dart';
import '../domain/monetization_models.dart';

class SponsoredCard extends ConsumerWidget {
  const SponsoredCard({
    required this.placementId,
    this.onOpen,
    this.topSpacing = 0,
    super.key,
  });

  final String placementId;
  final ValueChanged<SponsoredPlacement>? onOpen;
  final double topSpacing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flags = ref.watch(monetizationFeatureFlagsProvider);
    final service = ref.watch(monetizationServiceProvider);
    if (!flags.adsEnabled ||
        !flags.sponsoredCardsEnabled ||
        (service.isMock && !kDebugMode)) {
      return const SizedBox.shrink();
    }

    final premium = ref
        .watch(premiumStatusProvider)
        .maybeWhen<bool?>(
          data: (status) => status.adsRemoved,
          orElse: () => null,
        );
    if (premium == null || premium) {
      return const SizedBox.shrink();
    }

    return ref
        .watch(sponsoredPlacementProvider(placementId))
        .maybeWhen(
          data: (placement) {
            if (placement == null) {
              return const SizedBox.shrink();
            }
            return _SponsoredPlacementCard(
              placement: placement,
              onOpen: onOpen,
              topSpacing: topSpacing,
            );
          },
          orElse: () => const SizedBox.shrink(),
        );
  }
}

class _SponsoredPlacementCard extends StatelessWidget {
  const _SponsoredPlacementCard({
    required this.placement,
    required this.topSpacing,
    this.onOpen,
  });

  final SponsoredPlacement placement;
  final ValueChanged<SponsoredPlacement>? onOpen;
  final double topSpacing;

  @override
  Widget build(BuildContext context) {
    final actionable = placement.link.canOpen && onOpen != null;
    return Padding(
      padding: EdgeInsets.only(top: topSpacing, bottom: AppSpacing.md),
      child: Semantics(
        label:
            '${placement.link.disclosureLabel} from ${placement.link.partnerName}',
        button: actionable,
        child: Container(
          key: ValueKey('sponsored-card-${placement.id}'),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceRaised,
            borderRadius: AppRadius.largeCard,
            border: Border.all(color: AppColors.borderStrong),
            boxShadow: AppShadows.soft,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.lavender.withValues(alpha: 0.10),
                  borderRadius: AppRadius.mdBorder,
                ),
                child: const Icon(
                  Icons.storefront_outlined,
                  color: AppColors.lavender,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xxs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          placement.link.disclosureLabel,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                        ),
                        if (placement.isMock)
                          Text(
                            'MOCK PREVIEW',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: AppColors.lavender,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      placement.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      placement.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    TextButton(
                      key: ValueKey('sponsored-cta-${placement.id}'),
                      onPressed: actionable ? () => onOpen!(placement) : null,
                      child: Text(placement.ctaLabel),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
