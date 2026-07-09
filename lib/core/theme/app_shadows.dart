import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppShadows {
  static final soft = <BoxShadow>[
    BoxShadow(
      color: AppColors.navy900.withValues(alpha: 0.08),
      blurRadius: 24,
      offset: const Offset(0, 10),
    ),
  ];

  static final card = <BoxShadow>[
    BoxShadow(
      color: AppColors.navy900.withValues(alpha: 0.10),
      blurRadius: 28,
      offset: const Offset(0, 14),
    ),
  ];

  static final glowBlue = <BoxShadow>[
    BoxShadow(
      color: AppColors.primaryBlue.withValues(alpha: 0.28),
      blurRadius: 28,
      offset: const Offset(0, 12),
    ),
  ];

  static final glowCoral = <BoxShadow>[
    BoxShadow(
      color: AppColors.coral.withValues(alpha: 0.22),
      blurRadius: 24,
      offset: const Offset(0, 10),
    ),
  ];
}
