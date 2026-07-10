import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gomode/app/gomode_app.dart';
import 'package:gomode/features/home/presentation/home_screen.dart';
import 'package:gomode/shared/widgets/shared_widgets.dart';

void main() {
  testWidgets('Home renders key text', (tester) async {
    await _pumpGoModeHome(tester);

    expect(find.bySemanticsLabel('GoMode'), findsOneWidget);
    expect(find.text('Austin, TX'), findsOneWidget);
    expect(find.text('What mode are you in today?'), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);
    expect(find.text('Date'), findsOneWidget);
    expect(find.text('Kids'), findsOneWidget);
    expect(find.text('Road Trip'), findsOneWidget);
    expect(find.text('Outdoors'), findsOneWidget);
    expect(find.text('Health'), findsOneWidget);
    expect(find.text('Surprise Me'), findsOneWidget);
    expect(find.text('Spin My Mode'), findsWidgets);
    expect(find.text('Popular modes'), findsOneWidget);

    await _scrollHomeBy(tester, 900);

    expect(find.text('Continue where you left off'), findsOneWidget);
    expect(find.text('Barton Springs & Beyond'), findsOneWidget);
    expect(find.text('2 of 6 places visited'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('Spin button opens the evening mode', (tester) async {
    await _pumpGoModeHome(
      tester,
      app: ProviderScope(
        overrides: [
          homeNowProvider.overrideWithValue(DateTime(2026, 7, 8, 19)),
        ],
        child: const GoModeApp(),
      ),
    );

    await tester.ensureVisible(
      find.widgetWithText(PrimaryGradientButton, 'Spin My Mode'),
    );
    await tester.tap(
      find.widgetWithText(PrimaryGradientButton, 'Spin My Mode'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Budget'), findsOneWidget);
    expect(find.text('Generate My Night'), findsOneWidget);
  });

  testWidgets('Road Trip filter affects Spin My Mode selection', (
    tester,
  ) async {
    await _pumpGoModeHome(
      tester,
      app: ProviderScope(
        overrides: [
          homeNowProvider.overrideWithValue(DateTime(2026, 7, 8, 12)),
        ],
        child: const GoModeApp(),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('home-filter-road-trip')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.widgetWithText(PrimaryGradientButton, 'Spin My Mode'),
    );
    await tester.tap(
      find.widgetWithText(PrimaryGradientButton, 'Spin My Mode'),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Discover worthwhile food'), findsOneWidget);
  });

  testWidgets('Popular mode card tap opens mode detail', (tester) async {
    await _pumpGoModeHome(tester);

    await _scrollHomeBy(tester, 260);
    await tester.tap(find.byKey(const ValueKey('popular-mode-date-night')));
    await tester.pumpAndSettle();

    expect(find.text('Budget'), findsOneWidget);
    expect(find.text('Generate My Night'), findsOneWidget);
  });

  testWidgets('Home lays out on a small phone viewport', (tester) async {
    await _pumpGoModeHome(tester, size: const Size(320, 568));

    expect(tester.takeException(), isNull);

    await _scrollHomeBy(tester, 1500);

    expect(find.text('Barton Springs & Beyond'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpGoModeHome(
  WidgetTester tester, {
  Size size = const Size(430, 932),
  Widget app = const ProviderScope(child: GoModeApp()),
}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(app);
  await tester.pumpAndSettle();
}

Future<void> _scrollHomeBy(WidgetTester tester, double distance) async {
  await tester.drag(find.byType(Scrollable).first, Offset(0, -distance));
  await tester.pumpAndSettle();
}
