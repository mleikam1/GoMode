import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';

class AppSearchBar extends StatelessWidget {
  const AppSearchBar({
    super.key,
    this.controller,
    this.hintText = 'Search modes',
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.onDark = false,
  });

  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final foreground = onDark ? AppColors.white : AppColors.textPrimary;
    final hint = onDark
        ? AppColors.white.withValues(alpha: 0.78)
        : AppColors.textSecondary;

    return TextField(
      controller: controller,
      onChanged: onChanged,
      onTap: onTap,
      readOnly: readOnly,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: foreground,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: hint,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(Icons.search_rounded, color: foreground, size: 26),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        filled: true,
        fillColor: onDark
            ? AppColors.white.withValues(alpha: 0.08)
            : AppColors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          borderSide: BorderSide(
            color: onDark
                ? AppColors.white.withValues(alpha: 0.18)
                : AppColors.border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
        ),
      ),
    );
  }
}
