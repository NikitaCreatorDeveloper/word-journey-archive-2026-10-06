# Lottie Match feedback spike — 02.10.2026

## СДЕЛАНО

В существующем D:\Projects\word_journey реализованы четыре оригинальные векторные Lottie JSON: correct (433 ms), combo (700 ms), milestone (450 ms), victory (900 ms). Общий размер JSON 28 290 bytes. Тонкая amber/violet молния, lavender→mint check, четыре combo sparks, энергия у HUD markers и мягкая victory. Текст «Отлично!» / «Комбо xN» рисует Flutter. Нет чужих ресурсов, текста/шрифтов в JSON, raster images, blur/filter, expressions, masks или 3D. Lottie 3.6.1; версии всех прежних dependencies сохранены, добавлены только четыре транзитивных пакета. Подробные artboard/FPS/цвета/ограничения: [lottie-assets.md](lottie-assets.md).

MatchFeedbackController / MatchFeedbackOverlay: одна награда и один HUD pulse, без длинной FIFO очереди. Victory имеет высший приоритет, stale callbacks защищены token/dispose. Preload/parsing один раз в isolate при входе в Full/Calm; tap не ждёт загрузки. SafeMatchLottie использует публичный LottieDrawable renderer и конечный локальный cache ui.Picture drawing commands, не raster PNG; 60 FPS artwork на 120 Hz display. Ошибки preload/parse/render ловятся локально, без подмены глобального error handler; fallback — прежний LightningFeedback / лёгкий Flutter star/check. IgnorePointer, состояние пары изменяется до декоративного work.

Full: четыре Lottie. Calm: скрыты particles/trail. Production Minimal/reduced motion полностью использует прежнюю Flutter-ветку, без дополнительного Lottie overlay/result victory; standalone wrapper переиспользует один state/ticker. MatchingEngine, cards, 4/5 pairs, timer, progress/HUD, connection line, background, navigation, sound/haptics сохранены. Full/Calm victory передаёт оставшееся время в result decoration; прежние finish 620/300/1 ms и fade 140/120/1 ms не менялись.

## PERFORMANCE BEFORE

Свежий запуск исходного приложения до внедрения: UI p95 **3.902–4.193 ms**, Raster p95 **7.854–8.228 ms** (`control-before`; screenshot на входе, 850 ms после 60).

Основное A/B ниже: тот же production Match в одном profile APK, одинаковый Random(26), C1/5 pairs/Full, 60 matches, 3 ошибки при 7/23/41, combo x2–x5 и выше, milestones 20/30/60, sounds+haptics включены, cadence 170 ms, одинаковые 1150 ms после 60 включая результат. Итоговый A CustomPainter: UI p95 **3.240–3.883 ms**, Raster p95 **7.949–8.033 ms**.

## PERFORMANCE LOTTIE

Итоговый B Full: UI p95 **3.400–4.407 ms**, Raster p95 **7.657–8.152 ms**. Два Full прогона прошли обязательные числовые пороги UI <8 / Raster <8.3; желательное Raster ≤7.5 не достигнуто. **Полную приёмку по всем условиям объявлять нельзя**: локальные пики и физическая оценка визуала/rapid taps остаются.

POCO X4 Pro 5G / 2201116PG / 2aa7666ff377, Android 13, 1080×2400, density 440, font scale 1. Display 120.00001 Hz подтверждён до/после и в конце всех 12 сценариев. Final-clean без screenshot/video во время нагрузки. Отдельная визуальная запись исключена из метрик. Probe вызывает production WordCard.onPressed, проверяет IgnorePointer предков и использует отдельный MemoryTrainerStore; пользовательская БД не открывается. Physical touches / sensor→photons latency не измерены; настоящие gestures проверены widget tests, ощущение на устройстве проверяет пользователь.

Все значения ms. >8.333 / >16.667 — число FrameTiming кадров с max(build,raster) выше бюджета, **proxy**, не прямой счёт аппаратно потерянных display frames. State latency измеряется внутри production handler до декоративного work; post-frame — до callback, включает scheduling и не равен появлению пикселей. Lookup overhead отдельно в JSON. Основные сценарии: 126 accepted taps, 60 правильных пар, ровно 3 ошибки; A 0 Lottie paints, B Full 697/700; compositions ready 4, load failures 0.

