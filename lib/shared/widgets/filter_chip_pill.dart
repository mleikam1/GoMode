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
    this.compact = false,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;
  final Color color;
  final bool onDark;
  final bool compact;

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

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSpacing.minTouchTarget),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadius.chip,
          onTap: onTap,
          child: Center(
            widthFactor: 1,
            heightFactor: 1,
            child: AnimatedContainer(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 160),
              padding: EdgeInsets.symmetric(
                horizontal: compact ? AppSpacing.xs : AppSpacing.md,
                vertical: compact ? 6 : AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: background,
                borderRadius: AppRadius.chip,
                border: Border.all(color: borderColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: selected ? AppColors.white : color,
                    size: compact ? 17 : 21,
                  ),
                  SizedBox(width: compact ? 4 : AppSpacing.xs),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w800,
                      fontSize: compact ? 12 : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
