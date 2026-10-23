import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/ui/app.dart';
import 'package:green_friend/ui/plant_form_screen.dart';
import 'package:green_friend/ui/settings_controller.dart';

import '../support/fake_backup.dart';
import '../support/fake_care_log_repository.dart';
import '../support/fake_journal_repository.dart';
import '../support/fake_photos.dart';
import '../support/fake_plant_repository.dart';
import '../support/fake_settings_repository.dart';
import '../support/fake_species_catalog.dart';

Future<FakeSettingsRepository> pumpApp(
  WidgetTester tester, {
  bool done = false,
  Locale locale = const Locale('en'),
}) async {
  tester.platformDispatcher.localesTestValue = [locale];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  final repository = FakeSettingsRepository(onboardingDone: done);
  final settings = SettingsController(repository);
  await settings.load();
  await tester.pumpWidget(
    GreenFriendApp(
      species: FakeSpeciesCatalog(const []),
      backupArchive: FakeBackupArchive(),
      fileSharing: FakeFileSharing(),
      journal: FakeJournalRepository(),
      photos: FakePhotoStore(),
      photoPicker: FakePhotoPicker(),
      careLogs: FakeCareLogRepository(),
      settings: settings,
      plants: FakePlantRepository(),
    ),
  );
  await tester.pumpAndSettle();
  return repository;
}

const welcome = 'Never forget to water again';
const emptyHint = 'No plants yet – add your first plant.';

void main() {
  group('introduction', () {
    testWidgets('without the flag the app starts with the introduction', (
      tester,
    ) async {
      await pumpApp(tester);

      expect(find.text(welcome), findsOneWidget);
      expect(find.text(emptyHint), findsNothing);
    });

    testWidgets('with the flag the app starts on the home screen', (
      tester,
    ) async {
      await pumpApp(tester, done: true);

      expect(find.text(welcome), findsNothing);
      expect(find.text(emptyHint), findsOneWidget);
    });

    testWidgets('skip finishes the introduction and shows the home screen', (
      tester,
    ) async {
      final repository = await pumpApp(tester);

      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(find.text(emptyHint), findsOneWidget);
      expect(repository.onboardingDone, isTrue);
    });

    testWidgets('"Add your first plant" on the last page finishes it and '
        'opens the plant form', (tester) async {
      final repository = await pumpApp(tester);

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Know your plant from a photo'), findsOneWidget);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Everything in its place'), findsOneWidget);
      expect(find.text('Skip'), findsNothing);
      await tester.tap(find.text('Add your first plant'));
      await tester.pumpAndSettle();

      expect(repository.onboardingDone, isTrue);
      expect(find.byType(PlantFormScreen), findsOneWidget);
    });

    testWidgets('shows the introduction in German', (tester) async {
      await pumpApp(tester, locale: const Locale('de', 'DE'));

      expect(find.text('Nie wieder Gießen vergessen'), findsOneWidget);
      expect(find.text('Überspringen'), findsOneWidget);
      expect(find.text('Weiter'), findsOneWidget);
    });
  });
}