| Scenario | Frames | UI p50 | UI p95 | Raster p50 | Raster p95 | >8.333 | >16.667 | State p95 | Post-frame p95 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| A-custompaint-full-c1 | 1404 | 1.107 | 3.883 | 4.747 | 8.033 | 53 | 3 | 0.181 | 13.096 |
| B-lottie-full-c1 | 1384 | 1.408 | 4.407 | 5.068 | 7.657 | 44 | 2 | 0.197 | 16.359 |
| A-custompaint-repeat-c1 | 1396 | 1.350 | 3.240 | 5.947 | 7.949 | 50 | 2 | 0.075 | 10.919 |
| B-lottie-repeat-c1 | 1394 | 1.448 | 3.400 | 5.933 | 8.152 | 60 | 2 | 0.073 | 10.315 |
| B-lottie-calm-c1 | 1350 | 1.396 | 3.783 | 5.827 | 7.982 | 46 | 0 | 0.084 | 10.672 |
| A-custompaint-minimal-c1 | 969 | 0.725 | 4.090 | 5.598 | 8.315 | 53 | 9 | 0.474 | 26.574 |
| B-lottie-minimal-c1 | 962 | 0.742 | 4.244 | 5.663 | 10.328 | 83 | 12 | 0.421 | 25.466 |
| idle-match-c1 | 5 | 5.270 | 5.548 | 6.483 | 7.228 | 0 | 0 | 0.000 | 0.000 |
| correct-line-c1 | 67 | 1.392 | 2.689 | 5.592 | 8.088 | 3 | 0 | 0.382 | 24.397 |
| combo-lightning-c1 | 79 | 1.042 | 5.225 | 5.860 | 14.639 | 11 | 3 | 0.427 | 24.536 |
| batch-refill-c1 | 94 | 1.167 | 3.374 | 6.162 | 8.307 | 5 | 1 | 0.377 | 26.751 |
| milestone-20-c1 | 79 | 1.149 | 7.187 | 5.882 | 10.632 | 9 | 0 | 0.383 | 28.903 |

### Локальные окна

Monotonic Timeline timestamps сопоставлены с FrameTiming.buildStart. Перекрывающиеся окна одного kind не дублируют frame. Milestone window включает HUD/поле; victory включает переход. Ниже все Full A/B пики.

| Scenario | Window | Frames | UI p95 | Raster p95 | Raster p99 | >16.667 |
|---|---|---:|---:|---:|---:|---:|
| A-custompaint-full-c1 | correct | 297 | 3.905 | 8.275 | 10.880 | 2 |
| A-custompaint-full-c1 | combo | 1202 | 3.937 | 7.980 | 9.157 | 1 |
| A-custompaint-full-c1 | milestone | 158 | 4.078 | 8.039 | 9.863 | 0 |
| A-custompaint-full-c1 | victory | 100 | 3.842 | 12.993 | 19.163 | 1 |
| A-custompaint-full-c1 | victory-dock | 74 | 3.719 | 5.775 | 9.863 | 0 |
| A-custompaint-full-c1 | victory-result | 25 | 2.090 | 14.890 | 19.163 | 1 |
| B-lottie-full-c1 | correct | 196 | 4.646 | 7.431 | 10.529 | 0 |
| B-lottie-full-c1 | combo | 1046 | 4.313 | 7.683 | 8.859 | 1 |
| B-lottie-full-c1 | milestone | 153 | 4.787 | 7.209 | 8.203 | 0 |
| B-lottie-full-c1 | victory | 97 | 5.027 | 14.293 | 17.314 | 1 |
| B-lottie-full-c1 | victory-dock | 73 | 2.262 | 6.400 | 6.739 | 0 |
| B-lottie-full-c1 | victory-result | 23 | 5.445 | 14.615 | 17.314 | 1 |
| A-custompaint-repeat-c1 | correct | 300 | 3.131 | 7.939 | 10.784 | 1 |
| A-custompaint-repeat-c1 | combo | 1201 | 2.985 | 7.849 | 9.933 | 0 |
| A-custompaint-repeat-c1 | milestone | 159 | 3.323 | 7.241 | 7.945 | 0 |
| A-custompaint-repeat-c1 | victory | 98 | 3.358 | 13.698 | 15.154 | 1 |
| A-custompaint-repeat-c1 | victory-dock | 73 | 2.148 | 7.196 | 8.321 | 0 |
| A-custompaint-repeat-c1 | victory-result | 24 | 3.372 | 14.408 | 15.154 | 0 |
| B-lottie-repeat-c1 | correct | 199 | 3.618 | 7.433 | 14.358 | 1 |
| B-lottie-repeat-c1 | combo | 1056 | 3.172 | 8.060 | 9.225 | 0 |
| B-lottie-repeat-c1 | milestone | 159 | 4.546 | 7.422 | 8.510 | 0 |
| B-lottie-repeat-c1 | victory | 100 | 4.809 | 13.684 | 14.388 | 1 |
| B-lottie-repeat-c1 | victory-dock | 74 | 2.753 | 6.894 | 7.500 | 0 |
| B-lottie-repeat-c1 | victory-result | 25 | 4.809 | 14.194 | 14.388 | 0 |

Full combo B Raster p95 7.683/8.060; victory dock 6.400/6.894. Result window остаётся дорогим: A 14.890/14.408, B 14.615/14.194. Сам Lottie victory в dock не дал такого пика, но отсутствие всех локальных spikes **не подтверждено**. Короткие окна после idle тоже выше порога: short combo B 14.639, milestone20 10.632. Minimal: A Raster 8.315, B 10.328. В Minimal A/B одна прежняя Flutter-ветка, 0 Lottie/feedback paints, одинаковые board/card/HUD paint counts; причину числовой разницы не установили, пики не скрыты. State latency Minimal B 0.421 против A 0.474 ms. Нельзя обещать отсутствие всех лагов.

