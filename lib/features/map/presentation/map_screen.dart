import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/services/mode_catalog.dart';
import '../../../shared/widgets/shared_widgets.dart';

class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(modeCatalogProvider);
    final modes = catalog.mapModes.take(8).toList();

    return ColoredBox(
      color: AppColors.surface,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: GradientHeader(
              compact: true,
              title: 'Map',
              subtitle: kDebugMode
                  ? 'Nearby ideas from the local demo catalog.'
                  : 'Explore saved and suggested places nearby.',
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.page),
            sliver: SliverList.list(
              children: [
                const _MapCanvas(),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Map-ready modes',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: AppSpacing.sm),
                for (final mode in modes) ...[
                  CompactModeCard(
                    title: mode.title,
                    subtitle: mode.shortSubtitle,
                    icon: ModeCatalog.iconFor(mode.iconSemanticName),
                    accentColor: mode.accentColor,
                    width: double.infinity,
                    onTap: () => context.go('/modes/${mode.id}/results'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
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

class _MapCanvas extends StatelessWidget {
  const _MapCanvas();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 420,
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadius.heroCard,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: ClipRRect(
        borderRadius: AppRadius.heroCard,
        child: Stack(
          children: [
            const Positioned.fill(child: CustomPaint(painter: _MapPainter())),
            Positioned(
              top: AppSpacing.md,
              left: AppSpacing.md,
              right: AppSpacing.md,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: AppRadius.chip,
                        boxShadow: AppShadows.soft,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            color: AppColors.primaryBlue,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              'Austin, TX',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Material(
                    color: AppColors.white,
                    shape: const CircleBorder(),
                    child: IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.my_location_rounded),
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: AppSpacing.md,
              right: AppSpacing.md,
              bottom: AppSpacing.md,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: AppRadius.largeCard,
                  boxShadow: AppShadows.card,
                ),
                child: Row(
                  children: [
                    const SoftIconBadge(
                      icon: Icons.auto_awesome_rounded,
                      color: AppColors.coral,
                      showShadow: false,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            kDebugMode
                                ? '12 demo ideas nearby'
                                : 'Nearby ideas',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Date Night, Patio Finder, and Road Trip Stops are active.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  const _MapPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()..color = const Color(0xFFEFF4FF);
    canvas.drawRect(Offset.zero & size, background);

    final parkPaint = Paint()..color = AppColors.green.withValues(alpha: 0.18);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.28, size.height * 0.34),
        width: size.width * 0.48,
        height: size.height * 0.30,
      ),
      parkPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.76, size.height * 0.70),
        width: size.width * 0.42,
        height: size.height * 0.26,
      ),
      parkPaint,
    );

    final roadPaint = Paint()
      ..color = AppColors.white
      ..strokeWidth = 24
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final roadLinePaint = Paint()
      ..color = AppColors.borderStrong
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final roads = [
      Path()
        ..moveTo(-20, size.height * 0.22)
        ..cubicTo(
          size.width * 0.24,
          size.height * 0.12,
          size.width * 0.44,
          size.height * 0.48,
          size.width + 20,
          size.height * 0.36,
        ),
      Path()
        ..moveTo(size.width * 0.12, size.height + 20)
        ..cubicTo(
          size.width * 0.30,
          size.height * 0.72,
          size.width * 0.42,
          size.height * 0.34,
          size.width * 0.66,
          -20,
        ),
      Path()
        ..moveTo(-10, size.height * 0.80)
        ..quadraticBezierTo(
          size.width * 0.46,
          size.height * 0.62,
          size.width + 10,
          size.height * 0.88,
        ),
    ];

    for (final road in roads) {
      canvas.drawPath(road, roadPaint);
      canvas.drawPath(road, roadLinePaint);
    }

    final pins = [
      (Offset(size.width * 0.33, size.height * 0.50), AppColors.coral),
      (Offset(size.width * 0.56, size.height * 0.32), AppColors.teal),
      (Offset(size.width * 0.72, size.height * 0.58), AppColors.lavender),
      (Offset(size.width * 0.45, size.height * 0.76), AppColors.amber),
    ];

    for (final pin in pins) {
      canvas.drawCircle(pin.$1, 17, Paint()..color = AppColors.white);
      canvas.drawCircle(pin.$1, 10, Paint()..color = pin.$2);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
