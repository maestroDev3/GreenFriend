import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/domain/care_log.dart';

import 'fake_care_log_repository.dart';

void main() {
  group('FakeCareLogRepository', () {
    test('emits the plant logs newest first and after every change', () async {
      final repository = FakeCareLogRepository();
      final emitted = <List<DateTime>>[];
      final subscription = repository
          .watchLogs('p1')
          .listen((logs) => emitted.add([for (final log in logs) log.day]));
      await pumpEventQueue();

      await repository.add(
        plantId: 'p1',
        kind: const Water(),
        day: DateTime(2026, 9, 20),
      );
      final newer = await repository.add(
        plantId: 'p1',
        kind: const Water(),
        day: DateTime(2026, 9, 27),
      );
      await repository.add(
        plantId: 'other',
        kind: const Water(),
        day: DateTime(2026, 9, 28),
      );
      await repository.delete(newer.id);
      await repository.deleteForPlant('p1');
      await pumpEventQueue();
      await subscription.cancel();

      final day20 = DateTime.utc(2026, 9, 20);
      final day27 = DateTime.utc(2026, 9, 27);
      expect(emitted, [
        <DateTime>[],
        [day20],
        [day27, day20],
        [day27, day20],
        [day20],
        <DateTime>[],
      ]);
    });
  });
}
