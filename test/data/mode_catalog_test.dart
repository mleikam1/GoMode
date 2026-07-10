import 'package:flutter_test/flutter_test.dart';
import 'package:gomode/data/models/discovery_mode.dart';
import 'package:gomode/data/services/mode_catalog.dart';

void main() {
  const catalog = ModeCatalog();

  test('catalog has exactly 20 modes', () {
    expect(catalog.modes, hasLength(20));
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
}
