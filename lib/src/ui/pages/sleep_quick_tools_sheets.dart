part of 'sleep_quick_tools.dart';

class _CaffeineCutoffSheet extends ConsumerStatefulWidget {
  const _CaffeineCutoffSheet({this.initialBedtime});

  final TimeOfDay? initialBedtime;

  @override
  ConsumerState<_CaffeineCutoffSheet> createState() =>
      _CaffeineCutoffSheetState();
}

class _CaffeineCutoffSheetState extends ConsumerState<_CaffeineCutoffSheet> {
  late TimeOfDay _bedtime;
  bool _sensitive = false;

  @override
  void initState() {
    super.initState();
    _bedtime = widget.initialBedtime ?? const TimeOfDay(hour: 23, minute: 0);
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(ref.watch(appStateProvider).uiLanguage);
    final cutoffHours = _sensitive ? 10 : 8;
    final cutoff = _subtractHours(_bedtime, cutoffHours);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              i18n.t('toolbox.sleep.library.topic.caffeine.title'),
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(i18n.t('toolbox.sleep.sheets.plannedBedtime')),
              subtitle: Text(sleepTimeOfDayLabel(_bedtime)),
              trailing: const Icon(Icons.schedule_rounded),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _bedtime,
                );
                if (picked != null) {
                  setState(() => _bedtime = picked);
                }
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(i18n.t('toolbox.sleep.sheets.caffeineSensitive')),
              value: _sensitive,
              onChanged: (value) => setState(() => _sensitive = value),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  i18n.t(
                    'toolbox.sleep.sheets.caffeineSuggestion',
                    params: <String, Object?>{
                      'time': sleepTimeOfDayLabel(cutoff),
                    },
                  ),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TimeOfDay _subtractHours(TimeOfDay input, int hours) {
    final totalMinutes = input.hour * 60 + input.minute - hours * 60;
    final normalized = (totalMinutes % (24 * 60) + 24 * 60) % (24 * 60);
    return TimeOfDay(hour: normalized ~/ 60, minute: normalized % 60);
  }
}

class _MorningLightTimerSheet extends ConsumerStatefulWidget {
  const _MorningLightTimerSheet();

  @override
  ConsumerState<_MorningLightTimerSheet> createState() =>
      _MorningLightTimerSheetState();
}

class _MorningLightTimerSheetState
    extends ConsumerState<_MorningLightTimerSheet> {
  Timer? _timer;
  int _targetMinutes = 15;
  int _remainingSeconds = 15 * 60;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(ref.watch(appStateProvider).uiLanguage);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              i18n.t('toolbox.sleep.sheets.lightTimer'),
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              i18n.t(
                'toolbox.sleep.sheets.lightTimerHint',
                params: <String, Object?>{'minutes': _targetMinutes},
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              children: <int>[10, 15, 20, 30]
                  .map(
                    (minutes) => ChoiceChip(
                      label: Text('${minutes}m'),
                      selected: _targetMinutes == minutes,
                      onSelected: (_) {
                        setState(() {
                          _targetMinutes = minutes;
                          _remainingSeconds = minutes * 60;
                          _timer?.cancel();
                          _timer = null;
                        });
                      },
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 18),
            Center(
              child: Text(
                sleepSecondsLabel(_remainingSeconds, i18n: i18n),
                style: Theme.of(
                  context,
                ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                FilledButton.icon(
                  onPressed: _toggleTimer,
                  icon: Icon(
                    _timer == null
                        ? Icons.play_arrow_rounded
                        : Icons.pause_rounded,
                  ),
                  label: Text(
                    _timer == null
                        ? i18n.t('toolbox.sleep.core.start')
                        : i18n.t('toolbox.sleep.core.pause'),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _timer?.cancel();
                      _timer = null;
                      _remainingSeconds = _targetMinutes * 60;
                    });
                  },
                  icon: const Icon(Icons.replay_rounded),
                  label: Text(i18n.t('toolbox.sleep.core.cancel')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _toggleTimer() {
    if (_timer != null) {
      setState(() {
        _timer?.cancel();
        _timer = null;
      });
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() {
          _timer = null;
          _remainingSeconds = 0;
        });
        return;
      }
      setState(() => _remainingSeconds -= 1);
    });
    setState(() {});
  }
}

class _SleepCyclePlannerSheet extends ConsumerStatefulWidget {
  const _SleepCyclePlannerSheet();

  @override
  ConsumerState<_SleepCyclePlannerSheet> createState() =>
      _SleepCyclePlannerSheetState();
}

class _SleepCyclePlannerSheetState
    extends ConsumerState<_SleepCyclePlannerSheet> {
  late TimeOfDay _targetWakeTime;
  int _settleMinutes = 15;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(appStateProvider).sleepProfile;
    _targetWakeTime =
        tryParseTimeOfDay(profile?.typicalWakeTime ?? '') ??
        const TimeOfDay(hour: 7, minute: 0);
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(ref.watch(appStateProvider).uiLanguage);
    final now = DateTime.now();
    final targetWake = _nextDateTimeFor(_targetWakeTime, after: now);
    final bedtimeOptions = <int>[6, 5, 4]
        .map(
          (cycles) => _SleepCycleOption(
            cycles: cycles,
            time: targetWake.subtract(
              Duration(minutes: cycles * 90 + _settleMinutes),
            ),
          ),
        )
        .toList(growable: false);
    final wakeOptions = <int>[4, 5, 6]
        .map(
          (cycles) => _SleepCycleOption(
            cycles: cycles,
            time: now.add(Duration(minutes: cycles * 90)),
          ),
        )
        .toList(growable: false);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        shrinkWrap: true,
        children: <Widget>[
          Text(
            i18n.t('toolbox.sleep.sheets.cyclePlan'),
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(i18n.t('toolbox.sleep.sheets.cyclePlanHint')),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(i18n.t('toolbox.sleep.sheets.targetWake')),
            subtitle: Text(sleepTimeOfDayLabel(_targetWakeTime)),
            trailing: const Icon(Icons.alarm_rounded),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: _targetWakeTime,
              );
              if (picked != null) {
                setState(() => _targetWakeTime = picked);
              }
            },
          ),
          const SizedBox(height: 10),
          Text(
            i18n.t(
              'toolbox.sleep.sheets.settleBuffer',
              params: <String, Object?>{'minutes': _settleMinutes},
            ),
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <int>[0, 15, 30]
                .map(
                  (minutes) => ChoiceChip(
                    label: Text('${minutes}m'),
                    selected: _settleMinutes == minutes,
                    onSelected: (_) => setState(() => _settleMinutes = minutes),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 18),
          _SleepCycleSection(
            title: i18n.t(
              'toolbox.sleep.sheets.backPlanLightsOff',
              params: <String, Object?>{
                'time': sleepTimeOfDayLabel(_targetWakeTime),
              },
            ),
            subtitle: i18n.t('toolbox.sleep.sheets.backPlanHint'),
            options: bedtimeOptions,
            i18n: i18n,
          ),
          const SizedBox(height: 14),
          _SleepCycleSection(
            title: i18n.t('toolbox.sleep.sheets.sleepNow'),
            subtitle: i18n.t(
              'toolbox.sleep.sheets.sleepNowHint',
              params: <String, Object?>{
                'cycles': wakeOptions.first.cycles,
                'time': _sleepCycleDateTimeLabel(wakeOptions.first.time),
              },
            ),
            options: wakeOptions,
            i18n: i18n,
          ),
        ],
      ),
    );
  }

  DateTime _nextDateTimeFor(TimeOfDay time, {required DateTime after}) {
    var value = DateTime(
      after.year,
      after.month,
      after.day,
      time.hour,
      time.minute,
    );
    if (!value.isAfter(after)) {
      value = value.add(const Duration(days: 1));
    }
    return value;
  }

  String _sleepCycleDateTimeLabel(DateTime value) {
    return sleepTimeOfDayLabel(
      TimeOfDay(hour: value.hour, minute: value.minute),
    );
  }
}

