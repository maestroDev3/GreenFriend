import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/domain/care_log.dart';

void main() {
  group('CareKind', () {
    test('has water, fertilize, repot and prune with stable names', () {
      expect(CareKind.values.map((kind) => kind.name), [
        'water',
        'fertilize',
        'repot',
        'prune',
      ]);
      expect(CareKind.byName('fertilize'), const Fertilize());
      expect(CareKind.byName('unknown'), isNull);
    });
  });

  group('CareLog', () {
    test('normalizes its day and compares by value', () {
      final log = CareLog(
        id: 'l1',
        plantId: 'p1',
        kind: const Water(),
        day: DateTime(2026, 9, 30, 18, 5),
      );

      expect(log.day, DateTime.utc(2026, 9, 30));
      expect(
        log,
        CareLog(
          id: 'l1',
          plantId: 'p1',
          kind: const Water(),
          day: DateTime(2026, 9, 30),
        ),
      );
    });
  });

  group('newestFirst', () {
    test('sorts logs by day, newest first', () {
      final logs = [
        for (final (id, day) in [
          ('a', DateTime(2026, 9, 20)),
          ('b', DateTime(2026, 9, 28)),
          ('c', DateTime(2026, 9, 24)),
        ])
          CareLog(id: id, plantId: 'p1', kind: const Water(), day: day),
      ];

      expect(newestFirst(logs).map((log) => log.id), ['b', 'c', 'a']);
    });
  });
}
