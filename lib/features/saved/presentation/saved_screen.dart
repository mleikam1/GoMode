import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/discovery_mode.dart';
import '../../../data/services/mode_catalog.dart';
import '../../../shared/widgets/shared_widgets.dart';
import '../../modes/presentation/mode_visuals.dart';

class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(modeCatalogProvider);
    final savedModes = [
      catalog.modeById('date-night'),
      catalog.modeById('road-trip-stops'),
      catalog.modeById('local-quest'),
    ];

    return ColoredBox(
      color: AppColors.surface,
      child: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: GradientHeader(
              compact: true,
              title: 'Saved',
              subtitle: 'Plans, places, and quests ready to revisit.',
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.page),
            sliver: SliverList.list(
              children: [
                for (final mode in savedModes) ...[
                  _SavedPlanCard(mode: mode),
                  const SizedBox(height: AppSpacing.md),
                ],
                const _SavedStatsCard(),
                SizedBox(height: AppSpacing.bottomNavHeight + AppSpacing.xl),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedPlanCard extends StatelessWidget {
  const _SavedPlanCard({required this.mode});

  final DiscoveryMode mode;

  @override
  Widget build(BuildContext context) {
    final result = mode.demoResults.first;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.largeCard,
        onTap: () => context.go('/modes/${mode.id}/results'),
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceRaised,
            borderRadius: AppRadius.largeCard,
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.card,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 116,
                height: 108,
                child: demoIllustrationFor(
                  result.imageSemanticName,
                  borderRadius: AppRadius.mdBorder,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StatusPill(
                      label: mode.title,
                      color: mode.accentColor,
                      compact: true,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      result.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      result.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        const Icon(
                          Icons.bookmark_rounded,
                          color: AppColors.textMuted,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Saved locally',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SavedStatsCard extends StatelessWidget {
  const _SavedStatsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.08),
        borderRadius: AppRadius.largeCard,
        border: Border.all(
          color: AppColors.primaryBlue.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          const SoftIconBadge(
            icon: Icons.insights_rounded,
            color: AppColors.primaryBlue,
            showShadow: false,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '3 demo saves',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Saving is enabled for most modes in the catalog.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
