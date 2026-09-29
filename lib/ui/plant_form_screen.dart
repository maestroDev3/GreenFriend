import 'package:flutter/material.dart';

import '../domain/plant.dart';
import '../domain/plant_repository.dart';
import '../l10n/app_localizations.dart';

/// Form to add a new plant or to edit and delete an existing one.
class PlantFormScreen extends StatefulWidget {
  const PlantFormScreen({super.key, required this.plants, this.plant});

  final PlantRepository plants;

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
  var _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _species.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    if (widget.plant case final existing?) {
      await widget.plants.update(
        Plant(
          id: existing.id,
          name: _name.text,
          species: _species.text,
          location: _location.text,
        ),
      );
    } else {
      await widget.plants.add(
        name: _name.text,
        species: _species.text,
        location: _location.text,
      );
    }
    if (!mounted) return;
    Navigator.of(context).pop();
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
    await widget.plants.delete(plant.id);
    if (!mounted) return;
    Navigator.of(context).pop();
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
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _save(),
            ),
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
