import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../domain/care_actions.dart';
import '../domain/care_log.dart';
import '../domain/care_log_repository.dart';
import '../domain/care_status.dart';
import '../domain/clock.dart';
import '../domain/plant.dart';
import '../domain/plant_repository.dart';
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

  /// Supplies today's date as the default last watering, fertilizing and
  /// repotting.
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
  late final _today = dayOf(widget.clock());
  late final _water = _ScheduleInput(
    interval: widget.plant?.wateringIntervalDays,
    last: widget.plant?.lastWateredOn,
    today: _today,
  );
  late final _fertilize = _ScheduleInput(
    interval: widget.plant?.fertilizingIntervalDays,
    last: widget.plant?.lastFertilizedOn,
    today: _today,
  );
  late final _repot = _ScheduleInput(
    interval: widget.plant?.repottingIntervalMonths,
    last: widget.plant?.lastRepottedOn,
    today: _today,
  );
  var _saving = false;

  List<(CareKind, _ScheduleInput)> get _schedules => [
    (const Water(), _water),
    (const Fertilize(), _fertilize),
    (const Repot(), _repot),
  ];

  @override
  void initState() {
    super.initState();
    for (final (_, input) in _schedules) {
      input.controller.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _species.dispose();
    _location.dispose();
    for (final (_, input) in _schedules) {
      input.controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final water = _water.interval(max: 365);
    final fertilize = _fertilize.interval(max: 365);
    final repot = _repot.interval(max: 60);
    if (widget.plant case final existing?) {
      await widget.plants.update(
        Plant(
          id: existing.id,
          name: _name.text,
          species: _species.text,
          location: _location.text,
          wateringIntervalDays: water,
          lastWateredOn: _water.lastToSave(water),
          fertilizingIntervalDays: fertilize,
          lastFertilizedOn: _fertilize.lastToSave(fertilize),
          repottingIntervalMonths: repot,
          lastRepottedOn: _repot.lastToSave(repot),
        ),
      );
    } else {
      await widget.plants.add(
        name: _name.text,
        species: _species.text,
        location: _location.text,
        wateringIntervalDays: water,
        lastWateredOn: _water.lastToSave(water),
        fertilizingIntervalDays: fertilize,
        lastFertilizedOn: _fertilize.lastToSave(fertilize),
        repottingIntervalMonths: repot,
        lastRepottedOn: _repot.lastToSave(repot),
      );
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _pickLastDone(CareKind kind, _ScheduleInput input) async {
    final lookBack = kind is Repot ? 5 * 365 : 365;
    final picked = await showDatePicker(
      context: context,
      initialDate: input.last.isAfter(_today) ? _today : input.last,
      firstDate: _today.subtract(Duration(days: lookBack)),
      lastDate: _today,
    );
    if (picked == null || !mounted) return;
    setState(() => input.last = dayOf(picked));
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
            for (final (kind, input) in _schedules) ...[
              _ScheduleFields(
                kind: kind,
                input: input,
                onPickDate: () => _pickLastDone(kind, input),
              ),
              const SizedBox(height: 16),
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

/// The text field for one care interval and its last-done date.
class _ScheduleInput {
  _ScheduleInput({
    required int? interval,
    required DateTime? last,
    required DateTime today,
  }) : controller = TextEditingController(text: interval?.toString()),
       _stored = last,
       last = last ?? today;

  final TextEditingController controller;
  final DateTime? _stored;

  /// The last-done day shown in the form (today unless stored).
  DateTime last;

  bool get active => controller.text.trim().isNotEmpty;

  int? interval({required int max}) =>
      parseInterval(controller.text, max: max).days;

  /// Without an interval the stored day is kept unchanged.
  DateTime? lastToSave(int? interval) => interval == null ? _stored : last;
}

class _ScheduleFields extends StatelessWidget {
  const _ScheduleFields({
    required this.kind,
    required this.input,
    required this.onPickDate,
  });

  final CareKind kind;
  final _ScheduleInput input;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final max = kind is Repot ? 60 : 365;
    final (label, invalid, icon) = switch (kind) {
      Water() => (
        l10n.wateringIntervalLabel,
        l10n.wateringIntervalInvalid,
        Icons.water_drop_outlined,
      ),
      Fertilize() => (
        l10n.fertilizingIntervalLabel,
        l10n.wateringIntervalInvalid,
        Icons.science_outlined,
      ),
      Repot() => (
        l10n.repottingIntervalLabel,
        l10n.repottingIntervalInvalid,
        Icons.yard_outlined,
      ),
    };
    final date = DateFormat.yMMMd(Localizations.localeOf(context).toString())
        .format(input.last);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: input.controller,
          decoration: InputDecoration(labelText: label),
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          validator: (value) =>
              parseInterval(value ?? '', max: max).valid ? null : invalid,
        ),
        if (input.active) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onPickDate,
            icon: Icon(icon),
            label: Text(switch (kind) {
              Water() => l10n.lastWatered(date),
              Fertilize() => l10n.lastFertilized(date),
              Repot() => l10n.lastRepotted(date),
            }),
          ),
        ],
      ],
    );
  }
}
