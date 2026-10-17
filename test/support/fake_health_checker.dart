import 'package:green_friend/domain/health.dart';

/// Returns a prepared assessment (or throws [error]) and records each call.
class FakeHealthChecker implements PlantHealthChecker {
  FakeHealthChecker({this.result, this.error});

  final HealthAssessment? result;

  /// Thrown by [check] if set, e.g. an `IdentificationFailure`.
  final Object? error;
  final checks = <({List<int> photo, String apiKey, String languageCode})>[];

  @override
  Future<HealthAssessment> check(
    List<int> photo, {
    required String apiKey,
    required String languageCode,
  }) async {
    checks.add((photo: photo, apiKey: apiKey, languageCode: languageCode));
    if (error case final error?) throw error;
    return result ?? HealthAssessment(isHealthy: true, issues: const []);
  }
}
