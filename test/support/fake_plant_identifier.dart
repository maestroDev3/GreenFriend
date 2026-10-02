import 'package:green_friend/domain/identification.dart';

/// Returns prepared candidates (or throws a prepared failure) instead of
/// calling the identification service.
class FakePlantIdentifier implements PlantIdentifier {
  FakePlantIdentifier({this.candidates = const [], this.failure, this.error});

  final List<IdentificationCandidate> candidates;
  final IdentificationFailure? failure;

  /// Any other error, e.g. one the identifier did not expect.
  final Object? error;
  final calls = <({List<int> photo, String apiKey, String languageCode})>[];

  @override
  Future<List<IdentificationCandidate>> identify(
    List<int> photo, {
    required String apiKey,
    required String languageCode,
  }) async {
    calls.add((photo: photo, apiKey: apiKey, languageCode: languageCode));
    if (failure case final failure?) throw failure;
    if (error case final error?) throw error;
    return candidates;
  }
}
