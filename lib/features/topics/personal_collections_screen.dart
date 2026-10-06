import 'package:flutter/material.dart';

import '../profile/cefr_level.dart';
import '../profile/cefr_profile.dart';
import '../progress/trainer_data.dart';
import '../vocabulary/vocabulary_concept.dart';
import '../vocabulary/vocabulary_repository.dart';
import '../training/screens/training_setup_screen.dart';
import '../review/recall_screen.dart';
import '../review/adaptive_word_scheduler.dart';

class PersonalCollectionsScreen extends StatefulWidget {
  const PersonalCollectionsScreen({super.key, this.filter = 'custom'});
  final String filter;
  @override
  State<PersonalCollectionsScreen> createState() =>
      _PersonalCollectionsScreenState();
}

class _PersonalCollectionsScreenState extends State<PersonalCollectionsScreen> {
  late String _filter = widget.filter;
  Future<void> _add() async {
    final data = TrainerScope.of(context);
    final en = TextEditingController(),
        ru = TextEditingController(),
        ex = TextEditingController(),
        exru = TextEditingController();
    CefrLevel? level;
    String? error;
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: const Text('Моё слово'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: en,
                  maxLength: 48,
                  decoration: const InputDecoration(
                    labelText: 'English · конкретное значение',
                  ),
                ),
                TextField(
                  controller: ru,
                  maxLength: 48,
                  decoration: const InputDecoration(
                    labelText: 'Русский перевод',
                  ),
                ),
                TextField(
                  controller: ex,
                  decoration: const InputDecoration(
                    labelText: 'Свой пример (необязательно)',
                  ),
                ),
                TextField(
                  controller: exru,
                  decoration: const InputDecoration(
                    labelText: 'Перевод примера',
                  ),
                ),
                DropdownButton<CefrLevel?>(
                  isExpanded: true,
                  value: level,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('CEFR не указан'),
                    ),
                    ...CefrLevel.values.map(
                      (l) =>
                          DropdownMenuItem(value: l, child: Text(l.shortLabel)),
                    ),
                  ],
                  onChanged: (v) => setDialog(() => level = v),
                ),
                if (error != null) Text(error!),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () async {
                if (en.text.trim().isEmpty ||
                    ru.text.trim().isEmpty ||
                    [
                      ...data.custom,
                      ...?VocabularyRepository.current?.concepts,
                    ].any(
                      (c) =>
                          c.english.toLowerCase() ==
                              en.text.trim().toLowerCase() &&
                          c.russian.toLowerCase() ==
                              ru.text.trim().toLowerCase(),
                    )) {
                  setDialog(
                    () => error = 'Введите обе формы. Такое значение могло быть уже добавлено.',
                  );
                  return;
                }
                final c = VocabularyConcept(
                  id: 'user.${newSessionId()}',
                  english: en.text.trim(),
                  russian: ru.text.trim(),
                  cefrLevel: level,
                  partOfSpeech: PartOfSpeech.phrase,
                  senseKey: 'user-authored',
                  lemma: en.text.trim(),
                  exampleEn: ex.text.trim(),
                  exampleRu: exru.text.trim(),
                  acceptedVariants: [en.text.trim()],
                  tags: const ['daily'],
                  provenance: {
                    'source': 'User authored',
                    'url': 'local://personal',
                    'date': data.now().toUtc().toIso8601String(),
                    'cefrEvidenceScope': 'editorial',
                    'reviewStatus': 'user',
                  },
                );
                try {
                  await data.addCustom(c);
                  if (context.mounted) Navigator.pop(context, true);
                } catch (_) {
                  setDialog(
                    () => error =
                        'Не удалось сохранить слово. Повторите попытку.',
                  );
                }
              },
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
    en.dispose();
    ru.dispose();
    ex.dispose();
    exru.dispose();
    if (saved == true && mounted) setState(() => _filter = 'custom');
  }

  @override
  Widget build(BuildContext context) {
    final data = TrainerScope.of(context);
    final r = VocabularyRepository.current;
    final all = [...?r?.concepts, ...data.custom];
    final words = switch (_filter) {
      'favorite' =>
        all.where((c) => data.flags[c.id]?['favorite'] == true).toList(),
      'core' =>
        all
            .where(
              (c) =>
                  c.curriculumPriority == 'core' &&
                  c.cefrLevel == ProfileScope.levelOf(context),
            )
            .toList(),
      'verb' =>
        all
            .where(
              (c) =>
                  c.partOfSpeech == PartOfSpeech.verb &&
                  c.cefrLevel == ProfileScope.levelOf(context),
            )
            .toList(),
      'adjective' =>
        all
            .where(
              (c) =>
                  c.partOfSpeech == PartOfSpeech.adjective &&
                  c.cefrLevel == ProfileScope.levelOf(context),
            )
            .toList(),
      'phrasalVerb' =>
        all
            .where(
              (c) =>
                  c.partOfSpeech == PartOfSpeech.phrasalVerb &&
                  c.cefrLevel == ProfileScope.levelOf(context),
            )
            .toList(),
      'phrase' =>
        all
            .where(
              (c) =>
                  c.partOfSpeech == PartOfSpeech.phrase &&
                  c.cefrLevel == ProfileScope.levelOf(context),
            )
            .toList(),
      _ => data.custom,
    };
    return Scaffold(
      appBar: AppBar(
        title: const Text('Коллекции'),
        actions: [
          IconButton(
            tooltip: 'Добавить своё слово',
            onPressed: _add,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Wrap(
            spacing: 8,
            children: [
              for (final entry in {
                'core': 'Самое нужное',
                'favorite': 'Избранное',
                'custom': 'Мои слова',
                'verb': 'Глаголы',
                'adjective': 'Прилагательные',
                'phrasalVerb': 'Фразовые глаголы',
                'phrase': 'Выражения',
              }.entries)
                ChoiceChip(
                  label: Text(entry.value),
                  selected: _filter == entry.key,
                  onSelected: (_) => setState(() => _filter = entry.key),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text('${words.length} понятий'),
          if (words.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Добавьте свои слова кнопкой + или отметьте слово звёздочкой в обзоре.',
              ),
            ),
          if (words.isNotEmpty)
            FilledButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) =>
                      AdaptiveWordScheduler().compatible(words).length <
                          data.settings.pairs
                      ? RecallScreen(words: words.take(20).toList())
                      : TrainingSetupScreen(
                          words: AdaptiveWordScheduler().compatible(words),
                          collectionTitle: 'Коллекция',
                        ),
                ),
              ),
              child: Text(
                AdaptiveWordScheduler().compatible(words).length <
                        data.settings.pairs
                    ? 'Вспомнить слова'
                    : 'Начать Match',
              ),
            ),
          for (final c in words)
            ListTile(
              title: Text(c.english),
              subtitle: Text(
                '${c.russian} · ${c.cefrLevel?.shortLabel ?? 'CEFR не указан'}',
              ),
              trailing: IconButton(
                tooltip: 'Избранное',
                icon: Icon(
                  data.flags[c.id]?['favorite'] == true
                      ? Icons.star
                      : Icons.star_border,
                ),
                onPressed: () async {
                  try {
                    await data.setFlag(
                      c.id,
                      favorite: data.flags[c.id]?['favorite'] != true,
                    );
                  } catch (_) {}
                },
              ),
            ),
        ],
      ),
    );
  }
}
