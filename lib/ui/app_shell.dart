import 'package:flutter/material.dart';

import '../domain/backup_files.dart';
import '../domain/care_log_repository.dart';
import '../domain/journal_repository.dart';
import '../domain/photos.dart';
import '../domain/clock.dart';
import '../domain/plant_repository.dart';
import '../domain/species.dart';
import '../l10n/app_localizations.dart';
import 'calendar_screen.dart';
import 'home_screen.dart';
import 'more_screen.dart';
import 'plant_form_screen.dart';
import 'plants_screen.dart';

/// The main frame of the app: Home, Plants, Calendar and More in a bottom
/// bar, with a round add button in the middle.
class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.plants,
    required this.careLogs,
    required this.journal,
    required this.photos,
    required this.species,
    required this.photoPicker,
    required this.backupArchive,
    required this.fileSharing,
    this.clock = DateTime.now,
  });

  final PlantRepository plants;
  final CareLogRepository careLogs;
  final JournalRepository journal;
  final PhotoStore photos;

  /// The plant database used to suggest species and their care profile.
  final SpeciesCatalog species;
  final PhotoPicker photoPicker;
  final BackupArchive backupArchive;
  final FileSharing fileSharing;
  final Clock clock;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  var _index = 0;

  void _addPlant() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PlantFormScreen(
          species: widget.species,
          plants: widget.plants,
          careLogs: widget.careLogs,
          journal: widget.journal,
          photos: widget.photos,
          clock: widget.clock,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final tabs = [
      (Icons.home_outlined, l10n.navHome),
      (Icons.eco_outlined, l10n.navPlants),
      (Icons.calendar_month_outlined, l10n.calendarTitle),
      (Icons.menu, l10n.navMore),
    ];
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          HomeScreen(
            species: widget.species,
            plants: widget.plants,
            careLogs: widget.careLogs,
            journal: widget.journal,
            photos: widget.photos,
            photoPicker: widget.photoPicker,
            clock: widget.clock,
            showActions: false,
          ),
          PlantsScreen(
            species: widget.species,
            plants: widget.plants,
            careLogs: widget.careLogs,
            journal: widget.journal,
            photos: widget.photos,
            photoPicker: widget.photoPicker,
            clock: widget.clock,
          ),
          CalendarScreen(
            plants: widget.plants,
            careLogs: widget.careLogs,
            clock: widget.clock,
          ),
          MoreScreen(
            backupArchive: widget.backupArchive,
            fileSharing: widget.fileSharing,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addPlant,
        tooltip: l10n.addPlant,
        shape: const CircleBorder(),
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: scheme.surfaceContainer,
        padding: EdgeInsets.zero,
        child: Row(
          children: [
            for (final (index, (icon, label)) in tabs.indexed) ...[
              if (index == 2) const SizedBox(width: 72),
              Expanded(
                child: _NavItem(
                  icon: icon,
                  label: label,
                  selected: index == _index,
                  onTap: () => setState(() => _index = index),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
