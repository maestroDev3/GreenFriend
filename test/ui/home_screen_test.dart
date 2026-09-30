import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/ui/home_screen.dart';

import '../support/fake_journal_repository.dart';
import '../support/fake_photos.dart';
import '../support/fake_care_log_repository.dart';
import '../support/fake_plant_repository.dart';
import '../support/pump_app.dart';

void main() {
  group('HomeScreen', () {
    testWidgets('shows the app title and the empty-state hint', (tester) async {
      await tester.pumpApp(
        HomeScreen(journal: FakeJournalRepository(), photos: FakePhotoStore(), photoPicker: FakePhotoPicker(), 
          careLogs: FakeCareLogRepository(),
          plants: FakePlantRepository(),
        ),
      );

      expect(find.text('Green Friend'), findsOneWidget);
      expect(
        find.text('No plants yet – add your first plant.'),
        findsOneWidget,
      );
    });

    testWidgets('shows the German hint for locale de', (tester) async {
      await tester.pumpApp(
        HomeScreen(journal: FakeJournalRepository(), photos: FakePhotoStore(), photoPicker: FakePhotoPicker(), 
          careLogs: FakeCareLogRepository(),
          plants: FakePlantRepository(),
        ),
        locale: const Locale('de'),
      );

      expect(
        find.text('Noch keine Pflanzen – füge deine erste Pflanze hinzu.'),
        findsOneWidget,
      );
    });
  });
}
