import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/domain/phone_calendar.dart';
import 'package:green_friend/domain/plant.dart';
import 'package:green_friend/domain/settings.dart';
import 'package:green_friend/ui/calendar_sync.dart';
import 'package:green_friend/ui/settings_controller.dart';
import 'package:green_friend/ui/settings_screen.dart';

import '../support/fake_phone_calendar.dart';
import '../support/fake_plant_repository.dart';
import '../support/fake_settings_repository.dart';
import '../support/pump_app.dart';

const switchLabel = 'Care tasks in the phone calendar';

class Setup {
  Setup({
    bool grantAccess = true,
    CalendarChoice? choice,
    List<PhoneCalendarEvent> events = const [],
  }) : repository = FakeSettingsRepository(phoneCalendar: choice),
       calendar = FakePhoneCalendar(
         grantAccess: grantAccess,
         calendars: const [
           PhoneCalendarInfo(
             id: 'c1',
             name: 'Personal',
             account: 'me@example.com',
             writable: true,
           ),
           PhoneCalendarInfo(id: 'h', name: 'Holidays', writable: false),
         ],
         events: events,
       );

  final FakeSettingsRepository repository;
  final FakePhoneCalendar calendar;
  late final settings = SettingsController(repository);
  late final sync = CalendarSync(
    plants: FakePlantRepository([
      Plant(
        id: 'm',
        name: 'Monstera',
        wateringIntervalDays: 30,
        lastWateredOn: DateTime(2026, 10, 1),
        winterRest: false,
      ),
    ]),
    settings: settings,
    calendar: calendar,
    clock: () => DateTime(2026, 10, 14, 8),
  );

  Future<void> pump(WidgetTester tester) async {
    await settings.load();
    sync.start();
    await tester.pumpApp(
      CalendarScope(sync: sync, child: const SettingsScreen()),
      settings: settings,
    );
    await tester.scrollUntilVisible(
      find.text(switchLabel),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }
}

void main() {
  group('phone calendar setting', () {
    testWidgets('lets me pick a writable calendar and syncs to it', (
      tester,
    ) async {
      final setup = Setup();
      await setup.pump(tester);

      await tester.tap(find.text(switchLabel));
      await tester.pumpAndSettle();

      expect(find.text('Choose a calendar'), findsOneWidget);
      expect(find.text('me@example.com'), findsOneWidget);
      expect(find.text('Holidays'), findsNothing);

      await tester.tap(find.text('Personal'));
      await tester.pumpAndSettle();
      await tester.pump();
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      expect(setup.repository.phoneCalendar, (id: 'c1', name: 'Personal'));
      expect(find.textContaining('Personal'), findsOneWidget);
      expect(setup.calendar.events, isNotEmpty);
    });

    testWidgets('stays off and explains when access is denied', (tester) async {
      final setup = Setup(grantAccess: false);
      await setup.pump(tester);

      await tester.tap(find.text(switchLabel));
      await tester.pumpAndSettle();

      expect(find.text('Choose a calendar'), findsNothing);
      expect(
        find.textContaining('Calendar access was not allowed'),
        findsOneWidget,
      );
      expect(setup.repository.phoneCalendar, isNull);
    });

    testWidgets('removes its events when switched off', (tester) async {
      final setup = Setup(choice: (id: 'c1', name: 'Personal'));
      await setup.pump(tester);
      await tester.pump();
      await tester.pumpAndSettle();
      expect(setup.calendar.events, isNotEmpty);

      await tester.tap(find.text(switchLabel));
      await tester.pumpAndSettle();
      await tester.pump();
      await tester.pumpAndSettle();

      expect(setup.repository.phoneCalendar, isNull);
      expect(setup.calendar.events, isEmpty);
    });
  });
}
