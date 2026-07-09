import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import 'primary_gradient_button.dart';

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
    return Container(
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
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 360;
                final imageSize = compact ? 118.0 : 148.0;

                return Row(
                  children: [
                    SizedBox(
                      width: imageSize,
                      height: imageSize,
                      child: illustration,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w900,
                                  height: 1.02,
                                ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: AppColors.white.withValues(
                                    alpha: 0.84,
                                  ),
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          PrimaryGradientButton(
                            label: actionLabel,
                            icon: actionIcon,
                            height: 50,
                            expanded: false,
                            foregroundColor: AppColors.primaryBlue,
                            gradient: const LinearGradient(
                              colors: [AppColors.white, AppColors.white],
                            ),
                            onPressed: onPressed,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
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
