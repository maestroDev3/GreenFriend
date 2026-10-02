import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../domain/care_actions.dart';
import '../domain/care_log.dart';
import '../domain/care_log_repository.dart';
import '../domain/identification.dart';
import '../domain/journal_repository.dart';
import '../domain/photos.dart';
import '../domain/care_status.dart';
import '../domain/clock.dart';
import '../domain/plant.dart';
import '../domain/plant_repository.dart';
import '../domain/species.dart';
import '../l10n/app_localizations.dart';
import 'settings_controller.dart';

/// Form to add a new plant or to edit and delete an existing one.
///
/// Pops with `true` when the plant was deleted.
class PlantFormScreen extends StatefulWidget {
  const PlantFormScreen({
    super.key,
    required this.plants,
    required this.careLogs,
    required this.journal,
    required this.photos,
    required this.species,
    this.plant,
    this.photoPicker,
    this.identifier,
    this.clock = DateTime.now,
  });

  final PlantRepository plants;
  final CareLogRepository careLogs;
  final JournalRepository journal;
  final PhotoStore photos;

  /// The plant database used to suggest species and their care profile.
  final SpeciesCatalog species;

  /// Supplies today's date as the default last watering, fertilizing and
  /// repotting.
  final Clock clock;

  /// The plant to edit; `null` creates a new plant.
  final Plant? plant;

  /// Takes the photo for [identifier].
  final PhotoPicker? photoPicker;

  /// Identifies the species from a photo; `null` hides "Identify from photo".
  final PlantIdentifier? identifier;

  @override
  State<PlantFormScreen> createState() => _PlantFormScreenState();
}

