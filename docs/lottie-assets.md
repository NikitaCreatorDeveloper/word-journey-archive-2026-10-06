# Match Lottie assets

Оригинальные векторные композиции Midnight Indigo. Lottie `3.6.1` уже закреплён в проекте; зависимости и глобальная среда не обновлялись. Новые combo/victory созданы программно, без чужих assets и ручного редактора.

| Asset | Artboard | FPS | Frames | Duration | Layers | JSON bytes | Colors / purpose |
|---|---:|---:|---:|---:|---:|---:|---|
| correct.json | 80 × 80 | 60 | 26 | 433 ms | 3 | 5391 | Lavender → mint check, маленькая дуга и три искры после правильного ответа. Сохранён без изменений. |
| combo.json | 360 × 360 | 30 | 18 | 600 ms | 4 | 10905 | Amber/pale gold молния с гранью, lavender широкий полупрозрачный stroke, четыре amber/lavender sparks, тонкое violet кольцо. |
| milestone.json | 80 × 80 | 60 | 27 | 450 ms | 3 | 3605 | Pale/lavender звезда, lavender и mint кольца у реального HUD маркера 20/30/60. Сохранён без изменений. |
| victory.json | 420 × 420 | 30 | 27 | 900 ms | 3 | 16259 | Гранёная звезда с четырьмя лучами: pale gold/amber с lavender outline, violet кольцо и семь маленьких amber/lavender частиц. |

Палитра: amber `#FFD38A`, pale core `#FFF1CD`, грань `#EDB95E`, lavender `#B6A3FF`, violet `#7864DC`, mint `#58DDC2` (correct/milestone). Свечение — обычный широкий stroke с opacity, без blur/shadows/filters.

## Timeline

Combo: frames 0–3 — opacity 0→100, scale 85→106, pseudo-glow 0→35; 3–7 — scale 106→100, sparks 0→100, ring 50→110 и opacity 45→15; 7–13 — sparks расходятся на 16 px и затухают до 35, glow до 15; 13–18 — вся композиция затухает, core scale 100→98, sparks расходятся до 23 px. Easing плавный ease-out. Текст «Отлично!» и capsule «Комбо xN» рисует Flutter в постоянном dock, отдельно от JSON.

Victory: frames 0–5 — star scale 40→110, opacity 0→100, ring scale 30→100 и opacity 0→50; 5–11 — star 110→100, ring 100→145 и исчезает, частицы появляются; 11–20 — частицы движутся наружу и немного вверх на 30–65 px, opacity 100→40; 20–27 — star scale 100→96 и вся композиция исчезает. Небольшой поворот части частиц. Декорация локальная, без полноэкранного конфетти.

## Supported features and generation

Combo/victory используют только обычные 2D shape layers: paths (`sh`), ellipses (`el`), groups (`gr`), fills (`fl`), strokes (`st`) и transforms (`tr`). Keyframes opacity/scale/position/rotation используют Bezier easing. Сохранённые correct/milestone дополнительно используют linear gradients (`gf`), trim paths (`tm`) и color keyframes. Нет images/fonts/text, masks/mattes, merge paths, expressions, plugins, 3D или nested compositions.

`python tool/build_premium_match_lottie.py` из корня проекта воспроизводит только combo/victory. `python tool/build_match_lottie.py` воспроизводит все четыре, используя тот же новый генератор для combo/victory. Ручная работа пользователя не требуется. Glaxnimate может быть необязательным редактором в будущем; его import/export здесь не проверялся.

## Playback, priority and input

`MatchFeedbackAssets` memoizes один preload Future на входе в Full/Calm Match. Четыре composition загружаются/parsing выполняется в isolate и затем переиспользуются. Загрузка, отсутствующий JSON, parse error, unavailable composition или ошибка draw не задерживают игровой ответ; используется lightweight Flutter fallback. Повторного чтения JSON при combo нет; ошибки загрузки также кешируются.

