# FAST MATCH + PREMIUM PROGRAMMATIC LOTTIE — review

02.10.2026. Реальная доработка `D:/Projects/word_journey`, обычный debug APK установлен на POCO поверх приложения. Финального commit и публикации нет. Глобальные инструменты, зависимости, applicationId и launcher icon сохранены.

## СДЕЛАНО

Полностью удалены word_connection_overlay.dart и match_visual_feedback.dart, connection painter/controllers/events/callbacks, anchors и RenderBox/GlobalKey lookup карточек. В active Match и probe нет runtime линии; в MatchingEngine термин connection относится только к распределению слов и сохранён вместе со всем движком побайтно.

Correct state, progress и журнал ответа принимаются до запуска sound/haptic/effects. Accent surface/border — 100 ms, затем matched/inactive; success bounce отсутствует. TrainingBoard подтверждает пару по отдельному фиксированному таймеру 100 ms, независимо от animation/controller/ticker/geometry. Engine разрешает atomic batch, UI публикует его сразу; входящие слова сразу принимают input, без exit/entry fade и opacity gates. Активные/held/selected карточки сохраняют свои позиции/keys. Эффекты не являются prerequisite обновления.

Самостоятельно созданы оригинальные combo.json (360×360, 30 FPS, 18 frames/600 ms) и victory.json (420×420, 30 FPS, 27 frames/900 ms). Молния, гранёная звезда, тонкие strokes/ring и 4/7 vector particles; никакой ручной работы пользователя, чужих assets, blur, raster, expressions или plugins. correct/milestone сохранены. Генератор воспроизводит все четыре JSON побайтно; проверены parser/render нескольких фаз без pixel test. Контрольный рендер: `docs/art-review/premium-contact-sheet.png`.

Preload memoized один раз; compositions переиспользуются. Reward/milestone mailbox bounded, без FIFO; каждый combo заменяет предыдущий, stale callbacks защищены tokens, error сбрасывает combo, victory имеет высший приоритет. Result прекращает transient lanes, продолжает только нужную остаточную victory. RepaintBoundary изолируют overlay, dock, artwork/caption, cards/HUD/timer/background. Full/Calm/Minimal/reduced и lightweight fallback сохранены. Нативная bounded audio queue не менялась; sound/haptic идут после state update, актуальный reward sound — на peak.

Профиль обнаружил fullscreen FadeTransition на Result: alpha blending давал Raster p95 около 14–15 ms и с Lottie, и без неё. Переход теперь публикует Result без fullscreen fade, сохраняя finish dock 620/300/1 ms и оставшуюся локальную victory. Отдельная lifecycle regression гарантирует: board может завершить acknowledgement в фоне, но новые слова не записываются как встреченные до возврата; при возврате учитываются ровно один раз.

## PERFORMANCE BEFORE

Свежий baseline именно начала этого блока, production Lottie с прежними линиями. Full UI p95 **3.477–4.573 ms**, Raster p95 **8.072–8.079 ms**.

| Scenario | Frames | UI p50/p95 ms | Raster p50/p95 ms | >8.33 ms | >16.67 ms |
|---|---:|---:|---:|---:|---:|
| B-lottie-full-c1 | 1387 | 1.375 / 4.573 | 5.267 / 8.072 | 59 | 0 |
| B-lottie-repeat-c1 | 1390 | 1.406 / 3.477 | 5.920 / 8.079 | 57 | 2 |

## PERFORMANCE AFTER

Окончательный код, два Full прогона: UI p95 **2.593–4.172 ms**, Raster p95 **4.525–5.195 ms**. Обязательные пределы UI<8 / Raster<8.3 выполнены в обоих основных Full сценариях. Желаемые UI<5 / Raster<7.5 также выполнены в обоих основных Full прогонах.

