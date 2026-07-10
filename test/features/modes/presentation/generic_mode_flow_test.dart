import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gomode/app/gomode_app.dart';
import 'package:gomode/app/router.dart';
import 'package:gomode/data/models/discovery_mode.dart';
import 'package:gomode/data/services/mode_catalog.dart';
import 'package:gomode/features/modes/data/generic_mode_results_service.dart';
import 'package:gomode/features/modes/domain/mode_flow_config.dart';
import 'package:gomode/features/modes/presentation/mode_results_screen.dart';
import 'package:gomode/features/saved/application/saved_library_controller.dart';
import 'package:gomode/features/saved/data/saved_local_storage.dart';
import 'package:gomode/features/saved/data/saved_repository.dart';

void main() {
  const catalog = ModeCatalog();

  testWidgets('every one of the 20 mode cards navigates to a useful screen', (
    tester,
  ) async {
    final harness = await _pumpApp(tester);

    for (final mode in catalog.modes) {
      harness.container.read(appRouterProvider).go('/modes');
      await tester.pumpAndSettle();
      await _returnModesListToTop(tester);

      await tester.enterText(find.byType(TextField), mode.title);
      await tester.pumpAndSettle();

      final card = ModeCatalog.featuredModeIds.contains(mode.id)
          ? find.byKey(ValueKey('featured-mode-card-${mode.id}'))
          : find.byKey(ValueKey('category-mode-card-${mode.id}'));
      await tester.scrollUntilVisible(
        card,
        260,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(card);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: mode.id);
      if (mode.id == 'date-night') {
        expect(
          find.byKey(const ValueKey('date-night-setup-scroll')),
          findsOneWidget,
          reason: mode.id,
        );
      } else if (mode.id == 'road-trip-stops') {
        expect(
          find.byKey(const ValueKey('road-trip-stops-scroll-view')),
          findsOneWidget,
          reason: mode.id,
        );
      } else {
        expect(
          find.byKey(ValueKey('mode-setup-${mode.id}')),
          findsOneWidget,
          reason: mode.id,
        );
      }
    }
  });

  testWidgets('every generic mode route produces actionable result cards', (
    tester,
  ) async {
    final harness = await _pumpApp(tester);
    final genericModes = catalog.modes.where(
      (mode) => mode.id != 'date-night' && mode.id != 'road-trip-stops',
    );

    for (final mode in genericModes) {
      harness.container.read(appRouterProvider).go('/modes/${mode.id}/results');
      await tester.pumpAndSettle();

      final resultCard = find.byKey(
        ValueKey('mode-result-card-${mode.id}-result-0'),
      );
      await tester.scrollUntilVisible(
        resultCard,
        340,
        scrollable: find.byType(Scrollable).first,
      );

      expect(tester.takeException(), isNull, reason: mode.id);
      expect(resultCard, findsOneWidget, reason: mode.id);
      expect(
        find.byKey(ValueKey('save-mode-result-${mode.id}-0')),
        findsOneWidget,
        reason: mode.id,
      );
      expect(
        find.byKey(ValueKey('navigate-mode-result-${mode.id}-0')),
        findsOneWidget,
        reason: mode.id,
      );
    }
  });

  testWidgets(
    'generic results expose loading, error, retry, and empty states',
    (tester) async {
      final pendingService = _PendingResultsService();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            genericModeResultsServiceProvider.overrideWithValue(pendingService),
          ],
          child: const MaterialApp(
            home: ModeResultsScreen(modeId: 'patio-finder'),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.byKey(const ValueKey('mode-results-loading-patio-finder')),
        findsOneWidget,
      );

      final retryService = _ErrorThenEmptyResultsService();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            genericModeResultsServiceProvider.overrideWithValue(retryService),
          ],
          child: const MaterialApp(
            home: ModeResultsScreen(modeId: 'patio-finder'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('mode-results-error-patio-finder')),
        findsOneWidget,
      );
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(retryService.calls, 2);
      expect(
        find.byKey(const ValueKey('mode-results-empty-patio-finder')),
        findsOneWidget,
      );
    },
  );

  testWidgets('Food Wheel animates and chooses a new restaurant', (
    tester,
  ) async {
    final harness = await _pumpApp(tester);
    harness.container.read(appRouterProvider).go('/modes/food-wheel/results');
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('food-wheel-animation')), findsOneWidget);
    expect(find.text('Koko Noodle Bar'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('spin-food-wheel-again')));
    await tester.pumpAndSettle();

    expect(find.text('Mesa Verde Tacos'), findsWidgets);
  });

  testWidgets('quest cards update shared progress', (tester) async {
    final harness = await _pumpApp(tester);
    harness.container.read(appRouterProvider).go('/modes/local-quest/results');
    await tester.pumpAndSettle();

    expect(find.text('0 of 2 complete'), findsOneWidget);
    await tester.tap(find.text('Complete next step'));
    await tester.pumpAndSettle();

    expect(find.text('1 of 2 complete'), findsOneWidget);
  });

  testWidgets('address-based modes require an input before results', (
    tester,
  ) async {
    final harness = await _pumpApp(tester);
    harness.container.read(appRouterProvider).go('/modes/solar-checker');
    await tester.pumpAndSettle();

    final cta = find.text(
      modeFlowConfigFor(catalog.modeById('solar-checker')).ctaLabel,
    );
    await tester.scrollUntilVisible(
      cta,
      320,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(cta);
    await tester.pumpAndSettle();

    expect(find.text('Enter a location to continue.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('mode-location-input')),
      '123 Main Street',
    );
    await tester.tap(cta);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('mode-results-solar-checker')),
      findsOneWidget,
    );
  });
}

Future<_TestHarness> _pumpApp(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(430, 932);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  final repository = LocalSavedRepository(storage: _MemorySavedLocalStorage());
  final container = ProviderContainer(
    overrides: [
      savedRepositoryProvider.overrideWithValue(repository),
      genericModeResultsServiceProvider.overrideWithValue(
        const DemoGenericModeResultsService(delay: Duration.zero),
      ),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const GoModeApp()),
  );
  await tester.pumpAndSettle();
  return _TestHarness(container);
}

Future<void> _returnModesListToTop(WidgetTester tester) async {
  final scrollable = find.byType(Scrollable).first;
  await tester.fling(scrollable, const Offset(0, 1200), 2500);
  await tester.pumpAndSettle();
}

class _TestHarness {
  const _TestHarness(this.container);

  final ProviderContainer container;
}

class _PendingResultsService implements GenericModeResultsService {
  final Completer<List<ModeResultItem>> completer = Completer();

  @override
  Future<List<ModeResultItem>> load(DiscoveryMode mode) => completer.future;
}

class _ErrorThenEmptyResultsService implements GenericModeResultsService {
  int calls = 0;

  @override
  Future<List<ModeResultItem>> load(DiscoveryMode mode) async {
    calls += 1;
    if (calls == 1) {
      throw StateError('Test failure');
    }
    return [];
  }
}

class _MemorySavedLocalStorage implements SavedLocalStorage {
  final Map<String, Object> values = {};

  @override
  Future<bool?> readBool(String key) async => values[key] as bool?;

  @override
  Future<String?> readString(String key) async => values[key] as String?;

  @override
  Future<void> writeBool(String key, bool value) async {
    values[key] = value;
  }

  @override
  Future<void> writeString(String key, String value) async {
    values[key] = value;
  }
}
