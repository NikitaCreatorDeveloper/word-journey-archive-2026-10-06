import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_journey/app/word_journey_app.dart';

void main() {
  testWidgets(
    'Categories, review and progress replace travel without a fourth tab',
    (t) async {
      await t.pumpWidget(const WordJourneyApp());
      await t.pumpAndSettle();
      expect(find.byType(NavigationDestination), findsNWidgets(3));
      expect(find.text('Путешествие'), findsNothing);
      for (var i = 0; i < 3; i++) {
        await t.tap(find.byType(NavigationDestination).at(i));
        await t.pumpAndSettle();
        expect(
          t.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
          i,
        );
        expect(t.takeException(), isNull);
      }
    },
  );
  for (final size in [const Size(320, 568), const Size(568, 320)]) {
    testWidgets('Navigation safe area and large text $size', (t) async {
      t.view.devicePixelRatio = 1;
      t.view.physicalSize = size;
      t.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(t.view.reset);
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      await t.pumpWidget(const WordJourneyApp());
      await t.pumpAndSettle();
      for (var i = 0; i < 3; i++) {
        await t.tap(find.byType(NavigationDestination).at(i));
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
      }
    });
  }
}
