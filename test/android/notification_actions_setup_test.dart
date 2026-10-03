import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('declares the receiver for notification buttons', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    expect(
      manifest,
      contains('com.dexterous.flutterlocalnotifications.ActionBroadcastReceiver'),
    );
  });
}
