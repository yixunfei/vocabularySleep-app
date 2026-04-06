import 'package:flutter_test/flutter_test.dart';

import 'package:vocabulary_sleep_app/src/services/toolbox_soothing_prefs_service.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/toolbox_soothing_music/runtime_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Soothing runtime store', () {
    tearDown(() {
      SoothingMusicRuntimeStore.playbackMode = SoothingPlaybackMode.singleLoop;
      SoothingMusicRuntimeStore.arrangementSteps =
          <SoothingPlaybackArrangementStep>[];
      SoothingMusicRuntimeStore.arrangementStepIndex = 0;
      SoothingMusicRuntimeStore.arrangementStepPlayCount = 0;
      SoothingMusicRuntimeStore.activeModeId = null;
      SoothingMusicRuntimeStore.activeTrackIndex = 0;
      SoothingMusicRuntimeStore.activePlaying = false;
      SoothingMusicRuntimeStore.notifyChanged();
    });

    test('arrangement state resets to first step metadata when configured', () {
      SoothingMusicRuntimeStore.playbackMode = SoothingPlaybackMode.arrangement;
      SoothingMusicRuntimeStore.arrangementSteps =
          const <SoothingPlaybackArrangementStep>[
            SoothingPlaybackArrangementStep(
              modeId: 'sleep',
              trackIndex: 3,
              repeatCount: 2,
            ),
            SoothingPlaybackArrangementStep(
              modeId: 'harp',
              trackIndex: 1,
              repeatCount: 1,
            ),
          ];

      SoothingMusicRuntimeStore.arrangementStepIndex = 0;
      SoothingMusicRuntimeStore.arrangementStepPlayCount = 0;
      SoothingMusicRuntimeStore.activeModeId =
          SoothingMusicRuntimeStore.arrangementSteps.first.modeId;
      SoothingMusicRuntimeStore.activeTrackIndex =
          SoothingMusicRuntimeStore.arrangementSteps.first.trackIndex;

      expect(SoothingMusicRuntimeStore.activeModeId, 'sleep');
      expect(SoothingMusicRuntimeStore.activeTrackIndex, 3);
      expect(SoothingMusicRuntimeStore.arrangementStepIndex, 0);
      expect(SoothingMusicRuntimeStore.arrangementStepPlayCount, 0);
    });
  });
}
