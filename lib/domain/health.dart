import 'identification.dart';

/// A problem the health assessment thinks the photo shows, e.g. a fungus, a
/// pest or a care error.
class HealthIssue {
  /// Throws [ArgumentError] if [name] is blank or [probability] is outside 0
  /// to 1.
  HealthIssue({
    required String name,
    required this.probability,
    String? description,
    List<String> prevention = const [],
    List<String> biological = const [],
    List<String> chemical = const [],
  }) : name = _required(name),
       description = _optional(description),
       prevention = List.unmodifiable(prevention),
       biological = List.unmodifiable(biological),
       chemical = List.unmodifiable(chemical) {
    if (probability < 0 || probability > 1) {
      throw ArgumentError.value(probability, 'probability', 'must be 0-1');
    }
  }

  /// Name in the requested language if the service knows one.
  final String name;

  /// How sure the service is, from 0 to 1.
  final double probability;
  final String? description;

  /// Advice how to avoid the problem.
  final List<String> prevention;

  /// Treatments without chemicals.
  final List<String> biological;

  /// Chemical treatments.
  final List<String> chemical;

  @override
  String toString() => 'HealthIssue($name, $probability)';

  static String _required(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(value, 'name', 'must not be empty');
    }
    return trimmed;
  }

  static String? _optional(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }
}

/// The result of a health check.
class HealthAssessment {
  HealthAssessment({required this.isHealthy, required List<HealthIssue> issues})
    : issues = List.unmodifiable(issues);

  final bool isHealthy;

  /// The most likely problems, most probable first.
  final List<HealthIssue> issues;
}

/// The [count] most probable issues, most probable first.
List<HealthIssue> topIssues(Iterable<HealthIssue> issues, {int count = 3}) {
  final sorted = [...issues]
    ..sort((a, b) => b.probability.compareTo(a.probability));
  return sorted.take(count).toList();
}

/// Checks a plant's health on a photo with an online service.
abstract interface class PlantHealthChecker {
  /// Returns the assessment of [photo] (JPEG bytes) with texts in
  /// [languageCode].
  ///
  /// Throws an [IdentificationFailure] (key, credits, network) on errors.
  Future<HealthAssessment> check(
    List<int> photo, {
    required String apiKey,
    required String languageCode,
  });
}
