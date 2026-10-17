import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../domain/health.dart';
import '../domain/identification.dart';
import 'plant_id_identifier.dart';

/// Checks plant health with the plant.id health assessment (Kindwise) using
/// the user's own API key; each check uses credits of that account.
class PlantIdHealthChecker implements PlantHealthChecker {
  PlantIdHealthChecker({this.timeout = const Duration(seconds: 30)});

  /// Upper limit for connecting and for the whole answer.
  final Duration timeout;

  @override
  Future<HealthAssessment> check(
    List<int> photo, {
    required String apiKey,
    required String languageCode,
  }) async {
    final client = HttpClient()..connectionTimeout = timeout;
    try {
      final request = await client
          .postUrl(healthAssessmentUri(languageCode))
          .timeout(timeout);
      request.headers.set('Api-Key', apiKey);
      request.headers.contentType = ContentType.json;
      request.add(utf8.encode(jsonEncode(healthRequestBody(photo))));
      final response = await request.close().timeout(timeout);
      final body = await response
          .transform(utf8.decoder)
          .join()
          .timeout(timeout);
      return parseHealthResponse(response.statusCode, body);
    } on IdentificationFailure {
      rethrow;
    } catch (error) {
      if (identificationFailureFor(error) case final failure?) throw failure;
      rethrow;
    } finally {
      client.close();
    }
  }
}

/// The health assessment endpoint with names, descriptions and treatments in
/// [languageCode].
Uri healthAssessmentUri(String languageCode) => Uri.https(
  'plant.id',
  '/api/v3/health_assessment',
  {'details': 'local_name,description,treatment', 'language': languageCode},
);

/// The JSON body of a health assessment for [photo] (JPEG bytes).
Map<String, Object> healthRequestBody(List<int> photo) => {
  'images': ['data:image/jpeg;base64,${base64Encode(photo)}'],
  'similar_images': false,
};

/// Reads the answer of the health assessment: at most three problems, most
/// probable first.
///
/// Throws [InvalidApiKey] (401), [NoCredits] (429) and [ServiceUnavailable]
/// for anything else that is not a readable success.
HealthAssessment parseHealthResponse(int statusCode, String body) {
  switch (statusCode) {
    case 401:
      throw const InvalidApiKey();
    case 429:
      throw const NoCredits();
    case 200 || 201:
      break;
    default:
      throw ServiceUnavailable('status $statusCode');
  }
  try {
    final json = jsonDecode(body) as Map<String, Object?>;
    final result = json['result'] as Map<String, Object?>;
    final healthy = result['is_healthy'] as Map<String, Object?>;
    final disease = result['disease'] as Map<String, Object?>?;
    final suggestions = (disease?['suggestions'] as List<Object?>?) ?? [];
    return HealthAssessment(
      isHealthy: healthy['binary'] as bool,
      issues: topIssues([
        for (final suggestion in suggestions.cast<Map<String, Object?>>())
          _issue(suggestion),
      ]),
    );
  } on Object catch (error) {
    throw ServiceUnavailable('unreadable answer: $error');
  }
}

HealthIssue _issue(Map<String, Object?> suggestion) {
  final details = suggestion['details'] as Map<String, Object?>?;
  final treatment = details?['treatment'] as Map<String, Object?>?;
  List<String> texts(String key) => [
    ...?(treatment?[key] as List<Object?>?)?.whereType<String>(),
  ];
  final localName = details?['local_name'] as String?;
  return HealthIssue(
    name: (localName == null || localName.trim().isEmpty)
        ? suggestion['name'] as String
        : localName,
    probability: (suggestion['probability'] as num).toDouble().clamp(0, 1),
    description: details?['description'] as String?,
    prevention: texts('prevention'),
    biological: texts('biological'),
    chemical: texts('chemical'),
  );
}
