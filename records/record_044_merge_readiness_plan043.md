# Record 044: PLAN_043 Merge Readiness

## Basic Info
- Date: 2026-04-21
- Branch: `codex/plan024-backup`
- Goal: finalize this branch into a merge-ready, regression-verified candidate.

## Completed In This Round
1. AppState ownership split round-2
- Practice and playback domain reads/writes now use direct store ownership.
- AppState practice/playback bridge aliases were removed.
- Orchestration behavior was preserved and validated by full regression.

2. Harp layered split
- Heavy settings sheet UI was extracted from `harp.dart` into `harp_settings_sheet.dart`.
- Page file now keeps lifecycle hooks and UI entry orchestration.

3. Candidate commits and regression
- `ef849dd`:
  - `refactor: direct-store appstate ownership and split harp settings sheet`
- `e1ed273`:
  - `docs: finalize merge-readiness notes for plan043`
- Full regression:
  - Command: `flutter.bat test --reporter compact`
  - Result: all tests passed.

## Validation Summary
- Structural risk reduced:
  - practice/playback ownership boundaries are clearer.
  - harp main page file complexity was reduced.
- Behavioral risk controlled:
  - full test suite passed after the final merge-prep checkpoint.

## Remaining Non-Blocking Follow-Ups
1. `app_state.dart` is still large; continue domain extraction for sleep/wordbook/export.
2. `woodfish/zen_sand/harp` can continue state-render-config separation.
3. There are many untracked docs files in workspace; avoid blanket staging commands during merge operations.

## Merge Suggestion
1. Review and merge with focus on `ef849dd` + `f766204` + `0c302cb`.
2. Run one more CI `flutter test` gate right before mainline merge.
3. After merge, continue AppState domain ownership extraction to prevent monolith rebound.
