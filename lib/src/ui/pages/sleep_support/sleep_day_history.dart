import 'package:flutter/material.dart';

import '../../../i18n/app_i18n.dart';
import '../../../models/sleep_daily_log.dart';
import '../../../models/sleep_support_session.dart';
import '../../../services/sleep/sleep_day_report.dart';
import '../sleep_assistant_ui_support.dart';

/// Uses the same calendar dates as the diary report, including empty days.
List<SleepNightEvent> sleepNightEventsInWindow(
  Iterable<SleepNightEvent> events,
  List<DateTime> dates,
) {
  if (dates.isEmpty) return const [];
  final result = events.where((event) {
    final date = SleepDayReport.parseDate(event.dateKey);
    return date != null &&
        !date.isBefore(dates.first) &&
        !date.isAfter(dates.last);
  }).toList();
  result.sort((a, b) {
    final dateOrder = b.dateKey.compareTo(a.dateKey);
    if (dateOrder != 0) return dateOrder;
    final aTime = a.startedAt ?? a.endedAt;
    final bTime = b.startedAt ?? b.endedAt;
    if (aTime == null) return bTime == null ? 0 : 1;
    return bTime == null ? -1 : bTime.compareTo(aTime);
  });
  return result;
}

class SleepDayHistory extends StatelessWidget {
  const SleepDayHistory({
    super.key,
    required this.events,
    required this.dates,
    required this.i18n,
  });

  final List<SleepNightEvent> events;
  final List<DateTime> dates;
  final AppI18n i18n;

  @override
  Widget build(BuildContext context) {
    final selected = sleepNightEventsInWindow(events, dates);
    return Card(
      child: ExpansionTile(
        key: const PageStorageKey('sleep_support_history'),
        title: Text(i18n.t('toolbox.sleep.day.history.title')),
        subtitle: Text(
          i18n.t(
            'toolbox.sleep.day.history.count',
            params: {'count': selected.length},
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(i18n.t('toolbox.sleep.day.history.support_only')),
          const SizedBox(height: 12),
          if (selected.isEmpty) Text(i18n.t('toolbox.sleep.day.history.empty')),
          for (final event in selected)
            _SleepEventTile(event: event, i18n: i18n),
        ],
      ),
    );
  }
}

class _SleepEventTile extends StatelessWidget {
  const _SleepEventTile({required this.event, required this.i18n});
  final SleepNightEvent event;
  final AppI18n i18n;

  @override
  Widget build(BuildContext context) => ExpansionTile(
    key: PageStorageKey(
      'sleep-support-event-${event.id ?? '${event.dateKey}-${event.startedAt}-${event.mode.name}'}',
    ),
    tilePadding: EdgeInsets.zero,
    childrenPadding: const EdgeInsets.only(bottom: 16),
    title: Text(
      event.intent == null
          ? sleepNightModeLabel(i18n, event.mode)
          : i18n.t(switch (event.intent!) {
              SleepSupportIntent.prepareForSleep =>
                'toolbox.sleep.night.intent.prepare',
              SleepSupportIntent.nightWaking =>
                'toolbox.sleep.night.intent.awake',
              SleepSupportIntent.distressed =>
                'toolbox.sleep.night.intent.distressed',
            }),
    ),
    subtitle: Text(
      event.startedAt == null
          ? event.dateKey
          : _timestamp(context, event.startedAt!),
    ),
    children: [
      _timeRow(context, 'toolbox.sleep.day.history.started', event.startedAt),
      _timeRow(context, 'toolbox.sleep.day.history.ended', event.endedAt),
      _leaveBedRow(context),
      _timeRow(
        context,
        'toolbox.sleep.day.history.returned',
        event.returnedToBedAt,
      ),
      if (event.fellAsleepAgainAt != null)
        _timeRow(
          context,
          'toolbox.sleep.day.history.sleep_reported',
          event.fellAsleepAgainAt,
        ),
      if ((event.actionTaken ?? '').trim().isNotEmpty)
        _textRow('toolbox.sleep.rescue.actionTaken', event.actionTaken!),
      if ((event.guessedTrigger ?? '').trim().isNotEmpty)
        _textRow('toolbox.sleep.rescue.guessedTrigger', event.guessedTrigger!),
      if ((event.notes ?? '').trim().isNotEmpty)
        _textRow('toolbox.sleep.rescue.extraNotes', event.notes!),
    ],
  );

  Widget _leaveBedRow(BuildContext context) {
    return _textRow(
      'toolbox.sleep.day.history.left',
      i18n.t(
        event.hasLeftBed == true
            ? 'toolbox.sleep.day.history.left_confirmed'
            : 'toolbox.sleep.day.unknown',
      ),
    );
  }

  Widget _timeRow(BuildContext context, String key, DateTime? time) => _textRow(
    key,
    time == null
        ? i18n.t('toolbox.sleep.day.unknown')
        : _timestamp(context, time),
  );

  Widget _textRow(String key, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Align(
      alignment: AlignmentDirectional.centerStart,
      child: Text('${i18n.t(key)}: $text'),
    ),
  );

  String _timestamp(BuildContext context, DateTime time) {
    final local = time.toLocal();
    final material = MaterialLocalizations.of(context);
    return '${material.formatShortDate(local)} '
        '${material.formatTimeOfDay(TimeOfDay.fromDateTime(local), alwaysUse24HourFormat: true)}';
  }
}
