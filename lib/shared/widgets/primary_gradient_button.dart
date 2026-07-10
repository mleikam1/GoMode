import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import 'app_motion.dart';

class PrimaryGradientButton extends StatelessWidget {
  const PrimaryGradientButton({
    required this.label,
    super.key,
    this.icon,
    this.onPressed,
    this.height = 58,
    this.expanded = true,
    this.gradient = AppColors.primaryGradient,
    this.foregroundColor = AppColors.white,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final double height;
  final bool expanded;
  final Gradient gradient;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final content = Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: enabled ? gradient : null,
        color: enabled ? null : AppColors.border,
        borderRadius: AppRadius.chip,
        boxShadow: enabled ? AppShadows.glowBlue : null,
      ),
      child: Row(
        mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, color: foregroundColor, size: 24),
            const SizedBox(width: AppSpacing.xs),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: foregroundColor,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: PressScale(
        enabled: enabled,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: AppRadius.chip,
            onTap: onPressed,
            child: expanded
                ? SizedBox(width: double.infinity, child: content)
                : content,
          ),
        ),
      ),
    );
  }
}