class _PlantFormScreenState extends State<PlantFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.plant?.name);
  late final _species = TextEditingController(text: widget.plant?.species);
  late final _location = TextEditingController(text: widget.plant?.location);
  final _speciesFocus = FocusNode();

  /// Care profile the plant is linked to; cleared when the species text is
  /// edited away from [_linkedName].
  late String? _speciesId = widget.plant?.speciesId;
  late String? _linkedName = widget.plant?.species;
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
  late final _prune = _ScheduleInput(
    interval: widget.plant?.pruningIntervalMonths,
    last: widget.plant?.lastPrunedOn,
    today: _today,
  );
  var _saving = false;
  late var _winterRest = widget.plant?.winterRest ?? true;

  /// Photo taken for identification; saved to the journal with the plant,
  /// deleted again when the form is left without saving.
  String? _photo;
  var _photoSaved = false;
  var _identifying = false;
  String? _identificationNote;

  List<(CareKind, _ScheduleInput)> get _schedules => [
    (const Water(), _water),
    (const Fertilize(), _fertilize),
    (const Repot(), _repot),
    (const Prune(), _prune),
  ];

  @override
  void initState() {
    super.initState();
    _species.addListener(_unlinkIfEdited);
    for (final (_, input) in _schedules) {
      input.controller.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    if (_photo case final photo? when !_photoSaved) {
      unawaited(widget.photos.delete(photo));
    }
    _name.dispose();
    _species.dispose();
    _location.dispose();
    _speciesFocus.dispose();
    for (final (_, input) in _schedules) {
      input.controller.dispose();
    }
    super.dispose();
  }

  void _unlinkIfEdited() {
    if (_speciesId != null && _species.text.trim() != _linkedName) {
      setState(() => _speciesId = null);
    }
  }

  void _applySpecies(Species species, String name) {
    setState(() {
      _speciesId = species.id;
      _linkedName = name;
      _identificationNote = null;
      _setIntervals(species);
    });
  }

  void _setIntervals(Species species) {
    _water.controller.text = '${species.wateringIntervalDays}';
    _fertilize.controller.text = '${species.fertilizingIntervalDays}';
    _repot.controller.text = '${species.repottingIntervalMonths}';
    _prune.controller.text = species.pruningIntervalMonths?.toString() ?? '';
  }

  void _setNameIfEmpty(String name) {
    if (_name.text.trim().isEmpty) _name.text = name;
  }

  Future<void> _identify() async {
    final l10n = AppLocalizations.of(context);
    final identifier = widget.identifier;
    final picker = widget.photoPicker;
    if (identifier == null || picker == null) return;
    final apiKey = SettingsScope.of(context).plantIdApiKey;
    if (apiKey == null) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.apiKeyNeededTitle),
          content: Text(l10n.apiKeyNeededMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.ok),
            ),
          ],
        ),
      );
      return;
    }
    final source = await showModalBottomSheet<_PhotoSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => const _PhotoSourceSheet(),
    );
    if (source == null) return;
    final path = await switch (source) {
      _PhotoSource.camera => picker.takePhoto(),
      _PhotoSource.gallery => picker.pickFromGallery(),
    };
    if (path == null || !mounted) return;
    final language = Localizations.localeOf(context).languageCode;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _identifying = true);
    List<IdentificationCandidate>? found;
    IdentificationFailure? failure;
    try {
      final name = await widget.photos.save(path);
      if (!mounted) {
        // The form was left meanwhile; nobody will save or delete the photo.
        unawaited(widget.photos.delete(name));
        return;
      }
      _replacePhoto(name);
      final bytes = await widget.photos.readBytes(name);
      if (bytes == null) throw const ServiceUnavailable('photo not readable');
      found = await identifier.identify(
        bytes,
        apiKey: apiKey,
        languageCode: language,
      );
    } on IdentificationFailure catch (error) {
      failure = error;
    } catch (_) {
      // The progress indicator must never get stuck.
      failure = const ServiceUnavailable('unexpected error');
    } finally {
      if (mounted) setState(() => _identifying = false);
    }
    if (failure != null) {
      messenger.showSnackBar(
        SnackBar(content: Text(_failureMessage(l10n, failure))),
      );
      return;
    }
    if (found == null || !mounted) return;
    final best = topCandidates(found);
    final chosen = await showModalBottomSheet<IdentificationCandidate>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _CandidateSheet(candidates: best),
    );
    if (chosen == null || !mounted) return;
    _applyCandidate(chosen, language, l10n);
  }

  void _replacePhoto(String name) {
    final previous = _photo;
    setState(() => _photo = name);
    if (previous != null) unawaited(widget.photos.delete(previous));
  }

  void _applyCandidate(
    IdentificationCandidate candidate,
    String language,
    AppLocalizations l10n,
  ) {
    final commonName =
        candidate.commonNames.firstOrNull ?? candidate.scientificName;
    switch (matchSpecies(candidate, widget.species)) {
      case ExactSpecies(:final species):
        final name = species.displayName(language);
        _setNameIfEmpty(name);
        _species.text = name;
        _applySpecies(species, name);
      case SameGenus(:final template):
        _setNameIfEmpty(commonName);
        _species.text = candidate.scientificName;
        setState(() {
          _speciesId = null;
          _setIntervals(template);
          _identificationNote = l10n.intervalsFromGenus(
            template.displayName(language),
          );
        });
      case NoSpecies():
        _setNameIfEmpty(commonName);
        _species.text = candidate.scientificName;
        setState(() {
          _speciesId = null;
          _identificationNote = l10n.intervalsUnknownSpecies(
            candidate.scientificName,
          );
        });
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final water = _water.interval(max: 365);
    final fertilize = _fertilize.interval(max: 365);
    final repot = _repot.interval(max: 60);
    final prune = _prune.interval(max: 60);
    if (widget.plant case final existing?) {
      await widget.plants.update(
        Plant(
          id: existing.id,
          name: _name.text,
          species: _species.text,
          speciesId: _speciesId,
          location: _location.text,
          wateringIntervalDays: water,
          lastWateredOn: _water.lastToSave(water),
          fertilizingIntervalDays: fertilize,
          lastFertilizedOn: _fertilize.lastToSave(fertilize),
          repottingIntervalMonths: repot,
          lastRepottedOn: _repot.lastToSave(repot),
          pruningIntervalMonths: prune,
          lastPrunedOn: _prune.lastToSave(prune),
          winterRest: _winterRest,
        ),
      );
    } else {
      final plant = await widget.plants.add(
        name: _name.text,
        species: _species.text,
        speciesId: _speciesId,
        location: _location.text,
        wateringIntervalDays: water,
        lastWateredOn: _water.lastToSave(water),
        fertilizingIntervalDays: fertilize,
        lastFertilizedOn: _fertilize.lastToSave(fertilize),
        repottingIntervalMonths: repot,
        lastRepottedOn: _repot.lastToSave(repot),
        pruningIntervalMonths: prune,
        lastPrunedOn: _prune.lastToSave(prune),
        winterRest: _winterRest,
      );
      if (_photo case final photo?) {
        await widget.journal.add(plantId: plant.id, day: _today, photo: photo);
        _photoSaved = true;
      }
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _pickLastDone(CareKind kind, _ScheduleInput input) async {
    final lookBack = kind is Repot || kind is Prune ? 5 * 365 : 365;
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
      journal: widget.journal,
      photos: widget.photos,
      plantId: plant.id,
    );
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
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
            if (widget.plant == null && widget.identifier != null) ...[
              if (_photo case final photo?) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
                    child: Image.file(
                      widget.photos.fileFor(photo),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const _PhotoPlaceholder(),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.photoGoesToJournal,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
              ],
              if (_identifying) ...[
                const LinearProgressIndicator(),
                const SizedBox(height: 8),
                Text(l10n.identifyingPlant),
              ] else
                OutlinedButton.icon(
                  onPressed: _identify,
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: Text(l10n.identifyFromPhoto),
                ),
              const SizedBox(height: 16),
            ],
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
            RawAutocomplete<Species>(
              textEditingController: _species,
              focusNode: _speciesFocus,
              displayStringForOption: (species) =>
                  species.displayName(language),
              optionsBuilder: (value) => widget.species
                  .search(value.text, languageCode: language)
                  .take(8),
              onSelected: (species) =>
                  _applySpecies(species, species.displayName(language)),
              fieldViewBuilder: (context, controller, focusNode, _) =>
                  TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      labelText: l10n.plantSpeciesLabel,
                      helperText: _speciesId == null
                          ? null
                          : l10n.speciesLinkedHint,
                      helperMaxLines: 3,
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.next,
                  ),
              optionsViewBuilder: (context, onSelected, options) =>
                  _SpeciesOptions(
                    options: options.toList(),
                    language: language,
                    onSelected: onSelected,
                  ),
            ),
            if (_identificationNote case final note?) ...[
              const SizedBox(height: 8),
              Text(
                note,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
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
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.ac_unit),
              title: Text(l10n.winterRestSwitch),
              subtitle: Text(l10n.winterRestSwitchHelp),
              value: _winterRest,
              onChanged: (value) => setState(() => _winterRest = value),
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

String _failureMessage(AppLocalizations l10n, IdentificationFailure failure) =>
    switch (failure) {
      MissingApiKey() => l10n.apiKeyNeededMessage,
      InvalidApiKey() => l10n.identifyInvalidKey,
      NoCredits() => l10n.identifyNoCredits,
      NotAPlant() => l10n.identifyNotAPlant,
      ServiceUnavailable() => l10n.identifyUnavailable,
    };

enum _PhotoSource { camera, gallery }

/// Lets the user choose between camera and gallery for identification.
class _PhotoSourceSheet extends StatelessWidget {
  const _PhotoSourceSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: Text(l10n.takePhoto),
            onTap: () => Navigator.of(context).pop(_PhotoSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(l10n.choosePhoto),
            onTap: () => Navigator.of(context).pop(_PhotoSource.gallery),
          ),
        ],
      ),
    );
  }
}

