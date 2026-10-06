import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_journey/app/app_theme.dart';
import 'package:word_journey/features/training/widgets/lightning_feedback.dart';

void main() {
  for (final compact in [false, true]) {
    testWidgets('Reward fits 200% compact=$compact', (t) async {
      await t.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          builder: (c, child) => MediaQuery(
            data: MediaQuery.of(c)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: Scaffold(
            body: Center(
              child: LightningFeedback(
                revision: 1,
                combo: 60,
                compact: compact,
              ),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
    });
  }
}
