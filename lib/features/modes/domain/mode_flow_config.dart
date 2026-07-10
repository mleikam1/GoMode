import 'package:flutter/material.dart';

import '../../../data/models/discovery_mode.dart';

class ModeFilterDefinition {
  const ModeFilterDefinition({
    required this.id,
    required this.label,
    required this.icon,
    required this.options,
  });

  final String id;
  final String label;
  final IconData icon;
  final List<String> options;
}

class ModeFlowConfig {
  const ModeFlowConfig({
    required this.ctaLabel,
    required this.ctaIcon,
    required this.filters,
    this.inputLabel,
    this.inputHint,
    this.inputHelper,
    this.caveat,
  });

  final String ctaLabel;
  final IconData ctaIcon;
  final List<ModeFilterDefinition> filters;
  final String? inputLabel;
  final String? inputHint;
  final String? inputHelper;
  final String? caveat;

  bool get requiresInput => inputLabel != null;
}

const _distance = ModeFilterDefinition(
  id: 'distance',
  label: 'Distance',
  icon: Icons.near_me_rounded,
  options: ['2 mi', '5 mi', '10 mi'],
);

const _budget = ModeFilterDefinition(
  id: 'budget',
  label: 'Budget',
  icon: Icons.payments_outlined,
  options: [r'$', r'$$', 'Any'],
);

const _openNow = ModeFilterDefinition(
  id: 'open',
  label: 'Availability',
  icon: Icons.schedule_rounded,
  options: ['Open now', 'Any time'],
);

const _setting = ModeFilterDefinition(
  id: 'setting',
  label: 'Setting',
  icon: Icons.wb_sunny_outlined,
  options: ['Either', 'Indoor', 'Outdoor'],
);

const _family = ModeFilterDefinition(
  id: 'family',
  label: 'Group',
  icon: Icons.family_restroom_rounded,
  options: ['Everyone', 'Family-friendly'],
);

