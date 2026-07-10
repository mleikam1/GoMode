import 'package:flutter_test/flutter_test.dart';
import 'package:gomode/data/models/backend_models.dart';
import 'package:gomode/data/repositories/environment_repository.dart';
import 'package:gomode/data/repositories/places_repository.dart';
import 'package:gomode/data/repositories/routes_repository.dart';
import 'package:gomode/data/repositories/solar_repository.dart';
import 'package:gomode/data/services/mode_catalog.dart';
import 'package:gomode/features/modes/data/generic_mode_results_service.dart';
import 'package:gomode/services/api_client.dart';
import 'package:gomode/services/location_service.dart';

void main() {
  group('BackendPlacesRepository', () {
    test('maps search request and minimal place response', () async {
      final client = _MockBackendApiClient({
        'searchPlaces': {
          'places': [
            {
              'id': 'place-1',
              'displayName': {'text': 'Live Cafe'},
              'formattedAddress': '1 Congress Ave, Austin, TX',
              'location': {'latitude': 30.26, 'longitude': -97.74},
              'primaryType': 'cafe',
              'openNow': true,
              'photos': [
                {
                  'name': 'places/place-1/photos/photo-1',
                  'authorAttributions': [
                    {
                      'displayName': 'Local Guide',
                      'uri': 'https://example.test/contributor',
                    },
                  ],
                },
              ],
            },
          ],
        },
      });
      final repository = BackendPlacesRepository(client);

      final result = await repository.searchPlaces(
        latitude: 30.2,
        longitude: -97.7,
        modeId: 'patio-finder',
        query: 'patio',
        category: 'restaurant',
        radiusMeters: 4000,
        openNow: true,
        maxResults: 4,
      );

      expect(client.calls.single.name, 'searchPlaces');
      expect(client.calls.single.input, {
        'latitude': 30.2,
        'longitude': -97.7,
        'modeId': 'patio-finder',
        'query': 'patio',
        'category': 'restaurant',
        'radius': 4000,
        'openNow': true,
        'maxResults': 4,
      });
      expect(result.places.single.name, 'Live Cafe');
      expect(result.places.single.rating, isNull);
      expect(result.places.single.openNow, isTrue);
      expect(result.places.single.photoName, 'places/place-1/photos/photo-1');
      expect(
        result.places.single.photoAttributions.single.displayName,
        'Local Guide',
      );
    });

    test(
      'forwards autocomplete session into details and avoids retry',
      () async {
        final client = _MockBackendApiClient({
          'autocomplete': {
            'suggestions': [
              {
                'placePrediction': {
                  'placeId': 'place-1',
                  'text': {'text': 'Austin, TX, USA'},
                },
              },
            ],
          },
          'placeDetails': {
            'place': {
              'id': 'place-1',
              'displayName': {'text': 'Austin'},
            },
          },
        });
        final repository = BackendPlacesRepository(client);

        final suggestions = await repository.autocomplete(
          text: 'Aus',
          sessionToken: 'session-123',
        );
        final details = await repository.placeDetails(
          'place-1',
          sessionToken: 'session-123',
        );

        expect(suggestions.suggestions.single.fullText, 'Austin, TX, USA');
        expect(client.calls.first.retryTransient, isFalse);
        expect(client.calls.last.input['sessionToken'], 'session-123');
        expect(details.place.name, 'Austin');
      },
    );

    test('uses only short-lived backend photo URL', () async {
      final client = _MockBackendApiClient({
        'placePhoto': {
          'url': 'https://example.test/placePhotoProxy?token=signed',
          'expiresAt': '2026-07-10T18:00:00Z',
        },
      });
      final repository = BackendPlacesRepository(client);

      final result = await repository.placePhoto(
        'places/place-1/photos/photo-1',
        maxWidthPx: 5000,
      );

      expect(result.url?.host, 'example.test');
      expect(result.expiresAt, DateTime.utc(2026, 7, 10, 18));
      expect(client.calls.single.input['maxWidthPx'], 1200);
    });

    test('falls back only for eligible backend failures', () async {
      final transient = ResilientPlacesRepository(
        BackendPlacesRepository(
          _ThrowingBackendApiClient(
            const BackendException(
              kind: BackendFailureKind.unavailable,
              userMessage: 'Temporarily unavailable.',
            ),
          ),
        ),
        const DemoPlacesRepository(),
      );
      final fallback = await transient.searchPlaces(
        latitude: 30.2,
        longitude: -97.7,
        modeId: 'patio-finder',
      );
      expect(fallback.isDemo, isTrue);
      expect(fallback.fallbackMessage, 'Temporarily unavailable.');

      final denied = ResilientPlacesRepository(
        BackendPlacesRepository(
          _ThrowingBackendApiClient(
            const BackendException(
              kind: BackendFailureKind.permissionDenied,
              userMessage: 'App Check failed.',
            ),
          ),
        ),
        const DemoPlacesRepository(),
      );
      await expectLater(
        denied.searchPlaces(
          latitude: 30.2,
          longitude: -97.7,
          modeId: 'patio-finder',
        ),
        throwsA(
          isA<BackendException>().having(
            (error) => error.kind,
            'kind',
            BackendFailureKind.permissionDenied,
          ),
        ),
      );

      final misconfigured = ResilientPlacesRepository(
        BackendPlacesRepository(
          _ThrowingBackendApiClient(
            const BackendException(
              kind: BackendFailureKind.failedPrecondition,
              userMessage: 'Live results are not configured correctly.',
            ),
          ),
        ),
        const DemoPlacesRepository(),
      );
      await expectLater(
        misconfigured.searchPlaces(
          latitude: 30.2,
          longitude: -97.7,
          modeId: 'patio-finder',
        ),
        throwsA(
          isA<BackendException>().having(
            (error) => error.kind,
            'kind',
            BackendFailureKind.failedPrecondition,
          ),
        ),
      );
    });

    test(
      'rejects malformed payloads and falls back from bad responses',
      () async {
        final primary = BackendPlacesRepository(
          _MockBackendApiClient({'searchPlaces': {}}),
        );

        await expectLater(
          primary.searchPlaces(
            latitude: 30.2,
            longitude: -97.7,
            modeId: 'patio-finder',
          ),
          throwsA(_badResponseFor('searchPlaces')),
        );

        final result =
            await ResilientPlacesRepository(
              primary,
              const DemoPlacesRepository(),
            ).searchPlaces(
              latitude: 30.2,
              longitude: -97.7,
              modeId: 'patio-finder',
            );
        expect(result.isDemo, isTrue);
      },
    );

    test('keeps a valid empty places list as a live result', () async {
      final client = _MockBackendApiClient({
        'searchPlaces': {'places': <Object?>[]},
      });
      final result = await BackendPlacesRepository(client).searchPlaces(
        latitude: 30.2,
        longitude: -97.7,
        modeId: 'patio-finder',
        radiusMeters: 1,
      );

      expect(result.places, isEmpty);
      expect(result.isDemo, isFalse);
      expect(client.calls.single.input['radius'], 50);
    });
  });

  group('BackendRoutesRepository', () {
    test('parses route and caps stop categories at three', () async {
      final client = _MockBackendApiClient({
        'computeRoute': {
          'route': {
            'distanceMeters': 10000,
            'durationSeconds': 900,
            'encodedPolyline': 'encoded',
          },
        },
        'roadTripStops': {
          'route': {'distanceMeters': 12000, 'durationSeconds': 1000},
          'stops': [
            {
              'id': 'stop-1',
              'displayName': {'text': 'Route Cafe'},
              'types': ['cafe'],
            },
          ],
          'strategy': 'route_polyline_midpoints',
        },
      });
      final repository = BackendRoutesRepository(client);

      final route = await repository.computeRoute(
        origin: RouteWaypoint.address('Austin, TX'),
        destination: RouteWaypoint.address('San Antonio, TX'),
      );
      final stops = await repository.roadTripStops(
        origin: RouteWaypoint.address('Austin, TX'),
        destination: RouteWaypoint.address('San Antonio, TX'),
        categories: const [
          'restaurant',
          'cafe',
          'gas_station',
          'park',
          'restaurant',
        ],
      );

      expect(route.distanceMeters, 10000);
      expect(route.durationSeconds, 900);
      expect(route.encodedPolyline, 'encoded');
      expect(client.calls.last.input['categories'], [
        'restaurant',
        'cafe',
        'gas_station',
      ]);
      expect(stops.stops.single.detourSeconds, isNull);
      expect(stops.stops.single.distanceMeters, isNull);
      expect(stops.strategy, 'route_polyline_midpoints');
    });

    test('supports TWO_WHEELER and rejects malformed route shapes', () async {
      final client = _MockBackendApiClient({
        'computeRoute': {
          'route': {'distanceMeters': 1000},
        },
      });

      await expectLater(
        BackendRoutesRepository(client).computeRoute(
          origin: RouteWaypoint.address('Austin, TX'),
          destination: RouteWaypoint.address('San Antonio, TX'),
          travelMode: RouteTravelMode.twoWheeler,
        ),
        throwsA(_badResponseFor('computeRoute')),
      );
      expect(client.calls.single.input['travelMode'], 'TWO_WHEELER');

      final fallback =
          await ResilientRoutesRepository(
            BackendRoutesRepository(client),
            const DemoRoutesRepository(),
          ).computeRoute(
            origin: RouteWaypoint.address('Austin, TX'),
            destination: RouteWaypoint.address('San Antonio, TX'),
          );
      expect(fallback.isDemo, isTrue);
    });
  });

  group('environment and solar repositories', () {
    test('parse typed current air and pollen responses', () async {
      final client = _MockBackendApiClient({
        'airQuality': {
          'latitude': 30.2,
          'longitude': -97.7,
          'current': {
            'dateTime': '2026-07-10T18:00:00Z',
            'aqi': 42,
            'category': 'Good',
            'dominantPollutant': 'pm25',
            'healthRecommendation': 'Enjoy normal activities.',
          },
          'forecast': [
            {
              'dateTime': '2026-07-10T19:00:00Z',
              'aqi': 47,
              'dominantPollutant': 'o3',
            },
          ],
          'forecastAvailable': true,
          'forecastStatus': 'available',
        },
        'pollen': {
          'latitude': 30.2,
          'longitude': -97.7,
          'dailyInfo': [
            {
              'date': {'year': 2026, 'month': 7, 'day': 10},
              'pollenTypeInfo': [
                {
                  'code': 'GRASS',
                  'displayName': 'Grass',
                  'inSeason': true,
                  'indexInfo': {'value': 3, 'category': 'Moderate'},
                },
              ],
            },
          ],
        },
      });
      final repository = BackendEnvironmentRepository(client);

      final air = await repository.airQuality(latitude: 30.2, longitude: -97.7);
      final pollen = await repository.pollen(latitude: 30.2, longitude: -97.7);

      expect(air.aqi, 42);
      expect(air.currentDateTime, DateTime.utc(2026, 7, 10, 18));
      expect(air.category, 'Good');
      expect(air.healthRecommendation, 'Enjoy normal activities.');
      expect(air.forecastAvailable, isTrue);
      expect(air.forecast.single.aqi, 47);
      expect(air.forecast.single.dominantPollutant, 'o3');
      expect(client.calls.first.input['includeForecast'], isFalse);
      expect(client.calls.first.input['forecastHours'], 6);
      expect(pollen.days.single.category, 'Moderate');
      expect(pollen.days.single.inSeasonTypes, ['Grass']);
    });

    test('preserves structured solar unavailable state', () async {
      final client = _MockBackendApiClient({
        'solarCheck': {
          'available': false,
          'status': 'not_configured',
          'address': '1 Main St, Austin, TX',
          'reason': 'Solar API is not enabled.',
        },
      });
      final repository = BackendSolarRepository(client);

      final result = await repository.solarCheck('1 Main St, Austin, TX');

      expect(result.available, isFalse);
      expect(result.reason, 'Solar API is not enabled.');
      expect(result.isDemo, isFalse);
    });

    test('parses available solar insights wrapper', () async {
      final client = _MockBackendApiClient({
        'solarCheck': {
          'available': true,
          'status': 'available',
          'address': '1 Main St, Austin, TX',
          'location': {'latitude': 30.2, 'longitude': -97.7},
          'buildingInsights': {
            'solarPotential': {
              'maxArrayPanelsCount': 18,
              'maxSunshineHoursPerYear': 1320.5,
              'carbonOffsetFactorKgPerMwh': 410.0,
            },
          },
        },
      });

      final result = await BackendSolarRepository(
        client,
      ).solarCheck('1 Main St');

      expect(result.available, isTrue);
      expect(result.status, 'available');
      expect(result.address, '1 Main St, Austin, TX');
      expect(result.maxArrayPanelsCount, 18);
      expect(result.maxSunshineHoursPerYear, 1320.5);
    });

    test('reject malformed environment and solar payloads', () async {
      final malformedAir = BackendEnvironmentRepository(
        _MockBackendApiClient({
          'airQuality': {
            'latitude': 30.2,
            'longitude': -97.7,
            'forecast': <Object?>[],
            'forecastAvailable': false,
            'forecastStatus': 'not_requested',
          },
        }),
      );
      await expectLater(
        malformedAir.airQuality(latitude: 30.2, longitude: -97.7),
        throwsA(_badResponseFor('airQuality')),
      );
      final fallbackAir = await ResilientEnvironmentRepository(
        malformedAir,
        const DemoEnvironmentRepository(),
      ).airQuality(latitude: 30.2, longitude: -97.7);
      expect(fallbackAir.isDemo, isTrue);
      await expectLater(
        BackendEnvironmentRepository(
          _MockBackendApiClient({
            'pollen': {
              'latitude': 30.2,
              'longitude': -97.7,
              'dailyInfo': [
                {'date': 'not-an-object', 'pollenTypeInfo': <Object?>[]},
              ],
            },
          }),
        ).pollen(latitude: 30.2, longitude: -97.7),
        throwsA(_badResponseFor('pollen')),
      );
      await expectLater(
        _malformedSolarRepository().solarCheck('1 Main St'),
        throwsA(_badResponseFor('solarCheck')),
      );
      final fallbackSolar = await ResilientSolarRepository(
        _malformedSolarRepository(),
        const DemoSolarRepository(),
      ).solarCheck('1 Main St');
      expect(fallbackSolar.isDemo, isTrue);
    });
  });

  test(
    'generic live place results disclose Austin location fallback',
    () async {
      final client = _MockBackendApiClient({
        'searchPlaces': {
          'places': [
            {
              'id': 'place-1',
              'displayName': {'text': 'Live Cafe'},
              'formattedAddress': 'Austin, TX',
            },
          ],
        },
      });
      final service = BackendGenericModeResultsService(
        places: BackendPlacesRepository(client),
        environment: const DemoEnvironmentRepository(),
        solar: const DemoSolarRepository(),
        location: const _FallbackLocationService(),
        demo: const DemoGenericModeResultsService(delay: Duration.zero),
      );

      final results = await service.load(
        const ModeCatalog().modeById('patio-finder'),
      );

      expect(results.single.tags, contains('Austin fallback'));
      expect(results.single.isDemo, isFalse);
    },
  );
}

