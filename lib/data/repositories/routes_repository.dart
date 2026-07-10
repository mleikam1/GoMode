import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/api_client.dart';
import '../models/backend_models.dart';
import 'backend_response_validation.dart';

final routesRepositoryProvider = Provider<RoutesRepository>((ref) {
  return ResilientRoutesRepository(
    BackendRoutesRepository(ref.watch(backendApiClientProvider)),
    const DemoRoutesRepository(),
  );
});

enum RouteTravelMode { drive, walk, bicycle, transit, twoWheeler }

extension RouteTravelModeApiValue on RouteTravelMode {
  String get apiValue => switch (this) {
    RouteTravelMode.drive => 'DRIVE',
    RouteTravelMode.walk => 'WALK',
    RouteTravelMode.bicycle => 'BICYCLE',
    RouteTravelMode.transit => 'TRANSIT',
    RouteTravelMode.twoWheeler => 'TWO_WHEELER',
  };
}

abstract interface class RoutesRepository {
  Future<RouteResult> computeRoute({
    required RouteWaypoint origin,
    required RouteWaypoint destination,
    RouteTravelMode travelMode = RouteTravelMode.drive,
  });

  Future<RoadTripResult> roadTripStops({
    required RouteWaypoint origin,
    required RouteWaypoint destination,
    required List<String> categories,
  });
}

class BackendRoutesRepository implements RoutesRepository {
  const BackendRoutesRepository(this._client);

  final BackendApiClient _client;

  @override
  Future<RouteResult> computeRoute({
    required RouteWaypoint origin,
    required RouteWaypoint destination,
    RouteTravelMode travelMode = RouteTravelMode.drive,
  }) async {
    final payload = await _client.call('computeRoute', {
      'origin': origin.toJson(),
      'destination': destination.toJson(),
      'travelMode': travelMode.apiValue,
    });
    const endpoint = 'computeRoute';
    final route = requireResponseMap(
      payload['route'],
      endpoint: endpoint,
      field: 'route',
    );
    validateRouteResponse(route, endpoint: endpoint, field: 'route');
    return RouteResult.fromJson(route);
  }

  @override
  Future<RoadTripResult> roadTripStops({
    required RouteWaypoint origin,
    required RouteWaypoint destination,
    required List<String> categories,
  }) async {
    final payload = await _client.call('roadTripStops', {
      'origin': origin.toJson(),
      'destination': destination.toJson(),
      'categories': categories
          .map((category) => category.trim())
          .where((category) => category.isNotEmpty)
          .toSet()
          .take(3)
          .toList(),
    });
    const endpoint = 'roadTripStops';
    final route = requireResponseMap(
      payload['route'],
      endpoint: endpoint,
      field: 'route',
    );
    validateRouteResponse(route, endpoint: endpoint, field: 'route');
    final stops = requireResponseList(
      payload['stops'],
      endpoint: endpoint,
      field: 'stops',
    );
    for (var index = 0; index < stops.length; index++) {
      final stop = requireResponseMap(
        stops[index],
        endpoint: endpoint,
        field: 'stops[$index]',
      );
      validatePlaceResponse(stop, endpoint: endpoint, field: 'stops[$index]');
    }
    requireResponseString(payload, 'strategy', endpoint: endpoint);
    return RoadTripResult.fromJson(payload);
  }
}

class ResilientRoutesRepository implements RoutesRepository {
  const ResilientRoutesRepository(this._primary, this._fallback);

  final RoutesRepository _primary;
  final RoutesRepository _fallback;

  @override
  Future<RouteResult> computeRoute({
    required RouteWaypoint origin,
    required RouteWaypoint destination,
    RouteTravelMode travelMode = RouteTravelMode.drive,
  }) async {
    try {
      return await _primary.computeRoute(
        origin: origin,
        destination: destination,
        travelMode: travelMode,
      );
    } catch (error) {
      if (!canUseDemoFallback(error)) {
        rethrow;
      }
      final result = await _fallback.computeRoute(
        origin: origin,
        destination: destination,
        travelMode: travelMode,
      );
      return RouteResult(
        distanceMeters: result.distanceMeters,
        durationSeconds: result.durationSeconds,
        encodedPolyline: result.encodedPolyline,
        description: result.description,
        isDemo: true,
      );
    }
  }

  @override
  Future<RoadTripResult> roadTripStops({
    required RouteWaypoint origin,
    required RouteWaypoint destination,
    required List<String> categories,
  }) async {
    try {
      return await _primary.roadTripStops(
        origin: origin,
        destination: destination,
        categories: categories,
      );
    } catch (error) {
      if (!canUseDemoFallback(error)) {
        rethrow;
      }
      final result = await _fallback.roadTripStops(
        origin: origin,
        destination: destination,
        categories: categories,
      );
      return RoadTripResult(
        route: result.route,
        stops: result.stops,
        strategy: result.strategy,
        isDemo: true,
        fallbackMessage: error is BackendException
            ? error.userMessage
            : 'Showing demo stops while live route search is unavailable.',
      );
    }
  }
}

class DemoRoutesRepository implements RoutesRepository {
  const DemoRoutesRepository();

  @override
  Future<RouteResult> computeRoute({
    required RouteWaypoint origin,
    required RouteWaypoint destination,
    RouteTravelMode travelMode = RouteTravelMode.drive,
  }) async {
    return RouteResult(
      distanceMeters: travelMode == RouteTravelMode.drive ? 131970 : 130000,
      durationSeconds: travelMode == RouteTravelMode.drive ? 4980 : 28800,
      description: '${origin.label} to ${destination.label}',
      isDemo: true,
    );
  }

  @override
  Future<RoadTripResult> roadTripStops({
    required RouteWaypoint origin,
    required RouteWaypoint destination,
    required List<String> categories,
  }) async {
    final route = await computeRoute(origin: origin, destination: destination);
    return RoadTripResult(
      route: route,
      strategy: 'demo_fixture',
      isDemo: true,
      stops: const [
        PlaceSummary(
          id: 'bucees-new-braunfels',
          name: 'Buc-ee’s New Braunfels',
          address: 'I-35 S, Exit 189',
          types: ['food', 'coffee', 'gas_station', 'restroom'],
          rating: 4.9,
          userRatingCount: 4632,
          openNow: true,
          distanceMeters: 5150,
          detourSeconds: 300,
        ),
        PlaceSummary(
          id: 'scenic-overlook',
          name: 'Scenic Overlook',
          address: 'FM 306, Canyon Lake',
          types: ['tourist_attraction', 'restroom'],
          rating: 4.8,
          userRatingCount: 812,
          openNow: true,
          distanceMeters: 12230,
          detourSeconds: 480,
        ),
        PlaceSummary(
          id: 'local-bbq-stop',
          name: 'Local BBQ Stop',
          address: 'Exit 174',
          types: ['restaurant', 'food', 'restroom'],
          rating: 4.7,
          userRatingCount: 1254,
          openNow: true,
          distanceMeters: 6600,
          detourSeconds: 360,
        ),
      ],
    );
  }
}
