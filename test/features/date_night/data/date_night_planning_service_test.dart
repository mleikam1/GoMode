import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gomode/data/models/backend_models.dart';
import 'package:gomode/data/repositories/places_repository.dart';
import 'package:gomode/features/date_night/data/date_night_planning_service.dart';
import 'package:gomode/features/date_night/domain/date_night_preferences.dart';
import 'package:gomode/services/location_service.dart';

void main() {
  test(
    'default unconfigured backend stays useful with demo fallback',
    () async {
      final container = ProviderContainer(
        overrides: [
          locationServiceProvider.overrideWithValue(
            const _FixedLocationService(isFallback: true),
          ),
        ],
      );
      addTearDown(container.dispose);

      final plan = await container
          .read(dateNightPlanningServiceProvider)
          .generatePlan(const DateNightPreferences.defaults());

      expect(plan.isDemo, isTrue);
      expect(plan.steps, hasLength(3));
    },
  );

  test('builds a balanced live plan from three bounded searches', () async {
    final places = _RecordingPlacesRepository();
    final service = BackendDateNightPlanningService(
      places,
      const _FixedLocationService(isFallback: false),
    );

    final plan = await service.generatePlan(
      const DateNightPreferences.defaults(),
    );

    expect(plan.isDemo, isFalse);
    expect(plan.steps.map((step) => step.placeName), [
      'Live Dinner',
      'Live Activity',
      'Live Dessert',
    ]);
    expect(places.calls, hasLength(3));
    expect(places.calls.every((call) => call.maxResults == 3), isTrue);
    expect(places.calls.every((call) => call.openNow), isTrue);
    expect(places.calls.map((call) => call.category), [
      'restaurant',
      'tourist_attraction',
      null,
    ]);
  });

  test('uses a disclosed demo plan when a live category falls back', () async {
    final service = BackendDateNightPlanningService(
      _RecordingPlacesRepository(demoModeId: 'date-night-activity'),
      const _FixedLocationService(isFallback: true),
    );

    final plan = await service.generatePlan(
      const DateNightPreferences.defaults(),
    );

    expect(plan.isDemo, isTrue);
    expect(plan.fallbackMessage, contains('Live activity unavailable'));
    expect(plan.steps, hasLength(3));
  });
}

class _PlaceCall {
  const _PlaceCall({
    required this.modeId,
    required this.category,
    required this.openNow,
    required this.maxResults,
  });

  final String modeId;
  final String? category;
  final bool openNow;
  final int maxResults;
}

class _RecordingPlacesRepository implements PlacesRepository {
  _RecordingPlacesRepository({this.demoModeId});

  final String? demoModeId;
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
        category: category,
        openNow: openNow,
        maxResults: maxResults,
      ),
    );
    final place = switch (modeId) {
      'date-night-dinner' => const PlaceSummary(
        id: 'dinner',
        name: 'Live Dinner',
        address: '1 Dinner Way',
        types: ['restaurant'],
      ),
      'date-night-activity' => const PlaceSummary(
        id: 'activity',
        name: 'Live Activity',
        address: '2 Activity Way',
        types: ['tourist_attraction'],
      ),
      _ => const PlaceSummary(
        id: 'dessert',
        name: 'Live Dessert',
        address: '3 Dessert Way',
        types: ['dessert_shop'],
      ),
    };
    return PlaceSearchResult(
      places: [place],
      isDemo: modeId == demoModeId,
      fallbackMessage: modeId == demoModeId
          ? 'Live activity unavailable.'
          : null,
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

class _FixedLocationService implements LocationService {
  const _FixedLocationService({required this.isFallback});

  final bool isFallback;

  @override
  Future<AppLocation> currentOrFallback() async => AppLocation(
    latitude: 30.2672,
    longitude: -97.7431,
    label: 'Austin, TX',
    isFallback: isFallback,
  );
}
