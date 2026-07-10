import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final appDataMaintenanceServiceProvider = Provider<AppDataMaintenanceService>((
  ref,
) {
  return const SharedPreferencesAppDataMaintenanceService();
});

abstract interface class AppDataMaintenanceService {
  Future<int> clearBackendCache();

  Future<int> resetDemoData();
}

class SharedPreferencesAppDataMaintenanceService
    implements AppDataMaintenanceService {
  const SharedPreferencesAppDataMaintenanceService();

  static const _cacheIndexKey = 'gomode.backend.v1.keys';

  @override
  Future<int> clearBackendCache() async {
    final preferences = await SharedPreferences.getInstance();
    final indexedKeys = preferences.getStringList(_cacheIndexKey) ?? const [];
    final cacheKeys = <String>{
      ...indexedKeys,
      ...preferences.getKeys().where(
        (key) => key.startsWith('gomode.backend.v1.'),
      ),
    };
    for (final key in cacheKeys) {
      await preferences.remove(key);
    }
    return cacheKeys.length;
  }

  @override
  Future<int> resetDemoData() async {
    final preferences = await SharedPreferences.getInstance();
    final keys = preferences
        .getKeys()
        .where(
          (key) => key.startsWith('saved.') || key.startsWith('road_trip.'),
        )
        .toList(growable: false);
    for (final key in keys) {
      await preferences.remove(key);
    }
    return keys.length;
  }
}
