import 'package:flutter/material.dart';

import '../domain/plant_repository.dart';
import '../l10n/app_localizations.dart';

/// Form to add a new plant.
class PlantFormScreen extends StatefulWidget {
  const PlantFormScreen({super.key, required this.plants});

  final PlantRepository plants;

  @override
  State<PlantFormScreen> createState() => _PlantFormScreenState();
}

class _PlantFormScreenState extends State<PlantFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _species = TextEditingController();
  final _location = TextEditingController();
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
    await widget.plants.add(
      name: _name.text,
      species: _species.text,
      location: _location.text,
    );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.newPlantTitle)),
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