ModeFlowConfig modeFlowConfigFor(DiscoveryMode mode) {
  return switch (mode.id) {
    'weekend-plan' => const ModeFlowConfig(
      ctaLabel: 'Generate Plan',
      ctaIcon: Icons.auto_awesome_rounded,
      filters: [_distance, _budget, _setting, _family],
    ),
    'food-wheel' => const ModeFlowConfig(
      ctaLabel: 'Spin the Wheel',
      ctaIcon: Icons.casino_rounded,
      filters: [_distance, _budget, _openNow],
    ),
    'patio-finder' => const ModeFlowConfig(
      ctaLabel: 'Find Spots',
      ctaIcon: Icons.search_rounded,
      filters: [
        _distance,
        _budget,
        _openNow,
        ModeFilterDefinition(
          id: 'pet',
          label: 'Patio fit',
          icon: Icons.pets_rounded,
          options: ['Any patio', 'Pet-friendly'],
        ),
      ],
    ),
    'cheap-date' => const ModeFlowConfig(
      ctaLabel: 'Generate Plan',
      ctaIcon: Icons.auto_awesome_rounded,
      filters: [_distance, _budget, _setting],
    ),
    'food-challenge' => const ModeFlowConfig(
      ctaLabel: 'Start Quest',
      ctaIcon: Icons.emoji_events_rounded,
      filters: [
        _distance,
        _budget,
        ModeFilterDefinition(
          id: 'rounds',
          label: 'Rounds',
          icon: Icons.format_list_numbered_rounded,
          options: ['2 stops', '3 stops', '4 stops'],
        ),
      ],
    ),
    'kids-bored-button' => const ModeFlowConfig(
      ctaLabel: 'Give Us an Idea',
      ctaIcon: Icons.bolt_rounded,
      filters: [
        _distance,
        _setting,
        ModeFilterDefinition(
          id: 'energy',
          label: 'Energy',
          icon: Icons.directions_run_rounded,
          options: ['Low-key', 'Active', 'Surprise us'],
        ),
      ],
    ),
    'rainy-day-ideas' => const ModeFlowConfig(
      ctaLabel: 'Find Spots',
      ctaIcon: Icons.umbrella_rounded,
      filters: [_distance, _budget, _family],
    ),
    'dog-friendly-spots' => const ModeFlowConfig(
      ctaLabel: 'Find Spots',
      ctaIcon: Icons.pets_rounded,
      filters: [_distance, _budget, _openNow],
      caveat:
          'Pet policies can change. Verify the current policy before you go.',
    ),
    'ev-charge-chill' => const ModeFlowConfig(
      ctaLabel: 'Find Spots',
      ctaIcon: Icons.ev_station_rounded,
      filters: [
        _distance,
        _openNow,
        ModeFilterDefinition(
          id: 'charger',
          label: 'Charger',
          icon: Icons.bolt_rounded,
          options: ['Fast', 'Any speed'],
        ),
        ModeFilterDefinition(
          id: 'activity',
          label: 'While charging',
          icon: Icons.local_cafe_outlined,
          options: ['Coffee', 'Food', 'Park'],
        ),
      ],
    ),
    'road-rescue' => const ModeFlowConfig(
      ctaLabel: 'Find Help',
      ctaIcon: Icons.health_and_safety_rounded,
      filters: [
        _distance,
        _openNow,
        ModeFilterDefinition(
          id: 'need',
          label: 'What do you need?',
          icon: Icons.car_repair_rounded,
          options: ['Gas', 'Restroom', 'Pharmacy', 'Urgent care', 'Mechanic'],
        ),
      ],
      caveat:
          'For a life-threatening emergency, call local emergency services.',
    ),
    'open-now' => const ModeFlowConfig(
      ctaLabel: 'Find Spots',
      ctaIcon: Icons.schedule_rounded,
      filters: [
        _distance,
        _budget,
        ModeFilterDefinition(
          id: 'category',
          label: 'Category',
          icon: Icons.category_outlined,
          options: ['Anything', 'Food', 'Coffee', 'Activities'],
        ),
      ],
    ),
    'allergy-map' => const ModeFlowConfig(
      ctaLabel: 'Check Area',
      ctaIcon: Icons.local_florist_rounded,
      filters: [
        _distance,
        _setting,
        _family,
        ModeFilterDefinition(
          id: 'allergen',
          label: 'Concern',
          icon: Icons.grass_rounded,
          options: ['Pollen', 'Mold', 'General'],
        ),
      ],
    ),
    'clean-air-planner' => const ModeFlowConfig(
      ctaLabel: 'Generate Plan',
      ctaIcon: Icons.air_rounded,
      filters: [_distance, _setting, _family],
    ),
    'solar-checker' => const ModeFlowConfig(
      ctaLabel: 'Check Address',
      ctaIcon: Icons.wb_sunny_rounded,
      filters: [
        ModeFilterDefinition(
          id: 'homeType',
          label: 'Home type',
          icon: Icons.home_outlined,
          options: ['Single-family', 'Townhome', 'Other'],
        ),
        ModeFilterDefinition(
          id: 'shade',
          label: 'Roof shade',
          icon: Icons.park_outlined,
          options: ['Not sure', 'Low', 'Some', 'Heavy'],
        ),
      ],
      inputLabel: 'Property address',
      inputHint: '123 Main Street, Austin, TX',
      inputHelper: 'No solar analysis is performed without a live data source.',
    ),
    'neighborhood-check' => const ModeFlowConfig(
      ctaLabel: 'Check Area',
      ctaIcon: Icons.location_city_rounded,
      filters: [
        _distance,
        ModeFilterDefinition(
          id: 'priority',
          label: 'Top priority',
          icon: Icons.star_outline_rounded,
          options: ['Daily errands', 'Parks', 'Food', 'Transit'],
        ),
      ],
      inputLabel: 'Neighborhood or address',
      inputHint: 'Mueller, Austin',
      inputHelper: 'Choose a place to preview nearby everyday amenities.',
    ),
    'where-should-i-live' => const ModeFlowConfig(
      ctaLabel: 'Find My Match',
      ctaIcon: Icons.home_work_outlined,
      filters: [
        _budget,
        ModeFilterDefinition(
          id: 'lifestyle',
          label: 'Lifestyle',
          icon: Icons.favorite_outline_rounded,
          options: ['Walkable', 'Quiet', 'Social', 'Family-focused'],
        ),
        ModeFilterDefinition(
          id: 'commute',
          label: 'Commute priority',
          icon: Icons.commute_rounded,
          options: ['Low', 'Medium', 'High'],
        ),
        ModeFilterDefinition(
          id: 'space',
          label: 'Space',
          icon: Icons.apartment_rounded,
          options: ['Compact', 'Balanced', 'More room'],
        ),
      ],
    ),
    'local-quest' => const ModeFlowConfig(
      ctaLabel: 'Start Quest',
      ctaIcon: Icons.explore_rounded,
      filters: [
        _distance,
        _family,
        ModeFilterDefinition(
          id: 'duration',
          label: 'Duration',
          icon: Icons.timer_outlined,
          options: ['30 min', '60 min', '90 min'],
        ),
        ModeFilterDefinition(
          id: 'difficulty',
          label: 'Difficulty',
          icon: Icons.flag_outlined,
          options: ['Easy', 'Medium'],
        ),
      ],
    ),
    'tourist-mode' => const ModeFlowConfig(
      ctaLabel: 'Build My Route',
      ctaIcon: Icons.route_rounded,
      filters: [
        _distance,
        _budget,
        ModeFilterDefinition(
          id: 'duration',
          label: 'Duration',
          icon: Icons.timer_outlined,
          options: ['2 hours', 'Half day', 'Full day'],
        ),
        ModeFilterDefinition(
          id: 'style',
          label: 'Style',
          icon: Icons.camera_alt_outlined,
          options: ['Iconic', 'Local', 'Mix'],
        ),
      ],
    ),
    _ => ModeFlowConfig(
      ctaLabel: 'Find Spots',
      ctaIcon: Icons.search_rounded,
      filters: _fallbackFilters(mode),
    ),
  };
}

List<ModeFilterDefinition> _fallbackFilters(DiscoveryMode mode) {
  return [
    for (final filter in mode.defaultFilters.take(5))
      ModeFilterDefinition(
        id: filter.id,
        label: filter.label,
        icon: Icons.tune_rounded,
        options: [filter.value, 'Any'],
      ),
  ];
}
