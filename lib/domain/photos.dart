import 'dart:io';

/// Keeps photos in the app's own folder; the app stores only file names.
abstract interface class PhotoStore {
  /// Copies the photo at [sourcePath] into the app folder and returns its
  /// file name.
  Future<String> save(String sourcePath);

  Future<void> delete(String name);

  /// The file of a stored photo, for display.
  File fileFor(String name);

  /// The bytes of a stored photo, or `null` if it does not exist (backup).
  Future<List<int>?> readBytes(String name);

  /// Stores a photo under [name] (restoring a backup).
  Future<void> writeBytes(String name, List<int> bytes);
}

/// Lets the user take or choose a photo; returns a temporary path, or `null`
/// if the user cancelled.
abstract interface class PhotoPicker {
  Future<String?> takePhoto();

  Future<String?> pickFromGallery();
}
