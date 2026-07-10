import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gomode/services/api_client.dart';
import 'package:gomode/services/backend_response_cache.dart';

void main() {
  test('reuses canonical cached discovery responses until expiry', () async {
    var now = DateTime.utc(2026, 7, 10, 12);
    final delegate = _CountingClient();
    final client = CachedBackendApiClient.withCache(
      delegate,
      _MemoryCache(),
      now: () => now,
    );

    final first = await client.call('searchPlaces', {
      'modeId': 'food-wheel',
      'latitude': 30.2,
      'filters': {'open': true, 'distance': 5},
    });
    final second = await client.call('searchPlaces', {
      'filters': {'distance': 5, 'open': true},
      'latitude': 30.2,
      'modeId': 'food-wheel',
    });

    expect(second, first);
    expect(delegate.calls, 1);

    now = now.add(const Duration(minutes: 11));
    await client.call('searchPlaces', {
      'modeId': 'food-wheel',
      'latitude': 30.2,
      'filters': {'open': true, 'distance': 5},
    });
    expect(delegate.calls, 2);
  });

  test(
    'coalesces matching in-flight calls and skips session endpoints',
    () async {
      final completer = Completer<Map<String, dynamic>>();
      final delegate = _CountingClient(response: completer.future);
      final client = CachedBackendApiClient.withCache(delegate, _MemoryCache());

      final first = client.call('roadTripStops', {'origin': 'Austin'});
      final second = client.call('roadTripStops', {'origin': 'Austin'});
      await Future<void>.delayed(Duration.zero);
      expect(delegate.calls, 1);

      completer.complete({'stops': <Object?>[]});
      expect(await first, await second);

      await client.call('autocomplete', {'text': 'Aus', 'sessionToken': 'one'});
      await client.call('autocomplete', {'text': 'Aus', 'sessionToken': 'one'});
      expect(delegate.calls, 3);
    },
  );
}

class _CountingClient implements BackendApiClient {
  _CountingClient({this._response});

  final Future<Map<String, dynamic>>? _response;
  int calls = 0;

  @override
  bool get isConfigured => true;

  @override
  Future<Map<String, dynamic>> call(
    String functionName,
    Map<String, dynamic> input, {
    bool retryTransient = true,
  }) async {
    calls += 1;
    return _response ?? {'call': calls, 'function': functionName};
  }
}

class _MemoryCache implements BackendResponseCache {
  final Map<String, CachedBackendResponse> values = {};

  @override
  Future<CachedBackendResponse?> read(String key) async => values[key];

  @override
  Future<void> write(String key, CachedBackendResponse value) async {
    values[key] = value;
  }
}
