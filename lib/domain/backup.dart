import 'dart:convert';

import 'care_log.dart';
import 'care_log_repository.dart';
import 'journal.dart';
import 'journal_repository.dart';
import 'plant.dart';
import 'plant_repository.dart';

/// Everything the user entered: plants, care history and journal (the photo
/// files are packed next to it, see [photos]).
class Backup {
  const Backup({
    required this.plants,
    required this.careLogs,
    required this.journal,
  });

  static const format = 'green-friend-backup';
  static const version = 1;

  final List<Plant> plants;
  final List<CareLog> careLogs;
  final List<JournalEntry> journal;

  /// File names of the journal photos that belong to the backup.
  List<String> get photos => [for (final entry in journal) ?entry.photo];
}

/// Collects all data for a backup.
Future<Backup> createBackup({
  required PlantRepository plants,
  required CareLogRepository careLogs,
  required JournalRepository journal,
}) async {
  return Backup(
    plants: await plants.allPlants(),
    careLogs: await careLogs.allLogs(),
    journal: await journal.allEntries(),
  );
}

/// Replaces all data with the backup.
Future<void> restoreBackup(
  Backup backup, {
  required PlantRepository plants,
  required CareLogRepository careLogs,
  required JournalRepository journal,
}) async {
  await plants.replaceAll(backup.plants);
  await careLogs.replaceAll(backup.careLogs);
  await journal.replaceAll(backup.journal);
}

/// The backup as JSON (format version [Backup.version]).
String encodeBackup(Backup backup) {
  return const JsonEncoder.withIndent('  ').convert({
    'format': Backup.format,
    'version': Backup.version,
    'plants': [for (final plant in backup.plants) _plantToJson(plant)],
    'careLogs': [for (final log in backup.careLogs) _logToJson(log)],
    'journal': [for (final entry in backup.journal) _entryToJson(entry)],
  });
}

/// Reads a backup; throws [FormatException] if it is broken, of another app
/// or of an unknown format version.
Backup decodeBackup(String json) {
  try {
    final data = jsonDecode(json) as Map<String, dynamic>;
    if (data['format'] != Backup.format) {
      throw const FormatException('Not a Green Friend backup');
    }
    if (data['version'] != Backup.version) {
      throw FormatException('Unsupported backup version ${data['version']}');
    }
    List<dynamic> list(String key) => data[key] as List<dynamic>;
    return Backup(
      plants: [
        for (final item in list('plants'))
          _plantFromJson(item as Map<String, dynamic>),
      ],
      careLogs: [
        for (final item in list('careLogs'))
          _logFromJson(item as Map<String, dynamic>),
      ],
      journal: [
        for (final item in list('journal'))
          _entryFromJson(item as Map<String, dynamic>),
      ],
    );
  } on FormatException {
    rethrow;
  } on TypeError catch (error) {
    throw FormatException('Invalid backup: $error');
  } on ArgumentError catch (error) {
    throw FormatException('Invalid backup: ${error.message}');
  }
}

String? _day(DateTime? day) => day == null
    ? null
    : '${day.year.toString().padLeft(4, '0')}-'
          '${day.month.toString().padLeft(2, '0')}-'
          '${day.day.toString().padLeft(2, '0')}';

DateTime? _parseDay(Object? value) =>
    value == null ? null : DateTime.parse(value as String);

Map<String, Object?> _plantToJson(Plant plant) => {
  'id': plant.id,
  'name': plant.name,
  'species': plant.species,
  'location': plant.location,
  'wateringIntervalDays': plant.wateringIntervalDays,
  'lastWateredOn': _day(plant.lastWateredOn),
  'fertilizingIntervalDays': plant.fertilizingIntervalDays,
  'lastFertilizedOn': _day(plant.lastFertilizedOn),
  'repottingIntervalMonths': plant.repottingIntervalMonths,
  'lastRepottedOn': _day(plant.lastRepottedOn),
};

Plant _plantFromJson(Map<String, dynamic> json) => Plant(
  id: json['id'] as String,
  name: json['name'] as String,
  species: json['species'] as String?,
  location: json['location'] as String?,
  wateringIntervalDays: json['wateringIntervalDays'] as int?,
  lastWateredOn: _parseDay(json['lastWateredOn']),
  fertilizingIntervalDays: json['fertilizingIntervalDays'] as int?,
  lastFertilizedOn: _parseDay(json['lastFertilizedOn']),
  repottingIntervalMonths: json['repottingIntervalMonths'] as int?,
  lastRepottedOn: _parseDay(json['lastRepottedOn']),
);

Map<String, Object?> _logToJson(CareLog log) => {
  'id': log.id,
  'plantId': log.plantId,
  'kind': log.kind.name,
  'day': _day(log.day),
};

CareLog _logFromJson(Map<String, dynamic> json) {
  final kind = CareKind.byName(json['kind'] as String);
  if (kind == null) throw FormatException('Unknown care kind ${json['kind']}');
  return CareLog(
    id: json['id'] as String,
    plantId: json['plantId'] as String,
    kind: kind,
    day: DateTime.parse(json['day'] as String),
  );
}

Map<String, Object?> _entryToJson(JournalEntry entry) => {
  'id': entry.id,
  'plantId': entry.plantId,
  'day': _day(entry.day),
  'note': entry.note,
  'photo': entry.photo,
};

JournalEntry _entryFromJson(Map<String, dynamic> json) => JournalEntry(
  id: json['id'] as String,
  plantId: json['plantId'] as String,
  day: DateTime.parse(json['day'] as String),
  note: json['note'] as String?,
  photo: json['photo'] as String?,
);
