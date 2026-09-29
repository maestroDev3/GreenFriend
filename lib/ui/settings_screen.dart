import 'package:flutter/material.dart';

import '../domain/settings.dart';
import '../l10n/app_localizations.dart';
import 'settings_controller.dart';

/// Lets the user choose the app's appearance and language.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = SettingsScope.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionTitle(l10n.appearanceSection),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (final mode in AppThemeMode.values)
                  _ChoiceTile(
                    tileKey: ValueKey('theme-${mode.name}'),
                    label: switch (mode) {
                      AppThemeMode.system => l10n.themeModeSystem,
                      AppThemeMode.light => l10n.themeModeLight,
                      AppThemeMode.dark => l10n.themeModeDark,
                    },
                    selected: settings.themeMode == mode,
                    onTap: () => settings.setThemeMode(mode),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _SectionTitle(l10n.languageSection),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (final language in AppLanguage.values)
                  _ChoiceTile(
                    tileKey: ValueKey('language-${language.name}'),
                    label: switch (language) {
                      AppLanguage.system => l10n.languageSystem,
                      AppLanguage.english => l10n.languageEnglish,
                      AppLanguage.german => l10n.languageGerman,
                    },
                    selected: settings.language == language,
                    onTap: () => settings.setLanguage(language),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.tileKey,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  /// Identifies the option in tests.
  final Key tileKey;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: tileKey,
      title: Text(label),
      selected: selected,
      trailing: selected ? const Icon(Icons.check) : null,
      onTap: onTap,
    );
  }
}
