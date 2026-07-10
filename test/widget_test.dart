import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gomode/app/gomode_app.dart';

void main() {
  testWidgets('GoMode navigation shell smoke test', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: GoModeApp()));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('GoMode'), findsOneWidget);
    expect(find.text('What mode are you in today?'), findsOneWidget);
    expect(find.text('Spin My Mode'), findsWidgets);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Modes'), findsOneWidget);
    expect(find.text('Map'), findsOneWidget);
    expect(find.text('Saved'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    await tester.tap(find.text('Modes'));
    await tester.pumpAndSettle();

    expect(find.text('Top modes'), findsOneWidget);
    expect(find.text('Date Night'), findsOneWidget);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -220));
    await tester.pumpAndSettle();
    expect(find.text('Go Out'), findsOneWidget);

    final dateNightCard = find.byKey(
      const ValueKey('featured-mode-card-date-night'),
    );
    await tester.ensureVisible(dateNightCard);
    await tester.pumpAndSettle();
    await tester.tap(dateNightCard);
    await tester.pumpAndSettle();

    expect(find.text('Preview results'), findsOneWidget);
    expect(find.text('Map'), findsOneWidget);

    await tester.drag(
      find.byType(CustomScrollView).last,
      const Offset(0, -180),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Preview results'));
    await tester.pumpAndSettle();

    expect(find.text('Date Night results'), findsOneWidget);
  });
}
