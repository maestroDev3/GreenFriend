import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/data/bundled_species.dart';
import 'package:green_friend/data/bundled_tips.dart';

void main() {
  group('bundled care tips', () {
    test('has at least 40 tips with unique ids', () {
      final ids = {for (final tip in bundledTips) tip.id};

      expect(bundledTips.length, greaterThanOrEqualTo(40));
      expect(ids, hasLength(bundledTips.length));
    });

    test('has an English and a German text for every tip', () {
      for (final tip in bundledTips) {
        expect(tip.texts['en'], isNotEmpty, reason: tip.id);
        expect(tip.texts['de'], isNotEmpty, reason: tip.id);
      }
    });

    test('has at least 15 tips for genera of the plant database', () {
      final genera = {
        for (final species in bundledSpecies)
          species.scientificName.split(' ').first,
      };
      final genusTips = bundledTips.where((tip) => tip.genus != null);

      expect(genusTips.length, greaterThanOrEqualTo(15));
      for (final tip in genusTips) {
        expect(genera, contains(tip.genus), reason: tip.id);
      }
    });

    test('is available through the catalog', () {
      expect(BundledTipCatalog().all, bundledTips);
    });
  });
}
