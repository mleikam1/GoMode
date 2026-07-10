import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/backend_models.dart';
import '../../../data/models/discovery_mode.dart';
import '../../../data/repositories/environment_repository.dart';
import '../../../data/repositories/places_repository.dart';
import '../../../data/repositories/solar_repository.dart';
import '../../../data/services/mode_catalog.dart';
import '../../../services/location_service.dart';

final genericModeResultsServiceProvider = Provider<GenericModeResultsService>((
  ref,
) {
  return BackendGenericModeResultsService(
    places: ref.watch(placesRepositoryProvider),
    environment: ref.watch(environmentRepositoryProvider),
    solar: ref.watch(solarRepositoryProvider),
    location: ref.watch(locationServiceProvider),
  );
});

final genericModeResultsProvider = FutureProvider.autoDispose
    .family<List<ModeResultItem>, ModeResultsRequest>((ref, request) async {
      final mode = ref.watch(modeCatalogProvider).findById(request.modeId);
      if (mode == null) {
        throw StateError('Unknown discovery mode: ${request.modeId}');
      }
      final service = ref.watch(genericModeResultsServiceProvider);
      if (service is FilterAwareGenericModeResultsService) {
        return service.loadWithFilters(mode, request.filters);
      }
      return service.load(mode);
    });

class ModeResultsRequest {
  ModeResultsRequest({
    required this.modeId,
    Map<String, String> filters = const {},
  }) : filters = Map.unmodifiable(filters);

  final String modeId;
  final Map<String, String> filters;

  @override
  bool operator ==(Object other) {
    if (other is! ModeResultsRequest ||
        modeId != other.modeId ||
        filters.length != other.filters.length) {
      return false;
    }
    return filters.entries.every(
      (entry) => other.filters[entry.key] == entry.value,
    );
  }

  @override
  int get hashCode {
    final entries = filters.entries.toList()
      ..sort((left, right) => left.key.compareTo(right.key));
    return Object.hash(
      modeId,
      Object.hashAll(
        entries.map((entry) => Object.hash(entry.key, entry.value)),
      ),
    );
  }
}

abstract interface class GenericModeResultsService {
  Future<List<ModeResultItem>> load(DiscoveryMode mode);
}

abstract interface class FilterAwareGenericModeResultsService
    implements GenericModeResultsService {
  Future<List<ModeResultItem>> loadWithFilters(
    DiscoveryMode mode,
    Map<String, String> filters,
  );
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
    this.isDemo = false,
    this.fallbackMessage,
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
  final bool isDemo;
  final String? fallbackMessage;
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
      isDemo: true,
    );
  }
}

