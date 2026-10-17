import 'package:flutter/material.dart';

import '../domain/backup_files.dart';
import '../domain/missing_species.dart';
import '../l10n/app_localizations.dart';
import 'backup_screen.dart';
import 'missing_species_screen.dart';
import 'settings_screen.dart';

/// Settings and information about the app.
class MoreScreen extends StatelessWidget {
  const MoreScreen({
    super.key,
    required this.backupArchive,
    required this.fileSharing,
    this.missingSpecies,
  });

  final BackupArchive backupArchive;
  final FileSharing fileSharing;

  /// Identified species without a care profile; `null` hides the entry.
  final MissingSpeciesRepository? missingSpecies;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navMore)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: Text(l10n.settingsTitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SettingsScreen(),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.backup_outlined),
                  title: Text(l10n.backupTitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => BackupScreen(
                        archive: backupArchive,
                        files: fileSharing,
                      ),
                    ),
                  ),
                ),
                if (missingSpecies case final repository?)
                  ListTile(
                    leading: const Icon(Icons.playlist_add_outlined),
                    title: Text(l10n.missingSpeciesTitle),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            MissingSpeciesScreen(repository: repository),
                      ),
                    ),
                  ),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(l10n.about),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: l10n.appTitle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
