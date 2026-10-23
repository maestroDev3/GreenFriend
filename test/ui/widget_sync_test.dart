import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/domain/care_actions.dart';
import 'package:green_friend/domain/care_log.dart';
import 'package:green_friend/domain/plant.dart';
import 'package:green_friend/l10n/app_localizations.dart';
import 'package:green_friend/ui/settings_controller.dart';
import 'package:green_friend/ui/widget_sync.dart';

import '../support/fake_care_log_repository.dart';
import '../support/fake_care_widget.dart';
import '../support/fake_plant_repository.dart';
import '../support/fake_settings_repository.dart';

DateTime fixedNow() => DateTime(2026, 10, 17, 8);

Plant monstera() => Plant(
  id: 'm',
  name: 'Monstera',
  wateringIntervalDays: 7,
  lastWateredOn: DateTime(2026, 10, 5),
  fertilizingIntervalDays: 14,
  lastFertilizedOn: DateTime(2026, 10, 3),
);

Future<(WidgetSync, FakeCareWidget, FakePlantRepository)> start({
  Locale locale = const Locale('en'),
  List<Plant>? plants,
}) async {
  final repository = FakePlantRepository(plants ?? [monstera()]);
  final settings = SettingsController(FakeSettingsRepository());
  await settings.load();
  final widget = FakeCareWidget();
  final sync = WidgetSync(
    plants: repository,
    settings: settings,
    widget: widget,
    clock: fixedNow,
    localizations: () => lookupAppLocalizations(locale),
  )..start();
  await sync.idle;
  return (sync, widget, repository);
}

void main() {
  group('WidgetSync', () {
    test('shows today\'s plants with their tasks', () async {
      final (_, widget, _) = await start();

      final content = widget.last!;
      expect(content.title, 'Care today');
      expect(content.day, DateTime.utc(2026, 10, 17));
      expect(content.lines.single.name, 'Monstera');
      expect(content.lines.single.tasks, 'Water, Fertilize');
      expect(content.lines.single.kinds, const [Water(), Fertilize()]);
      expect(content.emptyText, 'All plants are happy today');
    });

    test('writes the texts in German', () async {
      final (_, widget, _) = await start(locale: const Locale('de'));

      expect(widget.last!.title, 'Heute zu tun');
      expect(widget.last!.lines.single.tasks, 'Gießen, Düngen');
    });

    test('follows care done in the app', () async {
      final (sync, widget, plants) = await start();

      await confirmCare(
        plants: plants,
        careLogs: FakeCareLogRepository(),
        plant: monstera(),
        kind: const Water(),
        today: fixedNow(),
      );
      await sync.idle;

      expect(widget.last!.lines.single.tasks, 'Fertilize');
    });

    test('shows no lines when nothing is due', () async {
      final (_, widget, _) = await start(
        plants: [Plant(id: 's', name: 'Stone')],
      );

      expect(widget.last!.lines, isEmpty);
    });
  });
}
