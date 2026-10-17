import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/domain/health.dart';
import 'package:green_friend/domain/journal.dart';
import 'package:green_friend/ui/health_check_screen.dart';
import 'package:green_friend/ui/timeline_screen.dart';

import '../support/fake_health_checker.dart';
import '../support/fake_journal_repository.dart';
import '../support/fake_photos.dart';
import '../support/pump_app.dart';

final sick = HealthAssessment(
  isHealthy: false,
  issues: [
    HealthIssue(name: 'Fungi', probability: 0.7),
    HealthIssue(name: 'Overwatering', probability: 0.2),
  ],
);

class Setup {
  Setup({HealthAssessment? result, Object? error})
    : checker = FakeHealthChecker(result: result ?? sick, error: error) {
    photos.stored.add('check.jpg');
  }

  final photos = FakePhotoStore();
  final journal = FakeJournalRepository();
  final FakeHealthChecker checker;

  Widget screen() => HealthCheckScreen(
    photo: 'check.jpg',
    photos: photos,
    checker: checker,
    apiKey: 'key',
    languageCode: 'en',
    plantId: 'p',
    journal: journal,
    clock: () => DateTime(2026, 10, 17, 10),
  );

  /// Opens the screen from a start page, so it can be left again.
  Future<void> open(WidgetTester tester, {Locale locale = const Locale('en')}) async {
    await tester.pumpApp(
      Builder(
        builder: (context) => TextButton(
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (_) => screen())),
          child: const Text('open'),
        ),
      ),
      locale: locale,
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }
}

Future<void> tapSave(WidgetTester tester, String label) async {
  await tester.scrollUntilVisible(
    find.text(label),
    100,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

void main() {
  group('saving a health check', () {
    testWidgets('saving adds one entry with the photo, the result text and '
        'the flag', (tester) async {
      final setup = Setup();
      await setup.open(tester);

      await tapSave(tester, 'Save to journal');

      final entry = setup.journal.entries.single;
      expect(entry.plantId, 'p');
      expect(entry.day, DateTime.utc(2026, 10, 17));
      expect(entry.photo, 'check.jpg');
      expect(entry.note, 'Health check: Fungi (70 %), Overwatering (20 %)');
      expect(entry.healthCheck, isTrue);
      expect(find.byType(HealthCheckScreen), findsNothing);
      expect(setup.photos.stored, contains('check.jpg'));
    });

    testWidgets('saving a healthy result in German', (tester) async {
      final setup = Setup(
        result: HealthAssessment(isHealthy: true, issues: const []),
      );
      await setup.open(tester, locale: const Locale('de'));

      await tapSave(tester, 'Im Tagebuch speichern');

      expect(
        setup.journal.entries.single.note,
        'Gesundheitscheck: sieht gesund aus',
      );
    });

    testWidgets('leaving the result without saving deletes the photo', (
      tester,
    ) async {
      final setup = Setup();
      await setup.open(tester);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(setup.journal.entries, isEmpty);
      expect(setup.photos.stored, isNot(contains('check.jpg')));
    });

    testWidgets('leaving the result without saving deletes the photo after '
        'an error too', (tester) async {
      final setup = Setup(error: Exception('offline'));
      await setup.open(tester);

      expect(find.text('Save to journal'), findsNothing);
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(setup.photos.stored, isNot(contains('check.jpg')));
    });
  });

  group('health checks in the timeline', () {
    testWidgets('the timeline shows the health icon only for health check '
        'entries', (tester) async {
      await tester.pumpApp(
        TimelineScreen(
          plantId: 'p',
          journal: FakeJournalRepository([
            JournalEntry(
              id: 'a',
              plantId: 'p',
              day: DateTime(2026, 10, 1),
              note: 'New leaf',
            ),
            JournalEntry(
              id: 'b',
              plantId: 'p',
              day: DateTime(2026, 10, 2),
              note: 'Health check: looks healthy',
              healthCheck: true,
            ),
          ]),
          photos: FakePhotoStore(),
        ),
      );

      expect(
        find.byIcon(Icons.health_and_safety_outlined),
        findsOneWidget,
      );
    });
  });
}
