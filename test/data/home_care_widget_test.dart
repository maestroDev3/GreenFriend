import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/data/home_care_widget.dart';
import 'package:green_friend/domain/care_log.dart';
import 'package:green_friend/domain/care_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HomeCareWidget', () {
    late Map<String, Object?> saved;
    late List<Map<Object?, Object?>> updates;

    setUp(() {
      saved = {};
      updates = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('home_widget'), (
            call,
          ) async {
            final arguments = call.arguments as Map<Object?, Object?>;
            switch (call.method) {
              case 'saveWidgetData':
                saved[arguments['id'] as String] = arguments['data'];
              case 'updateWidget':
                updates.add(arguments);
            }
            return true;
          });
    });

    test(
      'saves the texts and up to five rows, then updates the widget',
      () async {
        await HomeCareWidget().show(
          CareWidgetContent(
            title: 'Care today',
            emptyText: 'All happy',
            staleText: 'Open the app',
            day: DateTime.utc(2026, 10, 17),
            lines: [
              for (var i = 0; i < 6; i++)
                CareWidgetLine(
                  plantId: 'p$i',
                  name: 'Plant $i',
                  tasks: 'Water',
                  kinds: const [Water()],
                ),
            ],
          ),
        );

        expect(saved[CareWidgetKeys.title], 'Care today');
        expect(saved[CareWidgetKeys.empty], 'All happy');
        expect(saved[CareWidgetKeys.stale], 'Open the app');
        expect(saved[CareWidgetKeys.day], '2026-10-17');
        expect(saved[CareWidgetKeys.count], 5);
        expect(saved[CareWidgetKeys.name(0)], 'Plant 0');
        expect(saved[CareWidgetKeys.tasks(4)], 'Water');
        expect(saved.containsKey(CareWidgetKeys.name(5)), isFalse);
        expect(
          updates.single['qualifiedAndroidName'],
          CareWidgetKeys.androidProvider,
        );
      },
    );
  });
}
