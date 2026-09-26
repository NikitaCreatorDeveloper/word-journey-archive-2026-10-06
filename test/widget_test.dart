import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_journey/app/word_journey_app.dart';

const _titles = ['Путешествие', 'Темы', 'Повторение'];
const _messages = [
  'Здесь появится карта мира',
  'Тестовая тренировка',
  'Здесь появятся слова для повторения',
];

void expectSection(WidgetTester tester, int index) {
  expect(
    find.descendant(
      of: find.byType(AppBar),
      matching: find.text(_titles[index]),
    ),
    findsOneWidget,
  );
  for (var i = 0; i < _messages.length; i++) {
    expect(find.text(_messages[i]), i == index ? findsOneWidget : findsNothing);
  }
  expect(
    tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
    index,
  );
  expect(tester.takeException(), isNull);
}

Future<void> selectSection(WidgetTester tester, int index) async {
  await tester.tap(find.byType(NavigationDestination).at(index));
  await tester.pumpAndSettle();
  expectSection(tester, index);
}

void main() {
  testWidgets('Opens travel and switches between all three sections', (
    tester,
  ) async {
    await tester.pumpWidget(const WordJourneyApp());

    expectSection(tester, 0);
    expect(find.byType(NavigationDestination), findsNWidgets(3));
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.text('Flutter Demo Home Page'), findsNothing);

    for (final index in [1, 2, 0, 2, 1]) {
      await selectSection(tester, index);
    }
  });

  testWidgets('Follows system theme without resetting the selected section', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await tester.pumpWidget(const WordJourneyApp());
    await selectSection(tester, 2);

    ThemeData currentTheme() =>
        Theme.of(tester.element(find.byType(NavigationBar)));

    expect(currentTheme().brightness, Brightness.light);
    expect(currentTheme().useMaterial3, isTrue);

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await tester.pumpAndSettle();
    expect(currentTheme().brightness, Brightness.dark);
    expectSection(tester, 2);

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    await tester.pumpAndSettle();
    expect(currentTheme().brightness, Brightness.light);
    expectSection(tester, 2);
  });

  for (final size in [
    const Size(320, 568),
    const Size(568, 320),
    const Size(360, 800),
  ]) {
    testWidgets(
      'Handles ${size.width} x ${size.height}, insets and large text',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        tester.view.padding = const FakeViewPadding(top: 24, bottom: 34);
        tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 34);
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetPadding);
        addTearDown(tester.view.resetViewPadding);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        await tester.pumpWidget(const WordJourneyApp());

        for (final index in [0, 1, 2]) {
          await selectSection(tester, index);
          final titleRect = tester.getRect(
            find.descendant(
              of: find.byType(AppBar),
              matching: find.text(_titles[index]),
            ),
          );
          expect(titleRect.top, greaterThanOrEqualTo(24));
          final destinationCenter = tester.getCenter(
            find.byType(NavigationDestination).at(index),
          );
          expect(destinationCenter.dy, lessThan(size.height - 34));
        }
      },
    );
  }
}
