import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'backend_response_cache.dart';

const backendBaseUrl = String.fromEnvironment('GOMODE_BACKEND_BASE_URL');
const firebaseFunctionsRegion = String.fromEnvironment(
  'GOMODE_FIREBASE_FUNCTIONS_REGION',
  defaultValue: 'us-central1',
);
const functionsEmulatorHost = String.fromEnvironment(
  'GOMODE_FUNCTIONS_EMULATOR_HOST',
);
const functionsEmulatorPort = int.fromEnvironment(
  'GOMODE_FUNCTIONS_EMULATOR_PORT',
  defaultValue: 5001,
);

bool firebaseBackendReady = false;

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: const {'Accept': 'application/json'},
    ),
  );

  ref.onDispose(dio.close);
  return dio;
});

final backendApiClientProvider = Provider<BackendApiClient>((ref) {
  final BackendApiClient client;
  if (firebaseBackendReady && Firebase.apps.isNotEmpty) {
    final functions = FirebaseFunctions.instanceFor(
      region: firebaseFunctionsRegion,
    );
    if (kDebugMode && functionsEmulatorHost.isNotEmpty) {
      functions.useFunctionsEmulator(
        functionsEmulatorHost,
        functionsEmulatorPort,
      );
    }
    client = FirebaseCallableApiClient(functions);
  } else if (kDebugMode && backendBaseUrl.isNotEmpty) {
    client = HttpBackendApiClient(
      dio: ref.watch(dioProvider),
      baseUrl: backendBaseUrl,
    );
  } else {
    client = const UnconfiguredBackendApiClient();
  }
  return client.isConfigured ? CachedBackendApiClient(client) : client;
});

abstract interface class BackendApiClient {
  bool get isConfigured;

  Future<Map<String, dynamic>> call(
    String functionName,
    Map<String, dynamic> input, {
    bool retryTransient = true,
  });
}

/// Caches only idempotent discovery calls. Autocomplete, Place Details, and
/// photo calls stay uncached so autocomplete sessions and signed URLs retain
/// their expected lifecycle.
class CachedBackendApiClient implements BackendApiClient {
  CachedBackendApiClient(this._delegate, {DateTime Function()? now})
    : _cache = const SharedPreferencesBackendResponseCache(),
      _now = now ?? DateTime.now;

  CachedBackendApiClient.withCache(
    this._delegate,
    this._cache, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final BackendApiClient _delegate;
  final BackendResponseCache _cache;
  final DateTime Function() _now;
  final Map<String, Future<Map<String, dynamic>>> _inFlight = {};

  @override
  bool get isConfigured => _delegate.isConfigured;

  @override
  Future<Map<String, dynamic>> call(
    String functionName,
    Map<String, dynamic> input, {
    bool retryTransient = true,
  }) async {
    final ttl = _cacheTtlFor(functionName);
    if (ttl == null) {
      return _delegate.call(
        functionName,
        input,
        retryTransient: retryTransient,
      );
    }

    final signature = jsonEncode(_canonicalizeCacheInput(input));
    final key = 'gomode.backend.v1.$functionName.${_fnv1a64(signature)}';
    CachedBackendResponse? cached;
    try {
      cached = await _cache.read(key);
    } catch (_) {
      // A local cache failure must never block a live result.
    }
    final now = _now().toUtc();
    if (cached != null &&
        cached.signature == signature &&
        cached.expiresAt.isAfter(now)) {
      return Map<String, dynamic>.from(cached.payload);
    }

    final existing = _inFlight[key];
    if (existing != null) {
      return existing;
    }
    final future = () async {
      final response = await _delegate.call(
        functionName,
        input,
        retryTransient: retryTransient,
      );
      try {
        await _cache.write(
          key,
          CachedBackendResponse(
            signature: signature,
            expiresAt: now.add(ttl),
            payload: response,
          ),
        );
      } catch (_) {
        // Return the live response even when local persistence is unavailable.
      }
      return response;
    }();
    _inFlight[key] = future;
    try {
      return await future;
    } finally {
      if (identical(_inFlight[key], future)) {
        _inFlight.remove(key);
      }
    }
  }
}

Duration? _cacheTtlFor(String functionName) {
  return switch (functionName) {
    'searchPlaces' => const Duration(minutes: 10),
    'computeRoute' || 'roadTripStops' => const Duration(minutes: 15),
    'airQuality' => const Duration(minutes: 15),
    'pollen' => const Duration(hours: 6),
    'solarCheck' => const Duration(hours: 24),
    _ => null,
  };
}

Object? _canonicalizeCacheInput(Object? value) {
  if (value is Map) {
    final keys = value.keys.map((key) => '$key').toList()..sort();
    return <String, Object?>{
      for (final key in keys) key: _canonicalizeCacheInput(value[key]),
    };
  }
  if (value is Iterable) {
    return [for (final item in value) _canonicalizeCacheInput(item)];
  }
  return value;
}

String _fnv1a64(String value) {
  var hash = BigInt.parse('14695981039346656037');
  final prime = BigInt.from(1099511628211);
  final mask = (BigInt.one << 64) - BigInt.one;
  for (final byte in utf8.encode(value)) {
    hash = ((hash ^ BigInt.from(byte)) * prime) & mask;
  }
  return hash.toRadixString(16).padLeft(16, '0');
}

enum BackendFailureKind {
  unconfigured,
  invalidRequest,
  unauthenticated,
  permissionDenied,
  failedPrecondition,
  notFound,
  timeout,
  rateLimited,
  unavailable,
  badResponse,
  unknown,
}

class BackendException implements Exception {
  const BackendException({
    required this.kind,
    required this.userMessage,
    this.code,
    this.statusCode,
    this.cause,
  });

