import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/services/mode_catalog.dart';
import '../../../shared/widgets/shared_widgets.dart';
import '../../modes/presentation/mode_visuals.dart';

class DesignDebugScreen extends ConsumerWidget {
  const DesignDebugScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(modeCatalogProvider);
    final firstMode = catalog.modeById('date-night');
    final roadMode = catalog.modeById('road-trip-stops');

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: GradientHeader(
              compact: true,
              title: 'Design Debug',
              subtitle: 'Shared widgets and sample mode cards.',
              leading: HeaderIconButton(
                icon: Icons.arrow_back_rounded,
                onTap: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/profile');
                  }
                },
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.page),
            sliver: SliverList.list(
              children: [
                _DebugSection(
                  title: 'Actions',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      PrimaryGradientButton(
                        label: 'Primary action',
                        icon: Icons.auto_awesome_rounded,
                        onPressed: () {},
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: const [
                          FilterChipPill(
                            label: 'Food',
                            icon: Icons.lunch_dining_rounded,
                            color: AppColors.amber,
                          ),
                          FilterChipPill(
                            label: 'Date',
                            icon: Icons.favorite_rounded,
                            color: AppColors.coral,
                          ),
                          FilterChipPill(
                            label: 'Road',
                            icon: Icons.directions_car_rounded,
                            color: AppColors.lavender,
                          ),
                          StatusPill(label: 'Demo', color: AppColors.teal),
                        ],
                      ),
                    ],
                  ),
                ),
                _DebugSection(
                  title: 'Mode cards',
                  child: SizedBox(
                    height: 318,
                    child: ListView.separated(
                      clipBehavior: Clip.none,
                      scrollDirection: Axis.horizontal,
                      itemCount: 2,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: AppSpacing.md),
                      itemBuilder: (context, index) {
                        final mode = index == 0 ? firstMode : roadMode;
                        return ModeCard(
                          title: mode.title,
                          subtitle: mode.shortSubtitle,
                          icon: ModeCatalog.iconFor(mode.iconSemanticName),
                          accentColor: mode.accentColor,
                          badgeLabel: mode.category.label,
                          illustration: modeIllustrationFor(mode),
                          onTap: () => context.go('/modes/${mode.id}'),
                        );
                      },
                    ),
                  ),
                ),
                _DebugSection(
                  title: 'Compact cards',
                  child: Column(
                    children: [
                      CompactModeCard(
                        title: firstMode.title,
                        subtitle: firstMode.longDescription,
                        icon: ModeCatalog.iconFor(firstMode.iconSemanticName),
                        accentColor: firstMode.accentColor,
                        width: double.infinity,
                        onTap: () => context.go('/modes/${firstMode.id}'),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      CompactModeCard(
                        title: roadMode.title,
                        subtitle: roadMode.longDescription,
                        icon: ModeCatalog.iconFor(roadMode.iconSemanticName),
                        accentColor: roadMode.accentColor,
                        width: double.infinity,
                        onTap: () => context.go('/modes/${roadMode.id}'),
                      ),
                    ],
                  ),
                ),
                _DebugSection(
                  title: 'Illustrations',
                  child: SizedBox(
                    height: 150,
                    child: Row(
                      children: const [
                        Expanded(child: DateNightIllustration()),
                        SizedBox(width: AppSpacing.sm),
                        Expanded(child: RoadTripIllustration()),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DebugSection extends StatelessWidget {
  const _DebugSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: AppRadius.largeCard,
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.soft,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: AppSpacing.md),
            child,
          ],
        ),
      ),
    );
  }
}
