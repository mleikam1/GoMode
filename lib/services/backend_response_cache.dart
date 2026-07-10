import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class CachedBackendResponse {
  const CachedBackendResponse({
    required this.signature,
    required this.expiresAt,
    required this.payload,
  });

  final String signature;
  final DateTime expiresAt;
  final Map<String, dynamic> payload;

  Map<String, dynamic> toJson() => {
    'signature': signature,
    'expiresAt': expiresAt.toUtc().toIso8601String(),
    'payload': payload,
  };

  static CachedBackendResponse? fromJson(Object? value) {
    if (value is! Map) {
      return null;
    }
    final json = Map<String, dynamic>.from(value);
    final signature = json['signature'];
    final expiresAt = DateTime.tryParse('${json['expiresAt'] ?? ''}');
    final payload = json['payload'];
    if (signature is! String || expiresAt == null || payload is! Map) {
      return null;
    }
    return CachedBackendResponse(
      signature: signature,
      expiresAt: expiresAt,
      payload: Map<String, dynamic>.from(payload),
    );
  }
}

abstract interface class BackendResponseCache {
  Future<CachedBackendResponse?> read(String key);

  Future<void> write(String key, CachedBackendResponse value);
}

class SharedPreferencesBackendResponseCache implements BackendResponseCache {
  const SharedPreferencesBackendResponseCache();

  static const _keyIndex = 'gomode.backend.v1.keys';
  static const _maxEntries = 32;

  @override
  Future<CachedBackendResponse?> read(String key) async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(key);
    if (raw == null) {
      return null;
    }
    try {
      return CachedBackendResponse.fromJson(jsonDecode(raw));
    } catch (_) {
      await preferences.remove(key);
      return null;
    }
  }

  @override
  Future<void> write(String key, CachedBackendResponse value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(key, jsonEncode(value.toJson()));
    final keys = preferences.getStringList(_keyIndex) ?? <String>[];
    keys
      ..remove(key)
      ..add(key);
    while (keys.length > _maxEntries) {
      final expiredKey = keys.removeAt(0);
      await preferences.remove(expiredKey);
    }
    await preferences.setStringList(_keyIndex, keys);
  }
}
