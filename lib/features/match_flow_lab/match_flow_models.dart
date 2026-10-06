import '../training/model/match_flow_models.dart';
export '../training/model/match_flow_models.dart';

typedef LabSlotId = MatchSlotId;
typedef LabInstance = MatchInstance;
typedef LabConcept = MatchConcept;
typedef LabCardContent = MatchCardContent;
typedef LabVisualState = MatchVisualState;
typedef LabFeedback = FlowFeedback;
typedef LabSlotState = MatchSlotState;

String labSlotLabel(LabSlotId slot) => matchSlotLabel(slot);

final labConceptPool = List<LabConcept>.unmodifiable([
  for (final (index, words) in const [
    ('car', 'машина'),
    ('water', 'вода'),
    ('book', 'книга'),
    ('house', 'дом'),
    ('sun', 'солнце'),
    ('moon', 'луна'),
    ('tree', 'дерево'),
    ('flower', 'цветок'),
    ('bird', 'птица'),
    ('fish', 'рыба'),
    ('cat', 'кот'),
    ('dog', 'собака'),
    ('bread', 'хлеб'),
    ('milk', 'молоко'),
    ('apple', 'яблоко'),
    ('cheese', 'сыр'),
    ('coffee', 'кофе'),
    ('tea', 'чай'),
    ('chair', 'стул'),
    ('table', 'стол'),
    ('window', 'окно'),
    ('door', 'дверь'),
    ('road', 'дорога'),
    ('bridge', 'мост'),
    ('train', 'поезд'),
    ('plane', 'самолёт'),
    ('boat', 'лодка'),
    ('beach', 'пляж'),
    ('mountain', 'гора'),
    ('river', 'река'),
    ('rain', 'дождь'),
    ('snow', 'снег'),
    ('wind', 'ветер'),
    ('clock', 'часы'),
    ('key', 'ключ'),
    ('bag', 'сумка'),
  ].indexed)
    LabConcept('lab-$index', words.$1, words.$2),
]);
