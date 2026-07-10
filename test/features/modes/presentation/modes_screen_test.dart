import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gomode/app/gomode_app.dart';

void main() {
  testWidgets('Modes page renders the approved discovery structure', (
    tester,
  ) async {
    await _pumpModesScreen(tester);

    expect(find.text('Choose what you want to do'), findsOneWidget);
    expect(find.text('Search modes'), findsOneWidget);
    expect(find.text('Popular'), findsOneWidget);
    expect(find.text('Nearby'), findsOneWidget);
    expect(find.text('Family'), findsOneWidget);
    expect(find.text('Road'), findsOneWidget);
    expect(find.text('Health'), findsOneWidget);
    expect(find.text('Top modes'), findsOneWidget);
    expect(find.text('Date Night'), findsOneWidget);
    expect(find.text('Weekend Plan'), findsOneWidget);
    expect(find.text('Go Out'), findsOneWidget);
    expect(find.text('Food Wheel'), findsOneWidget);
  });

  testWidgets('Search filters modes by title, category, and subtitle', (
    tester,
  ) async {
    await _pumpModesScreen(tester);

    await tester.enterText(find.byType(TextField), 'Patio');
    await tester.pumpAndSettle();

    expect(find.text('Patio Finder'), findsOneWidget);
    expect(find.text('Food Wheel'), findsNothing);
    expect(find.text('Top modes'), findsNothing);
  });

  testWidgets('Category carousel item tap navigates to mode detail', (
    tester,
  ) async {
    await _pumpModesScreen(tester);

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -220));
    await tester.pumpAndSettle();

    final foodWheelCard = find.byKey(
      const ValueKey('category-mode-card-food-wheel'),
    );
    await tester.tap(foodWheelCard);
    await tester.pumpAndSettle();

    expect(find.textContaining('Use quick constraints'), findsOneWidget);
    expect(find.text('Preview results'), findsOneWidget);
  });
}

Future<void> _pumpModesScreen(
  WidgetTester tester, {
  Size size = const Size(430, 932),
}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(const ProviderScope(child: GoModeApp()));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Modes').last);
  await tester.pumpAndSettle();
}
