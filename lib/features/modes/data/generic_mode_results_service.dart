import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/discovery_mode.dart';
import '../../../data/services/mode_catalog.dart';

final genericModeResultsServiceProvider = Provider<GenericModeResultsService>((
  ref,
) {
  return const DemoGenericModeResultsService();
});

final genericModeResultsProvider = FutureProvider.autoDispose
    .family<List<ModeResultItem>, String>((ref, modeId) async {
      final mode = ref.watch(modeCatalogProvider).findById(modeId);
      if (mode == null) {
        throw StateError('Unknown discovery mode: $modeId');
      }
      return ref.watch(genericModeResultsServiceProvider).load(mode);
    });

abstract interface class GenericModeResultsService {
  Future<List<ModeResultItem>> load(DiscoveryMode mode);
}

class ModeResultItem {
  const ModeResultItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.detail,
    required this.distanceLabel,
    required this.imageSemanticName,
    required this.tags,
    this.rating,
    this.openStatus,
  });

  final String id;
  final String title;
  final String subtitle;
  final String detail;
  final String distanceLabel;
  final String imageSemanticName;
  final List<String> tags;
  final double? rating;
  final String? openStatus;
}

class DemoGenericModeResultsService implements GenericModeResultsService {
  const DemoGenericModeResultsService({
    this.delay = const Duration(milliseconds: 320),
  });

  final Duration delay;

  @override
  Future<List<ModeResultItem>> load(DiscoveryMode mode) async {
    await Future<void>.delayed(delay);
    final results = _resultsFor(mode);
    return [
      for (var index = 0; index < results.length; index++)
        _toResultItem(mode, results[index], index),
    ];
  }

  List<ModeDemoResult> _resultsFor(DiscoveryMode mode) {
    return switch (mode.id) {
      'weekend-plan' => _weekendItinerary,
      'ev-charge-chill' => _evChargeResults,
      'road-rescue' => _roadRescueResults,
      'allergy-map' => _allergySuggestions,
      'clean-air-planner' => _cleanAirSuggestions,
      'solar-checker' => _solarLeadResults,
      'where-should-i-live' => _neighborhoodMatches,
      'tourist-mode' => _touristItinerary,
      _ => mode.demoResults,
    };
  }

  ModeResultItem _toResultItem(
    DiscoveryMode mode,
    ModeDemoResult result,
    int index,
  ) {
    final placeLike = switch (mode.queryStrategyType) {
      ModeQueryStrategyType.nearbyPlaces ||
      ModeQueryStrategyType.textSearch ||
      ModeQueryStrategyType.routeSearch => true,
      _ => false,
    };
    return ModeResultItem(
      id: '${mode.id}-result-$index',
      title: result.title,
      subtitle: result.subtitle,
      detail: result.detail,
      distanceLabel: result.distanceLabel,
      imageSemanticName: result.imageSemanticName,
      tags: [
        for (final tag in result.tags)
          if (tag.toLowerCase() == 'open now') 'Hours unverified' else tag,
      ],
      rating: null,
      openStatus: placeLike ? 'Hours unverified' : null,
    );
  }
}

const _weekendItinerary = <ModeDemoResult>[
  ModeDemoResult(
    title: '9:00 AM · Neighborhood Coffee',
    subtitle: 'Easy start with pastries and outdoor tables',
    detail: 'Spend about 45 minutes here before the morning walk.',
    distanceLabel: 'Stop 1 of 5',
    imageSemanticName: 'food',
    tags: ['Coffee', 'Easy start', '45 min'],
  ),
  ModeDemoResult(
    title: '10:00 AM · Greenbelt Walk',
    subtitle: 'A shaded loop with several turnaround points',
    detail: 'Keep it flexible with a short or long route option.',
    distanceLabel: 'Stop 2 of 5',
    imageSemanticName: 'weekend',
    tags: ['Outdoors', 'Shade', '75 min'],
  ),
  ModeDemoResult(
    title: '12:00 PM · Local Taco Lunch',
    subtitle: 'Counter service and a relaxed patio',
    detail: 'A low-wait lunch stop close to the afternoon activities.',
    distanceLabel: 'Stop 3 of 5',
    imageSemanticName: 'food',
    tags: ['Lunch', 'Casual', 'Patio'],
  ),
  ModeDemoResult(
    title: '1:30 PM · Market Browse',
    subtitle: 'Books, local goods, and an optional gallery',
    detail: 'Browse at your own pace or skip ahead if energy is low.',
    distanceLabel: 'Stop 4 of 5',
    imageSemanticName: 'tourist',
    tags: ['Shopping', 'Indoor option', 'Flexible'],
  ),
  ModeDemoResult(
    title: '3:30 PM · Park Treat',
    subtitle: 'Dessert to-go and a shaded park finish',
    detail: 'A calm final stop with room to linger or head home.',
    distanceLabel: 'Stop 5 of 5',
    imageSemanticName: 'weekend',
    tags: ['Dessert', 'Park', 'Easy finish'],
  ),
];

