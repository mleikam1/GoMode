import 'package:flutter/material.dart';

abstract final class AppRadius {
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 38;
  static const double pill = 999;

  static const card = BorderRadius.all(Radius.circular(lg));
  static const mdBorder = BorderRadius.all(Radius.circular(md));
  static const xlBorder = BorderRadius.all(Radius.circular(xl));
  static const largeCard = BorderRadius.all(Radius.circular(xxl));
  static const heroCard = BorderRadius.all(Radius.circular(xxxl));
  static const chip = BorderRadius.all(Radius.circular(pill));
}
