import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../i18n/app_i18n.dart';
import '../../../state/app_state.dart';
import '../sleep_assistant_ui_support.dart';
import '../sleep_quick_tools.dart';
import '../toolbox_mind_tools.dart';
import '../toolbox_soothing_music_v2_page.dart';

class SleepRoutineToolsPanel extends StatelessWidget {
  const SleepRoutineToolsPanel({super.key, required this.i18n});

  final AppI18n i18n;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _tool(
          'toolbox.sleep.winddown.whiteNoise',
          Icons.graphic_eq_rounded,
          () => showSleepWhiteNoiseSheet(context),
        ),
        _tool(
          'toolbox.sleep.winddown.caffeineCutoff',
          Icons.local_cafe_outlined,
          () => showCaffeineCutoffCalculatorSheet(context),
        ),
        _tool(
          'toolbox.sleep.winddown.cycle90min',
          Icons.more_time_rounded,
          () => showSleepCyclePlannerSheet(context),
        ),
        _tool(
          'toolbox.sleep.winddown.bedReminder',
          Icons.notifications_outlined,
          () => _createReminder(context, wakeAlarm: false),
        ),
        _tool(
          'toolbox.sleep.winddown.wakeAlarm',
          Icons.alarm_rounded,
          () => _createReminder(context, wakeAlarm: true),
        ),
        _tool(
          'toolbox.sleep.winddown.breathing',
          Icons.air_rounded,
          () => _open(context, const BreathingToolPage()),
        ),
        _tool(
          'toolbox.sleep.winddown.soothingAudio',
          Icons.spa_outlined,
          () => _open(context, const SoothingMusicV2Page()),
        ),
      ],
    );
  }

  Widget _tool(String key, IconData icon, VoidCallback action) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          padding: const EdgeInsets.all(12),
        ),
        onPressed: action,
        icon: Icon(icon),
        label: Text(i18n.t(key), textAlign: TextAlign.center),
      ),
    );
  }

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  Future<void> _createReminder(
    BuildContext context, {
    required bool wakeAlarm,
  }) async {
    final appState = context.read<AppState>();
    final focus = appState.focusService;
    if (!focus.initialized) {
      await focus.init();
    }
    final permissionGranted = await focus
        .requestTodoReminderNotificationPermission();
    if (!context.mounted) return;
    final profile = appState.sleepProfile;
    final fallback = wakeAlarm
        ? const TimeOfDay(hour: 7, minute: 0)
        : const TimeOfDay(hour: 22, minute: 30);
    final time =
        tryParseTimeOfDay(
          wakeAlarm
              ? profile?.typicalWakeTime ?? ''
              : profile?.typicalBedtime ?? '',
        ) ??
        fallback;
    final now = DateTime.now();
    var dueAt = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    ).subtract(wakeAlarm ? Duration.zero : const Duration(minutes: 30));
    if (!dueAt.isAfter(now)) dueAt = dueAt.add(const Duration(days: 1));
    final created = focus.addTodo(
      i18n.t(
        wakeAlarm
            ? 'toolbox.sleep.winddown.wakeGetLight'
            : 'toolbox.sleep.winddown.startWindDown',
      ),
      category: 'sleep',
      note: i18n.t(
        wakeAlarm
            ? 'toolbox.sleep.winddown.reminderMorning'
            : 'toolbox.sleep.winddown.reminderEvening',
      ),
      dueAt: dueAt,
      alarmEnabled: true,
      syncToSystemCalendar: true,
      systemCalendarNotificationEnabled: !wakeAlarm,
      systemCalendarAlarmEnabled: wakeAlarm,
      systemCalendarNotificationMinutesBefore: 0,
      systemCalendarAlarmMinutesBefore: 0,
    );
    if (!created) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(i18n.t('toolbox.sleep.winddown.reminderUnavailable')),
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          i18n.t(
            permissionGranted
                ? (wakeAlarm
                      ? 'toolbox.sleep.winddown.reminderWakeCreated'
                      : 'toolbox.sleep.winddown.reminderBedCreated')
                : 'toolbox.sleep.winddown.reminderPermissionMissing',
          ),
        ),
      ),
    );
  }
}
