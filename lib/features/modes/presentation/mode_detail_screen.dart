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
import 'mode_visuals.dart';

class ModeDetailScreen extends ConsumerWidget {
  const ModeDetailScreen({required this.modeId, super.key});

  final String modeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(modeCatalogProvider);
    final mode = catalog.findById(modeId);

    if (mode == null) {
      return _UnknownModeScreen(modeId: modeId);
    }

    return ColoredBox(
      color: AppColors.surface,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: GradientHeader(
              compact: true,
              title: mode.title,
              subtitle: mode.longDescription,
              leading: HeaderIconButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => _goBackToModes(context),
              ),
              trailing: HeaderIconButton(
                icon: ModeCatalog.iconFor(mode.iconSemanticName),
              ),
              bottom: Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  StatusPill(
                    label: mode.category.label,
                    color: mode.accentColor,
                    filled: false,
                  ),
                  StatusPill(
                    label: mode.queryStrategyType.label,
                    color: AppColors.white,
                    filled: false,
                  ),
                  if (mode.hasCustomScreen)
                    const StatusPill(
                      label: 'Custom screen',
                      color: AppColors.white,
                      filled: false,
                    ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.page),
            sliver: SliverList.list(
              children: [
                SizedBox(
                  height: 188,
                  child: modeIllustrationFor(
                    mode,
                    borderRadius: AppRadius.xlBorder,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                _ActionPanel(mode: mode),
                const SizedBox(height: AppSpacing.xl),
                if (mode.hasCustomScreen) ...[
                  _CustomModePanel(mode: mode),
                  const SizedBox(height: AppSpacing.xl),
                ],
                _SectionTitle(
                  title: 'Default filters',
                  subtitle:
                      'These are local demo defaults until live signals are connected.',
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final filter in mode.defaultFilters)
                      StatusPill(
                        label: '${filter.label}: ${filter.value}',
                        color: mode.accentColor,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                _SectionTitle(
                  title: 'Capabilities',
                  subtitle:
                      'Route metadata used by the navigation and results surfaces.',
                ),
                const SizedBox(height: AppSpacing.sm),
                _CapabilityGrid(mode: mode),
                const SizedBox(height: AppSpacing.xl),
                _SectionTitle(
                  title: 'Demo results',
                  subtitle:
                      'Local sample content keeps the app rich before cloud data lands.',
                ),
                const SizedBox(height: AppSpacing.sm),
                for (final result in mode.demoResults) ...[
                  _DemoResultCard(mode: mode, result: result),
                  const SizedBox(height: AppSpacing.md),
                ],
                SizedBox(height: AppSpacing.bottomNavHeight + AppSpacing.xl),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void _goBackToModes(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go('/modes');
  }
}

class _ActionPanel extends StatelessWidget {
  const _ActionPanel({required this.mode});

  final DiscoveryMode mode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadius.largeCard,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PrimaryGradientButton(
            label: 'Preview results',
            icon: Icons.auto_awesome_rounded,
            onPressed: () => context.go('/modes/${mode.id}/results'),
          ),
          if (mode.supportsMapResults) ...[
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: () => context.go('/map'),
              icon: const Icon(Icons.map_rounded),
              label: const Text('Open map tab'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryBlue,
                side: const BorderSide(color: AppColors.borderStrong),
                minimumSize: const Size.fromHeight(52),
                textStyle: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CustomModePanel extends StatelessWidget {
  const _CustomModePanel({required this.mode});

  final DiscoveryMode mode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: mode.accentColor.withValues(alpha: 0.10),
        borderRadius: AppRadius.largeCard,
        border: Border.all(color: mode.accentColor.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          SoftIconBadge(
            icon: Icons.tune_rounded,
            color: mode.accentColor,
            showShadow: false,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Custom flow ready',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${mode.title} can branch into a tailored screen when the full experience is built.',
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

class _CapabilityGrid extends StatelessWidget {
  const _CapabilityGrid({required this.mode});

  final DiscoveryMode mode;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth = (constraints.maxWidth - AppSpacing.sm) / 2;
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _CapabilityTile(
              width: tileWidth,
              label: 'Map results',
              value: mode.supportsMapResults ? 'Supported' : 'Not needed',
              icon: Icons.map_rounded,
              color: mode.supportsMapResults
                  ? AppColors.primaryBlue
                  : AppColors.textMuted,
            ),
            _CapabilityTile(
              width: tileWidth,
              label: 'Saving',
              value: mode.supportsSaving ? 'Supported' : 'One-time use',
              icon: Icons.bookmark_rounded,
              color: mode.supportsSaving
                  ? AppColors.coral
                  : AppColors.textMuted,
            ),
            _CapabilityTile(
              width: tileWidth,
              label: 'Screen',
              value: mode.hasCustomScreen ? 'Custom' : 'Shared',
              icon: Icons.dashboard_customize_rounded,
              color: mode.hasCustomScreen ? mode.accentColor : AppColors.teal,
            ),
            _CapabilityTile(
              width: tileWidth,
              label: 'Strategy',
              value: mode.queryStrategyType.label,
              icon: Icons.route_rounded,
              color: mode.accentColor,
            ),
          ],
        );
      },
    );
  }
}

class _CapabilityTile extends StatelessWidget {
  const _CapabilityTile({
    required this.width,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final double width;
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: AppRadius.card,
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SoftIconBadge(
              icon: icon,
              color: color,
              size: 44,
              iconSize: 22,
              showShadow: false,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _DemoResultCard extends StatelessWidget {
  const _DemoResultCard({required this.mode, required this.result});

  final DiscoveryMode mode;
  final ModeDemoResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadius.largeCard,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            height: 112,
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        result.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    StatusPill(
                      label: result.distanceLabel,
                      color: mode.accentColor,
                      compact: true,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  result.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final tag in result.tags.take(3))
                      StatusPill(
                        label: tag,
                        color: mode.accentColor,
                        compact: true,
                        filled: false,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 2),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _UnknownModeScreen extends StatelessWidget {
  const _UnknownModeScreen({required this.modeId});

  final String modeId;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surface,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: GradientHeader(
              compact: true,
              title: 'Mode not found',
              subtitle: 'No local catalog entry exists for "$modeId".',
              leading: HeaderIconButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => _goBackToModes(context),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.page),
            sliver: SliverToBoxAdapter(
              child: PrimaryGradientButton(
                label: 'Back to modes',
                icon: Icons.grid_view_rounded,
                onPressed: () => context.go('/modes'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
