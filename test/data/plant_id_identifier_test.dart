import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/data/plant_id_identifier.dart';
import 'package:green_friend/domain/identification.dart';

String answer({bool isPlant = true, List<Object?> suggestions = const []}) =>
    jsonEncode({
      'access_token': 'abc',
      'result': {
        'is_plant': {'binary': isPlant, 'probability': isPlant ? 0.98 : 0.02},
        'classification': {'suggestions': suggestions},
      },
    });

void main() {
  group('plantIdRequestBody', () {
    test('contains the photo as a base64 JPEG data URL', () {
      final body = plantIdRequestBody([1, 2, 3]);

      expect(body['images'], ['data:image/jpeg;base64,${base64Encode([1, 2, 3])}']);
      expect(body['similar_images'], isFalse);
    });
  });

  group('parsePlantIdResponse', () {
    test('turns a created answer into candidates', () {
      final candidates = parsePlantIdResponse(
        201,
        answer(
          suggestions: [
            {
              'id': '1',
              'name': 'Monstera deliciosa',
              'probability': 0.91,
              'details': {
                'common_names': ['Fensterblatt', 'Monstera'],
              },
            },
            {
              'id': '2',
              'name': 'Philodendron bipinnatifidum',
              'probability': 0.05,
              'details': {'common_names': null},
            },
          ],
        ),
      );

      expect(candidates, [
        IdentificationCandidate(
          scientificName: 'Monstera deliciosa',
          commonNames: const ['Fensterblatt', 'Monstera'],
          probability: 0.91,
        ),
        IdentificationCandidate(
          scientificName: 'Philodendron bipinnatifidum',
          commonNames: const [],
          probability: 0.05,
        ),
      ]);
    });

    test('reports "not a plant" when the photo shows no plant', () {
      expect(
        () => parsePlantIdResponse(201, answer(isPlant: false)),
        throwsA(isA<NotAPlant>()),
      );
    });

    test('reports "not a plant" when there are no suggestions', () {
      expect(
        () => parsePlantIdResponse(201, answer()),
        throwsA(isA<NotAPlant>()),
      );
    });

    test('maps status 401 to an invalid key', () {
      expect(
        () => parsePlantIdResponse(401, '{"error": "Invalid api key"}'),
        throwsA(isA<InvalidApiKey>()),
      );
    });

    test('maps status 429 to no credits', () {
      expect(
        () => parsePlantIdResponse(429, 'Insufficient credits'),
        throwsA(isA<NoCredits>()),
      );
    });

    test('maps other errors and unreadable answers to a service error', () {
      expect(
        () => parsePlantIdResponse(500, 'oops'),
        throwsA(isA<ServiceUnavailable>()),
      );
      expect(
        () => parsePlantIdResponse(201, 'not json'),
        throwsA(isA<ServiceUnavailable>()),
      );
    });
  });
}
