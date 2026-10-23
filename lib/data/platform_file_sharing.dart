import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../domain/backup_files.dart';

/// Shares files with the Android share sheet and picks files with the system
/// file picker (no storage permission needed).
class PlatformFileSharing implements FileSharing {
  @override
  Future<String> temporaryPath(String fileName) async {
    final directory = await getTemporaryDirectory();
    return '${directory.path}/$fileName';
  }

  @override
  Future<void> shareFile(String path) =>
      _share(path, mimeType: 'application/zip');

  @override
  Future<void> shareBytes(
    List<int> bytes, {
    required String fileName,
    required String mimeType,
  }) async {
    final path = await temporaryPath(fileName);
    await File(path).writeAsBytes(bytes, flush: true);
    await _share(path, mimeType: mimeType);
  }

  Future<void> _share(String path, {required String mimeType}) async {
    await SharePlus.instance.share(
      ShareParams(files: [XFile(path, mimeType: mimeType)]),
    );
  }

  @override
  Future<void> shareText(String text, {String? subject}) async {
    await SharePlus.instance.share(ShareParams(text: text, subject: subject));
  }

  @override
  Future<String?> pickFile() async {
    final file = await FilePicker.pickFile();
    return file?.path;
  }
}
