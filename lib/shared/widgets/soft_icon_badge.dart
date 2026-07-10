import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';

class SoftIconBadge extends StatelessWidget {
  const SoftIconBadge({
    required this.icon,
    required this.color,
    super.key,
    this.backgroundColor,
    this.size = 54,
    this.iconSize = 28,
    this.showShadow = true,
  });

  final IconData icon;
  final Color color;
  final Color? backgroundColor;
  final double size;
  final double iconSize;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: showShadow ? AppShadows.soft : null,
      ),
      child: Icon(icon, color: color, size: iconSize),
    );
  }
}

class HeaderIconButton extends StatelessWidget {
  const HeaderIconButton({
    required this.icon,
    super.key,
    this.onTap,
    this.showDot = false,
    this.size = 44,
    this.iconSize = 22,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool showDot;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: AppColors.white.withValues(alpha: 0.10),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.white.withValues(alpha: 0.16),
                ),
              ),
              child: Icon(icon, color: AppColors.white, size: iconSize),
            ),
          ),
        ),
        if (showDot)
          Positioned(
            top: size <= 46 ? 1 : 4,
            right: size <= 46 ? 0 : 2,
            child: Container(
              width: size <= 46 ? 10 : 13,
              height: size <= 46 ? 10 : 13,
              decoration: BoxDecoration(
                color: AppColors.coral,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.navy900, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}
