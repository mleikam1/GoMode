import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/route_plan.dart';

final routeStopStoreProvider = Provider<RouteStopStore>((ref) {
  return const SharedPreferencesRouteStopStore();
});

abstract interface class RouteStopStore {
  Future<Set<String>> loadSavedStopIds();

  Future<void> setSaved(RouteStop stop, {required bool saved});
}

class SharedPreferencesRouteStopStore implements RouteStopStore {
  const SharedPreferencesRouteStopStore();

  static const _savedStopIdsKey = 'road_trip.saved_stop_ids';

  @override
  Future<Set<String>> loadSavedStopIds() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getStringList(_savedStopIdsKey)?.toSet() ?? <String>{};
  }

  @override
  Future<void> setSaved(RouteStop stop, {required bool saved}) async {
    final preferences = await SharedPreferences.getInstance();
    final savedIds =
        preferences.getStringList(_savedStopIdsKey)?.toSet() ?? <String>{};

    if (saved) {
      savedIds.add(stop.id);
    } else {
      savedIds.remove(stop.id);
    }

    await preferences.setStringList(
      _savedStopIdsKey,
      savedIds.toList()..sort(),
    );
  }
}
