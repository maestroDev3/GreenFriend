import 'dart:io';

import 'package:green_friend/domain/photos.dart';

/// Keeps track of stored photo names instead of copying files.
class FakePhotoStore implements PhotoStore {
  final stored = <String>{};
  final bytes = <String, List<int>>{};
  var _next = 1;

  @override
  Future<String> save(String sourcePath) async {
    final name = 'photo-${_next++}.jpg';
    stored.add(name);
    return name;
  }

  @override
  Future<void> delete(String name) async => stored.remove(name);

  @override
  File fileFor(String name) => File('/fake/photos/$name');

  @override
  Future<List<int>?> readBytes(String name) async =>
      stored.contains(name) ? bytes[name] ?? const [0] : null;

  @override
  Future<void> writeBytes(String name, List<int> data) async {
    stored.add(name);
    bytes[name] = data;
  }
}

/// Returns a prepared path instead of opening the camera or gallery.
class FakePhotoPicker implements PhotoPicker {
  FakePhotoPicker({this.path = '/tmp/picked.jpg'});

  /// `null` simulates a cancelled picker.
  final String? path;
  final requests = <String>[];

  @override
  Future<String?> takePhoto() async {
    requests.add('camera');
    return path;
  }

  @override
  Future<String?> pickFromGallery() async {
    requests.add('gallery');
    return path;
  }
}
