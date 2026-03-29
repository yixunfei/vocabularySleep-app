import '../../../i18n/app_i18n.dart';
import '../toolbox_soothing_music_v2_copy.dart';

class SoothingMusicTrack {
  const SoothingMusicTrack({
    required this.assetPath,
    required this.labelKey,
    required this.seed,
  });

  final String assetPath;
  final String labelKey;
  final int seed;

  String label(AppI18n i18n) => SoothingMusicCopy.trackLabel(i18n, labelKey);
}

class SoothingMusicTrackCatalog {
  const SoothingMusicTrackCatalog._();

  static List<SoothingMusicTrack> tracksForMode(String modeId) {
    final labelKeys =
        SoothingMusicCopy.trackKeysByMode[modeId] ??
        const <String>['track.fallback'];
    return List<SoothingMusicTrack>.generate(labelKeys.length, (index) {
      final number = index + 1;
      final suffix = number == 1 ? '' : '$number';
      return SoothingMusicTrack(
        assetPath: 'music/$modeId$suffix.m4a',
        labelKey: labelKeys[index],
        seed: (modeId.hashCode.abs() % 97) + number * 31,
      );
    }, growable: false);
  }
}
