import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:word_journey/features/progress/backup_service.dart';
import 'package:word_journey/features/progress/trainer_store.dart';
import 'package:word_journey/features/vocabulary/vocabulary_repository.dart';

void main() {
  test('POCO pre-upgrade SQLite copy exports, imports twice and reopens without loss', () async {
    sqfliteFfiInit();
    final dir = await Directory.systemTemp.createTemp('airy-backup-check-');
    final file = await File('docs/airy-device/personal-trainer.db')
        .copy('${dir.path}/copy.db');
    var store = await SqliteTrainerStore.open(
      factory: databaseFactoryFfi,
      path: file.path,
    );
    try {
      final before = await store.read();
      final exported = BackupService.encode(before);
      final r = await VocabularyRepository.load();
      final preview = BackupService.validate(exported, r.byId.keys.toSet());
      expect(preview.unknownConcepts, isEmpty);
      expect(
        jsonDecode(exported),
        jsonDecode(
          await File('docs/airy-device/u0-official-format-backup.json')
              .readAsString(),
        ),
      );
      await store.importSnapshot(preview.snapshot);
      await store.importSnapshot(preview.snapshot);
      await store.close();
      store = await SqliteTrainerStore.open(
        factory: databaseFactoryFfi,
        path: file.path,
      );
      final after = await store.read();
      expect(after.settings, before.settings);
      expect(after.rows, before.rows);
    } finally {
      await store.close();
      await dir.delete(recursive: true);
    }
  });
}
