import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../domain/care_log.dart';
import '../domain/care_log_repository.dart';
import '../domain/journal.dart';
import '../domain/journal_actions.dart';
import '../domain/journal_repository.dart';
import '../domain/timeline.dart';
import '../domain/photos.dart';
import '../domain/clock.dart';
import '../domain/plant.dart';
import '../domain/plant_repository.dart';
import '../domain/species.dart';
import '../domain/care_status.dart';
import '../domain/season.dart';
import '../l10n/app_localizations.dart';
import 'compare_screen.dart';
import 'journal_entry_screen.dart';
import 'plant_form_screen.dart';
import 'timeline_screen.dart';
import 'watering_actions.dart';
import 'widgets/care_button.dart';
import 'widgets/watering_label.dart';

/// Everything about one plant: its details, its watering and when it needs
/// water next.
class PlantDetailScreen extends StatefulWidget {
  const PlantDetailScreen({
    super.key,
    required this.plants,
    required this.careLogs,
    required this.journal,
    required this.photos,
    required this.species,
    required this.photoPicker,
    required this.plantId,
    this.clock = DateTime.now,
  });

  final PlantRepository plants;
  final CareLogRepository careLogs;
  final JournalRepository journal;
  final PhotoStore photos;

  /// The plant database used to suggest species and their care profile.
  final SpeciesCatalog species;
  final PhotoPicker photoPicker;
  final String plantId;

  /// Supplies today's date for the next watering.
  final Clock clock;

  @override
  State<PlantDetailScreen> createState() => _PlantDetailScreenState();
}

class _PlantDetailScreenState extends State<PlantDetailScreen> {
  late final Stream<Plant?> _plant = widget.plants.watchPlants().map(
    (plants) => plants.where((plant) => plant.id == widget.plantId).firstOrNull,
  );
  late final Stream<List<CareLog>> _logs = widget.careLogs.watchLogs(
    widget.plantId,
  );
  late final Stream<List<JournalEntry>> _entries = widget.journal.watchEntries(
    widget.plantId,
  );