const _evChargeResults = <ModeDemoResult>[
  ModeDemoResult(
    title: 'North Loop Charge + Coffee',
    subtitle: 'Fast charging with a bakery a short walk away',
    detail:
        'Confirm connector compatibility and availability in your charging app.',
    distanceLabel: '1.4 mi',
    imageSemanticName: 'ev',
    tags: ['Fast charge', 'Coffee', 'Walkable'],
  ),
  ModeDemoResult(
    title: 'Civic Center Charge + Park',
    subtitle: 'Charging near restrooms, shade, and a playground',
    detail: 'A family-friendly way to use a longer charging stop.',
    distanceLabel: '3.1 mi',
    imageSemanticName: 'ev',
    tags: ['Park', 'Restrooms', 'Family'],
  ),
  ModeDemoResult(
    title: 'Market Charge + Lunch',
    subtitle: 'Charging with several quick food choices nearby',
    detail: 'Choose a counter-service meal while the vehicle charges.',
    distanceLabel: '4.0 mi',
    imageSemanticName: 'ev',
    tags: ['Food', 'Errands', 'Covered seating'],
  ),
];

const _roadRescueResults = <ModeDemoResult>[
  ModeDemoResult(
    title: 'Closest Fuel Stop',
    subtitle: 'Fuel, air pump, and basic vehicle supplies',
    detail: 'Use Navigate to view the nearest route in the map tab.',
    distanceLabel: '4 min',
    imageSemanticName: 'road-rescue',
    tags: ['Gas', 'Open now', 'Air pump'],
  ),
  ModeDemoResult(
    title: 'Public Restroom Stop',
    subtitle: 'Well-lit travel stop with accessible restrooms',
    detail: 'A quick nearby option when you need a safe break.',
    distanceLabel: '6 min',
    imageSemanticName: 'road-rescue',
    tags: ['Restroom', 'Open now', 'Accessible'],
  ),
  ModeDemoResult(
    title: 'Late Pharmacy',
    subtitle: 'Pharmacy counter and common travel essentials',
    detail: 'Call ahead if you need a specific prescription service.',
    distanceLabel: '8 min',
    imageSemanticName: 'road-rescue',
    tags: ['Pharmacy', 'Open now', 'Supplies'],
  ),
  ModeDemoResult(
    title: 'Walk-In Urgent Care',
    subtitle: 'Nearby non-emergency medical care category',
    detail:
        'Verify hours and insurance; call emergency services for emergencies.',
    distanceLabel: '10 min',
    imageSemanticName: 'road-rescue',
    tags: ['Urgent care', 'Hours unverified', 'Call ahead'],
  ),
  ModeDemoResult(
    title: 'Tire & Mechanic Help',
    subtitle: 'Repair category with towing support nearby',
    detail: 'Call first to confirm service capacity and towing coverage.',
    distanceLabel: '12 min',
    imageSemanticName: 'road-rescue',
    tags: ['Mechanic', 'Tow', 'Call ahead'],
  ),
];

const _allergySuggestions = <ModeDemoResult>[
  ModeDemoResult(
    title: 'Indoor Museum Break',
    subtitle: 'A fully indoor activity with a nearby cafe',
    detail:
        'Use as a lower-exposure option while live pollen data is unavailable.',
    distanceLabel: '1.8 mi',
    imageSemanticName: 'allergy',
    tags: ['Indoor', 'Low exposure', 'Cafe nearby'],
  ),
  ModeDemoResult(
    title: 'Covered Market Wander',
    subtitle: 'Food and small shops under one roof',
    detail: 'A flexible indoor alternative to a longer outdoor plan.',
    distanceLabel: '2.5 mi',
    imageSemanticName: 'allergy',
    tags: ['Indoor', 'Flexible', 'Food'],
  ),
];

