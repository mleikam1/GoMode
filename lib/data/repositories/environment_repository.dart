import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/api_client.dart';
import '../models/backend_models.dart';
import 'backend_response_validation.dart';

final environmentRepositoryProvider = Provider<EnvironmentRepository>((ref) {
  return ResilientEnvironmentRepository(
    BackendEnvironmentRepository(ref.watch(backendApiClientProvider)),
    const DemoEnvironmentRepository(),
  );
});

abstract interface class EnvironmentRepository {
  Future<AirQualityReport> airQuality({
    required double latitude,
    required double longitude,
    bool includeForecast = false,
    int forecastHours = 6,
  });

  Future<PollenReport> pollen({
    required double latitude,
    required double longitude,
    int days = 3,
  });
}

class BackendEnvironmentRepository implements EnvironmentRepository {
  const BackendEnvironmentRepository(this._client);

  final BackendApiClient _client;

  @override
  Future<AirQualityReport> airQuality({
    required double latitude,
    required double longitude,
    bool includeForecast = false,
    int forecastHours = 6,
  }) async {
    final payload = await _client.call('airQuality', {
      'latitude': latitude,
      'longitude': longitude,
      'includeForecast': includeForecast,
      'forecastHours': forecastHours.clamp(1, 24),
    });
    _validateAirQualityPayload(payload);
    return AirQualityReport.fromJson(
      payload,
      requestedLocation: GeoPoint(latitude: latitude, longitude: longitude),
    );
  }

  @override
  Future<PollenReport> pollen({
    required double latitude,
    required double longitude,
    int days = 3,
  }) async {
    final payload = await _client.call('pollen', {
      'latitude': latitude,
      'longitude': longitude,
      'days': days.clamp(1, 5),
    });
    _validatePollenPayload(payload);
    return PollenReport.fromJson(
      payload,
      requestedLocation: GeoPoint(latitude: latitude, longitude: longitude),
    );
  }
}

class ResilientEnvironmentRepository implements EnvironmentRepository {
  const ResilientEnvironmentRepository(this._primary, this._fallback);

  final EnvironmentRepository _primary;
  final EnvironmentRepository _fallback;

  @override
  Future<AirQualityReport> airQuality({
    required double latitude,
    required double longitude,
    bool includeForecast = false,
    int forecastHours = 6,
  }) async {
    try {
      return await _primary.airQuality(
        latitude: latitude,
        longitude: longitude,
        includeForecast: includeForecast,
        forecastHours: forecastHours,
      );
    } catch (error) {
      if (!canUseDemoFallback(error)) {
        rethrow;
      }
      final result = await _fallback.airQuality(
        latitude: latitude,
        longitude: longitude,
        includeForecast: includeForecast,
        forecastHours: forecastHours,
      );
      return AirQualityReport(
        latitude: result.latitude,
        longitude: result.longitude,
        currentDateTime: result.currentDateTime,
        aqi: result.aqi,
        category: result.category,
        dominantPollutant: result.dominantPollutant,
        healthRecommendation: result.healthRecommendation,
        forecast: result.forecast,
        forecastAvailable: result.forecastAvailable,
        forecastStatus: result.forecastStatus,
        isDemo: true,
        fallbackMessage: _message(error),
      );
    }
  }

  @override
  Future<PollenReport> pollen({
    required double latitude,
    required double longitude,
    int days = 3,
  }) async {
    try {
      return await _primary.pollen(
        latitude: latitude,
        longitude: longitude,
        days: days,
      );
    } catch (error) {
      if (!canUseDemoFallback(error)) {
        rethrow;
      }
      final result = await _fallback.pollen(
        latitude: latitude,
        longitude: longitude,
        days: days,
      );
      return PollenReport(
        latitude: result.latitude,
        longitude: result.longitude,
        days: result.days,
        isDemo: true,
        fallbackMessage: _message(error),
      );
    }
  }
}

class DemoEnvironmentRepository implements EnvironmentRepository {
  const DemoEnvironmentRepository();

  @override
  Future<AirQualityReport> airQuality({
    required double latitude,
    required double longitude,
    bool includeForecast = false,
    int forecastHours = 6,
  }) async {
    return AirQualityReport(
      latitude: latitude,
      longitude: longitude,
      category: 'Live AQI unavailable',
      healthRecommendation:
          'Check an official local air-quality source before changing plans.',
      forecast: const [],
      forecastStatus: 'demo_unavailable',
      isDemo: true,
    );
  }

  @override
  Future<PollenReport> pollen({
    required double latitude,
    required double longitude,
    int days = 3,
  }) async {
    return PollenReport(
      latitude: latitude,
      longitude: longitude,
      days: const [],
      isDemo: true,
    );
  }
}

