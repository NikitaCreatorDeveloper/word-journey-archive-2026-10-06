import 'package:flutter/foundation.dart';

typedef MatchSlotId = ({bool left, int row});
typedef MatchInstance = ({MatchSlotId slot, int generation});

String matchSlotLabel(MatchSlotId slot) =>
    '${slot.left ? 'L' : 'R'}${slot.row + 1}';

@immutable
class MatchConcept {
  const MatchConcept(this.id, this.english, this.russian);
  final String id, english, russian;
}

@immutable
class MatchCardContent {
  const MatchCardContent(
    this.slotId,
    this.generation,
    this.concept, {
    this.occurrence = 0,
  });
  final MatchSlotId slotId;
  final int generation;
  final MatchConcept concept;
  final int occurrence;
  bool get isEmpty => concept.id.isEmpty;
  String get conceptId => concept.id;
  String get text => slotId.left ? concept.english : concept.russian;
  MatchInstance get instance => (slot: slotId, generation: generation);
}

enum MatchVisualState {
  active,
  success,
  fading,
  appearing,
  waitingPartner,
  empty,
}

enum FlowFeedback { ignored, selected, deselected, incorrect, correct }

@immutable
class CardTransitionVisual {
  const CardTransitionVisual({
    required this.state,
    required this.textOpacity,
    required this.surfaceOpacity,
    required this.successTint,
    this.errorTint = 0,
  });
  final MatchVisualState state;
  final double textOpacity, surfaceOpacity, successTint;
  final double errorTint;
  @override
  bool operator ==(Object other) =>
      other is CardTransitionVisual &&
      state == other.state &&
      textOpacity == other.textOpacity &&
      surfaceOpacity == other.surfaceOpacity &&
      successTint == other.successTint &&
      errorTint == other.errorTint;
  @override
  int get hashCode =>
      Object.hash(state, textOpacity, surfaceOpacity, successTint, errorTint);
}

@immutable
class MatchSlotState {
  const MatchSlotState({
    required this.content,
    required this.visual,
    required this.matched,
    required this.selected,
    required this.interactive,
  });
  final MatchCardContent content;
  final CardTransitionVisual visual;
  final bool matched, selected, interactive;
  @override
  bool operator ==(Object other) =>
      other is MatchSlotState &&
      identical(content, other.content) &&
      visual == other.visual &&
      matched == other.matched &&
      selected == other.selected &&
      interactive == other.interactive;
  @override
  int get hashCode =>
      Object.hash(content, visual, matched, selected, interactive);
}
