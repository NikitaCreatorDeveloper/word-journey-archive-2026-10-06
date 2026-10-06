import 'package:lottie/lottie.dart';

enum MatchDecoration { correct, combo, milestone, victory }

typedef MatchCompositionLoader = Future<LottieComposition> Function(
  String path,
);

/// One parse per asset/process, including failures. Gameplay only reads ready
/// compositions; pending or failed decoration always has an immediate fallback.
class MatchFeedbackAssets {
  MatchFeedbackAssets({MatchCompositionLoader? loader})
    : _loader = loader ?? _load;
  static final shared = MatchFeedbackAssets();
  static Future<LottieComposition> _load(String path) =>
      AssetLottie(path, backgroundLoading: true).load();
  final MatchCompositionLoader _loader;
  final _ready = <MatchDecoration, LottieComposition>{};
  final _failures = <MatchDecoration, Object>{};
  Future<void>? _preloading;
  Map<MatchDecoration, Object> get failures => Map.unmodifiable(_failures);
  LottieComposition? composition(MatchDecoration kind) => _ready[kind];

  Future<void> preload() => _preloading ??= Future.wait([
    for (final kind in MatchDecoration.values) _prepare(kind),
  ]).then((_) {});

  Future<void> _prepare(MatchDecoration kind) async {
    try {
      final value = await _loader('assets/lottie/${kind.name}.json');
      if (value.layers.isEmpty ||
          value.duration <= Duration.zero ||
          value.images.isNotEmpty ||
          value.fonts.isNotEmpty) {
        throw const FormatException(
          'Match decoration must be a finite vector composition',
        );
      }
      _ready[kind] = value;
    } catch (error) {
      _failures[kind] = error;
    }
  }
}
