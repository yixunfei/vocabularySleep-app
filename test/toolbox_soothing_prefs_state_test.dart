import 'package:flutter_test/flutter_test.dart';

import 'package:vocabulary_sleep_app/src/services/toolbox_soothing_prefs_service.dart';

void main() {
  group('SoothingPrefsState', () {
    test('round-trips arrangement templates and active template id', () {
      const state = SoothingPrefsState(
        favoriteModeIds: <String>{'sleep', 'study'},
        recentModeIds: <String>['sleep', 'harp'],
        lastTrackIndexByMode: <String, int>{'sleep': 2, 'harp': 1},
        lastModeId: 'sleep',
        continuePlaybackOnExit: true,
        playbackMode: SoothingPlaybackMode.arrangement,
        arrangementSteps: <SoothingPlaybackArrangementStep>[
          SoothingPlaybackArrangementStep(
            modeId: 'sleep',
            trackIndex: 2,
            repeatCount: 2,
          ),
          SoothingPlaybackArrangementStep(
            modeId: 'harp',
            trackIndex: 1,
            repeatCount: 1,
          ),
        ],
        arrangementTemplates: <SoothingPlaybackArrangementTemplate>[
          SoothingPlaybackArrangementTemplate(
            id: 'wind_down',
            name: 'Wind Down',
            steps: <SoothingPlaybackArrangementStep>[
              SoothingPlaybackArrangementStep(
                modeId: 'sleep',
                trackIndex: 2,
                repeatCount: 2,
              ),
              SoothingPlaybackArrangementStep(
                modeId: 'harp',
                trackIndex: 1,
                repeatCount: 1,
              ),
            ],
          ),
        ],
        activeArrangementTemplateId: 'wind_down',
      );

      final restored = SoothingPrefsState.fromJsonValue(state.toJson());

      expect(restored.favoriteModeIds, state.favoriteModeIds);
      expect(restored.recentModeIds, state.recentModeIds);
      expect(restored.lastTrackIndexByMode, state.lastTrackIndexByMode);
      expect(restored.lastModeId, state.lastModeId);
      expect(restored.continuePlaybackOnExit, isTrue);
      expect(restored.playbackMode, SoothingPlaybackMode.arrangement);
      expect(restored.arrangementSteps.length, 2);
      expect(restored.arrangementSteps.first.modeId, 'sleep');
      expect(restored.arrangementSteps.first.repeatCount, 2);
      expect(restored.arrangementTemplates.length, 1);
      expect(restored.arrangementTemplates.first.id, 'wind_down');
      expect(restored.arrangementTemplates.first.name, 'Wind Down');
      expect(restored.arrangementTemplates.first.steps.length, 2);
      expect(restored.activeArrangementTemplateId, 'wind_down');
    });
  });
}
