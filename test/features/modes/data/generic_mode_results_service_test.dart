import 'package:flutter_test/flutter_test.dart';
import 'package:gomode/data/services/mode_catalog.dart';
import 'package:gomode/features/modes/data/generic_mode_results_service.dart';

void main() {
  const catalog = ModeCatalog();
  const service = DemoGenericModeResultsService(delay: Duration.zero);

  test('every generic mode produces fallback results', () async {
    for (final mode in catalog.modes.where(
      (mode) => mode.id != 'date-night' && mode.id != 'road-trip-stops',
    )) {
      expect(await service.load(mode), isNotEmpty, reason: mode.id);
    }
  });

  test('weekend and tourist plans generate multi-stop itineraries', () async {
    final weekend = await service.load(catalog.modeById('weekend-plan'));
    final tourist = await service.load(catalog.modeById('tourist-mode'));

    expect(weekend, hasLength(5));
    expect(tourist, hasLength(4));
  });

  test('road rescue covers all requested urgent categories', () async {
    final results = await service.load(catalog.modeById('road-rescue'));
    final tags = results.expand((result) => result.tags).toSet();

    expect(
      tags,
      containsAll(['Gas', 'Restroom', 'Pharmacy', 'Urgent care', 'Mechanic']),
    );
  });
}
