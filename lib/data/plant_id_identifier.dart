import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../domain/identification.dart';

/// Identifies plants with the plant.id API (Kindwise) using the user's own
/// API key; no new package, only `dart:io`.
class PlantIdIdentifier implements PlantIdentifier {
  PlantIdIdentifier({this.timeout = const Duration(seconds: 30)});

  static final endpoint = Uri.parse(
    'https://plant.id/api/v3/identification',
  );

  /// Upper limit for connecting and for the whole answer.
  final Duration timeout;

  @override
  Future<List<IdentificationCandidate>> identify(
    List<int> photo, {
    required String apiKey,
    required String languageCode,
  }) async {
    final client = HttpClient()..connectionTimeout = timeout;
    try {
      final uri = endpoint.replace(
        queryParameters: {'details': 'common_names', 'language': languageCode},
      );
      final request = await client.postUrl(uri);
      request.headers.set('Api-Key', apiKey);
      request.headers.contentType = ContentType.json;
      request.add(utf8.encode(jsonEncode(plantIdRequestBody(photo))));
      final response = await request.close().timeout(timeout);
      final body = await response
          .transform(utf8.decoder)
          .join()
          .timeout(timeout);
      return parsePlantIdResponse(response.statusCode, body);
    } on SocketException catch (error) {
      throw ServiceUnavailable(error.message);
    } on HttpException catch (error) {
      throw ServiceUnavailable(error.message);
    } on TimeoutException {
      throw const ServiceUnavailable('timeout');
    } finally {
      client.close();
    }
  }
}

/// The JSON body of an identification request for [photo] (JPEG bytes).
Map<String, Object> plantIdRequestBody(List<int> photo) => {
  'images': ['data:image/jpeg;base64,${base64Encode(photo)}'],
  'similar_images': false,
};

/// Reads the answer of the identification endpoint.
///
/// Throws [InvalidApiKey] (401), [NoCredits] (429), [NotAPlant] when the
/// photo shows no plant, and [ServiceUnavailable] for anything else that is
/// not a readable success.
List<IdentificationCandidate> parsePlantIdResponse(
  int statusCode,
  String body,
) {
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
    final isPlant = result['is_plant'] as Map<String, Object?>?;
    if (isPlant?['binary'] == false) throw const NotAPlant();
    final classification = result['classification'] as Map<String, Object?>;
    final suggestions = classification['suggestions'] as List<Object?>;
    final candidates = [
      for (final suggestion in suggestions.cast<Map<String, Object?>>())
        _candidate(suggestion),
    ];
    if (candidates.isEmpty) throw const NotAPlant();
    return candidates;
  } on IdentificationFailure {
    rethrow;
  } on Object catch (error) {
    throw ServiceUnavailable('unreadable answer: $error');
  }
}

IdentificationCandidate _candidate(Map<String, Object?> suggestion) {
  final details = suggestion['details'] as Map<String, Object?>?;
  final names = details?['common_names'] as List<Object?>?;
  final probability = (suggestion['probability'] as num).toDouble();
  return IdentificationCandidate(
    scientificName: suggestion['name'] as String,
    commonNames: [...?names?.whereType<String>()],
    probability: probability.clamp(0, 1).toDouble(),
  );
}
