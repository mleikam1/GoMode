import 'package:flutter/material.dart';

abstract final class AppBreakpoints {
  static const double compactPhone = 390;
  static const double tablet = 600;
  static const double desktop = 900;

  static const double readableContent = 840;
  static const double focusedContent = 720;
}

class ResponsiveContent extends StatelessWidget {
  const ResponsiveContent({
    required this.child,
    super.key,
    this.maxWidth = AppBreakpoints.readableContent,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final double maxWidth;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
