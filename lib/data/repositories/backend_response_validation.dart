import '../../services/api_client.dart';

Map<String, dynamic> requireResponseMap(
  Object? value, {
  required String endpoint,
  required String field,
}) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    try {
      return Map<String, dynamic>.from(value);
    } on TypeError {
      // Fall through to the consistent bad-response error below.
    }
  }
  throwBadBackendResponse(endpoint, '$field must be an object');
}

List<Object?> requireResponseList(
  Object? value, {
  required String endpoint,
  required String field,
}) {
  if (value is List) {
    return value.cast<Object?>();
  }
  throwBadBackendResponse(endpoint, '$field must be a list');
}

String requireResponseString(
  Map<String, dynamic> value,
  String field, {
  required String endpoint,
}) {
  final result = value[field];
  if (result is String && result.trim().isNotEmpty) {
    return result;
  }
  throwBadBackendResponse(endpoint, '$field must be a non-empty string');
}

num requireResponseNumber(
  Map<String, dynamic> value,
  String field, {
  required String endpoint,
}) {
  final result = value[field];
  if (result is num && result.isFinite) {
    return result;
  }
  throwBadBackendResponse(endpoint, '$field must be a finite number');
}

bool requireResponseBool(
  Map<String, dynamic> value,
  String field, {
  required String endpoint,
}) {
  final result = value[field];
  if (result is bool) {
    return result;
  }
  throwBadBackendResponse(endpoint, '$field must be a boolean');
}

void validatePlaceResponse(
  Map<String, dynamic> place, {
  required String endpoint,
  required String field,
}) {
  requireResponseString(place, 'id', endpoint: endpoint);
  final displayName = requireResponseMap(
    place['displayName'],
    endpoint: endpoint,
    field: '$field.displayName',
  );
  requireResponseString(displayName, 'text', endpoint: endpoint);

  if (place['location'] case final location?) {
    final locationMap = requireResponseMap(
      location,
      endpoint: endpoint,
      field: '$field.location',
    );
    requireResponseNumber(locationMap, 'latitude', endpoint: endpoint);
    requireResponseNumber(locationMap, 'longitude', endpoint: endpoint);
  }
  if (place['types'] case final types?) {
    final values = requireResponseList(
      types,
      endpoint: endpoint,
      field: '$field.types',
    );
    if (values.any((value) => value is! String)) {
      throwBadBackendResponse(endpoint, '$field.types must contain strings');
    }
  }
  if (place['photos'] case final photos?) {
    final values = requireResponseList(
      photos,
      endpoint: endpoint,
      field: '$field.photos',
    );
    for (var index = 0; index < values.length; index++) {
      final photo = requireResponseMap(
        values[index],
        endpoint: endpoint,
        field: '$field.photos[$index]',
      );
      requireResponseString(photo, 'name', endpoint: endpoint);
    }
  }
}

void validateRouteResponse(
  Map<String, dynamic> route, {
  required String endpoint,
  required String field,
}) {
  requireResponseNumber(route, 'distanceMeters', endpoint: endpoint);
  requireResponseNumber(route, 'durationSeconds', endpoint: endpoint);
  if (route['encodedPolyline'] case final encodedPolyline?) {
    if (encodedPolyline is! String || encodedPolyline.isEmpty) {
      throwBadBackendResponse(
        endpoint,
        '$field.encodedPolyline must be a non-empty string',
      );
    }
  }
}

Never throwBadBackendResponse(String endpoint, String problem) {
  throw BackendException(
    kind: BackendFailureKind.badResponse,
    userMessage: 'The server returned an unexpected response.',
    code: endpoint,
    cause: FormatException(problem),
  );
}
