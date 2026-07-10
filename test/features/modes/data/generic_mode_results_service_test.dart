import 'package:flutter_test/flutter_test.dart';
import 'package:gomode/data/models/backend_models.dart';
import 'package:gomode/data/repositories/environment_repository.dart';
import 'package:gomode/data/repositories/places_repository.dart';
import 'package:gomode/data/repositories/solar_repository.dart';
import 'package:gomode/data/services/mode_catalog.dart';
import 'package:gomode/features/modes/data/generic_mode_results_service.dart';
import 'package:gomode/services/location_service.dart';

void main() {
  const catalog = ModeCatalog();
  const service = DemoGenericModeResultsService(delay: Duration.zero);

  test('every generic mode produces fallback results', () async {
    for (final mode in catalog.modes.where(
      (mode) => mode.id != 'date-night' && mode.id != 'road-trip-stops',
    )) {
      expect(await service.load(mode), isNotEmpty, reason: mode.id);
    }
  });

  test('weekend and tourist plans generate multi-stop itineraries', () async {
    final weekend = await service.load(catalog.modeById('weekend-plan'));
    final tourist = await service.load(catalog.modeById('tourist-mode'));

    expect(weekend, hasLength(5));
    expect(tourist, hasLength(4));
  });

  test('road rescue covers all requested urgent categories', () async {
    final results = await service.load(catalog.modeById('road-rescue'));
    final tags = results.expand((result) => result.tags).toSet();

    expect(
      tags,
      containsAll(['Gas', 'Restroom', 'Pharmacy', 'Urgent care', 'Mechanic']),
    );
  });

  test('live Weekend Plan makes four bounded role searches', () async {
    final places = _RecordingPlacesRepository();
    final live = _service(places);

    final results = await live.loadWithFilters(
      catalog.modeById('weekend-plan'),
      const {'setting': 'Outdoor', 'distance': '5 mi'},
    );

    expect(results, hasLength(4));
    expect(results.every((result) => !result.isDemo), isTrue);
    expect(places.calls, hasLength(4));
    expect(places.calls.every((call) => call.maxResults == 3), isTrue);
    expect(places.calls.map((call) => call.category), [
      'restaurant',
      'park',
      null,
      'scenic_spot',
    ]);
  });

  test(
    'priority place modes use cost-conscious mode-specific searches',
    () async {
      final places = _RecordingPlacesRepository();
      final live = _service(places);

      await live.loadWithFilters(catalog.modeById('food-wheel'), const {
        'open': 'Any time',
      });
      final foodCall = places.calls.last;
      expect(foodCall.query, isNull);
      expect(foodCall.category, 'restaurant');
      expect(foodCall.maxResults, 8);

      final patio = await live.loadWithFilters(
        catalog.modeById('patio-finder'),
        const {'pet': 'Any patio'},
      );
      expect(patio.first.title, 'Garden Deck Cafe');
      expect(patio.first.tags, containsAll(['Photo signal', 'Review signal']));

      await live.loadWithFilters(catalog.modeById('kids-bored-button'), const {
        'setting': 'Indoor',
        'energy': 'Active',
      });
      expect(places.calls.last.category, isNull);
      expect(places.calls.last.query, contains('bowling'));

      await live.loadWithFilters(catalog.modeById('open-now'), const {
        'category': 'Coffee',
      });
      expect(places.calls.last.category, 'coffee_shop');
      expect(places.calls.last.openNow, isTrue);
    },
  );

  test(
    'environment modes combine live conditions with Places suggestions',
    () async {
      final places = _RecordingPlacesRepository();
      final live = _service(places);

      final allergy = await live.loadWithFilters(
        catalog.modeById('allergy-map'),
        const {'allergen': 'Mold', 'setting': 'Indoor'},
      );
      expect(allergy.first.title, contains('mold not covered'));
      expect(allergy.first.tags, contains('Mold not measured'));
      expect(allergy, hasLength(greaterThan(1)));

      final air = await live.loadWithFilters(
        catalog.modeById('clean-air-planner'),
        const {'setting': 'Outdoor'},
      );
      expect(air.first.title, contains('AQI 42'));
      expect(air, hasLength(greaterThan(1)));
    },
  );

  test(
    'Solar disabled state keeps inputs without making an estimate',
    () async {
      final results = await _service(_RecordingPlacesRepository())
          .loadWithFilters(catalog.modeById('solar-checker'), const {
            'location': '101 Congress Ave, Austin, TX',
            'homeType': 'Single-family',
            'shade': 'Some',
          });

      expect(results.map((result) => result.title), [
        'Connect Solar API',
        'Local estimation placeholder',
      ]);
      expect(results.last.detail, contains('no roof'));
      expect(results.last.tags, contains('No solar claim'));
    },
  );
}

