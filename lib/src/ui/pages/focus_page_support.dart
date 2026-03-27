part of 'focus_page.dart';

mixin _FocusPageSupportMixin on State<FocusPage> {
  String _formatUnitSummary(int seconds, AppI18n i18n) {
    final parts = _DurationParts.fromSeconds(seconds);
    final segments = <String>[];
    if (parts.hours > 0) {
      segments.add('${parts.hours}${i18n.t('hoursUnit')}');
    }
    if (parts.minutes > 0 || segments.isNotEmpty) {
      segments.add('${parts.minutes}${i18n.t('minutesUnit')}');
    }
    segments.add('${parts.seconds}${i18n.t('secondsUnit')}');
    return segments.join(' ');
  }

  double _responsiveItemWidth(
    double maxWidth,
    AppWidthTier widthTier, {
    required int columns,
  }) {
    if (widthTier.isCompact) {
      return maxWidth;
    }
    final spacing = 12.0 * (columns - 1);
    if (widthTier.isExpanded) {
      return ((maxWidth - spacing) / columns).clamp(220.0, maxWidth).toDouble();
    }
    return ((maxWidth - 12) / 2).clamp(220.0, maxWidth).toDouble();
  }

  double _pageContentMaxWidth(AppWidthTier widthTier) {
    return switch (widthTier) {
      AppWidthTier.compact => 560.0,
      AppWidthTier.regular => 860.0,
      AppWidthTier.expanded => 980.0,
    };
  }
}

class _TodoPlanSection {
  const _TodoPlanSection({
    required this.key,
    required this.title,
    required this.icon,
    required this.items,
    this.highlight = false,
  });

  final String key;
  final String title;
  final IconData icon;
  final List<TodoItem> items;
  final bool highlight;
}

class _DurationParts {
  const _DurationParts({
    required this.hours,
    required this.minutes,
    required this.seconds,
  });

  final int hours;
  final int minutes;
  final int seconds;

  factory _DurationParts.fromSeconds(int totalSeconds) {
    final safe = totalSeconds.clamp(0, 359999);
    final duration = Duration(seconds: safe);
    return _DurationParts(
      hours: duration.inHours,
      minutes: duration.inMinutes.remainder(60),
      seconds: duration.inSeconds.remainder(60),
    );
  }

  int toSeconds() {
    final total = hours * 3600 + minutes * 60 + seconds;
    return total <= 0 ? 1 : total;
  }
}

class _StatItem {
  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;
}
