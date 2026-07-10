import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/route_plan.dart';

final roadTripRouteServiceProvider = Provider<RoadTripRouteService>((ref) {
  return const DemoRoadTripRouteService();
});

abstract interface class RoadTripRouteService {
  Future<RoutePlan> loadRoutePlan();
}

class DemoRoadTripRouteService implements RoadTripRouteService {
  const DemoRoadTripRouteService();

  @override
  Future<RoutePlan> loadRoutePlan() async => demoRoadTripRoutePlan;
}

const demoRoadTripRoutePlan = RoutePlan(
  id: 'austin-san-antonio-demo',
  routeSubtitle: 'Austin to San Antonio',
  isDemo: true,
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
