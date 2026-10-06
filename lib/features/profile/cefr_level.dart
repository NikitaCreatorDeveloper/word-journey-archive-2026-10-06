enum CefrLevel {
  a1('a1', 'A1', 'Начальный', 'Понимаю простые слова и короткие фразы.', 0, 12),
  a2(
    'a2',
    'A2',
    'Базовый',
    'Могу общаться в знакомых повседневных ситуациях.',
    1,
    14,
  ),
  b1(
    'b1',
    'B1',
    'Средний',
    'Поддерживаю разговор и рассказываю о своём опыте.',
    2,
    16,
  ),
  b2(
    'b2',
    'B2',
    'Выше среднего',
    'Уверенно обсуждаю разные темы и объясняю своё мнение.',
    3,
    18,
  ),
  c1(
    'c1',
    'C1',
    'Продвинутый',
    'Свободно выражаю мысли и понимаю оттенки смысла.',
    4,
    20,
  );

  const CefrLevel(
    this.id,
    this.shortLabel,
    this.localizedTitle,
    this.shortDescription,
    this.order,
    this.defaultWordPoolSize,
  );
  final String id;
  final String shortLabel;
  final String localizedTitle;
  final String shortDescription;
  final int order;

  /// Product tuning, not a CEFR standard.
  final int defaultWordPoolSize;

  static CefrLevel? fromId(String? id) {
    for (final level in values) {
      if (level.id == id) return level;
    }
    return null;
  }
}
