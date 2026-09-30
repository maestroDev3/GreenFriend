import 'package:green_friend/domain/backup_files.dart';

/// Records exports and restores instead of writing zip files.
class FakeBackupArchive implements BackupArchive {
  FakeBackupArchive({this.restoreError});

  /// Thrown by [restore], e.g. a `FormatException` for a broken file.
  final Object? restoreError;
  final exported = <String>[];
  final restored = <String>[];

  @override
  Future<void> export(String zipPath) async => exported.add(zipPath);

  @override
  Future<void> restore(String zipPath) async {
    if (restoreError case final error?) throw error;
    restored.add(zipPath);
  }
}

/// Records shared files and returns a prepared picked file.
class FakeFileSharing implements FileSharing {
  FakeFileSharing({this.picked = '/downloads/backup.zip'});

  /// `null` simulates a cancelled file picker.
  final String? picked;
  final shared = <String>[];

  @override
  Future<String> temporaryPath(String fileName) async => '/tmp/$fileName';

  @override
  Future<void> shareFile(String path) async => shared.add(path);

  @override
  Future<String?> pickFile() async => picked;
}
