enum FocusStartupTab { timer, todo }

extension FocusStartupTabX on FocusStartupTab {
  String get storageValue => name;

  int get index => switch (this) {
    FocusStartupTab.timer => 0,
    FocusStartupTab.todo => 1,
  };

  static FocusStartupTab fromStorage(String? raw) {
    final normalized = raw?.trim();
    return FocusStartupTab.values.firstWhere(
      (item) => item.storageValue == normalized,
      orElse: () => FocusStartupTab.todo,
    );
  }
}
