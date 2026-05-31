import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';

import 'package:vocabulary_sleep_app/src/services/toolbox_breathing_audio_repository.dart';
import 'package:vocabulary_sleep_app/src/services/toolbox_breathing_catalog.dart';

void main() {
  group('ToolboxBreathingAudioRepository', () {
    test('maps required generic voice cues to uploaded S3 file names', () {
      final repo = ToolboxBreathingAudioRepository(null);
      const expected = <String, String>{
        'inhale_soft': '音效：呼吸引导/吸气.wav',
        'exhale_soft': '音效：呼吸引导/呼气.wav',
        'hold_soft': '音效：呼吸引导/屏息.wav',
        'nose_inhale': '音效：呼吸引导/鼻子吸气.wav',
        'nose_exhale': '音效：呼吸引导/鼻子呼气.wav',
        'mouth_inhale': '音效：呼吸引导/嘴吸气.wav',
        'mouth_exhale': '音效：呼吸引导/嘴呼气.wav',
        'preview_relax': '音效：呼吸引导/放松.wav',
        'preview_intro_1': '音效：呼吸引导/呼吸引导1.wav',
        'preview_intro_2': '音效：呼吸引导/呼吸引导2.wav',
        'preview_nose_slow': '音效：呼吸引导/开始用鼻子缓缓吸气.wav',
        'preview_parasym': '音效：呼吸引导/副交感交替.wav',
        'preview_altitude': '音效：呼吸引导/快速嘴吸气屏气.wav',
        'session_start': '音效：呼吸引导/breathing_session_start.wav',
        'session_complete': '音效：呼吸引导/breathing_session_complete.wav',
        'bolt_prepare': '音效：呼吸引导/breathing_bolt_prepare.wav',
        'bolt_start': '音效：呼吸引导/breathing_bolt_start.wav',
        'bolt_stop': '音效：呼吸引导/breathing_bolt_stop.wav',
        'bolt_recover': '音效：呼吸引导/breathing_bolt_recover.wav',
        'altitude_warning_short':
            '音效：呼吸引导/breathing_altitude_warning_short.wav',
      };

      for (final entry in expected.entries) {
        expect(
          repo.candidateRemoteKeysForCue(entry.key),
          contains(entry.value),
          reason: entry.key,
        );
      }
    });

    test('all scenario stage fallback cues have remote candidates', () {
      final repo = ToolboxBreathingAudioRepository(null);

      for (final scenario in BreathingExperienceCatalog.scenarios) {
        for (final stage in scenario.stages) {
          final cueId = _effectiveCueIdForStage(stage);
          if (cueId == null) {
            continue;
          }
          expect(
            repo.candidateRemoteKeysForCue(cueId),
            isNotEmpty,
            reason: '${scenario.id} ${stage.kind.name}',
          );
        }
      }
    });

    test('stage cue durations fit with mobile-friendly playback rate caps', () {
      for (final scenario in BreathingExperienceCatalog.scenarios) {
        for (final stage in scenario.stages) {
          final cueId = _effectiveCueIdForStage(stage);
          if (cueId == null) {
            continue;
          }
          final cue = BreathingExperienceCatalog.cues[cueId]!;
          final paddingMs = _cueSafetyPaddingForStage(stage).inMilliseconds;
          final targetWindowMs = math.max(
            240,
            stage.seconds * 1000 - paddingMs,
          );
          final playbackRate = (cue.approxDurationMs / targetWindowMs)
              .clamp(1.0, _maxCuePlaybackRateForStage(stage))
              .toDouble();
          final adjustedMs = (cue.approxDurationMs / playbackRate).round();

          expect(
            adjustedMs + paddingMs,
            lessThanOrEqualTo(stage.seconds * 1000),
            reason: '${scenario.id} ${stage.kind.name} uses $cueId',
          );
        }
      }
    });
  });
}

String? _effectiveCueIdForStage(BreathingStagePlan stage) {
  if (stage.kind == BreathingStageKind.rest) {
    return null;
  }
  if (stage.seconds <= 2) {
    return switch (stage.kind) {
      BreathingStageKind.inhale => 'inhale_soft',
      BreathingStageKind.exhale => 'exhale_soft',
      BreathingStageKind.hold => 'hold_soft',
      BreathingStageKind.rest => null,
    };
  }
  return stage.cueId;
}

Duration _cueSafetyPaddingForStage(BreathingStagePlan stage) {
  if (stage.seconds <= 2) {
    return Duration.zero;
  }
  if (stage.seconds <= 4) {
    return const Duration(milliseconds: 80);
  }
  return const Duration(milliseconds: 180);
}

double _maxCuePlaybackRateForStage(BreathingStagePlan stage) {
  if (stage.seconds <= 1) {
    return 1.55;
  }
  if (stage.seconds <= 2) {
    return 1.4;
  }
  return switch (stage.kind) {
    BreathingStageKind.hold => 1.25,
    BreathingStageKind.inhale => 1.35,
    BreathingStageKind.exhale => 1.35,
    BreathingStageKind.rest => 1.0,
  };
}
