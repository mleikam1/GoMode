import 'package:flutter_test/flutter_test.dart';
import 'package:gomode/services/app_data_maintenance_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('reset demo data preserves profile settings', () async {
    SharedPreferences.setMockInitialValues({
      'saved.items.v1': '[{"id":"temporary"}]',
      'saved.collections.v1': '[]',
      'saved.demo_seed_completed.v1': true,
      'road_trip.saved_stop_ids': <String>['stop-1'],
      'profile.settings.v1': '{"distanceMiles":25}',
    });
    const service = SharedPreferencesAppDataMaintenanceService();

    final removed = await service.resetDemoData();
    final preferences = await SharedPreferences.getInstance();

    expect(removed, 4);
    expect(preferences.getString('saved.items.v1'), isNull);
    expect(preferences.getStringList('road_trip.saved_stop_ids'), isNull);
    expect(
      preferences.getString('profile.settings.v1'),
      '{"distanceMiles":25}',
    );
  });

  test('clear cache removes indexed and orphaned backend entries', () async {
    SharedPreferences.setMockInitialValues({
      'gomode.backend.v1.keys': <String>['gomode.backend.v1.search.one'],
      'gomode.backend.v1.search.one': '{}',
      'gomode.backend.v1.search.orphan': '{}',
      'profile.settings.v1': '{}',
    });
    const service = SharedPreferencesAppDataMaintenanceService();

    final removed = await service.clearBackendCache();
    final preferences = await SharedPreferences.getInstance();

    expect(removed, 3);
    expect(
      preferences.getKeys().where(
        (key) => key.startsWith('gomode.backend.v1.'),
      ),
      isEmpty,
    );
    expect(preferences.getString('profile.settings.v1'), '{}');
  });
}
