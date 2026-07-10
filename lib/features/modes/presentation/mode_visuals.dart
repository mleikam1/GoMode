import 'package:flutter/widgets.dart';

import '../../../core/theme/app_radius.dart';
import '../../../data/models/discovery_mode.dart';
import '../../../shared/widgets/shared_widgets.dart';

Widget modeIllustrationFor(
  DiscoveryMode mode, {
  BorderRadiusGeometry borderRadius = AppRadius.card,
}) {
  final semanticName = mode.demoResults.isEmpty
      ? mode.iconSemanticName
      : mode.demoResults.first.imageSemanticName;
  return demoIllustrationFor(semanticName, borderRadius: borderRadius);
}

Widget demoIllustrationFor(
  String semanticName, {
  BorderRadiusGeometry borderRadius = AppRadius.card,
}) {
  return switch (semanticName) {
    'date-night' => DateNightIllustration(borderRadius: borderRadius),
    'road-trip' ||
    'ev' ||
    'road-rescue' => RoadTripIllustration(borderRadius: borderRadius),
    'allergy' ||
    'air' ||
    'solar' => AllergyOutdoorIllustration(borderRadius: borderRadius),
    'quest' ||
    'tourist' ||
    'home-life' => LocalQuestIllustration(borderRadius: borderRadius),
    'food' => ModeWheelIllustration(borderRadius: borderRadius),
    _ => WeekendParkIllustration(borderRadius: borderRadius),
  };
}
