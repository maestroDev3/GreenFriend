import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/domain/plant.dart';
import 'package:green_friend/domain/vacation.dart';
import 'package:green_friend/ui/home_screen.dart';
import 'package:green_friend/ui/settings_controller.dart';
import 'package:green_friend/ui/settings_screen.dart';

import '../support/fake_care_log_repository.dart';
import '../support/fake_journal_repository.dart';
import '../support/fake_photos.dart';
import '../support/fake_plant_repository.dart';
import '../support/fake_settings_repository.dart';
import '../support/fake_species_catalog.dart';
import '../support/pump_app.dart';

DateTime fixedNow() => DateTime(2026, 10, 17, 9);

final vacation = Vacation(
  first: DateTime(2026, 10, 15),
  last: DateTime(2026, 10, 25),
);

Future<(SettingsController, FakeSettingsRepository)> loaded({
  Vacation? current,
}) async {
  final repository = FakeSettingsRepository(vacation: current);
  final settings = SettingsController(repository);
  await settings.load();
  return (settings, repository);
}

Future<void> scrollTo(WidgetTester tester, String text) async {
  await tester.scrollUntilVisible(
    find.text(text),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

Widget home() => HomeScreen(
  plants: FakePlantRepository([Plant(id: '1', name: 'Monstera')]),
  careLogs: FakeCareLogRepository(),
  journal: FakeJournalRepository(),
  photos: FakePhotoStore(),
  photoPicker: FakePhotoPicker(),
  species: FakeSpeciesCatalog(const []),
  clock: fixedNow,
);

void main() {
  group('vacation in the settings', () {
    testWidgets('plans a vacation with the date range picker', (tester) async {
      final (settings, repository) = await loaded();
      await tester.pumpApp(SettingsScreen(clock: fixedNow), settings: settings);
      await scrollTo(tester, 'Plan vacation');
      expect(
        find.text('No vacation planned – reminders run as usual.'),
        findsOneWidget,
      );

      // The picker's header needs more width than a phone in the test font.
      tester.view.physicalSize =
          const Size(900, 1400) * tester.view.devicePixelRatio;
      await tester.pumpAndSettle();
      await tester.tap(find.text('Plan vacation'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('20').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('25').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save').last);
      await tester.pumpAndSettle();

      expect(
        repository.vacation,
        Vacation(first: DateTime(2026, 10, 20), last: DateTime(2026, 10, 25)),
      );
      expect(find.text('Oct 20, 2026 – Oct 25, 2026'), findsOneWidget);
    });

    testWidgets('ends a planned vacation', (tester) async {
      final (settings, repository) = await loaded(current: vacation);
      await tester.pumpApp(SettingsScreen(clock: fixedNow), settings: settings);
      await scrollTo(tester, 'End vacation');

      await tester.tap(find.text('End vacation'));
      await tester.pumpAndSettle();

      expect(repository.vacation, isNull);
    });
  });

  group('vacation banner on the home screen', () {
    testWidgets('shows the end date and ends the vacation', (tester) async {
      final (settings, repository) = await loaded(current: vacation);
      await tester.pumpApp(home(), settings: settings);

      expect(find.text('On vacation until Oct 25, 2026'), findsOneWidget);
      await tester.tap(find.text('End vacation'));
      await tester.pumpAndSettle();

      expect(repository.vacation, isNull);
      expect(find.textContaining('On vacation'), findsNothing);
    });

    testWidgets('is not shown before the vacation starts', (tester) async {
      final (settings, _) = await loaded(
        current: Vacation(
          first: DateTime(2026, 11, 1),
          last: DateTime(2026, 11, 5),
        ),
      );
      await tester.pumpApp(home(), settings: settings);

      expect(find.textContaining('On vacation'), findsNothing);
    });
  });
}