| Scenario | Frames | UI p50/p95 ms | Raster p50/p95 ms | >8.33 ms | >16.67 ms |
|---|---:|---:|---:|---:|---:|
| B-lottie-full-c1 | 1376 | 1.470 / 4.172 | 3.400 / 5.195 | 32 | 2 |
| B-lottie-repeat-c1 | 1418 | 0.795 / 2.593 | 3.523 / 4.525 | 5 | 1 |
| B-lottie-calm-c1 | 1350 | 0.736 / 2.786 | 3.579 / 4.723 | 6 | 1 |
| B-lottie-minimal-c1 | 1217 | 0.318 / 2.388 | 3.795 / 5.651 | 17 | 3 |

Счётчики frames >8.33/>16.67 используют max(buildDuration,rasterDuration) и отражают превышение бюджета 120 Hz, а не прямую телеметрию пропущенных presentation frames SurfaceFlinger. Редкие spikes приведены без исключения кадров.

| Full scenario | Tap→state p95 ms | Tap→post-frame p95 ms | Accepted taps | Card paints | Lottie paints | HUD builds | Background paints |
|---|---:|---:|---:|---:|---:|---:|---:|
| B-lottie-full-c1 | 0.235 | 21.111 | 126 | 531 | 475 | 1 | 1 |
| B-lottie-repeat-c1 | 0.117 | 10.237 | 126 | 537 | 464 | 1 | 1 |

Время Tap→state измеряет принятый production callback, не physical touch-to-photon. Tap→post-frame — завершение Flutter frame callback, не фактическую презентацию дисплея. Реальные pointer gestures проверены Flutter tests; субъективный отклик физического пальца остаётся пользовательской проверкой.

| Full effect window | UI p95 ms (run/repeat) | Raster p95 ms (run/repeat) |
|---|---:|---:|
| correct | 4.444 / 2.514 | 8.495 / 4.918 |
| combo | 4.332 / 2.614 | 5.142 / 4.506 |
| milestone | 4.016 / 3.159 | 5.003 / 4.830 |
| victory-dock | 3.911 / 2.069 | 4.704 / 4.697 |
| victory-result | 2.576 / 1.129 | 4.310 / 4.124 |

Дополнительные короткие окна после простоя (это отдельные сценарии, вне основного 60-match burst):

| Scenario | Frames | UI p50/p95 ms | Raster p50/p95 ms | >8.33 ms | >16.67 ms |
|---|---:|---:|---:|---:|---:|
| idle-match-c1 | 5 | 1.461 / 1.647 | 4.343 / 4.731 | 0 | 0 |
| correct-card-c1 | 54 | 0.851 / 1.962 | 3.671 / 10.438 | 3 | 1 |
| combo-lightning-c1 | 72 | 0.692 / 1.536 | 3.878 / 7.954 | 3 | 1 |
| batch-refill-c1 | 84 | 0.731 / 1.630 | 3.836 / 7.220 | 4 | 1 |
| milestone-20-c1 | 71 | 0.878 / 1.655 | 3.725 / 9.666 | 4 | 2 |

Честное ограничение: короткие окна выше обязательного бюджета: correct-card-c1, milestone-20-c1. Общая цель основного Full сценария выполнена; абсолютное отсутствие единичных spikes и одинаковый первый кадр после простоя не подтверждены.

## Методика

POCO X4 Pro 5G / 2201116PG / Android 13 / serial 2aa7666ff377, 1080×2400, density440, font scale1, physical120.00001Hz (dumpsys display до/после/при завершении сценариев). C1, 5 pairs, Random(26), pool20, target60, 3 mistakes на 7/23/41, cadence170ms, combo x2–x5 и дальше, milestones20/30/60, batch replacement, victory и Result; sounds+haptics включены. 1800ms warmup +300ms label delay; после60 ещё1150ms включены в sample. Все samples измеряются FrameTiming в profile, без видео и screencap в benchmark. Backend comparison A использует сохранённый lightweight Flutter renderer, B — текущий Lottie; главный BEFORE/AFTER сравнивает B.

