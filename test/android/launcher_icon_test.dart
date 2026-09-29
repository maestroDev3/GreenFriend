import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

const res = 'android/app/src/main/res';

String read(String path) => File(path).readAsStringSync();

/// Width and height from the IHDR chunk of a PNG file.
(int, int) pngSize(String path) {
  final bytes = ByteData.sublistView(File(path).readAsBytesSync());
  return (bytes.getUint32(16), bytes.getUint32(20));
}

void main() {
  group('launcher icon', () {
    test('is an adaptive icon with background, foreground and monochrome', () {
      final icon = read('$res/mipmap-anydpi-v26/ic_launcher.xml');

      expect(icon, contains('<adaptive-icon'));
      expect(icon, contains('<background'));
      expect(icon, contains('@drawable/ic_launcher_foreground'));
      expect(icon, contains('<monochrome'));
      expect(icon, contains('@drawable/ic_launcher_monochrome'));
    });

    test('has vector layers on the 108 dp adaptive-icon canvas', () {
      for (final layer in ['foreground', 'monochrome']) {
        final vector = read('$res/drawable/ic_launcher_$layer.xml');

        expect(vector, contains('<vector'), reason: layer);
        expect(vector, contains('android:viewportWidth="108"'), reason: layer);
      }
    });

    test('uses the cream background of the design spec', () {
      expect(
        read('$res/values/ic_launcher_background.xml'),
        contains('#F5F0E4'),
      );
    });

    test('has legacy PNG icons for all densities', () {
      const sizes = {
        'mdpi': 48,
        'hdpi': 72,
        'xhdpi': 96,
        'xxhdpi': 144,
        'xxxhdpi': 192,
      };
      for (final MapEntry(key: density, value: size) in sizes.entries) {
        expect(pngSize('$res/mipmap-$density/ic_launcher.png'), (
          size,
          size,
        ), reason: density);
      }
    });

    test('is used by the manifest with the app name Green Friend', () {
      final manifest = read('android/app/src/main/AndroidManifest.xml');

      expect(manifest, contains('android:icon="@mipmap/ic_launcher"'));
      expect(manifest, contains('android:label="Green Friend"'));
    });

    test('keeps the source SVG in the repository', () {
      expect(read('assets/icon/app_icon.svg'), contains('<svg'));
    });
  });
}
