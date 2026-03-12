enum AppWidthTier { compact, regular, expanded }

class AppWidthBreakpoints {
  const AppWidthBreakpoints._();

  static const double compactMaxWidth = 390;
  static const double expandedMinWidth = 600;

  static AppWidthTier tierFor(double width) {
    if (width < compactMaxWidth) {
      return AppWidthTier.compact;
    }
    if (width >= expandedMinWidth) {
      return AppWidthTier.expanded;
    }
    return AppWidthTier.regular;
  }
}

extension AppWidthTierX on AppWidthTier {
  bool get isCompact => this == AppWidthTier.compact;

  bool get isRegular => this == AppWidthTier.regular;

  bool get isExpanded => this == AppWidthTier.expanded;
}
