import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/profile_settings_repository.dart';
import '../domain/profile_settings.dart';

final profileSettingsRepositoryProvider = Provider<ProfileSettingsRepository>((
  ref,
) {
  return const LocalProfileSettingsRepository(
    storage: SharedPreferencesProfileSettingsStorage(),
  );
});

final profileSettingsProvider =
    AsyncNotifierProvider<ProfileSettingsController, ProfileSettings>(
      ProfileSettingsController.new,
    );

class ProfileSettingsController extends AsyncNotifier<ProfileSettings> {
  ProfileSettingsRepository get _repository =>
      ref.read(profileSettingsRepositoryProvider);

  @override
  Future<ProfileSettings> build() => _repository.load();

  Future<void> setLocationPreference(LocationPreference preference) {
    return _update(
      (current) => current.copyWith(locationPreference: preference),
    );
  }

  Future<void> setDefaultCity(String cityId) {
    return _update((current) => current.copyWith(defaultCityId: cityId));
  }

  Future<void> setBudget(BudgetPreference budget) {
    return _update((current) => current.copyWith(budget: budget));
  }

  Future<void> setDistance(int miles) {
    return _update((current) => current.copyWith(distanceMiles: miles));
  }

  Future<void> setSetting(SettingPreference setting) {
    return _update((current) => current.copyWith(setting: setting));
  }

  Future<void> setFamilyFriendly(bool enabled) {
    return _update((current) => current.copyWith(familyFriendly: enabled));
  }

  Future<void> setPetFriendly(bool enabled) {
    return _update((current) => current.copyWith(petFriendly: enabled));
  }

  Future<void> setAccessibilityPreferred(bool enabled) {
    return _update(
      (current) => current.copyWith(accessibilityPreferred: enabled),
    );
  }

  Future<void> _update(
    ProfileSettings Function(ProfileSettings) transform,
  ) async {
    final current = state.value ?? await future;
    final next = transform(current);
    state = AsyncData(next);
    try {
      await _repository.save(next);
    } catch (error, stackTrace) {
      state = AsyncData(current);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}
