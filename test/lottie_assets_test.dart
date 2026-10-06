import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:word_journey/features/training/widgets/match_feedback_assets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Four original finite vector assets parse and render at representative phases', () async {
    final expected = [433, 600, 450, 900];
    for (final kind in MatchDecoration.values) {
      final bytes = await rootBundle.load('assets/lottie/${kind.name}.json');
      final raw = jsonDecode(utf8.decode(bytes.buffer.asUint8List())) as Map;
      expect(raw['assets'], isEmpty);
      expect(raw.containsKey('fonts'), isFalse);
      expect(raw['fr'], [60, 30, 60, 30][kind.index]);
      expect(raw['w'], [80, 360, 80, 420][kind.index]);
      expect(raw['h'], raw['w']);
      final composition = await LottieComposition.fromByteData(bytes);
      expect(composition.images, isEmpty);
      expect(composition.layers, isNotEmpty);
      expect(
        composition.duration.inMilliseconds,
        closeTo(expected[kind.index], 2),
      );
      final drawable = LottieDrawable(composition);
      for (final phase in [0.0, .15, .35, .55, .8, 1.0]) {
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        drawable.setProgress(phase);
        drawable.draw(canvas, const Rect.fromLTWH(0, 0, 160, 160));
        final picture = recorder.endRecording();
        if (const bool.fromEnvironment('LOTTIE_CONTACT_SHEET')) {
          final image = await picture.toImage(160, 160);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          final directory = Directory('docs/lottie-art-review')
            ..createSync(recursive: true);
          File('${directory.path}/${kind.name}-${(phase * 100).round()}.png')
              .writeAsBytesSync(data!.buffer.asUint8List());
          image.dispose();
        }
        picture.dispose();
      }
    }
  });
  test(
    'Preload reuses compositions and caches missing/malformed asset failures',
    () async {
      final bytes = await rootBundle.load('assets/lottie/correct.json');
      final valid = await LottieComposition.fromByteData(bytes);
      final calls = <String>[];
      final assets = MatchFeedbackAssets(
        loader: (path) async {
          calls.add(path);
          if (path.endsWith('combo.json')) throw StateError('missing');
          if (path.endsWith('victory.json')) {
            return LottieComposition.parseJsonBytes(utf8.encode('{invalid'));
          }
          return valid;
        },
      );
      final first = assets.preload();
      expect(identical(first, assets.preload()), isTrue);
      await first;
      await assets.preload();
      expect(calls, hasLength(4));
      expect(
        identical(assets.composition(MatchDecoration.correct), valid),
        isTrue,
      );
      expect(assets.composition(MatchDecoration.combo), isNull);
      expect(assets.composition(MatchDecoration.victory), isNull);
      expect(
        assets.failures.keys,
        containsAll([MatchDecoration.combo, MatchDecoration.victory]),
      );
    },
  );
}
