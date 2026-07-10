import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/profile_settings.dart';

abstract interface class ProfileSettingsStorage {
  Future<String?> read(String key);

  Future<void> write(String key, String value);
}

class SharedPreferencesProfileSettingsStorage
    implements ProfileSettingsStorage {
  const SharedPreferencesProfileSettingsStorage();

  @override
  Future<String?> read(String key) async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(key);
  }

  @override
  Future<void> write(String key, String value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(key, value);
  }
}

abstract interface class ProfileSettingsRepository {
  Future<ProfileSettings> load();

  Future<void> save(ProfileSettings settings);
}

class LocalProfileSettingsRepository implements ProfileSettingsRepository {
  const LocalProfileSettingsRepository({required this.storage});

  static const settingsKey = 'profile.settings.v1';

  final ProfileSettingsStorage storage;

  @override
  Future<ProfileSettings> load() async {
    try {
      final encoded = await storage.read(settingsKey);
      if (encoded == null || encoded.isEmpty) {
        return const ProfileSettings();
      }
      return ProfileSettings.fromJson(
        Map<String, Object?>.from(jsonDecode(encoded) as Map),
      );
    } catch (_) {
      return const ProfileSettings();
    }
  }

  @override
  Future<void> save(ProfileSettings settings) {
    return storage.write(settingsKey, jsonEncode(settings.toJson()));
  }
}
