import 'package:flutter_test/flutter_test.dart';
import 'package:gomode/data/models/discovery_mode.dart';
import 'package:gomode/data/services/mode_catalog.dart';
import 'package:gomode/features/modes/domain/mode_flow_config.dart';

void main() {
  const catalog = ModeCatalog();

  test('catalog has exactly 20 modes', () {
    expect(catalog.modes, hasLength(20));
  });

  test('catalog matches the requested 20-mode product set', () {
    const expectedIds = <String>{
      'date-night',
      'weekend-plan',
      'food-wheel',
      'patio-finder',
      'cheap-date',
      'food-challenge',
      'kids-bored-button',
      'rainy-day-ideas',
      'dog-friendly-spots',
      'road-trip-stops',
      'ev-charge-chill',
      'road-rescue',
      'open-now',
      'allergy-map',
      'clean-air-planner',
      'solar-checker',
      'neighborhood-check',
      'where-should-i-live',
      'local-quest',
      'tourist-mode',
    };

    expect(catalog.modes.map((mode) => mode.id).toSet(), expectedIds);
  });

  test('latest Modes screen exposes exactly 20 discoverable modes', () {
    final catalogIds = catalog.modes.map((mode) => mode.id).toSet();
    final discoveryIds = catalog.latestDiscoverableModes
        .map((mode) => mode.id)
        .toSet();

    expect(discoveryIds, hasLength(20));
    expect(discoveryIds, catalogIds);
  });

  test('every mode id is unique', () {
    final ids = catalog.modes.map((mode) => mode.id).toList();
    expect(ids.toSet(), hasLength(ids.length));
  });

  test('every category has at least one mode', () {
    for (final category in ModeCategory.values) {
      expect(
        catalog.byCategory(category),
        isNotEmpty,
        reason: '${category.label} should not be empty',
      );
    }
  });

  test('every mode has a title and subtitle', () {
    for (final mode in catalog.modes) {
      expect(mode.title.trim(), isNotEmpty, reason: mode.id);
      expect(mode.shortSubtitle.trim(), isNotEmpty, reason: mode.id);
    }
  });

  test('every mode has fallback results and consistent saving', () {
    for (final mode in catalog.modes) {
      expect(mode.demoResults, isNotEmpty, reason: mode.id);
      expect(mode.supportsSaving, isTrue, reason: mode.id);
    }
  });

  test('every shared setup keeps filters between one and five', () {
    for (final mode in catalog.modes.where(
      (mode) => mode.id != 'date-night' && mode.id != 'road-trip-stops',
    )) {
      final filters = modeFlowConfigFor(mode).filters;
      expect(filters, isNotEmpty, reason: mode.id);
      expect(filters.length, lessThanOrEqualTo(5), reason: mode.id);
    }
  });
}