Matcher _badResponseFor(String endpoint) {
  return isA<BackendException>()
      .having((error) => error.kind, 'kind', BackendFailureKind.badResponse)
      .having((error) => error.code, 'code', endpoint);
}

BackendSolarRepository _malformedSolarRepository() {
  return BackendSolarRepository(
    _MockBackendApiClient({
      'solarCheck': {
        'available': true,
        'status': 'available',
        'address': '1 Main St',
        'buildingInsights': <String, Object?>{},
      },
    }),
  );
}

class _BackendCall {
  const _BackendCall(this.name, this.input, this.retryTransient);

  final String name;
  final Map<String, dynamic> input;
  final bool retryTransient;
}

class _MockBackendApiClient implements BackendApiClient {
  _MockBackendApiClient(this.responses);

  final Map<String, Map<String, dynamic>> responses;
  final List<_BackendCall> calls = [];

  @override
  bool get isConfigured => true;

  @override
  Future<Map<String, dynamic>> call(
    String functionName,
    Map<String, dynamic> input, {
    bool retryTransient = true,
  }) async {
    calls.add(_BackendCall(functionName, input, retryTransient));
    return responses[functionName] ?? <String, dynamic>{};
  }
}

class _ThrowingBackendApiClient implements BackendApiClient {
  const _ThrowingBackendApiClient(this.error);

  final Object error;

  @override
  bool get isConfigured => true;

  @override
  Future<Map<String, dynamic>> call(
    String functionName,
    Map<String, dynamic> input, {
    bool retryTransient = true,
  }) async {
    throw error;
  }
}

class _FallbackLocationService implements LocationService {
  const _FallbackLocationService();

  @override
  Future<AppLocation> currentOrFallback() async => austinFallbackLocation;
}
