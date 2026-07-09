import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'bottom_nav_shell.dart';

class GoModeScaffold extends StatelessWidget {
  const GoModeScaffold({
    required this.body,
    super.key,
    this.currentIndex = 0,
    this.onDestinationSelected,
    this.backgroundColor = AppColors.surface,
  });

  final Widget body;
  final int currentIndex;
  final ValueChanged<int>? onDestinationSelected;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return BottomNavShell(
      currentIndex: currentIndex,
      onDestinationSelected: onDestinationSelected,
      child: ColoredBox(color: backgroundColor, child: body),
    );
  }
}
