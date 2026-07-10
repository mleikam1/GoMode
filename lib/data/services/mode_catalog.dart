import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/discovery_mode.dart';

final modeCatalogProvider = Provider<ModeCatalog>((ref) {
  return const ModeCatalog();
});

class ModeCatalog {
  const ModeCatalog();

  static const featuredModeIds = <String>[
    'date-night',
    'weekend-plan',
    'road-trip-stops',
    'local-quest',
  ];

  static const discoveryCategories = <ModeCategory>[
    ModeCategory.goOut,
    ModeCategory.familyPets,
    ModeCategory.road,
    ModeCategory.healthOutdoors,
    ModeCategory.homeLife,
  ];

  static const discoveryCategoryModeIds = <ModeCategory, List<String>>{
    ModeCategory.goOut: [
      'food-wheel',
      'patio-finder',
      'food-challenge',
      'date-night',
      'weekend-plan',
      'cheap-date',
      'open-now',
      'tourist-mode',
    ],
    ModeCategory.familyPets: [
      'kids-bored-button',
      'dog-friendly-spots',
      'rainy-day-ideas',
    ],
    ModeCategory.road: ['road-trip-stops', 'ev-charge-chill', 'road-rescue'],
    ModeCategory.healthOutdoors: ['allergy-map', 'clean-air-planner'],
    ModeCategory.homeLife: [
      'solar-checker',
      'neighborhood-check',
      'where-should-i-live',
    ],
  };

  List<DiscoveryMode> get modes => discoveryModes;

  List<ModeCategory> get categories => ModeCategory.values;

  List<DiscoveryMode> get featuredModes => modesByIds(featuredModeIds);

  List<ModeCategory> get latestDiscoveryCategories => discoveryCategories;

  List<DiscoveryMode> latestByCategory(ModeCategory category) {
    final ids = discoveryCategoryModeIds[category];
    if (ids == null) {
      return const [];
    }
    return modesByIds(ids);
  }

  List<DiscoveryMode> get latestDiscoverableModes {
    final ordered = <String, DiscoveryMode>{};
    for (final mode in featuredModes) {
      ordered[mode.id] = mode;
    }
    for (final category in latestDiscoveryCategories) {
      for (final mode in latestByCategory(category)) {
        ordered[mode.id] = mode;
      }
    }
    return ordered.values.toList();
  }

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

  List<DiscoveryMode> modesByIds(List<String> ids) {
    return [for (final id in ids) modeById(id)];
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
      'forest' => Icons.forest_rounded,
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
