import '../../models/sleep_daily_log.dart';

/// A complete calendar window, including gaps and excluding future entries.
class SleepDayReport {
  SleepDayReport(
    Iterable<SleepDailyLog> entries, {
    required int days,
    required DateTime now,
  }) {
    final local = now.toLocal();
    final today = DateTime(local.year, local.month, local.day);
    final count = days == 14 ? 14 : 7;
    dates = List.generate(
      count,
      (index) =>
          DateTime(today.year, today.month, today.day - count + index + 1),
    );
    final byDate = <String, SleepDailyLog>{};
    for (final entry in entries) {
      final date = parseDate(entry.dateKey);
      if (date == null || date.isBefore(dates.first) || date.isAfter(today)) {
        continue;
      }
      final previous = byDate[entry.dateKey];
      final updated = entry.updatedAt ?? entry.createdAt;
      final oldUpdated = previous?.updatedAt ?? previous?.createdAt;
      if (previous == null ||
          (updated != null &&
              (oldUpdated == null || updated.isAfter(oldUpdated)))) {
        byDate[entry.dateKey] = entry;
      }
    }
    logs = dates.map((date) => byDate[dateKey(date)]).toList(growable: false);
  }

  late final List<DateTime> dates;
  late final List<SleepDailyLog?> logs;
  List<SleepDailyLog> get recordedLogs =>
      logs.whereType<SleepDailyLog>().toList();

  static String dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  static DateTime? parseDate(String key) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(key)) return null;
    final year = int.parse(key.substring(0, 4));
    final month = int.parse(key.substring(5, 7));
    final day = int.parse(key.substring(8, 10));
    final date = DateTime(year, month, day);
    return date.year == year && date.month == month && date.day == day
        ? date
        : null;
  }
}
