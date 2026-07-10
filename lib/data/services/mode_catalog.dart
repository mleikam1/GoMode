import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/discovery_mode.dart';

final modeCatalogProvider = Provider<ModeCatalog>((ref) {
  return const ModeCatalog();
});

class ModeCatalog {
  const ModeCatalog();

  List<DiscoveryMode> get modes => discoveryModes;

  List<ModeCategory> get categories => ModeCategory.values;

  List<DiscoveryMode> byCategory(ModeCategory category) {
    return modes.where((mode) => mode.category == category).toList();
  }

  DiscoveryMode? findById(String id) {
    for (final mode in modes) {
      if (mode.id == id) {
        return mode;
      }
    }
    return null;
  }

  DiscoveryMode modeById(String id) {
    final mode = findById(id);
    if (mode == null) {
      throw StateError('Unknown discovery mode: $id');
    }
    return mode;
  }

  List<DiscoveryMode> get savingModes {
    return modes.where((mode) => mode.supportsSaving).toList();
  }

  List<DiscoveryMode> get mapModes {
    return modes.where((mode) => mode.supportsMapResults).toList();
  }

  static IconData iconFor(String semanticName) {
    return switch (semanticName) {
      'air' => Icons.air_rounded,
      'calendar' => Icons.calendar_month_rounded,
      'camera_alt' => Icons.camera_alt_rounded,
      'car_repair' => Icons.car_repair_rounded,
      'deck' => Icons.deck_rounded,
      'directions_car' => Icons.directions_car_rounded,
      'emoji_events' => Icons.emoji_events_rounded,
      'ev_station' => Icons.ev_station_rounded,
      'explore' => Icons.explore_rounded,
      'family_restroom' => Icons.family_restroom_rounded,
      'favorite' => Icons.favorite_rounded,
      'home_work' => Icons.home_work_rounded,
      'local_florist' => Icons.local_florist_rounded,
      'location_city' => Icons.location_city_rounded,
      'lunch_dining' => Icons.lunch_dining_rounded,
      'pets' => Icons.pets_rounded,
      'savings' => Icons.savings_rounded,
      'schedule' => Icons.schedule_rounded,
      'umbrella' => Icons.umbrella_rounded,
      'wb_sunny' => Icons.wb_sunny_rounded,
      _ => Icons.auto_awesome_rounded,
    };
  }
}

extension ModeQueryStrategyLabel on ModeQueryStrategyType {
  String get label {
    return switch (this) {
      ModeQueryStrategyType.nearbyPlaces => 'Nearby places',
      ModeQueryStrategyType.textSearch => 'Text search',
      ModeQueryStrategyType.routeSearch => 'Route search',
      ModeQueryStrategyType.environmental => 'Environmental',
      ModeQueryStrategyType.solar => 'Solar',
      ModeQueryStrategyType.gameQuest => 'Game / quest',
      ModeQueryStrategyType.genericPlanGenerator => 'Plan generator',
    };
  }
}
