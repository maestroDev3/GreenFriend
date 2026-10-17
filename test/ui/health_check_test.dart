import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/domain/health.dart';
import 'package:green_friend/domain/identification.dart';
import 'package:green_friend/domain/plant.dart';
import 'package:green_friend/ui/health_check_screen.dart';
import 'package:green_friend/ui/plant_detail_screen.dart';
import 'package:green_friend/ui/settings_controller.dart';

import '../support/fake_care_log_repository.dart';
import '../support/fake_health_checker.dart';
import '../support/fake_journal_repository.dart';
import '../support/fake_photos.dart';
import '../support/fake_plant_repository.dart';
import '../support/fake_settings_repository.dart';
import '../support/fake_species_catalog.dart';
import '../support/pump_app.dart';

final sick = HealthAssessment(
  isHealthy: false,
  issues: [
    HealthIssue(
      name: 'Fungi',
      probability: 0.7,
      description: 'Fungi grow on the leaves.',
      prevention: const ['Keep leaves dry.'],
      biological: const ['Neem oil.'],
      chemical: const ['Fungicide.'],
    ),
    HealthIssue(name: 'Overwatering', probability: 0.2),
  ],
);

class Setup {
  Setup({
    String? apiKey = 'key-123',
    bool consent = false,
    FakeHealthChecker? checker,
  }) : settingsRepository = FakeSettingsRepository(
         plantIdApiKey: apiKey,
         healthCheckConsent: consent,
       ),
       checker = checker ?? FakeHealthChecker(result: sick);

  final FakeSettingsRepository settingsRepository;
  late final settings = SettingsController(settingsRepository);
  final FakeHealthChecker checker;
  final photos = FakePhotoStore();

  Future<void> pump(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
  }) async {
    await settings.load();
    await tester.pumpApp(
      PlantDetailScreen(
        species: FakeSpeciesCatalog(const []),
        plants: FakePlantRepository([Plant(id: 'p', name: 'Monstera')]),
        careLogs: FakeCareLogRepository(),
        journal: FakeJournalRepository(),
        photos: photos,
        photoPicker: FakePhotoPicker(),
        plantId: 'p',
        healthChecker: checker,
        clock: () => DateTime(2026, 10, 17, 10),
      ),
      settings: settings,
      locale: locale,
    );
  }
}

Future<void> startCheck(WidgetTester tester, {bool confirm = true}) async {
  await tester.tap(find.byTooltip('Health check'));
  await tester.pumpAndSettle();
  if (confirm) {
    await tester.tap(find.text('Check'));
    await tester.pumpAndSettle();
  }
}

Future<void> takePhoto(WidgetTester tester) async {
  await tester.tap(find.text('Take photo'));
  await tester.pumpAndSettle();
}

void main() {
  group('health check from the detail page', () {
    testWidgets('the action starts the check with a photo and shows the '
        'result screen', (tester) async {
      final setup = Setup();
      await setup.pump(tester);

      await startCheck(tester);
      await takePhoto(tester);

      expect(find.byType(HealthCheckScreen), findsOneWidget);
      expect(setup.checker.checks.single.apiKey, 'key-123');
      expect(setup.checker.checks.single.languageCode, 'en');
      expect(find.text('Possible problems'), findsOneWidget);
      expect(find.text('Fungi'), findsOneWidget);
      expect(find.text('70 % likely'), findsOneWidget);
      expect(find.text('Fungi grow on the leaves.'), findsOneWidget);
      expect(find.text('Keep leaves dry.'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Overwatering'),
        100,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('20 % likely'), findsOneWidget);
    });

    testWidgets('the action shows a healthy result', (tester) async {
      final setup = Setup(
        checker: FakeHealthChecker(
          result: HealthAssessment(isHealthy: true, issues: const []),
        ),
        consent: true,
      );
      await setup.pump(tester);

      await startCheck(tester, confirm: false);
      await takePhoto(tester);

      expect(find.text('Your plant looks healthy'), findsOneWidget);
    });

    testWidgets('the credit dialog appears only before the first check', (
      tester,
    ) async {
      final setup = Setup();
      await setup.pump(tester);

      await tester.tap(find.byTooltip('Health check'));
      await tester.pumpAndSettle();
      expect(
        find.text('Each health check uses credits of your plant.id account.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Check'));
      await tester.pumpAndSettle();
      expect(setup.settingsRepository.healthCheckConsent, isTrue);
      await takePhoto(tester);
      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Health check'));
      await tester.pumpAndSettle();
      expect(find.text('Take photo'), findsOneWidget);
      expect(
        find.text('Each health check uses credits of your plant.id account.'),
        findsNothing,
      );
    });

    testWidgets('the credit dialog: cancelling checks nothing', (tester) async {
      final setup = Setup();
      await setup.pump(tester);

      await tester.tap(find.byTooltip('Health check'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Take photo'), findsNothing);
      expect(setup.checker.checks, isEmpty);
      expect(setup.settingsRepository.healthCheckConsent, isFalse);
    });

    testWidgets('without key a message is shown', (tester) async {
      final setup = Setup(apiKey: null);
      await setup.pump(tester);

      await tester.tap(find.byTooltip('Health check'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'To check plant health, enter your plant.id API key in the '
          'settings (More → Settings → Plant identification).',
        ),
        findsOneWidget,
      );
      expect(setup.checker.checks, isEmpty);
    });

    for (final (failure, message) in [
      (
        const InvalidApiKey(),
        'The plant.id API key was rejected. Please check it in the settings.',
      ),
      (const NoCredits(), 'Your plant.id credits are used up.'),
      (
        const ServiceUnavailable(),
        'The health check is not reachable. Check your internet connection '
            'and try again.',
      ),
    ]) {
      testWidgets('with invalid key, without credits or offline a message is '
          'shown: $failure', (tester) async {
        final setup = Setup(
          checker: FakeHealthChecker(error: failure),
          consent: true,
        );
        await setup.pump(tester);

        await startCheck(tester, confirm: false);
        await takePhoto(tester);

        expect(find.text(message), findsOneWidget);
      });
    }

    testWidgets('shows the health check in German', (tester) async {
      final setup = Setup(consent: true);
      await setup.pump(tester, locale: const Locale('de'));

      await tester.tap(find.byTooltip('Gesundheitscheck'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Foto aufnehmen'));
      await tester.pumpAndSettle();

      expect(find.text('Gesundheitscheck'), findsOneWidget);
      expect(find.text('Mögliche Probleme'), findsOneWidget);
      expect(find.text('70 % wahrscheinlich'), findsOneWidget);
      expect(setup.checker.checks.single.languageCode, 'de');
    });
  });
}
