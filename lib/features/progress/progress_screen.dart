import 'package:flutter/material.dart';

import '../../app/airy_components.dart';
import '../../app/reward_presentation.dart';
import '../../app/premium_components.dart';
import '../../app/design_tokens.dart';
import '../vocabulary/vocabulary_repository.dart';
import '../vocabulary/word_detail_screen.dart';

import 'achievement_service.dart';
import 'mastery_policy.dart';
import 'practice_event.dart';
import 'trainer_data.dart';
import 'session_history_screen.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final d = TrainerScope.of(context), now = TrainerScope.of(context).now();
    final count = d.consolidatedCount, rank = rankIndex(d.consolidatedCount);
    final local = now.toLocal();
    final monday = DateTime(
      local.year,
      local.month,
      local.day,
    ).subtract(Duration(days: local.weekday - 1));
    final answers = d.events
        .where(
          (e) =>
              e.kind != PracticeKind.exposure &&
              e.kind != PracticeKind.hint &&
              !e.at.toLocal().isBefore(monday),
        )
        .toList();
    final days = answers.map((e) => practiceDay(e.at)).toSet();
    final ms = d.sessions
        .where(
          (s) => !DateTime.parse(s['at'] as String).toLocal().isBefore(monday),
        )
        .fold<int>(0, (n, s) => n + (s['elapsedMs'] as int? ?? 0));
    final completedIds = d.sessions.map((s) => s['id']).toSet();
    final interrupted = d.events
        .where(
          (e) =>
              e.kind != PracticeKind.hint &&
              !completedIds.contains(e.sessionId),
        )
        .map((e) => e.sessionId)
        .toSet();
    final week = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    return AiryBackground(
      child: ListView(
        key: const PageStorageKey('progress-scroll'),
        padding: EdgeInsets.fromLTRB(
          pageInset(context),
          16,
          pageInset(context),
          32,
        ),
        children: [
          EntryReveal(
            child: PremiumHero(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LayoutBuilder(
                    builder: (context, c) {
                      final info = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Текущий ранг',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            rankNames[rank],
                            key: const ValueKey('current-rank'),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (rank + 1 < rankNames.length) ...[
                            Text(
                              'До следующего ранга: ${rankThresholds[rank + 1] - count}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 6),
                            LinearProgressIndicator(
                              value:
                                  (count - rankThresholds[rank]) /
                                  (rankThresholds[rank + 1] -
                                      rankThresholds[rank]),
                              minHeight: 6,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '$count / ${rankThresholds[rank + 1]}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ] else
                            Text(
                              '$count подтверждено · высший ранг',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      );
                      if (MediaQuery.textScalerOf(context).scale(16) > 23 &&
                          c.maxWidth < 360) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RankBadge(rank: rank, size: 110),
                            const SizedBox(height: 12),
                            info,
                          ],
                        );
                      }
                      return Row(
                        children: [
                          RankBadge(
                            rank: rank,
                            size: c.maxWidth < 320 ? 92 : 104,
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: info),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Ранг хранит первое подтверждение. Забытые слова возвращаются в повторение.',
                    style: TextStyle(fontSize: 13, height: 1.35),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              children: [
                Text(
                  'Ваши слова',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: () => _openWords(context, 'Все слова', 'all'),
                  child: const Text('Все слова ›'),
                ),
              ],
            ),
          ),
          _MetricGrid(
            metrics: [
              (
                'Встречено',
                d.progress.values.where((p) => p.exposures > 0).length,
                Icons.menu_book_outlined,
                'seen',
              ),
              (
                'Тренирую',
                d.progress.values
                    .where((p) => p.mastery.label == 'Тренирую')
                    .length,
                Icons.bar_chart_rounded,
                'training',
              ),
              (
                'Узнаю',
                d.progress.values
                    .where((p) => p.mastery.label == 'Узнаю')
                    .length,
                Icons.psychology_outlined,
                'recognizing',
              ),
              (
                'Сейчас подтверждено',
                d.progress.values
                    .where((p) => p.mastery.currentlyConsolidated)
                    .length,
                Icons.check_rounded,
                'confirmed',
              ),
              (
                'Пора повторить',
                d.progress.values
                    .where((p) => p.isDue(now) || p.isDue(now, recall: true))
                    .length,
                Icons.replay_rounded,
                'due',
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              children: [
                Text(
                  'Эта неделя',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    AiryPageRoute<void>(
                      builder: (_) => const SessionHistoryScreen(),
                    ),
                  ),
                  child: const Text('История ›'),
                ),
              ],
            ),
          ),
          SurfaceCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    for (var i = 0; i < 7; i++)
                      Expanded(
                        child: Semantics(
                          label: week[i],
                          value:
                              days.contains(
                                practiceDay(monday.add(Duration(days: i))),
                              )
                              ? 'Была практика'
                              : 'Без практики',
                          child: Column(
                            children: [
                              Text(
                                week[i],
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 10),
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient:
                                      days.contains(
                                        practiceDay(
                                          monday.add(Duration(days: i)),
                                        ),
                                      )
                                      ? AppSurfaces.accent(context)
                                      : null,
                                  border: Border.all(
                                    color: AppSurfaces.outline(context),
                                  ),
                                ),
                                child:
                                    days.contains(
                                      practiceDay(
                                        monday.add(Duration(days: i)),
                                      ),
                                    )
                                    ? Icon(
                                        Icons.check_rounded,
                                        size: 20,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimary,
                                      )
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                Divider(
                  height: 1,
                  color: AppSurfaces.outline(context).withValues(alpha: .5),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    _WeekStat(
                      Icons.chat_bubble_outline_rounded,
                      "${answers.length} ${russianPlural(answers.length, 'ответ', 'ответа', 'ответов')}",
                    ),
                    _WeekStat(
                      Icons.local_fire_department_outlined,
                      "${days.length} ${russianPlural(days.length, 'активный день', 'активных дня', 'активных дней')}",
                    ),
                    _WeekStat(
                      Icons.schedule_rounded,
                      '${(ms / 60000).toStringAsFixed(1)} мин',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SectionHeader('Достижения'),
          for (final entry in achievementDefinitions.entries)
            ListTile(
              leading: AchievementBadge(
                index: achievementDefinitions.keys.toList().indexOf(entry.key),
                earned: d.awards.any((a) => a['id'] == entry.key),
              ),
              title: Text(entry.value.$1),
              subtitle: Text(entry.value.$2),
              trailing: d.awards.any((a) => a['id'] == entry.key)
                  ? const Icon(Icons.check)
                  : null,
            ),
          const SectionHeader('История'),
          if (d.sessions.isEmpty && interrupted.isEmpty)
            const Text('Первая тренировка появится здесь.'),
          if (d.sessions.length > 10)
            TextButton(
              onPressed: () => Navigator.push(
                context,
                AiryPageRoute<void>(
                  builder: (_) => const SessionHistoryScreen(),
                ),
              ),
              child: Text('Вся история · ${d.sessions.length} занятий'),
            ),
          for (final s in d.sessions.reversed.take(10))
            ListTile(
              title: Text(
                '${s['mode'] == 'match' ? 'Match' : 'Вспоминание'} · ${s['completed'] == true ? 'завершено' : 'остановлено'}',
              ),
              subtitle: Text(
                '${practiceDay(DateTime.parse(s['at'] as String))} · ${s['correct']} верно · ${s['wrong']} ошибок · ${((s['elapsedMs'] as int? ?? 0) / 1000).round()} с',
              ),
            ),
          for (final id in interrupted)
            ListTile(
              title: const Text('Прерванная практика'),
              subtitle: Text(
                '${d.sessionEvents(id).where((e) => e.kind != PracticeKind.exposure && e.kind != PracticeKind.hint).length} ответов сохранено; завершение не зарегистрировано',
              ),
            ),
        ],
      ),
    );
  }

  void _openWords(BuildContext context, String title, String filter) =>
      Navigator.push(
        context,
        AiryPageRoute<void>(
          builder: (_) => MetricWordsScreen(title: title, filter: filter),
        ),
      );
}

class AchievementBadge extends StatelessWidget {
  const AchievementBadge({
    super.key,
    required this.index,
    required this.earned,
  });
  final int index;
  final bool earned;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 42,
    height: 42,
    child: CustomPaint(
      painter: _BadgePainter(
        index,
        earned
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.outline,
      ),
    ),
  );
}

class _BadgePainter extends CustomPainter {
  _BadgePainter(this.index, this.color);
  final int index;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(2, 2, 38, 38),
        Radius.circular(index.isEven ? 12 : 19),
      ),
      p,
    );
    final path = Path();
    switch (index) {
      case 0:
        path.moveTo(14, 11);
        path.lineTo(14, 31);
        path.moveTo(14, 11);
        path.lineTo(29, 16);
        path.lineTo(14, 21);
      case 1:
        canvas.drawCircle(const Offset(21, 21), 8, p);
        path.moveTo(21, 6);
        path.lineTo(21, 10);
        path.moveTo(21, 32);
        path.lineTo(21, 36);
        path.moveTo(6, 21);
        path.lineTo(10, 21);
        path.moveTo(32, 21);
        path.lineTo(36, 21);
      case 2:
        path.moveTo(24, 8);
        path.lineTo(12, 23);
        path.lineTo(21, 23);
        path.lineTo(18, 34);
        path.lineTo(30, 18);
        path.lineTo(21, 18);
        path.close();
      case 3:
        path.moveTo(10, 22);
        path.lineTo(18, 30);
        path.lineTo(32, 12);
        canvas.drawCircle(const Offset(21, 21), 14, p);
      case 4:
        canvas.drawCircle(const Offset(21, 21), 12, p);
        path.moveTo(21, 12);
        path.lineTo(21, 22);
        path.lineTo(28, 25);
      case 5:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(10, 11, 14, 22),
            const Radius.circular(3),
          ),
          p,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(18, 7, 14, 22),
            const Radius.circular(3),
          ),
          p,
        );
      default:
        for (var i = 0; i < 4; i++) {
          canvas.drawRect(
            Rect.fromLTWH(10 + i * 6, 28 - i * 5, 4, 5 + i * 5),
            p,
          );
        }
    }
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant _BadgePainter old) =>
      old.index != index || old.color != color;
}

