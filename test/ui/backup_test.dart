import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/ui/backup_screen.dart';

import '../support/fake_backup.dart';
import '../support/pump_app.dart';

DateTime fixedNow() => DateTime(2026, 9, 30, 10);

Future<void> pumpBackup(
  WidgetTester tester, {
  required FakeBackupArchive archive,
  required FakeFileSharing files,
  Locale locale = const Locale('en'),
}) {
  return tester.pumpApp(
    BackupScreen(archive: archive, files: files, clock: fixedNow),
    locale: locale,
  );
}

Future<void> startRestore(WidgetTester tester) async {
  await tester.tap(find.text('Restore backup'));
  await tester.pumpAndSettle();
}

void main() {
  group('BackupScreen', () {
    testWidgets('exports a dated backup and shares it', (tester) async {
      final archive = FakeBackupArchive();
      final files = FakeFileSharing();
      await pumpBackup(tester, archive: archive, files: files);

      await tester.tap(find.text('Export backup'));
      await tester.pumpAndSettle();

      const path = '/tmp/green-friend-backup-2026-09-30.zip';
      expect(archive.exported, [path]);
      expect(files.shared, [path]);
    });

    testWidgets('restores after confirmation', (tester) async {
      final archive = FakeBackupArchive();
      await pumpBackup(tester, archive: archive, files: FakeFileSharing());

      await startRestore(tester);
      expect(find.text('Replace all data?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Replace'));
      await tester.pumpAndSettle();

      expect(archive.restored, ['/downloads/backup.zip']);
      expect(find.text('Backup restored'), findsOneWidget);
    });

    testWidgets('changes nothing when cancelled', (tester) async {
      final archive = FakeBackupArchive();
      await pumpBackup(tester, archive: archive, files: FakeFileSharing());

      await startRestore(tester);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(archive.restored, isEmpty);
    });

    testWidgets('does nothing when no file is picked', (tester) async {
      final archive = FakeBackupArchive();
      await pumpBackup(
        tester,
        archive: archive,
        files: FakeFileSharing(picked: null),
      );

      await startRestore(tester);

      expect(find.text('Replace all data?'), findsNothing);
      expect(archive.restored, isEmpty);
    });

    testWidgets('reports a file that is not a backup', (tester) async {
      await pumpBackup(
        tester,
        archive: FakeBackupArchive(
          restoreError: const FormatException('broken'),
        ),
        files: FakeFileSharing(),
      );

      await startRestore(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Replace'));
      await tester.pumpAndSettle();

      expect(
        find.text('This file is not a Green Friend backup.'),
        findsOneWidget,
      );
    });

    testWidgets('shows the texts in German', (tester) async {
      await pumpBackup(
        tester,
        archive: FakeBackupArchive(),
        files: FakeFileSharing(),
        locale: const Locale('de'),
      );

      expect(find.text('Backup exportieren'), findsOneWidget);
      expect(find.text('Backup wiederherstellen'), findsOneWidget);
    });
  });
}
