import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/data/home_care_widget.dart';

const providerPath =
    'android/app/src/main/kotlin/de/maestrodev/green_friend/CareWidgetProvider.kt';

void main() {
  group('home-screen widget setup', () {
    test('declares the widget receiver with its provider info', () {
      final manifest = File('android/app/src/main/AndroidManifest.xml')
          .readAsStringSync();

      expect(manifest, contains('.CareWidgetProvider'));
      expect(manifest, contains('android.appwidget.action.APPWIDGET_UPDATE'));
      expect(manifest, contains('@xml/care_widget_info'));
      expect(
        File('android/app/src/main/res/xml/care_widget_info.xml').existsSync(),
        isTrue,
      );
    });

    test('reads the same data keys the app writes', () {
      final provider = File(providerPath).readAsStringSync();

      for (final key in [
        CareWidgetKeys.title,
        CareWidgetKeys.empty,
        CareWidgetKeys.stale,
        CareWidgetKeys.day,
        CareWidgetKeys.count,
        CareWidgetKeys.rowPrefix,
      ]) {
        expect(provider, contains('"$key'), reason: key);
      }
      expect(
        CareWidgetKeys.androidProvider,
        'de.maestrodev.green_friend.CareWidgetProvider',
      );
    });
  });
}
