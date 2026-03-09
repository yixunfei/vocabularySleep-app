# ASR Follow-Along Deferred Plan (If Current Round Still Fails)

## Scope

Target issue: in follow-along mode, expected short English words (for example `able`) are still intermittently misrecognized under slow speech, delayed start, or elongated pronunciation.

Current runtime path in problematic cases:

- ASR provider: `multiEngine`
- Engine order: `offline -> localSimilarity`
- TTS provider for reference: `local` (desktop)

## What Has Been Tried

The following mitigation layers are already implemented in code:

1. Recording robustness
- Stop timeout + cancel fallback.
- Fallback recording path handling.

2. Audio preprocessing
- DC offset removal.
- High-pass filter.
- Adaptive noise gate.
- Frame-energy trimming.
- Segment scoring and preferred speech span selection.
- Slow-speech segment merge (larger inter-segment gap).

3. Multi-engine result handling
- Ignore noise transcripts (`[static]`, etc.).
- Prevent pseudo acoustic scoring when no real acoustic score is available.
- Short-word bias and no-acoustic fallback guards.

4. Offline decode fallback
- Loose second-pass decode.
- Candidate confidence comparison between strict/loose outputs.

5. Latest round (this round)
- Added quantized template alignment against expected word:
  - Quantized envelope extraction from user audio.
  - Text-derived quantized pronunciation template.
  - DTW similarity comparison of expected vs recognized template fit.
  - Force align to expected only under strict guard conditions.

## Why It Still May Fail

The core bottleneck remains:

- On desktop with `local` TTS, reliable reference waveform generation for `localSimilarity` is not guaranteed.
- Without a stable reference audio, follow-along correctness is still mostly dominated by offline text ASR output.
- Whisper-like offline decoding is not optimized for very short constrained pronunciation scoring tasks.

## Defer Decision Criteria

If after this round there are still frequent false results on short words (`3-5` letters) in user testing, pause further incremental patching and defer this track.

## Next-Phase Improvement Direction

### A. Make acoustic reference reliable first (highest priority)

1. Add a desktop-capable reference TTS backend
- Option 1: bundled lightweight TTS engine that can export WAV.
- Option 2: optional remote TTS reference generation with dedicated key/config.
- Option 3: platform-specific desktop TTS file export integration.

2. Promote real acoustic scoring to first-class signal
- If reference exists, use acoustic score as primary gate.
- If reference missing, show explicit degraded mode in UI.

### B. Replace heuristic-only short-word correction

1. Add constrained pronunciation scoring model
- Small phoneme posterior or CTC phoneme model for short-token scoring.
- Avoid pure transcript substitution logic for correctness decisions.

2. Add deterministic pronunciation benchmark set
- Curate fixed test words with variants (normal/slow/delayed/noisy).
- Track precision/recall before each tuning change.

### C. Product-level guardrails

1. Add “short-word strict mode” toggle in settings.
2. If degraded mode detected (no reference), surface recommendation:
- “Use remote reference for higher follow-along accuracy.”

## Re-open Checklist

When resuming this track:

1. Confirm available reference-TTS route on desktop.
2. Build a fixed benchmark and baseline report.
3. Re-enable iteration only against benchmark deltas, not ad-hoc tuning.
4. Keep UI messaging aligned with real scoring capability.