class BackendGenericModeResultsService
    implements FilterAwareGenericModeResultsService {
  BackendGenericModeResultsService({
    required PlacesRepository places,
    required EnvironmentRepository environment,
    required SolarRepository solar,
    required LocationService location,
    DemoGenericModeResultsService demo = const DemoGenericModeResultsService(),
  }) : this._(places, environment, solar, location, demo);

  BackendGenericModeResultsService._(
    this._places,
    this._environment,
    this._solar,
    this._location,
    this._demo,
  );

  final PlacesRepository _places;
  final EnvironmentRepository _environment;
  final SolarRepository _solar;
  final LocationService _location;
  final DemoGenericModeResultsService _demo;

  @override
  Future<List<ModeResultItem>> load(DiscoveryMode mode) {
    return loadWithFilters(mode, const {});
  }

  @override
  Future<List<ModeResultItem>> loadWithFilters(
    DiscoveryMode mode,
    Map<String, String> filters,
  ) async {
    return switch (mode.queryStrategyType) {
      ModeQueryStrategyType.nearbyPlaces ||
      ModeQueryStrategyType.textSearch ||
      ModeQueryStrategyType.routeSearch => _loadPlaces(mode, filters),
      ModeQueryStrategyType.environmental => _loadEnvironment(mode),
      ModeQueryStrategyType.solar => _loadSolar(mode, filters),
      _ => _demo.load(mode),
    };
  }

  Future<List<ModeResultItem>> _loadPlaces(
    DiscoveryMode mode,
    Map<String, String> filters,
  ) async {
    final location = await _location.currentOrFallback();
    final result = await _places.searchPlaces(
      latitude: location.latitude,
      longitude: location.longitude,
      modeId: mode.id,
      query: _queryFor(mode, filters),
      category: _categoryFor(mode, filters),
      radiusMeters: _radiusMeters(filters['distance']),
      openNow:
          mode.id == 'open-now' ||
          filters.values.any((value) => value.toLowerCase() == 'open now'),
      maxResults: mode.id == 'food-wheel' ? 8 : 10,
    );
    return [
      for (final place in result.places)
        _placeItem(
          mode: mode,
          place: place,
          isDemo: result.isDemo,
          fallbackMessage: result.fallbackMessage,
          locationFallback: location.isFallback,
        ),
    ];
  }

  Future<List<ModeResultItem>> _loadEnvironment(DiscoveryMode mode) async {
    final location = await _location.currentOrFallback();
    if (mode.id == 'allergy-map') {
      final report = await _environment.pollen(
        latitude: location.latitude,
        longitude: location.longitude,
      );
      if (report.isDemo || report.days.isEmpty) {
        return _markDemo(
          await _demo.load(mode),
          report.fallbackMessage ??
              'Live pollen data is unavailable. Showing lower-exposure ideas.',
        );
      }
      final today = report.days.first;
      final level = today.category ?? 'Current pollen';
      return [
        ModeResultItem(
          id: '${mode.id}-live-pollen',
          title: '$level pollen outlook',
          subtitle: today.inSeasonTypes.isEmpty
              ? 'Current conditions near ${location.label}'
              : '${today.inSeasonTypes.join(', ')} in season',
          detail:
              'Use this forecast as a planning signal and follow personal medical guidance.',
          distanceLabel: 'Current area',
          imageSemanticName: 'allergy',
          tags: [
            if (today.indexValue != null) 'Index ${today.indexValue}',
            'Live forecast',
            if (location.isFallback) 'Austin fallback',
          ],
        ),
      ];
    }

    final report = await _environment.airQuality(
      latitude: location.latitude,
      longitude: location.longitude,
    );
    if (report.isDemo || report.aqi == null) {
      return _markDemo(
        await _demo.load(mode),
        report.fallbackMessage ??
            'Live air-quality data is unavailable. Verify conditions before leaving.',
      );
    }
    return [
      ModeResultItem(
        id: '${mode.id}-live-aqi',
        title: 'AQI ${report.aqi} · ${report.category ?? 'Current conditions'}',
        subtitle: 'Air quality near ${location.label}',
        detail:
            report.healthRecommendation ??
            'Use the current AQI to choose an indoor or outdoor plan.',
        distanceLabel: 'Current area',
        imageSemanticName: 'air',
        tags: [
          'Live AQI',
          if (report.dominantPollutant != null) report.dominantPollutant!,
          if (location.isFallback) 'Austin fallback',
        ],
      ),
    ];
  }

  Future<List<ModeResultItem>> _loadSolar(
    DiscoveryMode mode,
    Map<String, String> filters,
  ) async {
    final address = filters['location']?.trim() ?? '';
    if (address.isEmpty) {
      return _markDemo(
        await _demo.load(mode),
        'Enter an address to request a live solar check.',
      );
    }
    final result = await _solar.solarCheck(address);
    if (!result.available) {
      return [
        ModeResultItem(
          id: '${mode.id}-unavailable',
          title: 'Solar data unavailable',
          subtitle: address,
          detail:
              result.reason ??
              'No roof suitability or savings estimate was performed.',
          distanceLabel: 'Unavailable',
          imageSemanticName: 'solar',
          tags: const ['No estimate', 'Try another address'],
          isDemo: result.isDemo,
          fallbackMessage: result.reason,
        ),
      ];
    }
    return [
      ModeResultItem(
        id: '${mode.id}-live',
        title: 'Solar roof data found',
        subtitle: result.address,
        detail: result.maxSunshineHoursPerYear == null
            ? 'Building insights are available for a professional review.'
            : '${result.maxSunshineHoursPerYear!.round()} estimated sunshine hours per year.',
        distanceLabel: result.maxArrayPanelsCount == null
            ? 'Review ready'
            : 'Up to ${result.maxArrayPanelsCount} panels',
        imageSemanticName: 'solar',
        tags: const ['Live building data', 'Installer review'],
      ),
    ];
  }

  List<ModeResultItem> _markDemo(List<ModeResultItem> items, String message) {
    return [
      for (final item in items)
        ModeResultItem(
          id: item.id,
          title: item.title,
          subtitle: item.subtitle,
          detail: item.detail,
          distanceLabel: item.distanceLabel,
          imageSemanticName: item.imageSemanticName,
          tags: item.tags,
          rating: item.rating,
          openStatus: item.openStatus,
          isDemo: true,
          fallbackMessage: message,
        ),
    ];
  }

  ModeResultItem _placeItem({
    required DiscoveryMode mode,
    required PlaceSummary place,
    required bool isDemo,
    required String? fallbackMessage,
    required bool locationFallback,
  }) {
    final openStatus = switch (place.openNow) {
      true => 'Open now',
      false => 'Closed now',
      null => 'Hours unverified',
    };
    return ModeResultItem(
      id: place.id.isEmpty ? '${mode.id}-${place.name.hashCode}' : place.id,
      title: place.name,
      subtitle: place.address.isEmpty
          ? _readableType(place.primaryType) ?? 'Nearby place'
          : place.address,
      detail: place.rating == null
          ? 'Open place details to confirm current hours and availability.'
          : 'Rated ${place.rating!.toStringAsFixed(1)} from ${place.userRatingCount ?? 0} reviews.',
      distanceLabel: place.distanceMeters == null
          ? 'Nearby'
          : _distanceLabel(place.distanceMeters!),
      imageSemanticName: _imageFor(mode),
      tags: [
        ?_readableType(place.primaryType),
        openStatus,
        if (locationFallback) 'Austin fallback',
      ],
      rating: place.rating,
      openStatus: openStatus,
      isDemo: isDemo,
      fallbackMessage: fallbackMessage,
    );
  }
}

