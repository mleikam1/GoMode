import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/services/mode_catalog.dart';
import '../../../shared/widgets/shared_widgets.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(modeCatalogProvider);

    return ColoredBox(
      color: AppColors.surface,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: GradientHeader(
              compact: true,
              title: 'Profile',
              subtitle: 'Demo preferences for smarter local picks.',
              bottom: Row(
                children: [
                  const SoftIconBadge(
                    icon: Icons.person_rounded,
                    color: AppColors.white,
                    backgroundColor: AppColors.primaryBlue,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Matt',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        Text(
                          'Austin, TX',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppColors.white.withValues(alpha: 0.72),
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.page),
            sliver: SliverList.list(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _ProfileMetric(
                        label: 'Modes',
                        value: '${catalog.modes.length}',
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _ProfileMetric(
                        label: 'Map ready',
                        value: '${catalog.mapModes.length}',
                        color: AppColors.teal,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _ProfileMetric(
                        label: 'Saved',
                        value: '${catalog.savingModes.length}',
                        color: AppColors.coral,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                _ProfileRow(
                  icon: Icons.tune_rounded,
                  color: AppColors.primaryBlue,
                  title: 'Preferences',
                  subtitle: 'Food, budget, distance, and pace',
                  onTap: () {},
                ),
                _ProfileRow(
                  icon: Icons.location_on_rounded,
                  color: AppColors.teal,
                  title: 'Home area',
                  subtitle: 'Austin demo location',
                  onTap: () => context.go('/map'),
                ),
                _ProfileRow(
                  icon: Icons.palette_rounded,
                  color: AppColors.lavender,
                  title: 'Design debug',
                  subtitle: 'Shared widgets and sample cards',
                  onTap: () => context.go('/debug/design'),
                ),
                _ProfileRow(
                  icon: Icons.privacy_tip_rounded,
                  color: AppColors.amber,
                  title: 'Data controls',
                  subtitle: 'Local demo data only',
                  onTap: () {},
                ),
                SizedBox(height: AppSpacing.bottomNavHeight + AppSpacing.xl),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileMetric extends StatelessWidget {
  const _ProfileMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadius.largeCard,
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceRaised,
              borderRadius: AppRadius.largeCard,
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                SoftIconBadge(
                  icon: icon,
                  color: color,
                  size: 50,
                  iconSize: 25,
                  showShadow: false,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
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
      ),
    );
  }
}
