import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:word_journey/app/word_journey_app.dart';
import 'package:word_journey/features/profile/cefr_level.dart';
import 'package:word_journey/features/profile/cefr_profile.dart';
import 'package:word_journey/features/profile/level_selector_screen.dart';

class FailingStore implements LevelStore {
  @override
  Future<CefrLevel?> read() async => null;
  @override
  Future<void> write(CefrLevel level) async => throw StateError('disk');
}

void main() {
  test('A1–C1 have stable ordered metadata and separate product defaults', () {
    expect(CefrLevel.values.map((l) => l.id), ['a1', 'a2', 'b1', 'b2', 'c1']);
    expect(CefrLevel.values.map((l) => l.shortLabel), [
      'A1',
      'A2',
      'B1',
      'B2',
      'C1',
    ]);
    expect(CefrLevel.values.map((l) => l.order), [0, 1, 2, 3, 4]);
    expect(CefrLevel.values.map((l) => l.defaultWordPoolSize), [
      12,
      14,
      16,
      18,
      20,
    ]);
    for (final l in CefrLevel.values) {
      expect(l.localizedTitle, isNotEmpty);
      expect(l.shortDescription, isNotEmpty);
      expect(CefrLevel.fromId(l.id), l);
    }
    expect(CefrLevel.fromId('invalid'), isNull);
  });
  test('Fresh profile, write and reload from a new store survive controller restart', () async {
    SharedPreferences.setMockInitialValues({'existing.progress': 42});
    final first = CefrProfile(PreferencesLevelStore());
    await first.load();
    expect(first.level, isNull);
    expect(await first.choose(CefrLevel.b2), isTrue);
    first.dispose();
    final restarted = CefrProfile(PreferencesLevelStore());
    await restarted.load();
    expect(restarted.level, CefrLevel.b2);
    await restarted.choose(CefrLevel.a2);
    final third = CefrProfile(PreferencesLevelStore());
    await third.load();
    expect(third.level, CefrLevel.a2);
    expect(
      (await SharedPreferences.getInstance()).getInt('existing.progress'),
      42,
    );
    restarted.dispose();
    third.dispose();
  });
  test('Failed save does not accept an unsaved level', () async {
    final profile = CefrProfile(FailingStore());
    await profile.load();
    expect(await profile.choose(CefrLevel.c1), isFalse);
    expect(profile.level, isNull);
    expect(profile.error, isNotNull);
    profile.dispose();
  });
  for (final level in CefrLevel.values) {
    testWidgets(
      'First-run selection ${level.shortLabel} persists through app rebuild',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        await tester.pumpWidget(const WordJourneyApp());
        await tester.pumpAndSettle();
        expect(find.text('Какой у вас уровень английского?'), findsOneWidget);
        expect(find.byType(NavigationBar), findsNothing);
        final choice = find.byKey(ValueKey('cefr-${level.id}'));
        await tester.ensureVisible(choice);
        await tester.pumpAndSettle();
        await tester.tap(choice);
        await tester.pumpAndSettle();
        expect(find.byType(NavigationBar), findsOneWidget);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpWidget(const WordJourneyApp());
        await tester.pumpAndSettle();
        expect(find.byType(LevelSelectorScreen), findsNothing);
        expect(find.text(level.shortLabel), findsOneWidget);
      },
    );
  }
  testWidgets('Settings change preserves selected tab and persists only CEFR', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      PreferencesLevelStore.key: 'a1',
      'test.progress': 7,
    });
    await tester.pumpWidget(const WordJourneyApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byType(NavigationDestination).at(2));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('open-level-settings')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('cefr-c1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cefr-c1')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      2,
    );
    expect(find.text('C1'), findsOneWidget);
    expect((await SharedPreferences.getInstance()).getInt('test.progress'), 7);
  });
  for (final brightness in Brightness.values) {
    testWidgets('First-run selector fits large text in $brightness', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 568);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      tester.platformDispatcher.platformBrightnessTestValue = brightness;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await tester.pumpWidget(const WordJourneyApp());
      await tester.pumpAndSettle();
      for (final level in CefrLevel.values) {
        await tester.ensureVisible(find.byKey(ValueKey('cefr-${level.id}')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });
  }
}
