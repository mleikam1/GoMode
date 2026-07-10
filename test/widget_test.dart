import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gomode/app/gomode_app.dart';
import 'package:gomode/services/location_service.dart';

void main() {
  testWidgets('GoMode navigation shell smoke test', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          locationServiceProvider.overrideWithValue(
            const _TestLocationService(),
          ),
        ],
        child: const GoModeApp(),
      ),
    );
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
    expect(find.text('Date Night'), findsWidgets);
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

    expect(find.text('Budget'), findsOneWidget);
    expect(find.text('Generate My Night'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const ValueKey('generate-date-night-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('generate-date-night-button')));
    await tester.pumpAndSettle();

    expect(find.text("Tonight's Plan"), findsOneWidget);
    expect(find.text('Juniper & Rye'), findsOneWidget);
  });
}

class _TestLocationService implements LocationService {
  const _TestLocationService();

  @override
  Future<AppLocation> currentOrFallback() async => austinFallbackLocation;
}
