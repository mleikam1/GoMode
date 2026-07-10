import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gomode/app/gomode_app.dart';
import 'package:gomode/app/router.dart';
import 'package:gomode/features/saved/application/saved_library_controller.dart';
import 'package:gomode/features/saved/data/saved_local_storage.dart';
import 'package:gomode/features/saved/data/saved_repository.dart';
import 'package:gomode/features/saved/domain/saved_item.dart';

void main() {
  testWidgets('Saved tabs filter locally persisted items by type', (
    tester,
  ) async {
    final harness = await _pumpSavedScreen(tester);
    await harness.repository.saveItem(
      SavedItem(
        id: 'saved-place',
        type: SavedItemType.place,
        categoryLabel: 'Coffee',
        title: 'Cosmic Coffee',
        description: 'A favorite patio in South Austin',
        savedAt: DateTime(2026, 7, 10),
        status: SavedItemStatus.saved,
        visual: SavedItemVisual.place,
      ),
    );
    harness.container.invalidate(savedLibraryProvider);
    await tester.pumpAndSettle();

    expect(find.text('Sunset & Sparkle'), findsOneWidget);
    expect(find.text('Cosmic Coffee'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('saved-tab-place')));
    await tester.pumpAndSettle();

    expect(find.text('Sunset & Sparkle'), findsNothing);
    expect(find.text('Cosmic Coffee'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('saved-tab-route')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('saved-empty-route')), findsOneWidget);
    expect(find.text('No saved routes yet'), findsOneWidget);
  });

  testWidgets('collection can be created with a local name', (tester) async {
    final harness = await _pumpSavedScreen(tester);
    final createButton = find.byKey(const ValueKey('create-collection-button'));
    await tester.ensureVisible(createButton);
    await tester.pumpAndSettle();
    await tester.tap(createButton);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('collection-name-field')),
      'Austin Favorites',
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('confirm-create-collection-button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Austin Favorites'), findsOneWidget);
    expect(
      (await harness.repository.loadCollections()).single.name,
      'Austin Favorites',
    );
  });

  testWidgets('mode result cards toggle saved state', (tester) async {
    final harness = await _pumpApp(tester);
    harness.container.read(appRouterProvider).go('/modes/weekend-plan/results');
    await tester.pumpAndSettle();
    final saveButton = find.byKey(
      const ValueKey('save-mode-result-weekend-plan-0'),
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('mode-result-card-weekend-plan-result-0')),
      320,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(saveButton);
    await tester.pumpAndSettle();
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(
      harness.container
          .read(savedLibraryProvider)
          .requireValue
          .contains('weekend-plan-result-0'),
      isTrue,
    );

    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(
      harness.container
          .read(savedLibraryProvider)
          .requireValue
          .contains('weekend-plan-result-0'),
      isFalse,
    );
  });
}

Future<_SavedTestHarness> _pumpSavedScreen(WidgetTester tester) async {
  final harness = await _pumpApp(tester);
  harness.container.read(appRouterProvider).go('/saved');
  await tester.pumpAndSettle();
  return harness;
}

Future<_SavedTestHarness> _pumpApp(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  final storage = _MemorySavedLocalStorage();
  final repository = LocalSavedRepository(
    storage: storage,
    now: () => DateTime(2026, 7, 10, 12),
  );
  final container = ProviderContainer(
    overrides: [savedRepositoryProvider.overrideWithValue(repository)],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const GoModeApp()),
  );
  await tester.pumpAndSettle();
  return _SavedTestHarness(container: container, repository: repository);
}

class _SavedTestHarness {
  const _SavedTestHarness({required this.container, required this.repository});

  final ProviderContainer container;
  final LocalSavedRepository repository;
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
