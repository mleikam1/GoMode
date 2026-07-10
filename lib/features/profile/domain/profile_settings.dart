enum LocationPreference { currentLocation, defaultCity }

extension LocationPreferenceLabel on LocationPreference {
  String get label => switch (this) {
    LocationPreference.currentLocation => 'Use current location',
    LocationPreference.defaultCity => 'Default city',
  };
}

enum BudgetPreference { value, balanced, flexible }

extension BudgetPreferenceLabel on BudgetPreference {
  String get label => switch (this) {
    BudgetPreference.value => r'$',
    BudgetPreference.balanced => r'$$',
    BudgetPreference.flexible => 'Any',
  };
}

enum SettingPreference { either, indoor, outdoor }

extension SettingPreferenceLabel on SettingPreference {
  String get label => switch (this) {
    SettingPreference.either => 'Either',
    SettingPreference.indoor => 'Indoor',
    SettingPreference.outdoor => 'Outdoor',
  };
}

class DefaultCity {
  const DefaultCity({
    required this.id,
    required this.label,
    required this.latitude,
    required this.longitude,
  });

  final String id;
  final String label;
  final double latitude;
  final double longitude;
}

const defaultCities = <DefaultCity>[
  DefaultCity(
    id: 'austin-tx',
    label: 'Austin, TX',
    latitude: 30.2672,
    longitude: -97.7431,
  ),
  DefaultCity(
    id: 'chicago-il',
    label: 'Chicago, IL',
    latitude: 41.8781,
    longitude: -87.6298,
  ),
  DefaultCity(
    id: 'denver-co',
    label: 'Denver, CO',
    latitude: 39.7392,
    longitude: -104.9903,
  ),
];

DefaultCity defaultCityFor(String id) {
  return defaultCities.firstWhere(
    (city) => city.id == id,
    orElse: () => defaultCities.first,
  );
}

class ProfileSettings {
  const ProfileSettings({
    this.locationPreference = LocationPreference.currentLocation,
    this.defaultCityId = 'austin-tx',
    this.budget = BudgetPreference.balanced,
    this.distanceMiles = 10,
    this.setting = SettingPreference.either,
    this.familyFriendly = false,
    this.petFriendly = false,
    this.accessibilityPreferred = false,
  });

  final LocationPreference locationPreference;
  final String defaultCityId;
  final BudgetPreference budget;
  final int distanceMiles;
  final SettingPreference setting;
  final bool familyFriendly;
  final bool petFriendly;
  final bool accessibilityPreferred;

  DefaultCity get defaultCity => defaultCityFor(defaultCityId);

  ProfileSettings copyWith({
    LocationPreference? locationPreference,
    String? defaultCityId,
    BudgetPreference? budget,
    int? distanceMiles,
    SettingPreference? setting,
    bool? familyFriendly,
    bool? petFriendly,
    bool? accessibilityPreferred,
  }) {
    return ProfileSettings(
      locationPreference: locationPreference ?? this.locationPreference,
      defaultCityId: defaultCityId ?? this.defaultCityId,
      budget: budget ?? this.budget,
      distanceMiles: distanceMiles ?? this.distanceMiles,
      setting: setting ?? this.setting,
      familyFriendly: familyFriendly ?? this.familyFriendly,
      petFriendly: petFriendly ?? this.petFriendly,
      accessibilityPreferred:
          accessibilityPreferred ?? this.accessibilityPreferred,
    );
  }

  Map<String, Object> toJson() => {
    'locationPreference': locationPreference.name,
    'defaultCityId': defaultCityId,
    'budget': budget.name,
    'distanceMiles': distanceMiles,
    'setting': setting.name,
    'familyFriendly': familyFriendly,
    'petFriendly': petFriendly,
    'accessibilityPreferred': accessibilityPreferred,
  };

  factory ProfileSettings.fromJson(Map<String, Object?> json) {
    return ProfileSettings(
      locationPreference: _enumByName(
        LocationPreference.values,
        json['locationPreference'],
        LocationPreference.currentLocation,
      ),
      defaultCityId: defaultCityFor(
        json['defaultCityId'] as String? ?? 'austin-tx',
      ).id,
      budget: _enumByName(
        BudgetPreference.values,
        json['budget'],
        BudgetPreference.balanced,
      ),
      distanceMiles: switch (json['distanceMiles']) {
        final num value when const [2, 5, 10, 25].contains(value.toInt()) =>
          value.toInt(),
        _ => 10,
      },
      setting: _enumByName(
        SettingPreference.values,
        json['setting'],
        SettingPreference.either,
      ),
      familyFriendly: json['familyFriendly'] as bool? ?? false,
      petFriendly: json['petFriendly'] as bool? ?? false,
      accessibilityPreferred: json['accessibilityPreferred'] as bool? ?? false,
    );
  }
}

T _enumByName<T extends Enum>(List<T> values, Object? raw, T fallback) {
  if (raw is! String) {
    return fallback;
  }
  for (final value in values) {
    if (value.name == raw) {
      return value;
    }
  }
  return fallback;
}
