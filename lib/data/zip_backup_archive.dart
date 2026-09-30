import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';

import '../domain/backup.dart';
import '../domain/backup_files.dart';
import '../domain/care_log_repository.dart';
import '../domain/journal_repository.dart';
import '../domain/photos.dart';
import '../domain/plant_repository.dart';

/// Writes and reads the backup file: a zip with `backup.json` and the
/// journal photos under `photos/`.
class ZipBackupArchive implements BackupArchive {
  ZipBackupArchive({
    required this.plants,
    required this.careLogs,
    required this.journal,
    required this.photos,
  });

  static const dataFile = 'backup.json';
  static const photoFolder = 'photos/';

  final PlantRepository plants;
  final CareLogRepository careLogs;
  final JournalRepository journal;
  final PhotoStore photos;

  /// Writes all data and the photos referenced by the journal to [zipPath].
  @override
  Future<void> export(String zipPath) async {
    final backup = await createBackup(
      plants: plants,
      careLogs: careLogs,
      journal: journal,
    );
    final archive = Archive()
      ..addFile(ArchiveFile.string(dataFile, encodeBackup(backup)));
    for (final photo in backup.photos.toSet()) {
      final bytes = await photos.readBytes(photo);
      if (bytes != null) {
        archive.addFile(ArchiveFile.bytes('$photoFolder$photo', bytes));
      }
    }
    await File(zipPath).writeAsBytes(ZipEncoder().encodeBytes(archive));
  }

  /// Replaces all data with the backup in [zipPath]; throws
  /// [FormatException] (and changes nothing) if the file is not a valid
  /// backup. Photos of the replaced journal that are not in the backup are
  /// deleted.
  @override
  Future<void> restore(String zipPath) async {
    final archive = _decode(await File(zipPath).readAsBytes());
    final data = archive.findFile(dataFile)?.readBytes();
    if (data == null) {
      throw const FormatException('The file contains no Green Friend backup.');
    }
    final backup = decodeBackup(utf8.decode(data, allowMalformed: true));

    final oldPhotos = {
      for (final entry in await journal.allEntries()) ?entry.photo,
    };
    for (final file in archive.files) {
      final name = file.name;
      final bytes = file.readBytes();
      if (!file.isFile || bytes == null || !name.startsWith(photoFolder)) {
        continue;
      }
      final photo = name.substring(photoFolder.length);
      if (photo.isEmpty || photo.contains('/')) continue;
      await photos.writeBytes(photo, bytes);
    }
    await restoreBackup(
      backup,
      plants: plants,
      careLogs: careLogs,
      journal: journal,
    );
    for (final photo in oldPhotos.difference(backup.photos.toSet())) {
      await photos.delete(photo);
    }
  }

  static Archive _decode(List<int> bytes) {
    try {
      return ZipDecoder().decodeBytes(bytes);
    } on FormatException {
      rethrow;
    } on Object catch (error) {
      throw FormatException('Not a zip file: $error');
    }
  }
}
