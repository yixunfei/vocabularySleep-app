enum AppHomeTab { play, library, practice, focus, more }

extension AppHomeTabX on AppHomeTab {
  String get storageValue => name;

  int get index => switch (this) {
    AppHomeTab.play => 0,
    AppHomeTab.library => 1,
    AppHomeTab.practice => 2,
    AppHomeTab.focus => 3,
    AppHomeTab.more => 4,
  };

  static AppHomeTab fromStorage(String? raw) {
    final normalized = raw?.trim();
    return AppHomeTab.values.firstWhere(
      (item) => item.storageValue == normalized,
      orElse: () => AppHomeTab.play,
    );
  }

  static AppHomeTab fromIndex(int index) {
    for (final item in AppHomeTab.values) {
      if (item.index == index) {
        return item;
      }
    }
    return AppHomeTab.play;
  }
}
