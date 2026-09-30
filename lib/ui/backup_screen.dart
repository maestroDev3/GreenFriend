import 'package:flutter/material.dart';

import '../domain/backup_files.dart';
import '../domain/clock.dart';
import '../l10n/app_localizations.dart';

/// Export all data as one file and restore it, e.g. on a new phone.
class BackupScreen extends StatefulWidget {
  const BackupScreen({
    super.key,
    required this.archive,
    required this.files,
    this.clock = DateTime.now,
  });

  final BackupArchive archive;
  final FileSharing files;

  /// Supplies the date in the file name.
  final Clock clock;

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  var _busy = false;

  String get _fileName {
    final day = widget.clock();
    String two(int value) => value.toString().padLeft(2, '0');
    return 'green-friend-backup-${day.year}-${two(day.month)}-'
        '${two(day.day)}.zip';
  }

  Future<void> _export() async {
    setState(() => _busy = true);
    try {
      final path = await widget.files.temporaryPath(_fileName);
      await widget.archive.export(path);
      await widget.files.shareFile(path);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final path = await widget.files.pickFile();
    if (path == null || !mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.restoreQuestion),
        content: Text(l10n.restoreWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.replace),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await widget.archive.restore(path);
      messenger.showSnackBar(SnackBar(content: Text(l10n.backupRestored)));
    } on FormatException {
      messenger.showSnackBar(SnackBar(content: Text(l10n.notABackup)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.backupTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.backupExplanation, style: text.bodyMedium),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _busy ? null : _export,
            icon: const Icon(Icons.upload_outlined),
            label: Text(l10n.exportBackup),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _busy ? null : _restore,
            icon: const Icon(Icons.download_outlined),
            label: Text(l10n.restoreBackup),
          ),
          if (_busy) ...[
            const SizedBox(height: 24),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }
}
