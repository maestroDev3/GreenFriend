import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/data/file_photo_store.dart';
import 'package:green_friend/data/zip_backup_archive.dart';
import 'package:green_friend/domain/care_log.dart';
import 'package:green_friend/domain/journal.dart';
import 'package:green_friend/domain/plant.dart';

import '../support/fake_care_log_repository.dart';
import '../support/fake_journal_repository.dart';
import '../support/fake_plant_repository.dart';

final plant = Plant(id: 'p', name: 'Monstera', wateringIntervalDays: 7);
final log = CareLog(
  id: 'l',
  plantId: 'p',
  kind: const Water(),
  day: DateTime(2026, 9, 28),
);
final entry = JournalEntry(
  id: 'j',
  plantId: 'p',
  day: DateTime(2026, 9, 1),
  note: 'Bought it',
  photo: 'abc.jpg',
);

void main() {
  late Directory temp;

  setUp(() async => temp = await Directory.systemTemp.createTemp('backup'));
  tearDown(() => temp.delete(recursive: true));

  ZipBackupArchive archiveFor(
    FakePlantRepository plants,
    FakeCareLogRepository logs,
    FakeJournalRepository journal,
    String photoFolder,
  ) => ZipBackupArchive(
    plants: plants,
    careLogs: logs,
    journal: journal,
    photos: FilePhotoStore(Directory('${temp.path}/$photoFolder')),
  );

  test('restores data and photos from an exported backup', () async {
    final source = FilePhotoStore(Directory('${temp.path}/source'));
    await source.writeBytes('abc.jpg', [1, 2, 3]);
    await source.writeBytes('orphan.jpg', [9]);
    final zip = '${temp.path}/backup.zip';
    await archiveFor(
      FakePlantRepository([plant]),
      FakeCareLogRepository([log]),
      FakeJournalRepository([entry]),
      'source',
    ).export(zip);

    final plants = FakePlantRepository([Plant(id: 'old', name: 'Old')]);
    final logs = FakeCareLogRepository();
    final journal = FakeJournalRepository();
    await archiveFor(plants, logs, journal, 'target').restore(zip);

    expect(plants.plants, [plant]);
    expect(logs.logs, [log]);
    expect(journal.entries, [entry]);
    final target = FilePhotoStore(Directory('${temp.path}/target'));
    expect(await target.readBytes('abc.jpg'), [1, 2, 3]);
    final names = ZipDecoder()
        .decodeBytes(File(zip).readAsBytesSync())
        .files
        .map((file) => file.name);
    expect(names, containsAll(['backup.json', 'photos/abc.jpg']));
    expect(names, isNot(contains('photos/orphan.jpg')));
  });

  Future<void> expectRejected(List<int> zipBytes) async {
    final zip = File('${temp.path}/bad.zip')..writeAsBytesSync(zipBytes);
    final plants = FakePlantRepository([plant]);

    await expectLater(
      archiveFor(
        plants,
        FakeCareLogRepository(),
        FakeJournalRepository(),
        'target',
      ).restore(zip.path),
      throwsFormatException,
    );
    expect(plants.plants, [plant]);
  }

  test('rejects a file that is not a zip', () async {
    await expectRejected([1, 2, 3, 4]);
  });

  test('rejects a zip without backup.json', () async {
    final archive = Archive()..addFile(ArchiveFile.string('other.txt', 'hi'));
    await expectRejected(ZipEncoder().encodeBytes(archive));
  });

  test('rejects a backup of an unknown version', () async {
    final archive = Archive()
      ..addFile(
        ArchiveFile.string(
          'backup.json',
          '{"format":"green-friend-backup","version":2,'
              '"plants":[],"careLogs":[],"journal":[]}',
        ),
      );
    await expectRejected(ZipEncoder().encodeBytes(archive));
  });
}
