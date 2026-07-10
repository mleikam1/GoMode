import 'package:shared_preferences/shared_preferences.dart';

abstract interface class SavedLocalStorage {
  Future<String?> readString(String key);

  Future<bool?> readBool(String key);

  Future<void> writeString(String key, String value);

  Future<void> writeBool(String key, bool value);
}

class SharedPreferencesSavedLocalStorage implements SavedLocalStorage {
  const SharedPreferencesSavedLocalStorage();

  @override
  Future<String?> readString(String key) async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(key);
  }

  @override
  Future<bool?> readBool(String key) async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(key);
  }

  @override
  Future<void> writeString(String key, String value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(key, value);
  }

  @override
  Future<void> writeBool(String key, bool value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(key, value);
  }
}
