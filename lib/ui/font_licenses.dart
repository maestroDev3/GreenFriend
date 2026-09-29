import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const _fontLicenses = [
  ('Playfair Display', 'assets/fonts/OFL-PlayfairDisplay.txt'),
  ('Inter', 'assets/fonts/OFL-Inter.txt'),
];

/// Adds the SIL Open Font License texts of the bundled fonts to the app's
/// license page, as the license requires.
void registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final (package, asset) in _fontLicenses) {
      final text = await rootBundle.loadString(asset);
      yield LicenseEntryWithLineBreaks([package], text);
    }
  });
}
