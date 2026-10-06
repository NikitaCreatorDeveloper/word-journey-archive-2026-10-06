import 'package:flutter/material.dart';

import 'trainer_data.dart';
import 'mastery_policy.dart';

class SessionHistoryScreen extends StatelessWidget {
  const SessionHistoryScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final sessions = TrainerScope.of(context).sessions.reversed.toList();
    return Scaffold(
      appBar: AppBar(title: const Text('История занятий')),
      body: ListView.builder(
        itemCount: sessions.length,
        itemBuilder: (context, index) {
          final s = sessions[index];
          return ListTile(
            title: Text(
              '${s['mode'] == 'match' ? 'Match' : 'Вспоминание'} · ${s['completed'] == true ? 'завершено' : 'остановлено'}',
            ),
            subtitle: Text(
              '${practiceDay(DateTime.parse(s['at'] as String))} · ${s['correct']} верно · ${s['wrong']} ошибок · ${((s['elapsedMs'] as int? ?? 0) / 1000).round()} с',
            ),
          );
        },
      ),
    );
  }
}
