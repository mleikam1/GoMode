import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/api_client.dart';
import '../models/backend_models.dart';
import 'backend_response_validation.dart';

final placesRepositoryProvider = Provider<PlacesRepository>((ref) {
  return ResilientPlacesRepository(
    BackendPlacesRepository(ref.watch(backendApiClientProvider)),
    const DemoPlacesRepository(),
  );
});

abstract interface class PlacesRepository {
  Future<PlaceSearchResult> searchPlaces({
    required double latitude,
    required double longitude,
    required String modeId,
    String? query,
    String? category,
    int radiusMeters = 8000,
    bool openNow = false,
    int maxResults = 10,
  });

  Future<PlaceDetailsResult> placeDetails(
    String placeId, {
    String? sessionToken,
  });

  Future<PlacePhotoResult> placePhoto(String photoName, {int maxWidthPx = 800});

  Future<AutocompleteResult> autocomplete({
    required String text,
    required String sessionToken,
    double? latitude,
    double? longitude,
    int? radiusMeters,
  });
}

class BackendPlacesRepository implements PlacesRepository {
  const BackendPlacesRepository(this._client);

  final BackendApiClient _client;

  @override
  Future<PlaceSearchResult> searchPlaces({
    required double latitude,
    required double longitude,
    required String modeId,
    String? query,
    String? category,
    int radiusMeters = 8000,
    bool openNow = false,
    int maxResults = 10,
  }) async {
    final payload = await _client.call('searchPlaces', {
      'latitude': latitude,
      'longitude': longitude,
      'modeId': modeId,
      if (query?.trim().isNotEmpty ?? false) 'query': query!.trim(),
      if (category?.trim().isNotEmpty ?? false) 'category': category!.trim(),
      'radius': radiusMeters.clamp(50, 50000),
      'openNow': openNow,
      'maxResults': maxResults.clamp(1, 20),
    });
    const endpoint = 'searchPlaces';
    final values = requireResponseList(
      payload['places'],
      endpoint: endpoint,
      field: 'places',
    );
    return PlaceSearchResult(
      places: [
        for (var index = 0; index < values.length; index++)
          PlaceSummary.fromJson(
            _validatedPlace(values[index], endpoint, 'places[$index]'),
          ),
      ],
    );
  }

  @override
  Future<PlaceDetailsResult> placeDetails(
    String placeId, {
    String? sessionToken,
  }) async {
    if (placeId.trim().isEmpty) {
      throw ArgumentError.value(placeId, 'placeId', 'Must not be empty');
    }
    final payload = await _client.call('placeDetails', {
      'placeId': placeId.trim(),
      if (sessionToken?.trim().isNotEmpty ?? false)
        'sessionToken': sessionToken!.trim(),
    });
    const endpoint = 'placeDetails';
    final place = _validatedPlace(payload['place'], endpoint, 'place');
    return PlaceDetailsResult(place: PlaceSummary.fromJson(place));
  }

  @override
  Future<PlacePhotoResult> placePhoto(
    String photoName, {
    int maxWidthPx = 800,
  }) async {
    if (photoName.trim().isEmpty) {
      throw ArgumentError.value(photoName, 'photoName', 'Must not be empty');
    }
    final payload = await _client.call('placePhoto', {
      'photoName': photoName.trim(),
      'maxWidthPx': maxWidthPx.clamp(64, 1200),
    });
    const endpoint = 'placePhoto';
    final urlText = requireResponseString(payload, 'url', endpoint: endpoint);
    final expiresAtText = requireResponseString(
      payload,
      'expiresAt',
      endpoint: endpoint,
    );
    final url = Uri.tryParse(urlText);
    final expiresAt = DateTime.tryParse(expiresAtText);
    if (url == null ||
        !url.hasScheme ||
        !url.hasAuthority ||
        (url.scheme != 'https' && url.scheme != 'http') ||
        expiresAt == null) {
      throwBadBackendResponse(endpoint, 'photo URL metadata is malformed');
    }
    return PlacePhotoResult(url: url, expiresAt: expiresAt);
  }