Probe использует настоящий TrainingGameScreen/TrainingWordCard.onPressed, проверяет IgnorePointer ancestors и fresh MemoryTrainerStore на сценарий. Он не инжектирует ADB input и не пишет learner database. Это воспроизводимый callback workload; он не заменяет ручную проверку multitouch/physical taps. Отдельная видеозапись visual-final исключена из acceptance timings.

Воспроизведение: `flutter build apk --profile --no-pub -t tool/match_performance_probe.dart --dart-define=MATCH_PROFILE_CONTROLS=true --dart-define=MATCH_LOTTIE_AB=true --dart-define=MATCH_PROFILE_HAPTICS=true`. Обычный review APK — default lib/main.dart, без диагностических defines. После профиля он снова установлен через `adb install -r`.

Raw доказательства: `docs/fast-device/before-clean/profile-frame-report.json` и `docs/fast-device/review-clean/profile-frame-report.json`; промежуточные after-clean/final-clean сохранены; display dumps/profile logs рядом. Build/analyze/tests: docs/fast-s1-pass-*, fast-s2-final-*, fast-s3-*, fast-s4-lifecycle-*; native queue: docs/fast-native-tests.log. Документация: docs/lottie-assets.md.

## ПРОВЕРЕНО

Обычный APK после профиля снова установлен и открыт; снимок без PROFILE banner: `docs/fast-device/ordinary-review-installed.png`. Проверка подписи: `docs/fast-apk-signature.txt`.

Последовательные этапы с format/analyze/tests между ними. Финал: dart format ., flutter analyze — no issues; **260 Flutter tests**, **6 native audio queue regressions**, debug build. Tests сохранены за исключением трёх line-only cases; связанные combo/error/minimal/audio tests переписаны для новой презентации. Старые fade/bounce assertions заменены соответствующими 100ms/input-ready/inactive assertions, с сохранением stale/held/timeout/state/navigation invariants. Новые regressions: board без decoration/tickers/geometry; rapid combo replacement x2–x5, stale finish, preload once, transient cleanup и visibility-aware exposure при pause/resume. Missing/invalid/render errors, Full/Calm/Minimal/reduced, HUD20/30/60, lifecycle/dispose и реальный production tap flow также зелёные.

Data preservation: {"protectedFilesIdentical": 109, "intentionalNativeAudioChanges": {}, "HEADUnchanged": "f8962c87bee8caafdda6ad0930d21ee3ca7dbac3", "catalogSHA256": "89b67ecea52a490c96c00479f652ca0baf64be0119b79ef597c2e8b879048a21", "phoneTablesIdentical": {"settings": true, "events": true, "sessions": true, "flags": true, "awards": true, "custom": true}, "schemaIdentical": true, "phoneRowCounts": {"settings": 1, "events": 563, "sessions": 10, "flags": 0, "awards": 5, "custom": 0}, "sharedPreferencesIdentical": true}

Обычный review APK: `checkpoints/word-journey-fast-match-review.apk`, 190633994 bytes, SHA256 `c7c6565e72e0ec7482aca42854673186e0c8ab3e8200c0a0ddbd5466523d3c39`. applicationId `com.wordjourney.app`, version1.0.0+1. Прежняя подпись SHA256 `0535940c371a16e0818928fa971616823285bf353c7902a792b0c2ff774ab189`. HEAD `f8962c87bee8caafdda6ad0930d21ee3ca7dbac3` не менялся; существующие незакоммиченные изменения сохранены.

## НА ТЕЛЕФОНЕ ПРОВЕРИТЬ

1. Rapid taps, особенно сразу после batch refresh.
2. Combo x2–x5 и сброс после ошибки.
3. Milestone20/30/60.
4. Victory60/60 и переход Result.
5. Full / Minimal, а также ощущение первого ответа после простоя.

STOP. Финальный commit и публикация не выполнялись.