  final BackendFailureKind kind;
  final String userMessage;
  final String? code;
  final int? statusCode;
  final Object? cause;

  @override
  String toString() => 'BackendException($kind, $code)';
}

class UnconfiguredBackendApiClient implements BackendApiClient {
  const UnconfiguredBackendApiClient();

  @override
  bool get isConfigured => false;

  @override
  Future<Map<String, dynamic>> call(
    String functionName,
    Map<String, dynamic> input, {
    bool retryTransient = true,
  }) {
    throw const BackendException(
      kind: BackendFailureKind.unconfigured,
      userMessage: 'Live results are not configured on this device.',
    );
  }
}

class FirebaseCallableApiClient implements BackendApiClient {
  const FirebaseCallableApiClient(this._functions);

  final FirebaseFunctions _functions;

  @override
  bool get isConfigured => true;

  @override
  Future<Map<String, dynamic>> call(
    String functionName,
    Map<String, dynamic> input, {
    bool retryTransient = true,
  }) async {
    final callable = _functions.httpsCallable(
      functionName,
      options: HttpsCallableOptions(timeout: _timeoutFor(functionName)),
    );
    final maxAttempts = retryTransient ? 2 : 1;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final result = await callable.call<Map<String, dynamic>>(input);
        return _asStringMap(result.data, functionName);
      } on FirebaseFunctionsException catch (error) {
        final kind = _firebaseFailureKind(error.code);
        if (attempt < maxAttempts && _isTransient(kind)) {
          await Future<void>.delayed(const Duration(milliseconds: 250));
          continue;
        }
        throw BackendException(
          kind: kind,
          code: error.code,
          userMessage: _firebaseUserMessage(error.code),
          cause: error,
        );
      } catch (error) {
        if (error is BackendException) {
          rethrow;
        }
        throw BackendException(
          kind: BackendFailureKind.unknown,
          userMessage: 'Live results are temporarily unavailable.',
          cause: error,
        );
      }
    }
    throw const BackendException(
      kind: BackendFailureKind.unavailable,
      userMessage: 'Live results are temporarily unavailable.',
    );
  }
}

/// Dev-only transport for a callable-protocol emulator or local proxy.
/// Production uses [FirebaseCallableApiClient] so App Check is attached.
class HttpBackendApiClient implements BackendApiClient {
  HttpBackendApiClient({
    required this.dio,
    required String baseUrl,
    this.maxAttempts = 3,
    this.retryDelay = const Duration(milliseconds: 250),
  }) : _baseUrl = baseUrl.replaceFirst(RegExp(r'/+$'), '');

  final Dio dio;
  final String _baseUrl;
  final int maxAttempts;
  final Duration retryDelay;

  @override
  bool get isConfigured => _baseUrl.isNotEmpty;

