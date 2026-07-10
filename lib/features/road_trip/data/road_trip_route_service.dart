import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/backend_models.dart';
import '../../../data/repositories/routes_repository.dart';
import '../domain/route_plan.dart';

final roadTripRouteServiceProvider = Provider<RoadTripRouteService>((ref) {
  return BackendRoadTripRouteService(ref.watch(routesRepositoryProvider));
});

abstract interface class RoadTripRouteService {
  Future<RoutePlan> loadRoutePlan();
}

class DemoRoadTripRouteService implements RoadTripRouteService {
  const DemoRoadTripRouteService();

  @override
  Future<RoutePlan> loadRoutePlan() async => demoRoadTripRoutePlan;
}

class BackendRoadTripRouteService implements RoadTripRouteService {
  const BackendRoadTripRouteService(this._routes);

  final RoutesRepository _routes;

  @override
  Future<RoutePlan> loadRoutePlan() async {
    final result = await _routes.roadTripStops(
      origin: RouteWaypoint.address('Austin, TX'),
      destination: RouteWaypoint.address('San Antonio, TX'),
      categories: const ['restaurant', 'gas_station', 'tourist_attraction'],
    );
    return RoutePlan(
      id: result.isDemo ? demoRoadTripRoutePlan.id : 'austin-san-antonio-live',
      routeSubtitle: 'Austin to San Antonio',
      isDemo: result.isDemo,
      strategy: result.strategy,
      summary: RouteSummary(
        origin: 'Austin, TX',
        destination: 'San Antonio, TX',
        totalDistanceMiles: (result.route.distanceMeters / 1609.344).round(),
        estimatedDriveTime: Duration(seconds: result.route.durationSeconds),
        progress: 0.42,
      ),
      stops: [
        for (var index = 0; index < result.stops.length; index++)
          _routeStop(result.stops[index], index),
      ],
    );
  }

  RouteStop _routeStop(PlaceSummary place, int index) {
    return RouteStop(
      id: place.id.isEmpty ? 'route-stop-$index' : place.id,
      title: place.name,
      rating: place.rating,
      reviewCount: place.userRatingCount,
      distanceOffRouteMiles: place.distanceMeters == null
          ? null
          : place.distanceMeters! / 1609.344,
      detourTime: place.detourSeconds == null
          ? null
          : Duration(seconds: place.detourSeconds!),
      openNow: place.openNow,
      locationLabel: place.address.isEmpty ? 'Along the route' : place.address,
      imageAsset: _routeImage(index),
      categories: _stopCategories(place.types),
    );
  }
}

String _routeImage(int index) {
  return switch (index % 3) {
    0 => 'assets/images/road_trip/bucees_new_braunfels.png',
    1 => 'assets/images/road_trip/scenic_overlook.png',
    _ => 'assets/images/road_trip/local_bbq_stop.png',
  };
}

Set<StopCategory> _stopCategories(List<String> types) {
  final normalized = types.map((type) => type.toLowerCase()).toSet();
  final categories = <StopCategory>{};
  if (normalized.any(
    (type) =>
        type.contains('food') ||
        type.contains('restaurant') ||
        type.contains('meal'),
  )) {
    categories.add(StopCategory.food);
  }
  if (normalized.any((type) => type.contains('coffee') || type == 'cafe')) {
    categories.add(StopCategory.coffee);
  }
  if (normalized.any((type) => type.contains('gas'))) {
    categories.add(StopCategory.gas);
  }
  if (normalized.any((type) => type.contains('restroom'))) {
    categories.add(StopCategory.bathrooms);
  }
  if (normalized.any(
    (type) =>
        type.contains('scenic') ||
        type.contains('tourist') ||
        type.contains('park'),
  )) {
    categories.add(StopCategory.scenic);
  }
  return categories.isEmpty ? {StopCategory.scenic} : categories;
}

const demoRoadTripRoutePlan = RoutePlan(
  id: 'austin-san-antonio-demo',
  routeSubtitle: 'Austin to San Antonio',
  isDemo: true,
  strategy: 'demo_fixture',
  summary: RouteSummary(
    origin: 'Austin, TX',
    destination: 'San Antonio, TX',
    totalDistanceMiles: 82,
    estimatedDriveTime: Duration(hours: 1, minutes: 23),
    progress: 0.42,
  ),
  stops: [
    RouteStop(
      id: 'bucees-new-braunfels',
      title: 'Buc-ee’s New Braunfels',
      rating: 4.9,
      reviewCount: 4632,
      distanceOffRouteMiles: 3.2,
      detourTime: Duration(minutes: 5),
      openNow: true,
      locationLabel: 'I-35 S, Exit 189',
      imageAsset: 'assets/images/road_trip/bucees_new_braunfels.png',
      categories: {
        StopCategory.food,
        StopCategory.coffee,
        StopCategory.gas,
        StopCategory.bathrooms,
      },
    ),
    RouteStop(
      id: 'scenic-overlook',
      title: 'Scenic Overlook',
      rating: 4.8,
      reviewCount: 812,
      distanceOffRouteMiles: 7.6,
      detourTime: Duration(minutes: 8),
      openNow: true,
      locationLabel: 'FM 306, Canyon Lake',
      imageAsset: 'assets/images/road_trip/scenic_overlook.png',
      categories: {StopCategory.scenic, StopCategory.bathrooms},
    ),
    RouteStop(
      id: 'local-bbq-stop',
      title: 'Local BBQ Stop',
      rating: 4.7,
      reviewCount: 1254,
      distanceOffRouteMiles: 4.1,
      detourTime: Duration(minutes: 6),
      openNow: true,
      locationLabel: 'Exit 174',
      imageAsset: 'assets/images/road_trip/local_bbq_stop.png',
      categories: {StopCategory.food, StopCategory.bathrooms},
    ),
  ],
);
