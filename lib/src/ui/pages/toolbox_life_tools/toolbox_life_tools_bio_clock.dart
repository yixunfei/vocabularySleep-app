part of '../toolbox_life_tools.dart';

enum _MenstrualCyclePhase { period, follicular, fertile, ovulation, luteal }

Color _menstrualPhaseColor(_MenstrualCyclePhase phase) {
  return switch (phase) {
    _MenstrualCyclePhase.period => const Color(0xFFD24B68),
    _MenstrualCyclePhase.follicular => const Color(0xFF4F9D69),
    _MenstrualCyclePhase.fertile => const Color(0xFF2F9B95),
    _MenstrualCyclePhase.ovulation => const Color(0xFFC27B25),
    _MenstrualCyclePhase.luteal => const Color(0xFF5B6FAE),
  };
}

class _BioClockToolPage extends StatefulWidget {
  const _BioClockToolPage();

  @override
  State<_BioClockToolPage> createState() => _BioClockToolPageState();
}

class _BioClockToolPageState extends State<_BioClockToolPage> {
  DateTime _lastPeriodStart = DateUtils.dateOnly(
    DateTime.now().subtract(const Duration(days: 12)),
  );
  double _cycleLength = 28;
  double _periodLength = 5;
  double _lutealLength = 14;
  late DateTime _visibleCalendarMonth;
  DateTime? _selectedCalendarDate;

  @override
  void initState() {
    super.initState();
    final today = DateUtils.dateOnly(DateTime.now());
    _visibleCalendarMonth = DateTime(today.year, today.month);
    _selectedCalendarDate = today;
  }

