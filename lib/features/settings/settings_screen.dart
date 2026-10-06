import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/airy_components.dart';
import '../training/widgets/pair_count_selector.dart';

import '../progress/backup_service.dart';
import '../progress/trainer_data.dart';
import '../profile/cefr_profile.dart';
import '../profile/level_selector_screen.dart';
import '../vocabulary/vocabulary_repository.dart';
import '../topics/personal_collections_screen.dart';
import 'audio_feedback_service.dart';

const personalPlatform = MethodChannel('com.wordjourney.app/personal');

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double? _volume;
  bool _busy = false;
  late final Future<List<Map<String, dynamic>>> _voices = _loadVoices();
  Future<List<Map<String, dynamic>>> _loadVoices() async {
    try {
      final rows = await personalPlatform.invokeListMethod<dynamic>('voices');
      return rows?.map((v) => Map<String, dynamic>.from(v as Map)).toList() ??
          [];
    } catch (_) {
      return [];
    }
  }

  Future<void> _act(Future<void> Function() f) async {
    try {
      await f();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось выполнить действие: $e')),
        );
      }
    }
  }

  Widget _choice(
    String title,
    String key,
    Map<Object, String> options, {
    String? help,
  }) {
    final data = TrainerScope.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          if (help != null) Text(help),
          DropdownButton<Object>(
            isExpanded: true,
            itemHeight: null,
            value: data.settings.values[key] as Object,
            items: options.entries
                .map(
                  (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                )
                .toList(),
            onChanged: (v) =>
                _act(() => data.saveSettings(data.settings.withValue(key, v))),
          ),
        ],
      ),
    );
  }

  Widget _toggle(String title, String key) => SwitchListTile.adaptive(
    contentPadding: EdgeInsets.zero,
    title: Text(title),
    value: TrainerScope.of(context).settings.values[key] as bool,
    onChanged: (v) => _act(() async {
      if (key == 'sounds' && !v) AudioFeedbackService.shared.stop();
      final data = TrainerScope.of(context);
      await data.saveSettings(data.settings.withValue(key, v));
    }),
  );
  Widget _group(String title, List<Widget> children) => Card(
    margin: const EdgeInsets.only(bottom: 24),
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    ),
  );
  Future<void> _export() async {
    setState(() => _busy = true);
    try {
      final data = TrainerScope.of(context);
      await data.flush();
      final text = BackupService.encode(await data.store!.read());
      final saved = await personalPlatform.invokeMethod<bool>('exportBackup', {
        'text': text,
      });
      if (mounted && saved == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Резервная копия сохранена.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    setState(() => _busy = true);
    try {
      final data = TrainerScope.of(context);
      final profile = ProfileScope.of(context);
      final text = await personalPlatform.invokeMethod<String>('importBackup');
      if (text == null) return;
      final r = await VocabularyRepository.load();
      final preview = BackupService.validate(text, r.byId.keys.toSet());
      if (!mounted) return;
      final apply = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Импорт резервной копии'),
          content: Text(
            '${preview.events} событий · ${preview.sessions} сессий · ${preview.words} своих слов.\nНастройки будут восстановлены. Существующая история объединится по ID.\n${preview.unknownConcepts.length} неизвестных ID сохранятся отдельно.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Применить'),
            ),
          ],
        ),
      );
      if (apply == true) {
        await data.importData(preview.snapshot);
        await profile.load();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = TrainerScope.of(context);
    final s = data.settings;
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.all(pageInset(context)),
          children: [
            _group('Обучение', [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Уровень содержания'),
                subtitle: Text(ProfileScope.levelOf(context).shortLabel),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const LevelSelectorScreen(settings: true),
                  ),
                ),
              ),
              _choice('Ежедневная цель', 'dailyMinutes', {
                0: 'Без цели',
                5: '5 минут',
                10: '10 минут',
                15: '15 минут',
              }),
              _choice(
                'Новые слова',
                'newWords',
                {
                  'little': 'Мало — до 2 новых',
                  'normal': 'Обычно — до 4 новых',
                  'more': 'Больше — до 8 новых',
                },
                help: 'Если есть знакомые слова, дополняем ими набор. На первом занятии знакомимся с небольшим набором.',
              ),
              _choice('Повторение', 'reviewMode', {
                'match': 'Match',
                'recall': 'Вспомнить без вариантов',
              }),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Избранное и мои слова'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const PersonalCollectionsScreen(),
                  ),
                ),
              ),
            ]),
            _group('Игра', [
              PairCountSelector(
                value: data.settings.pairs,
                onChanged: (v) => _act(
                  () => data.saveSettings(data.settings.withValue('pairs', v)),
                ),
              ),
              _choice('Таймер', 'timer', {
                0: 'Выключен',
                60: '60 секунд',
                90: '90 секунд',
                120: '120 секунд',
              }),
              const Text(
                'Один раунд — 60 совпадений. Контрольные точки: 20 / 30 / 60. Изменения — со следующей сессии.',
              ),
              _toggle('Испытание: до 5 ошибок', 'mistakeChallenge'),
            ]),
            _group('Звук и движение', [
              _toggle('Звуки игры', 'sounds'),
              const Text('Громкость эффектов'),
              Slider(
                value: _volume ?? s.volume,
                onChanged: (v) => setState(() => _volume = v),
                onChangeEnd: (v) => _act(() async {
                  await data.saveSettings(s.withValue('volume', v));
                  if (mounted) setState(() => _volume = null);
                }),
              ),
              _toggle('Лёгкая вибрация', 'haptics'),
              _choice('Движение', 'motion', {
                'full': 'Полное',
                'calm': 'Спокойное',
                'minimal': 'Минимальное',
              }),
              _toggle('Произношение по нажатию', 'pronunciation'),
              const Text(
                'Используется только доступный офлайн-голос английского. Список голосов проверяется на устройстве.',
              ),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _voices,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Text('Проверяем офлайн-голоса…');
                  }
                  final voices = snapshot.data!;
                  if (voices.isEmpty) {
                    return const Text(
                      'Офлайн-голос английского не установлен. Можно добавить его в системных настройках речи.',
                    );
                  }
                  final selected = s.values['voice'];
                  return DropdownButton<String>(
                    isExpanded: true,
                    itemHeight: null,
                    value: voices.any((v) => v['id'] == selected)
                        ? selected as String?
                        : null,
                    hint: const Text('Первый доступный офлайн-голос'),
                    items: voices
                        .map(
                          (v) => DropdownMenuItem<String>(
                            value: v['id'] as String,
                            child: Text(v['label'] as String, maxLines: 2),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => _act(
                      () => data.saveSettings(
                        data.settings.withValue('voice', v),
                      ),
                    ),
                  );
                },
              ),
            ]),
            _group('Внешний вид', [
              _choice('Тема', 'theme', {
                'system': 'Как в системе',
                'light': 'Светлая',
                'dark': 'Тёмная',
              }),
              _toggle('Увеличенный текст', 'largeText'),
            ]),
            _group('Данные', [
              OutlinedButton(
                onPressed: _busy ? null : () => _act(_export),
                child: const Text('Экспорт резервной копии'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _busy ? null : () => _act(_import),
                child: const Text('Импорт с предварительной проверкой'),
              ),
              TextButton(
                onPressed: () => _act(() async {
                  final yes = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Сбросить учебный прогресс?'),
                      content: const Text(
                        'Удалятся события, история сессий, ранги и награды. Свои слова, избранное и настройки сохранятся. Сначала можно экспортировать копию.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Отмена'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Сбросить прогресс'),
                        ),
                      ],
                    ),
                  );
                  if (yes == true) await data.resetProgress();
                }),
                child: const Text('Сброс прогресса…'),
              ),
              TextButton(
                onPressed: () => showAboutDialog(
                  context: context,
                  applicationName: 'Word Journey',
                  applicationVersion: '1.0.0+1',
                  children: [
                    Text(
                      'Личный офлайн-тренажёр. ${VocabularyRepository.current?.concepts.length ?? 0} понятий, ${VocabularyRepository.current?.packs.length ?? 0} наборов. Авторские переводы и примеры; CEFR конкретных значений — редакторская оценка. Oxford 3000/5000 и British Council использованы как ориентиры отбора. Не сертификация. Все данные хранятся на устройстве.',
                    ),
                  ],
                ),
                child: const Text('О приложении и источниках'),
              ),
            ]),
            if (data.error != null) Text(data.error!),
          ],
        ),
      ),
    );
  }
}
