import 'package:audioplayers/audioplayers.dart';

import '../../../services/toolbox_soothing_prefs_service.dart';

class SoothingMusicRuntimeStore {
  static Set<String> favoriteModeIds = <String>{};
  static List<String> recentModeIds = <String>[];
  static Map<String, int> lastTrackIndexByMode = <String, int>{};
  static String? lastModeId;
  static SoothingPlaybackMode playbackMode = SoothingPlaybackMode.singleLoop;
  static List<SoothingPlaybackArrangementStep> arrangementSteps =
      <SoothingPlaybackArrangementStep>[];
  static int arrangementStepIndex = 0;
  static int arrangementStepPlayCount = 0;
  static AudioPlayer? retainedPlayer;
  static String? activeModeId;
  static int activeTrackIndex = 0;
  static bool activePlaying = false;
  static double activeVolume = 0.62;
  static bool activeMuted = false;
  static Duration activePosition = Duration.zero;
  static Duration activeDuration = const Duration(minutes: 2);
  static bool continuePlaybackOnExit = false;
}
