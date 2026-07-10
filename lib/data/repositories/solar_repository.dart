import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/api_client.dart';
import '../models/backend_models.dart';
import 'backend_response_validation.dart';

final solarRepositoryProvider = Provider<SolarRepository>((ref) {
  return ResilientSolarRepository(
    BackendSolarRepository(ref.watch(backendApiClientProvider)),
    const DemoSolarRepository(),
  );
});

abstract interface class SolarRepository {
  Future<SolarCheckResult> solarCheck(String address);
}

class BackendSolarRepository implements SolarRepository {
  const BackendSolarRepository(this._client);

  final BackendApiClient _client;

  @override
  Future<SolarCheckResult> solarCheck(String address) async {
    final trimmedAddress = address.trim();
    if (trimmedAddress.isEmpty) {
      throw ArgumentError.value(address, 'address', 'Must not be empty');
    }
    final payload = await _client.call('solarCheck', {
      'address': trimmedAddress,
    });
    _validateSolarPayload(payload);
    return SolarCheckResult.fromJson(payload, requestedAddress: trimmedAddress);
  }
}

class ResilientSolarRepository implements SolarRepository {
  const ResilientSolarRepository(this._primary, this._fallback);

  final SolarRepository _primary;
  final SolarRepository _fallback;

  @override
  Future<SolarCheckResult> solarCheck(String address) async {
    try {
      return await _primary.solarCheck(address);
    } catch (error) {
      if (!canUseDemoFallback(error)) {
        rethrow;
      }
      final result = await _fallback.solarCheck(address);
      return SolarCheckResult(
        available: false,
        address: result.address,
        status: result.status,
        reason: error is BackendException ? error.userMessage : result.reason,
        isDemo: true,
      );
    }
  }
}

class DemoSolarRepository implements SolarRepository {
  const DemoSolarRepository();

  @override
  Future<SolarCheckResult> solarCheck(String address) async {
    return SolarCheckResult(
      available: false,
      address: address.trim(),
      status: 'demo_unavailable',
      reason:
          'Solar analysis is unavailable. No suitability or savings estimate was performed.',
      isDemo: true,
    );
  }
}

void _validateSolarPayload(Map<String, dynamic> payload) {
  const endpoint = 'solarCheck';
  final available = requireResponseBool(
    payload,
    'available',
    endpoint: endpoint,
  );
  requireResponseString(payload, 'status', endpoint: endpoint);
  requireResponseString(payload, 'address', endpoint: endpoint);
  if (!available) {
    requireResponseString(payload, 'reason', endpoint: endpoint);
    return;
  }

  final location = requireResponseMap(
    payload['location'],
    endpoint: endpoint,
    field: 'location',
  );
  requireResponseNumber(location, 'latitude', endpoint: endpoint);
  requireResponseNumber(location, 'longitude', endpoint: endpoint);
  requireResponseMap(
    payload['buildingInsights'],
    endpoint: endpoint,
    field: 'buildingInsights',
  );
}