const _cleanAirSuggestions = <ModeDemoResult>[
  ModeDemoResult(
    title: 'Indoor Activity Backup',
    subtitle: 'Museum time with coffee and transit nearby',
    detail: 'A lower-exposure fallback when live AQI data is unavailable.',
    distanceLabel: '14 min',
    imageSemanticName: 'air',
    tags: ['Indoor', 'Transit', 'Flexible'],
  ),
  ModeDemoResult(
    title: 'Short Shaded Route',
    subtitle: 'A brief outdoor loop with an indoor backup',
    detail: 'Check current air quality and heat before choosing this option.',
    distanceLabel: '1.2 mi',
    imageSemanticName: 'air',
    tags: ['Shade', 'Short route', 'Verify AQI'],
  ),
];

const _solarLeadResults = <ModeDemoResult>[
  ModeDemoResult(
    title: 'Request a Roof Review',
    subtitle: 'Your address is ready for a future suitability check',
    detail:
        'No roof geometry, shade, production, or savings analysis has been performed.',
    distanceLabel: 'Next step',
    imageSemanticName: 'solar',
    tags: ['Lead preview', 'No estimate', 'Review needed'],
  ),
  ModeDemoResult(
    title: 'Prepare an Installer Conversation',
    subtitle: 'Collect a utility bill and recent roof information',
    detail: 'These details can support a qualified installer assessment later.',
    distanceLabel: 'Checklist',
    imageSemanticName: 'solar',
    tags: ['Utility bill', 'Roof age', 'Installer'],
  ),
];

const _neighborhoodMatches = <ModeDemoResult>[
  ModeDemoResult(
    title: 'Mueller',
    subtitle: 'A match for parks, errands, and planned community energy',
    detail:
        'Explore in person and verify current housing costs and commute times.',
    distanceLabel: 'Match 1',
    imageSemanticName: 'home-life',
    tags: ['Parks', 'Errands', 'Balanced'],
  ),
  ModeDemoResult(
    title: 'North Loop',
    subtitle: 'A match for local shops and a social neighborhood feel',
    detail:
        'Compare actual listings, transit, and daily routes before deciding.',
    distanceLabel: 'Match 2',
    imageSemanticName: 'home-life',
    tags: ['Local shops', 'Social', 'Compact'],
  ),
  ModeDemoResult(
    title: 'South Austin',
    subtitle: 'A match for more space and varied neighborhood options',
    detail:
        'Commutes and amenities vary widely; use this as an exploration lead.',
    distanceLabel: 'Match 3',
    imageSemanticName: 'home-life',
    tags: ['More room', 'Variety', 'Explore'],
  ),
];

const _touristItinerary = <ModeDemoResult>[
  ModeDemoResult(
    title: 'Stop 1 · City Landmark',
    subtitle: 'Start with a recognizable view and an easy photo',
    detail: 'Allow about 35 minutes before walking to the next stop.',
    distanceLabel: '9:00 AM',
    imageSemanticName: 'tourist',
    tags: ['Landmark', 'Photos', 'Walkable'],
  ),
  ModeDemoResult(
    title: 'Stop 2 · Local Coffee',
    subtitle: 'A quick neighborhood drink and pastry break',
    detail: 'Try a local favorite before the late-morning crowds.',
    distanceLabel: '10:00 AM',
    imageSemanticName: 'food',
    tags: ['Coffee', 'Local', '45 min'],
  ),
  ModeDemoResult(
    title: 'Stop 3 · Culture Stop',
    subtitle: 'A museum, gallery, or history stop near lunch',
    detail: 'Choose the indoor option if weather changes.',
    distanceLabel: '11:00 AM',
    imageSemanticName: 'tourist',
    tags: ['Culture', 'Indoor', 'Flexible'],
  ),
  ModeDemoResult(
    title: 'Stop 4 · Signature Lunch',
    subtitle: 'Finish with a classic local meal',
    detail: 'Save the route now and adjust the order as needed.',
    distanceLabel: '1:00 PM',
    imageSemanticName: 'food',
    tags: ['Lunch', 'Classic', 'Final stop'],
  ),
];
