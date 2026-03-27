enum AppHomeTab { study, practice, focus, toolbox, more }

extension AppHomeTabX on AppHomeTab {
  String get storageValue => name;

  int get index => switch (this) {
    AppHomeTab.study => 0,
    AppHomeTab.practice => 1,
    AppHomeTab.focus => 2,
    AppHomeTab.toolbox => 3,
    AppHomeTab.more => 4,
  };

  static AppHomeTab fromStorage(String? raw) {
    final normalized = raw?.trim();
    return switch (normalized) {
      'play' || 'library' || 'study' => AppHomeTab.study,
      'practice' => AppHomeTab.practice,
      'focus' => AppHomeTab.focus,
      'toolbox' => AppHomeTab.toolbox,
      'more' => AppHomeTab.more,
      _ => AppHomeTab.focus,
    };
  }

  static AppHomeTab fromIndex(int index) {
    for (final item in AppHomeTab.values) {
      if (item.index == index) {
        return item;
      }
    }
    return AppHomeTab.focus;
  }
}
