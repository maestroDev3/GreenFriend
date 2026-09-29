import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/l10n/app_localizations.dart';
import 'package:green_friend/ui/theme.dart';

import 'pump_app.dart';

void main() {
  group('pumpApp', () {
    testWidgets('renders the widget with theme, localization and locale en', (
      tester,
    ) async {
      late BuildContext captured;
      await tester.pumpApp(
        Builder(
          builder: (context) {
            captured = context;
            return Text(AppLocalizations.of(context).appTitle);
          },
        ),
      );

      expect(find.text('Green Friend'), findsOneWidget);
      expect(
        Theme.of(captured).colorScheme.primary,
        lightTheme.colorScheme.primary,
      );
      expect(Localizations.localeOf(captured), const Locale('en'));
    });

    testWidgets('uses a phone-sized surface', (tester) async {
      await tester.pumpApp(const SizedBox());

      final view = tester.view;
      expect(view.physicalSize / view.devicePixelRatio, phoneSize);
    });

    testWidgets('restores the default surface after the previous test', (
      tester,
    ) async {
      final view = tester.view;
      expect(view.physicalSize / view.devicePixelRatio, isNot(phoneSize));
    });
  });
}
