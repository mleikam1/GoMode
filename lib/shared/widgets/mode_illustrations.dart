import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';

class DateNightIllustration extends StatelessWidget {
  const DateNightIllustration({super.key, this.borderRadius = AppRadius.card});

  final BorderRadiusGeometry borderRadius;

  @override
  Widget build(BuildContext context) {
    return _IllustrationSurface(
      gradient: AppColors.pinkGradient,
      borderRadius: borderRadius,
      painter: const _DateNightPainter(),
    );
  }
}

class WeekendParkIllustration extends StatelessWidget {
  const WeekendParkIllustration({
    super.key,
    this.borderRadius = AppRadius.card,
  });

  final BorderRadiusGeometry borderRadius;

  @override
  Widget build(BuildContext context) {
    return _IllustrationSurface(
      gradient: AppColors.tealGradient,
      borderRadius: borderRadius,
      painter: const _WeekendParkPainter(),
    );
  }
}

class RoadTripIllustration extends StatelessWidget {
  const RoadTripIllustration({super.key, this.borderRadius = AppRadius.card});

  final BorderRadiusGeometry borderRadius;

  @override
  Widget build(BuildContext context) {
    return _IllustrationSurface(
      gradient: AppColors.lavenderGradient,
      borderRadius: borderRadius,
      painter: const _RoadTripPainter(),
    );
  }
}

class AllergyOutdoorIllustration extends StatelessWidget {
  const AllergyOutdoorIllustration({
    super.key,
    this.borderRadius = AppRadius.card,
  });

  final BorderRadiusGeometry borderRadius;

  @override
  Widget build(BuildContext context) {
    return _IllustrationSurface(
      gradient: AppColors.amberGradient,
      borderRadius: borderRadius,
      painter: const _AllergyOutdoorPainter(),
    );
  }
}

class LocalQuestIllustration extends StatelessWidget {
  const LocalQuestIllustration({super.key, this.borderRadius = AppRadius.card});

  final BorderRadiusGeometry borderRadius;

  @override
  Widget build(BuildContext context) {
    return _IllustrationSurface(
      gradient: AppColors.amberGradient,
      borderRadius: borderRadius,
      painter: const _LocalQuestPainter(),
    );
  }
}

class ModeWheelIllustration extends StatelessWidget {
  const ModeWheelIllustration({super.key, this.borderRadius = AppRadius.card});

  final BorderRadiusGeometry borderRadius;

  @override
  Widget build(BuildContext context) {
    return _IllustrationSurface(
      gradient: AppColors.activeBlueGradient,
      borderRadius: borderRadius,
      painter: const _ModeWheelPainter(),
    );
  }
}

enum SavedPlanThumbnailKind { dateNight, weekendPark, roadTrip, localQuest }

class SavedPlanThumbnail extends StatelessWidget {
  const SavedPlanThumbnail({
    required this.kind,
    super.key,
    this.borderRadius = AppRadius.mdBorder,
  });

  final SavedPlanThumbnailKind kind;
  final BorderRadiusGeometry borderRadius;

  @override
  Widget build(BuildContext context) {
    return switch (kind) {
      SavedPlanThumbnailKind.dateNight => DateNightIllustration(
        borderRadius: borderRadius,
      ),
      SavedPlanThumbnailKind.weekendPark => WeekendParkIllustration(
        borderRadius: borderRadius,
      ),
      SavedPlanThumbnailKind.roadTrip => RoadTripIllustration(
        borderRadius: borderRadius,
      ),
      SavedPlanThumbnailKind.localQuest => LocalQuestIllustration(
        borderRadius: borderRadius,
      ),
    };
  }
}

class _IllustrationSurface extends StatelessWidget {
  const _IllustrationSurface({
    required this.gradient,
    required this.painter,
    required this.borderRadius,
  });

  final Gradient gradient;
  final CustomPainter painter;
  final BorderRadiusGeometry borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: DecoratedBox(
        decoration: BoxDecoration(gradient: gradient),
        child: CustomPaint(painter: painter, child: const SizedBox.expand()),
      ),
    );
  }
}

