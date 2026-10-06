# Word Journey

## Скачать APK и установить

[Скачать Word Journey для Android — APK (около 191 МБ)](https://github.com/NikitaCreatorDeveloper/word-journey-archive-2026-10-06/releases/download/full-backup-2026-10-06/word-journey.apk)

[Инструкция по установке на русском](https://github.com/NikitaCreatorDeveloper/word-journey-archive-2026-10-06/blob/main/INSTALL.md)

Android 7.0 и новее. Последняя сохранённая тестовая сборка, версия 1.0.0.

Personal offline vocabulary trainer: Categories, Review, Progress.
Travel/maps/routes have been retired. Match retains one paired-card engine.
See docs/personal-trainer-plan.md and docs/personal-trainer-report.md.
Airy upgrade: 1520 unique concepts, 91 packs of 20 concepts, 12 categories.
The 600-pack target remains incomplete (509 packs missing). See
docs/airy-upgrade-report.md, docs/catalog-coverage.md and docs/content-editorial-audit.md.
Application ID: com.wordjourney.app. No publishing or commit before acceptance.

Premium Midnight Indigo redesign: Categories, Review, Progress and Match.
See docs/indigo-redesign-report.md for validation, POCO frame timings, data
preservation and remaining manual checks. Review APK:
checkpoints/word-journey-indigo-review.apk.

Indigo final visual polish: docs/indigo-final-polish-report.md.
Latest review APK: checkpoints/word-journey-indigo-polish-review.apk.
Installed on POCO without clearing learner data; 237 tests passed.
Full-screen Match raster p95 9.48–9.70 ms; the 6–7 ms target is not yet achieved.

Match performance fix: docs/match-performance-report.md.
Latest review APK: checkpoints/word-journey-match-performance-review.apk.
242 Flutter tests + 6 native queue regressions passed. Full C1/5 pairs at 120 Hz,
sounds/haptics enabled: UI p95 3.897–4.383 ms, raster p95 7.800–7.928 ms.
Data/settings preserved; ordinary debug APK restored on POCO.
Preferred 6–7 ms raster target and consistent <8 ms in all short windows remain unachieved.

Match Lottie feedback spike: docs/lottie-assets.md and docs/lottie-spike-report.md.
Previous Lottie spike APK: checkpoints/word-journey-lottie-review.apk.
Original correct/combo/milestone/victory vectors, preload, bounded feedback controller,
Full/Calm/Minimal and local error fallback. No commit or publication before review.

FAST MATCH + PREMIUM PROGRAMMATIC LOTTIE: docs/fast-match-report.md.
Latest review APK: checkpoints/word-journey-fast-match-review.apk.
Removed connection runtime; independent100ms acknowledgements; 30FPS combo/victory.
Full C1/5 pairs/120Hz: UI p95 2.593–4.172ms; Raster p95 4.525–5.195ms.
260 Flutter +6 native tests passed; data preserved; no commit/publication.
