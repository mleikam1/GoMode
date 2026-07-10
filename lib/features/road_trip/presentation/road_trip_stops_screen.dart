import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../features/saved/application/saved_library_controller.dart';
import '../../../features/saved/domain/saved_item.dart';
import '../../../shared/widgets/primary_gradient_button.dart';
import '../data/road_trip_route_service.dart';
import '../data/route_stop_store.dart';
import '../domain/route_plan.dart';
import 'route_map_placeholder.dart';
import 'route_results_list.dart';

enum RoadTripView { results, map }

class RoadTripStopsScreen extends ConsumerStatefulWidget {
  const RoadTripStopsScreen({super.key});

  @override
  ConsumerState<RoadTripStopsScreen> createState() =>
      _RoadTripStopsScreenState();
}

class _RoadTripStopsScreenState extends ConsumerState<RoadTripStopsScreen> {
  late Future<RoutePlan> _routePlan;
  RoadTripView _selectedView = RoadTripView.results;
  final Set<StopCategory> _selectedFilters = {};
  Set<String> _savedStopIds = {};

  @override
  void initState() {
    super.initState();
    _routePlan = _loadRoutePlan();
    _loadSavedStops();
  }

  @override
  Widget build(BuildContext context) {
    final library = ref.watch(savedLibraryProvider);
    final savedStopIds = {
      ..._savedStopIds,
      ...library.maybeWhen(
        data: (value) => value.items
            .where((item) => item.id.startsWith('road-trip-stop-'))
            .map((item) => item.id.substring('road-trip-stop-'.length)),
        orElse: () => const Iterable<String>.empty(),
      ),
    };

    return ColoredBox(
      color: AppColors.surface,
      child: FutureBuilder<RoutePlan>(
        future: _routePlan,
        builder: (context, snapshot) {
          final plan = snapshot.data;
          if (plan == null) {
            if (snapshot.hasError) {
              return _RouteLoadError(onBack: _goBack, onTryAgain: _retryRoute);
            }
            return const Center(child: CircularProgressIndicator());
          }

          final visibleStops = _selectedFilters.isEmpty
              ? plan.stops
              : plan.stops
                    .where(
                      (stop) => stop.categories.any(
                        (category) => _selectedFilters.contains(category),
                      ),
                    )
                    .toList();

          return Stack(
            children: [
              CustomScrollView(
                key: const ValueKey('road-trip-stops-scroll-view'),
                slivers: [
                  SliverToBoxAdapter(
                    child: _RoadTripHeader(
                      plan: plan,
                      selectedView: _selectedView,
                      selectedFilters: _selectedFilters,
                      onBack: _goBack,
                      onViewChanged: (view) {
                        setState(() => _selectedView = view);
                      },
                      onFilterChanged: _toggleFilter,
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.page,
                      AppSpacing.sm,
                      AppSpacing.page,
                      0,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: _selectedView == RoadTripView.results
                            ? RouteResultsList(
                                key: const ValueKey('route-results-list'),
                                stops: visibleStops,
                                savedStopIds: savedStopIds,
                                onSave: _toggleSaved,
                                onFavorite: _toggleSaved,
                                onNavigate: _navigateToStop,
                              )
                            : RouteMapPlaceholder(
                                key: const ValueKey('route-map-view'),
                                plan: plan,
                                onOpenFullMap: () => context.go('/map'),
                              ),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 190)),
                ],
              ),
              Positioned(
                left: AppSpacing.md,
                right: AppSpacing.md,
                bottom: AppSpacing.bottomNavHeight,
                child: PrimaryGradientButton(
                  key: const ValueKey('open-route-map-button'),
                  label: 'Open Route Map',
                  icon: Icons.map_outlined,
                  height: 38,
                  onPressed: () {
                    if (_selectedView == RoadTripView.map) {
                      context.go('/map');
                    } else {
                      setState(() => _selectedView = RoadTripView.map);
                    }
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _loadSavedStops() async {
    final savedIds = await ref.read(routeStopStoreProvider).loadSavedStopIds();
    if (mounted) {
      setState(() => _savedStopIds = savedIds);
    }
  }

  Future<RoutePlan> _loadRoutePlan() {
    return ref.read(roadTripRouteServiceProvider).loadRoutePlan();
  }

  void _retryRoute() {
    setState(() {
      _routePlan = _loadRoutePlan();
    });
  }

  void _toggleFilter(StopCategory category) {
    setState(() {
      if (!_selectedFilters.add(category)) {
        _selectedFilters.remove(category);
      }
    });
  }

  Future<void> _toggleSaved(RouteStop stop) async {
    final itemId = 'road-trip-stop-${stop.id}';
    final libraryContains = ref
        .read(savedLibraryProvider)
        .maybeWhen(
          data: (value) => value.contains(itemId),
          orElse: () => false,
        );
    final shouldSave = !(_savedStopIds.contains(stop.id) || libraryContains);
    await ref.read(routeStopStoreProvider).setSaved(stop, saved: shouldSave);
    if (!mounted) {
      return;
    }

    setState(() {
      if (shouldSave) {
        _savedStopIds = {..._savedStopIds, stop.id};
      } else {
        _savedStopIds = {..._savedStopIds}..remove(stop.id);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          shouldSave
              ? '${stop.title} saved locally.'
              : '${stop.title} removed from saved stops.',
        ),
      ),
    );

    await ref.read(savedLibraryProvider.future);
    if (shouldSave) {
      await ref
          .read(savedLibraryProvider.notifier)
          .saveItem(_savedItemForStop(stop));
    } else {
      await ref.read(savedLibraryProvider.notifier).removeItem(itemId);
    }
  }

  SavedItem _savedItemForStop(RouteStop stop) {
    return SavedItem(
      id: 'road-trip-stop-${stop.id}',
      type: SavedItemType.place,
      categoryLabel: 'Road Trip Stop',
      title: stop.title,
      description: stop.savedDescription,
      savedAt: DateTime.now(),
      status: SavedItemStatus.saved,
      visual: SavedItemVisual.place,
      imageAsset: stop.imageAsset,
      destinationPath: '/modes/road-trip-stops',
    );
  }

  void _navigateToStop(RouteStop stop) {
    context.go('/map');
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/modes');
    }
  }
}

class _RoadTripHeader extends StatelessWidget {
  const _RoadTripHeader({
    required this.plan,
    required this.selectedView,
    required this.selectedFilters,
    required this.onBack,
    required this.onViewChanged,
    required this.onFilterChanged,
  });

  final RoutePlan plan;
  final RoadTripView selectedView;
  final Set<StopCategory> selectedFilters;
  final VoidCallback onBack;
  final ValueChanged<RoadTripView> onViewChanged;
  final ValueChanged<StopCategory> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.paddingOf(context).top;
    final summaryTop = safeTop + 126;
    final selectorInset = MediaQuery.sizeOf(context).width >= 440 ? 76.0 : 58.0;

    return SizedBox(
      height: summaryTop + 154,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 0,
            right: 0,
            height: summaryTop + 123,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppColors.headerGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(AppRadius.xxl),
                  bottomRight: Radius.circular(AppRadius.xxl),
                ),
              ),
            ),
          ),
          Positioned(
            left: AppSpacing.page,
            right: AppSpacing.page,
            top: safeTop + AppSpacing.sm,
            height: 58,
            child: Row(
              children: [
                _HeaderButton(
                  key: const ValueKey('road-trip-back-button'),
                  icon: Icons.arrow_back_rounded,
                  onTap: onBack,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Road Trip Stops',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 24,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.directions_car_rounded,
                            size: 17,
                            color: AppColors.lavender,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              plan.routeSubtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: AppColors.white.withValues(
                                      alpha: 0.72,
                                    ),
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                          if (plan.isDemo) ...[
                            const SizedBox(width: 6),
                            Container(
                              key: const ValueKey('road-trip-demo-fallback'),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.white.withValues(alpha: 0.12),
                                borderRadius: AppRadius.chip,
                                border: Border.all(
                                  color: AppColors.white.withValues(
                                    alpha: 0.18,
                                  ),
                                ),
                              ),
                              child: Text(
                                'Demo fallback',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 9,
                                    ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                const _HeaderButton(
                  icon: Icons.notifications_none_rounded,
                  showNotification: true,
                ),
              ],
            ),
          ),
          Positioned(
            left: selectorInset,
            right: selectorInset,
            top: safeTop + 76,
            height: 46,
            child: _ViewSelector(
              selectedView: selectedView,
              onChanged: onViewChanged,
            ),
          ),
          Positioned(
            left: AppSpacing.page,
            right: AppSpacing.page,
            top: summaryTop,
            height: 154,
            child: _RouteSummaryCard(
              summary: plan.summary,
              selectedFilters: selectedFilters,
              onFilterChanged: onFilterChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.icon,
    super.key,
    this.onTap,
    this.showNotification = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool showNotification;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: AppColors.white.withValues(alpha: 0.07),
          shape: CircleBorder(
            side: BorderSide(color: AppColors.white.withValues(alpha: 0.18)),
          ),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap ?? () {},
            child: SizedBox(
              width: 46,
              height: 46,
              child: Icon(icon, color: AppColors.white, size: 25),
            ),
          ),
        ),
        if (showNotification)
          const Positioned(
            right: 1,
            top: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.danger,
                shape: BoxShape.circle,
              ),
              child: SizedBox(width: 9, height: 9),
            ),
          ),
      ],
    );
  }
}

class _ViewSelector extends StatelessWidget {
  const _ViewSelector({required this.selectedView, required this.onChanged});

  final RoadTripView selectedView;
  final ValueChanged<RoadTripView> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.navy800.withValues(alpha: 0.82),
        borderRadius: AppRadius.chip,
        border: Border.all(color: AppColors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          for (final view in RoadTripView.values)
            Expanded(
              child: _ViewSegment(
                view: view,
                selected: selectedView == view,
                onTap: () => onChanged(view),
              ),
            ),
        ],
      ),
    );
  }
}

