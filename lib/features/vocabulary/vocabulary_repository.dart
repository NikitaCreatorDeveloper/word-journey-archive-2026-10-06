import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

import '../profile/cefr_level.dart';
import 'vocabulary_concept.dart';

class VocabularyCategory {
  const VocabularyCategory(this.id, this.title, this.symbol);
  final String id, title, symbol;
}

class VocabularyPack {
  const VocabularyPack({
    required this.id,
    required this.title,
    required this.categoryId,
    required this.level,
    required this.conceptIds,
    this.goal = '',
  });
  final String id, title, categoryId, goal;
  final CefrLevel level;
  final List<String> conceptIds;
}

class VocabularyRepository {
  VocabularyRepository(
    this.concepts,
    this.packs,
    this.categories, {
    this.sizedLevels = const {},
  }) : byId = {for (final c in concepts) c.id: c} {
    for (final p in packs) {
      _searchIndex[p.id] =
          '${p.title} ${categories.where((c) => c.id == p.categoryId).firstOrNull?.title ?? ''} ${p.conceptIds.map((id) => '${byId[id]?.english ?? ''} ${byId[id]?.russian ?? ''}').join(' ')}'
              .toLowerCase();
      _groups.putIfAbsent('${p.categoryId}:${p.level.id}', () => []).add(p);
    }
  }
  final _searchIndex = <String, String>{};
  final _groups = <String, List<VocabularyPack>>{};
  List<VocabularyPack> search(String query, CefrLevel level) => packs
      .where(
        (p) =>
            p.level == level &&
            _searchIndex[p.id]!.contains(query.toLowerCase().trim()),
      )
      .toList();
  final List<VocabularyConcept> concepts;
  final List<VocabularyPack> packs;
  final List<VocabularyCategory> categories;
  final Set<CefrLevel> sizedLevels;
  final Map<String, VocabularyConcept> byId;
  static Future<VocabularyRepository>? _cached;
  static VocabularyRepository? current;
  static Future<VocabularyRepository> load() =>
      current != null ? SynchronousFuture(current!) : (_cached ??= _read());
  static Future<VocabularyRepository> _read() async {
    final parsed = await compute<String, VocabularyRepository>(
      _decodeCatalog,
      await rootBundle.loadString('assets/vocabulary/catalog-v1.json'),
    );
    current = parsed;
    return parsed;
  }

  factory VocabularyRepository.fromJson(Map<String, dynamic> j) {
    if (j['schemaVersion'] != 1) {
      throw const FormatException('Unsupported content version');
    }
    final r = VocabularyRepository(
      (j['concepts'] as List)
          .map(
            (c) =>
                VocabularyConcept.fromJson(Map<String, dynamic>.from(c as Map)),
          )
          .toList(),
      (j['packs'] as List)
          .map(
            (p) => VocabularyPack(
              id: p['id'] as String,
              title: p['title'] as String,
              categoryId: p['categoryId'] as String,
              level: CefrLevel.fromId(p['cefrLevel'] as String)!,
              conceptIds: List<String>.from(p['conceptIds'] as List),
              goal: p['goal'] as String? ?? '',
            ),
          )
          .toList(),
      (j['categories'] as List)
          .map(
            (c) => VocabularyCategory(
              c['id'] as String,
              c['title'] as String,
              c['symbol'] as String,
            ),
          )
          .toList(),
      sizedLevels: {
        for (final id in (j['sizedLevels'] as List? ?? []))
          CefrLevel.fromId(id as String)!,
      },
    );
    final errors = r.validate();
    if (errors.isNotEmpty) throw FormatException(errors.join('\n'));
    return r;
  }
  List<VocabularyPack> packsFor(String category, CefrLevel level) =>
      _groups['$category:${level.id}'] ?? const [];
  List<VocabularyConcept> words(VocabularyPack p) =>
      p.conceptIds.map((id) => byId[id]!).toList();
  List<String> validate() {
    final errors = <String>[];
    if (byId.length != concepts.length) errors.add('Duplicate concept ID');
    if (packs.map((p) => p.id).toSet().length != packs.length) {
      errors.add('Duplicate pack ID');
    }
    for (final c in concepts) {
      if (c.cefrLevel == null) errors.add('Unknown built-in CEFR ${c.id}');
      if (c.acceptedVariants.any((v) => v.trim().isEmpty)) {
        errors.add('Empty accepted variant ${c.id}');
      }
      if (![
            'meaning',
            'lemma',
            'phrase',
            'editorial',
          ].contains(c.provenance['cefrEvidenceScope']) ||
          DateTime.tryParse(c.provenance['date']?.toString() ?? '') == null ||
          !(Uri.tryParse(c.provenance['url']?.toString() ?? '')
                  ?.hasAbsolutePath ??
              false)) {
        errors.add('Invalid provenance ${c.id}');
      }
      if ([
        c.id,
        c.lemma,
        c.senseKey,
        c.english,
        c.russian,
        c.labelEn,
        c.labelRu,
        c.exampleEn,
        c.exampleRu,
      ].any((s) => s.trim().isEmpty)) {
        errors.add('Empty field ${c.id}');
      }
      if (c.labelEn.length > 48 || c.labelRu.length > 48) {
        errors.add('Long label ${c.id}');
      }
      if (c.acceptedVariants.isEmpty ||
          c.provenance['cefrEvidenceScope'] == null ||
          c.provenance['reviewStatus'] == null) {
        errors.add('Missing metadata ${c.id}');
      }
      if (c.tags.any((tag) => !categories.any((cat) => cat.id == tag))) {
        errors.add('Unknown category ${c.id}');
      }
    }
    for (final p in packs) {
      if (!categories.any((cat) => cat.id == p.categoryId) ||
          p.conceptIds.length < 4 ||
          p.conceptIds.toSet().length != p.conceptIds.length) {
        errors.add('Invalid pack ${p.id}');
      }
      if (sizedLevels.contains(p.level) &&
          (p.conceptIds.length < 20 || p.conceptIds.length > 30)) {
        errors.add('Published pack must contain 20–30 concepts ${p.id}');
      }
      if (p.conceptIds.any(
        (id) => byId[id] == null || byId[id]!.cefrLevel != p.level,
      )) {
        errors.add('Broken reference ${p.id}');
        continue;
      }
      for (final labels in [
        words(p).map((c) => c.labelEn.toLowerCase().trim()),
        words(p).map((c) => c.labelRu.toLowerCase().trim()),
      ]) {
        if (labels.toSet().length != labels.length) {
          errors.add('Ambiguous labels ${p.id}');
        }
      }
    }
    return errors;
  }
}

VocabularyRepository _decodeCatalog(String text) =>
    VocabularyRepository.fromJson(jsonDecode(text) as Map<String, dynamic>);
