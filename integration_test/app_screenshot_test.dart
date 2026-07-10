import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gomode/app/gomode_app.dart';
import 'package:gomode/app/router.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('capture approved GoMode screens', (tester) async {
    if (Platform.isAndroid) {
      await binding.convertFlutterSurfaceToImage();
    }

    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const GoModeApp()),
    );
    await tester.pumpAndSettle();

    await _capture(binding, tester, 'home');
    await _goAndCapture(container, binding, tester, '/modes', 'modes');
    await _goAndCapture(
      container,
      binding,
      tester,
      '/modes/date-night',
      'date-night',
    );
    // Change shell branches so the persistent navigation is repainted before
    // the next nested-route screenshot on Android's image-reader surface.
    container.read(appRouterProvider).go('/home');
    await tester.pumpAndSettle();
    await _goAndCapture(
      container,
      binding,
      tester,
      '/modes/road-trip-stops',
      'road-trip',
    );
    await _goAndCapture(container, binding, tester, '/saved', 'saved');
  });
}

Future<void> _goAndCapture(
  ProviderContainer container,
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
  String route,
  String name,
) async {
  container.read(appRouterProvider).go(route);
  await tester.pumpAndSettle(const Duration(milliseconds: 100));
  await _capture(binding, tester, name);
}

Future<void> _capture(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
  String name,
) async {
  // Asset decoding and native route compositing complete on real device time,
  // not only on the test clock advanced by pumpAndSettle.
  await Future<void>.delayed(const Duration(milliseconds: 900));
  await tester.pumpAndSettle();
  await binding.takeScreenshot(name);
}
