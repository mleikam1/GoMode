import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/discovery_mode.dart';
import '../../../data/services/mode_catalog.dart';
import '../../../features/saved/application/saved_library_controller.dart';
import '../../../features/saved/domain/saved_item.dart';
import '../../../shared/widgets/shared_widgets.dart';
import '../data/generic_mode_results_service.dart';
import 'mode_visuals.dart';

class ModeResultsScreen extends ConsumerStatefulWidget {
  const ModeResultsScreen({
    required this.modeId,
    this.selectedFilters = const {},
    super.key,
  });

  final String modeId;
  final Map<String, String> selectedFilters;

  @override
  ConsumerState<ModeResultsScreen> createState() => _ModeResultsScreenState();
}

class _ModeResultsScreenState extends ConsumerState<ModeResultsScreen> {
  final Set<String> _completedResultIds = {};
  double _wheelTurns = 4;
  int _wheelChoice = 0;

  @override
  void didUpdateWidget(covariant ModeResultsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.modeId != widget.modeId) {
      _completedResultIds.clear();
      _wheelTurns = 4;
      _wheelChoice = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(modeCatalogProvider);
    final mode = catalog.findById(widget.modeId);
    if (mode == null) {
      return _UnknownResultsScreen(modeId: widget.modeId);
    }

    final request = ModeResultsRequest(
      modeId: mode.id,
      filters: widget.selectedFilters,
    );
    final resultState = ref.watch(genericModeResultsProvider(request));
    final showingDemo = resultState.maybeWhen(
      data: (results) => results.any((result) => result.isDemo),
      orElse: () => false,
    );
    final filterValues = widget.selectedFilters.values.isNotEmpty
        ? widget.selectedFilters.values
        : mode.defaultFilters.map((filter) => filter.value);

    return ColoredBox(
      color: AppColors.surface,
      child: CustomScrollView(
        key: ValueKey('mode-results-${mode.id}'),
        slivers: [
          SliverToBoxAdapter(
            child: GradientHeader(
              compact: true,
              title: '${mode.title} results',
              subtitle: _resultsSubtitle(mode),
              leading: HeaderIconButton(
                icon: Icons.arrow_back_rounded,
                onTap: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/modes/${mode.id}');
                  }
                },
              ),
              trailing: HeaderIconButton(
                icon: Icons.bookmark_border_rounded,
                onTap: () => context.go('/saved'),
              ),
              bottom: Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final value in filterValues.take(4))
                    StatusPill(
                      label: value,
                      color: AppColors.white,
                      filled: false,
                    ),
                  if (showingDemo)
                    const StatusPill(
                      label: 'Demo fallback',
                      color: AppColors.white,
                      filled: false,
                    ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.page),
            sliver: resultState.when(
              loading: () => SliverList.list(
                children: [
                  _LoadingResultsState(mode: mode),
                  SizedBox(height: AppSpacing.bottomNavHeight + AppSpacing.xl),
                ],
              ),
              error: (error, stackTrace) => SliverList.list(
                children: [
                  _ErrorResultsState(
                    mode: mode,
                    error: error,
                    onTryAgain: () =>
                        ref.invalidate(genericModeResultsProvider(request)),
                  ),
                  SizedBox(height: AppSpacing.bottomNavHeight + AppSpacing.xl),
                ],
              ),
              data: (results) {
                if (results.isEmpty) {
                  return SliverList.list(
                    children: [
                      _EmptyResultsState(
                        mode: mode,
                        onTryAgain: () =>
                            ref.invalidate(genericModeResultsProvider(request)),
                      ),
                      SizedBox(
                        height: AppSpacing.bottomNavHeight + AppSpacing.xl,
                      ),
                    ],
                  );
                }
                return _resultsList(mode, results);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultsList(DiscoveryMode mode, List<ModeResultItem> allResults) {
    final library = ref.watch(savedLibraryProvider);
    final isWheel = mode.id == 'food-wheel';
    final visibleResults = isWheel
        ? [allResults[_wheelChoice % allResults.length]]
        : allResults;
    String? fallbackMessage;
    for (final result in allResults) {
      if (result.fallbackMessage != null) {
        fallbackMessage = result.fallbackMessage;
        break;
      }
    }

    return SliverList.list(
      children: [
        if (fallbackMessage != null) ...[
          _FallbackNotice(message: fallbackMessage),
          const SizedBox(height: AppSpacing.md),
        ],
        _modeSummary(mode, allResults),
        const SizedBox(height: AppSpacing.xl),
        if (mode.supportsMapResults && !isWheel) ...[
          _MapPreview(mode: mode, resultCount: allResults.length),
          const SizedBox(height: AppSpacing.xl),
        ],
        Row(
          children: [
            Expanded(
              child: Text(
                _resultSectionTitle(mode, visibleResults.length),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              '${visibleResults.length}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: mode.accentColor,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        for (var index = 0; index < visibleResults.length; index++)
          Builder(
            builder: (context) {
              final result = visibleResults[index];
              final item = _savedItemForResult(mode, result);
              final saved = library.maybeWhen(
                data: (value) => value.contains(item.id),
                orElse: () => false,
              );
              return _ResultCard(
                mode: mode,
                result: result,
                index: index,
                saved: saved,
                completed: _completedResultIds.contains(result.id),
                showProgressAction: _isProgressMode(mode),
                onToggleCompleted: () {
                  setState(() {
                    if (!_completedResultIds.add(result.id)) {
                      _completedResultIds.remove(result.id);
                    }
                  });
                },
                onToggleSaved: () => _toggleSaved(item),
                onNavigate: () => context.go('/map'),
              );
            },
          ),
        const SizedBox(height: AppSpacing.sm),
        PrimaryGradientButton(
          label: 'View saved items',
          icon: Icons.bookmarks_rounded,
          onPressed: () => context.go('/saved'),
        ),
        SizedBox(height: AppSpacing.bottomNavHeight + AppSpacing.xl),
      ],
    );
  }

  Widget _modeSummary(DiscoveryMode mode, List<ModeResultItem> results) {
    if (mode.id == 'food-wheel') {
      final choice = results[_wheelChoice % results.length];
      return _FoodWheelPanel(
        mode: mode,
        choice: choice,
        turns: _wheelTurns,
        onSpinAgain: () {
          setState(() {
            _wheelChoice = (_wheelChoice + 1) % results.length;
            _wheelTurns += 4.75;
          });
        },
      );
    }
    if (_isProgressMode(mode)) {
      return _ProgressSummaryPanel(
        mode: mode,
        completed: _completedResultIds.length,
        total: results.length,
        onMarkNextComplete: () {
          final next = results.where(
            (result) => !_completedResultIds.contains(result.id),
          );
          if (next.isEmpty) {
            setState(_completedResultIds.clear);
          } else {
            setState(() => _completedResultIds.add(next.first.id));
          }
        },
      );
    }

    final summary = _summaryFor(mode, results);
    return _SummaryPanel(
      icon: summary.icon,
      title: summary.title,
      message: summary.message,
      color: mode.accentColor,
      warning: summary.warning,
    );
  }

  Future<void> _toggleSaved(SavedItem item) async {
    try {
      await ref.read(savedLibraryProvider.future);
      await ref.read(savedLibraryProvider.notifier).toggleItem(item);
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update saved items. Try again.'),
        ),
      );
    }
  }
}

class _FallbackNotice extends StatelessWidget {
  const _FallbackNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('mode-results-fallback-notice'),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.amber.withValues(alpha: 0.10),
        borderRadius: AppRadius.largeCard,
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.32)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.warning),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _resultsSubtitle(DiscoveryMode mode) {
  return switch (mode.id) {
    'weekend-plan' => 'A balanced, flexible local itinerary.',
    'food-wheel' => 'One spin. One dinner decision.',
    'food-challenge' => 'Pick a challenge and track your progress.',
    'kids-bored-button' => 'Fast family-friendly ideas.',
    'road-rescue' => 'Urgent nearby categories in one place.',
    'local-quest' => 'Complete each clue to finish the quest.',
    'tourist-mode' => 'A self-guided route you can adjust.',
    _ => 'A focused shortlist based on your choices.',
  };
}

bool _isProgressMode(DiscoveryMode mode) {
  return mode.id == 'food-challenge' || mode.id == 'local-quest';
}

String _resultSectionTitle(DiscoveryMode mode, int count) {
  return switch (mode.id) {
    'weekend-plan' || 'tourist-mode' => 'Your route',
    'food-challenge' || 'local-quest' => 'Challenge cards',
    'food-wheel' => 'The wheel chose',
    'where-should-i-live' => 'Suggested neighborhoods',
    'road-rescue' => 'Nearby help categories',
    _ => count == 1 ? 'Top result' : 'Top results',
  };
}

class _ModeSummaryCopy {
  const _ModeSummaryCopy({
    required this.icon,
    required this.title,
    required this.message,
    this.warning = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final bool warning;
}

_ModeSummaryCopy _summaryFor(DiscoveryMode mode, List<ModeResultItem> results) {
  final resultCount = results.length;
  final hasLiveResults = results.any((result) => !result.isDemo);
  final hasLivePollen = results.any(
    (result) => result.tags.contains('Live forecast'),
  );
  final hasLiveAir = results.any((result) => result.tags.contains('Live AQI'));
  return switch (mode.id) {
    'weekend-plan' => _ModeSummaryCopy(
      icon: Icons.calendar_month_rounded,
      title: 'Your $resultCount-stop itinerary',
      message: 'The order keeps travel light and leaves room to slow down.',
    ),
    'patio-finder' => const _ModeSummaryCopy(
      icon: Icons.deck_rounded,
      title: 'Outdoor-style shortlist',
      message:
          'Verify current seating, weather, and patio hours before leaving.',
    ),
    'cheap-date' => const _ModeSummaryCopy(
      icon: Icons.savings_outlined,
      title: 'Low-cost combinations',
      message:
          'Prices are planning placeholders; confirm current costs at each stop.',
    ),
    'kids-bored-button' => const _ModeSummaryCopy(
      icon: Icons.bolt_rounded,
      title: 'One-tap family picks',
      message: 'Choose the first idea that fits the energy in the room.',
    ),
    'rainy-day-ideas' => const _ModeSummaryCopy(
      icon: Icons.umbrella_rounded,
      title: 'Indoor ideas',
      message: 'Each suggestion keeps outdoor transitions short and simple.',
    ),
    'dog-friendly-spots' => const _ModeSummaryCopy(
      icon: Icons.pets_rounded,
      title: 'Pet-friendly leads',
      message:
          'Pet policies can change. Verify the current policy before you go.',
      warning: true,
    ),
    'ev-charge-chill' => const _ModeSummaryCopy(
      icon: Icons.ev_station_rounded,
      title: 'Charge-adjacent ideas',
      message:
          'Confirm connector compatibility and live charger availability in your charging app.',
      warning: true,
    ),
    'road-rescue' => const _ModeSummaryCopy(
      icon: Icons.health_and_safety_rounded,
      title: 'Urgent nearby categories',
      message:
          'Hours are not live. Call ahead, and use emergency services for emergencies.',
      warning: true,
    ),
    'open-now' => _ModeSummaryCopy(
      icon: Icons.schedule_rounded,
      title: 'Open-now shortlist',
      message: hasLiveResults
          ? 'Google reports these places open now. Hours can change, so verify before traveling.'
          : 'Live hours are unavailable in fallback mode. Verify before traveling.',
      warning: true,
    ),
    'allergy-map' => _ModeSummaryCopy(
      icon: Icons.local_florist_rounded,
      title: hasLivePollen
          ? 'Pollen-aware planning'
          : 'Live pollen unavailable',
      message: hasLivePollen
          ? 'Use the pollen outlook with nearby indoor or outdoor ideas and your personal medical guidance.'
          : 'Nearby ideas do not represent current pollen conditions.',
      warning: true,
    ),
    'clean-air-planner' => _ModeSummaryCopy(
      icon: Icons.air_rounded,
      title: hasLiveAir
          ? 'Current air-aware plan'
          : 'Live air quality unavailable',
      message: hasLiveAir
          ? 'Use the current AQI as one planning signal alongside weather and personal guidance.'
          : 'Check current AQI and heat guidance before choosing an outdoor activity.',
      warning: true,
    ),
    'solar-checker' => _ModeSummaryCopy(
      icon: Icons.wb_sunny_rounded,
      title: results.any((result) => result.tags.contains('Live building data'))
          ? 'Solar building data found'
          : results.any((result) => result.title == 'Connect Solar API')
          ? 'Connect Solar API state'
          : 'Solar data unavailable',
      message:
          results.any((result) => result.tags.contains('Live building data'))
          ? 'Building insight is available for review; it is not an installation recommendation.'
          : 'No roof, shade, energy production, savings, or installation analysis has been performed.',
      warning: true,
    ),
    'neighborhood-check' => const _ModeSummaryCopy(
      icon: Icons.location_city_rounded,
      title: 'Amenities and livability overview',
      message:
          'Use these everyday categories as a starting point for an in-person check.',
    ),
    'where-should-i-live' => const _ModeSummaryCopy(
      icon: Icons.home_work_outlined,
      title: 'Lifestyle quiz matches',
      message:
          'These are exploration leads, not housing or financial recommendations.',
      warning: true,
    ),
    'tourist-mode' => _ModeSummaryCopy(
      icon: Icons.route_rounded,
      title: '$resultCount-stop self-guided itinerary',
      message:
          'Follow the order or save individual stops and make it your own.',
    ),
    _ => _ModeSummaryCopy(
      icon: ModeCatalog.iconFor(mode.iconSemanticName),
      title: '$resultCount useful suggestions',
      message: 'Save a favorite or navigate to view it in the map tab.',
    ),
  };
}

class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
    required this.warning,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color color;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final panelColor = warning ? AppColors.warning : color;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: panelColor.withValues(alpha: 0.09),
        borderRadius: AppRadius.largeCard,
        border: Border.all(color: panelColor.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SoftIconBadge(icon: icon, color: panelColor, showShadow: false),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(message, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FoodWheelPanel extends StatelessWidget {
  const _FoodWheelPanel({
    required this.mode,
    required this.choice,
    required this.turns,
    required this.onSpinAgain,
  });

  final DiscoveryMode mode;
  final ModeResultItem choice;
  final double turns;
  final VoidCallback onSpinAgain;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: mode.accentColor.withValues(alpha: 0.10),
        borderRadius: AppRadius.largeCard,
        border: Border.all(color: mode.accentColor.withValues(alpha: 0.28)),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 170,
            height: 170,
            child: Stack(
              alignment: Alignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  key: ValueKey('food-wheel-$turns'),
                  tween: Tween(begin: turns - 4, end: turns),
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Transform.rotate(
                      angle: value * math.pi * 2,
                      child: child,
                    );
                  },
                  child: CustomPaint(
                    key: const ValueKey('food-wheel-animation'),
                    painter: _FoodWheelPainter(mode.accentColor),
                    child: const SizedBox.expand(),
                  ),
                ),
                Container(
                  width: 46,
                  height: 46,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.white,
                  ),
                  child: const Icon(Icons.restaurant_rounded),
                ),
                const Positioned(
                  top: 0,
                  child: Icon(
                    Icons.arrow_drop_down_rounded,
                    color: AppColors.navy900,
                    size: 38,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Tonight’s pick',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: mode.accentColor,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            choice.title,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            key: const ValueKey('spin-food-wheel-again'),
            onPressed: onSpinAgain,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Spin again'),
          ),
        ],
      ),
    );
  }
}

class _FoodWheelPainter extends CustomPainter {
  const _FoodWheelPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    const segmentCount = 8;
    for (var index = 0; index < segmentCount; index++) {
      final paint = Paint()
        ..color = index.isEven
            ? color
            : Color.lerp(color, AppColors.white, 0.52)!;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2 + index * math.pi * 2 / segmentCount,
        math.pi * 2 / segmentCount,
        true,
        paint,
      );
    }
    canvas.drawCircle(
      center,
      radius - 2,
      Paint()
        ..color = AppColors.white.withValues(alpha: 0.65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
  }

  @override
  bool shouldRepaint(covariant _FoodWheelPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _ProgressSummaryPanel extends StatelessWidget {
  const _ProgressSummaryPanel({
    required this.mode,
    required this.completed,
    required this.total,
    required this.onMarkNextComplete,
  });

  final DiscoveryMode mode;
  final int completed;
  final int total;
  final VoidCallback onMarkNextComplete;

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : completed / total;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: mode.accentColor.withValues(alpha: 0.10),
        borderRadius: AppRadius.largeCard,
        border: Border.all(color: mode.accentColor.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SoftIconBadge(
                icon: Icons.emoji_events_rounded,
                color: mode.accentColor,
                showShadow: false,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mode.id == 'local-quest'
                          ? 'Quest progress'
                          : 'Challenge progress',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text('$completed of $total complete'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          LinearProgressIndicator(
            key: ValueKey('mode-progress-${mode.id}'),
            value: progress,
            minHeight: 10,
            color: mode.accentColor,
            backgroundColor: mode.accentColor.withValues(alpha: 0.16),
            borderRadius: AppRadius.chip,
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: onMarkNextComplete,
            icon: Icon(
              completed == total
                  ? Icons.refresh_rounded
                  : Icons.check_circle_outline_rounded,
            ),
            label: Text(
              completed == total ? 'Reset progress' : 'Complete next step',
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPreview extends StatelessWidget {
  const _MapPreview({required this.mode, required this.resultCount});

  final DiscoveryMode mode;
  final int resultCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 188,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadius.largeCard,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: mode.accentColor.withValues(alpha: 0.10),
                borderRadius: AppRadius.card,
              ),
              child: CustomPaint(painter: _MapPreviewPainter(mode.accentColor)),
            ),
          ),
          Positioned(
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: AppSpacing.md,
            child: Row(
              children: [
                SoftIconBadge(
                  icon: Icons.map_rounded,
                  color: mode.accentColor,
                  backgroundColor: AppColors.white,
                  showShadow: false,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    '$resultCount suggestions ready for the map',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.mode,
    required this.result,
    required this.index,
    required this.saved,
    required this.completed,
    required this.showProgressAction,
    required this.onToggleCompleted,
    required this.onToggleSaved,
    required this.onNavigate,
  });

  final DiscoveryMode mode;
  final ModeResultItem result;
  final int index;
  final bool saved;
  final bool completed;
  final bool showProgressAction;
  final VoidCallback onToggleCompleted;
  final Future<void> Function() onToggleSaved;
  final VoidCallback onNavigate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        key: ValueKey('mode-result-card-${result.id}'),
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 96,
                  height: 96,
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
                        label: _cardEyebrow(mode, index),
                        color: mode.accentColor,
                        compact: true,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        result.title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                if (result.rating != null)
                  _MetaPill(
                    icon: Icons.star_rounded,
                    label: result.rating!.toStringAsFixed(1),
                    color: AppColors.amber,
                  ),
                _MetaPill(
                  icon: Icons.near_me_rounded,
                  label: result.distanceLabel,
                  color: mode.accentColor,
                ),
                if (result.openStatus != null)
                  _MetaPill(
                    icon: result.openStatus == 'Open now'
                        ? Icons.schedule_rounded
                        : Icons.help_outline_rounded,
                    label: result.openStatus!,
                    color: result.openStatus == 'Open now'
                        ? AppColors.success
                        : AppColors.textMuted,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(result.subtitle, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(result.detail, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final tag in result.tags)
                  StatusPill(
                    label: tag,
                    color: mode.accentColor,
                    compact: true,
                    filled: false,
                  ),
              ],
            ),
            if (showProgressAction) ...[
              const SizedBox(height: AppSpacing.sm),
              TextButton.icon(
                key: ValueKey('complete-mode-result-${result.id}'),
                onPressed: onToggleCompleted,
                icon: Icon(
                  completed
                      ? Icons.check_circle_rounded
                      : Icons.check_circle_outline_rounded,
                ),
                label: Text(completed ? 'Completed' : 'Mark complete'),
              ),
            ],
            const Divider(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: ValueKey(_actionKey('save', result.id)),
                    onPressed: onToggleSaved,
                    icon: Icon(
                      saved
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                    ),
                    label: Text(saved ? 'Saved' : 'Save'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton.icon(
                    key: ValueKey(_actionKey('navigate', result.id)),
                    onPressed: onNavigate,
                    style: FilledButton.styleFrom(
                      backgroundColor: mode.accentColor,
                      foregroundColor: AppColors.white,
                    ),
                    icon: const Icon(Icons.navigation_rounded),
                    label: const Text('Navigate'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _actionKey(String action, String resultId) {
  final compactId = resultId.replaceFirst('-result-', '-');
  return '$action-mode-result-$compactId';
}

String _cardEyebrow(DiscoveryMode mode, int index) {
  return switch (mode.id) {
    'weekend-plan' || 'tourist-mode' => 'Stop ${index + 1}',
    'food-challenge' || 'local-quest' => 'Challenge ${index + 1}',
    'road-rescue' => 'Help option ${index + 1}',
    'where-should-i-live' => 'Match ${index + 1}',
    _ => 'Suggestion ${index + 1}',
  };
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: AppRadius.chip,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingResultsState extends StatelessWidget {
  const _LoadingResultsState({required this.mode});

  final DiscoveryMode mode;

  @override
  Widget build(BuildContext context) {
    return _StateCard(
      key: ValueKey('mode-results-loading-${mode.id}'),
      icon: Icons.travel_explore_rounded,
      color: mode.accentColor,
      title: 'Finding useful options…',
      message: 'Building a short list for ${mode.title}.',
      progress: true,
    );
  }
}

class _EmptyResultsState extends StatelessWidget {
  const _EmptyResultsState({required this.mode, required this.onTryAgain});

  final DiscoveryMode mode;
  final VoidCallback onTryAgain;

  @override
  Widget build(BuildContext context) {
    return _StateCard(
      key: ValueKey('mode-results-empty-${mode.id}'),
      icon: Icons.search_off_rounded,
      color: mode.accentColor,
      title: 'No matches yet',
      message: 'Try again or loosen one setup choice.',
      actionLabel: 'Try again',
      onAction: onTryAgain,
    );
  }
}

class _ErrorResultsState extends StatelessWidget {
  const _ErrorResultsState({
    required this.mode,
    required this.error,
    required this.onTryAgain,
  });

  final DiscoveryMode mode;
  final Object error;
  final VoidCallback onTryAgain;

  @override
  Widget build(BuildContext context) {
    return _StateCard(
      key: ValueKey('mode-results-error-${mode.id}'),
      icon: Icons.cloud_off_rounded,
      color: AppColors.danger,
      title: 'Couldn’t load results',
      message: kDebugMode
          ? 'Try again. Debug detail: $error'
          : 'Something went wrong while building this list.',
      actionLabel: 'Try again',
      onAction: onTryAgain,
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    super.key,
    this.actionLabel,
    this.onAction,
    this.progress = false,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadius.largeCard,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          SoftIconBadge(icon: icon, color: color, showShadow: false),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (progress) ...[
            const SizedBox(height: AppSpacing.lg),
            CircularProgressIndicator(color: color),
          ],
          if (actionLabel != null) ...[
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

SavedItem _savedItemForResult(DiscoveryMode mode, ModeResultItem result) {
  final type = switch (mode.queryStrategyType) {
    ModeQueryStrategyType.genericPlanGenerator => SavedItemType.plan,
    ModeQueryStrategyType.routeSearch => SavedItemType.route,
    ModeQueryStrategyType.gameQuest => SavedItemType.quest,
    ModeQueryStrategyType.nearbyPlaces ||
    ModeQueryStrategyType.textSearch ||
    ModeQueryStrategyType.environmental ||
    ModeQueryStrategyType.solar => SavedItemType.place,
  };
  final visual = switch (type) {
    SavedItemType.plan => SavedItemVisual.weekendPlan,
    SavedItemType.place => SavedItemVisual.place,
    SavedItemType.route => SavedItemVisual.roadTrip,
    SavedItemType.quest => SavedItemVisual.localQuest,
  };

  return SavedItem(
    id: result.id,
    type: type,
    categoryLabel: mode.title,
    title: result.title,
    description: result.subtitle,
    savedAt: DateTime.now(),
    status: _isProgressMode(mode)
        ? SavedItemStatus.inProgress
        : SavedItemStatus.saved,
    visual: visual,
    destinationPath: '/modes/${mode.id}/results',
    progressCompleted: _isProgressMode(mode) ? 0 : null,
    progressTotal: _isProgressMode(mode) ? 1 : null,
  );
}

class _MapPreviewPainter extends CustomPainter {
  const _MapPreviewPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppColors.white.withValues(alpha: 0.72)
      ..strokeWidth = 2;
    for (var index = 1; index < 5; index++) {
      final x = size.width * index / 5;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (var index = 1; index < 4; index++) {
      final y = size.height * index / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final routePaint = Paint()
      ..color = color
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final route = Path()
      ..moveTo(size.width * 0.12, size.height * 0.70)
      ..cubicTo(
        size.width * 0.28,
        size.height * 0.30,
        size.width * 0.48,
        size.height * 0.76,
        size.width * 0.66,
        size.height * 0.38,
      )
      ..quadraticBezierTo(
        size.width * 0.78,
        size.height * 0.12,
        size.width * 0.90,
        size.height * 0.32,
      );
    canvas.drawPath(route, routePaint);

    for (final point in [
      Offset(size.width * 0.12, size.height * 0.70),
      Offset(size.width * 0.54, size.height * 0.62),
      Offset(size.width * 0.90, size.height * 0.32),
    ]) {
      canvas.drawCircle(point, 10, Paint()..color = AppColors.white);
      canvas.drawCircle(point, 5, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _MapPreviewPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _UnknownResultsScreen extends StatelessWidget {
  const _UnknownResultsScreen({required this.modeId});

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
              title: 'Results not found',
              subtitle: 'No local catalog entry exists for "$modeId".',
              leading: HeaderIconButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => context.go('/modes'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
