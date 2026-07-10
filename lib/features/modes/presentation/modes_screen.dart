import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/services/mode_catalog.dart';
import '../../../shared/widgets/shared_widgets.dart';
import 'mode_visuals.dart';

class ModesScreen extends ConsumerWidget {
  const ModesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(modeCatalogProvider);

    return ColoredBox(
      color: AppColors.surface,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: GradientHeader(
              title: 'Modes',
              subtitle: 'Pick the job, vibe, or constraint for your next move.',
              bottom: const AppSearchBar(
                hintText: 'Search all 20 modes',
                readOnly: true,
                onDark: true,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
          for (final category in catalog.categories) ...[
            SliverToBoxAdapter(
              child: CategoryCarousel(
                title: category.label,
                actionLabel: '${catalog.byCategory(category).length} modes',
                height: 294,
                children: [
                  for (final mode in catalog.byCategory(category))
                    ModeCard(
                      title: mode.title,
                      subtitle: mode.shortSubtitle,
                      icon: ModeCatalog.iconFor(mode.iconSemanticName),
                      accentColor: mode.accentColor,
                      badgeLabel: mode.queryStrategyType.label,
                      illustration: modeIllustrationFor(mode),
                      onTap: () => context.go('/modes/${mode.id}'),
                    ),
                ],
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
          ],
          SliverToBoxAdapter(
            child: SizedBox(
              height: AppSpacing.bottomNavHeight + AppSpacing.xxl,
            ),
          ),
        ],
      ),
    );
  }
}
