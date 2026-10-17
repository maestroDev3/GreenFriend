import 'package:flutter/material.dart';

import '../domain/health.dart';
import '../domain/identification.dart';
import '../domain/photos.dart';
import '../l10n/app_localizations.dart';

/// Runs a health check on a stored photo and shows the likely problems with
/// advice.
class HealthCheckScreen extends StatefulWidget {
  const HealthCheckScreen({
    super.key,
    required this.photo,
    required this.photos,
    required this.checker,
    required this.apiKey,
    required this.languageCode,
  });

  /// Name of the photo in [photos].
  final String photo;
  final PhotoStore photos;
  final PlantHealthChecker checker;
  final String apiKey;
  final String languageCode;

  @override
  State<HealthCheckScreen> createState() => _HealthCheckScreenState();
}

class _HealthCheckScreenState extends State<HealthCheckScreen> {
  late final Future<HealthAssessment> _result = _check();

  Future<HealthAssessment> _check() async {
    final bytes = await widget.photos.readBytes(widget.photo);
    if (bytes == null) throw const ServiceUnavailable('photo not readable');
    return widget.checker.check(
      bytes,
      apiKey: widget.apiKey,
      languageCode: widget.languageCode,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.healthCheckTitle)),
      body: FutureBuilder<HealthAssessment>(
        future: _result,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return _Progress(text: l10n.healthChecking);
          }
          if (snapshot.data case final result?) {
            return _Result(
              result: result,
              photo: Image.file(
                widget.photos.fileFor(widget.photo),
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            );
          }
          return _Message(
            text: switch (snapshot.error) {
              InvalidApiKey() => l10n.identifyInvalidKey,
              NoCredits() => l10n.identifyNoCredits,
              _ => l10n.healthUnavailable,
            },
          );
        },
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        Text(text),
      ],
    ),
  );
}

class _Message extends StatelessWidget {
  const _Message({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    ),
  );
}

class _Result extends StatelessWidget {
  const _Result({required this.result, required this.photo});

  final HealthAssessment result;
  final Widget photo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ClipRRect(borderRadius: BorderRadius.circular(16), child: photo),
        const SizedBox(height: 16),
        Card(
          color: result.isHealthy
              ? scheme.primaryContainer
              : scheme.errorContainer,
          child: ListTile(
            leading: Icon(
              result.isHealthy
                  ? Icons.check_circle_outline
                  : Icons.healing_outlined,
              color: result.isHealthy
                  ? scheme.onPrimaryContainer
                  : scheme.onErrorContainer,
            ),
            title: Text(
              result.isHealthy ? l10n.healthLooksHealthy : l10n.healthProblems,
              style: theme.textTheme.titleMedium?.copyWith(
                color: result.isHealthy
                    ? scheme.onPrimaryContainer
                    : scheme.onErrorContainer,
              ),
            ),
          ),
        ),
        for (final issue in result.issues) ...[
          const SizedBox(height: 12),
          _IssueCard(issue: issue),
        ],
      ],
    );
  }
}

class _IssueCard extends StatelessWidget {
  const _IssueCard({required this.issue});

  final HealthIssue issue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(issue.name, style: text.titleMedium),
            const SizedBox(height: 4),
            Text(
              l10n.healthProbability((issue.probability * 100).round()),
              style: text.labelLarge,
            ),
            if (issue.description case final description?) ...[
              const SizedBox(height: 8),
              Text(description, style: text.bodyMedium),
            ],
            for (final (title, items) in [
              (l10n.healthPrevention, issue.prevention),
              (l10n.healthBiological, issue.biological),
              (l10n.healthChemical, issue.chemical),
            ])
              if (items.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(title, style: text.titleSmall),
                for (final item in items)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(item, style: text.bodyMedium),
                  ),
              ],
          ],
        ),
      ),
    );
  }
}