class _WeekStat extends StatelessWidget {
  const _WeekStat(this.icon, this.text);
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 6),
      Flexible(child: Text(text, style: Theme.of(context).textTheme.bodySmall)),
    ],
  );
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.metrics});
  final List<(String, int, IconData, String)> metrics;
  @override
  Widget build(BuildContext context) {
    final columns =
        MediaQuery.sizeOf(context).width >= 380 &&
            MediaQuery.textScalerOf(context).scale(16) <= 18
        ? 2
        : 1;
    Widget tile((String, int, IconData, String) m) => SurfaceCard(
      key: ValueKey('metric-${m.$4}'),
      onTap: () => Navigator.push(
        context,
        AiryPageRoute<void>(
          builder: (_) => MetricWordsScreen(title: m.$1, filter: m.$4),
        ),
      ),
      padding: const EdgeInsets.all(8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 34,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary
                    .withValues(alpha: .14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                m.$3,
                size: 20,
                color: m.$4 == 'confirmed' && AppSurfaces.dark(context)
                    ? AppColors.success
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(m.$1, style: const TextStyle(fontSize: 13, height: 1.3)),
                  const SizedBox(height: 4),
                  Text(
                    '${m.$2}',
                    key: ValueKey('metric-count-${m.$4}'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 12),
          ],
        ),
      ),
    );
    return SurfaceCard(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          for (var i = 0; i < metrics.length; i += columns)
            Padding(
              padding: EdgeInsets.only(
                bottom: i + columns < metrics.length ? 8 : 0,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (
                    var j = 0;
                    j < columns && i + j < metrics.length;
                    j++
                  ) ...[
                    if (j > 0) const SizedBox(width: 8),
                    Expanded(child: tile(metrics[i + j])),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class MetricWordsScreen extends StatelessWidget {
  const MetricWordsScreen({
    super.key,
    required this.title,
    required this.filter,
  });
  final String title, filter;
  @override
  Widget build(BuildContext context) {
    final d = TrainerScope.of(context), now = d.now();
    final words = [...?VocabularyRepository.current?.concepts, ...d.custom]
        .where((c) {
          final p = d.progress[c.id];
          if (p == null) return false;
          return switch (filter) {
            'training' => p.mastery.label == 'Тренирую',
            'recognizing' => p.mastery.label == 'Узнаю',
            'confirmed' => p.mastery.currentlyConsolidated,
            'due' => p.isDue(now) || p.isDue(now, recall: true),
            _ => p.exposures > 0,
          };
        })
        .toList();
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        top: false,
        child: AiryBackground(
          child: words.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Здесь пока нет слов.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(pageInset(context)),
                  itemCount: words.length,
                  itemBuilder: (c, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SurfaceCard(
                      onTap: () => Navigator.push(
                        context,
                        AiryPageRoute<void>(
                          builder: (_) => WordDetailScreen(concept: words[i]),
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  words[i].english,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                                Text(words[i].russian),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
