import 'package:flutter/material.dart';

import '../progress/trainer_data.dart';
import '../progress/practice_event.dart';
import '../training/logic/session_clock.dart';
import '../vocabulary/vocabulary_concept.dart';

String normalizeRecall(String value) => value
    .toLowerCase()
    .replaceAll('’', "'")
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim()
    .replaceAll(RegExp(r'[.!?,;:]+$'), '')
    .trim();
bool acceptedRecall(VocabularyConcept c, String input) =>
    c.acceptedVariants.any((v) => normalizeRecall(v) == normalizeRecall(input));

class RecallScreen extends StatefulWidget {
  const RecallScreen({super.key, required this.words});
  final List<VocabularyConcept> words;
  @override
  State<RecallScreen> createState() => _RecallScreenState();
}

class _RecallScreenState extends State<RecallScreen>
    with WidgetsBindingObserver {
  final _input = TextEditingController();
  final _clock = SessionClock();
  final _id = newSessionId();
  final _pending = <String, PracticeEvent>{};
  TrainerData? _data;
  int _index = 0, _correct = 0, _wrong = 0;
  bool _shown = false, _saving = false, _paused = false, _ended = false;
  bool _lastCorrect = false;
  late DateTime _started;
  Map<String, dynamic>? _terminal;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _clock.resume();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_data == null) {
      _data = TrainerScope.of(context);
      _started = _data!.now().toUtc();
      _expose();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _paused = state != AppLifecycleState.resumed;
    if (_paused) {
      _clock.pause();
      FocusManager.instance.primaryFocus?.unfocus();
    } else {
      _clock.resume();
    }
    if (mounted) setState(() {});
  }

  Future<bool> _send(List<PracticeEvent> es) async {
    for (final e in es) {
      _pending[e.id] = e;
    }
    final copy = _pending.values.toList();
    try {
      await _data!.append(copy);
      for (final e in copy) {
        _pending.remove(e.id);
      }
      return true;
    } catch (_) {
      return false;
    } finally {
      if (mounted) setState(() {});
    }
  }

  void _expose() {
    final c = widget.words[_index];
    _send([
      PracticeEvent(
        id: '$_id:expose:$_index',
        sessionId: _id,
        conceptId: c.id,
        kind: PracticeKind.exposure,
        at: _data!.now().toUtc(),
        index: _index,
      ),
    ]);
  }

  Future<void> _answer({bool unknown = false}) async {
    if (_shown || _saving || _paused || _ended) return;
    final c = widget.words[_index];
    final at = _data!.now().toUtc();
    final correct = !unknown && acceptedRecall(c, _input.text);
    final independent = _data!.progress[c.id]?.hintedToday(at) != true;
    setState(() {
      _shown = true;
      _saving = true;
      _lastCorrect = correct;
      if (correct) {
        _correct++;
      } else {
        _wrong++;
      }
    });
    FocusManager.instance.primaryFocus?.unfocus();
    await _send([
      PracticeEvent(
        id: '$_id:answer:$_index',
        sessionId: _id,
        conceptId: c.id,
        kind: correct ? PracticeKind.recallCorrect : PracticeKind.recallWrong,
        at: at,
        index: _index,
        independent: independent,
      ),
      PracticeEvent(
        id: '$_id:hint:$_index',
        sessionId: _id,
        conceptId: c.id,
        kind: PracticeKind.hint,
        at: _data!.now().toUtc(),
        index: _index,
      ),
    ]);
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _saveSession(bool completed) async {
    _clock.pause();
    _terminal ??= {
      'id': _id,
      'mode': 'recall',
      'packId': null,
      'at': _started.toIso8601String(),
      'completed': completed,
      'correct': _correct,
      'wrong': _wrong,
      'elapsedMs': _clock.elapsed.inMilliseconds,
      'unique': _correct + _wrong,
      'newConcepts': 0,
      'bestCombo': 0,
    };
    try {
      await _data!.saveSession(_terminal!);
      await _data!.reconcileAchievements();
    } catch (_) {}
  }

  Future<void> _next() async {
    if (_saving || _pending.isNotEmpty) return;
    if (_index + 1 == widget.words.length) {
      _ended = true;
      await _saveSession(true);
      if (mounted) setState(() {});
      return;
    }
    setState(() {
      _index++;
      _shown = false;
      _input.clear();
    });
    _expose();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (!_ended && _data != null) _saveSession(false);
    _clock.pause();
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.words[_index];
    final theme = Theme.of(context);
    TrainerScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Вспомнить без вариантов')),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_ended) ...[
                Text(
                  'Проверка завершена',
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 20),
                Text('Правильно: $_correct · Не вспомнил: $_wrong'),
                const Text(
                  'Самостоятельное вспоминание учитывается отдельно от Match.',
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Готово'),
                ),
              ] else if (_paused)
                const Text('Пауза')
              else ...[
                Text(
                  '${_index + 1} / ${widget.words.length}',
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: 24),
                Text(c.labelRu, style: theme.textTheme.headlineMedium),
                const SizedBox(height: 12),
                if (c.exampleRu.isNotEmpty)
                  Text(c.exampleRu, style: theme.textTheme.bodyLarge),
                const SizedBox(height: 24),
                if (!_shown) ...[
                  TextField(
                    key: const ValueKey('recall-input'),
                    controller: _input,
                    autocorrect: false,
                    enableSuggestions: false,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _answer(),
                    decoration: const InputDecoration(
                      labelText: 'Английское слово или выражение',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _saving ? null : () => _answer(),
                    child: const Text('Проверить'),
                  ),
                  TextButton(
                    onPressed: _saving ? null : () => _answer(unknown: true),
                    child: const Text('Не знаю · показать ответ'),
                  ),
                ] else ...[
                  Text(
                    _lastCorrect ? 'Верно' : 'Правильный ответ',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(c.english, style: theme.textTheme.headlineSmall),
                  Text(c.exampleEn),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _saving || _pending.isNotEmpty ? null : _next,
                    child: Text(
                      _index + 1 == widget.words.length
                          ? 'Завершить'
                          : 'Дальше',
                    ),
                  ),
                ],
              ],
              if (_pending.isNotEmpty && !_saving)
                TextButton(
                  onPressed: () => _send([]),
                  child: const Text('Повторить сохранение'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
