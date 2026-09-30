import 'package:flutter/material.dart';

import '../domain/care_log.dart';
import '../domain/care_log_repository.dart';
import '../domain/clock.dart';
import '../domain/plant.dart';
import '../domain/plant_repository.dart';
import '../domain/urgency.dart';
import '../domain/care_status.dart';
import '../l10n/app_localizations.dart';
import 'plant_detail_screen.dart';
import 'plant_form_screen.dart';
import 'settings_screen.dart';
import 'watering_actions.dart';
import 'widgets/watering_label.dart';

/// The start screen: the user's plants, or a friendly hint while there are
/// none yet.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.plants,
    required this.careLogs,
    this.clock = DateTime.now,
  });

  final PlantRepository plants;
  final CareLogRepository careLogs;

  /// Supplies today's date for watering defaults and due dates.
  final Clock clock;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Stream<List<Plant>> _plants = widget.plants.watchPlants();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.settingsTitle,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openForm,
        icon: const Icon(Icons.add),
        label: Text(l10n.addPlant),
      ),
      body: StreamBuilder<List<Plant>>(
        stream: _plants,
        builder: (context, snapshot) => switch (snapshot.data) {
          null => const SizedBox.shrink(),
          [] => _EmptyHint(l10n.emptyPlantsHint),
          final plants => _PlantOverview(
            plants: plants,
            today: widget.clock(),
            onOpen: _openDetail,
            onWatered: _water,
          ),
        },
      ),
    );
  }

  Future<void> _water(Plant plant) => waterWithUndo(
    context,
    plants: widget.plants,
    careLogs: widget.careLogs,
    plant: plant,
    today: widget.clock(),
  );

  void _openForm() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PlantFormScreen(
          plants: widget.plants,
          careLogs: widget.careLogs,
          clock: widget.clock,
        ),
      ),
    );
  }

  void _openDetail(Plant plant) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PlantDetailScreen(
          plants: widget.plants,
          careLogs: widget.careLogs,
          plantId: plant.id,
          clock: widget.clock,
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}

/// Greeting, today's summary and all plants, the most urgent first.
class _PlantOverview extends StatelessWidget {
  const _PlantOverview({
    required this.plants,
    required this.today,
    required this.onOpen,
    required this.onWatered,
  });

  final List<Plant> plants;
  final DateTime today;
  final ValueChanged<Plant> onOpen;
  final ValueChanged<Plant> onWatered;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final sorted = sortedByUrgency(plants, today);
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          sliver: SliverList.list(
            children: [
              Text(l10n.greeting, style: text.headlineLarge),
              const SizedBox(height: 4),
              Text(l10n.greetingSubtitle, style: text.bodyLarge),
              const SizedBox(height: 20),
              _SummaryCard(
                l10n.attentionSummary(
                  needingAttention(plants, today),
                  plants.length,
                ),
              ),
              const SizedBox(height: 28),
              Text(l10n.myPlants, style: text.titleLarge),
              const SizedBox(height: 12),
            ],
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
          sliver: SliverList.builder(
            itemCount: sorted.length,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _PlantCard(
                sorted[index],
                status: wateringStatus(sorted[index], today),
                otherDue: [
                  for (final kind in const [Fertilize(), Repot()])
                    if (careStatus(sorted[index], kind, today) case final status
                        when status is DueToday || status is Overdue)
                      (kind, status),
                ],
                onTap: () => onOpen(sorted[index]),
                onWatered: () => onWatered(sorted[index]),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onPrimary = theme.colorScheme.onPrimary;
    return Card(
      color: theme.colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(Icons.water_drop_outlined, color: onPrimary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.titleMedium?.copyWith(color: onPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlantCard extends StatelessWidget {
  const _PlantCard(
    this.plant, {
    required this.status,
    required this.otherDue,
    required this.onTap,
    required this.onWatered,
  });

  final Plant plant;
  final CareStatus status;
  final List<(CareKind, CareStatus)> otherDue;
  final VoidCallback onTap;
  final VoidCallback onWatered;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.secondaryContainer,
                foregroundColor: theme.colorScheme.onSecondaryContainer,
                child: const Icon(Icons.eco_outlined),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _PlantTexts(
                  plant,
                  status: status,
                  otherDue: otherDue,
                  onWatered: onWatered,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlantTexts extends StatelessWidget {
  const _PlantTexts(
    this.plant, {
    required this.status,
    required this.otherDue,
    required this.onWatered,
  });

  final Plant plant;
  final CareStatus status;
  final List<(CareKind, CareStatus)> otherDue;
  final VoidCallback onWatered;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(plant.name, style: text.titleMedium),
        if (plant.species case final species?)
          Text(
            species,
            style: text.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
          ),
        if (plant.location case final location?)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                const Icon(Icons.place_outlined, size: 16),
                const SizedBox(width: 4),
                Expanded(child: Text(location, style: text.bodySmall)),
              ],
            ),
          ),
        if (status is! NotScheduled)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Expanded(child: CareLabel(status)),
                TextButton.icon(
                  onPressed: onWatered,
                  icon: const Icon(Icons.check),
                  label: Text(AppLocalizations.of(context).watered),
                ),
              ],
            ),
          ),
        if (otherDue.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (kind, status) in otherDue)
                  CareLabel(status, kind: kind),
              ],
            ),
          ),
      ],
    );
  }
}
