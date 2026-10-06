import 'package:flutter_test/flutter_test.dart';
import 'package:word_journey/features/training/logic/adaptive_refill_controller.dart';

import 'features/training/adaptive_refill_test.dart' show Fixture;
import 'features/training/matching_engine_test.dart' as h;

void main() {
  test('A alone spends about five seconds in its complete return cycle', () {
    final f = Fixture(), before = h.board(f.game);
    final a = f.match();
    f.advance(3999);
    expect(h.board(f.game), before);
    expect(f.game.isActive(a.id), isFalse);
    f.advance(1001);
    expect(f.game.cards.any((c) => c.id == a.id), isFalse);
    for (final slot in before.keys.where(
      (slot) => before[slot]?.pairId == a.pairId,
    )) {
      expect(f.controller.visualFor(slot).opacity, 1);
    }
  });

  test('B at 500 ms accelerates A over about a second, keeping a smooth outgoing phase', () {
    final f = Fixture(), a = f.match();
    final aSlot = f.game.slotIdOf(a.id)!;
    f.advance(500);
    f.match();
    f.advance(500);
    expect(f.game.cardAt(aSlot), same(a));
    f.advance(500);
    expect(f.game.cardAt(aSlot), isNot(same(a)));
    expect(f.controller.visualFor(aSlot).phase, RefillPhase.active);
  });
}
