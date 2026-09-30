import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../domain/journal.dart';
import '../domain/journal_repository.dart';
import '../domain/photos.dart';
import '../domain/timeline.dart';
import '../l10n/app_localizations.dart';

/// The journal of a plant as a timeline, oldest first, grouped by month.
class TimelineScreen extends StatefulWidget {
  const TimelineScreen({
    super.key,
    required this.plantId,
    required this.journal,
    required this.photos,
  });

  final String plantId;
  final JournalRepository journal;
  final PhotoStore photos;

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  late final Stream<List<JournalEntry>> _entries = widget.journal.watchEntries(
    widget.plantId,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.timelineTitle)),
      body: StreamBuilder<List<JournalEntry>>(
        stream: _entries,
        builder: (context, snapshot) {
          final months = journalTimeline(snapshot.data ?? const []);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              for (final month in months) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
                  child: Text(
                    DateFormat.yMMMM(locale)
                        .format(DateTime(month.year, month.month)),
                    style: text.titleLarge,
                  ),
                ),
                for (final item in month.items)
                  _TimelineTile(item: item, photos: widget.photos),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({required this.item, required this.photos});

  final TimelineItem item;
  final PhotoStore photos;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final entry = item.entry;
    final date = DateFormat.yMMMd(Localizations.localeOf(context).toString())
        .format(entry.day);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                const SizedBox(height: 18),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Container(width: 2, color: scheme.secondaryContainer),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ListTile(
                      title: Text(l10n.timelineDay(item.dayNumber)),
                      subtitle: Text(date),
                    ),
                    if (entry.photo case final photo?)
                      AspectRatio(
                        aspectRatio: 4 / 3,
                        child: Image.file(
                          photos.fileFor(photo),
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => ColoredBox(
                            color: scheme.secondaryContainer,
                            child: const Icon(Icons.image_outlined, size: 48),
                          ),
                        ),
                      ),
                    if (entry.note case final note?)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(note, style: theme.textTheme.bodyMedium),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