void _validateAirQualityPayload(Map<String, dynamic> payload) {
  const endpoint = 'airQuality';
  requireResponseNumber(payload, 'latitude', endpoint: endpoint);
  requireResponseNumber(payload, 'longitude', endpoint: endpoint);
  final current = requireResponseMap(
    payload['current'],
    endpoint: endpoint,
    field: 'current',
  );
  _validateAirPoint(current, endpoint: endpoint, field: 'current');
  final forecast = requireResponseList(
    payload['forecast'],
    endpoint: endpoint,
    field: 'forecast',
  );
  for (var index = 0; index < forecast.length; index++) {
    final point = requireResponseMap(
      forecast[index],
      endpoint: endpoint,
      field: 'forecast[$index]',
    );
    _validateAirPoint(point, endpoint: endpoint, field: 'forecast[$index]');
  }
  requireResponseBool(payload, 'forecastAvailable', endpoint: endpoint);
  requireResponseString(payload, 'forecastStatus', endpoint: endpoint);
}

void _validateAirPoint(
  Map<String, dynamic> point, {
  required String endpoint,
  required String field,
}) {
  if (point['dateTime'] case final dateTime?) {
    if (dateTime is! String || DateTime.tryParse(dateTime) == null) {
      throwBadBackendResponse(endpoint, '$field.dateTime must be ISO-8601');
    }
  }
  _validateOptionalNumber(point, 'aqi', endpoint: endpoint, field: field);
  _validateOptionalString(point, 'category', endpoint: endpoint, field: field);
  _validateOptionalString(
    point,
    'dominantPollutant',
    endpoint: endpoint,
    field: field,
  );
  _validateOptionalString(
    point,
    'healthRecommendation',
    endpoint: endpoint,
    field: field,
  );
}

void _validatePollenPayload(Map<String, dynamic> payload) {
  const endpoint = 'pollen';
  requireResponseNumber(payload, 'latitude', endpoint: endpoint);
  requireResponseNumber(payload, 'longitude', endpoint: endpoint);
  final days = requireResponseList(
    payload['dailyInfo'],
    endpoint: endpoint,
    field: 'dailyInfo',
  );
  for (var dayIndex = 0; dayIndex < days.length; dayIndex++) {
    final day = requireResponseMap(
      days[dayIndex],
      endpoint: endpoint,
      field: 'dailyInfo[$dayIndex]',
    );
    final date = requireResponseMap(
      day['date'],
      endpoint: endpoint,
      field: 'dailyInfo[$dayIndex].date',
    );
    requireResponseNumber(date, 'year', endpoint: endpoint);
    requireResponseNumber(date, 'month', endpoint: endpoint);
    requireResponseNumber(date, 'day', endpoint: endpoint);
    final typeInfo = requireResponseList(
      day['pollenTypeInfo'],
      endpoint: endpoint,
      field: 'dailyInfo[$dayIndex].pollenTypeInfo',
    );
    for (var typeIndex = 0; typeIndex < typeInfo.length; typeIndex++) {
      final info = requireResponseMap(
        typeInfo[typeIndex],
        endpoint: endpoint,
        field: 'dailyInfo[$dayIndex].pollenTypeInfo[$typeIndex]',
      );
      final code = info['code'];
      final displayName = info['displayName'];
      if ((code is! String || code.trim().isEmpty) &&
          (displayName is! String || displayName.trim().isEmpty)) {
        throwBadBackendResponse(
          endpoint,
          'pollen type must have a code or displayName',
        );
      }
      if (info['inSeason'] case final inSeason?) {
        if (inSeason is! bool) {
          throwBadBackendResponse(endpoint, 'inSeason must be a boolean');
        }
      }
      if (info['indexInfo'] case final rawIndex?) {
        final indexInfo = requireResponseMap(
          rawIndex,
          endpoint: endpoint,
          field: 'dailyInfo[$dayIndex].pollenTypeInfo[$typeIndex].indexInfo',
        );
        _validateOptionalNumber(
          indexInfo,
          'value',
          endpoint: endpoint,
          field: 'indexInfo',
        );
        _validateOptionalString(
          indexInfo,
          'category',
          endpoint: endpoint,
          field: 'indexInfo',
        );
      }
    }
  }
}

void _validateOptionalNumber(
  Map<String, dynamic> value,
  String key, {
  required String endpoint,
  required String field,
}) {
  if (value[key] case final candidate?) {
    if (candidate is! num || !candidate.isFinite) {
      throwBadBackendResponse(endpoint, '$field.$key must be a number');
    }
  }
}

void _validateOptionalString(
  Map<String, dynamic> value,
  String key, {
  required String endpoint,
  required String field,
}) {
  if (value[key] case final candidate?) {
    if (candidate is! String || candidate.trim().isEmpty) {
      throwBadBackendResponse(endpoint, '$field.$key must be a string');
    }
  }
}

String _message(Object error) {
  return error is BackendException
      ? error.userMessage
      : 'Live environmental data is temporarily unavailable.';
}