class _ViewSegment extends StatelessWidget {
  const _ViewSegment({
    required this.view,
    required this.selected,
    required this.onTap,
  });

  final RoadTripView view;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = view == RoadTripView.results ? 'Results' : 'Map';
    final icon = view == RoadTripView.results
        ? Icons.format_list_bulleted_rounded
        : Icons.map_outlined;
    final foreground = selected
        ? AppColors.primaryBlue
        : AppColors.white.withValues(alpha: 0.70);

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        key: ValueKey(
          'road-trip-${view.name}-tab-${selected ? 'selected' : 'unselected'}',
        ),
        color: selected ? AppColors.white : Colors.transparent,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: foreground, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RouteSummaryCard extends StatelessWidget {
  const _RouteSummaryCard({
    required this.summary,
    required this.selectedFilters,
    required this.onFilterChanged,
  });

  final RouteSummary summary;
  final Set<StopCategory> selectedFilters;
  final ValueChanged<StopCategory> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('route-summary-card'),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: AppRadius.xlBorder,
        border: Border.all(color: AppColors.primaryBlueLight),
        boxShadow: AppShadows.glowBlue,
      ),
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(15, 12, 15, 7),
              child: Row(
                children: [
                  SizedBox(
                    width: 116,
                    child: _RouteEndpoints(summary: summary),
                  ),
                  Container(
                    width: 1,
                    height: 62,
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    color: AppColors.white.withValues(alpha: 0.28),
                  ),
                  Expanded(child: _RouteMetrics(summary: summary)),
                ],
              ),
            ),
          ),
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.navy800.withValues(alpha: 0.76),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(AppRadius.xl),
                bottomRight: Radius.circular(AppRadius.xl),
              ),
              border: Border(
                top: BorderSide(color: AppColors.white.withValues(alpha: 0.13)),
              ),
            ),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 9),
              scrollDirection: Axis.horizontal,
              itemCount: StopCategory.values.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(width: AppSpacing.xs),
              itemBuilder: (context, index) {
                final category = StopCategory.values[index];
                final selected = selectedFilters.contains(category);
                return _FilterChip(
                  category: category,
                  selected: selected,
                  onTap: () => onFilterChanged(category),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteEndpoints extends StatelessWidget {
  const _RouteEndpoints({required this.summary});

  final RouteSummary summary;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: AppColors.white,
      fontWeight: FontWeight.w900,
    );
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.trip_origin_rounded,
              color: Color(0xFF59F2C6),
              size: 17,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                summary.origin,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textStyle,
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 7),
          child: Icon(
            Icons.more_vert_rounded,
            color: AppColors.white.withValues(alpha: 0.46),
            size: 17,
          ),
        ),
        Row(
          children: [
            const Icon(
              Icons.location_on_rounded,
              color: AppColors.coral,
              size: 18,
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                summary.destination,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textStyle,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RouteMetrics extends StatelessWidget {
  const _RouteMetrics({required this.summary});

  final RouteSummary summary;

  @override
  Widget build(BuildContext context) {
    final hours = summary.estimatedDriveTime.inHours;
    final minutes = summary.estimatedDriveTime.inMinutes.remainder(60);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Expanded(
              child: _Metric(
                value: '${summary.totalDistanceMiles} mi',
                label: 'Total distance',
              ),
            ),
            Container(
              width: 1,
              height: 38,
              color: AppColors.white.withValues(alpha: 0.30),
            ),
            Expanded(
              child: _Metric(
                value: '${hours}h ${minutes}m',
                label: 'Est. drive time',
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        _RouteProgress(progress: summary.progress),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          maxLines: 1,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w900,
            fontSize: 23,
          ),
        ),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.white.withValues(alpha: 0.76),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _RouteProgress extends StatelessWidget {
  const _RouteProgress({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('route-progress-bar'),
      height: 18,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            alignment: Alignment.centerLeft,
            children: [
              Positioned(
                left: 2,
                right: 2,
                child: ClipRRect(
                  borderRadius: AppRadius.chip,
                  child: LinearProgressIndicator(
                    minHeight: 5,
                    value: progress,
                    color: AppColors.primaryBlueLight,
                    backgroundColor: AppColors.white.withValues(alpha: 0.34),
                  ),
                ),
              ),
              Positioned(
                left: (constraints.maxWidth - 19) * progress,
                child: const Icon(
                  Icons.directions_car_filled_rounded,
                  color: AppColors.white,
                  size: 19,
                ),
              ),
              const Positioned(
                right: 0,
                child: Icon(
                  Icons.flag_rounded,
                  color: AppColors.white,
                  size: 17,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final StopCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor(category);
    return Material(
      key: ValueKey(
        'route-filter-${category.name}-${selected ? 'selected' : 'unselected'}',
      ),
      color: selected
          ? AppColors.white
          : AppColors.white.withValues(alpha: 0.05),
      shape: StadiumBorder(
        side: BorderSide(
          color: selected
              ? AppColors.white
              : AppColors.white.withValues(alpha: 0.18),
        ),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              Icon(_categoryIcon(category), color: color, size: 17),
              const SizedBox(width: 5),
              Text(
                category.label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: selected ? AppColors.navy900 : AppColors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RouteLoadError extends StatelessWidget {
  const _RouteLoadError({required this.onBack, required this.onTryAgain});

  final VoidCallback onBack;
  final VoidCallback onTryAgain;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.route_rounded,
              size: 52,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Route stops are unavailable',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Check your connection and try again.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton(onPressed: onBack, child: const Text('Back')),
                const SizedBox(width: AppSpacing.sm),
                FilledButton.icon(
                  onPressed: onTryAgain,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try again'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

IconData _categoryIcon(StopCategory category) => switch (category) {
  StopCategory.food => Icons.lunch_dining_rounded,
  StopCategory.coffee => Icons.coffee_rounded,
  StopCategory.gas => Icons.local_gas_station_rounded,
  StopCategory.bathrooms => Icons.wc_rounded,
  StopCategory.scenic => Icons.landscape_rounded,
};

Color _categoryColor(StopCategory category) => switch (category) {
  StopCategory.food => AppColors.amber,
  StopCategory.coffee => const Color(0xFFFFC27A),
  StopCategory.gas => AppColors.primaryBlueLight,
  StopCategory.bathrooms => const Color(0xFFE779FF),
  StopCategory.scenic => const Color(0xFF56E48B),
};