  @override
  Future<AutocompleteResult> autocomplete({
    required String text,
    required String sessionToken,
    double? latitude,
    double? longitude,
    int? radiusMeters,
  }) async {
    final trimmedText = text.trim();
    final trimmedToken = sessionToken.trim();
    if (trimmedText.isEmpty || trimmedToken.isEmpty) {
      return const AutocompleteResult(suggestions: []);
    }
    if ((latitude == null) != (longitude == null)) {
      throw ArgumentError('latitude and longitude must be provided together.');
    }
    final payload = await _client.call('autocomplete', {
      'text': trimmedText,
      'sessionToken': trimmedToken,
      'latitude': ?latitude,
      'longitude': ?longitude,
      if (radiusMeters != null) 'radius': radiusMeters.clamp(50, 50000),
    }, retryTransient: false);
    const endpoint = 'autocomplete';
    final values = requireResponseList(
      payload['suggestions'],
      endpoint: endpoint,
      field: 'suggestions',
    );
    return AutocompleteResult(
      suggestions: [
        for (var index = 0; index < values.length; index++)
          AutocompleteSuggestion.fromJson(
            _validatedSuggestion(values[index], endpoint, index),
          ),
      ],
    );
  }
}

Map<String, dynamic> _validatedPlace(
  Object? value,
  String endpoint,
  String field,
) {
  final place = requireResponseMap(value, endpoint: endpoint, field: field);
  validatePlaceResponse(place, endpoint: endpoint, field: field);
  return place;
}

Map<String, dynamic> _validatedSuggestion(
  Object? value,
  String endpoint,
  int index,
) {
  final suggestion = requireResponseMap(
    value,
    endpoint: endpoint,
    field: 'suggestions[$index]',
  );
  final prediction = requireResponseMap(
    suggestion['placePrediction'],
    endpoint: endpoint,
    field: 'suggestions[$index].placePrediction',
  );
  requireResponseString(prediction, 'placeId', endpoint: endpoint);
  final text = requireResponseMap(
    prediction['text'],
    endpoint: endpoint,
    field: 'suggestions[$index].placePrediction.text',
  );
  requireResponseString(text, 'text', endpoint: endpoint);
  return suggestion;
}

class ResilientPlacesRepository implements PlacesRepository {
  const ResilientPlacesRepository(this._primary, this._fallback);

  final PlacesRepository _primary;
  final PlacesRepository _fallback;

  @override
  Future<PlaceSearchResult> searchPlaces({
    required double latitude,
    required double longitude,
    required String modeId,
    String? query,
    String? category,
    int radiusMeters = 8000,
    bool openNow = false,
    int maxResults = 10,
  }) async {
    try {
      return await _primary.searchPlaces(
        latitude: latitude,
        longitude: longitude,
        modeId: modeId,
        query: query,
        category: category,
        radiusMeters: radiusMeters,
        openNow: openNow,
        maxResults: maxResults,
      );
    } catch (error) {
      if (!canUseDemoFallback(error)) {
        rethrow;
      }
      final result = await _fallback.searchPlaces(
        latitude: latitude,
        longitude: longitude,
        modeId: modeId,
        query: query,
        category: category,
        radiusMeters: radiusMeters,
        openNow: openNow,
        maxResults: maxResults,
      );
      return PlaceSearchResult(
        places: result.places,
        isDemo: true,
        fallbackMessage: _fallbackMessage(error),
      );
    }
  }

  @override
  Future<PlaceDetailsResult> placeDetails(
    String placeId, {
    String? sessionToken,
  }) async {
    try {
      return await _primary.placeDetails(placeId, sessionToken: sessionToken);
    } catch (error) {
      if (!canUseDemoFallback(error)) {
        rethrow;
      }
      final result = await _fallback.placeDetails(
        placeId,
        sessionToken: sessionToken,
      );
      return PlaceDetailsResult(
        place: result.place,
        isDemo: true,
        fallbackMessage: _fallbackMessage(error),
      );
    }
  }