BackendGenericModeResultsService _service(_RecordingPlacesRepository places) {
  return BackendGenericModeResultsService(
    places: places,
    environment: const _LiveEnvironmentRepository(),
    solar: const _UnavailableSolarRepository(),
    location: const _FixedLocationService(),
    demo: const DemoGenericModeResultsService(delay: Duration.zero),
  );
}

class _PlaceCall {
  const _PlaceCall({
    required this.modeId,
    required this.query,
    required this.category,
    required this.openNow,
    required this.maxResults,
  });

  final String modeId;
  final String? query;
  final String? category;
  final bool openNow;
  final int maxResults;
}

class _RecordingPlacesRepository implements PlacesRepository {
  final List<_PlaceCall> calls = [];

  @override
  Future<PlaceSearchResult> searchPlaces({
    required double latitude,
    required double longitude,
    required String modeId,
    String? query,
    String? category,
    int radiusMeters = 8000,
    bool openNow = false,
    int maxResults = 10,
  }) async {
    calls.add(
      _PlaceCall(
        modeId: modeId,
        query: query,
        category: category,
        openNow: openNow,
        maxResults: maxResults,
      ),
    );
    if (modeId == 'patio-finder') {
      return const PlaceSearchResult(
        places: [
          PlaceSummary(
            id: 'plain',
            name: 'Plain Restaurant',
            address: '1 Main St',
            types: ['restaurant'],
            rating: 4.9,
            userRatingCount: 20,
          ),
          PlaceSummary(
            id: 'patio',
            name: 'Garden Deck Cafe',
            address: '2 Main St',
            types: ['restaurant'],
            rating: 4.7,
            userRatingCount: 800,
            photoName: 'places/patio/photos/one',
          ),
        ],
      );
    }
    final id = '${calls.length}-$modeId';
    return PlaceSearchResult(
      places: [
        PlaceSummary(
          id: id,
          name: query ?? 'Nearby Restaurant',
          address: 'Austin, TX',
          types: [category ?? 'tourist_attraction'],
          primaryType: category,
          openNow: openNow ? true : null,
        ),
      ],
    );
  }

  @override
  Future<AutocompleteResult> autocomplete({
    required String text,
    required String sessionToken,
    double? latitude,
    double? longitude,
    int? radiusMeters,
  }) => throw UnimplementedError();

  @override
  Future<PlaceDetailsResult> placeDetails(
    String placeId, {
    String? sessionToken,
  }) => throw UnimplementedError();

  @override
  Future<PlacePhotoResult> placePhoto(
    String photoName, {
    int maxWidthPx = 800,
  }) => throw UnimplementedError();
}

class _LiveEnvironmentRepository implements EnvironmentRepository {
  const _LiveEnvironmentRepository();

  @override
  Future<AirQualityReport> airQuality({
    required double latitude,
    required double longitude,
    bool includeForecast = false,
    int forecastHours = 6,
  }) async {
    return AirQualityReport(
      latitude: latitude,
      longitude: longitude,
      aqi: 42,
      category: 'Good',
      healthRecommendation: 'Normal activities are appropriate.',
      forecast: const [],
    );
  }

  @override
  Future<PollenReport> pollen({
    required double latitude,
    required double longitude,
    int days = 3,
  }) async {
    return PollenReport(
      latitude: latitude,
      longitude: longitude,
      days: [
        PollenDay(
          date: DateTime(2026, 7, 10),
          indexValue: 2,
          category: 'Low',
          inSeasonTypes: const ['Grass'],
        ),
      ],
    );
  }
}

class _UnavailableSolarRepository implements SolarRepository {
  const _UnavailableSolarRepository();

  @override
  Future<SolarCheckResult> solarCheck(String address) async {
    return SolarCheckResult(
      available: false,
      address: address,
      status: 'not_configured',
      reason: 'Solar API is not configured.',
    );
  }
}

class _FixedLocationService implements LocationService {
  const _FixedLocationService();

  @override
  Future<AppLocation> currentOrFallback() async => const AppLocation(
    latitude: 30.2672,
    longitude: -97.7431,
    label: 'Current location',
  );
}
