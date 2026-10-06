import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import 'cefr_level.dart';
import 'cefr_profile.dart';

class LevelSelectorScreen extends StatelessWidget {
  const LevelSelectorScreen({super.key, this.settings = false});
  final bool settings;
  @override
  Widget build(BuildContext context) {
    final profile = ProfileScope.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: settings
          ? AppBar(title: const Text('Уровень английского'))
          : null,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!settings) ...[
                    Text(
                      'WORD JOURNEY',
                      style: theme.textTheme.labelMedium?.copyWith(
                        letterSpacing: 2,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Какой у вас уровень английского?',
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    settings
                        ? 'Выберите уровень для новых тренировок. Ваш прогресс сохранится.'
                        : 'Выберите ближайший вариант. Его можно изменить позже в настройках.',
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.4),
                  ),
                  const SizedBox(height: 24),
                  for (final level in CefrLevel.values) ...[
                    Semantics(
                      selected: profile.level == level,
                      button: true,
                      child: Material(
                        color: profile.level == level
                            ? TrainerColors.of(context).selected
                            : TrainerColors.of(context).card,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: BorderSide(
                            color: profile.level == level
                                ? theme.colorScheme.primary
                                : TrainerColors.of(context).cardOutline,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          key: ValueKey('cefr-${level.id}'),
                          onTap: profile.saving
                              ? null
                              : () async {
                                  final saved = await profile.choose(level);
                                  if (saved && settings && context.mounted) {
                                    Navigator.pop(context);
                                  }
                                },
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 48,
                                  child: Text(
                                    level.shortLabel,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        level.localizedTitle,
                                        style: theme.textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        level.shortDescription,
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                                if (profile.level == level)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 8),
                                    child: Icon(Icons.check_rounded, size: 20),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (profile.saving) const LinearProgressIndicator(),
                  if (profile.error case final error?)
                    Text(
                      error,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
