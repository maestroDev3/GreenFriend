import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/ui/app.dart';
import 'package:green_friend/ui/theme.dart';

import '../support/contrast.dart';

void main() {
  group('lightTheme', () {
    final scheme = lightTheme.colorScheme;

    test('uses Material 3 with a light brightness', () {
      expect(lightTheme.useMaterial3, isTrue);
      expect(scheme.brightness, Brightness.light);
    });

    test('uses the agreed palette', () {
      expect(scheme.primary, const Color(0xFF173B2A));
      expect(scheme.secondary, const Color(0xFF244A36));
      expect(scheme.secondaryContainer, const Color(0xFFA8B59A));
      expect(scheme.tertiary, const Color(0xFFB8785C));
      expect(scheme.surface, const Color(0xFFF5F0E4));
      expect(scheme.onSurface, const Color(0xFF2B2B2B));
      expect(lightTheme.scaffoldBackgroundColor, const Color(0xFFF5F0E4));
      expect(lightTheme.cardTheme.color, const Color(0xFFE8DECC));
    });
  });

  group('darkTheme', () {
    final scheme = darkTheme.colorScheme;

    test('uses Material 3 with a dark brightness', () {
      expect(darkTheme.useMaterial3, isTrue);
      expect(scheme.brightness, Brightness.dark);
    });

    test('uses the agreed dark palette', () {
      expect(scheme.primary, const Color(0xFFA8B59A));
      expect(scheme.onPrimary, const Color(0xFF13201A));
      expect(scheme.secondary, const Color(0xFFC9D2BC));
      expect(scheme.tertiary, const Color(0xFFD9A080));
      expect(scheme.surface, const Color(0xFF13201A));
      expect(scheme.onSurface, const Color(0xFFF5F0E4));
      expect(darkTheme.scaffoldBackgroundColor, const Color(0xFF13201A));
      expect(darkTheme.cardTheme.color, const Color(0xFF1E2E25));
    });
  });

  for (final (name, theme) in [('light', lightTheme), ('dark', darkTheme)]) {
    group('$name theme', () {
      final scheme = theme.colorScheme;

      test('meets WCAG AA contrast for text', () {
        expect(contrastRatio(scheme.onPrimary, scheme.primary),
            greaterThanOrEqualTo(4.5));
        expect(contrastRatio(scheme.onSurface, scheme.surface),
            greaterThanOrEqualTo(4.5));
        expect(contrastRatio(scheme.primary, scheme.surface),
            greaterThanOrEqualTo(4.5));
        expect(contrastRatio(scheme.onSurface, theme.cardTheme.color!),
            greaterThanOrEqualTo(4.5));
      });

      test('uses rounded shapes', () {
        const states = <WidgetState>{};
        expect(
          theme.cardTheme.shape,
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        );
        expect(
          theme.filledButtonTheme.style?.shape?.resolve(states),
          isA<StadiumBorder>(),
        );
        expect(
          theme.outlinedButtonTheme.style?.shape?.resolve(states),
          isA<StadiumBorder>(),
        );
        expect(theme.chipTheme.shape, isA<StadiumBorder>());
        expect(
          theme.bottomSheetTheme.shape,
          const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
        );
        expect(theme.bottomSheetTheme.showDragHandle, isTrue);
      });
    });
  }

  testWidgets('GreenFriendApp uses the light and dark theme', (tester) async {
    await tester.pumpWidget(const GreenFriendApp());

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.theme, same(lightTheme));
    expect(app.darkTheme, same(darkTheme));
  });

  test('no hex color values outside lib/ui/theme.dart', () {
    final offenders = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where((file) => !file.path.endsWith('ui/theme.dart'))
        .where((file) => !file.path.contains('l10n/app_localizations'))
        .where((file) => file.readAsStringSync().contains('Color(0x'))
        .map((file) => file.path);

    expect(offenders, isEmpty);
  });

  test('the design spec is documented in docs/design.md', () {
    final spec = File('docs/design.md');

    expect(spec.existsSync(), isTrue);
    expect(spec.readAsStringSync(), contains('#173B2A'));
  });
}
