import 'package:flutter_test/flutter_test.dart';

import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:word_journey/features/vocabulary/vocabulary_repository.dart';
import 'package:word_journey/features/profile/cefr_level.dart';

void main() {
  test('Expansion preserves all 1000 concepts and 85 pack IDs and their existing senses', () async {
    final r = await VocabularyRepository.load();
    expect(r.concepts.length, greaterThanOrEqualTo(1000));
    final baseline = jsonDecode(
      await File('tool/content/airy/baseline-catalog-v1.json').readAsString(),
    ) as Map<String, dynamic>;
    for (final c in baseline['concepts'] as List) {
      final current = r.byId[c['id']]!;
      expect(current.english, c['english']);
      expect(current.russian, c['russian']);
      expect(current.cefrLevel?.id, c['cefrLevel']);
      expect(current.acceptedVariants, c['acceptedVariants']);
    }
    expect(
      r.packs.map((p) => p.id),
      containsAll((baseline['packs'] as List).map((p) => p['id'])),
    );
    for (final p in baseline['packs'] as List) {
      expect(
        r.packs.firstWhere((now) => now.id == p['id']).conceptIds,
        containsAll(p['conceptIds'] as List),
      );
    }
    for (final level in CefrLevel.values) {
      expect(
        r.concepts.where((c) => c.cefrLevel == level).length,
        greaterThanOrEqualTo(200),
      );
      expect(
        r.packs.where((p) => p.level == level).length,
        greaterThanOrEqualTo(17),
      );
      if (r.sizedLevels.contains(level)) {
        for (final p in r.packs.where((p) => p.level == level)) {
          expect(p.conceptIds.length, inInclusiveRange(20, 30));
        }
      }
    }
  });
  for (final fault in [
    'duplicate',
    'reference',
    'translation',
    'level',
    'ambiguous',
    'provenance',
    'size',
  ]) {
    test('Reject malformed catalog: $fault', () async {
      final j = jsonDecode(
        await rootBundle.loadString('assets/vocabulary/catalog-v1.json'),
      ) as Map<String, dynamic>;
      final cs = j['concepts'] as List;
      final ps = j['packs'] as List;
      switch (fault) {
        case 'duplicate':
          cs.add(cs.first);
        case 'reference':
          ps.first['conceptIds'][0] = 'missing';
        case 'translation':
          cs.first['russian'] = '';
        case 'level':
          cs.first['cefrLevel'] = 'd1';
        case 'ambiguous':
          cs[1]['matchLabelEn'] = cs[0]['matchLabelEn'];
        case 'provenance':
          cs.first['provenance']['date'] = 'not a date';
        case 'size':
          ps.first['conceptIds'] = (ps.first['conceptIds'] as List)
              .take(19)
              .toList();
      }
      expect(() => VocabularyRepository.fromJson(j), throwsFormatException);
    });
  }
  test('Versioned catalog has valid IDs, labels, references and distinct level pools', () async {
    final r = await VocabularyRepository.load();
    expect(r.validate(), isEmpty);
    expect(r.concepts.where((c) => c.id.startsWith('cafe.')), hasLength(100));
    for (final l in CefrLevel.values) {
      final pack = r.packs.firstWhere((p) => p.level == l);
      expect(r.words(pack).every((c) => c.cefrLevel == l), isTrue);
    }
    final still = r.concepts.where((c) => c.english == 'still').toList();
    expect(still.map((c) => c.id).toSet(), hasLength(2));
  });
  test(
    'Search finds real bilingual content only within its actual level',
    () async {
      final r = await VocabularyRepository.load();
      final results = r.search('arguably', CefrLevel.c1);
      expect(results, isNotEmpty);
      expect(
        results.every((p) => r.words(p).any((c) => c.english == 'arguably')),
        true,
      );
      expect(r.search('arguably', CefrLevel.a1), isEmpty);
      final drinks = r.packs.firstWhere((p) => p.id == 'airy.a1.drinks');
      expect(r.search('апельсиновый сок', CefrLevel.a1), contains(drinks));
    },
  );
  test(
    'Coverage report agrees with published sizes, unique IDs and memberships',
    () async {
      final r = await VocabularyRepository.load();
      final coverage = jsonDecode(
        await File('docs/catalog-coverage.json').readAsString(),
      );
      expect(coverage['concepts'], r.byId.length);
      expect(coverage['packs'], r.packs.length);
      expect(
        coverage['memberships'],
        r.packs.fold<int>(0, (n, p) => n + p.conceptIds.length),
      );
      expect(r.sizedLevels, CefrLevel.values.toSet());
      for (final p in r.packs) {
        expect(p.goal, isNotEmpty);
        expect(p.conceptIds.length, inInclusiveRange(20, 30));
      }
    },
  );
}
