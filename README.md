# Vocabulary Sleep (Flutter Rewrite)

This folder contains the Flutter rewrite of the original Electron app, targeting:

- Android / iOS (primary)
- Windows / macOS / Linux (desktop compatibility)

## Current migration scope

Implemented in this phase:

- Local SQLite storage (`wordbooks`, `words`, `settings`, etc.)
- Built-in wordbook seeding from bundled assets
- JSON / CSV / MDX import
- Favorites / Task special wordbooks
- Search modes (All/Word/Meaning/Fuzzy) + A-Z/prefix jump
- Word CRUD
- Test mode (hide/hint/reveal)
- Playback queue and TTS (local + SiliconFlow API)
- Ambient audio mixing (built-in assets + imported files)
- Wordbook merge workflow (source/target/delete-source)
- Legacy database import from old desktop DB file
- Offline ASR with Sherpa ONNX (Whisper base/small, auto download)
- Follow-along practice UI (record, transcribe, similarity scoring)

Still being migrated:

- Full parity of advanced appearance/theme editor

## Run

```bash
cd flutter_app
flutter pub get
flutter run
```

PowerShell helper (Windows):

```powershell
cd flutter_app
.\scripts\dev-run.ps1
```

Optional flags:

- `-Clean`: run `flutter clean` first
- `-NoPubGet`: skip `flutter pub get`
- `-NoRun`: only prepare (no `flutter run`)
- `-Device windows|chrome|edge`: choose run target
- `-RunRetry 2`: retry `flutter run` after auto cleanup when Windows file locks occur

The script now also:

- Checks `flutter`, `cmake`, and `nuget.exe` before running
- Downloads `nuget.exe` to `%USERPROFILE%\.local\bin` if missing
- Stops stale `flutter_app` process and removes stale runner artifacts before retry

## Notes

- Built-in assets are copied into `assets/ambient/` and `assets/wordbooks/`.
- Legacy migration entry is available in the top app bar (`Migrate old database`).
- Offline ASR downloads model files on first use (base/small variant).
- `.mdd` is a companion resource file and cannot be imported by itself.
- On Windows desktop, Flutter plugin build requires symlink support. Enable Developer Mode:
  - `start ms-settings:developers`
