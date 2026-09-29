import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/ui/font_licenses.dart';
import 'package:green_friend/ui/theme.dart';

const headingFont = 'PlayfairDisplay';
const bodyFont = 'Inter';

double? weightOf(TextStyle? style) => style?.fontVariations
    ?.where((variation) => variation.axis == 'wght')
    .map((variation) => variation.value)
    .firstOrNull;

void main() {
  for (final (name, theme) in [('light', lightTheme), ('dark', darkTheme)]) {
    group('$name text theme', () {
      final text = theme.textTheme;
      final scheme = theme.colorScheme;

      test('uses Playfair Display for headings', () {
        for (final style in [
          text.displayLarge,
          text.displayMedium,
          text.displaySmall,
          text.headlineLarge,
          text.headlineMedium,
          text.headlineSmall,
          text.titleLarge,
        ]) {
          expect(style?.fontFamily, headingFont);
          expect(style?.color, scheme.primary);
        }
      });

      test('uses Inter for body text and labels', () {
        for (final style in [
          text.titleMedium,
          text.titleSmall,
          text.bodyLarge,
          text.bodyMedium,
          text.bodySmall,
          text.labelLarge,
          text.labelMedium,
          text.labelSmall,
        ]) {
          expect(style?.fontFamily, bodyFont);
          expect(style?.color, scheme.onSurface);
        }
      });

      test('follows the sizes and weights of the design spec', () {
        for (final style in [
          text.headlineLarge,
          text.headlineMedium,
          text.headlineSmall,
        ]) {
          expect(style?.fontSize, inInclusiveRange(24, 32));
          expect(weightOf(style), 600);
        }
        expect(text.titleLarge?.fontSize, inInclusiveRange(18, 22));
        expect(weightOf(text.titleLarge), 500);
        expect(text.titleMedium?.fontSize, 16);
        expect(weightOf(text.titleMedium), 600);
        expect(text.bodyMedium?.fontSize, 14);
        expect(weightOf(text.bodyMedium), 400);
        expect(text.bodySmall?.fontSize, 12);
        expect(text.labelMedium?.fontSize, 12);
      });
    });
  }

  testWidgets('registers the font licenses', (tester) async {
    registerFontLicenses();

    final packages = <String>{};
    await tester.runAsync(() async {
      await for (final entry in LicenseRegistry.licenses) {
        packages.addAll(entry.packages);
      }
    });

    expect(packages, containsAll(['Playfair Display', 'Inter']));
  });
}