  void _addEntry() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => JournalEntryScreen(
          plantId: widget.plantId,
          journal: widget.journal,
          photos: widget.photos,
          photoPicker: widget.photoPicker,
          clock: widget.clock,
        ),
      ),
    );
  }

  void _openTimeline() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TimelineScreen(
          plantId: widget.plantId,
          journal: widget.journal,
          photos: widget.photos,
        ),
      ),
    );
  }

  void _openComparison() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CompareScreen(
          plantId: widget.plantId,
          journal: widget.journal,
          photos: widget.photos,
        ),
      ),
    );
  }

  Future<void> _deleteEntry(JournalEntry entry) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteJournalEntryQuestion),
        content: Text(l10n.deletePlantMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await deleteJournalEntry(
      journal: widget.journal,
      photos: widget.photos,
      entry: entry,
    );
  }

  Future<void> _edit(Plant plant) async {
    final deleted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PlantFormScreen(
          species: widget.species,
          plants: widget.plants,
          careLogs: widget.careLogs,
          journal: widget.journal,
          photos: widget.photos,
          plant: plant,
          clock: widget.clock,
        ),
      ),
    );
    if (deleted != true || !mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return StreamBuilder<Plant?>(
      stream: _plant,
      builder: (context, snapshot) {
        final plant = snapshot.data;
        return Scaffold(
          appBar: AppBar(
            actions: [
              if (plant != null)
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: l10n.editPlantTitle,
                  onPressed: () => _edit(plant),
                ),
            ],
          ),
          body: plant == null
              ? const SizedBox.shrink()
              : _Details(
                  plant: plant,
                  profile: switch (plant.speciesId) {
                    final id? => widget.species.byId(id),
                    null => null,
                  },
                  journal: StreamBuilder<List<JournalEntry>>(
                    stream: _entries,
                    builder: (context, snapshot) => _Journal(
                      entries: snapshot.data ?? const [],
                      photos: widget.photos,
                      onAdd: _addEntry,
                      onTimeline: _openTimeline,
                      onCompare: _openComparison,
                      onDelete: _deleteEntry,
                    ),
                  ),
                  history: StreamBuilder<List<CareLog>>(
                    stream: _logs,
                    builder: (context, snapshot) =>
                        _History(snapshot.data ?? const []),
                  ),
                  today: widget.clock(),
                  onCare: (kind) => careWithUndo(
                    context,
                    plants: widget.plants,
                    careLogs: widget.careLogs,
                    plant: plant,
                    kind: kind,
                    today: widget.clock(),
                  ),
                ),
        );
      },
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({
    required this.plant,
    required this.profile,
    required this.today,
    required this.onCare,
    required this.journal,
    required this.history,
  });

  final Plant plant;

  /// Care profile of the plant's species, if it is linked to one.
  final Species? profile;
  final DateTime today;
  final ValueChanged<CareKind> onCare;
  final Widget journal;
  final Widget history;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final status = wateringStatus(plant, today);
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        const _Header(),
        const SizedBox(height: 20),
        Text(plant.name, style: text.headlineMedium),
        if (plant.species case final species?)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              species,
              style: text.bodyLarge?.copyWith(fontStyle: FontStyle.italic),
            ),
          ),
        if (plant.location case final location?)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                const Icon(Icons.place_outlined, size: 18),
                const SizedBox(width: 6),
                Expanded(child: Text(location, style: text.bodyMedium)),
              ],
            ),
          ),
        const SizedBox(height: 24),
        if (profile case final profile?) ...[
          _CareTile(
            icon: Icons.wb_sunny_outlined,
            title: l10n.lightTileTitle,
            value: switch (profile.light) {
              Light.low => l10n.lightLow,
              Light.medium => l10n.lightMedium,
              Light.brightIndirect => l10n.lightBrightIndirect,
              Light.direct => l10n.lightDirect,
            },
          ),
          const SizedBox(height: 12),
          _CareTile(
            icon: Icons.opacity,
            title: l10n.humidityTileTitle,
            value: switch (profile.humidity) {
              Humidity.low => l10n.humidityLow,
              Humidity.medium => l10n.humidityMedium,
              Humidity.high => l10n.humidityHigh,
            },
          ),
          const SizedBox(height: 12),
        ],
        _CareTile(
          icon: Icons.water_drop_outlined,
          title: l10n.wateringTileTitle,
          value: switch (plant.wateringIntervalDays) {
            final days? => l10n.wateringEvery(days),
            null => l10n.noWateringSchedule,
          },
        ),
        if (plant.winterRest && isWinterRest(today)) ...[
          const SizedBox(height: 12),
          _CareTile(
            icon: Icons.ac_unit,
            title: l10n.winterRestTitle,
            value: l10n.winterRestActive,
          ),
        ],
        if (status is! NotScheduled) ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.nextWatering, style: text.titleMedium),
                  const SizedBox(height: 8),
                  CareLabel(status),
                  const SizedBox(height: 16),
                  CareButton(
                    kind: const Water(),
                    doneToday: isSameDay(plant.lastWateredOn, today),
                    onPressed: () => onCare(const Water()),
                  ),
                ],
              ),
            ),
          ),
        ],
        for (final kind in const [Fertilize(), Repot(), Prune()])
          if (careStatus(plant, kind, today) case final status
              when status is! NotScheduled) ...[
            const SizedBox(height: 12),
            _CareCard(
              kind: kind,
              plant: plant,
              today: today,
              status: status,
              onConfirm: () => onCare(kind),
            ),
          ],
        const SizedBox(height: 24),
        journal,
        const SizedBox(height: 24),
        history,
      ],
    );
  }
}

/// Interval, status and confirmation for fertilizing or repotting.
class _CareCard extends StatelessWidget {
  const _CareCard({
    required this.kind,
    required this.plant,
    required this.today,
    required this.status,
    required this.onConfirm,
  });

