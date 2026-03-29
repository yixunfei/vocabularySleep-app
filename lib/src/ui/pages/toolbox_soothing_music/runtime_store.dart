import 'package:audioplayers/audioplayers.dart';

class SoothingMusicRuntimeStore {
  static Set<String> favoriteModeIds = <String>{};
  static List<String> recentModeIds = <String>[];
  static Map<String, int> lastTrackIndexByMode = <String, int>{};
  static String? lastModeId;
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
