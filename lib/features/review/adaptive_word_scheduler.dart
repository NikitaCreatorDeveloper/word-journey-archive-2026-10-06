import '../progress/practice_event.dart';
import '../settings/trainer_settings.dart';
import '../vocabulary/vocabulary_concept.dart';

String labelKey(String label) =>
    label.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

class AdaptiveWordScheduler {
  List<VocabularyConcept> order(
    List<VocabularyConcept> candidates,
    Map<String, WordProgress> progress,
    DateTime now, {
    bool recall = false,
  }) {
    final words = candidates
        .where((c) => progress[c.id]?.excluded != true)
        .toList();
    int tier(VocabularyConcept c) {
      final p = progress[c.id];
      if (p?.isDue(now, recall: recall) == true) return 0;
      if (p?.needsReview == true) return 1;
      if (p?.firstConsolidatedAt == null && (p?.exposures ?? 0) > 0) return 2;
      return 3;
    }

    DateTime age(VocabularyConcept c) {
      final p = progress[c.id];
      return (recall ? p?.recallDueAt : p?.recognitionDueAt) ??
          p?.lastSeenAt ??
          DateTime.utc(1970);
    }

    words.sort((a, b) {
      var n = tier(a).compareTo(tier(b));
      if (n == 0) n = age(a).compareTo(age(b));
      if (n == 0) n = a.id.compareTo(b.id);
      return n;
    });
    return words;
  }

  List<VocabularyConcept> compatible(
    Iterable<VocabularyConcept> words, {
    int limit = 20,
  }) {
    final en = <String>{}, ru = <String>{}, ids = <String>{};
    final result = <VocabularyConcept>[];
    for (final c in words) {
      if (ids.contains(c.id) ||
          en.contains(labelKey(c.labelEn)) ||
          ru.contains(labelKey(c.labelRu))) {
        continue;
      }
      ids.add(c.id);
      en.add(labelKey(c.labelEn));
      ru.add(labelKey(c.labelRu));
      result.add(c);
      if (result.length == limit) break;
    }
    return result;
  }

  Map<String, int> priorities(
    List<VocabularyConcept> words,
    Map<String, WordProgress> progress,
  ) => {
    for (final c in words) c.id: (progress[c.id]?.needsReview == true ? 3 : 0),
  };
}

class CurriculumSelector {
  List<VocabularyConcept> select(
    List<VocabularyConcept> source,
    Map<String, WordProgress> progress,
    TrainerSettings settings,
    DateTime now,
  ) {
    final scheduler = AdaptiveWordScheduler();
    final candidates = source
        .where((c) => progress[c.id]?.excluded != true)
        .toList();
    final known = candidates
        .where(
          (c) =>
              (progress[c.id]?.matchCorrect ?? 0) +
                  (progress[c.id]?.recallCorrect ?? 0) >
              0,
        )
        .toList();
    final unseen = candidates
        .where((c) => !known.any((k) => k.id == c.id))
        .toList();
    final positions = {
      for (var i = 0; i < candidates.length; i++) candidates[i].id: i,
    };
    unseen.sort((a, b) {
      final pa = progress[a.id], pb = progress[b.id];
      var n = (pa?.exposures ?? 0).compareTo(pb?.exposures ?? 0);
      if (n == 0) {
        n = (pa?.lastSeenAt ?? DateTime.utc(1970)).compareTo(
          pb?.lastSeenAt ?? DateTime.utc(1970),
        );
      }
      return n == 0 ? positions[a.id]!.compareTo(positions[b.id]!) : n;
    });
    if (known.isEmpty) return scheduler.compatible(unseen, limit: 12);
    final budget = switch (settings.values['newWords']) {
      'little' => 2,
      'more' => 8,
      _ => 4,
    };
    final newCount = unseen.length < budget ? unseen.length : budget;
    final selected = scheduler.compatible([
      ...scheduler.order(known, progress, now).take(20 - newCount),
      ...unseen.take(budget),
    ]);
    // A queue too small for the selected board is offered as recall. We never
    // silently exceed the new-word budget to create a Match board.
    return selected;
  }
}
