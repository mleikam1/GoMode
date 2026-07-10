import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/discovery_mode.dart';
import '../../../data/services/mode_catalog.dart';
import '../../../shared/widgets/shared_widgets.dart';

@visibleForTesting
final homeNowProvider = Provider<DateTime>((ref) => DateTime.now());

@visibleForTesting
final homeWeatherPlaceholderProvider = Provider<String>((ref) => 'sunny');

@visibleForTesting
final homeSpinRandomProvider = Provider<math.Random>((ref) => math.Random());

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  _HomeFilter? _activeFilter;
  double _wheelTurns = 0;
  bool _isSpinning = false;

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(modeCatalogProvider);
    final now = ref.watch(homeNowProvider);
    final weatherPlaceholder = ref.watch(homeWeatherPlaceholderProvider);
    final random = ref.watch(homeSpinRandomProvider);
    final popularModes = _popularModes(catalog.modes);
    return ColoredBox(
      color: AppColors.surface,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Stack(
              children: [
                Column(
                  children: [
                    GradientHeader(
                      compact: true,
                      showWordmark: true,
                      locationLabel: 'Austin, TX',
                      title: AppConstants.primaryQuestion,
                      bottom: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [
                          for (final filter in _homeFilters)
                            FilterChipPill(
                              key: ValueKey('home-filter-${filter.id}'),
                              label: filter.label,
                              icon: filter.icon,
                              color: filter.color,
                              compact: true,
                              selected: _activeFilter == filter.filter,
                              onDark: true,
                              onTap: () => _toggleFilter(filter.filter),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 96),
                  ],
                ),
                Positioned(
                  left: AppSpacing.page,
                  right: AppSpacing.page,
                  bottom: 0,
                  height: 166,
                  child: FeaturedModeCard(
                    key: const ValueKey('home-spin-card'),
                    title: 'Spin My Mode',
                    subtitle: 'Get a smart local idea',
                    actionLabel: _isSpinning
                        ? 'Picking a mode…'
                        : 'Spin My Mode',
                    illustration: Semantics(
                      liveRegion: true,
                      label: _isSpinning
                          ? 'Spinning mode wheel'
                          : 'Mode wheel ready to spin',
                      child: TweenAnimationBuilder<double>(
                        key: ValueKey('home-mode-wheel-$_wheelTurns'),
                        tween: Tween<double>(
                          begin: _wheelTurns == 0 ? 0 : _wheelTurns - 4.75,
                          end: _wheelTurns,
                        ),
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : const Duration(milliseconds: 900),
                        curve: Curves.easeOutCubic,
                        builder: (context, turns, child) {
                          return ModeWheelIllustration(
                            borderRadius: AppRadius.xlBorder,
                            rotationTurns: turns,
                          );
                        },
                      ),
                    ),
                    onPressed: _isSpinning
                        ? null
                        : () => _spinMode(
                            now: now,
                            weatherPlaceholder: weatherPlaceholder,
                            random: random,
                          ),
                  ),
                ),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.only(top: AppSpacing.xl),
            sliver: SliverToBoxAdapter(
              child: CategoryCarousel(
                title: 'Popular modes',
                onActionTap: () => context.go('/modes'),
                height: 176,
                spacing: AppSpacing.xs,
                children: [
                  for (final mode in popularModes)
                    ModeCard(
                      key: ValueKey('popular-mode-${mode.id}'),
                      title: mode.title,
                      subtitle: mode.subtitle,
                      icon: mode.icon,
                      accentColor: mode.color,
                      badgeLabel: mode.badge,
                      illustration: mode.illustration,
                      width: 104,
                      height: 176,
                      onTap: () => _openMode(context, mode.id),
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

  void _toggleFilter(_HomeFilter filter) {
    HapticFeedback.selectionClick();
    setState(() {
      _activeFilter = _activeFilter == filter ? null : filter;
    });
  }

  Future<void> _spinMode({
    required DateTime now,
    required String weatherPlaceholder,
    required math.Random random,
  }) async {
    if (_isSpinning) {
      return;
    }
    final selectedModeId = selectHomeSpinModeId(
      now: now,
      weatherPlaceholder: weatherPlaceholder,
      roadFilterActive: _activeFilter == _HomeFilter.roadTrip,
      random: random,
    );
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    setState(() {
      _isSpinning = true;
      _wheelTurns += 4.75;
    });
    if (!reduceMotion) {
      await Future<void>.delayed(const Duration(milliseconds: 920));
    }
    if (!mounted) {
      return;
    }
    setState(() => _isSpinning = false);
    _openMode(context, selectedModeId, impact: true);
  }
}

void _openMode(BuildContext context, String modeId, {bool impact = false}) {
  if (impact) {
    HapticFeedback.mediumImpact();
  } else {
    HapticFeedback.selectionClick();
  }
  context.go('/modes/$modeId');
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
        const _ContinuePlanCard(),
      ],
    );
  }
}

class _ContinuePlanCard extends StatelessWidget {
  const _ContinuePlanCard();

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
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 340) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  height: 128,
                  width: double.infinity,
                  child: SavedPlanThumbnail(
                    kind: SavedPlanThumbnailKind.weekendPark,
                    borderRadius: AppRadius.mdBorder,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(child: _ContinuePlanDetails(compact: true)),
                    const SizedBox(width: AppSpacing.sm),
                    _ContinuePlanArrow(onTap: () {}),
                  ],
                ),
              ],
            );
          }

          return Row(
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
              const Expanded(child: _ContinuePlanDetails()),
              const SizedBox(width: AppSpacing.sm),
              _ContinuePlanArrow(onTap: () {}),
            ],
          );
        },
      ),
    );
  }
}