  @override
  Widget build(BuildContext context) {
    final forecast = _forecast();
    final phase = forecast.phase;
    return ToolboxToolPage(
      title: _lifeI18nText(context, 'toolbox.life.menstrual_cycle.title'),
      subtitle: _lifeI18nText(context, 'toolbox.life.menstrual_cycle.subtitle'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _LifeSettingsPanel(
            title: _lifeI18nText(
              context,
              'toolbox.life.menstrual_cycle.inputs',
            ),
            subtitle: _lifeI18nText(
              context,
              'toolbox.life.menstrual_cycle.inputs_subtitle',
            ),
            children: <Widget>[
              FilledButton.tonalIcon(
                onPressed: _pickLastPeriodStart,
                icon: const Icon(Icons.event_rounded),
                label: Text(
                  _lifeI18nText(
                    context,
                    'toolbox.life.menstrual_cycle.last_period',
                    params: <String, Object?>{
                      'date': _formatDate(context, _lastPeriodStart),
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _LifeSliderField(
                label: _lifeI18nText(
                  context,
                  'toolbox.life.menstrual_cycle.cycle_length',
                ),
                valueText: _daysText(context, _cycleLength.round()),
                value: _cycleLength,
                min: 21,
                max: 45,
                divisions: 24,
                onChanged: (value) => setState(() {
                  _cycleLength = value;
                  if (_periodLength >= _cycleLength) {
                    _periodLength = _cycleLength - 1;
                  }
                }),
              ),
              _LifeSliderField(
                label: _lifeI18nText(
                  context,
                  'toolbox.life.menstrual_cycle.period_length',
                ),
                valueText: _daysText(context, _periodLength.round()),
                value: _periodLength,
                min: 2,
                max: 10,
                divisions: 8,
                onChanged: (value) => setState(() => _periodLength = value),
              ),
              _LifeSliderField(
                label: _lifeI18nText(
                  context,
                  'toolbox.life.menstrual_cycle.luteal_length',
                ),
                valueText: _daysText(context, _lutealLength.round()),
                value: _lutealLength,
                min: 10,
                max: 16,
                divisions: 6,
                onChanged: (value) => setState(() => _lutealLength = value),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              ToolboxMetricCard(
                label: _lifeI18nText(
                  context,
                  'toolbox.life.menstrual_cycle.metric_phase',
                ),
                value: _phaseTitle(context, phase),
              ),
              ToolboxMetricCard(
                label: _lifeI18nText(
                  context,
                  'toolbox.life.menstrual_cycle.metric_day',
                ),
                value: _lifeI18nText(
                  context,
                  'toolbox.life.menstrual_cycle.cycle_day',
                  params: <String, Object?>{
                    'day': forecast.cycleDay,
                    'length': forecast.cycleLength,
                  },
                ),
              ),
              ToolboxMetricCard(
                label: _lifeI18nText(
                  context,
                  'toolbox.life.menstrual_cycle.metric_next',
                ),
                value: _countdownText(context, forecast.daysToNextPeriod),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildPhaseCard(context, forecast),
          const SizedBox(height: 12),
          _LifeSettingsPanel(
            title: _lifeI18nText(
              context,
              'toolbox.life.menstrual_cycle.timeline',
            ),
            subtitle: _lifeI18nText(
              context,
              'toolbox.life.menstrual_cycle.timeline_subtitle',
            ),
            children: <Widget>[
              _MenstrualCycleCalendar(
                forecast: forecast,
                visibleMonth: _visibleCalendarMonth,
                selectedDate: _selectedCalendarDate,
                phaseForDate: _phaseForDate,
                cycleDayForDate: _cycleDayForDate,
                phaseTitle: (phase) => _phaseTitle(context, phase),
                onPreviousMonth: () => setState(() {
                  _visibleCalendarMonth = DateTime(
                    _visibleCalendarMonth.year,
                    _visibleCalendarMonth.month - 1,
                  );
                }),
                onNextMonth: () => setState(() {
                  _visibleCalendarMonth = DateTime(
                    _visibleCalendarMonth.year,
                    _visibleCalendarMonth.month + 1,
                  );
                }),
                onDateSelected: (date) => setState(() {
                  _selectedCalendarDate = DateUtils.dateOnly(date);
                }),
              ),
              const SizedBox(height: 12),
              _buildSelectedDateDetails(context, forecast),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseCard(
    BuildContext context,
    _MenstrualCycleForecast forecast,
  ) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                _phaseIcon(forecast.phase),
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _phaseTitle(context, forecast.phase),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _lifeI18nText(
              context,
              _phaseBodyKey(forecast.phase),
              params: <String, Object?>{
                'day': forecast.cycleDay,
                'length': forecast.cycleLength,
              },
            ),
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 10),
          Text(
            _lifeI18nText(context, 'toolbox.life.menstrual_cycle.disclaimer'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  _MenstrualCycleForecast _forecast() {
    final today = DateUtils.dateOnly(DateTime.now());
    final cycleLength = _cycleLength.round();
    final periodLength = math.min(_periodLength.round(), cycleLength - 1);
    final lutealLength = _lutealLength.round();
    final ovulationDay = (cycleLength - lutealLength).clamp(
      periodLength + 1,
      cycleLength,
    );
    final fertileStartDay = math.max(periodLength + 1, ovulationDay - 5);
    final fertileEndDay = math.min(cycleLength, ovulationDay + 1);
    final dayOffset = today.difference(_lastPeriodStart).inDays;
    final normalizedOffset =
        ((dayOffset % cycleLength) + cycleLength) % cycleLength;
    final currentCycleStart = _lastPeriodStart.add(
      Duration(days: dayOffset - normalizedOffset),
    );
    final cycleDay = normalizedOffset + 1;
    final phase = _phaseForDay(
      cycleDay: cycleDay,
      periodLength: periodLength,
      fertileStartDay: fertileStartDay,
      fertileEndDay: fertileEndDay,
      ovulationDay: ovulationDay,
    );
    final nextPeriodStart = currentCycleStart.add(Duration(days: cycleLength));
    return _MenstrualCycleForecast(
      cycleLength: cycleLength,
      cycleDay: cycleDay,
      phase: phase,
      periodLength: periodLength,
      fertileStartDay: fertileStartDay,
      fertileEndDay: fertileEndDay,
      ovulationDay: ovulationDay,
      currentCycleStart: currentCycleStart,
      periodEnd: currentCycleStart.add(Duration(days: periodLength - 1)),
      fertileStart: currentCycleStart.add(Duration(days: fertileStartDay - 1)),
      fertileEnd: currentCycleStart.add(Duration(days: fertileEndDay - 1)),
      ovulationDate: currentCycleStart.add(Duration(days: ovulationDay - 1)),
      nextPeriodStart: nextPeriodStart,
      daysToNextPeriod: nextPeriodStart.difference(today).inDays,
    );
  }

  _MenstrualCyclePhase _phaseForDay({
    required int cycleDay,
    required int periodLength,
    required int fertileStartDay,
    required int fertileEndDay,
    required int ovulationDay,
  }) {
    if (cycleDay <= periodLength) {
      return _MenstrualCyclePhase.period;
    }
    if (cycleDay == ovulationDay) {
      return _MenstrualCyclePhase.ovulation;
    }
    if (cycleDay >= fertileStartDay && cycleDay <= fertileEndDay) {
      return _MenstrualCyclePhase.fertile;
    }
    if (cycleDay < fertileStartDay) {
      return _MenstrualCyclePhase.follicular;
    }
    return _MenstrualCyclePhase.luteal;
  }

  int _cycleDayForDate(DateTime date, _MenstrualCycleForecast forecast) {
    final dayOffset = DateUtils.dateOnly(
      date,
    ).difference(forecast.currentCycleStart).inDays;
    final normalizedOffset =
        ((dayOffset % forecast.cycleLength) + forecast.cycleLength) %
        forecast.cycleLength;
    return normalizedOffset + 1;
  }

  _MenstrualCyclePhase _phaseForDate(
    DateTime date,
    _MenstrualCycleForecast forecast,
  ) {
    return _phaseForDay(
      cycleDay: _cycleDayForDate(date, forecast),
      periodLength: forecast.periodLength,
      fertileStartDay: forecast.fertileStartDay,
      fertileEndDay: forecast.fertileEndDay,
      ovulationDay: forecast.ovulationDay,
    );
  }

  Widget _buildSelectedDateDetails(
    BuildContext context,
    _MenstrualCycleForecast forecast,
  ) {
    final theme = Theme.of(context);
    final selected =
        _selectedCalendarDate ?? DateUtils.dateOnly(DateTime.now());
    final phase = _phaseForDate(selected, forecast);
    final cycleDay = _cycleDayForDate(selected, forecast);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _phaseColor(phase).withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _phaseColor(phase).withValues(alpha: 0.32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(_phaseIcon(phase), color: _phaseColor(phase)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${_formatDate(context, selected)} · ${_phaseTitle(context, phase)}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _lifeI18nText(
              context,
              _phaseBodyKey(phase),
              params: <String, Object?>{
                'day': cycleDay,
                'length': forecast.cycleLength,
              },
            ),
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          Text(
            _lifeI18nText(context, 'toolbox.life.menstrual_cycle.daily_tips'),
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          for (final key in _phaseTipKeys(phase)) ...<Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Icon(Icons.circle, size: 6, color: _phaseColor(phase)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _lifeI18nText(context, key),
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
          ],
        ],
      ),
    );
  }

  List<String> _phaseTipKeys(_MenstrualCyclePhase phase) {
    return switch (phase) {
      _MenstrualCyclePhase.period => const <String>[
        'toolbox.life.menstrual_cycle.tip.period.energy',
        'toolbox.life.menstrual_cycle.tip.period.symptoms',
      ],
      _MenstrualCyclePhase.follicular => const <String>[
        'toolbox.life.menstrual_cycle.tip.follicular.training',
        'toolbox.life.menstrual_cycle.tip.follicular.planning',
      ],
      _MenstrualCyclePhase.fertile => const <String>[
        'toolbox.life.menstrual_cycle.tip.fertile.body_signs',
        'toolbox.life.menstrual_cycle.tip.fertile.boundary',
      ],
      _MenstrualCyclePhase.ovulation => const <String>[
        'toolbox.life.menstrual_cycle.tip.ovulation.shift',
        'toolbox.life.menstrual_cycle.tip.ovulation.care',
      ],
      _MenstrualCyclePhase.luteal => const <String>[
        'toolbox.life.menstrual_cycle.tip.luteal.sleep',
        'toolbox.life.menstrual_cycle.tip.luteal.pms',
      ],
    };
  }

  Color _phaseColor(_MenstrualCyclePhase phase) {
    return _menstrualPhaseColor(phase);
  }

  Future<void> _pickLastPeriodStart() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _lastPeriodStart.isAfter(today) ? today : _lastPeriodStart,
      firstDate: DateTime(today.year - 3, 1, 1),
      lastDate: today,
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() => _lastPeriodStart = DateUtils.dateOnly(picked));
  }

  String _phaseTitle(BuildContext context, _MenstrualCyclePhase phase) {
    return _lifeI18nText(context, _phaseTitleKey(phase));
  }

  String _phaseTitleKey(_MenstrualCyclePhase phase) {
    return switch (phase) {
      _MenstrualCyclePhase.period =>
        'toolbox.life.menstrual_cycle.phase.period',
      _MenstrualCyclePhase.follicular =>
        'toolbox.life.menstrual_cycle.phase.follicular',
      _MenstrualCyclePhase.fertile =>
        'toolbox.life.menstrual_cycle.phase.fertile',
      _MenstrualCyclePhase.ovulation =>
        'toolbox.life.menstrual_cycle.phase.ovulation',
      _MenstrualCyclePhase.luteal =>
        'toolbox.life.menstrual_cycle.phase.luteal',
    };
  }

  String _phaseBodyKey(_MenstrualCyclePhase phase) {
    return switch (phase) {
      _MenstrualCyclePhase.period =>
        'toolbox.life.menstrual_cycle.phase.period_body',
      _MenstrualCyclePhase.follicular =>
        'toolbox.life.menstrual_cycle.phase.follicular_body',
      _MenstrualCyclePhase.fertile =>
        'toolbox.life.menstrual_cycle.phase.fertile_body',
      _MenstrualCyclePhase.ovulation =>
        'toolbox.life.menstrual_cycle.phase.ovulation_body',
      _MenstrualCyclePhase.luteal =>
        'toolbox.life.menstrual_cycle.phase.luteal_body',
    };
  }

  IconData _phaseIcon(_MenstrualCyclePhase phase) {
    return switch (phase) {
      _MenstrualCyclePhase.period => Icons.water_drop_rounded,
      _MenstrualCyclePhase.follicular => Icons.local_florist_rounded,
      _MenstrualCyclePhase.fertile => Icons.spa_rounded,
      _MenstrualCyclePhase.ovulation => Icons.radio_button_checked_rounded,
      _MenstrualCyclePhase.luteal => Icons.nights_stay_rounded,
    };
  }

  String _daysText(BuildContext context, int days) {
    return _lifeI18nText(
      context,
      'toolbox.life.menstrual_cycle.days',
      params: <String, Object?>{'days': days},
    );
  }

  String _countdownText(BuildContext context, int days) {
    if (days <= 0) {
      return _lifeI18nText(context, 'toolbox.life.menstrual_cycle.today');
    }
    return _lifeI18nText(
      context,
      'toolbox.life.menstrual_cycle.countdown',
      params: <String, Object?>{'days': days},
    );
  }

  String _formatDate(BuildContext context, DateTime date) {
    return MaterialLocalizations.of(context).formatMediumDate(date);
  }
}

class _MenstrualCycleForecast {
  const _MenstrualCycleForecast({
    required this.cycleLength,
    required this.cycleDay,
    required this.phase,
    required this.periodLength,
    required this.fertileStartDay,
    required this.fertileEndDay,
    required this.ovulationDay,
    required this.currentCycleStart,
    required this.periodEnd,
    required this.fertileStart,
    required this.fertileEnd,
    required this.ovulationDate,
    required this.nextPeriodStart,
    required this.daysToNextPeriod,
  });

  final int cycleLength;
  final int cycleDay;
  final _MenstrualCyclePhase phase;
  final int periodLength;
  final int fertileStartDay;
  final int fertileEndDay;
  final int ovulationDay;
  final DateTime currentCycleStart;
  final DateTime periodEnd;
  final DateTime fertileStart;
  final DateTime fertileEnd;
  final DateTime ovulationDate;
  final DateTime nextPeriodStart;
  final int daysToNextPeriod;
}

class _MenstrualCycleCalendar extends StatelessWidget {
  const _MenstrualCycleCalendar({
    required this.forecast,
    required this.visibleMonth,
    required this.selectedDate,
    required this.phaseForDate,
    required this.cycleDayForDate,
    required this.phaseTitle,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onDateSelected,
  });

  final _MenstrualCycleForecast forecast;
  final DateTime visibleMonth;
  final DateTime? selectedDate;
  final _MenstrualCyclePhase Function(
    DateTime date,
    _MenstrualCycleForecast forecast,
  )
  phaseForDate;
  final int Function(DateTime date, _MenstrualCycleForecast forecast)
  cycleDayForDate;
  final String Function(_MenstrualCyclePhase phase) phaseTitle;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<DateTime> onDateSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = MaterialLocalizations.of(context);
    final monthStart = DateTime(visibleMonth.year, visibleMonth.month);
    final firstDayIndex = localizations.firstDayOfWeekIndex;
    final monthStartIndex = monthStart.weekday % DateTime.daysPerWeek;
    final leadingDays =
        (monthStartIndex - firstDayIndex + DateTime.daysPerWeek) %
        DateTime.daysPerWeek;
    final firstGridDate = monthStart.subtract(Duration(days: leadingDays));
    final dates = List<DateTime>.generate(
      DateTime.daysPerWeek * 6,
      (index) => firstGridDate.add(Duration(days: index)),
    );
    final weekdays = <String>[
      for (var i = 0; i < DateTime.daysPerWeek; i++)
        localizations.narrowWeekdays[(firstDayIndex + i) %
            DateTime.daysPerWeek],
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            IconButton(
              tooltip: _lifeI18nText(
                context,
                'toolbox.life.menstrual_cycle.calendar_prev_month',
              ),
              onPressed: onPreviousMonth,
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Expanded(
              child: Text(
                localizations.formatMonthYear(monthStart),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            IconButton(
              tooltip: _lifeI18nText(
                context,
                'toolbox.life.menstrual_cycle.calendar_next_month',
              ),
              onPressed: onNextMonth,
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: weekdays
              .map(
                (weekday) => Expanded(
                  child: Center(
                    child: Text(
                      weekday,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: dates.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: DateTime.daysPerWeek,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 0.82,
          ),
          itemBuilder: (context, index) {
            final date = dates[index];
            final selected = selectedDate;
            return _MenstrualCycleDayCell(
              date: date,
              inVisibleMonth: date.month == visibleMonth.month,
              selected: selected != null && DateUtils.isSameDay(selected, date),
              today: DateUtils.isSameDay(DateTime.now(), date),
              phase: phaseForDate(date, forecast),
              cycleDay: cycleDayForDate(date, forecast),
              onTap: () => onDateSelected(date),
            );
          },
        ),
        const SizedBox(height: 12),
        Text(
          _lifeI18nText(
            context,
            'toolbox.life.menstrual_cycle.calendar_legend',
          ),
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _MenstrualCyclePhase.values
              .map(
                (phase) => _MenstrualCycleLegendItem(
                  color: _menstrualPhaseColor(phase),
                  label: phaseTitle(phase),
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }
}

class _MenstrualCycleDayCell extends StatelessWidget {
  const _MenstrualCycleDayCell({
    required this.date,
    required this.inVisibleMonth,
    required this.selected,
    required this.today,
    required this.phase,
    required this.cycleDay,
    required this.onTap,
  });

  final DateTime date;
  final bool inVisibleMonth;
  final bool selected;
  final bool today;
  final _MenstrualCyclePhase phase;
  final int cycleDay;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _menstrualPhaseColor(phase);
    final textColor = inVisibleMonth
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.56);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: inVisibleMonth ? 0.18 : 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary
                  : today
                  ? color.withValues(alpha: 0.75)
                  : color.withValues(alpha: 0.18),
              width: selected ? 2 : 1,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Align(
                alignment: Alignment.topCenter,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${date.day}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: textColor,
                      fontWeight: selected || today
                          ? FontWeight.w900
                          : FontWeight.w700,
                      fontFeatures: const <ui.FontFeature>[
                        ui.FontFeature.tabularFigures(),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                width: selected ? 8 : 6,
                height: selected ? 8 : 6,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '$cycleDay',
                    maxLines: 1,
                    softWrap: false,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: textColor,
                      fontSize: 10,
                      fontFeatures: const <ui.FontFeature>[
                        ui.FontFeature.tabularFigures(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenstrualCycleLegendItem extends StatelessWidget {
  const _MenstrualCycleLegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
