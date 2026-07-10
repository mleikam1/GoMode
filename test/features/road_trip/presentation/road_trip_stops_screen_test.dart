import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gomode/app/gomode_app.dart';
import 'package:gomode/app/router.dart';
import 'package:gomode/features/road_trip/data/road_trip_route_service.dart';
import 'package:gomode/features/road_trip/data/route_stop_store.dart';
import 'package:gomode/features/road_trip/domain/route_plan.dart';

void main() {
  test('saved descriptions do not invent an absent rating', () {
    expect(
      _unknownTelemetryPlan.stops.single.savedDescription,
      'Along the route · Rating unverified',
    );
  });

  testWidgets('Road Trip Stops renders the route summary', (tester) async {
    await _pumpRoadTripStops(tester);

    expect(find.text('Road Trip Stops'), findsOneWidget);
    expect(find.text('Austin to San Antonio'), findsOneWidget);
    expect(find.text('Austin, TX'), findsOneWidget);
    expect(find.text('San Antonio, TX'), findsOneWidget);
    expect(find.text('82 mi'), findsOneWidget);
    expect(find.text('1h 23m'), findsOneWidget);
    expect(find.byKey(const ValueKey('route-progress-bar')), findsOneWidget);
    expect(find.text('Buc-ee’s New Braunfels'), findsOneWidget);
    expect(find.text('Scenic Overlook'), findsOneWidget);
    expect(find.text('Local BBQ Stop'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('road-trip-demo-fallback')),
      findsOneWidget,
    );
  });

  testWidgets('live stops disclose telemetry the backend did not return', (
    tester,
  ) async {
    await _pumpRoadTripStops(
      tester,
      routeService: const _StaticRouteService(_unknownTelemetryPlan),
    );

    expect(find.text('Rating & reviews unverified'), findsOneWidget);
    expect(
      find.textContaining('Distance off route not computed'),
      findsOneWidget,
    );
    expect(find.text('Detour not computed'), findsOneWidget);
    expect(find.text('Hours unverified'), findsOneWidget);
    expect(find.byKey(const ValueKey('road-trip-demo-fallback')), findsNothing);
  });

  testWidgets('quick filters update selected state and visible stops', (
    tester,
  ) async {
    await _pumpRoadTripStops(tester);

    const unselectedKey = ValueKey('route-filter-food-unselected');
    const selectedKey = ValueKey('route-filter-food-selected');
    expect(find.byKey(unselectedKey), findsOneWidget);

    await tester.tap(find.byKey(unselectedKey));
    await tester.pumpAndSettle();

    expect(find.byKey(selectedKey), findsOneWidget);
    expect(find.text('Buc-ee’s New Braunfels'), findsOneWidget);
    expect(find.text('Local BBQ Stop'), findsOneWidget);
    expect(find.text('Scenic Overlook'), findsNothing);
  });

  testWidgets('saving a route stop persists through the injected store', (
    tester,
  ) async {
    final store = _RecordingRouteStopStore();
    await _pumpRoadTripStops(tester, store: store);

    await tester.tap(
      find.byKey(const ValueKey('save-stop-bucees-new-braunfels')),
    );
    await tester.pumpAndSettle();

    expect(store.savedStopIds, contains('bucees-new-braunfels'));
    expect(store.lastStop?.title, 'Buc-ee’s New Braunfels');
    expect(store.lastSavedValue, isTrue);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('save-stop-bucees-new-braunfels')),
        matching: find.text('Saved'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Results and Map control switches views', (tester) async {
    await _pumpRoadTripStops(tester);

    expect(find.byKey(const ValueKey('route-results-list')), findsOneWidget);
    expect(find.byKey(const ValueKey('route-map-placeholder')), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey('road-trip-map-tab-unselected')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('route-results-list')), findsNothing);
    expect(find.byKey(const ValueKey('route-map-placeholder')), findsOneWidget);
    expect(find.text('Route map preview'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('road-trip-results-tab-unselected')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('route-results-list')), findsOneWidget);
  });

  testWidgets('route failure offers a working retry', (tester) async {
    final service = _ErrorThenRouteService();
    await _pumpRoadTripStops(tester, routeService: service);

    expect(find.text('Route stops are unavailable'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(service.calls, 2);
    expect(find.text('Austin to San Antonio'), findsOneWidget);
    expect(find.byKey(const ValueKey('route-results-list')), findsOneWidget);
  });
}

Future<void> _pumpRoadTripStops(
  WidgetTester tester, {
  _RecordingRouteStopStore? store,
  RoadTripRouteService? routeService,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  final routeStopStore = store ?? _RecordingRouteStopStore();
  final container = ProviderContainer(
    overrides: [
      routeStopStoreProvider.overrideWithValue(routeStopStore),
      if (routeService != null)
        roadTripRouteServiceProvider.overrideWithValue(routeService),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const GoModeApp()),
  );
  await tester.pumpAndSettle();
  container.read(appRouterProvider).go('/modes/road-trip-stops');
  await tester.pumpAndSettle();
}

class _ErrorThenRouteService implements RoadTripRouteService {
  int calls = 0;

  @override
  Future<RoutePlan> loadRoutePlan() async {
    calls += 1;
    if (calls == 1) {
      throw StateError('Temporary route failure');
    }
    return demoRoadTripRoutePlan;
  }
}

class _StaticRouteService implements RoadTripRouteService {
  const _StaticRouteService(this.plan);

  final RoutePlan plan;

  @override
  Future<RoutePlan> loadRoutePlan() async => plan;
}

class _RecordingRouteStopStore implements RouteStopStore {
  final Set<String> savedStopIds = {};
  RouteStop? lastStop;
  bool? lastSavedValue;

  @override
  Future<Set<String>> loadSavedStopIds() async => {...savedStopIds};

  @override
  Future<void> setSaved(RouteStop stop, {required bool saved}) async {
    lastStop = stop;
    lastSavedValue = saved;
    if (saved) {
      savedStopIds.add(stop.id);
    } else {
      savedStopIds.remove(stop.id);
    }
  }
}

const _unknownTelemetryPlan = RoutePlan(
  id: 'live-route',
  routeSubtitle: 'Austin to San Antonio',
  summary: RouteSummary(
    origin: 'Austin, TX',
    destination: 'San Antonio, TX',
    totalDistanceMiles: 82,
    estimatedDriveTime: Duration(hours: 1, minutes: 23),
    progress: 0.42,
  ),
  stops: [
    RouteStop(
      id: 'live-stop',
      title: 'Live Route Stop',
      locationLabel: 'Along the route',
      imageAsset: 'assets/images/road_trip/scenic_overlook.png',
      categories: {StopCategory.scenic},
    ),
  ],
);