class _DateNightPainter extends CustomPainter {
  const _DateNightPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final cloudPaint = Paint()..color = AppColors.white.withValues(alpha: 0.38);
    canvas.drawCircle(Offset(w * 0.23, h * 0.22), h * 0.09, cloudPaint);
    canvas.drawCircle(Offset(w * 0.33, h * 0.18), h * 0.12, cloudPaint);
    canvas.drawCircle(Offset(w * 0.77, h * 0.24), h * 0.10, cloudPaint);

    final skylinePaint = Paint()
      ..color = AppColors.coral.withValues(alpha: 0.38);
    for (final building in <Rect>[
      Rect.fromLTWH(w * 0.08, h * 0.44, w * 0.08, h * 0.32),
      Rect.fromLTWH(w * 0.18, h * 0.36, w * 0.10, h * 0.40),
      Rect.fromLTWH(w * 0.32, h * 0.48, w * 0.08, h * 0.28),
      Rect.fromLTWH(w * 0.70, h * 0.34, w * 0.12, h * 0.42),
      Rect.fromLTWH(w * 0.84, h * 0.42, w * 0.08, h * 0.34),
    ]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(building, const Radius.circular(4)),
        skylinePaint,
      );
    }

    final bridgePaint = Paint()
      ..color = AppColors.coral.withValues(alpha: 0.52)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final bridge = Path()
      ..moveTo(w * 0.05, h * 0.58)
      ..cubicTo(w * 0.30, h * 0.42, w * 0.55, h * 0.72, w * 0.95, h * 0.52);
    canvas.drawPath(bridge, bridgePaint);

    final lightPaint = Paint()..color = AppColors.white.withValues(alpha: 0.90);
    for (var i = 0; i < 7; i++) {
      final t = i / 6;
      final x = w * (0.12 + t * 0.74);
      final y = h * (0.54 + math.sin(t * math.pi * 2) * 0.05);
      canvas.drawCircle(Offset(x, y), 3, lightPaint);
    }

    final hillPaint = Paint()..color = AppColors.coral.withValues(alpha: 0.55);
    canvas.drawPath(
      Path()
        ..moveTo(0, h * 0.72)
        ..quadraticBezierTo(w * 0.25, h * 0.58, w * 0.50, h * 0.74)
        ..quadraticBezierTo(w * 0.72, h * 0.88, w, h * 0.68)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close(),
      hillPaint,
    );

    final tablePaint = Paint()
      ..color = AppColors.navy900.withValues(alpha: 0.30);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.62, h * 0.80),
        width: w * 0.32,
        height: h * 0.08,
      ),
      tablePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.46, h * 0.80, w * 0.32, h * 0.12),
        const Radius.circular(12),
      ),
      Paint()..color = AppColors.coral.withValues(alpha: 0.58),
    );

    final glassPaint = Paint()
      ..color = AppColors.white.withValues(alpha: 0.86)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    _drawGlass(canvas, Offset(w * 0.55, h * 0.71), h * 0.16, glassPaint);
    _drawGlass(canvas, Offset(w * 0.70, h * 0.71), h * 0.16, glassPaint);

    final heartPaint = Paint()..color = AppColors.coral;
    canvas.drawCircle(Offset(w * 0.18, h * 0.22), h * 0.035, heartPaint);
    canvas.drawCircle(Offset(w * 0.24, h * 0.22), h * 0.035, heartPaint);
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.14, h * 0.24)
        ..quadraticBezierTo(w * 0.21, h * 0.33, w * 0.28, h * 0.24)
        ..lineTo(w * 0.21, h * 0.34)
        ..close(),
      heartPaint,
    );
  }

  void _drawGlass(Canvas canvas, Offset top, double height, Paint paint) {
    final path = Path()
      ..moveTo(top.dx - height * 0.12, top.dy)
      ..lineTo(top.dx + height * 0.12, top.dy)
      ..lineTo(top.dx + height * 0.07, top.dy + height * 0.28)
      ..quadraticBezierTo(
        top.dx,
        top.dy + height * 0.34,
        top.dx - height * 0.07,
        top.dy + height * 0.28,
      )
      ..close();
    canvas.drawPath(path, paint);
    canvas.drawLine(
      Offset(top.dx, top.dy + height * 0.33),
      Offset(top.dx, top.dy + height * 0.58),
      paint,
    );
    canvas.drawLine(
      Offset(top.dx - height * 0.10, top.dy + height * 0.58),
      Offset(top.dx + height * 0.10, top.dy + height * 0.58),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WeekendParkPainter extends CustomPainter {
  const _WeekendParkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final skyPaint = Paint()..color = AppColors.white.withValues(alpha: 0.36);
    canvas.drawCircle(Offset(w * 0.78, h * 0.18), h * 0.12, skyPaint);
    canvas.drawCircle(Offset(w * 0.88, h * 0.21), h * 0.09, skyPaint);

    final skylinePaint = Paint()
      ..color = AppColors.primaryBlue.withValues(alpha: 0.22);
    for (var i = 0; i < 6; i++) {
      final x = w * (0.36 + i * 0.07);
      final height = h * (0.20 + (i.isEven ? 0.10 : 0.04));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, h * 0.42 - height, w * 0.045, height),
          const Radius.circular(3),
        ),
        skylinePaint,
      );
    }

    final waterPaint = Paint()..color = AppColors.teal.withValues(alpha: 0.36);
    canvas.drawPath(
      Path()
        ..moveTo(0, h * 0.62)
        ..quadraticBezierTo(w * 0.30, h * 0.54, w * 0.56, h * 0.66)
        ..quadraticBezierTo(w * 0.78, h * 0.76, w, h * 0.60)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close(),
      waterPaint,
    );

    final treePaint = Paint()..color = AppColors.teal;
    for (final center in <Offset>[
      Offset(w * 0.13, h * 0.56),
      Offset(w * 0.19, h * 0.48),
      Offset(w * 0.87, h * 0.54),
      Offset(w * 0.78, h * 0.50),
    ]) {
      canvas.drawCircle(center, h * 0.10, treePaint);
    }
    final trunkPaint = Paint()
      ..color = AppColors.navy800.withValues(alpha: 0.45);
    canvas.drawRect(Rect.fromLTWH(w * 0.18, h * 0.55, 6, h * 0.22), trunkPaint);
    canvas.drawRect(Rect.fromLTWH(w * 0.80, h * 0.57, 6, h * 0.20), trunkPaint);

    final benchPaint = Paint()
      ..color = AppColors.navy800.withValues(alpha: 0.72)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5;
    canvas.drawLine(
      Offset(w * 0.36, h * 0.70),
      Offset(w * 0.67, h * 0.70),
      benchPaint,
    );
    canvas.drawLine(
      Offset(w * 0.39, h * 0.76),
      Offset(w * 0.64, h * 0.76),
      benchPaint,
    );
    canvas.drawLine(
      Offset(w * 0.42, h * 0.77),
      Offset(w * 0.38, h * 0.90),
      benchPaint,
    );
    canvas.drawLine(
      Offset(w * 0.62, h * 0.77),
      Offset(w * 0.66, h * 0.90),
      benchPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RoadTripPainter extends CustomPainter {
  const _RoadTripPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final cloudPaint = Paint()..color = AppColors.white.withValues(alpha: 0.40);
    canvas.drawCircle(Offset(w * 0.18, h * 0.18), h * 0.08, cloudPaint);
    canvas.drawCircle(Offset(w * 0.28, h * 0.15), h * 0.10, cloudPaint);
    canvas.drawCircle(Offset(w * 0.75, h * 0.17), h * 0.08, cloudPaint);

    final mountainBack = Paint()
      ..color = AppColors.primaryBlue.withValues(alpha: 0.28);
    final mountainFront = Paint()
      ..color = AppColors.lavender.withValues(alpha: 0.48);
    canvas.drawPath(
      Path()
        ..moveTo(0, h * 0.58)
        ..lineTo(w * 0.20, h * 0.30)
        ..lineTo(w * 0.42, h * 0.58)
        ..lineTo(w * 0.60, h * 0.34)
        ..lineTo(w * 0.88, h * 0.58)
        ..lineTo(w, h * 0.48)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close(),
      mountainBack,
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, h * 0.70)
        ..lineTo(w * 0.26, h * 0.42)
        ..lineTo(w * 0.48, h * 0.68)
        ..lineTo(w * 0.72, h * 0.38)
        ..lineTo(w, h * 0.70)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close(),
      mountainFront,
    );

    final lakePaint = Paint()
      ..color = AppColors.primaryBlueLight.withValues(alpha: 0.60);
    canvas.drawPath(
      Path()
        ..moveTo(0, h * 0.70)
        ..quadraticBezierTo(w * 0.26, h * 0.63, w * 0.48, h * 0.72)
        ..quadraticBezierTo(w * 0.68, h * 0.80, w, h * 0.66)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close(),
      lakePaint,
    );

    final roadPaint = Paint()
      ..color = AppColors.navy800.withValues(alpha: 0.74);
    final road = Path()
      ..moveTo(w * 0.40, h)
      ..cubicTo(w * 0.48, h * 0.78, w * 0.70, h * 0.70, w * 0.64, h * 0.48)
      ..lineTo(w * 0.76, h * 0.48)
      ..cubicTo(w * 0.88, h * 0.72, w * 0.70, h * 0.82, w * 0.62, h)
      ..close();
    canvas.drawPath(road, roadPaint);

    final stripePaint = Paint()
      ..color = AppColors.amber
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(w * 0.58, h * 0.90),
      Offset(w * 0.62, h * 0.78),
      stripePaint,
    );
    canvas.drawLine(
      Offset(w * 0.65, h * 0.68),
      Offset(w * 0.67, h * 0.60),
      stripePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AllergyOutdoorPainter extends CustomPainter {
  const _AllergyOutdoorPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final hillPaint = Paint()..color = AppColors.amber.withValues(alpha: 0.28);
    canvas.drawPath(
      Path()
        ..moveTo(0, h * 0.62)
        ..quadraticBezierTo(w * 0.30, h * 0.42, w * 0.56, h * 0.62)
        ..quadraticBezierTo(w * 0.78, h * 0.76, w, h * 0.56)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close(),
      hillPaint,
    );

    final pathPaint = Paint()
      ..color = AppColors.white.withValues(alpha: 0.65)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.08, h * 0.86)
        ..quadraticBezierTo(w * 0.28, h * 0.72, w * 0.46, h * 0.82)
        ..quadraticBezierTo(w * 0.62, h * 0.92, w * 0.82, h * 0.70),
      pathPaint,
    );

    final stemPaint = Paint()
      ..color = AppColors.amber
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final flowerPaint = Paint()..color = AppColors.warning;
    for (final x in <double>[w * 0.18, w * 0.30, w * 0.78]) {
      canvas.drawLine(Offset(x, h * 0.76), Offset(x, h * 0.48), stemPaint);
      for (var i = 0; i < 6; i++) {
        final angle = math.pi * 2 * i / 6;
        canvas.drawCircle(
          Offset(x + math.cos(angle) * 13, h * 0.46 + math.sin(angle) * 13),
          7,
          flowerPaint,
        );
      }
      canvas.drawCircle(
        Offset(x, h * 0.46),
        6,
        Paint()..color = AppColors.white,
      );
    }

    _drawMapPin(
      canvas,
      Offset(w * 0.58, h * 0.50),
      h * 0.20,
      AppColors.warning,
    );
  }

  void _drawMapPin(Canvas canvas, Offset center, double size, Color color) {
    final pinPaint = Paint()..color = color;
    final path = Path()
      ..moveTo(center.dx, center.dy + size * 0.58)
      ..cubicTo(
        center.dx - size * 0.42,
        center.dy + size * 0.06,
        center.dx - size * 0.36,
        center.dy - size * 0.34,
        center.dx,
        center.dy - size * 0.34,
      )
      ..cubicTo(
        center.dx + size * 0.36,
        center.dy - size * 0.34,
        center.dx + size * 0.42,
        center.dy + size * 0.06,
        center.dx,
        center.dy + size * 0.58,
      )
      ..close();
    canvas.drawPath(path, pinPaint);
    canvas.drawCircle(center, size * 0.12, Paint()..color = AppColors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LocalQuestPainter extends CustomPainter {
  const _LocalQuestPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final hillPaint = Paint()
      ..color = AppColors.warning.withValues(alpha: 0.22);
    canvas.drawPath(
      Path()
        ..moveTo(0, h * 0.66)
        ..quadraticBezierTo(w * 0.28, h * 0.46, w * 0.50, h * 0.64)
        ..quadraticBezierTo(w * 0.76, h * 0.84, w, h * 0.58)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close(),
      hillPaint,
    );

    final routePaint = Paint()
      ..color = AppColors.white.withValues(alpha: 0.72)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.10, h * 0.80)
        ..cubicTo(w * 0.24, h * 0.58, w * 0.42, h * 0.88, w * 0.54, h * 0.66)
        ..cubicTo(w * 0.68, h * 0.42, w * 0.82, h * 0.66, w * 0.92, h * 0.48),
      routePaint,
    );

    final pinPaint = Paint()..color = AppColors.warning;
    final center = Offset(w * 0.52, h * 0.45);
    final radius = h * 0.18;
    final pin = Path()
      ..moveTo(center.dx, center.dy + radius)
      ..cubicTo(
        center.dx - radius,
        center.dy - radius * 0.12,
        center.dx - radius * 0.58,
        center.dy - radius,
        center.dx,
        center.dy - radius,
      )
      ..cubicTo(
        center.dx + radius * 0.58,
        center.dy - radius,
        center.dx + radius,
        center.dy - radius * 0.12,
        center.dx,
        center.dy + radius,
      )
      ..close();
    canvas.drawPath(pin, pinPaint);

    final star = Path();
    for (var i = 0; i < 10; i++) {
      final angle = -math.pi / 2 + i * math.pi / 5;
      final r = i.isEven ? radius * 0.34 : radius * 0.16;
      final point = Offset(
        center.dx + math.cos(angle) * r,
        center.dy + math.sin(angle) * r,
      );
      if (i == 0) {
        star.moveTo(point.dx, point.dy);
      } else {
        star.lineTo(point.dx, point.dy);
      }
    }
    star.close();
    canvas.drawPath(star, Paint()..color = AppColors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ModeWheelPainter extends CustomPainter {
  const _ModeWheelPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w * 0.40, h * 0.54);
    final radius = math.min(w, h) * 0.34;

    final rayPaint = Paint()..color = AppColors.white.withValues(alpha: 0.08);
    for (var i = 0; i < 14; i++) {
      final start = -math.pi + i * math.pi / 7;
      final ray = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(
          Rect.fromCircle(center: center, radius: radius * 2.4),
          start,
          math.pi / 18,
          false,
        )
        ..close();
      canvas.drawPath(ray, rayPaint);
    }

    final basePaint = Paint()..color = AppColors.white;
    canvas.drawCircle(center, radius * 1.08, basePaint);
    canvas.drawCircle(center, radius, Paint()..color = AppColors.navy900);

    final colors = <Color>[
      AppColors.teal,
      AppColors.coral,
      AppColors.lavender,
      AppColors.amber,
      AppColors.primaryBlueLight,
      AppColors.green,
    ];
    for (var i = 0; i < colors.length; i++) {
      final segmentPaint = Paint()..color = colors[i];
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius * 0.92),
        -math.pi / 2 + i * math.pi / 3,
        math.pi / 3,
        true,
        segmentPaint,
      );
    }

    final dividerPaint = Paint()
      ..color = AppColors.navy900.withValues(alpha: 0.44)
      ..strokeWidth = 2;
    for (var i = 0; i < colors.length; i++) {
      final angle = -math.pi / 2 + i * math.pi / 3;
      canvas.drawLine(
        center,
        Offset(
          center.dx + math.cos(angle) * radius,
          center.dy + math.sin(angle) * radius,
        ),
        dividerPaint,
      );
    }

    canvas.drawCircle(center, radius * 0.26, Paint()..color = AppColors.white);
    canvas.drawCircle(
      center,
      radius * 0.15,
      Paint()..color = AppColors.navy800,
    );

    final pointer = Path()
      ..moveTo(center.dx, center.dy - radius * 1.22)
      ..lineTo(center.dx - radius * 0.16, center.dy - radius * 0.90)
      ..lineTo(center.dx + radius * 0.16, center.dy - radius * 0.90)
      ..close();
    canvas.drawPath(pointer, Paint()..color = AppColors.amber);

    final sparklePaint = Paint()
      ..color = AppColors.white.withValues(alpha: 0.75)
      ..strokeWidth = 2;
    final sparkle = Offset(w * 0.82, h * 0.28);
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
