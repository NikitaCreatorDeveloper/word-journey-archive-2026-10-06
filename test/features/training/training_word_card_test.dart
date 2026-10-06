import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_journey/app/app_theme.dart';
import 'package:word_journey/features/training/widgets/training_word_card.dart';

void main() {
  testWidgets('Long labels keep readable type and fit the measured card', (
    tester,
  ) async {
    for (final word in [
      'происхождение',
      'необязательный',
      'произведённый',
      'house',
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 172,
                height: 60,
                child: TrainingWordCard(
                  text: word,
                  selected: false,
                  onPressed: () {},
                ),
              ),
            ),
          ),
        ),
      );
      final label = tester.widget<Text>(find.text(word));
      final painter = TextPainter(
        text: TextSpan(text: word, style: label.style),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 172 - 2 * AppTokens.cardHorizontalPadding);
      // Widget tests use Ahem; real Roboto word wrapping is inspected on POCO.
      expect(
        painter.height,
        lessThanOrEqualTo(60 - 2 * AppTokens.cardVerticalPadding),
        reason: word,
      );
      expect(label.style!.fontSize, greaterThanOrEqualTo(18));
      if (word == 'house') expect(label.style!.fontSize, 20);
      painter.dispose();
      expect(tester.takeException(), isNull);
    }
  });
  testWidgets('Compact cards keep large centered text and fit long words', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 144,
              height: 60,
              child: TrainingWordCard(
                text: 'достопримечательность',
                selected: false,
                onPressed: () {},
              ),
            ),
          ),
        ),
      ),
    );
    final text = tester.widget<Text>(find.text('достопримечательность'));
    expect(
      text.style!.fontSize,
      inInclusiveRange(AppTokens.wordMinSize, AppTokens.wordMaxSize),
    );
    expect(text.textAlign, TextAlign.center);
    expect(find.byType(Icon), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Error feedback never disables a new selection', (tester) async {
    var taps = 0;
    Future<void> show(int revision, bool selected) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 170,
            height: 100,
            child: TrainingWordCard(
              text: 'apple',
              selected: selected,
              errorRevision: revision,
              onPressed: () => taps++,
            ),
          ),
        ),
      ),
    );
    await show(0, false);
    await show(1, false);
    await tester.pump(const Duration(milliseconds: 30));
    expect(
      tester.widget<InkWell>(find.byType(InkWell)).enableFeedback,
      isFalse,
    );
    await tester.tap(find.text('apple'));
    expect(taps, 1);
    await show(1, true);
    expect(
      tester.widget<TrainingWordCard>(find.byType(TrainingWordCard)).selected,
      isTrue,
    );
    await tester.tap(find.text('apple'));
    expect(taps, 2);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Press stays short; correct locks input immediately and its appearance settles',
    (tester) async {
      var taps = 0;
      var settled = 0;
      Future<void> show(bool completed) => tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 160,
                height: 60,
                child: TrainingWordCard(
                  text: 'apple',
                  selected: false,
                  completed: completed,
                  onSettled: () => settled++,
                  onPressed: () => taps++,
                ),
              ),
            ),
          ),
        ),
      );
      await show(false);
      final pointer = await tester.startGesture(
        tester.getCenter(find.text('apple')),
      );
      await tester.pump(const Duration(milliseconds: 150));
      expect(
        tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
        .985,
      );
      await pointer.up();
      await tester.pumpAndSettle();
      expect(taps, 1);
      await show(true);
      expect(
        tester
            .widget<TrainingWordCard>(find.byType(TrainingWordCard))
            .completed,
        isTrue,
      );
      expect(tester.widget<InkWell>(find.byType(InkWell)).onTap, isNull);
      await tester.pump(const Duration(milliseconds: 139));
      expect(settled, 0);
      await tester.pump(const Duration(milliseconds: 1));
      expect(settled, 1);
      final ink = tester.widget<InkWell>(find.byType(InkWell));
      expect(ink.onTap, isNull);
      await tester.pumpAndSettle();
      final surface = tester.widgetList<Material>(find.byType(Material)).last;
      expect(surface.color, TrainerColors.light.card);
      expect(tester.takeException(), isNull);
    },
  );

  test('Atlas word colors stay readable in light and dark themes', () {
    double contrast(Color a, Color b) {
      final first = a.computeLuminance();
      final second = b.computeLuminance();
      return first > second
          ? (first + .05) / (second + .05)
          : (second + .05) / (first + .05);
    }

    for (final theme in [AppTheme.light, AppTheme.dark]) {
      final atlas = theme.extension<TrainerColors>()!;
      expect(
        contrast(atlas.card, theme.colorScheme.onSurface),
        greaterThan(4.5),
      );
      expect(contrast(atlas.selected, atlas.onSelected), greaterThan(4.5));
      expect(contrast(atlas.success, atlas.onSuccess), greaterThan(4.5));
      expect(contrast(atlas.error, atlas.onError), greaterThan(4.5));
    }
  });
}
