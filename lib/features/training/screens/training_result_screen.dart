import 'package:flutter/material.dart';

import '../../../app/airy_components.dart';
import '../../../app/reward_presentation.dart';
import '../model/session_result.dart';
import '../../progress/session_journal.dart';
import '../../progress/trainer_data.dart';
import '../../progress/achievement_service.dart';

class TrainingResultScreen extends StatelessWidget {
  const TrainingResultScreen({
    super.key,
    required this.result,
    required this.onPlayAgain,
    required this.onBackToSetup,
    this.journal,
    this.victoryFeedback,
  });
  final SessionResult result;
  final SessionJournal? journal;
  final Widget? victoryFeedback;
  final VoidCallback onPlayAgain, onBackToSetup;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context),
        data = TrainerScope.maybeOf(context),
        j = journal;
    final seconds = result.elapsedTime.inSeconds,
        rank = rankIndex(data?.consolidatedCount ?? 0);
    final time =
        '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
    final attempts = result.completedMatches + result.wrongAttempts;
    final accuracy = attempts == 0
        ? '—'
        : '${(100 * result.completedMatches / attempts).round()}%';
    final awards = j == null
        ? <Map<String, dynamic>>[]
        : data?.awards
                  .where((a) => !j.awardsBefore.contains(a['id']))
                  .toList() ??
              [];
    return Scaffold(
      appBar: AppBar(title: const Text('Результат')),
      body: SafeArea(
        top: false,
        child: AiryBackground(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              pageInset(context),
              24,
              pageInset(context),
              32,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: victoryFeedback == null
                      ? RankBadge(rank: rank, size: 64)
                      : SizedBox(
                          width: 64,
                          height: 64,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Positioned(
                                left: -24,
                                top: -24,
                                width: 112,
                                height: 112,
                                child: victoryFeedback!,
                              ),
                              RankBadge(rank: rank, size: 64),
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: 16),
                Text(
                  switch (result.endReason) {
                    SessionEndReason.targetReached => 'Цель достигнута',
                    SessionEndReason.mistakeLimit => 'Испытание завершено',
                    SessionEndReason.timeExpired => 'Время вышло',
                    SessionEndReason.userExited => 'Тренировка завершена',
                  },
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 24),
                SurfaceCard(
                  child: Column(
                    children: [
                      Text(
                        '${result.completedMatches} / ${result.targetMatches}',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('успешных совпадений'),
                      const SizedBox(height: 20),
                      if (result.targetReached)
                        Text(
                          'Время: $time',
                          style: theme.textTheme.titleMedium,
                        ),
                      const SizedBox(height: 8),
                      Text(
                        'Ошибки: ${result.wrongAttempts}',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text('Точность выбора: $accuracy'),
                    ],
                  ),
                ),
                if (j != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Новых понятий: ${j.newConcepts} · предъявлено разных: ${j.presented.length}',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Успешных совпадений: ${result.completedMatches} · повторных: ${result.completedMatches - j.correctlyMatched.length}',
                  ),
                  if (data?.error case final error?) ...[
                    const SizedBox(height: 12),
                    Text(error),
                    TextButton(
                      onPressed: j.retry,
                      child: const Text('Повторить сохранение'),
                    ),
                  ],
                ],
                const SizedBox(height: 16),
                const Text(
                  'Продолжите знакомство со словами или вернитесь к ним по сроку. Один раунд не подтверждает знание навсегда.',
                ),
                if (j != null &&
                    data != null &&
                    (rank > rankIndex(j.consolidatedBefore) ||
                        awards.isNotEmpty)) ...[
                  const SectionHeader('Награда за практику'),
                  RewardPresentation(
                    title: rank > rankIndex(j.consolidatedBefore)
                        ? 'Новый ранг: ${rankNames[rank]}'
                        : achievementDefinitions[awards.first['id']]?.$1 ??
                              'Достижение',
                    detail: rank > rankIndex(j.consolidatedBefore)
                        ? '${data.consolidatedCount} разных понятий подтверждено позже'
                        : achievementDefinitions[awards.first['id']]?.$2 ?? '',
                    rank: rank,
                  ),
                  for (final a in awards.skip(1))
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        'Достижение: ${achievementDefinitions[a['id']]?.$1 ?? a['id']}',
                      ),
                    ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: onPlayAgain,
                  child: const Text('Ещё раз'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: onBackToSetup,
                  child: const Text('К настройке'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
