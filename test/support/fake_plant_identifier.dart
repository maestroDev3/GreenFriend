import 'package:green_friend/domain/identification.dart';

/// Returns prepared candidates (or throws a prepared failure) instead of
/// calling the identification service.
class FakePlantIdentifier implements PlantIdentifier {
  FakePlantIdentifier({this.candidates = const [], this.failure});

  final List<IdentificationCandidate> candidates;
  final IdentificationFailure? failure;
  final calls = <({List<int> photo, String apiKey, String languageCode})>[];

  @override
  Future<List<IdentificationCandidate>> identify(
    List<int> photo, {
    required String apiKey,
    required String languageCode,
  }) async {
    calls.add((photo: photo, apiKey: apiKey, languageCode: languageCode));
    if (failure case final failure?) throw failure;
    return candidates;
  }
}
