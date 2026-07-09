import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';

class FilterChipPill extends StatelessWidget {
  const FilterChipPill({
    required this.label,
    required this.icon,
    super.key,
    this.selected = false,
    this.onTap,
    this.color = AppColors.primaryBlue,
    this.onDark = false,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;
  final Color color;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final foreground = selected
        ? AppColors.white
        : onDark
        ? AppColors.white
        : AppColors.textPrimary;
    final background = selected
        ? color
        : onDark
        ? AppColors.white.withValues(alpha: 0.08)
        : AppColors.white;
    final borderColor = selected
        ? color
        : onDark
        ? AppColors.white.withValues(alpha: 0.18)
        : AppColors.border;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.chip,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: background,
            borderRadius: AppRadius.chip,
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: selected ? AppColors.white : color, size: 21),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
