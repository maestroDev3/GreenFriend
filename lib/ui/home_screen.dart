import 'package:flutter/material.dart';

import '../domain/clock.dart';
import '../domain/plant.dart';
import '../domain/plant_repository.dart';
import '../l10n/app_localizations.dart';
import 'plant_form_screen.dart';
import 'settings_screen.dart';

/// The start screen: the user's plants, or a friendly hint while there are
/// none yet.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.plants,
    this.clock = DateTime.now,
  });

  final PlantRepository plants;

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
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: Text(l10n.addPlant),
      ),
      body: StreamBuilder<List<Plant>>(
        stream: _plants,
        builder: (context, snapshot) => switch (snapshot.data) {
          null => const SizedBox.shrink(),
          [] => _EmptyHint(l10n.emptyPlantsHint),
          final plants => ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            itemCount: plants.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _PlantCard(
              plants[index],
              onTap: () => _openForm(plant: plants[index]),
            ),
          ),
        },
      ),
    );
  }

  void _openForm({Plant? plant}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PlantFormScreen(
          plants: widget.plants,
          plant: plant,
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

class _PlantCard extends StatelessWidget {
  const _PlantCard(this.plant, {required this.onTap});

  final Plant plant;
  final VoidCallback onTap;

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
              Expanded(child: _PlantTexts(plant)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlantTexts extends StatelessWidget {
  const _PlantTexts(this.plant);

  final Plant plant;

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
      ],
    );
  }
}
