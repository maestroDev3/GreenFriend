import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

List<File> dartFiles(String directory) => Directory(directory)
    .listSync(recursive: true)
    .whereType<File>()
    .where((file) => file.path.endsWith('.dart'))
    .toList();

final _dataImport = RegExp("import '(\\.\\./data/|package:green_friend/data/)");

void main() {
  test('lib/domain does not import Flutter', () {
    final files = dartFiles('lib/domain');

    expect(files, isNotEmpty);
    for (final file in files) {
      expect(
        file.readAsStringSync(),
        isNot(contains('package:flutter')),
        reason: file.path,
      );
    }
  });

  test('lib/ui does not import lib/data', () {
    for (final file in dartFiles('lib/ui')) {
      expect(
        file.readAsStringSync(),
        isNot(contains(_dataImport)),
        reason: file.path,
      );
    }
  });
}