  @override
  Future<PlacePhotoResult> placePhoto(
    String photoName, {
    int maxWidthPx = 800,
  }) async {
    try {
      return await _primary.placePhoto(photoName, maxWidthPx: maxWidthPx);
    } catch (error) {
      if (!canUseDemoFallback(error)) {
        rethrow;
      }
      return const PlacePhotoResult(url: null, isDemo: true);
    }
  }

  @override
  Future<AutocompleteResult> autocomplete({
    required String text,
    required String sessionToken,
    double? latitude,
    double? longitude,
    int? radiusMeters,
  }) async {
    try {
      return await _primary.autocomplete(
        text: text,
        sessionToken: sessionToken,
        latitude: latitude,
        longitude: longitude,
        radiusMeters: radiusMeters,
      );
    } catch (error) {
      if (!canUseDemoFallback(error)) {
        rethrow;
      }
      final result = await _fallback.autocomplete(
        text: text,
        sessionToken: sessionToken,
        latitude: latitude,
        longitude: longitude,
        radiusMeters: radiusMeters,
      );
      return AutocompleteResult(suggestions: result.suggestions, isDemo: true);
    }
  }
}

class DemoPlacesRepository implements PlacesRepository {
  const DemoPlacesRepository();

  static const _places = [
    PlaceSummary(
      id: 'demo-neighborhood-cafe',
      name: 'Neighborhood Cafe',
      address: 'Central Austin, TX',
      types: ['cafe', 'restaurant'],
      location: GeoPoint(latitude: 30.2684, longitude: -97.7421),
      rating: 4.7,
      userRatingCount: 328,
      openNow: null,
      primaryType: 'cafe',
    ),
    PlaceSummary(
      id: 'demo-shaded-park',
      name: 'Shaded Park Loop',
      address: 'Austin, TX',
      types: ['park', 'tourist_attraction'],
      location: GeoPoint(latitude: 30.2711, longitude: -97.7502),
      rating: 4.8,
      userRatingCount: 912,
      openNow: null,
      primaryType: 'park',
    ),
    PlaceSummary(
      id: 'demo-local-market',
      name: 'Local Market Hall',
      address: 'East Austin, TX',
      types: ['market', 'food'],
      location: GeoPoint(latitude: 30.2637, longitude: -97.7314),
      rating: 4.6,
      userRatingCount: 541,
      openNow: null,
      primaryType: 'market',
    ),
  ];

  @override
  Future<PlaceSearchResult> searchPlaces({
    required double latitude,
    required double longitude,
    required String modeId,
    String? query,
    String? category,
    int radiusMeters = 8000,
    bool openNow = false,
    int maxResults = 10,
  }) async {
    return PlaceSearchResult(
      places: _places.take(maxResults.clamp(1, _places.length)).toList(),
      isDemo: true,
    );
  }

  @override
  Future<PlaceDetailsResult> placeDetails(
    String placeId, {
    String? sessionToken,
  }) async {
    PlaceSummary? place;
    for (final item in _places) {
      if (item.id == placeId) {
        place = item;
        break;
      }
    }
    return PlaceDetailsResult(place: place ?? _places.first, isDemo: true);
  }

  @override
  Future<PlacePhotoResult> placePhoto(
    String photoName, {
    int maxWidthPx = 800,
  }) async {
    return const PlacePhotoResult(url: null, isDemo: true);
  }

  @override
  Future<AutocompleteResult> autocomplete({
    required String text,
    required String sessionToken,
    double? latitude,
    double? longitude,
    int? radiusMeters,
  }) async {
    if (text.trim().isEmpty) {
      return const AutocompleteResult(suggestions: [], isDemo: true);
    }
    return const AutocompleteResult(
      isDemo: true,
      suggestions: [
        AutocompleteSuggestion(
          placeId: 'demo-austin',
          fullText: 'Austin, TX, USA',
          primaryText: 'Austin',
          secondaryText: 'TX, USA',
          types: ['locality'],
        ),
      ],
    );
  }
}

String _fallbackMessage(Object error) {
  return error is BackendException
      ? error.userMessage
      : 'Showing demo results while live results are unavailable.';
}
