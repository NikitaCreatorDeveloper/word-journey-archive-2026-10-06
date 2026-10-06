import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_journey/app/app_theme.dart';
import 'package:word_journey/features/progress/progress_screen.dart';
import 'package:word_journey/features/progress/trainer_data.dart';
import 'package:word_journey/features/progress/trainer_store.dart';

void main() {
  for (final spec in [(320.0, 1.5), (320.0, 1.6), (393.0, 2.0)]) {
    testWidgets(
      'Premium progress uses readable adaptive rows ${spec.$1}/${spec.$2}',
      (t) async {
        t.view.devicePixelRatio = 1;
        t.view.physicalSize = Size(spec.$1, 800);
        addTearDown(t.view.reset);
        final data = TrainerData(store: MemoryTrainerStore());
        await data.load();
        final original = FlutterError.onError;
        FlutterError.onError = (details) {
          debugPrint(details.toString());
          original?.call(details);
        };
        await t.pumpWidget(
          TrainerScope(
            data: data,
            child: MaterialApp(
              theme: AppTheme.dark,
              builder: (c, child) => MediaQuery(
                data: MediaQuery.of(c)
                    .copyWith(textScaler: TextScaler.linear(spec.$2)),
                child: child!,
              ),
              home: const Scaffold(body: ProgressScreen()),
            ),
          ),
        );
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
        FlutterError.onError = original;
        await t.pumpWidget(const SizedBox());
        await data.flush();
        data.dispose();
      },
    );
  }
}