class _ContinuePlanDetails extends StatelessWidget {
  const _ContinuePlanDetails({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: StatusPill(
              label: 'Weekend Plan',
              color: AppColors.teal,
              compact: true,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Barton Springs & Beyond',
          maxLines: compact ? 2 : 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            height: 1.05,
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
    );
  }
}

class _ContinuePlanArrow extends StatelessWidget {
  const _ContinuePlanArrow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
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
    );
  }
}

enum _HomeFilter { food, date, kids, roadTrip, outdoors, health, surpriseMe }

class _HomeFilterData {
  const _HomeFilterData({
    required this.filter,
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
  });

  final _HomeFilter filter;
  final String id;
  final String label;
  final IconData icon;
  final Color color;
}

const _homeFilterData = <_HomeFilterData>[
  _HomeFilterData(
    filter: _HomeFilter.food,
    id: 'food',
    label: 'Food',
    icon: Icons.lunch_dining_rounded,
    color: AppColors.amber,
  ),
  _HomeFilterData(
    filter: _HomeFilter.date,
    id: 'date',
    label: 'Date',
    icon: Icons.favorite_rounded,
    color: AppColors.coral,
  ),
  _HomeFilterData(
    filter: _HomeFilter.kids,
    id: 'kids',
    label: 'Kids',
    icon: Icons.family_restroom_rounded,
    color: AppColors.green,
  ),
  _HomeFilterData(
    filter: _HomeFilter.roadTrip,
    id: 'road-trip',
    label: 'Road Trip',
    icon: Icons.directions_car_rounded,
    color: AppColors.lavender,
  ),
  _HomeFilterData(
    filter: _HomeFilter.outdoors,
    id: 'outdoors',
    label: 'Outdoors',
    icon: Icons.park_rounded,
    color: AppColors.green,
  ),
  _HomeFilterData(
    filter: _HomeFilter.health,
    id: 'health',
    label: 'Health',
    icon: Icons.health_and_safety_rounded,
    color: AppColors.amber,
  ),
  _HomeFilterData(
    filter: _HomeFilter.surpriseMe,
    id: 'surprise-me',
    label: 'Surprise Me',
    icon: Icons.casino_rounded,
    color: AppColors.primaryBlueLight,
  ),
];

Iterable<_HomeFilterData> get _homeFilters => _homeFilterData;

@visibleForTesting
String selectHomeSpinModeId({
  required DateTime now,
  required String weatherPlaceholder,
  required bool roadFilterActive,
  required math.Random random,
}) {
  final rules = [
    _SpinRule(modeId: 'road-trip-stops', weight: roadFilterActive ? 100 : 0),
    _SpinRule(
      modeId: 'rainy-day-ideas',
      weight: _isRainy(weatherPlaceholder) ? 90 : 0,
    ),
    _SpinRule(modeId: 'date-night', weight: _isEvening(now) ? 80 : 0),
    _SpinRule(modeId: 'weekend-plan', weight: _isWeekend(now) ? 70 : 0),
  ]..sort((a, b) => b.weight.compareTo(a.weight));

  if (rules.first.weight > 0) {
    return rules.first.modeId;
  }

  const fallbackModeIds = [
    'food-wheel',
    'date-night',
    'weekend-plan',
    'kids-bored-button',
    'road-trip-stops',
    'allergy-map',
    'patio-finder',
  ];

  return fallbackModeIds[random.nextInt(fallbackModeIds.length)];
}

class _SpinRule {
  const _SpinRule({required this.modeId, required this.weight});

  final String modeId;
  final int weight;
}

bool _isEvening(DateTime now) => now.hour >= 17 || now.hour < 2;

bool _isWeekend(DateTime now) {
  return now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;
}

bool _isRainy(String weatherPlaceholder) {
  return weatherPlaceholder.toLowerCase().contains('rain');
}

class _HomeModeCardData {
  const _HomeModeCardData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.illustration,
    this.badge,
  });

  final String id;
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
      id: 'date-night',
      title: 'Date Night',
      subtitle:
          lookup['date-night']?.shortSubtitle ?? 'Romantic spots and fun ideas',
      icon: Icons.favorite_border_rounded,
      color: AppColors.coral,
      badge: 'Popular',
      illustration: const DateNightIllustration(),
    ),
    _HomeModeCardData(
      id: 'weekend-plan',
      title: 'Weekend Plan',
      subtitle:
          lookup['weekend-plan']?.shortSubtitle ??
          'Make the most of your weekend',
      icon: Icons.calendar_month_rounded,
      color: AppColors.teal,
      badge: 'Great tonight',
      illustration: const WeekendParkIllustration(),
    ),
    _HomeModeCardData(
      id: 'road-trip-stops',
      title: 'Road Trip Stops',
      subtitle:
          lookup['road-trip-stops']?.shortSubtitle ??
          'Scenic places worth the detour',
      icon: Icons.directions_car_rounded,
      color: AppColors.lavender,
      badge: 'Popular',
      illustration: const RoadTripIllustration(),
    ),
    _HomeModeCardData(
      id: 'allergy-map',
      title: 'Allergy Map',
      subtitle:
          lookup['allergy-map']?.shortSubtitle ?? 'Find safe places near you',
      icon: Icons.local_florist_rounded,
      color: AppColors.amber,
      badge: 'New',
      illustration: const AllergyOutdoorIllustration(),
    ),
  ];
}
