import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/domain/health.dart';
import 'package:green_friend/domain/journal.dart';
import 'package:green_friend/domain/vacation.dart';
import 'package:green_friend/ui/health_check_screen.dart';
import 'package:green_friend/ui/settings_controller.dart';
import 'package:green_friend/ui/settings_screen.dart';
import 'package:green_friend/ui/timelapse_screen.dart';

import '../support/fake_backup.dart';
import '../support/fake_health_checker.dart';
import '../support/fake_journal_repository.dart';
import '../support/fake_photos.dart';
import '../support/fake_settings_repository.dart';
import '../support/fake_timelapse_encoder.dart';
import '../support/pump_app.dart';

DateTime fixedNow() => DateTime(2026, 10, 17, 9);

Future<SettingsController> settingsWith(Vacation vacation) async {
  final settings = SettingsController(
    FakeSettingsRepository(vacation: vacation),
  );
  await settings.load();
  return settings;
}

Future<void> scrollTo(WidgetTester tester, String text) async {
  await tester.scrollUntilVisible(
    find.text(text),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('any encoding error shows the failure message', (tester) async {
    final photos = FakePhotoStore()..stored.addAll(['a.jpg', 'b.jpg']);
    await tester.pumpApp(
      TimelapseScreen(
        entries: [
          JournalEntry(
            id: 'a',
            plantId: 'p',
            day: DateTime(2026, 9, 1),
            photo: 'a.jpg',
          ),
          JournalEntry(
            id: 'b',
            plantId: 'p',
            day: DateTime(2026, 9, 2),
            photo: 'b.jpg',
          ),
        ],
        photos: photos,
        fileSharing: FakeFileSharing(),
        encoder: FakeTimelapseEncoder(error: StateError('out of memory')),
      ),
    );

    await tester.tap(find.text('Share as GIF'));
    await tester.pump();
    await tester.pump();

    expect(find.text('The time-lapse could not be created.'), findsOneWidget);
    expect(find.text('Share as GIF'), findsOneWidget);
  });

  testWidgets('a double tap on "Save to journal" adds one entry', (
    tester,
  ) async {
    final journal = FakeJournalRepository();
    final photos = FakePhotoStore()..stored.add('check.jpg');
    await tester.pumpApp(
      HealthCheckScreen(
        photo: 'check.jpg',
        photos: photos,
        checker: FakeHealthChecker(
          result: HealthAssessment(isHealthy: true, issues: const []),
        ),
        apiKey: 'key',
        languageCode: 'en',
        plantId: 'p',
        journal: journal,
        clock: fixedNow,
      ),
    );
    await tester.scrollUntilVisible(
      find.text('Save to journal'),
      100,
      scrollable: find.byType(Scrollable).last,
    );

    await tester.tap(find.text('Save to journal'));
    await tester.tap(find.text('Save to journal'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(journal.entries, hasLength(1));
  });

  group('vacation', () {
    testWidgets('changing a running vacation opens the picker', (
      tester,
    ) async {
      final settings = await settingsWith(
        Vacation(first: DateTime(2026, 10, 10), last: DateTime(2026, 10, 25)),
      );
      await tester.pumpApp(SettingsScreen(clock: fixedNow), settings: settings);
      await scrollTo(tester, 'Change');
      tester.view.physicalSize =
          const Size(900, 1400) * tester.view.devicePixelRatio;
      await tester.pumpAndSettle();

      await tester.tap(find.text('Change'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(DateRangePickerDialog), findsOneWidget);
    });

    testWidgets('an ended vacation is not shown', (tester) async {
      final settings = await settingsWith(
        Vacation(first: DateTime(2026, 10, 1), last: DateTime(2026, 10, 5)),
      );
      await tester.pumpApp(SettingsScreen(clock: fixedNow), settings: settings);

      await scrollTo(tester, 'Plan vacation');

      expect(
        find.text('No vacation planned – reminders run as usual.'),
        findsOneWidget,
      );
    });
  });
}
