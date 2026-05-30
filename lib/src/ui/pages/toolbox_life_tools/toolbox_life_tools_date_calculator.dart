part of '../toolbox_life_tools.dart';

enum _DateCalculatorTab { difference, offset, progress, life }

class _DateCalculatorPage extends StatefulWidget {
  const _DateCalculatorPage();

  @override
  State<_DateCalculatorPage> createState() => _DateCalculatorPageState();
}

class _DateCalculatorPageState extends State<_DateCalculatorPage> {
  static final ToolboxDateCalculatorService _service =
      ToolboxDateCalculatorService();

  final TextEditingController _years = TextEditingController(text: '0.5');
  final TextEditingController _months = TextEditingController(text: '2');
  final TextEditingController _days = TextEditingController(text: '7');
  final TextEditingController _hours = TextEditingController(text: '3');
  final TextEditingController _minutes = TextEditingController(text: '15');
  final TextEditingController _seconds = TextEditingController(text: '30');
  final TextEditingController _targetLabel = TextEditingController(
    text: 'Final exam',
  );
  final TextEditingController _expectedLifeYears = TextEditingController(
    text: ToolboxDateCalculatorService.defaultExpectedLifeYears.toStringAsFixed(
      0,
    ),
  );

  late DateTime _start;
  late DateTime _end;
  late DateTime _targetStart;
  late DateTime _target;
  late DateTime _birth;
  late DateTime _now;
  Timer? _ticker;

  _DateCalculatorTab _tab = _DateCalculatorTab.difference;
  ToolboxDateMathDirection _direction = ToolboxDateMathDirection.add;

  @override
  void initState() {
    super.initState();
    final base = DateTime.now();
    _now = base;
    _start = base.subtract(const Duration(days: 1, hours: 2, minutes: 30));
    _end = base;
    _targetStart = DateTime(base.year, base.month, base.day, 8);
    _target = base.add(const Duration(days: 100, hours: 9));
    _birth = DateTime(base.year - 30, base.month, base.day, 9);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _years.dispose();
    _months.dispose();
    _days.dispose();
    _hours.dispose();
    _minutes.dispose();
    _seconds.dispose();
    _targetLabel.dispose();
    _expectedLifeYears.dispose();
    super.dispose();
  }

  ToolboxDateDifference get _difference => _service.difference(_start, _end);

  ToolboxDateOffsetResult get _offsetResult => _service.offset(
    ToolboxDateOffsetInput(
      start: _start,
      direction: _direction,
      years: _years.text,
      months: _months.text,
      days: _days.text,
      hours: _hours.text,
      minutes: _minutes.text,
      seconds: _seconds.text,
    ),
  );

  ToolboxTargetProgress get _targetProgress =>
      _service.targetProgress(start: _targetStart, target: _target, now: _now);

  ToolboxLifeCandleProgress get _lifeProgress => _service.lifeCandle(
    birth: _birth,
    expectedYears: _parsePlainNumber(_expectedLifeYears.text) == 0
        ? ToolboxDateCalculatorService.defaultExpectedLifeYears
        : _parsePlainNumber(_expectedLifeYears.text),
    now: _now,
  );

