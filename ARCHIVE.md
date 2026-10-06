# Full project preservation — 2026-10-06

This repository contains the latest Word Journey source files and the original Git commit history. The snapshot includes all current local source changes, documentation, assets, tests, and tools.

The release `full-backup-2026-10-06` contains complete copies of both local directories, including ignored files, Git metadata, all checkpoints/APKs, intermediate implementations, backups, build output, and caches:

- `word-journey-project.7z.001` (and any following numbered volumes): the complete `D:\Projects\word_journey` directory, stored under `word_journey/`.
- `word-journey-workspace.7z.001` (and any following numbered volumes): every pre-existing file in `C:\Users\TSS\Documents\ChatGPT\English words`, including its `.git/` directory. Temporary upload files are excluded.
- `SHA256SUMS.txt`: checksums for all archive volumes and file manifests.
- `project-files.jsonl` and `workspace-files.jsonl`: original file paths, byte lengths, modification times, and SHA-256 hashes.

To restore, download every numbered volume for an archive into one folder, then open its `.001` file with 7-Zip and extract it. All volumes must be present. The source repository can also be cloned independently.

The full archives may contain personal application data and local machine paths. This repository is public, including the full backup release.
