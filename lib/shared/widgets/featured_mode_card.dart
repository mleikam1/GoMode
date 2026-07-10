import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import 'primary_gradient_button.dart';
import 'app_motion.dart';

class FeaturedModeCard extends StatelessWidget {
  const FeaturedModeCard({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.illustration,
    super.key,
    this.onPressed,
    this.actionIcon = Icons.arrow_forward_rounded,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final Widget illustration;
  final VoidCallback? onPressed;
  final IconData actionIcon;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      enabled: onPressed != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: Container(
          decoration: BoxDecoration(
            gradient: AppColors.activeBlueGradient,
            borderRadius: AppRadius.heroCard,
            boxShadow: AppShadows.glowBlue,
          ),
          child: Stack(
            children: [
              const Positioned.fill(
                child: CustomPaint(painter: _FeatureSparkPainter()),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final narrow = constraints.maxWidth < 250;
                    final compact = constraints.maxWidth < 360;
                    final compactHeight = constraints.maxHeight < 170;
                    final imageSize = narrow
                        ? 112.0
                        : compact
                        ? 112.0
                        : 128.0;
                    final titleStyle =
                        (compactHeight
                                ? Theme.of(context).textTheme.titleLarge
                                : narrow
                                ? Theme.of(context).textTheme.headlineSmall
                                : Theme.of(context).textTheme.headlineMedium)
                            ?.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w900,
                              height: 1.02,
                            );
                    final textContent = Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: titleStyle,
                        ),
                        SizedBox(height: compactHeight ? 4 : AppSpacing.xs),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style:
                              (compactHeight
                                      ? Theme.of(context).textTheme.bodyMedium
                                      : Theme.of(context).textTheme.titleMedium)
                                  ?.copyWith(
                                    color: AppColors.white.withValues(
                                      alpha: 0.84,
                                    ),
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        SizedBox(height: compactHeight ? 4 : AppSpacing.xs),
                        PrimaryGradientButton(
                          label: actionLabel,
                          icon: actionIcon,
                          height: 44,
                          expanded: narrow,
                          foregroundColor: AppColors.primaryBlue,
                          gradient: const LinearGradient(
                            colors: [AppColors.white, AppColors.white],
                          ),
                          onPressed: onPressed,
                        ),
                      ],
                    );

                    if (narrow) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: SizedBox(
                              width: imageSize,
                              height: imageSize,
                              child: illustration,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          textContent,
                        ],
                      );
                    }

                    return Row(
                      children: [
                        SizedBox(
                          width: imageSize,
                          height: imageSize,
                          child: illustration,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(child: textContent),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureSparkPainter extends CustomPainter {
  const _FeatureSparkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rayPaint = Paint()..color = AppColors.white.withValues(alpha: 0.05);
    for (var i = 0; i < 9; i++) {
      final path = Path()
        ..moveTo(size.width * 0.15, size.height * 0.60)
        ..lineTo(size.width * (0.20 + i * 0.10), 0)
        ..lineTo(size.width * (0.30 + i * 0.10), 0)
        ..close();
      canvas.drawPath(path, rayPaint);
    }

    final orbPaint = Paint()..color = AppColors.white.withValues(alpha: 0.07);
    canvas.drawCircle(
      Offset(size.width * 0.93, size.height * 0.86),
      size.height * 0.26,
      orbPaint,
    );

    final sparklePaint = Paint()
      ..color = AppColors.white.withValues(alpha: 0.72)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    final sparkle = Offset(size.width * 0.53, size.height * 0.26);
    canvas.drawLine(
      Offset(sparkle.dx - 8, sparkle.dy),
      Offset(sparkle.dx + 8, sparkle.dy),
      sparklePaint,
    );
    canvas.drawLine(
      Offset(sparkle.dx, sparkle.dy - 8),
      Offset(sparkle.dx, sparkle.dy + 8),
      sparklePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
