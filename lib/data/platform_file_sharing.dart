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
  Future<void> shareFile(String path) async {
    await SharePlus.instance.share(
      ShareParams(files: [XFile(path, mimeType: 'application/zip')]),
    );
  }

  @override
  Future<String?> pickFile() async {
    final file = await FilePicker.pickFile();
    return file?.path;
  }
}
