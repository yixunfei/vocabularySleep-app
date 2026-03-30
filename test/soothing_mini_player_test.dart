import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vocabulary_sleep_app/src/i18n/app_i18n.dart';
import 'package:vocabulary_sleep_app/src/services/toolbox_soothing_prefs_service.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/toolbox_soothing_music/runtime_store.dart';
import 'package:vocabulary_sleep_app/src/ui/widgets/soothing_mini_player.dart';

void main() {
  group('SoothingMiniPlayer', () {
    tearDown(() {
      SoothingMusicRuntimeStore.favoriteModeIds = <String>{};
      SoothingMusicRuntimeStore.recentModeIds = <String>[];
      SoothingMusicRuntimeStore.lastTrackIndexByMode = <String, int>{};
      SoothingMusicRuntimeStore.lastModeId = null;
      SoothingMusicRuntimeStore.playbackMode = SoothingPlaybackMode.singleLoop;
      SoothingMusicRuntimeStore.arrangementSteps =
          <SoothingPlaybackArrangementStep>[];
      SoothingMusicRuntimeStore.arrangementTemplates =
          <SoothingPlaybackArrangementTemplate>[];
      SoothingMusicRuntimeStore.activeArrangementTemplateId = null;
      SoothingMusicRuntimeStore.arrangementStepIndex = 0;
      SoothingMusicRuntimeStore.arrangementStepPlayCount = 0;
      SoothingMusicRuntimeStore.retainedPlayer = null;
      SoothingMusicRuntimeStore.activeModeId = null;
      SoothingMusicRuntimeStore.activeTrackIndex = 0;
      SoothingMusicRuntimeStore.activePlaying = false;
      SoothingMusicRuntimeStore.notifyChanged();
    });

    testWidgets('shows arrangement progress badges when soothing is active', (
      tester,
    ) async {
      SoothingMusicRuntimeStore.activeModeId = 'sleep';
      SoothingMusicRuntimeStore.activeTrackIndex = 1;
      SoothingMusicRuntimeStore.activePlaying = true;
      SoothingMusicRuntimeStore.playbackMode = SoothingPlaybackMode.arrangement;
      SoothingMusicRuntimeStore.arrangementSteps =
          const <SoothingPlaybackArrangementStep>[
            SoothingPlaybackArrangementStep(
              modeId: 'sleep',
              trackIndex: 1,
              repeatCount: 2,
            ),
            SoothingPlaybackArrangementStep(
              modeId: 'harp',
              trackIndex: 0,
              repeatCount: 1,
            ),
          ];
      SoothingMusicRuntimeStore.arrangementStepIndex = 1;
      SoothingMusicRuntimeStore.notifyChanged();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SoothingMiniPlayer(
              i18n: AppI18n('en'),
              onOpen: () {},
              onTogglePlayback: () async {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Sleep'), findsOneWidget);
      expect(find.text('Midnight Haze'), findsOneWidget);
      expect(find.text('Arrangement'), findsOneWidget);
      expect(find.text('Step 2/2'), findsOneWidget);
    });
  });
}
