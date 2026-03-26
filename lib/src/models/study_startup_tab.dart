enum StudyStartupTab { play, library }

extension StudyStartupTabX on StudyStartupTab {
  String get storageValue => switch (this) {
    StudyStartupTab.play => 'play',
    StudyStartupTab.library => 'library',
  };

  static StudyStartupTab fromStorage(String? raw) {
    return switch ((raw ?? '').trim()) {
      'library' => StudyStartupTab.library,
      _ => StudyStartupTab.play,
    };
  }
}
