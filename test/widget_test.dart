import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gomode/app/gomode_app.dart';

void main() {
  testWidgets('GoMode shell smoke test', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: GoModeApp()));
    await tester.pumpAndSettle();

    expect(find.text('GoMode'), findsWidgets);
    expect(find.text('Pick your mood. Find your move.'), findsOneWidget);
    expect(find.text('What mode are you in today?'), findsOneWidget);
    expect(find.text('Date night'), findsOneWidget);
    expect(find.text('Food wheel'), findsOneWidget);
  });
}
