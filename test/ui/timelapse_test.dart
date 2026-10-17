import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/domain/journal.dart';
import 'package:green_friend/domain/timelapse.dart';
import 'package:green_friend/ui/timelapse_screen.dart';
import 'package:green_friend/ui/timeline_screen.dart';

import '../support/fake_backup.dart';
import '../support/fake_journal_repository.dart';
import '../support/fake_photos.dart';
import '../support/fake_timelapse_encoder.dart';
import '../support/pump_app.dart';

JournalEntry _photo(String id, DateTime day) =>
    JournalEntry(id: id, plantId: 'p', day: day, photo: '$id.jpg');

final photoEntries = [
  _photo('c', DateTime(2026, 9, 3)),
  _photo('a', DateTime(2026, 8, 1)),
  JournalEntry(id: 'n', plantId: 'p', day: DateTime(2026, 8, 5), note: 'Hi'),
  _photo('b', DateTime(2026, 8, 20)),
];

FakePhotoStore photoStore() {
  final store = FakePhotoStore();
  for (final name in ['a.jpg', 'b.jpg', 'c.jpg']) {
    store.stored.add(name);
    store.bytes[name] = [name.codeUnitAt(0)];
  }
  return store;
}

Future<void> pumpTimelapse(
  WidgetTester tester, {
  FakeFileSharing? sharing,
  FakeTimelapseEncoder? encoder,
  Locale locale = const Locale('en'),
}) {
  return tester.pumpApp(
    TimelapseScreen(
      entries: photoEntries,
      photos: photoStore(),
      fileSharing: sharing ?? FakeFileSharing(),
      encoder: encoder ?? FakeTimelapseEncoder(),
    ),
    locale: locale,
  );
}

Future<void> pumpTimeline(WidgetTester tester, List<JournalEntry> entries) {
  return tester.pumpApp(
    TimelineScreen(
      plantId: 'p',
      journal: FakeJournalRepository(entries),
      photos: photoStore(),
      fileSharing: FakeFileSharing(),
      timelapseEncoder: FakeTimelapseEncoder(),
    ),
  );
}

void main() {
  group('Time-lapse action', () {
    testWidgets('the action appears with three or more photos', (tester) async {
      await pumpTimeline(tester, photoEntries);

      await tester.tap(find.byTooltip('Time-lapse'));
      await tester.pumpAndSettle();

      expect(find.byType(TimelapseScreen), findsOneWidget);
      expect(find.text('Share as GIF'), findsOneWidget);
    });

    testWidgets('the action does not appear with fewer than three photos', (
      tester,
    ) async {
      await pumpTimeline(tester, photoEntries.skip(1).toList());

      expect(find.byTooltip('Time-lapse'), findsNothing);
    });
  });

  group('TimelapseScreen', () {
    testWidgets("the screen shows the first photo's date and moves on", (
      tester,
    ) async {
      await pumpTimelapse(tester);

      expect(find.text('Time-lapse'), findsOneWidget);
      expect(find.text('8/1/2026'), findsOneWidget);
      expect(find.text('1 of 3'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      expect(find.text('8/20/2026'), findsOneWidget);
      expect(find.text('2 of 3'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      expect(find.text('9/3/2026'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      expect(find.text('8/1/2026'), findsOneWidget);
    });

    testWidgets('"Share as GIF" encodes the photos and shares an image/gif '
        'file', (tester) async {
      final sharing = FakeFileSharing();
      final encoder = FakeTimelapseEncoder();
      await pumpTimelapse(tester, sharing: sharing, encoder: encoder);

      await tester.tap(find.text('Share as GIF'));
      await tester.pump();
      await tester.pump();
      await tester.pump();

      final frames = encoder.encoded.single;
      expect(frames.map((frame) => frame.label), [
        '8/1/2026',
        '8/20/2026',
        '9/3/2026',
      ]);
      expect(frames.map((frame) => frame.bytes), [
        ['a'.codeUnitAt(0)],
        ['b'.codeUnitAt(0)],
        ['c'.codeUnitAt(0)],
      ]);
      final shared = sharing.sharedBytes.single;
      expect(shared.bytes, FakeTimelapseEncoder.gif);
      expect(shared.mimeType, 'image/gif');
      expect(shared.fileName, endsWith('.gif'));
    });

    testWidgets('"Share as GIF" shows an error if encoding fails', (
      tester,
    ) async {
      final sharing = FakeFileSharing();
      await pumpTimelapse(
        tester,
        sharing: sharing,
        encoder: FakeTimelapseEncoder(error: const TimelapseException('x')),
      );

      await tester.tap(find.text('Share as GIF'));
      await tester.pump();
      await tester.pump();

      expect(find.text('The time-lapse could not be created.'), findsOneWidget);
      expect(sharing.sharedBytes, isEmpty);
    });

    testWidgets('shows the time-lapse in German', (tester) async {
      await pumpTimelapse(tester, locale: const Locale('de'));

      expect(find.text('Zeitraffer'), findsOneWidget);
      expect(find.text('1.8.2026'), findsOneWidget);
      expect(find.text('1 von 3'), findsOneWidget);
      expect(find.text('Als GIF teilen'), findsOneWidget);
    });
  });
}
