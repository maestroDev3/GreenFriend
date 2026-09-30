import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/domain/plant.dart';
import 'package:green_friend/domain/urgency.dart';

final today = DateTime(2026, 9, 30, 8);

Plant plant(String name, {int? every, DateTime? lastWatered}) => Plant(
  id: name,
  name: name,
  wateringIntervalDays: every,
  lastWateredOn: lastWatered,
);

final plants = [
  plant('Unscheduled A'),
  plant('In 4 days', every: 7, lastWatered: DateTime(2026, 9, 27)),
  plant('Today', every: 7, lastWatered: DateTime(2026, 9, 23)),
  plant('Overdue 1', every: 3, lastWatered: DateTime(2026, 9, 26)),
  plant('In 1 day', every: 2, lastWatered: DateTime(2026, 9, 29)),
  plant('Overdue 3', every: 2, lastWatered: DateTime(2026, 9, 25)),
  plant('Also today', every: 1, lastWatered: DateTime(2026, 9, 29)),
];

void main() {
  group('sortedByUrgency', () {
    test('orders overdue, today, upcoming and unscheduled plants', () {
      expect(sortedByUrgency(plants, today).map((plant) => plant.name), [
        'Overdue 3',
        'Overdue 1',
        'Also today',
        'Today',
        'In 1 day',
        'In 4 days',
        'Unscheduled A',
      ]);
    });

    test('keeps the input list unchanged', () {
      final names = plants.map((plant) => plant.name).toList();

      sortedByUrgency(plants, today);

      expect(plants.map((plant) => plant.name), names);
    });
  });

  group('needingAttention', () {
    test('counts overdue plants and plants due today', () {
      expect(needingAttention(plants, today), 4);
    });

    test('is zero when nothing is due', () {
      expect(needingAttention([plant('Unscheduled A')], today), 0);
    });
  });
}