class _SleepCycleOption {
  const _SleepCycleOption({required this.cycles, required this.time});

  final int cycles;
  final DateTime time;
}

class _SleepCycleSection extends StatelessWidget {
  const _SleepCycleSection({
    required this.title,
    required this.subtitle,
    required this.options,
    required this.i18n,
  });

  final String title;
  final String subtitle;
  final List<_SleepCycleOption> options;
  final AppI18n i18n;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(subtitle),
            const SizedBox(height: 12),
            ...options.map(
              (option) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 46,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: Theme.of(context).colorScheme.primaryContainer,
                      ),
                      child: Text(
                        '${option.cycles}x',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _dateTimeClockLabel(option.time),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      sleepMinutesLabel(option.cycles * 90, i18n: i18n),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _dateTimeClockLabel(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _SleepinessDecisionSheet extends ConsumerStatefulWidget {
  const _SleepinessDecisionSheet();

  @override
  ConsumerState<_SleepinessDecisionSheet> createState() =>
      _SleepinessDecisionSheetState();
}

class _SleepinessDecisionSheetState
    extends ConsumerState<_SleepinessDecisionSheet> {
  bool _awakeLong = true;
  bool _sleepy = false;
  bool _mindBusy = false;
  bool _bodyUncomfortable = false;

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(ref.watch(appStateProvider).uiLanguage);
    final recommendation = _buildRecommendation(i18n);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              i18n.t('toolbox.sleep.sheets.leaveBed'),
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _awakeLong,
              title: Text(i18n.t('toolbox.sleep.sheets.awakeAWhile')),
              onChanged: (value) => setState(() => _awakeLong = value ?? false),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _sleepy,
              title: Text(i18n.t('toolbox.sleep.sheets.stillSleepy')),
              onChanged: (value) => setState(() => _sleepy = value ?? false),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _mindBusy,
              title: Text(i18n.t('toolbox.sleep.sheets.busyMind')),
              onChanged: (value) => setState(() => _mindBusy = value ?? false),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _bodyUncomfortable,
              title: Text(i18n.t('toolbox.sleep.sheets.bodyUncomfortable')),
              onChanged: (value) =>
                  setState(() => _bodyUncomfortable = value ?? false),
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  recommendation,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildRecommendation(AppI18n i18n) {
    if (_bodyUncomfortable) {
      return i18n.t('toolbox.sleep.sheets.adviceUncomfortable');
    }
    if (_awakeLong && !_sleepy) {
      return i18n.t('toolbox.sleep.sheets.adviceAwake');
    }
    if (_mindBusy) {
      return i18n.t('toolbox.sleep.sheets.adviceBusy');
    }
    return i18n.t('toolbox.sleep.sheets.adviceSleepy');
  }
}
