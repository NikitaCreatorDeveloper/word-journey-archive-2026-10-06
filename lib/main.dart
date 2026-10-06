import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';

import 'app/word_journey_app.dart';
import 'features/match_flow_lab/match_flow_lab_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode &&
      WidgetsBinding.instance.platformDispatcher.defaultRouteName ==
          matchFlowLabRoute) {
    runApp(const MatchFlowLabApp());
    return;
  }
  runApp(const WordJourneyApp());
}