`MatchFeedbackController` хранит один reward и один HUD pulse, без FIFO. Новый small correct заменяет старый correct; каждый combo заменяет предыдущий и получает новый token. Stale completion не удаляет новое событие. Ошибка сбрасывает streak. Victory имеет высший приоритет. При Result все transient lanes прекращаются, а только оставшаяся часть victory может продолжиться независимо от уничтоженного game controller.

Все эффекты IgnorePointer/ExcludeSemantics. Reward dock сохраняет размер и не закрывает карточки. `MatchFeedbackOverlay` имеет RepaintBoundary; dock, векторная графика, подписи, карточки, timer/progress изолированы локально. Correct state и данные принимаются синхронно до audio/haptics/decorations. Нативная очередь звука сохранена; reward sound звучит на peak только актуального разрешённого combo, victory sound запускается параллельно.

Линии связи, painter/controller, события и поиск координат карточек полностью удалены. Geometry применяется только к HUD milestone. MatchingEngine сохранён побайтно. `TrainingBoard` независимо от эффектов подтверждает найденную пару через фиксированные 100 ms и публикует разрешённый движком batch атомарно; callback анимации в этом пути отсутствует. Пары на экране активны сразу, без fade/opacity input gate. Correct surface accent — 100 ms, затем matched/inactive; success bounce отсутствует. Wrong feedback — 100 ms Full, 70 ms Calm, 1 ms Minimal.

Full — четыре Lottie. Calm — correct/milestone и облегчённые combo/victory без particles, pseudo-glow и peak-ring через delegates. Minimal/reduced motion — лёгкий Flutter feedback с одним переиспользуемым controller, без сложного combo/victory и без HUD Lottie. Во всех режимах одинаковый engine и одинаковая политика board acknowledgements.

## Performance and verification

Новые композиции рисуются с собственной частотой 30 FPS на 120 Hz дисплее; correct/milestone — с 60 FPS. `SafeMatchLottie` использует публичный LottieDrawable renderer и конечный локальный cache `ui.Picture` drawing commands; записи освобождаются при resize/composition change/dispose. TickerMode/lifecycle приостанавливают playback. Никаких saveLayer для применения opacity ко всему слою. Переход Match → Result публикуется без полноэкранного FadeTransition: его alpha blending давал Raster p95 около 14 ms даже без Lottie. Прежний finish dock 620/300/1 ms и продолжение локальной victory сохранены.

Тесты проверяют parsing/rendering нескольких фаз без pixel comparison, durations/artboards/FPS, preload reuse/failures, rapid replacement x2–x5, stale callbacks, reset/victory priority, HUD 20/30/60, Full/Calm/Minimal/reduced, lifecycle/dispose, production gestures, batch input без эффектов и результата. Фактические frame timings, spikes, методика и данные POCO: `docs/fast-match-report.md`.

Performance notes по asset (окна effects включают одновременные карточки/таймер, не изолированный GPU draw):

- correct: 80×80, 3 слоя, 60 FPS. Сохранён; в итоговых Full окнах Raster p95 8.495/4.918 ms, отдельное короткое окно после простоя 10.438 ms — этот предел ещё не стабилизирован.
- combo: 360×360 artboard отображается в локальном dock 64×72 logical px; 4 слоя, 30 FPS, минимум strokes/particles. Full combo-window Raster p95 5.142/4.506 ms. Flutter caption отдельный, layout постоянный.
- milestone: локальный 56×56 HUD pulse, 3 слоя, 60 FPS. Main Full window p95 5.003/4.830 ms; отдельный milestone20 после простоя 9.666 ms со spikes. Minimal не воспроизводит Lottie pulse.
- victory: 3 слоя, 30 FPS. Dock 64×72, остаток в Result 112×112. Итоговые Full Raster p95 dock 4.704/4.697 ms, Result 4.310/4.124 ms после удаления fullscreen fade. Сложная victory выключена в production Minimal/reduced.
