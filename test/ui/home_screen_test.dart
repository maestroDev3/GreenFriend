import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/ui/home_screen.dart';

import '../support/pump_app.dart';

void main() {
  group('HomeScreen', () {
    testWidgets('shows the app title and the empty-state hint', (tester) async {
      await tester.pumpApp(const HomeScreen());

      expect(find.text('Green Friend'), findsOneWidget);
      expect(
        find.text('No plants yet – add your first plant.'),
        findsOneWidget,
      );
    });

    testWidgets('shows the German hint for locale de', (tester) async {
      await tester.pumpApp(const HomeScreen(), locale: const Locale('de'));

      expect(
        find.text('Noch keine Pflanzen – füge deine erste Pflanze hinzu.'),
        findsOneWidget,
      );
    });
  });
}
