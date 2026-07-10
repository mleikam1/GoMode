import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gomode/app/gomode_app.dart';
import 'package:gomode/app/router.dart';
import 'package:gomode/features/date_night/data/date_night_planning_service.dart';
import 'package:gomode/features/date_night/data/generated_plan_store.dart';
import 'package:gomode/features/date_night/domain/date_night_preferences.dart';
import 'package:gomode/features/date_night/domain/generated_plan.dart';

void main() {
  testWidgets('default Date Night selections render', (tester) async {
    await _pumpDateNightSetup(tester);

    expect(find.text('Date Night'), findsNWidgets(2));
    expect(find.text('Budget'), findsOneWidget);
    expect(find.text('Vibe'), findsOneWidget);
    expect(find.text('Time'), findsOneWidget);
    expect(find.byKey(const ValueKey('budget-fifty-selected')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('vibe-romantic-selected')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('time-twoHours-selected')),
      findsOneWidget,
    );
  });

  testWidgets('selecting chips and toggles updates Date Night state', (
    tester,
  ) async {
    await _pumpDateNightSetup(tester);

    await tester.tap(find.text(r'$25'));
    await tester.tap(find.text('Fun'));
    await tester.ensureVisible(find.text('All evening'));
    await tester.tap(find.text('All evening'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('budget-twentyFive-selected')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('vibe-fun-selected')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('time-allEvening-selected')),
      findsOneWidget,
    );

    final indoorSwitch = find.descendant(
      of: find.byKey(const ValueKey('toggle-indoor')),
      matching: find.byType(Switch),
    );
    expect(tester.widget<Switch>(indoorSwitch).value, isTrue);
    await tester.tap(indoorSwitch);
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(indoorSwitch).value, isFalse);
  });

  testWidgets('Generate My Night produces a local plan', (tester) async {
    final service = _RecordingPlanningService();
    await _pumpDateNightSetup(tester, planningService: service);

    await _generatePlan(tester);

    expect(service.lastPreferences, isNotNull);
    expect(service.lastPreferences?.budget, DateNightBudget.fifty);
    expect(find.text("Tonight's Plan"), findsOneWidget);
    expect(find.text('Juniper & Rye'), findsOneWidget);
    expect(find.text('Boardwalk Moonlight Stroll'), findsOneWidget);
    expect(find.text('Luna Sweets & Sips'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Save Plan'), 300);
    await tester.pumpAndSettle();
    expect(find.text('Save Plan'), findsOneWidget);
    expect(find.text('Open Map'), findsOneWidget);
  });

  testWidgets('generated Date Night plan can be saved', (tester) async {
    final store = _RecordingPlanStore();
    await _pumpDateNightSetup(tester, planStore: store);
    await _generatePlan(tester);

    final saveButton = find.byKey(const ValueKey('save-generated-plan-button'));
    await tester.scrollUntilVisible(saveButton, 300);
    await tester.pumpAndSettle();
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(store.savedPlan, isNotNull);
    expect(store.savedPlan?.steps, hasLength(3));
    expect(
      find.descendant(of: saveButton, matching: find.text('Saved')),
      findsOneWidget,
    );
    expect(find.text('Date Night plan saved locally.'), findsOneWidget);
  });
}

Future<void> _pumpDateNightSetup(
  WidgetTester tester, {
  DateNightPlanningService? planningService,
  GeneratedPlanStore? planStore,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  final container = ProviderContainer(
    overrides: [
      if (planningService != null)
        dateNightPlanningServiceProvider.overrideWithValue(planningService),
      if (planStore != null)
        generatedPlanStoreProvider.overrideWithValue(planStore),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const GoModeApp()),
  );
  await tester.pumpAndSettle();
  container.read(appRouterProvider).go('/modes/date-night');
  await tester.pumpAndSettle();
}

Future<void> _generatePlan(WidgetTester tester) async {
  final generateButton = find.byKey(
    const ValueKey('generate-date-night-button'),
  );
  await tester.ensureVisible(generateButton);
  await tester.pumpAndSettle();
  await tester.tap(generateButton);
  await tester.pumpAndSettle();
}

class _RecordingPlanningService implements DateNightPlanningService {
  DateNightPreferences? lastPreferences;

  @override
  Future<GeneratedPlan> generatePlan(DateNightPreferences preferences) async {
    lastPreferences = preferences;
    return generateDemoDateNightPlan(
      preferences,
      now: DateTime(2026, 7, 10, 12),
    );
  }
}

class _RecordingPlanStore implements GeneratedPlanStore {
  GeneratedPlan? savedPlan;

  @override
  bool contains(String planId) => savedPlan?.id == planId;

  @override
  Future<void> save(GeneratedPlan plan) async {
    savedPlan = plan;
  }
}
