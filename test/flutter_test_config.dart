import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:word_journey/features/profile/cefr_profile.dart';
import 'package:word_journey/features/vocabulary/vocabulary_repository.dart';
import 'package:word_journey/features/progress/trainer_data.dart';
import 'package:word_journey/features/progress/trainer_store.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await VocabularyRepository.load();
  });
  setUp(() {
    final memory = MemoryTrainerStore();
    TrainerData.testStoreFactory = () async => memory;
    SharedPreferences.setMockInitialValues({PreferencesLevelStore.key: 'a1'});
  });
  await testMain();
}
