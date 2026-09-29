import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> readArb(String name) =>
    jsonDecode(File('lib/l10n/$name').readAsStringSync())
        as Map<String, dynamic>;

Set<String> messageKeys(Map<String, dynamic> arb) =>
    arb.keys.where((key) => !key.startsWith('@')).toSet();

void main() {
  group('ARB files', () {
    test('English and German contain the same message keys', () {
      final english = readArb('app_en.arb');
      final german = readArb('app_de.arb');

      expect(messageKeys(german), messageKeys(english));
    });

    test('every English message has a description', () {
      final english = readArb('app_en.arb');

      for (final key in messageKeys(english)) {
        final metadata = english['@$key'];
        expect(metadata, isA<Map<String, dynamic>>(), reason: key);
        expect(
          (metadata as Map<String, dynamic>)['description'],
          isA<String>().having((d) => d.isNotEmpty, 'not empty', isTrue),
          reason: key,
        );
      }
    });
  });
}
