import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/data/plant_id_health_checker.dart';
import 'package:green_friend/domain/health.dart';
import 'package:green_friend/domain/identification.dart';

Map<String, Object?> suggestion(
  String name,
  double probability, {
  String? localName,
  Map<String, Object?>? treatment,
  String? description,
}) => {
  'id': name,
  'name': name,
  'probability': probability,
  'details': {
    'local_name': localName,
    'description': description,
    'treatment': treatment,
  },
};

String answer({bool healthy = false, List<Object?> suggestions = const []}) =>
    jsonEncode({
      'access_token': 'abc',
      'result': {
        'is_plant': {'binary': true, 'probability': 0.99},
        'is_healthy': {'binary': healthy, 'probability': healthy ? 0.9 : 0.1},
        'disease': {'suggestions': suggestions},
      },
    });

void main() {
  group('healthRequest', () {
    test('the request body contains the photo as base64 JPEG', () {
      expect(healthRequestBody([1, 2, 3])['images'], [
        'data:image/jpeg;base64,${base64Encode([1, 2, 3])}',
      ]);
    });

    test('the request asks for local names, description and treatment', () {
      final uri = healthAssessmentUri('de');

      expect(uri.host, 'plant.id');
      expect(uri.path, '/api/v3/health_assessment');
      expect(
        uri.queryParameters['details'],
        'local_name,description,treatment',
      );
      expect(uri.queryParameters['language'], 'de');
    });
  });

  group('parseHealthResponse', () {
    test('the parser reads the problems, most probable first, at most '
        'three, with local name, description and advice', () {
      final result = parseHealthResponse(
        201,
        answer(
          suggestions: [
            suggestion('water excess or uneven watering', 0.2),
            suggestion(
              'Fungi',
              0.7,
              localName: 'Pilzbefall',
              description: 'Fungi grow on leaves.',
              treatment: {
                'prevention': ['Keep leaves dry.'],
                'biological': ['Neem oil.'],
                'chemical': ['Fungicide.'],
              },
            ),
            suggestion('nutrient deficiency', 0.1),
            suggestion('Pests', 0.05),
          ],
        ),
      );

      expect(result.isHealthy, isFalse);
      expect(result.issues.map((issue) => issue.name), [
        'Pilzbefall',
        'water excess or uneven watering',
        'nutrient deficiency',
      ]);
      final fungi = result.issues.first;
      expect(fungi.probability, 0.7);
      expect(fungi.description, 'Fungi grow on leaves.');
      expect(fungi.prevention, ['Keep leaves dry.']);
      expect(fungi.biological, ['Neem oil.']);
      expect(fungi.chemical, ['Fungicide.']);
      expect(result.issues[1].description, isNull);
      expect(result.issues[1].prevention, isEmpty);
    });

    test('the parser reads healthy plants', () {
      final result = parseHealthResponse(200, answer(healthy: true));

      expect(result.isHealthy, isTrue);
      expect(result.issues, isEmpty);
    });

    test('401 gives an invalid key, 429 no credits, other errors and '
        'unreadable answers the service as unavailable', () {
      expect(
        () => parseHealthResponse(401, '{}'),
        throwsA(isA<InvalidApiKey>()),
      );
      expect(() => parseHealthResponse(429, '{}'), throwsA(isA<NoCredits>()));
      expect(
        () => parseHealthResponse(500, '{}'),
        throwsA(isA<ServiceUnavailable>()),
      );
      expect(
        () => parseHealthResponse(200, 'oops'),
        throwsA(isA<ServiceUnavailable>()),
      );
    });
  });

  group('HealthIssue', () {
    test('rejects a blank name or a probability outside 0 to 1', () {
      expect(
        () => HealthIssue(name: ' ', probability: 0.5),
        throwsArgumentError,
      );
      expect(
        () => HealthIssue(name: 'Fungi', probability: 1.5),
        throwsArgumentError,
      );
    });
  });
}
