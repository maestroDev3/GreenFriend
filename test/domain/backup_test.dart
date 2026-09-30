import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/domain/backup.dart';
import 'package:green_friend/domain/care_log.dart';
import 'package:green_friend/domain/journal.dart';
import 'package:green_friend/domain/plant.dart';

import '../support/fake_care_log_repository.dart';
import '../support/fake_journal_repository.dart';
import '../support/fake_plant_repository.dart';

final plant = Plant(
  id: 'p1',
  name: 'Monstera',
  species: 'Monstera deliciosa',
  location: 'Living room',
  wateringIntervalDays: 7,
  lastWateredOn: DateTime(2026, 9, 28),
  fertilizingIntervalDays: 14,
  lastFertilizedOn: DateTime(2026, 9, 20),
  repottingIntervalMonths: 12,
  lastRepottedOn: DateTime(2025, 4, 2),
);
final log = CareLog(
  id: 'l1',
  plantId: 'p1',
  kind: const Fertilize(),
  day: DateTime(2026, 9, 20),
);
final entry = JournalEntry(
  id: 'j1',
  plantId: 'p1',
  day: DateTime(2026, 9, 1),
  note: 'Bought it',
  photo: 'abc.jpg',
);

void main() {
  group('backup', () {
    test('restores the same data after encoding and decoding', () async {
      final backup = await createBackup(
        plants: FakePlantRepository([plant]),
        careLogs: FakeCareLogRepository([log]),
        journal: FakeJournalRepository([entry]),
      );
      final plants = FakePlantRepository();
      final logs = FakeCareLogRepository();
      final journal = FakeJournalRepository();

      await restoreBackup(
        decodeBackup(encodeBackup(backup)),
        plants: plants,
        careLogs: logs,
        journal: journal,
      );

      expect(plants.plants, [plant]);
      expect(logs.logs, [log]);
      expect(journal.entries, [entry]);
    });

    test('replaces the existing data completely', () async {
      final plants = FakePlantRepository([Plant(id: 'old', name: 'Old')]);
      final logs = FakeCareLogRepository([
        CareLog(
          id: 'old',
          plantId: 'old',
          kind: const Water(),
          day: DateTime(2026, 1, 1),
        ),
      ]);
      final journal = FakeJournalRepository();

      await restoreBackup(
        Backup(plants: [plant], careLogs: const [], journal: [entry]),
        plants: plants,
        careLogs: logs,
        journal: journal,
      );

      expect(plants.plants, [plant]);
      expect(logs.logs, isEmpty);
      expect(journal.entries, [entry]);
    });

    test('rejects broken or unknown backups', () {
      expect(() => decodeBackup('not json'), throwsFormatException);
      expect(() => decodeBackup('{"format":"other"}'), throwsFormatException);
      expect(
        () => decodeBackup(
          '{"format":"green-friend-backup","version":99,'
          '"plants":[],"careLogs":[],"journal":[]}',
        ),
        throwsFormatException,
      );
      expect(
        () => decodeBackup(
          '{"format":"green-friend-backup","version":1,'
          '"plants":[{"id":"p","name":""}],"careLogs":[],"journal":[]}',
        ),
        throwsFormatException,
      );
    });

    test('lists the photos of the journal', () {
      final backup = Backup(
        plants: [plant],
        careLogs: const [],
        journal: [
          entry,
          JournalEntry(
            id: 'j2',
            plantId: 'p1',
            day: DateTime(2026, 9, 2),
            note: 'no photo',
          ),
        ],
      );

      expect(backup.photos, ['abc.jpg']);
    });
  });
}
