import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/discovery_mode.dart';
import '../../../data/repositories/discovery_repository.dart';
import '../../../shared/widgets/shared_widgets.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modes = ref.watch(discoveryRepositoryProvider).getModes();
    final popularModes = _popularModes(modes);

    return GoModeScaffold(
      currentIndex: 0,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: GradientHeader(
              showWordmark: true,
              locationLabel: 'Austin, TX',
              title: AppConstants.primaryQuestion,
              bottom: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: const [
                      FilterChipPill(
                        label: 'Food',
                        icon: Icons.lunch_dining_rounded,
                        color: AppColors.amber,
                        onDark: true,
                      ),
                      FilterChipPill(
                        label: 'Date',
                        icon: Icons.favorite_rounded,
                        color: AppColors.coral,
                        onDark: true,
                      ),
                      FilterChipPill(
                        label: 'Kids',
                        icon: Icons.family_restroom_rounded,
                        color: AppColors.green,
                        onDark: true,
                      ),
                      FilterChipPill(
                        label: 'Road Trip',
                        icon: Icons.directions_car_rounded,
                        color: AppColors.lavender,
                        onDark: true,
                      ),
                      FilterChipPill(
                        label: 'Outdoors',
                        icon: Icons.park_rounded,
                        color: AppColors.green,
                        onDark: true,
                      ),
                      FilterChipPill(
                        label: 'Health',
                        icon: Icons.health_and_safety_rounded,
                        color: AppColors.amber,
                        onDark: true,
                      ),
                      FilterChipPill(
                        label: 'Surprise Me',
                        icon: Icons.casino_rounded,
                        color: AppColors.white,
                        onDark: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FeaturedModeCard(
                    title: 'Spin My Mode',
                    subtitle: 'Get a smart local idea',
                    actionLabel: 'Spin My Mode',
                    illustration: const ModeWheelIllustration(
                      borderRadius: AppRadius.xlBorder,
                    ),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.only(top: AppSpacing.xl),
            sliver: SliverToBoxAdapter(
              child: CategoryCarousel(
                title: 'Popular modes',
                height: 294,
                children: [
                  for (final mode in popularModes)
                    ModeCard(
                      title: mode.title,
                      subtitle: mode.subtitle,
                      icon: mode.icon,
                      accentColor: mode.color,
                      badgeLabel: mode.badge,
                      illustration: mode.illustration,
                    ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
          const SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.page),
            sliver: SliverToBoxAdapter(child: _ContinueSection()),
          ),
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

class _ContinueSection extends StatelessWidget {
  const _ContinueSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Continue where you left off',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            TextButton.icon(
              onPressed: () {},
              iconAlignment: IconAlignment.end,
              icon: const Icon(Icons.chevron_right_rounded),
              label: const Text('View all'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryBlue,
                textStyle: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceRaised,
            borderRadius: AppRadius.largeCard,
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.card,
          ),
          child: Row(
            children: [
              const SizedBox(
                width: 128,
                height: 96,
                child: SavedPlanThumbnail(
                  kind: SavedPlanThumbnailKind.weekendPark,
                  borderRadius: AppRadius.mdBorder,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const StatusPill(
                      label: 'Weekend Plan',
                      color: AppColors.teal,
                      compact: true,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Barton Springs & Beyond',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          color: AppColors.textMuted,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Saved 2 days ago',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '2 of 6 places visited',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const ProgressPill(value: 0.34, color: AppColors.teal),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Material(
                color: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  onTap: () {},
                  child: const SizedBox(
                    width: 52,
                    height: 52,
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textPrimary,
                      size: 30,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HomeModeCardData {
  const _HomeModeCardData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.illustration,
    this.badge,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget illustration;
  final String? badge;
}

List<_HomeModeCardData> _popularModes(List<DiscoveryMode> modes) {
  final lookup = {for (final mode in modes) mode.id: mode};

  return [
    _HomeModeCardData(
      title: 'Date Night',
      subtitle:
          lookup['date-night']?.description ?? 'Romantic spots and fun ideas',
      icon: Icons.favorite_border_rounded,
      color: AppColors.coral,
      badge: 'Popular',
      illustration: const DateNightIllustration(),
    ),
    _HomeModeCardData(
      title: 'Weekend Plan',
      subtitle:
          lookup['weekend']?.description ?? 'Make the most of your weekend',
      icon: Icons.calendar_month_rounded,
      color: AppColors.teal,
      badge: 'Great tonight',
      illustration: const WeekendParkIllustration(),
    ),
    _HomeModeCardData(
      title: 'Road Trip Stops',
      subtitle:
          lookup['road-trip']?.description ?? 'Scenic places worth the detour',
      icon: Icons.directions_car_rounded,
      color: AppColors.lavender,
      badge: 'Popular',
      illustration: const RoadTripIllustration(),
    ),
    const _HomeModeCardData(
      title: 'Allergy Map',
      subtitle: 'Find safe places near you',
      icon: Icons.local_florist_rounded,
      color: AppColors.amber,
      badge: 'New',
      illustration: AllergyOutdoorIllustration(),
    ),
  ];
}
