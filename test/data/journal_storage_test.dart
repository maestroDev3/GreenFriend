import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/data/file_photo_store.dart';
import 'package:green_friend/data/image_picker_photo_picker.dart';
import 'package:green_friend/data/shared_preferences_journal_repository.dart';
import 'package:green_friend/domain/journal.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<SharedPreferencesJournalRepository> openJournal() async =>
    SharedPreferencesJournalRepository(await SharedPreferences.getInstance());

void main() {
  group('SharedPreferencesJournalRepository', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('keeps entries across a restart', () async {
      final entry = await (await openJournal()).add(
        plantId: 'p',
        day: DateTime(2026, 9, 30, 20),
        note: 'First flower',
        photo: 'abc.jpg',
      );

      final loaded = await (await openJournal()).watchEntries('p').first;

      expect(loaded, [entry]);
      expect(loaded.single.day, DateTime.utc(2026, 9, 30));
    });

    test('deletes entries and all entries of a plant', () async {
      final journal = await openJournal();
      final first = await journal.add(
        plantId: 'p',
        day: DateTime(2026, 9, 1),
        note: 'a',
      );
      await journal.add(plantId: 'p', day: DateTime(2026, 9, 2), note: 'b');
      final other = await journal.add(
        plantId: 'x',
        day: DateTime(2026, 9, 3),
        note: 'c',
      );

      await journal.delete(first.id);
      expect(await journal.watchEntries('p').first, hasLength(1));
      await journal.deleteForPlant('p');

      expect(await (await openJournal()).watchEntries('p').first, isEmpty);
      expect(await (await openJournal()).watchEntries('x').first, [other]);
    });

    test('starts empty on corrupt data and keeps a backup', () async {
      SharedPreferences.setMockInitialValues({
        SharedPreferencesJournalRepository.entriesKey: '[{"broken": true}]',
      });

      final journal = await openJournal();
      final preferences = await SharedPreferences.getInstance();

      expect(await journal.watchEntries('p').first, isEmpty);
      expect(
        preferences.getString(SharedPreferencesJournalRepository.backupKey),
        '[{"broken": true}]',
      );
    });
  });

  test('lists and replaces all journal entries', () async {
    SharedPreferences.setMockInitialValues({});
    final journal = await openJournal();
    await journal.add(plantId: 'old', day: DateTime(2026, 1, 1), note: 'old');
    final entry = JournalEntry(
      id: 'x',
      plantId: 'p',
      day: DateTime(2026, 9, 1),
      note: 'new',
    );

    await journal.replaceAll([entry]);

    expect(await (await openJournal()).allEntries(), [entry]);
  });

  group('FilePhotoStore', () {
    late Directory temp;
    late FilePhotoStore store;

    setUp(() async {
      temp = await Directory.systemTemp.createTemp('photos');
      store = FilePhotoStore(Directory('${temp.path}/photos'));
    });
    tearDown(() => temp.delete(recursive: true));

    test('copies a photo into its folder and returns only the name', () async {
      final source = File('${temp.path}/picked.jpg')
        ..writeAsBytesSync([1, 2, 3]);

      final name = await store.save(source.path);

      expect(name, isNot(contains('/')));
      expect(name, endsWith('.jpg'));
      expect(store.fileFor(name).readAsBytesSync(), [1, 2, 3]);
      expect(store.fileFor(name).path, startsWith('${temp.path}/photos/'));
    });

    test('deletes a stored photo', () async {
      final source = File('${temp.path}/picked.jpg')..writeAsBytesSync([1]);
      final name = await store.save(source.path);

      await store.delete(name);

      expect(store.fileFor(name).existsSync(), isFalse);
    });

    test('reads and writes photo bytes', () async {
      await store.writeBytes('x.jpg', [4, 5]);

      expect(await store.readBytes('x.jpg'), [4, 5]);
      expect(await store.readBytes('missing.jpg'), isNull);
    });

    test('ignores deleting a photo that does not exist', () async {
      await store.delete('missing.jpg');
    });
  });

  test('picked photos are downscaled', () {
    expect(ImagePickerPhotoPicker.maxSide, 2048);
    expect(ImagePickerPhotoPicker.quality, 85);
  });

  test('the app asks for no camera or storage permission', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();

    for (final permission in [
      'android.permission.CAMERA',
      'READ_MEDIA_IMAGES',
      'READ_EXTERNAL_STORAGE',
      'WRITE_EXTERNAL_STORAGE',
    ]) {
      expect(manifest, isNot(contains(permission)), reason: permission);
    }
  });
}
