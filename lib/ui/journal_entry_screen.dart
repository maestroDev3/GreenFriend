import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../domain/clock.dart';
import '../domain/journal_repository.dart';
import '../domain/photos.dart';
import '../l10n/app_localizations.dart';

/// Adds a journal entry: a photo (camera or gallery), a note and the day.
class JournalEntryScreen extends StatefulWidget {
  const JournalEntryScreen({
    super.key,
    required this.plantId,
    required this.journal,
    required this.photos,
    required this.photoPicker,
    this.clock = DateTime.now,
  });

  final String plantId;
  final JournalRepository journal;
  final PhotoStore photos;
  final PhotoPicker photoPicker;
  final Clock clock;

  @override
  State<JournalEntryScreen> createState() => _JournalEntryScreenState();
}

class _JournalEntryScreenState extends State<JournalEntryScreen> {
  final _note = TextEditingController();
  late DateTime _day = dayOf(widget.clock());
  String? _pickedPath;
  var _saving = false;

  bool get _canSave =>
      !_saving && (_pickedPath != null || _note.text.trim().isNotEmpty);

  @override
  void initState() {
    super.initState();
    _note.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _pick(Future<String?> Function() picker) async {
    final path = await picker();
    if (path == null || !mounted) return;
    setState(() => _pickedPath = path);
  }

  Future<void> _pickDay() async {
    final today = dayOf(widget.clock());
    final picked = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: today.subtract(const Duration(days: 5 * 365)),
      lastDate: today,
    );
    if (picked == null || !mounted) return;
    setState(() => _day = dayOf(picked));
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final picked = _pickedPath;
    final photo = picked == null ? null : await widget.photos.save(picked);
    await widget.journal.add(
      plantId: widget.plantId,
      day: _day,
      note: _note.text,
      photo: photo,
    );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final picked = _pickedPath;
    final date = DateFormat.yMMMd(
      Localizations.localeOf(context).toString(),
    ).format(_day);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.newJournalEntry)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (picked != null)
            ClipRRect(
              key: const ValueKey('photo-preview'),
              borderRadius: BorderRadius.circular(20),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: Image.file(
                  File(picked),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const _PhotoPlaceholder(),
                ),
              ),
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => _pick(widget.photoPicker.takePhoto),
                icon: const Icon(Icons.photo_camera_outlined),
                label: Text(l10n.takePhoto),
              ),
              OutlinedButton.icon(
                onPressed: () => _pick(widget.photoPicker.pickFromGallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(l10n.choosePhoto),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _note,
            decoration: InputDecoration(labelText: l10n.journalNote),
            textCapitalization: TextCapitalization.sentences,
            minLines: 3,
            maxLines: 8,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: _pickDay,
              icon: const Icon(Icons.event_outlined),
              label: Text(date),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _canSave ? _save : null,
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }
}

/// Shown while a photo is loading or if it cannot be read.
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