  @override
  Future<Map<String, dynamic>> call(
    String functionName,
    Map<String, dynamic> input, {
    bool retryTransient = true,
  }) async {
    DioException? lastError;
    final attempts = retryTransient ? maxAttempts : 1;
    for (var attempt = 1; attempt <= attempts; attempt++) {
      try {
        final response = await dio.post<Object?>(
          '$_baseUrl/$functionName',
          data: {'data': input},
          options: Options(receiveTimeout: _timeoutFor(functionName)),
        );
        final body = _asStringMap(response.data, functionName);
        final error = body['error'];
        if (error is Map) {
          final errorMap = Map<String, dynamic>.from(error);
          final code = errorMap['code']?.toString();
          throw BackendException(
            kind: _firebaseFailureKind(code ?? 'unknown'),
            code: code,
            statusCode: response.statusCode,
            userMessage: _firebaseUserMessage(code ?? 'unknown'),
          );
        }
        final payload = body['data'] ?? body['result'] ?? body;
        return _asStringMap(payload, functionName);
      } on DioException catch (error) {
        lastError = error;
        if (!_shouldRetry(error) || attempt == attempts) {
          throw _fromDio(error);
        }
        await Future<void>.delayed(retryDelay * attempt);
      }
    }
    throw _fromDio(lastError!);
  }

  bool _shouldRetry(DioException error) {
    final status = error.response?.statusCode;
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError ||
        status == 429 ||
        (status != null && status >= 500);
  }

  BackendException _fromDio(DioException error) {
    final status = error.response?.statusCode;
    final kind = switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => BackendFailureKind.timeout,
      _ when status == 400 => BackendFailureKind.invalidRequest,
      _ when status == 401 => BackendFailureKind.unauthenticated,
      _ when status == 403 => BackendFailureKind.permissionDenied,
      _ when status == 412 => BackendFailureKind.failedPrecondition,
      _ when status == 404 => BackendFailureKind.notFound,
      _ when status == 429 => BackendFailureKind.rateLimited,
      _ when status != null && status >= 500 => BackendFailureKind.unavailable,
      _ => BackendFailureKind.unavailable,
    };
    return BackendException(
      kind: kind,
      statusCode: status,
      userMessage: switch (kind) {
        BackendFailureKind.timeout =>
          'Live results took too long. Please try again.',
        BackendFailureKind.failedPrecondition =>
          'Live results are not configured correctly. Please try again later.',
        _ => 'Live results are temporarily unavailable.',
      },
      cause: error,
    );
  }
}

Duration _timeoutFor(String functionName) {
  return switch (functionName) {
    'roadTripStops' ||
    'airQuality' ||
    'solarCheck' => const Duration(seconds: 30),
    _ => const Duration(seconds: 15),
  };
}

bool _isTransient(BackendFailureKind kind) {
  return kind == BackendFailureKind.timeout ||
      kind == BackendFailureKind.rateLimited ||
      kind == BackendFailureKind.unavailable;
}

Map<String, dynamic> _asStringMap(Object? value, String functionName) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  throw BackendException(
    kind: BackendFailureKind.badResponse,
    userMessage: 'The server returned an unexpected response.',
    code: functionName,
  );
}

BackendFailureKind _firebaseFailureKind(String code) {
  return switch (code) {
    'invalid-argument' => BackendFailureKind.invalidRequest,
    'unauthenticated' => BackendFailureKind.unauthenticated,
    'permission-denied' => BackendFailureKind.permissionDenied,
    'failed-precondition' => BackendFailureKind.failedPrecondition,
    'not-found' => BackendFailureKind.notFound,
    'deadline-exceeded' => BackendFailureKind.timeout,
    'resource-exhausted' => BackendFailureKind.rateLimited,
    'unavailable' || 'internal' => BackendFailureKind.unavailable,
    _ => BackendFailureKind.unknown,
  };
}

String _firebaseUserMessage(String code) {
  return switch (code) {
    'invalid-argument' => 'Some search details were not valid.',
    'unauthenticated' ||
    'permission-denied' => 'Live results could not be verified on this device.',
    'failed-precondition' =>
      'Live results are not configured correctly. Please try again later.',
    'not-found' => 'That result is no longer available.',
    'deadline-exceeded' => 'Live results took too long. Please try again.',
    'resource-exhausted' => 'Live results are busy. Please try again later.',
    _ => 'Live results are temporarily unavailable.',
  };
}

bool canUseDemoFallback(Object error) {
  if (error is! BackendException) {
    return false;
  }
  return switch (error.kind) {
    BackendFailureKind.unconfigured ||
    BackendFailureKind.timeout ||
    BackendFailureKind.rateLimited ||
    BackendFailureKind.unavailable ||
    BackendFailureKind.badResponse ||
    BackendFailureKind.unknown => true,
    _ => false,
  };
}
