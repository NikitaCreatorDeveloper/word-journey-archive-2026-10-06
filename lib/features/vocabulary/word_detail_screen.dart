import 'package:flutter/material.dart';

import '../progress/trainer_data.dart';
import '../progress/practice_event.dart';
import '../settings/settings_screen.dart';
import 'vocabulary_concept.dart';

String localDate(DateTime? date) {
  if (date == null) return 'Ещё не назначено';
  final d = date.toLocal();
  return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year} · ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

class WordDetailScreen extends StatefulWidget {
  const WordDetailScreen({super.key, required this.concept});
  final VocabularyConcept concept;
  @override
  State<WordDetailScreen> createState() => _WordDetailScreenState();
}

class _WordDetailScreenState extends State<WordDetailScreen> {
  bool _logged = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_logged) {
      _logged = true;
      final data = TrainerScope.of(context);
      data
          .append([
            PracticeEvent(
              id: '${newSessionId()}:hint:${widget.concept.id}',
              sessionId: 'word-detail',
              conceptId: widget.concept.id,
              kind: PracticeKind.hint,
              at: data.now().toUtc(),
            ),
          ])
          .catchError((Object _) {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.concept,
        data = TrainerScope.of(context),
        p = data.progress[c.id];
    return Scaffold(
      appBar: AppBar(title: Text(c.english)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(c.russian, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Text(c.exampleEn, style: Theme.of(context).textTheme.titleMedium),
          Text(c.exampleRu),
          const SizedBox(height: 20),
          if (data.error != null) ...[
            Text(data.error!),
            TextButton(
              onPressed: () => data.append([]).catchError((Object _) {}),
              child: const Text('Повторить сохранение'),
            ),
          ],
          Text(
            '${c.cefrLevel?.shortLabel ?? 'CEFR не указан'} · ${c.partOfSpeech.name} · ${p?.mastery.label ?? 'Новое'}',
          ),
          Text(
            'Match: ${p?.matchCorrect ?? 0} верно, ${p?.wrongAttempts ?? 0} ошибок.\nВспоминание: ${p?.recallCorrect ?? 0} верно, ${p?.recallWrong ?? 0} ошибок.',
          ),
          Text(
            'Узнавание: ${localDate(p?.recognitionDueAt)}\nВспоминание: ${localDate(p?.recallDueAt)}',
          ),
          if (data.settings.values['pronunciation'] == true)
            OutlinedButton.icon(
              icon: const Icon(Icons.volume_up_outlined),
              label: const Text('Произнести'),
              onPressed: () async {
                try {
                  final result = await personalPlatform.invokeMethod<bool>(
                    'speak',
                    {'text': c.english, 'voice': data.settings.values['voice']},
                  );
                  if (result != true && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Офлайн-голос английского недоступен. Проверьте настройки.',
                        ),
                      ),
                    );
                  }
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Произношение сейчас недоступно.'),
                      ),
                    );
                  }
                }
              },
            ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Избранное'),
            value: data.flags[c.id]?['favorite'] == true,
            onChanged: (v) =>
                data.setFlag(c.id, favorite: v).catchError((Object _) {}),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Исключить из выдачи'),
            subtitle: const Text('История сохранится.'),
            value: data.flags[c.id]?['excluded'] == true,
            onChanged: (v) =>
                data.setFlag(c.id, excluded: v).catchError((Object _) {}),
          ),
          const Divider(),
          Text(
            'Материал: ${c.provenance['cefrEvidenceScope'] == 'lemma' ? 'Уровень леммы проверен; значение — редакторское.' : 'Уровень конкретного значения — редакторская оценка.'}',
          ),
          Text(c.provenance['source']?.toString() ?? ''),
          Text(c.provenance['url']?.toString() ?? ''),
          if (data.error != null) Text(data.error!),
        ],
      ),
    );
  }
}