Ранее корректные серии сохранены: ab-verified (до упрощения, B повтор Raster 8.414), final-ab, acceptance-ab. Они включали screenshot на входе. После превышения убраны дублирующие echo у correct, peak ring/широкий stroke у combo и дублирующий contour у victory; core/trail/четыре sparks/фазирование сохранены. Промежуточный s3-ab оборвался из-за logcat truncation; s3-ab-fixed использовал неверный diagnostic flag, оба **исключены** из A/B. Итоговые метрики передаются base64 chunks, renderer/latency счётчики проверены.

[Итоговый JSON](lottie-device/final-clean/profile-frame-report.json), [log](lottie-device/final-clean/profile-log.txt), [отдельное A/B video](lottie-device/visual-final/ab-full-c1.mp4), [кадр combo x4](lottie-device/visual-final/frame-15.png), [contact sheet](lottie-device/final-art-sheet.png). На просмотренных кадрах слова открыты, line/HUD сохраняются, декорация помещается в зарезервированном footer. Субъективное «явно лучше» окончательно оценивает пользователь на APK. Glaxnimate import/export round-trip не проверялся.

## ПРОВЕРЕНО

Внутренние этапы выполнены последовательно с format/analyze/tests между ними. Финал: dart format ., flutter analyze без issues, **259 Flutter tests** (242 прежних +17 новых), **6 native queue regressions**, flutter build apk --debug. Проверены parsing/rendering шести фаз без pixel comparisons, cache, correct/combo/count, rapid/stale/priority, missing/invalid/render-throw fallback, Full/Calm/Minimal/reduced, HUD 20/30/60 bounds, IgnorePointer, lifecycle/dispose, реальные production gestures Full/Minimal, victory handoff/navigation. Прежние tests сохранены; три finder обращения polish Match адаптированы к wrapper без ослабления assertions. Старый HUD/journal regression поймал лишнюю подписку на TrainerScope при motion check; исправлено через уже существующий snapshot предпочтения, полный финальный набор прошёл.

Profile reproduction: `flutter build apk --profile --no-pub -t tool/match_performance_probe.dart --dart-define=MATCH_PROFILE_CONTROLS=true --dart-define=MATCH_LOTTIE_AB=true --dart-define=MATCH_PROFILE_HAPTICS=true`. Обычный review APK собирается default lib/main.dart без этих defines.

Logs: lottie-final-verified-repair-{tests,analyze,build,format}.log. [Поэтапные проверки](lottie-stage-validation.json).

Сравнение выполнено с **новым baseline начала этого блока**, а не с 470 events предыдущей задачи. Все 6 SQLite payload tables и schema совпали; shared preferences byte hashes совпали. После установки: **510 events, 9 sessions, 5 awards, 1 settings, 0 flags/custom**. Настройки сохранены (motion calm, 4 пары, timer120, sound .35, haptics/pronunciation включены). SHA256 всех **105 защищённых файлов** совпали: движок/models, progress/profile/settings/vocabulary, прежние assets/audio/icon и Android source/config. Сгенерированный build local.properties восстановлен. Старые package versions неизменны, добавлены только lottie3.6.1 / archive4.3.0 / http1.6.0 / http_parser4.1.2 / posix6.5.2.

Глобальные инструменты не обновлялись. applicationId com.wordjourney.app, версия 1.0.0+1 и debug signing certificate сохранены. HEAD неизменён; commit/staging/publication не выполнялись. Каталог не менялся: прежний контентный долг до цели 600 packs этот spike не закрывает. [Preservation proof](lottie-preservation.json).

Обычный checkpoints/word-journey-lottie-review.apk установлен на POCO через adb install -r после profile/video, **без clear/uninstall**, затем запущен lib/main.dart с реальными данными.

APK SHA256: `8a030fd80f0b00e751173b43c2440d3bd41fd174c250759034f52a45873c8d81`, 190633994 bytes. Certificate SHA256: `0535940c371a16e0818928fa971616823285bf353c7902a792b0c2ff774ab189`. [APK metadata](lottie-apk.json).

## НА ТЕЛЕФОНЕ ПРОВЕРИТЬ

Выберите Full (пользовательское значение сохранено Calm).

1. correct — check/spark, lavender→mint, слова открыты.
2. combo x2–x5 — тонкая молния/trail, динамическая подпись, без огромного flash.
3. milestone 20/30/60 — маленькая звезда/кольцо у прежнего marker.
4. victory 60/60 — мягкая энергия и результат.
5. rapid taps Full/Minimal — мгновенность выбора, отсутствие interception/застрявшей награды.

## ОСТАЛОСЬ

- Общая performance приёмка не закрыта: ≤7.5 и отсутствие локальных spikes (result/short windows/Minimal) не подтверждены. Полные Full прогоны обязательные числовые пороги прошли.
- В Glaxnimate полезно отшлифовать **combo** (trail curve/easing core) и **victory** (orbit/upward particle choreography). Текущие assets рабочие, не заглушки. Round-trip import/export ещё проверить вручную.
- Субъективный визуал и реальные пальцевые rapid taps на POCO — проверка пользователя. Commit и публикация ожидают его проверки.

STOP.
