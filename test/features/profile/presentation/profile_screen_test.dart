import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gomode/app/gomode_app.dart';
import 'package:gomode/app/router.dart';
import 'package:gomode/features/profile/application/profile_settings_controller.dart';
import 'package:gomode/features/profile/data/profile_settings_repository.dart';
import 'package:gomode/features/profile/domain/profile_settings.dart';

void main() {
  testWidgets('profile renders settings and persists an updated default', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final storage = _MemoryProfileSettingsStorage();
    final repository = LocalProfileSettingsRepository(storage: storage);
    final container = ProviderContainer(
      overrides: [
        profileSettingsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const GoModeApp()),
    );
    container.read(appRouterProvider).go('/profile');
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('profile-screen')), findsOneWidget);
    expect(find.text('Location preference'), findsOneWidget);
    expect(find.text('Preferences'), findsOneWidget);

    final budgetButton = find.byKey(const ValueKey('profile-budget-value'));
    await tester.scrollUntilVisible(
      budgetButton,
      320,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(budgetButton);
    await tester.pumpAndSettle();

    expect((await repository.load()).budget, BudgetPreference.value);
  });
}

class _MemoryProfileSettingsStorage implements ProfileSettingsStorage {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }
}