/// The best identification results; pops with the chosen candidate, or
/// `null` to enter the plant manually.
class _CandidateSheet extends StatelessWidget {
  const _CandidateSheet({required this.candidates});

  final List<IdentificationCandidate> candidates;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final percent = NumberFormat.percentPattern(
      Localizations.localeOf(context).toString(),
    );
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(
              l10n.identificationResultsTitle,
              style: theme.textTheme.titleLarge,
            ),
          ),
          for (final candidate in candidates)
            ListTile(
              title: Text(
                candidate.commonNames.firstOrNull ?? candidate.scientificName,
              ),
              subtitle: candidate.commonNames.isEmpty
                  ? null
                  : Text(candidate.scientificName),
              trailing: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(percent.format(candidate.probability)),
                  if (isUncertain(candidate.probability))
                    Text(
                      l10n.uncertainCandidate,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                ],
              ),
              onTap: () => Navigator.of(context).pop(candidate),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.enterManually),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown while the identification photo is loading or cannot be read.
class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.secondaryContainer,
      child: Icon(
        Icons.image_outlined,
        size: 48,
        color: scheme.onSecondaryContainer,
      ),
    );
  }
}

/// Species suggestions shown below the species field while typing.
class _SpeciesOptions extends StatelessWidget {
  const _SpeciesOptions({
    required this.options,
    required this.language,
    required this.onSelected,
  });

  final List<Species> options;
  final String language;
  final ValueChanged<Species> onSelected;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 280),
          child: ListView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            itemCount: options.length,
            itemBuilder: (context, index) {
              final species = options[index];
              return ListTile(
                key: ValueKey('species-option-${species.id}'),
                title: Text(species.displayName(language)),
                subtitle: Text(species.scientificName),
                onTap: () => onSelected(species),
              );
            },
          ),
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
    final max = kind is Repot || kind is Prune ? 60 : 365;
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
      Prune() => (
        l10n.pruningIntervalLabel,
        l10n.repottingIntervalInvalid,
        Icons.content_cut,
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
              Prune() => l10n.lastPruned(date),
            }),
          ),
        ],
      ],
    );
  }
}