String _queryFor(DiscoveryMode mode, Map<String, String> filters) {
  return switch (mode.id) {
    'food-wheel' => 'restaurant',
    'patio-finder' => 'restaurant patio',
    'cheap-date' => 'affordable date activities',
    'kids-bored-button' => 'family activities',
    'rainy-day-ideas' => 'indoor activities',
    'dog-friendly-spots' => 'dog friendly places',
    'ev-charge-chill' => 'electric vehicle charging station',
    'road-rescue' => filters['need'] ?? 'roadside services',
    'open-now' =>
      filters['category'] == 'Anything'
          ? 'popular places'
          : filters['category'] ?? 'popular places',
    'neighborhood-check' => filters['priority'] ?? 'daily errands',
    _ => mode.title,
  };
}

String? _categoryFor(DiscoveryMode mode, Map<String, String> filters) {
  return switch (mode.id) {
    'food-wheel' || 'patio-finder' => 'restaurant',
    'ev-charge-chill' => 'electric_vehicle_charging_station',
    'road-rescue' when filters['need'] == 'Gas' => 'gas_station',
    'road-rescue' when filters['need'] == 'Pharmacy' => 'pharmacy',
    _ => null,
  };
}

int _radiusMeters(String? value) {
  final miles = int.tryParse(
    RegExp(r'\d+').firstMatch(value ?? '')?.group(0) ?? '',
  );
  return miles == null ? 8000 : (miles * 1609.344).round();
}

String _distanceLabel(int meters) {
  final miles = meters / 1609.344;
  return '${miles.toStringAsFixed(miles < 10 ? 1 : 0)} mi';
}

String? _readableType(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }
  final text = value.replaceAll('_', ' ');
  return '${text[0].toUpperCase()}${text.substring(1)}';
}

String _imageFor(DiscoveryMode mode) {
  return switch (mode.id) {
    'ev-charge-chill' => 'ev',
    'road-rescue' => 'road-rescue',
    'dog-friendly-spots' => 'dog',
    'rainy-day-ideas' => 'rainy-day',
    _ => 'food',
  };
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
