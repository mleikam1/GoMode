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
import 'mode_visuals.dart';

class ModeResultsScreen extends ConsumerWidget {
  const ModeResultsScreen({required this.modeId, super.key});

  final String modeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(modeCatalogProvider);
    final mode = catalog.findById(modeId);
    final library = ref.watch(savedLibraryProvider);

    if (mode == null) {
      return _UnknownResultsScreen(modeId: modeId);
    }

    return ColoredBox(
      color: AppColors.surface,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: GradientHeader(
              compact: true,
              title: '${mode.title} results',
              subtitle: 'Local demo results using the catalog defaults.',
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
                icon: mode.supportsSaving
                    ? Icons.bookmark_border_rounded
                    : Icons.more_horiz_rounded,
                onTap: mode.supportsSaving ? () => context.go('/saved') : null,
              ),
              bottom: Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final filter in mode.defaultFilters)
                    StatusPill(
                      label: filter.value,
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
                if (mode.supportsMapResults) ...[
                  _MapPreview(mode: mode),
                  const SizedBox(height: AppSpacing.xl),
                ],
                for (var index = 0; index < mode.demoResults.length; index++)
                  Builder(
                    builder: (context) {
                      final item = _savedItemForResult(
                        mode,
                        mode.demoResults[index],
                        index,
                      );
                      final saved = library.maybeWhen(
                        data: (value) => value.contains(item.id),
                        orElse: () => false,
                      );
                      return _ResultStopCard(
                        mode: mode,
                        result: mode.demoResults[index],
                        index: index,
                        saved: saved,
                        onToggleSaved: () async {
                          await ref.read(savedLibraryProvider.future);
                          await ref
                              .read(savedLibraryProvider.notifier)
                              .toggleItem(item);
                        },
                      );
                    },
                  ),
                if (mode.supportsSaving) ...[
                  const SizedBox(height: AppSpacing.md),
                  PrimaryGradientButton(
                    label: 'View saved items',
                    icon: Icons.bookmarks_rounded,
                    onPressed: () => context.go('/saved'),
                  ),
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

class _MapPreview extends StatelessWidget {
  const _MapPreview({required this.mode});

  final DiscoveryMode mode;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 214,
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
                    'Demo route with ${mode.demoResults.length} suggested stops',
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

class _ResultStopCard extends StatelessWidget {
  const _ResultStopCard({
    required this.mode,
    required this.result,
    required this.index,
    required this.saved,
    required this.onToggleSaved,
  });

  final DiscoveryMode mode;
  final ModeDemoResult result;
  final int index;
  final bool saved;
  final VoidCallback onToggleSaved;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 104,
                  height: 104,
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
                        label: 'Stop ${index + 1}',
                        color: mode.accentColor,
                        compact: true,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        result.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        result.distanceLabel,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: ValueKey('save-mode-result-${mode.id}-$index'),
                  tooltip: saved ? 'Remove from saved' : 'Save result',
                  onPressed: onToggleSaved,
                  icon: Icon(
                    saved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    color: saved ? mode.accentColor : AppColors.textMuted,
                  ),
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
          ],
        ),
      ),
    );
  }
}

SavedItem _savedItemForResult(
  DiscoveryMode mode,
  ModeDemoResult result,
  int index,
) {
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
    SavedItemType.plan =>
      mode.id == 'date-night'
          ? SavedItemVisual.dateNight
          : SavedItemVisual.weekendPlan,
    SavedItemType.place => SavedItemVisual.place,
    SavedItemType.route => SavedItemVisual.roadTrip,
    SavedItemType.quest => SavedItemVisual.localQuest,
  };

  return SavedItem(
    id: '${mode.id}-result-$index',
    type: type,
    categoryLabel: mode.title,
    title: result.title,
    description: result.subtitle,
    savedAt: DateTime.now(),
    status: SavedItemStatus.saved,
    visual: visual,
    destinationPath: '/modes/${mode.id}/results',
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
    for (var i = 1; i < 5; i++) {
      final x = size.width * i / 5;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (var i = 1; i < 4; i++) {
      final y = size.height * i / 4;
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

    final pinPaint = Paint()..color = AppColors.white;
    for (final point in [
      Offset(size.width * 0.12, size.height * 0.70),
      Offset(size.width * 0.54, size.height * 0.62),
      Offset(size.width * 0.90, size.height * 0.32),
    ]) {
      canvas.drawCircle(point, 10, pinPaint);
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
