import '../training/logic/match_flow_controller.dart' as shared;
import 'match_flow_models.dart';
export 'match_flow_models.dart';

/// The debug lab and production board execute exactly the same scheduler.
class MatchFlowController extends shared.MatchFlowController {
  MatchFlowController({
    List<LabConcept>? pool,
    super.now,
    super.random,
    super.autoSchedule,
    super.timerFactory,
  }) : super(pool: pool ?? labConceptPool);
  static const slowCycle = shared.MatchFlowController.slowCycle,
      confirmation = shared.MatchFlowController.confirmation,
      slowAppearance = shared.MatchFlowController.slowAppearance,
      acceleratedRemaining = shared.MatchFlowController.acceleratedRemaining,
      fastAppearance = shared.MatchFlowController.fastAppearance,
      readableOpacity = shared.MatchFlowController.readableOpacity;
  static final slots = shared.MatchFlowController.slotsFor(5);
}
