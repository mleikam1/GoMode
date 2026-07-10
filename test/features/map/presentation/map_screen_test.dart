import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gomode/app/gomode_app.dart';
import 'package:gomode/app/router.dart';
import 'package:gomode/data/repositories/places_repository.dart';
import 'package:gomode/features/profile/application/profile_settings_controller.dart';
import 'package:gomode/features/profile/data/profile_settings_repository.dart';
import 'package:gomode/features/road_trip/data/road_trip_route_service.dart';
import 'package:gomode/features/saved/application/saved_library_controller.dart';
import 'package:gomode/features/saved/data/saved_local_storage.dart';
import 'package:gomode/features/saved/data/saved_repository.dart';
import 'package:gomode/services/location_service.dart';

void main() {
  testWidgets('map renders nearby pins and opens place details', (
    tester,
  ) async {
    final harness = await _pumpMap(
      tester,
      locationService: const _FixedLocationService(
        AppLocation(
          latitude: 30.2672,
          longitude: -97.7431,
          label: 'Current location',
        ),
      ),
    );

    expect(find.byKey(const ValueKey('map-screen')), findsOneWidget);
    expect(find.byKey(const ValueKey('map-placeholder')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('map-pin-demo-neighborhood-cafe')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('map-pin-demo-neighborhood-cafe')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('place-details-sheet')), findsOneWidget);
    expect(find.text('Neighborhood Cafe'), findsWidgets);
    expect(find.byKey(const ValueKey('place-details-save')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('place-details-navigate')),
      findsOneWidget,
    );
    expect(find.text('Website'), findsOneWidget);
    expect(find.text('Call'), findsOneWidget);

    harness.dispose();
  });

  testWidgets('permission denied state explains fallback and remains usable', (
    tester,
  ) async {
    final harness = await _pumpMap(
      tester,
      locationService: const _FixedLocationService(
        AppLocation(
          latitude: 30.2672,
          longitude: -97.7431,
          label: 'Austin, TX',
          isFallback: true,
          fallbackReason: LocationFallbackReason.permissionDenied,
        ),
      ),
    );

    expect(find.byKey(const ValueKey('map-location-notice')), findsOneWidget);
    expect(find.textContaining('Location permission is off'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('map-pin-demo-neighborhood-cafe')),
      findsOneWidget,
    );

    harness.dispose();
  });
}

Future<_MapHarness> _pumpMap(
  WidgetTester tester, {
  required LocationService locationService,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  final savedStorage = _MemorySavedLocalStorage();
  final savedRepository = LocalSavedRepository(
    storage: savedStorage,
    now: () => DateTime(2026, 7, 10, 12),
  );
  final container = ProviderContainer(
    overrides: [
      locationServiceProvider.overrideWithValue(locationService),
      placesRepositoryProvider.overrideWithValue(const DemoPlacesRepository()),
      roadTripRouteServiceProvider.overrideWithValue(
        const DemoRoadTripRouteService(),
      ),
      profileSettingsRepositoryProvider.overrideWithValue(
        LocalProfileSettingsRepository(
          storage: _MemoryProfileSettingsStorage(),
        ),
      ),
      savedRepositoryProvider.overrideWithValue(savedRepository),
    ],
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const GoModeApp()),
  );
  container.read(appRouterProvider).go('/map');
  await tester.pumpAndSettle();
  return _MapHarness(container);
}

class _MapHarness {
  const _MapHarness(this.container);

  final ProviderContainer container;

  void dispose() => container.dispose();
}

class _FixedLocationService implements LocationService {
  const _FixedLocationService(this.location);

  final AppLocation location;

  @override
  Future<AppLocation> currentOrFallback() async => location;
}

class _MemoryProfileSettingsStorage implements ProfileSettingsStorage {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }
}

class _MemorySavedLocalStorage implements SavedLocalStorage {
  final Map<String, Object> values = {};

  @override
  Future<bool?> readBool(String key) async => values[key] as bool?;

  @override
  Future<String?> readString(String key) async => values[key] as String?;

  @override
  Future<void> writeBool(String key, bool value) async {
    values[key] = value;
  }

  @override
  Future<void> writeString(String key, String value) async {
    values[key] = value;
  }
}