  final CareKind kind;
  final Plant plant;
  final DateTime today;
  final CareStatus status;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final (title, interval, icon) = switch (kind) {
      Water() => (
        l10n.wateringTileTitle,
        l10n.wateringEvery(plant.wateringIntervalDays ?? 0),
        Icons.water_drop_outlined,
      ),
      Fertilize() => (
        l10n.fertilizingTitle,
        l10n.wateringEvery(plant.fertilizingIntervalDays ?? 0),
        Icons.science_outlined,
      ),
      Repot() => (
        l10n.repottingTitle,
        l10n.everyMonths(plant.repottingIntervalMonths ?? 0),
        Icons.yard_outlined,
      ),
      Prune() => (
        l10n.pruningTitle,
        l10n.everyMonths(plant.pruningIntervalMonths ?? 0),
        Icons.content_cut,
      ),
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.secondaryContainer,
                  foregroundColor: theme.colorScheme.onSecondaryContainer,
                  child: Icon(icon),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.labelMedium),
                      Text(interval, style: theme.textTheme.titleMedium),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            CareLabel(status, kind: kind),
            const SizedBox(height: 12),
            CareButton(
              kind: kind,
              doneToday: isSameDay(switch (kind) {
                Water() => plant.lastWateredOn,
                Fertilize() => plant.lastFertilizedOn,
                Repot() => plant.lastRepottedOn,
                Prune() => plant.lastPrunedOn,
              }, today),
              onPressed: onConfirm,
            ),
          ],
        ),
      ),
    );
  }
}

/// The growth journal: photos and notes, newest first.
class _Journal extends StatelessWidget {
  const _Journal({
    required this.entries,
    required this.photos,
    required this.onAdd,
    required this.onTimeline,
    required this.onCompare,
    required this.onDelete,
  });

  final List<JournalEntry> entries;
  final PhotoStore photos;
  final VoidCallback onAdd;
  final VoidCallback onTimeline;
  final VoidCallback onCompare;
  final ValueChanged<JournalEntry> onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final dates = DateFormat.yMMMd(Localizations.localeOf(context).toString());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.journalTitle, style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: Text(l10n.addJournalEntry),
            ),
            if (entries.isNotEmpty)
              TextButton.icon(
                onPressed: onTimeline,
                icon: const Icon(Icons.timeline),
                label: Text(l10n.timelineTitle),
              ),
            if (defaultComparison(entries) != null)
              TextButton.icon(
                onPressed: onCompare,
                icon: const Icon(Icons.compare_outlined),
                label: Text(l10n.compareTitle),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (entries.isEmpty)
          Text(l10n.noJournalEntries, style: theme.textTheme.bodyMedium),
        for (final entry in entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (entry.photo case final photo?)
                    AspectRatio(
                      key: ValueKey('journal-photo-${entry.id}'),
                      aspectRatio: 4 / 3,
                      child: Image.file(
                        photos.fileFor(photo),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => ColoredBox(
                          color: theme.colorScheme.secondaryContainer,
                          child: const Icon(Icons.image_outlined, size: 48),
                        ),
                      ),
                    ),
                  ListTile(
                    title: Text(dates.format(entry.day)),
                    subtitle: switch (entry.note) {
                      final note? => Text(note),
                      null => null,
                    },
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: l10n.deleteJournalEntry,
                      onPressed: () => onDelete(entry),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// The most recent care, newest first.
class _History extends StatelessWidget {
  const _History(this.logs);

  static const maxEntries = 10;

  final List<CareLog> logs;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final dates = DateFormat.yMMMd(Localizations.localeOf(context).toString());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.history, style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        if (logs.isEmpty)
          Text(l10n.noCareLogged, style: theme.textTheme.bodyMedium)
        else
          Card(
            child: Column(
              children: [
                for (final log in logs.take(maxEntries))
                  ListTile(
                    leading: Icon(switch (log.kind) {
                      Water() => Icons.water_drop_outlined,
                      Fertilize() => Icons.science_outlined,
                      Repot() => Icons.yard_outlined,
                      Prune() => Icons.content_cut,
                    }, color: theme.colorScheme.primary),
                    title: Text(dates.format(log.day)),
                    subtitle: Text(switch (log.kind) {
                      Water() => l10n.watered,
                      Fertilize() => l10n.fertilized,
                      Repot() => l10n.repotted,
                      Prune() => l10n.pruned,
                    }),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Placeholder until plants have photos.
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AspectRatio(
      aspectRatio: 16 / 10,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.secondaryContainer,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Icon(
          Icons.eco_outlined,
          size: 96,
          color: scheme.onSecondaryContainer,
        ),
      ),
    );
  }
}

class _CareTile extends StatelessWidget {
  const _CareTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: theme.colorScheme.secondaryContainer,
              foregroundColor: theme.colorScheme.onSecondaryContainer,
              child: Icon(icon),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.labelMedium),
                  Text(value, style: theme.textTheme.titleMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
