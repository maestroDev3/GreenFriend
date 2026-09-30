/// Writes and reads the backup file (see `ZipBackupArchive`).
abstract interface class BackupArchive {
  /// Writes all data and photos to [zipPath].
  Future<void> export(String zipPath);

  /// Replaces all data with the backup; throws [FormatException] (and
  /// changes nothing) if the file is not a valid backup.
  Future<void> restore(String zipPath);
}

/// Hands files to other apps and lets the user pick a file.
abstract interface class FileSharing {
  /// A path in the app's temporary folder for a new file.
  Future<String> temporaryPath(String fileName);

  /// Opens the system share sheet for the file.
  Future<void> shareFile(String path);

  /// Lets the user choose a file; `null` if cancelled.
  Future<String?> pickFile();
}
