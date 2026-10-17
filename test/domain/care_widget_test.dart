import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/domain/care_log.dart';
import 'package:green_friend/domain/care_widget.dart';
import 'package:green_friend/domain/plant.dart';

final today = DateTime(2026, 10, 17, 8);

void main() {
  group('careWidgetRows', () {
    test('lists plants with care due today, most urgent first', () {
      final rows = careWidgetRows([
        Plant(
          id: 'a',
          name: 'Aloe',
          wateringIntervalDays: 14,
          lastWateredOn: DateTime(2026, 10, 3),
        ),
        Plant(
          id: 'm',
          name: 'Monstera',
          wateringIntervalDays: 7,
          lastWateredOn: DateTime(2026, 10, 5),
          fertilizingIntervalDays: 14,
          lastFertilizedOn: DateTime(2026, 10, 3),
        ),
        Plant(
          id: 'f',
          name: 'Ficus',
          wateringIntervalDays: 7,
          lastWateredOn: DateTime(2026, 10, 15),
        ),
      ], today: today);

      expect(rows, const [
        CareWidgetRow(
          plantId: 'm',
          plantName: 'Monstera',
          kinds: [Water(), Fertilize()],
        ),
        CareWidgetRow(plantId: 'a', plantName: 'Aloe', kinds: [Water()]),
      ]);
    });

    test('is empty when nothing is due', () {
      expect(careWidgetRows([Plant(id: 'x', name: 'Stone')], today: today),
          isEmpty);
    });
  });
}
