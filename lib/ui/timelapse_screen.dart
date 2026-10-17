import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../domain/backup_files.dart';
import '../domain/journal.dart';
import '../domain/photos.dart';
import '../domain/timelapse.dart';
import '../l10n/app_localizations.dart';

/// Plays a plant's journal photos one after the other, with their date, and
/// shares them as an animated GIF.
class TimelapseScreen extends StatefulWidget {
  const TimelapseScreen({
    super.key,
    required this.entries,
    required this.photos,
    this.fileSharing,
    this.encoder,
    this.frameDuration = const Duration(seconds: 1),
  });

  /// Journal entries; only those with a photo are shown, oldest first.
  final List<JournalEntry> entries;
  final PhotoStore photos;

  /// With [encoder], enables "Share as GIF".
  final FileSharing? fileSharing;
  final TimelapseEncoder? encoder;
  final Duration frameDuration;

  @override
  State<TimelapseScreen> createState() => _TimelapseScreenState();
}

class _TimelapseScreenState extends State<TimelapseScreen> {
  late final List<JournalEntry> _entries = timelapseEntries(widget.entries);
  late final Timer _timer;
  var _index = 0;
  var _sharing = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(widget.frameDuration, (_) {
      if (_entries.isEmpty) return;
      setState(() => _index = (_index + 1) % _entries.length);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _date(DateTime day) =>
      DateFormat.yMd(Localizations.localeOf(context).toString()).format(day);

  Future<void> _share(FileSharing sharing, TimelapseEncoder encoder) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _sharing = true);
    try {
      final frames = <TimelapseFrame>[];
      for (final entry in _entries) {
        final bytes = await widget.photos.readBytes(entry.photo!);
        if (bytes == null) continue;
        frames.add(TimelapseFrame(bytes: bytes, label: _date(entry.day)));
      }
      if (frames.isEmpty) throw const TimelapseException('No photo found.');
      final gif = await encoder.encode(frames);
      await sharing.shareBytes(
        gif,
        fileName: 'green-friend-timelapse.gif',
        mimeType: 'image/gif',
      );
    } on TimelapseException {
      messenger.showSnackBar(SnackBar(content: Text(l10n.timelapseFailed)));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final sharing = widget.fileSharing;
    final encoder = widget.encoder;
    final entry = _entries.isEmpty ? null : _entries[_index];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.timelapseTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: entry == null
                    ? const SizedBox.shrink()
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          widget.photos.fileFor(entry.photo!),
                          key: ValueKey(entry.id),
                          fit: BoxFit.contain,
                          gaplessPlayback: true,
                          errorBuilder: (_, _, _) => ColoredBox(
                            color: scheme.secondaryContainer,
                            child: const Icon(Icons.image_outlined, size: 48),
                          ),
                        ),
                      ),
              ),
              if (entry != null) ...[
                const SizedBox(height: 16),
                Text(
                  _date(entry.day),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.timelapsePosition(_index + 1, _entries.length),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
              if ((sharing, encoder) case (final sharing?, final encoder?)) ...[
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _sharing ? null : () => _share(sharing, encoder),
                  icon: _sharing
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.gif_box_outlined),
                  label: Text(
                    _sharing ? l10n.timelapseCreating : l10n.timelapseShare,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
