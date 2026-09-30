import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/domain/care_actions.dart';
import 'package:green_friend/domain/care_log.dart';
import 'package:green_friend/domain/plant.dart';

import '../support/fake_care_log_repository.dart';
import '../support/fake_plant_repository.dart';

final today = DateTime(2026, 9, 30, 19, 45);

Plant monstera() => Plant(
  id: '1',
  name: 'Monstera',
  wateringIntervalDays: 7,
  lastWateredOn: DateTime(2026, 9, 20),
);

void main() {
  group('confirmWatering', () {
    test('sets the last watering to today and logs it', () async {
      final plants = FakePlantRepository([monstera()]);
      final logs = FakeCareLogRepository();

      await confirmWatering(
        plants: plants,
        careLogs: logs,
        plant: monstera(),
        today: today,
      );

      expect(plants.plants.single.lastWateredOn, DateTime.utc(2026, 9, 30));
      expect(plants.plants.single.wateringIntervalDays, 7);
      expect(logs.logs.single.plantId, '1');
      expect(logs.logs.single.kind, const Water());
      expect(logs.logs.single.day, DateTime.utc(2026, 9, 30));
    });
  });

  group('undoWatering', () {
    test('restores the previous last watering and removes the log', () async {
      final plants = FakePlantRepository([monstera()]);
      final logs = FakeCareLogRepository();
      final confirmation = await confirmWatering(
        plants: plants,
        careLogs: logs,
        plant: monstera(),
        today: today,
      );

      await undoWatering(
        plants: plants,
        careLogs: logs,
        confirmation: confirmation,
      );

      expect(plants.plants.single, monstera());
      expect(logs.logs, isEmpty);
    });
  });
}
