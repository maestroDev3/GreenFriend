import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/domain/care_actions.dart';
import 'package:green_friend/domain/care_log.dart';
import 'package:green_friend/domain/care_widget.dart';
import 'package:green_friend/domain/plant.dart';

import '../support/fake_care_log_repository.dart';
import '../support/fake_plant_repository.dart';

final today = DateTime(2026, 10, 17, 8);

Plant monstera() => Plant(
  id: 'm:1',
  name: 'Monstera',
  wateringIntervalDays: 7,
  lastWateredOn: DateTime(2026, 10, 5),
  fertilizingIntervalDays: 14,
  lastFertilizedOn: DateTime(2026, 10, 3),
);

void main() {
  group('care widget URIs', () {
    test('round-trip plant id and kinds', () {
      final uri = careWidgetUri('m:1', const [Water(), Fertilize()]);

      expect(uri.scheme, 'greenfriend');
      expect(parseCareWidgetUri(uri), (
        plantId: 'm:1',
        kinds: const [Water(), Fertilize()],
      ));
    });

    test('give null for other URIs', () {
      expect(parseCareWidgetUri(null), isNull);
      expect(parseCareWidgetUri(Uri.parse('greenfriend://open')), isNull);
      expect(
        parseCareWidgetUri(Uri.parse('greenfriend://care?plant=x&kinds=dance')),
        isNull,
      );
    });
  });

  group('completeCareFromWidget', () {
    test('records every kind of the row for the plant', () async {
      final plants = FakePlantRepository([monstera()]);
      final logs = FakeCareLogRepository();

      final done = await completeCareFromWidget(
        plants: plants,
        careLogs: logs,
        uri: careWidgetUri('m:1', const [Water(), Fertilize()]),
        today: today,
      );

      expect(done, isTrue);
      expect(plants.plants.single.lastWateredOn, DateTime.utc(2026, 10, 17));
      expect(plants.plants.single.lastFertilizedOn, DateTime.utc(2026, 10, 17));
      expect(logs.logs.map((log) => log.kind), [
        const Water(),
        const Fertilize(),
      ]);
      expect(careWidgetRows(plants.plants, today: today), isEmpty);
    });

    test('changes nothing for unknown URIs', () async {
      final plants = FakePlantRepository([monstera()]);

      final done = await completeCareFromWidget(
        plants: plants,
        careLogs: FakeCareLogRepository(),
        uri: Uri.parse('greenfriend://open'),
        today: today,
      );

      expect(done, isFalse);
      expect(plants.plants.single, monstera());
    });
  });
}
