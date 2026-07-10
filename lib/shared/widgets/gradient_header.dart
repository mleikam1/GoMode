import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import 'soft_icon_badge.dart';

class GradientHeader extends StatelessWidget {
  const GradientHeader({
    required this.title,
    super.key,
    this.subtitle,
    this.locationLabel,
    this.showWordmark = false,
    this.leading,
    this.trailing,
    this.bottom,
    this.compact = false,
    this.dense = false,
  });

  final String title;
  final String? subtitle;
  final String? locationLabel;
  final bool showWordmark;
  final Widget? leading;
  final Widget? trailing;
  final Widget? bottom;
  final bool compact;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppRadius.xxl),
          bottomRight: Radius.circular(AppRadius.xxl),
        ),
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: CustomPaint(painter: _HeaderPainter())),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.headerHorizontal,
                dense
                    ? 10
                    : compact
                    ? AppSpacing.md
                    : AppSpacing.xl,
                AppSpacing.headerHorizontal,
                dense
                    ? 81
                    : compact
                    ? AppSpacing.xl
                    : AppSpacing.xxxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      if (leading != null)
                        leading!
                      else if (showWordmark)
                        _GoModeWordmark(dense: dense),
                      if (leading == null && !showWordmark)
                        const SizedBox.shrink(),
                      const Spacer(),
                      trailing ??
                          const HeaderIconButton(
                            icon: Icons.notifications_none_rounded,
                            showDot: true,
                          ),
                    ],
                  ),
                  if (locationLabel != null) ...[
                    SizedBox(height: dense ? 4 : AppSpacing.sm),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          color: AppColors.white.withValues(alpha: 0.72),
                          size: dense ? 17 : 22,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          locationLabel!,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: AppColors.white.withValues(alpha: 0.72),
                                fontWeight: FontWeight.w700,
                                fontSize: dense ? 13 : null,
                                height: dense ? 1 : null,
                              ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppColors.white.withValues(alpha: 0.72),
                          size: dense ? 20 : null,
                        ),
                      ],
                    ),
                  ],
                  SizedBox(
                    height: dense
                        ? 10
                        : compact
                        ? AppSpacing.lg
                        : AppSpacing.xxl,
                  ),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w900,
                      height: 1.04,
                      fontSize: dense ? 34 : null,
                    ),
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: dense ? 4 : AppSpacing.xs),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.white.withValues(alpha: 0.76),
                        fontWeight: FontWeight.w600,
                        fontSize: dense ? 14.5 : null,
                        height: dense ? 1.2 : null,
                      ),
                    ),
                  ],
                  if (bottom != null) ...[
                    SizedBox(height: dense ? AppSpacing.sm : AppSpacing.xl),
                    bottom!,
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoModeWordmark extends StatelessWidget {
  const _GoModeWordmark({this.dense = false});

  final bool dense;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.displaySmall?.copyWith(
      color: AppColors.white,
      fontWeight: FontWeight.w900,
      height: 1,
      fontSize: dense ? 31 : null,
    );

    return Semantics(
      label: 'GoMode',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Go', style: style),
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) =>
                  AppColors.activeBlueGradient.createShader(bounds),
              child: Text('Mode', style: style),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderPainter extends CustomPainter {
  const _HeaderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final wavePaint = Paint()
      ..color = AppColors.navy700.withValues(alpha: 0.34);
    final wave = Path()
      ..moveTo(size.width * 0.58, size.height * 0.58)
      ..cubicTo(
        size.width * 0.70,
        size.height * 0.46,
        size.width * 0.72,
        size.height * 0.68,
        size.width * 0.82,
        size.height * 0.52,
      )
      ..cubicTo(
        size.width * 0.92,
        size.height * 0.36,
        size.width * 0.95,
        size.height * 0.58,
        size.width,
        size.height * 0.42,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(size.width * 0.58, size.height)
      ..close();
    canvas.drawPath(wave, wavePaint);

    final lowerWavePaint = Paint()
      ..color = AppColors.primaryBlueDark.withValues(alpha: 0.14);
    final lowerWave = Path()
      ..moveTo(0, size.height * 0.88)
      ..cubicTo(
        size.width * 0.18,
        size.height * 0.72,
        size.width * 0.30,
        size.height * 1.04,
        size.width * 0.48,
        size.height * 0.82,
      )
      ..cubicTo(
        size.width * 0.68,
        size.height * 0.60,
        size.width * 0.78,
        size.height * 0.96,
        size.width,
        size.height * 0.74,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(lowerWave, lowerWavePaint);

    final starPaint = Paint()..color = AppColors.white.withValues(alpha: 0.60);
    final stars = <Offset>[
      Offset(size.width * 0.08, size.height * 0.70),
      Offset(size.width * 0.68, size.height * 0.25),
      Offset(size.width * 0.74, size.height * 0.40),
      Offset(size.width * 0.90, size.height * 0.32),
      Offset(size.width * 0.53, size.height * 0.78),
    ];
    for (final star in stars) {
      canvas.drawCircle(star, 1.5, starPaint);
    }

    final sparklePaint = Paint()
      ..color = AppColors.white.withValues(alpha: 0.78);
    final center = Offset(size.width * 0.91, size.height * 0.46);
    canvas.drawLine(
      Offset(center.dx - 7, center.dy),
      Offset(center.dx + 7, center.dy),
      sparklePaint..strokeWidth = 1.4,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - 7),
      Offset(center.dx, center.dy + 7),
      sparklePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
