import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../domain/care_actions.dart';
import '../domain/care_log_repository.dart';
import '../domain/clock.dart';

import '../domain/plant.dart';
import '../domain/plant_repository.dart';
import '../domain/watering.dart';
import '../l10n/app_localizations.dart';

/// Form to add a new plant or to edit and delete an existing one.
///
/// Pops with `true` when the plant was deleted.
class PlantFormScreen extends StatefulWidget {
  const PlantFormScreen({
    super.key,
    required this.plants,
    required this.careLogs,
    this.plant,
    this.clock = DateTime.now,
  });

  final PlantRepository plants;
  final CareLogRepository careLogs;

  /// Supplies today's date as the default last watering.
  final Clock clock;

  /// The plant to edit; `null` creates a new plant.
  final Plant? plant;

  @override
  State<PlantFormScreen> createState() => _PlantFormScreenState();
}

class _PlantFormScreenState extends State<PlantFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.plant?.name);
  late final _species = TextEditingController(text: widget.plant?.species);
  late final _location = TextEditingController(text: widget.plant?.location);
  late final _interval = TextEditingController(
    text: widget.plant?.wateringIntervalDays?.toString(),
  );
  late DateTime _lastWatered =
      widget.plant?.lastWateredOn ?? dayOf(widget.clock());
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _interval.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _species.dispose();
    _location.dispose();
    _interval.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final interval = parseWateringInterval(_interval.text).days;
    final lastWatered = interval == null
        ? widget.plant?.lastWateredOn
        : _lastWatered;
    if (widget.plant case final existing?) {
      await widget.plants.update(
        Plant(
          id: existing.id,
          name: _name.text,
          species: _species.text,
          location: _location.text,
          wateringIntervalDays: interval,
          lastWateredOn: lastWatered,
        ),
      );
    } else {
      await widget.plants.add(
        name: _name.text,
        species: _species.text,
        location: _location.text,
        wateringIntervalDays: interval,
        lastWateredOn: lastWatered,
      );
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _pickLastWatered() async {
    final today = dayOf(widget.clock());
    final picked = await showDatePicker(
      context: context,
      initialDate: _lastWatered.isAfter(today) ? today : _lastWatered,
      firstDate: today.subtract(const Duration(days: 365)),
      lastDate: today,
    );
    if (picked == null || !mounted) return;
    setState(() => _lastWatered = dayOf(picked));
  }

  Future<void> _delete(Plant plant) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deletePlantQuestion(plant.name)),
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
    await deletePlant(
      plants: widget.plants,
      careLogs: widget.careLogs,
      plantId: plant.id,
    );
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.plant == null ? l10n.newPlantTitle : l10n.editPlantTitle,
        ),
        actions: [
          if (widget.plant case final plant?)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: l10n.deletePlant,
              onPressed: () => _delete(plant),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              decoration: InputDecoration(labelText: l10n.plantNameLabel),
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? l10n.plantNameRequired
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _species,
              decoration: InputDecoration(labelText: l10n.plantSpeciesLabel),
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _location,
              decoration: InputDecoration(labelText: l10n.plantLocationLabel),
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _interval,
              decoration: InputDecoration(
                labelText: l10n.wateringIntervalLabel,
              ),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              validator: (value) => parseWateringInterval(value ?? '').valid
                  ? null
                  : l10n.wateringIntervalInvalid,
            ),
            if (_interval.text.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              _LastWateredButton(
                label: l10n.lastWatered(
                  DateFormat.yMMMd(Localizations.localeOf(context).toString())
                      .format(_lastWatered),
                ),
                onPressed: _pickLastWatered,
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }
}

class _LastWateredButton extends StatelessWidget {
  const _LastWateredButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.water_drop_outlined),
        label: Text(label),
      ),
    );
  }
}
