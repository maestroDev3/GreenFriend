import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const locales = ['en-US', 'de-DE'];

/// Google Play limits in characters.
const limits = {
  'title.txt': 30,
  'short_description.txt': 80,
  'full_description.txt': 4000,
};

void main() {
  group('store listing', () {
    for (final locale in locales) {
      test('both languages have all three texts: $locale', () {
        for (final name in limits.keys) {
          final file = File('store/listing/$locale/$name');
          expect(file.existsSync(), isTrue, reason: file.path);
          expect(file.readAsStringSync().trim(), isNotEmpty, reason: name);
        }
      });

      test('title ≤ 30, short description ≤ 80, full description ≤ 4000 '
          'characters: $locale', () {
        for (final MapEntry(key: name, value: max) in limits.entries) {
          final text = File('store/listing/$locale/$name').readAsStringSync();
          expect(text.trim().runes.length, lessThanOrEqualTo(max), reason: name);
        }
      });
    }
  });
}
