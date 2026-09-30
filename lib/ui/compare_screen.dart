import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../domain/journal.dart';
import '../domain/journal_repository.dart';
import '../domain/photos.dart';
import '../domain/timeline.dart';
import '../l10n/app_localizations.dart';

/// Two journal photos on top of each other; a slider reveals how the plant
/// has grown.
class CompareScreen extends StatefulWidget {
  const CompareScreen({
    super.key,
    required this.plantId,
    required this.journal,
    required this.photos,
  });

  final String plantId;
  final JournalRepository journal;
  final PhotoStore photos;

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  late final Stream<List<JournalEntry>> _entries = widget.journal
      .watchEntries(widget.plantId);
  String? _beforeId;
  String? _afterId;
  var _position = 0.5;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.compareTitle)),
      body: StreamBuilder<List<JournalEntry>>(
        stream: _entries,
        builder: (context, snapshot) {
          final photos = photoEntriesOldestFirst(snapshot.data ?? const []);
          final fallback = defaultComparison(photos);
          if (fallback == null) return const SizedBox.shrink();
          JournalEntry pick(String? id, JournalEntry otherwise) =>
              photos.where((entry) => entry.id == id).firstOrNull ?? otherwise;
          final before = pick(_beforeId, fallback.before);
          final after = pick(_afterId, fallback.after);
          return _Comparison(
            photos: photos,
            before: before,
            after: after,
            position: _position,
            store: widget.photos,
            onPosition: (value) => setState(() => _position = value),
            onBefore: (entry) => setState(() => _beforeId = entry.id),
            onAfter: (entry) => setState(() => _afterId = entry.id),
          );
        },
      ),
    );
  }
}

class _Comparison extends StatelessWidget {
  const _Comparison({
    required this.photos,
    required this.before,
    required this.after,
    required this.position,
    required this.store,
    required this.onPosition,
    required this.onBefore,
    required this.onAfter,
  });

  final List<JournalEntry> photos;
  final JournalEntry before;
  final JournalEntry after;
  final double position;
  final PhotoStore store;
  final ValueChanged<double> onPosition;
  final ValueChanged<JournalEntry> onBefore;
  final ValueChanged<JournalEntry> onAfter;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final dates = DateFormat.yMMMd(Localizations.localeOf(context).toString());
    final days = after.day.difference(before.day).inDays.abs();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: AspectRatio(
            aspectRatio: 3 / 4,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _Photo(store: store, entry: after),
                ClipRect(
                  child: Align(
                    key: const ValueKey('before-clip'),
                    alignment: Alignment.centerLeft,
                    widthFactor: position,
                    child: _Photo(store: store, entry: before),
                  ),
                ),
              ],
            ),
          ),
        ),
        Slider(value: position, onChanged: onPosition),
        Text(
          l10n.beforeLabel(dates.format(before.day)),
          style: text.titleMedium,
        ),
        Text(l10n.afterLabel(dates.format(after.day)), style: text.titleMedium),
        const SizedBox(height: 4),
        Text(l10n.daysLater(days), style: text.bodyMedium),
        const SizedBox(height: 16),
        _PhotoChoice(
          title: l10n.chooseBefore,
          options: [for (final entry in photos) if (entry != after) entry],
          selected: before,
          onSelected: onBefore,
        ),
        const SizedBox(height: 12),
        _PhotoChoice(
          title: l10n.chooseAfter,
          options: [for (final entry in photos) if (entry != before) entry],
          selected: after,
          onSelected: onAfter,
        ),
      ],
    );
  }
}

class _Photo extends StatelessWidget {
  const _Photo({required this.store, required this.entry});

  final PhotoStore store;
  final JournalEntry entry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return switch (entry.photo) {
      final photo? => Image.file(
        store.fileFor(photo),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => ColoredBox(
          color: scheme.secondaryContainer,
          child: const Icon(Icons.image_outlined, size: 48),
        ),
      ),
      null => const SizedBox.shrink(),
    };
  }
}

class _PhotoChoice extends StatelessWidget {
  const _PhotoChoice({
    required this.title,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final String title;
  final List<JournalEntry> options;
  final JournalEntry selected;
  final ValueChanged<JournalEntry> onSelected;

  @override
  Widget build(BuildContext context) {
    final dates = DateFormat.yMMMd(Localizations.localeOf(context).toString());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final entry in options)
              ChoiceChip(
                label: Text(dates.format(entry.day)),
                selected: entry == selected,
                onSelected: (_) => onSelected(entry),
              ),
          ],
        ),
      ],
    );
  }
}
