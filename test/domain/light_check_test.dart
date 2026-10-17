import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/domain/light_check.dart';
import 'package:green_friend/domain/species.dart';

void main() {
  group('lightVerdict', () {
    test('the verdict follows the lux ranges of each light need, borders '
        'included', () {
      final cases = {
        Light.low: (min: 250, max: 15000),
        Light.medium: (min: 1000, max: 20000),
        Light.brightIndirect: (min: 2500, max: 25000),
      };
      for (final MapEntry(key: need, value: range) in cases.entries) {
        expect(lightVerdict(range.min - 1, need), LightVerdict.tooDark);
        expect(lightVerdict(range.min.toDouble(), need), LightVerdict.fine);
        expect(lightVerdict(range.max.toDouble(), need), LightVerdict.fine);
        expect(lightVerdict(range.max + 1, need), LightVerdict.tooBright);
      }
      expect(lightVerdict(9999, Light.direct), LightVerdict.tooDark);
      expect(lightVerdict(10000, Light.direct), LightVerdict.fine);
      expect(lightVerdict(120000, Light.direct), LightVerdict.fine);
    });
  });

  group('averageLux', () {
    test('the average ignores negative readings; no readings give null', () {
      expect(averageLux([100, 200, -1]), 150);
      expect(averageLux([]), isNull);
      expect(averageLux([-5]), isNull);
    });
  });
}
