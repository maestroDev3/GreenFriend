import 'package:flutter/widgets.dart';

/// The language used when none of the device languages is supported.
const fallbackLocale = Locale('en');

/// Picks the first device language the app supports, so a German device gets
/// German texts and every other unsupported language falls back to English.
Locale resolveLocale(List<Locale>? preferred, Iterable<Locale> supported) {
  for (final locale in preferred ?? const <Locale>[]) {
    for (final candidate in supported) {
      if (candidate.languageCode == locale.languageCode) {
        return candidate;
      }
    }
  }
  return fallbackLocale;
}
