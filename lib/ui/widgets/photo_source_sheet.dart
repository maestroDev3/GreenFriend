import 'package:flutter/material.dart';

import '../../domain/photos.dart';
import '../../l10n/app_localizations.dart';

enum _PhotoSource { camera, gallery }

/// Lets the user choose between camera and gallery and returns the path of
/// the photo; `null` if cancelled.
Future<String?> pickPhotoWithSource(
  BuildContext context,
  PhotoPicker picker,
) async {
  final source = await showModalBottomSheet<_PhotoSource>(
    context: context,
    showDragHandle: true,
    builder: (context) => const _PhotoSourceSheet(),
  );
  return switch (source) {
    null => null,
    _PhotoSource.camera => picker.takePhoto(),
    _PhotoSource.gallery => picker.pickFromGallery(),
  };
}

class _PhotoSourceSheet extends StatelessWidget {
  const _PhotoSourceSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: Text(l10n.takePhoto),
            onTap: () => Navigator.of(context).pop(_PhotoSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(l10n.choosePhoto),
            onTap: () => Navigator.of(context).pop(_PhotoSource.gallery),
          ),
        ],
      ),
    );
  }
}