  double _parsePlainNumber(String value) {
    return double.tryParse(value.trim().replaceAll(',', '')) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final difference = _difference;
    final offsetResult = _offsetResult;
    final targetProgress = _targetProgress;
    final lifeProgress = _lifeProgress;
    return ToolboxToolPage(
      title: _lifeI18nText(
        context,
        'inline.plan295.life.date_calculator.20630c7c40d6',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.second_level_diff_multi_unit_math_pe.4ac23781e172',
      ),
      child: Column(
        key: const ValueKey<String>('life-date-calculator-page'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _DateCalculatorStage(
            tab: _tab,
            difference: difference,
            offsetResult: offsetResult,
            targetLabel: _targetLabel.text.trim().isEmpty
                ? _lifeI18nText(
                    context,
                    'inline.plan295.life.target_date.b5c47edc1dbd',
                  )
                : _targetLabel.text.trim(),
            targetProgress: targetProgress,
            lifeProgress: lifeProgress,
          ),
          const SizedBox(height: 12),
          _tabSelector(),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInQuad,
            child: switch (_tab) {
              _DateCalculatorTab.difference => _differencePanel(difference),
              _DateCalculatorTab.offset => _offsetPanel(offsetResult),
              _DateCalculatorTab.progress => _progressPanel(targetProgress),
              _DateCalculatorTab.life => _lifePanel(lifeProgress),
            },
          ),
        ],
      ),
    );
  }

  Widget _tabSelector() {
    final options = <_LifeOption<_DateCalculatorTab>>[
      const _LifeOption(
        value: _DateCalculatorTab.difference,
        labelKey: 'inline.plan295.life.diff.270701e692f0',
      ),
      const _LifeOption(
        value: _DateCalculatorTab.offset,
        labelKey: 'inline.plan295.life.add.39b10e367972',
      ),
      const _LifeOption(
        value: _DateCalculatorTab.progress,
        labelKey:
            'inline.ui.pages.toolbox_human_tests_auditory.progress_444768',
      ),
      const _LifeOption(
        value: _DateCalculatorTab.life,
        labelKey: 'inline.plan295.life.candle.f1484f322547',
      ),
    ];
    return _LifeSettingsPanel(
      title: _lifeI18nText(
        context,
        'inline.ui.pages.toolbox_human_tests_aim.mode_35c458',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.the_same_start_time_can_be_reused_ac.9d43f66d8e66',
      ),
      children: <Widget>[
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options
              .map((option) {
                return ChoiceChip(
                  selected: _tab == option.value,
                  label: Text(option.label(context)),
                  onSelected: (_) => setState(() => _tab = option.value),
                );
              })
              .toList(growable: false),
        ),
      ],
    );
  }

  Widget _differencePanel(ToolboxDateDifference difference) {
    return _LifeSettingsPanel(
      key: const ValueKey<String>('date-diff-panel'),
      title: _lifeI18nText(
        context,
        'inline.plan295.life.second_level_difference.b2cf02c928b2',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.pick_start_and_end_time_see_both_cal.c88e61ae8e4d',
      ),
      children: <Widget>[
        _DateTimePickerTile(
          label: _lifeI18nText(
            context,
            'inline.plan295.life.start_time.434d6ffe05f0',
          ),
          value: _start,
          onChanged: (value) => setState(() => _start = value),
        ),
        const SizedBox(height: 10),
        _DateTimePickerTile(
          label: _lifeI18nText(
            context,
            'inline.plan295.life.end_time.9f449c073148',
          ),
          value: _end,
          onChanged: (value) => setState(() => _end = value),
        ),
        const SizedBox(height: 14),
        _DateMetricGrid(
          children: <Widget>[
            ToolboxMetricCard(
              label: _lifeI18nText(
                context,
                'inline.plan295.life.calendar_split.8adc56c6cf2d',
              ),
              value: _formatDifferenceParts(difference),
            ),
            ToolboxMetricCard(
              label: _lifeI18nText(
                context,
                'inline.plan295.life.total_seconds.4c2ed13c57e3',
              ),
              value: _signed(difference, '${difference.totalSeconds} s'),
            ),
            ToolboxMetricCard(
              label: _lifeI18nText(
                context,
                'inline.plan295.life.total_days.7cc9b8d7254a',
              ),
              value: _signed(
                difference,
                '${difference.totalDays.toStringAsFixed(4)} d',
              ),
            ),
            ToolboxMetricCard(
              label: _lifeI18nText(
                context,
                'inline.plan295.life.approx_years.fc837ba37a46',
              ),
              value: _signed(
                difference,
                '${difference.approxYears.toStringAsFixed(6)} y',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _offsetPanel(ToolboxDateOffsetResult result) {
    final resultDiff = _service.difference(_start, result.end);
    return _LifeSettingsPanel(
      key: const ValueKey<String>('date-offset-panel'),
      title: _lifeI18nText(
        context,
        'inline.plan295.life.multi_unit_date_math.922f0aaf7217',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.years_accept_0_5_1_25_or_50_whole_ye.71634a244240',
      ),
      children: <Widget>[
        _DateTimePickerTile(
          label: _lifeI18nText(
            context,
            'inline.plan295.life.base_time.77be4f01251a',
          ),
          value: _start,
          onChanged: (value) => setState(() => _start = value),
        ),
        const SizedBox(height: 12),
        _LifeSegmentedField<ToolboxDateMathDirection>(
          label: _lifeI18nText(
            context,
            'inline.ui.pages.toolbox_daily_choice.daily_choice_modules.direction_d4bbf8',
          ),
          value: _direction,
          options: const <_LifeOption<ToolboxDateMathDirection>>[
            _LifeOption(
              value: ToolboxDateMathDirection.add,
              labelKey: 'inline.plan295.life.add.fabcfd81e721',
            ),
            _LifeOption(
              value: ToolboxDateMathDirection.subtract,
              labelKey: 'inline.plan295.life.subtract.b3155762fcf5',
            ),
          ],
          onChanged: (value) => setState(() => _direction = value),
        ),
        const SizedBox(height: 12),
        _DateFieldGrid(
          children: <Widget>[
            _numberField(
              _years,
              'life.date_calculator.field.years',
              '0.5 / 50%',
            ),
            _numberField(_months, 'life.date_calculator.field.months', '2'),
            _numberField(_days, 'life.date_calculator.field.days', '7'),
            _numberField(_hours, 'life.date_calculator.field.hours', '3'),
            _numberField(_minutes, 'life.date_calculator.field.minutes', '15'),
            _numberField(_seconds, 'life.date_calculator.field.seconds', '30'),
          ],
        ),
        const SizedBox(height: 14),
        _DateResultPanel(
          title: _lifeI18nText(
            context,
            'inline.plan295.life.result.e1843313cacb',
          ),
          value: _formatDateTime(result.end),
          subtitle: _lifeI18nText(
            context,
            'inline.plan296.ui.pages.toolbox.life.tools.toolbox.life.tools.date.calculator.actual_offset.19216c7ed2',
            params: <String, Object?>{'p0': _formatDurationCompact(resultDiff)},
          ),
        ),
      ],
    );
  }

  Widget _progressPanel(ToolboxTargetProgress targetProgress) {
    final periodItems = _service.currentPeriodProgress(_now);
    return Column(
      key: const ValueKey<String>('date-progress-panel'),
      children: <Widget>[
        _LifeSettingsPanel(
          title: _lifeI18nText(
            context,
            'inline.plan295.life.target_progress.94e804115d3a',
          ),
          subtitle: _lifeI18nText(
            context,
            'inline.plan295.life.useful_for_school_entry_graduation_e.d4c14204e313',
          ),
          children: <Widget>[
            TextField(
              controller: _targetLabel,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: _lifeI18nText(
                  context,
                  'inline.plan295.life.target_label.8c6e4236e07b',
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            _DateTimePickerTile(
              label: _lifeI18nText(
                context,
                'inline.plan295.life.start_time.434d6ffe05f0',
              ),
              value: _targetStart,
              onChanged: (value) => setState(() => _targetStart = value),
            ),
            const SizedBox(height: 10),
            _DateTimePickerTile(
              label: _lifeI18nText(
                context,
                'inline.plan295.life.target_time.fb199602506d',
              ),
              value: _target,
              onChanged: (value) => setState(() => _target = value),
            ),
            const SizedBox(height: 14),
            _TimeProgressTile(
              title: _targetLabel.text.trim().isEmpty
                  ? _lifeI18nText(
                      context,
                      'inline.plan295.life.target_date.b5c47edc1dbd',
                    )
                  : _targetLabel.text.trim(),
              subtitle: _targetStatus(targetProgress),
              progress: targetProgress.progress,
              remaining: targetProgress.remaining,
              accent: const Color(0xFF4B83A6),
              expanded: true,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _LifeSettingsPanel(
          title: _lifeI18nText(
            context,
            'inline.plan295.life.current_period_left.dbb487a745db',
          ),
          subtitle: _lifeI18nText(
            context,
            'inline.plan295.life.year_month_week_day_and_hour_update.9617ff997f2e',
          ),
          children: <Widget>[
            for (final item in periodItems.reversed)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _TimeProgressTile(
                  title: _periodLabel(item.key),
                  subtitle: _lifeI18nText(
                    context,
                    'inline.plan296.ui.pages.toolbox.life.tools.toolbox.life.tools.date.calculator.left.e9e7ca90ca',
                    params: <String, Object?>{
                      'p0': _formatDuration(item.remaining),
                    },
                  ),
                  progress: item.progress,
                  remaining: item.remaining,
                  accent: _periodColor(item.key),
                  expanded: item.key == 'year' || item.key == 'month',
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _lifePanel(ToolboxLifeCandleProgress progress) {
    return _LifeSettingsPanel(
      key: const ValueKey<String>('date-life-panel'),
      title: _lifeI18nText(
        context,
        'inline.plan295.life.life_candle.f910cc75cdfb',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.default_life_expectancy_is_79_years.8a0902435c7a',
      ),
      children: <Widget>[
        _DateTimePickerTile(
          label: _lifeI18nText(
            context,
            'inline.plan295.life.birth_time.b4755bb9debb',
          ),
          value: _birth,
          onChanged: (value) => setState(() => _birth = value),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _expectedLifeYears,
          key: const ValueKey<String>('date-life-years-field'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: _lifeI18nText(
              context,
              'inline.plan295.life.expected_life_years.611818c77016',
            ),
            helperText: _lifeI18nText(
              context,
              'inline.plan295.life.try_79_or_80_5_default_is_79_years.212c31d77546',
            ),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        _LifeCandleVisual(progress: progress),
        const SizedBox(height: 14),
        _DateMetricGrid(
          children: <Widget>[
            ToolboxMetricCard(
              label: _lifeI18nText(
                context,
                'inline.plan295.life.burned.67ea6dd11f0a',
              ),
              value: _percent(progress.burnedRatio),
            ),
            ToolboxMetricCard(
              label: _lifeI18nText(
                context,
                'inline.plan295.life.expected_end.f0d5506c3954',
              ),
              value: _formatDate(progress.expectedEnd),
            ),
            ToolboxMetricCard(
              label: _lifeI18nText(
                context,
                'inline.plan295.life.elapsed.ecf0061dfbf0',
              ),
              value: _formatDuration(progress.elapsed),
            ),
            ToolboxMetricCard(
              label: _lifeI18nText(
                context,
                'inline.plan295.life.remaining.4d5c7bf5ae9e',
              ),
              value: _formatDuration(progress.remaining),
            ),
          ],
        ),
      ],
    );
  }

  Widget _numberField(
    TextEditingController controller,
    String labelKey,
    String hint,
  ) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: _lifeI18nText(context, labelKey),
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
    );
  }

  String _periodLabel(String key) {
    return switch (key) {
      'year' => _lifeI18nText(
        context,
        'inline.plan295.life.this_year_left.e6f2d74d9d66',
      ),
      'month' => _lifeI18nText(
        context,
        'inline.plan295.life.this_month_left.00d520a15e56',
      ),
      'week' => _lifeI18nText(
        context,
        'inline.plan295.life.this_week_left.78d6668eec67',
      ),
      'day' => _lifeI18nText(
        context,
        'inline.plan295.life.today_left.758e1d7a7533',
      ),
      'hour' => _lifeI18nText(
        context,
        'inline.plan295.life.this_hour_left.4a5131becc91',
      ),
      _ => key,
    };
  }

  Color _periodColor(String key) {
    return switch (key) {
      'year' => const Color(0xFF466D77),
      'month' => const Color(0xFF6B8E5F),
      'week' => const Color(0xFFB58B42),
      'day' => const Color(0xFFB66C54),
      'hour' => const Color(0xFF7B6FB3),
      _ => Theme.of(context).colorScheme.primary,
    };
  }

  String _targetStatus(ToolboxTargetProgress progress) {
    if (progress.isComplete) {
      return _lifeI18nText(
        context,
        'inline.plan295.life.target_reached.5a1afb6862c8',
      );
    }
    if (progress.isBeforeStart) {
      return _lifeI18nText(
        context,
        'inline.plan295.life.not_started.b41198fd9a56',
      );
    }
    return _lifeI18nText(
      context,
      'inline.plan296.ui.pages.toolbox.life.tools.toolbox.life.tools.date.calculator.left.e9e7ca90ca',
      params: <String, Object?>{'p0': _formatDuration(progress.remaining)},
    );
  }

  String _signed(ToolboxDateDifference difference, String value) {
    return difference.isNegative ? '-$value' : value;
  }

  String _formatDifferenceParts(ToolboxDateDifference difference) {
    final sign = difference.isNegative ? '-' : '';
    return '$sign${difference.years}y ${difference.months}mo '
        '${difference.days}d ${difference.hours}h '
        '${difference.minutes}m ${difference.seconds}s';
  }

  String _formatDurationCompact(ToolboxDateDifference difference) {
    return _formatDifferenceParts(difference);
  }

  String _formatDateTime(DateTime value) {
    return '${_formatDate(value)} ${_two(value.hour)}:${_two(value.minute)}:${_two(value.second)}';
  }

  String _formatDate(DateTime value) {
    return '${value.year}-${_two(value.month)}-${_two(value.day)}';
  }

  String _formatTime(DateTime value) {
    return '${_two(value.hour)}:${_two(value.minute)}:${_two(value.second)}';
  }

  String _formatDuration(Duration duration) {
    final seconds = duration.inSeconds.abs();
    final days = seconds ~/ Duration.secondsPerDay;
    final hours = (seconds ~/ Duration.secondsPerHour) % Duration.hoursPerDay;
    final minutes =
        (seconds ~/ Duration.secondsPerMinute) % Duration.minutesPerHour;
    final restSeconds = seconds % Duration.secondsPerMinute;
    if (days > 0) {
      return '${days}d ${hours}h ${minutes}m ${restSeconds}s';
    }
    if (hours > 0) {
      return '${hours}h ${minutes}m ${restSeconds}s';
    }
    return '${minutes}m ${restSeconds}s';
  }

  String _two(int value) => value.toString().padLeft(2, '0');

  String _percent(double value) =>
      '${(value.clamp(0.0, 1.0) * 100).toStringAsFixed(4)}%';
}

class _DateCalculatorStage extends StatelessWidget {
  const _DateCalculatorStage({
    required this.tab,
    required this.difference,
    required this.offsetResult,
    required this.targetLabel,
    required this.targetProgress,
    required this.lifeProgress,
  });

  final _DateCalculatorTab tab;
  final ToolboxDateDifference difference;
  final ToolboxDateOffsetResult offsetResult;
  final String targetLabel;
  final ToolboxTargetProgress targetProgress;
  final ToolboxLifeCandleProgress lifeProgress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = switch (tab) {
      _DateCalculatorTab.difference => _lifeI18nText(
        context,
        'inline.plan295.life.second_level_time_distance.3214ccd8af98',
      ),
      _DateCalculatorTab.offset => _lifeI18nText(
        context,
        'inline.plan295.life.derive_from_a_base_time.8dee3f2bf0ef',
      ),
      _DateCalculatorTab.progress => targetLabel,
      _DateCalculatorTab.life => _lifeI18nText(
        context,
        'inline.plan295.life.life_candle_is_burning.e3d861014e9c',
      ),
    };
    final headline = switch (tab) {
      _DateCalculatorTab.difference =>
        '${difference.years}y ${difference.months}mo ${difference.days}d',
      _DateCalculatorTab.offset => _formatDateTime(offsetResult.end),
      _DateCalculatorTab.progress =>
        '${(targetProgress.progress * 100).toStringAsFixed(2)}%',
      _DateCalculatorTab.life =>
        '${(lifeProgress.burnedRatio * 100).toStringAsFixed(2)}%',
    };
    final supporting = switch (tab) {
      _DateCalculatorTab.difference =>
        '${difference.hours}h ${difference.minutes}m ${difference.seconds}s',
      _DateCalculatorTab.offset =>
        '${offsetResult.signedSeconds >= 0 ? '+' : ''}${offsetResult.signedSeconds}s',
      _DateCalculatorTab.progress => _formatDurationStatic(
        targetProgress.remaining,
      ),
      _DateCalculatorTab.life => _formatDurationStatic(lifeProgress.remaining),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF243E45),
            Color(0xFF456A68),
            Color(0xFFB77A4C),
          ],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF243E45).withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.22),
                  ),
                ),
                child: Text(
                  _lifeI18nText(
                    context,
                    'inline.plan295.life.date_calculator.20630c7c40d6',
                  ),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                Icons.hourglass_bottom_rounded,
                color: Colors.white.withValues(alpha: 0.82),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.86),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            headline,
            style: theme.textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            supporting,
            style: theme.textTheme.titleSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.82),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime value) {
    return '${value.year}-${_two(value.month)}-${_two(value.day)} '
        '${_two(value.hour)}:${_two(value.minute)}:${_two(value.second)}';
  }

  String _two(int value) => value.toString().padLeft(2, '0');
}

class _DateTimePickerTile extends StatelessWidget {
  const _DateTimePickerTile({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        final pickedDate = await showDatePicker(
          context: context,
          firstDate: DateTime(1900),
          lastDate: DateTime(2300),
          initialDate: value,
        );
        if (pickedDate == null || !context.mounted) {
          return;
        }
        final pickedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(value),
        );
        final resolvedTime = pickedTime ?? TimeOfDay.fromDateTime(value);
        final pickedSecond = await _pickSecond(context, value.second);
        if (pickedSecond == null) {
          return;
        }
        onChanged(
          DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            resolvedTime.hour,
            resolvedTime.minute,
            pickedSecond,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.48,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(
          children: <Widget>[
            Icon(Icons.event_rounded, color: theme.colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${value.year}-${_two(value.month)}-${_two(value.day)} '
                    '${_two(value.hour)}:${_two(value.minute)}:${_two(value.second)}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.edit_calendar_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  String _two(int value) => value.toString().padLeft(2, '0');

  Future<int?> _pickSecond(BuildContext context, int initialSecond) async {
    var selected = initialSecond.clamp(0, 59);
    return showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    _lifeI18nText(
                      context,
                      'inline.plan295.life.second.77129f7d5400',
                    ),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Slider(
                          value: selected.toDouble(),
                          min: 0,
                          max: 59,
                          divisions: 59,
                          label: selected.toString(),
                          onChanged: (value) =>
                              setModalState(() => selected = value.round()),
                        ),
                      ),
                      SizedBox(
                        width: 52,
                        child: Text(
                          selected.toString().padLeft(2, '0'),
                          textAlign: TextAlign.end,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(selected),
                      child: Text(
                        _lifeI18nText(
                          context,
                          'inline.plan295.life.done.38144b570df2',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _DateFieldGrid extends StatelessWidget {
  const _DateFieldGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 520 ? 3 : 2;
        final spacing = 10.0;
        final width =
            (constraints.maxWidth - (columns - 1) * spacing) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: children
              .map((child) => SizedBox(width: width, child: child))
              .toList(growable: false),
        );
      },
    );
  }
}

class _DateMetricGrid extends StatelessWidget {
  const _DateMetricGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 520 ? 2 : 1;
        final spacing = 10.0;
        final width =
            (constraints.maxWidth - (columns - 1) * spacing) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: children
              .map((child) => SizedBox(width: width, child: child))
              .toList(growable: false),
        );
      },
    );
  }
}

class _DateResultPanel extends StatelessWidget {
  const _DateResultPanel({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.56),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: theme.textTheme.labelLarge),
          const SizedBox(height: 4),
          SelectableText(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _TimeProgressTile extends StatelessWidget {
  const _TimeProgressTile({
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.remaining,
    required this.accent,
    required this.expanded,
  });

  final String title;
  final String subtitle;
  final double progress;
  final Duration remaining;
  final Color accent;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = (progress.clamp(0.0, 1.0) * 100).toStringAsFixed(2);
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              '$percent%',
              style: theme.textTheme.labelLarge?.copyWith(
                color: accent,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(subtitle, style: theme.textTheme.bodySmall),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 10,
            value: progress.clamp(0.0, 1.0),
            backgroundColor: accent.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(accent),
          ),
        ),
      ],
    );
    if (expanded) {
      return _progressShell(context, body);
    }
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 8),
      childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
      title: Text(title),
      subtitle: Text(subtitle),
      children: <Widget>[_progressShell(context, body)],
    );
  }

  Widget _progressShell(BuildContext context, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: child,
    );
  }
}

class _LifeCandleVisual extends StatelessWidget {
  const _LifeCandleVisual({required this.progress});

  final ToolboxLifeCandleProgress progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: const ValueKey<String>('date-life-candle'),
      height: 220,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF20251F),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFD7B56D).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 94,
            child: CustomPaint(
              painter: _LifeCandlePainter(
                burnedRatio: progress.burnedRatio,
                waxRatio: progress.waxRatio,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  _lifeI18nText(
                    context,
                    'inline.plan295.life.wax_left.a509a4d08edf',
                  ),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.72),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${(progress.waxRatio * 100).toStringAsFixed(2)}%',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _lifeI18nText(
                    context,
                    'inline.plan296.ui.pages.toolbox.life.tools.toolbox.life.tools.date.calculator.burned.5707697670',
                    params: <String, Object?>{
                      'p0': _formatDurationStatic(progress.elapsed),
                    },
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.72),
                  ),
                ),
                Text(
                  _lifeI18nText(
                    context,
                    'inline.plan296.ui.pages.toolbox.life.tools.toolbox.life.tools.date.calculator.estimated_left.c791d75a00',
                    params: <String, Object?>{
                      'p0': _formatDurationStatic(progress.remaining),
                    },
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.72),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LifeCandlePainter extends CustomPainter {
  const _LifeCandlePainter({required this.burnedRatio, required this.waxRatio});

  final double burnedRatio;
  final double waxRatio;

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final flameTop = size.height * 0.04;
    final candleTop = size.height * 0.22;
    final candleBottom = size.height * 0.95;
    final candleWidth = size.width * 0.44;
    final candleHeight = candleBottom - candleTop;
    final remainingHeight = candleHeight * waxRatio.clamp(0.0, 1.0);
    final currentTop = candleBottom - remainingHeight;

    final glowPaint = Paint()
      ..shader =
          RadialGradient(
            colors: <Color>[
              const Color(0xFFFFD06B).withValues(alpha: 0.38),
              const Color(0xFFFF8A4A).withValues(alpha: 0.0),
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(centerX, candleTop - 18),
              radius: size.width * 0.46,
            ),
          );
    canvas.drawCircle(
      Offset(centerX, candleTop - 18),
      size.width * 0.45,
      glowPaint,
    );

    final flamePath = Path()
      ..moveTo(centerX, flameTop)
      ..cubicTo(
        centerX + size.width * 0.26,
        candleTop - 20,
        centerX + size.width * 0.08,
        candleTop + 8,
        centerX,
        candleTop + 10,
      )
      ..cubicTo(
        centerX - size.width * 0.18,
        candleTop - 2,
        centerX - size.width * 0.18,
        candleTop - 26,
        centerX,
        flameTop,
      );
    canvas.drawPath(
      flamePath,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFFFFF1A6), Color(0xFFFF8B3D)],
        ).createShader(Rect.fromLTWH(0, flameTop, size.width, candleTop)),
    );

    final wickPaint = Paint()
      ..color = const Color(0xFF32251D)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(centerX, candleTop - 4),
      Offset(centerX, candleTop + 18),
      wickPaint,
    );

    final shadowRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        centerX - candleWidth / 2,
        candleTop,
        candleWidth,
        candleHeight,
      ),
      const Radius.circular(18),
    );
    canvas.drawRRect(
      shadowRect,
      Paint()..color = const Color(0xFF5D4631).withValues(alpha: 0.32),
    );

    final waxRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        centerX - candleWidth / 2,
        currentTop,
        candleWidth,
        remainingHeight,
      ),
      const Radius.circular(18),
    );
    canvas.drawRRect(
      waxRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFFFFE0A3), Color(0xFFC6864E)],
        ).createShader(waxRect.outerRect),
    );

    final burnLine = Paint()
      ..color = const Color(0xFFFFD184).withValues(alpha: 0.62)
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(centerX - candleWidth / 2 + 7, currentTop),
      Offset(centerX + candleWidth / 2 - 7, currentTop),
      burnLine,
    );

    final baseRect = Rect.fromLTWH(
      centerX - candleWidth * 0.72,
      candleBottom - 4,
      candleWidth * 1.44,
      10,
    );
    canvas.drawOval(
      baseRect,
      Paint()..color = const Color(0xFF9B704D).withValues(alpha: 0.62),
    );
  }

  @override
  bool shouldRepaint(covariant _LifeCandlePainter oldDelegate) {
    return oldDelegate.burnedRatio != burnedRatio ||
        oldDelegate.waxRatio != waxRatio;
  }
}

String _formatDurationStatic(Duration duration) {
  final seconds = duration.inSeconds.abs();
  final days = seconds ~/ Duration.secondsPerDay;
  final hours = (seconds ~/ Duration.secondsPerHour) % Duration.hoursPerDay;
  final minutes =
      (seconds ~/ Duration.secondsPerMinute) % Duration.minutesPerHour;
  final restSeconds = seconds % Duration.secondsPerMinute;
  if (days > 0) {
    return '${days}d ${hours}h ${minutes}m ${restSeconds}s';
  }
  if (hours > 0) {
    return '${hours}h ${minutes}m ${restSeconds}s';
  }
  return '${minutes}m ${restSeconds}s';
}
