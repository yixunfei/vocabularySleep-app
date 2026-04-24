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
              pickSleepText(i18n, zh: '咖啡因截止线', en: 'Caffeine cutoff'),
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                pickSleepText(i18n, zh: '计划上床时间', en: 'Planned bedtime'),
              ),
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
              title: Text(
                pickSleepText(
                  i18n,
                  zh: '我对咖啡因较敏感',
                  en: 'I am caffeine sensitive',
                ),
              ),
              value: _sensitive,
              onChanged: (value) => setState(() => _sensitive = value),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  pickSleepText(
                    i18n,
                    zh: '建议最后一杯含咖啡因饮品不晚于 ${sleepTimeOfDayLabel(cutoff)}。',
                    en: 'Suggested latest caffeine time: ${sleepTimeOfDayLabel(cutoff)}.',
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
              pickSleepText(i18n, zh: '晨光计时器', en: 'Morning light timer'),
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              pickSleepText(
                i18n,
                zh: '起床后尽快见光，先从一个短而稳的时长开始。',
                en: 'Get light soon after waking and start with a short consistent duration.',
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
                        ? pickSleepText(i18n, zh: '开始', en: 'Start')
                        : pickSleepText(i18n, zh: '暂停', en: 'Pause'),
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
                  label: Text(pickSleepText(i18n, zh: '重置', en: 'Reset')),
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
            pickSleepText(i18n, zh: '90 分钟周期规划', en: '90-minute cycle plan'),
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            pickSleepText(
              i18n,
              zh: '用完整睡眠周期辅助安排，不需要精确卡点。先固定起床、晨光和低刺激流程更重要。',
              en: 'Use full cycles as a planning aid, not a precision rule. Stable wake time, morning light, and low stimulation still matter more.',
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              pickSleepText(i18n, zh: '目标起床时间', en: 'Target wake time'),
            ),
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
            pickSleepText(i18n, zh: '预留入睡缓冲', en: 'Settle buffer'),
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
            title: pickSleepText(
              i18n,
              zh: '反推今晚关灯',
              en: 'Back-plan lights off',
            ),
            subtitle: pickSleepText(
              i18n,
              zh: '按目标起床时间倒推，优先选择你现实能做到的一档。',
              en: 'Back-plan from wake time and choose the option you can actually do.',
            ),
            options: bedtimeOptions,
            i18n: i18n,
          ),
          const SizedBox(height: 14),
          _SleepCycleSection(
            title: pickSleepText(i18n, zh: '如果现在就睡', en: 'If you sleep now'),
            subtitle: pickSleepText(
              i18n,
              zh: '适合夜里已经很累时快速看一眼，不要为了等整点继续熬。',
              en: 'Useful when you are already tired. Do not stay up just to hit a perfect time.',
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
              pickSleepText(i18n, zh: '我该离床吗', en: 'Should I leave bed'),
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _awakeLong,
              title: Text(
                pickSleepText(
                  i18n,
                  zh: '我已经清醒了一会',
                  en: 'I have been awake for a while',
                ),
              ),
              onChanged: (value) => setState(() => _awakeLong = value ?? false),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _sleepy,
              title: Text(
                pickSleepText(i18n, zh: '我现在还是困的', en: 'I still feel sleepy'),
              ),
              onChanged: (value) => setState(() => _sleepy = value ?? false),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _mindBusy,
              title: Text(
                pickSleepText(i18n, zh: '脑子很忙', en: 'My mind is busy'),
              ),
              onChanged: (value) => setState(() => _mindBusy = value ?? false),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _bodyUncomfortable,
              title: Text(
                pickSleepText(
                  i18n,
                  zh: '身体很热/紧/不舒服',
                  en: 'My body feels hot, tense, or uncomfortable',
                ),
              ),
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
      return pickSleepText(
        i18n,
        zh: '先处理热、冷、紧绷或不适，再判断要不要离床。',
        en: 'Fix heat, discomfort, or tension first, then decide whether to leave bed.',
      );
    }
    if (_awakeLong && !_sleepy) {
      return pickSleepText(
        i18n,
        zh: '更像是已经完全清醒。先离床做低刺激活动，等困意回来再回床。',
        en: 'This looks more like full wakefulness. Leave bed for a low-stimulation activity and return when sleepy.',
      );
    }
    if (_mindBusy) {
      return pickSleepText(
        i18n,
        zh: '先不要在床上继续想问题。把念头停放，回到呼吸。',
        en: 'Do not keep thinking in bed. Park the thought, then return to breathing.',
      );
    }
    return pickSleepText(
      i18n,
      zh: '如果你还困，先保持低刺激，不急着做更多事。',
      en: 'If you are still sleepy, keep things low-stim and avoid doing more.',
    );
  }
}
