import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/data/shared_preferences_care_log_repository.dart';
import 'package:green_friend/domain/care_log.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<SharedPreferencesCareLogRepository> openRepository() async =>
    SharedPreferencesCareLogRepository(await SharedPreferences.getInstance());

void main() {
  group('SharedPreferencesCareLogRepository', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('keeps logs across a restart', () async {
      final log = await (await openRepository()).add(
        plantId: 'p1',
        kind: const Fertilize(),
        day: DateTime(2026, 9, 28, 19),
      );

      final loaded = await (await openRepository()).watchLogs('p1').first;

      expect(loaded, [log]);
      expect(loaded.single.kind, const Fertilize());
      expect(loaded.single.day, DateTime.utc(2026, 9, 28));
    });

    test('stores kinds by name and days as ISO calendar days', () async {
      await (await openRepository()).add(
        plantId: 'p1',
        kind: const Water(),
        day: DateTime(2026, 9, 28, 23, 30),
      );
      final raw = (await SharedPreferences.getInstance()).getString(
        SharedPreferencesCareLogRepository.logsKey,
      );

      expect(raw, contains('"kind":"water"'));
      expect(raw, contains('"day":"2026-09-28"'));
    });

    test('emits the logs of a plant newest first after every change', () async {
      final repository = await openRepository();
      final emitted = <List<String>>[];
      final subscription = repository
          .watchLogs('p1')
          .listen((logs) => emitted.add([for (final log in logs) log.id]));
      await pumpEventQueue();

      final older = await repository.add(
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
        plantId: 'p2',
        kind: const Water(),
        day: DateTime(2026, 9, 28),
      );
      await repository.delete(older.id);
      await repository.deleteForPlant('p1');
      await pumpEventQueue();
      await subscription.cancel();

      expect(emitted, [
        <String>[],
        [older.id],
        [newer.id, older.id],
        [newer.id, older.id],
        [newer.id],
        <String>[],
      ]);
    });

    test('keeps the logs of other plants when deleting a plant', () async {
      final repository = await openRepository();
      await repository.add(
        plantId: 'p1',
        kind: const Water(),
        day: DateTime(2026, 9, 20),
      );
      final other = await repository.add(
        plantId: 'p2',
        kind: const Water(),
        day: DateTime(2026, 9, 21),
      );

      await repository.deleteForPlant('p1');

      expect(await (await openRepository()).watchLogs('p2').first, [other]);
    });

    test('starts empty on corrupt data and keeps a backup of it', () async {
      SharedPreferences.setMockInitialValues({
        SharedPreferencesCareLogRepository.logsKey: '{broken',
      });

      final repository = await openRepository();
      final preferences = await SharedPreferences.getInstance();

      expect(await repository.watchLogs('p1').first, isEmpty);
      expect(
        preferences.getString(SharedPreferencesCareLogRepository.backupKey),
        '{broken',
      );
    });

    test('lists and replaces all logs', () async {
      final repository = await openRepository();
      await repository.add(
        plantId: 'old',
        kind: const Water(),
        day: DateTime(2026, 1, 1),
      );
      final log = CareLog(
        id: 'x',
        plantId: 'p',
        kind: const Repot(),
        day: DateTime(2026, 9, 1),
      );

      await repository.replaceAll([log]);

      expect(await (await openRepository()).allLogs(), [log]);
    });
  });
}
