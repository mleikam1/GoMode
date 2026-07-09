import 'package:flutter/material.dart';

abstract final class AppColors {
  static const navy950 = Color(0xFF02071F);
  static const navy900 = Color(0xFF06113D);
  static const navy800 = Color(0xFF0A2367);
  static const navy700 = Color(0xFF103A91);

  static const primaryBlue = Color(0xFF086CFF);
  static const primaryBlueLight = Color(0xFF27B7FF);
  static const primaryBlueDark = Color(0xFF0038FF);

  static const teal = Color(0xFF15C8BE);
  static const coral = Color(0xFFFF4D83);
  static const amber = Color(0xFFFFA51E);
  static const lavender = Color(0xFF7B5CFF);
  static const green = Color(0xFF35C85A);

  static const white = Color(0xFFFFFFFF);
  static const surface = Color(0xFFF6F8FC);
  static const surfaceRaised = Color(0xFFFFFFFF);
  static const surfaceTint = Color(0xFFEFF4FF);
  static const border = Color(0xFFDCE4F0);
  static const borderStrong = Color(0xFFC7D2E5);

  static const textPrimary = Color(0xFF07113D);
  static const textSecondary = Color(0xFF526181);
  static const textMuted = Color(0xFF7280A0);

  static const success = Color(0xFF11AD86);
  static const warning = Color(0xFFFF9500);
  static const danger = Color(0xFFFF3B5F);

  static const headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [navy950, navy900, navy800],
  );

  static const primaryGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [primaryBlue, primaryBlueDark],
  );

  static const activeBlueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryBlueLight, primaryBlue, primaryBlueDark],
  );

  static const pinkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFF1F6), Color(0xFFFF6F9F)],
  );

  static const tealGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE6FFFB), Color(0xFF44D4CE)],
  );

  static const amberGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFF4D9), Color(0xFFFFB44C)],
  );

  static const lavenderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF0ECFF), Color(0xFF8B6EFF)],
  );

  static const greenGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE8FFE8), Color(0xFF65D96D)],
  );
}
