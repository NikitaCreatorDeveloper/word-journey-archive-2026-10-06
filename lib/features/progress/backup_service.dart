import 'dart:convert';

import '../settings/trainer_settings.dart';
import '../vocabulary/vocabulary_concept.dart';
import 'practice_event.dart';
import 'trainer_store.dart';

class BackupPreview {
  BackupPreview(this.snapshot, this.unknownConcepts);
  final TrainerSnapshot snapshot;
  final Set<String> unknownConcepts;
  int get events => snapshot.rows['events']!.length;
  int get words => snapshot.rows['custom']!.length;
  int get sessions => snapshot.rows['sessions']!.length;
}

class BackupService {
  static String encode(TrainerSnapshot s) => jsonEncode({
    'format': 'word-journey-personal',
    'version': 1,
    'settings': s.settings,
    ...s.rows,
  });
  static BackupPreview validate(String text, Set<String> builtInIds) {
    if (text.length > 8 * 1024 * 1024) {
      throw const FormatException('Backup too large');
    }
    try {
      final j = jsonDecode(text) as Map<String, dynamic>;
      if (j['format'] != 'word-journey-personal' || j['version'] != 1) {
        throw const FormatException('Unsupported backup');
      }
      final settings = Map<String, dynamic>.from(j['settings'] as Map);
      TrainerSettings(settings).validate();
      final rows = <String, List<Map<String, dynamic>>>{};
      for (final t in dataTables) {
        rows[t] = (j[t] as List)
            .map((r) => Map<String, dynamic>.from(r as Map))
            .toList();
        if (rows[t]!.length > 100000 ||
            rows[t]!.any(
              (r) => r['id'] is! String || (r['id'] as String).isEmpty,
            ) ||
            rows[t]!.map((r) => r['id']).toSet().length != rows[t]!.length) {
          throw const FormatException('Invalid or duplicate records');
        }
      }
      final custom = rows['custom']!.map(VocabularyConcept.fromJson).toList();
      for (final c in custom) {
        if (!c.id.startsWith('user.') ||
            builtInIds.contains(c.id) ||
            c.english.trim().isEmpty ||
            c.russian.trim().isEmpty ||
            c.acceptedVariants.isEmpty ||
            c.labelEn.length > 48 ||
            c.labelRu.length > 48) {
          throw const FormatException('Invalid custom word');
        }
      }
      final ids = {...builtInIds, ...custom.map((c) => c.id)};
      final unknown = <String>{};
      for (final row in rows['events']!) {
        final e = PracticeEvent.fromJson(row);
        if (!ids.contains(e.conceptId)) unknown.add(e.conceptId);
        if (e.otherConceptId != null && !ids.contains(e.otherConceptId)) {
          unknown.add(e.otherConceptId!);
        }
      }
      for (final r in rows['flags']!) {
        if (r['favorite'] is! bool || r['excluded'] is! bool) {
          throw const FormatException('Invalid flags');
        }
        if (r['firstConsolidatedAt'] != null) {
          DateTime.parse(r['firstConsolidatedAt'] as String);
        }
      }
      for (final r in rows['sessions']!) {
        if (r['mode'] != 'match' && r['mode'] != 'recall') {
          throw const FormatException('Invalid session mode');
        }
        DateTime.parse(r['at'] as String);
        if (r['completed'] is! bool ||
            (r['correct'] as int) < 0 ||
            (r['wrong'] as int) < 0 ||
            (r['elapsedMs'] as int) < 0) {
          throw const FormatException('Invalid session');
        }
      }
      for (final r in rows['awards']!) {
        DateTime.parse(r['at'] as String);
      }
      return BackupPreview(
        TrainerSnapshot(settings: settings, rows: rows),
        unknown,
      );
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('Malformed backup');
    }
  }
}
