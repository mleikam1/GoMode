import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gomode/app/gomode_app.dart';

void main() {
  testWidgets('GoMode shell smoke test', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: GoModeApp()));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('GoMode'), findsOneWidget);
    expect(find.text('What mode are you in today?'), findsOneWidget);
    expect(find.text('Spin My Mode'), findsWidgets);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -700));
    await tester.pumpAndSettle();

    expect(find.text('Date Night'), findsOneWidget);
    expect(find.text('Weekend Plan'), findsWidgets);
  });
}
