import 'dart:io';
import 'dart:math';

import 'package:path_provider/path_provider.dart';

import '../domain/clock.dart';
import '../domain/photos.dart';

/// Keeps photos as files in the app's own folder (removed with the app).
class FilePhotoStore implements PhotoStore {
  FilePhotoStore(this.directory, {this.clock = DateTime.now, Random? random})
    : _random = random ?? Random.secure();

  /// The store in `<app documents>/photos`.
  static Future<FilePhotoStore> create() async {
    final documents = await getApplicationDocumentsDirectory();
    return FilePhotoStore(Directory('${documents.path}/photos'));
  }

  final Directory directory;

  /// Supplies the time used in generated file names.
  final Clock clock;

  final Random _random;

  @override
  Future<String> save(String sourcePath) async {
    await directory.create(recursive: true);
    final dot = sourcePath.lastIndexOf('.');
    final extension = dot > sourcePath.lastIndexOf('/')
        ? sourcePath.substring(dot).toLowerCase()
        : '.jpg';
    final name =
        '${clock().microsecondsSinceEpoch.toRadixString(36)}-'
        '${_random.nextInt(1 << 32).toRadixString(36)}$extension';
    await File(sourcePath).copy(fileFor(name).path);
    return name;
  }

  @override
  Future<void> delete(String name) async {
    final file = fileFor(name);
    if (await file.exists()) await file.delete();
  }

  @override
  File fileFor(String name) => File('${directory.path}/$name');

  @override
  Future<List<int>?> readBytes(String name) async {
    final file = fileFor(name);
    return await file.exists() ? file.readAsBytes() : null;
  }

  @override
  Future<void> writeBytes(String name, List<int> bytes) async {
    await directory.create(recursive: true);
    await fileFor(name).writeAsBytes(bytes);
  }
}
