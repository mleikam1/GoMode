import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gomode/app/gomode_app.dart';
import 'package:gomode/app/router.dart';

void main() {
  testWidgets('core screens reflow at larger text and tablet widths', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(768, 1024);
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const GoModeApp()),
    );
    await tester.pumpAndSettle();

    container.read(appRouterProvider).go('/modes');
    await tester.pumpAndSettle();
    expect(find.text('Top modes'), findsOneWidget);
    expect(tester.takeException(), isNull);

    container.read(appRouterProvider).go('/modes/date-night');
    await tester.pumpAndSettle();
    final choice = find.byKey(const ValueKey('budget-fifty-selected'));
    expect(tester.getSize(choice).height, greaterThanOrEqualTo(44));
    expect(tester.takeException(), isNull);

    container.read(appRouterProvider).go('/saved');
    for (var frame = 0; frame < 10; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Saved'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('navigation destinations expose selected button semantics', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: GoModeApp()));
    await tester.pumpAndSettle();

    final semantics = tester.getSemantics(find.bySemanticsLabel('Home'));
    expect(semantics.flagsCollection.isButton, isTrue);
    expect(semantics.flagsCollection.isSelected.toBoolOrNull(), isTrue);
  });
}
