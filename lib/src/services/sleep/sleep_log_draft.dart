import '../../models/sleep_daily_log.dart';

/// Sparse edits preserve facts the user has not touched.
class SleepLogDraft {
  SleepLogDraft({required String dateKey, SleepDailyLog? existing})
    : _values = existing?.toJsonMap() ?? {'date_key': dateKey};

  final Map<String, Object?> _values;
  bool changed = false;

  Object? value(String field) => _values[field];
  bool has(String field) => _values[field] != null;

  void set(String field, Object? value) {
    _values[field] = value;
    changed = true;
    if (field == 'bedtime_at' ||
        field == 'out_of_bed_at' ||
        field == 'estimated_total_sleep_minutes') {
      _values['time_in_bed_minutes'] = null;
      _values['sleep_efficiency'] = null;
    }
  }

  SleepDailyLog build() => SleepDailyLog.fromJsonValue(_values)!;

  static String appendNoteTag(String current, String tag) {
    final cleaned = current.trim();
    final addition = tag.trim();
    if (addition.isEmpty) return cleaned;
    if (cleaned.split(RegExp(r'\s*[·\n]\s*')).contains(addition)) {
      return cleaned;
    }
    return cleaned.isEmpty ? addition : '$cleaned\n$addition';
  }
}
