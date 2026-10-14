import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../domain/missing_species.dart';
import '../l10n/app_localizations.dart';

/// Identified species without a care profile, so they can be added to the
/// plant database in a next update.
class MissingSpeciesScreen extends StatelessWidget {
  const MissingSpeciesScreen({super.key, required this.repository});

  final MissingSpeciesRepository repository;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final format = DateFormat.yMMMd(Localizations.localeOf(context).toString());
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.missingSpeciesTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: l10n.clearList,
            onPressed: repository.clear,
          ),
        ],
      ),
      body: StreamBuilder<List<MissingSpecies>>(
        stream: repository.watch(),
        builder: (context, snapshot) {
          final species = snapshot.data ?? const [];
          if (species.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.missingSpeciesEmpty,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: species.length,
            itemBuilder: (context, index) {
              final item = species[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.eco_outlined),
                  title: Text(item.commonName ?? item.scientificName),
                  subtitle: Text(
                    l10n.missingSpeciesDetail(
                      item.scientificName,
                      item.count,
                      format.format(item.lastSeen),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
