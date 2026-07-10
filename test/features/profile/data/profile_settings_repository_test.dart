import 'package:flutter_test/flutter_test.dart';
import 'package:gomode/features/profile/data/profile_settings_repository.dart';
import 'package:gomode/features/profile/domain/profile_settings.dart';

void main() {
  test('profile settings persist across repository instances', () async {
    final storage = _MemoryProfileSettingsStorage();
    final firstRepository = LocalProfileSettingsRepository(storage: storage);
    const settings = ProfileSettings(
      locationPreference: LocationPreference.defaultCity,
      defaultCityId: 'denver-co',
      budget: BudgetPreference.value,
      distanceMiles: 25,
      setting: SettingPreference.outdoor,
      familyFriendly: true,
      petFriendly: true,
      accessibilityPreferred: true,
    );

    await firstRepository.save(settings);

    final restartedRepository = LocalProfileSettingsRepository(
      storage: storage,
    );
    final loaded = await restartedRepository.load();

    expect(loaded.locationPreference, LocationPreference.defaultCity);
    expect(loaded.defaultCityId, 'denver-co');
    expect(loaded.budget, BudgetPreference.value);
    expect(loaded.distanceMiles, 25);
    expect(loaded.setting, SettingPreference.outdoor);
    expect(loaded.familyFriendly, isTrue);
    expect(loaded.petFriendly, isTrue);
    expect(loaded.accessibilityPreferred, isTrue);
  });

  test('invalid persisted settings safely return defaults', () async {
    final storage = _MemoryProfileSettingsStorage()
      ..values[LocalProfileSettingsRepository.settingsKey] = 'not-json';
    final repository = LocalProfileSettingsRepository(storage: storage);

    final loaded = await repository.load();

    expect(loaded.locationPreference, LocationPreference.currentLocation);
    expect(loaded.defaultCity.label, 'Austin, TX');
    expect(loaded.distanceMiles, 10);
  });
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
