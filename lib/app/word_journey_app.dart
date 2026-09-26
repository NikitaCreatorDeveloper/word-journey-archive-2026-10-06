import 'package:flutter/material.dart';

import 'app_shell.dart';
import 'app_theme.dart';

class WordJourneyApp extends StatelessWidget {
  const WordJourneyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Word Journey',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: const AppShell(),
    );
  }
}
