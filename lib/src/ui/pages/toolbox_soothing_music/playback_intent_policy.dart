class SoothingPlaybackIntentPolicy {
  const SoothingPlaybackIntentPolicy._();

  static bool visualActive({
    required bool playing,
    required bool loading,
    required bool playbackIntent,
  }) {
    return playing || (loading && playbackIntent);
  }

  static bool shouldIgnoreTransientPause({
    required bool loading,
    required bool playbackIntent,
    required bool nextPlaying,
  }) {
    return loading && playbackIntent && !nextPlaying;
  }

  static bool resolveShouldAutoplay({
    required bool playing,
    required bool playbackIntent,
    bool? override,
  }) {
    return override ?? (playing || playbackIntent);
  }
}
