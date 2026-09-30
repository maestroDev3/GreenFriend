import 'package:image_picker/image_picker.dart';

import '../domain/photos.dart';

/// Takes photos with the system camera app and chooses them with the Android
/// photo picker, so the app needs no camera or storage permission.
class ImagePickerPhotoPicker implements PhotoPicker {
  /// Photos are downscaled to keep the app's storage small.
  static const maxSide = 2048;
  static const quality = 85;

  final _picker = ImagePicker();

  @override
  Future<String?> takePhoto() => _pick(ImageSource.camera);

  @override
  Future<String?> pickFromGallery() => _pick(ImageSource.gallery);

  Future<String?> _pick(ImageSource source) async {
    final file = await _picker.pickImage(
      source: source,
      maxWidth: maxSide.toDouble(),
      maxHeight: maxSide.toDouble(),
      imageQuality: quality,
    );
    return file?.path;
  }
}
