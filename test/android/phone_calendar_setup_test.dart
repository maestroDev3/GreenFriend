import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('declares the calendar permissions', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();

    expect(manifest, contains('android.permission.READ_CALENDAR'));
    expect(manifest, contains('android.permission.WRITE_CALENDAR'));
  });
}
