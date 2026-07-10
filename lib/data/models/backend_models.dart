class GeoPoint {
  const GeoPoint({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
  };

  factory GeoPoint.fromJson(Map<String, dynamic> json) {
    return GeoPoint(
      latitude: _double(json['latitude']) ?? 0,
      longitude: _double(json['longitude']) ?? 0,
    );
  }
}

class PlaceSummary {
  const PlaceSummary({
    required this.id,
    required this.name,
    required this.address,
    required this.types,
    this.location,
    this.rating,
    this.userRatingCount,
    this.openNow,
    this.primaryType,
    this.photoName,
    this.photoAttributions = const [],
    this.googleMapsUri,
    this.websiteUri,
    this.phoneNumber,
    this.distanceMeters,
    this.detourSeconds,
  });

  final String id;
  final String name;
  final String address;
  final List<String> types;
  final GeoPoint? location;
  final double? rating;
  final int? userRatingCount;
  final bool? openNow;
  final String? primaryType;
  final String? photoName;
  final List<PlaceAttribution> photoAttributions;
  final Uri? googleMapsUri;
  final Uri? websiteUri;
  final String? phoneNumber;
  final int? distanceMeters;
  final int? detourSeconds;

  factory PlaceSummary.fromJson(Map<String, dynamic> json) {
    final displayName = _map(json['displayName']);
    final openingHours =
        _map(json['currentOpeningHours']) ?? _map(json['regularOpeningHours']);
    final photos = _list(json['photos']);
    final firstPhoto = photos.isEmpty ? null : _map(photos.first);
    final locationJson = _map(json['location']);
    final uri = _string(json['googleMapsUri'] ?? json['mapsUri']);
    final website = _string(json['websiteUri']);
    return PlaceSummary(
      id: _string(json['id'] ?? json['placeId'] ?? json['name']) ?? '',
      name:
          _string(
            displayName?['text'] ?? json['displayName'] ?? json['title'],
          ) ??
          'Unnamed place',
      address:
          _string(
            json['formattedAddress'] ??
                json['shortFormattedAddress'] ??
                json['address'] ??
                json['vicinity'],
          ) ??
          '',
      types: _list(json['types']).map((value) => value.toString()).toList(),
      location: locationJson == null ? null : GeoPoint.fromJson(locationJson),
      rating: _double(json['rating']),
      userRatingCount: _int(
        json['userRatingCount'] ?? json['userRatingsTotal'],
      ),
      openNow: _bool(openingHours?['openNow'] ?? json['openNow']),
      primaryType: _string(json['primaryType']),
      photoName: _string(
        firstPhoto?['name'] ?? json['photoName'] ?? json['photoReference'],
      ),
      photoAttributions: [
        for (final value in _list(
          firstPhoto?['authorAttributions'] ?? json['authorAttributions'],
        ))
          if (_map(value) case final attribution?)
            PlaceAttribution.fromJson(attribution),
      ],
      googleMapsUri: uri == null ? null : Uri.tryParse(uri),
      websiteUri: website == null ? null : Uri.tryParse(website),
      phoneNumber: _string(
        json['nationalPhoneNumber'] ?? json['internationalPhoneNumber'],
      ),
      distanceMeters: _int(
        json['distanceMeters'] ?? json['distanceFromRouteMeters'],
      ),
      detourSeconds: _optionalDurationSeconds(
        json['detourDuration'] ??
            json['detourDurationSeconds'] ??
            json['detourSeconds'],
      ),
    );
  }
}

class PlaceAttribution {
  const PlaceAttribution({required this.displayName, this.uri, this.photoUri});

  final String displayName;
  final Uri? uri;
  final Uri? photoUri;

  factory PlaceAttribution.fromJson(Map<String, dynamic> json) {
    return PlaceAttribution(
      displayName: _string(json['displayName']) ?? 'Photo contributor',
      uri: Uri.tryParse(_string(json['uri']) ?? ''),
      photoUri: Uri.tryParse(_string(json['photoUri']) ?? ''),
    );
  }
}

class PlaceSearchResult {
  const PlaceSearchResult({
    required this.places,
    this.isDemo = false,
    this.fallbackMessage,
  });

  final List<PlaceSummary> places;
  final bool isDemo;
  final String? fallbackMessage;
}

class PlaceDetailsResult {
  const PlaceDetailsResult({
    required this.place,
    this.isDemo = false,
    this.fallbackMessage,
  });

  final PlaceSummary place;
  final bool isDemo;
  final String? fallbackMessage;
}

class PlacePhotoResult {
  const PlacePhotoResult({
    required this.url,
    this.expiresAt,
    this.isDemo = false,
  });

  final Uri? url;
  final DateTime? expiresAt;
  final bool isDemo;
}

class AutocompleteSuggestion {
  const AutocompleteSuggestion({
    required this.placeId,
    required this.fullText,
    this.primaryText,
    this.secondaryText,
    this.types = const [],
  });

  final String placeId;
  final String fullText;
  final String? primaryText;
  final String? secondaryText;
  final List<String> types;

  factory AutocompleteSuggestion.fromJson(Map<String, dynamic> json) {
    final prediction = _map(json['placePrediction']) ?? json;
    final text = _map(prediction['text']);
    final structured = _map(prediction['structuredFormat']);
    final mainText = _map(structured?['mainText']);
    final secondaryText = _map(structured?['secondaryText']);
    return AutocompleteSuggestion(
      placeId: _string(prediction['placeId']) ?? '',
      fullText:
          _string(
            text?['text'] ?? prediction['text'] ?? prediction['description'],
          ) ??
          '',
      primaryText: _string(mainText?['text'] ?? prediction['primaryText']),
      secondaryText: _string(
        secondaryText?['text'] ?? prediction['secondaryText'],
      ),
      types: _list(prediction['types']).map((value) => '$value').toList(),
    );
  }
}

class AutocompleteResult {
  const AutocompleteResult({required this.suggestions, this.isDemo = false});

  final List<AutocompleteSuggestion> suggestions;
  final bool isDemo;
}

class RouteWaypoint {
  const RouteWaypoint._({this.address, this.location});

  factory RouteWaypoint.address(String address) {
    return RouteWaypoint._(address: address);
  }

  factory RouteWaypoint.location(GeoPoint location) {
    return RouteWaypoint._(location: location);
  }

  final String? address;
  final GeoPoint? location;

  Object toJson() => address ?? location!.toJson();

  String get label => address ?? 'Selected location';
}

class RouteResult {
  const RouteResult({
    required this.distanceMeters,
    required this.durationSeconds,
    this.encodedPolyline,
    this.description,
    this.isDemo = false,
  });

  final int distanceMeters;
  final int durationSeconds;
  final String? encodedPolyline;
  final String? description;
  final bool isDemo;

  factory RouteResult.fromJson(
    Map<String, dynamic> json, {
    bool isDemo = false,
  }) {
    final routes = _list(json['routes']);
    final route =
        _map(json['route']) ??
        (routes.isEmpty ? null : _map(routes.first)) ??
        json;
    final polyline = _map(route['polyline']);
    return RouteResult(
      distanceMeters: _int(route['distanceMeters']) ?? 0,
      durationSeconds: _durationSeconds(
        route['duration'] ?? route['durationSeconds'],
      ),
      encodedPolyline: _string(
        polyline?['encodedPolyline'] ?? route['encodedPolyline'],
      ),
      description: _string(route['description'] ?? json['description']),
      isDemo: isDemo,
    );
  }
}

class RoadTripResult {
  const RoadTripResult({
    required this.route,
    required this.stops,
    this.strategy,
    this.isDemo = false,
    this.fallbackMessage,
  });

  final RouteResult route;
  final List<PlaceSummary> stops;
  final String? strategy;
  final bool isDemo;
  final String? fallbackMessage;

  factory RoadTripResult.fromJson(Map<String, dynamic> json) {
    final stopValues = _list(json['stops'] ?? json['places']);
    return RoadTripResult(
      route: RouteResult.fromJson(json),
      stops: [
        for (final value in stopValues)
          if (_map(value) case final stop?)
            PlaceSummary.fromJson(_flattenPlace(stop)),
      ],
      strategy: _string(json['strategy']),
    );
  }
}

class AirQualityForecastPoint {
  const AirQualityForecastPoint({
    required this.dateTime,
    this.aqi,
    this.category,
    this.dominantPollutant,
  });

  final DateTime? dateTime;
  final int? aqi;
  final String? category;
  final String? dominantPollutant;

  factory AirQualityForecastPoint.fromJson(Map<String, dynamic> json) {
    final indexes = _list(json['indexes']);
    final index = indexes.isEmpty ? null : _map(indexes.first);
    return AirQualityForecastPoint(
      dateTime: DateTime.tryParse(_string(json['dateTime']) ?? ''),
      aqi: _int(index?['aqi'] ?? json['aqi']),
      category: _string(index?['category'] ?? json['category']),
      dominantPollutant: _string(
        index?['dominantPollutant'] ?? json['dominantPollutant'],
      ),
    );
  }
}

class AirQualityReport {
  const AirQualityReport({
    required this.latitude,
    required this.longitude,
    required this.forecast,
    this.forecastAvailable = false,
    this.forecastStatus,
    this.currentDateTime,
    this.aqi,
    this.category,
    this.dominantPollutant,
    this.healthRecommendation,
    this.isDemo = false,
    this.fallbackMessage,
  });

  final double latitude;
  final double longitude;
  final DateTime? currentDateTime;
  final int? aqi;
  final String? category;
  final String? dominantPollutant;
  final String? healthRecommendation;
  final List<AirQualityForecastPoint> forecast;
  final bool forecastAvailable;
  final String? forecastStatus;
  final bool isDemo;
  final String? fallbackMessage;

  factory AirQualityReport.fromJson(
    Map<String, dynamic> json, {
    required GeoPoint requestedLocation,
  }) {
    final current = _map(json['current']) ?? json;
    final indexes = _list(current['indexes']);
    final index = indexes.isEmpty ? null : _map(indexes.first);
    final recommendations = _map(index?['healthRecommendations']);
    final currentRecommendations = _map(current['healthRecommendations']);
    final forecastContainer = _map(json['forecast']);
    final forecastData = _map(forecastContainer?['data']);
    final forecastValues = _list(
      forecastData?['hourlyForecasts'] ??
          forecastContainer?['hourlyForecasts'] ??
          json['hourlyForecasts'] ??
          json['forecast'] ??
          json['hours'],
    );
    return AirQualityReport(
      latitude: _double(json['latitude']) ?? requestedLocation.latitude,
      longitude: _double(json['longitude']) ?? requestedLocation.longitude,
      currentDateTime: DateTime.tryParse(_string(current['dateTime']) ?? ''),
      aqi: _int(index?['aqi'] ?? current['aqi']),
      category: _string(index?['category'] ?? current['category']),
      dominantPollutant: _string(
        index?['dominantPollutant'] ?? current['dominantPollutant'],
      ),
      healthRecommendation: _string(
        recommendations?['generalPopulation'] ??
            currentRecommendations?['generalPopulation'] ??
            current['healthRecommendation'],
      ),
      forecastAvailable:
          _bool(json['forecastAvailable']) ??
          _bool(forecastContainer?['available']) ??
          forecastValues.isNotEmpty,
      forecastStatus: _string(
        json['forecastStatus'] ?? forecastContainer?['status'],
      ),
      forecast: [
        for (final value in forecastValues)
          if (_map(value) case final point?)
            AirQualityForecastPoint.fromJson(point),
      ],
    );
  }
}

class PollenDay {
  const PollenDay({
    required this.date,
    required this.indexValue,
    required this.category,
    required this.inSeasonTypes,
  });

  final DateTime? date;
  final int? indexValue;
  final String? category;
  final List<String> inSeasonTypes;

  factory PollenDay.fromJson(Map<String, dynamic> json) {
    final dateJson = _map(json['date']);
    final typeInfo = _list(json['pollenTypeInfo']);
    final inSeason = <String>[];
    int? highestIndex;
    String? highestCategory;
    for (final value in typeInfo) {
      final info = _map(value);
      if (info == null) {
        continue;
      }
      final indexInfo = _map(info['indexInfo']);
      final code = _string(info['displayName'] ?? info['code']);
      if (_bool(info['inSeason']) == true && code != null) {
        inSeason.add(code);
      }
      final candidate = _int(indexInfo?['value']);
      if (candidate != null &&
          (highestIndex == null || candidate > highestIndex)) {
        highestIndex = candidate;
        highestCategory = _string(indexInfo?['category']);
      }
    }
    final year = _int(dateJson?['year']);
    final month = _int(dateJson?['month']);
    final day = _int(dateJson?['day']);
    return PollenDay(
      date: year == null || month == null || day == null
          ? DateTime.tryParse(_string(json['date']) ?? '')
          : DateTime(year, month, day),
      indexValue: highestIndex ?? _int(json['indexValue']),
      category: highestCategory ?? _string(json['category']),
      inSeasonTypes: inSeason,
    );
  }
}

class PollenReport {
  const PollenReport({
    required this.latitude,
    required this.longitude,
    required this.days,
    this.isDemo = false,
    this.fallbackMessage,
  });

  final double latitude;
  final double longitude;
  final List<PollenDay> days;
  final bool isDemo;
  final String? fallbackMessage;

  factory PollenReport.fromJson(
    Map<String, dynamic> json, {
    required GeoPoint requestedLocation,
  }) {
    return PollenReport(
      latitude: _double(json['latitude']) ?? requestedLocation.latitude,
      longitude: _double(json['longitude']) ?? requestedLocation.longitude,
      days: [
        for (final value in _list(json['dailyInfo'] ?? json['days']))
          if (_map(value) case final day?) PollenDay.fromJson(day),
      ],
    );
  }
}

class SolarCheckResult {
  const SolarCheckResult({
    required this.available,
    required this.address,
    this.status,
    this.reason,
    this.maxArrayPanelsCount,
    this.maxSunshineHoursPerYear,
    this.carbonOffsetFactorKgPerMwh,
    this.isDemo = false,
  });

  final bool available;
  final String address;
  final String? status;
  final String? reason;
  final int? maxArrayPanelsCount;
  final double? maxSunshineHoursPerYear;
  final double? carbonOffsetFactorKgPerMwh;
  final bool isDemo;

  factory SolarCheckResult.fromJson(
    Map<String, dynamic> json, {
    required String requestedAddress,
  }) {
    final insights =
        _map(json['insights']) ??
        _map(json['buildingInsights']) ??
        _map(json['result']) ??
        json;
    final potential = _map(insights['solarPotential']);
    final panels = _list(potential?['solarPanels']);
    return SolarCheckResult(
      available: _bool(json['available']) ?? potential != null,
      address:
          _string(
            json['resolvedAddress'] ?? json['address'] ?? insights['name'],
          ) ??
          requestedAddress,
      status: _string(json['status']),
      reason: _string(json['reason'] ?? json['message']),
      maxArrayPanelsCount:
          _int(potential?['maxArrayPanelsCount']) ??
          (panels.isEmpty ? null : panels.length),
      maxSunshineHoursPerYear: _double(potential?['maxSunshineHoursPerYear']),
      carbonOffsetFactorKgPerMwh: _double(
        potential?['carbonOffsetFactorKgPerMwh'],
      ),
    );
  }
}

Map<String, dynamic> _flattenPlace(Map<String, dynamic> stop) {
  final place = _map(stop['place']);
  if (place == null) {
    return stop;
  }
  return {...place, ...stop}..remove('place');
}

Map<String, dynamic>? _map(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return null;
}

List<Object?> _list(Object? value) {
  if (value is List) {
    return value.cast<Object?>();
  }
  return const [];
}

String? _string(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is String) {
    return value;
  }
  return value.toString();
}

double? _double(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '');
}

int? _int(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.round();
  }
  return int.tryParse(value?.toString() ?? '');
}

bool? _bool(Object? value) {
  if (value is bool) {
    return value;
  }
  return switch (value?.toString().toLowerCase()) {
    'true' => true,
    'false' => false,
    _ => null,
  };
}

int _durationSeconds(Object? value) {
  if (value is num) {
    return value.round();
  }
  final text = value?.toString() ?? '';
  if (text.endsWith('s')) {
    return double.tryParse(text.substring(0, text.length - 1))?.round() ?? 0;
  }
  return int.tryParse(text) ?? 0;
}

int? _optionalDurationSeconds(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is num) {
    return value.round();
  }
  final text = value.toString();
  if (text.endsWith('s')) {
    return double.tryParse(text.substring(0, text.length - 1))?.round();
  }
  return int.tryParse(text);
}
