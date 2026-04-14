import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/module_system/module_id.dart';
import '../../i18n/app_i18n.dart';
import '../../models/sleep_daily_log.dart';
import '../../state/app_state.dart';
import '../module/module_access.dart';
import '../widgets/setting_tile.dart';
import 'sleep_assistant_ui_support.dart';
import 'sleep_quick_tools.dart';
import 'sleep_research_library.dart';
import 'toolbox_tool_shell.dart';

class SleepDailyLogPage extends StatefulWidget {
  const SleepDailyLogPage({super.key});

  @override
  State<SleepDailyLogPage> createState() => _SleepDailyLogPageState();
}

class _SleepDailyLogPageState extends State<SleepDailyLogPage> {
  late String _dateKey;
  late final TextEditingController _sleepMinutesController;
  late final TextEditingController _latencyController;
  late final TextEditingController _wakeCountController;
  late final TextEditingController _wakeMinutesController;
  late final TextEditingController _napMinutesController;
  late final TextEditingController _windDownMinutesController;
  late final TextEditingController _notesController;

  TimeOfDay? _bedtime;
  TimeOfDay? _lightsOff;
  TimeOfDay? _sleepOnset;
  TimeOfDay? _finalWake;
  TimeOfDay? _outOfBed;
  double _morningEnergy = 3;
  double _daytimeSleepiness = 3;
  double _stressPeakLevel = 2;
  double _worryLoadLevel = 2;
  bool _caffeineAfterCutoff = false;
  bool _alcoholAtNight = false;
  bool _lateScreenExposure = false;
  bool _morningLightDone = false;
  bool _heavyDinner = false;
  bool _intenseExerciseLate = false;
  bool _hotBathDone = false;
  bool _stretchingDone = false;
  bool _whiteNoiseUsed = false;
  bool _bedroomTooHot = false;
  bool _bedroomTooBright = false;
  bool _bedroomTooNoisy = false;
  bool _clockChecking = false;

  @override
  void initState() {
    super.initState();
    _sleepMinutesController = TextEditingController();
    _latencyController = TextEditingController();
    _wakeCountController = TextEditingController();
    _wakeMinutesController = TextEditingController();
    _napMinutesController = TextEditingController();
    _windDownMinutesController = TextEditingController();
    _notesController = TextEditingController();
    final appState = context.read<AppState>();
    final selected = appState.sleepDashboardState.selectedLogDateKey.trim();
    _dateKey = selected.isEmpty ? todaySleepDateKey() : selected;
    _loadDate(_dateKey);
  }

  @override
  void dispose() {
    _sleepMinutesController.dispose();
    _latencyController.dispose();
    _wakeCountController.dispose();
    _wakeMinutesController.dispose();
    _napMinutesController.dispose();
    _windDownMinutesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _loadDate(String dateKey) {
    final appState = context.read<AppState>();
    final log = appState.sleepDailyLogByDateKey(dateKey);
    final profile = appState.sleepProfile;
    setState(() {
      _dateKey = dateKey;
      _bedtime =
          timeOfDayFromDateTime(log?.bedtimeAt) ??
          tryParseTimeOfDay(profile?.typicalBedtime ?? '');
      _lightsOff = timeOfDayFromDateTime(log?.lightsOffAt);
      _sleepOnset = timeOfDayFromDateTime(log?.sleepOnsetAt);
      _finalWake = timeOfDayFromDateTime(log?.finalWakeAt);
      _outOfBed =
          timeOfDayFromDateTime(log?.outOfBedAt) ??
          tryParseTimeOfDay(profile?.typicalWakeTime ?? '');
      _sleepMinutesController.text =
          log?.estimatedTotalSleepMinutes?.toString() ?? '';
      _latencyController.text = log?.sleepLatencyMinutes?.toString() ?? '';
      _wakeCountController.text = log?.nightWakeCount.toString() ?? '0';
      _wakeMinutesController.text =
          log?.nightWakeTotalMinutes.toString() ?? '0';
      _napMinutesController.text = log?.napMinutes.toString() ?? '0';
      _windDownMinutesController.text = log?.windDownMinutes?.toString() ?? '';
      _notesController.text = log?.notes ?? '';
      _morningEnergy = (log?.morningEnergy ?? 3).toDouble().clamp(1, 5);
      _daytimeSleepiness = (log?.daytimeSleepiness ?? 3).toDouble().clamp(1, 5);
      _stressPeakLevel = (log?.stressPeakLevel ?? 2).toDouble().clamp(0, 5);
      _worryLoadLevel = (log?.worryLoadLevel ?? 2).toDouble().clamp(0, 5);
      _caffeineAfterCutoff = log?.caffeineAfterCutoff ?? false;
      _alcoholAtNight = log?.alcoholAtNight ?? false;
      _lateScreenExposure = log?.lateScreenExposure ?? false;
      _morningLightDone = log?.morningLightDone ?? false;
      _heavyDinner = log?.heavyDinner ?? false;
      _intenseExerciseLate = log?.intenseExerciseLate ?? false;
      _hotBathDone = log?.hotBathDone ?? false;
      _stretchingDone = log?.stretchingDone ?? false;
      _whiteNoiseUsed = log?.whiteNoiseUsed ?? false;
      _bedroomTooHot = log?.bedroomTooHot ?? false;
      _bedroomTooBright = log?.bedroomTooBright ?? false;
      _bedroomTooNoisy = log?.bedroomTooNoisy ?? false;
      _clockChecking = log?.clockChecking ?? false;
    });
    appState.updateSleepDashboardState(
      appState.sleepDashboardState.copyWith(selectedLogDateKey: dateKey),
    );
  }

  Future<void> _pickDate() async {
    final initialDate = tryParseSleepDateKey(_dateKey) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked == null) {
      return;
    }
    _loadDate(sleepDateKeyFromDateTime(picked));
  }

  Future<void> _pickTime({
    required TimeOfDay? initial,
    required ValueChanged<TimeOfDay> onPicked,
  }) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: initial ?? const TimeOfDay(hour: 23, minute: 0),
    );
    if (picked != null) {
      setState(() => onPicked(picked));
    }
  }

  SleepDailyLog _draftLog() {
    final appState = context.read<AppState>();
    final preferredNoiseId = appState.sleepDashboardState.preferredWhiteNoiseId
        ?.trim();
    return SleepDailyLog(
      dateKey: _dateKey,
      bedtimeAt: sleepDateTimeFromTimeOfDay(
        _dateKey,
        _bedtime,
        bedtimeSide: true,
      ),
      lightsOffAt: sleepDateTimeFromTimeOfDay(
        _dateKey,
        _lightsOff,
        bedtimeSide: true,
      ),
      sleepOnsetAt: sleepDateTimeFromTimeOfDay(
        _dateKey,
        _sleepOnset,
        bedtimeSide: true,
      ),
      finalWakeAt: sleepDateTimeFromTimeOfDay(
        _dateKey,
        _finalWake,
        bedtimeSide: false,
      ),
      outOfBedAt: sleepDateTimeFromTimeOfDay(
        _dateKey,
        _outOfBed,
        bedtimeSide: false,
      ),
      estimatedTotalSleepMinutes: _parseInt(_sleepMinutesController.text),
      sleepLatencyMinutes: _parseInt(_latencyController.text),
      nightWakeCount: _parseInt(_wakeCountController.text) ?? 0,
      nightWakeTotalMinutes: _parseInt(_wakeMinutesController.text) ?? 0,
      morningEnergy: _morningEnergy.round(),
      daytimeSleepiness: _daytimeSleepiness.round(),
      caffeineAfterCutoff: _caffeineAfterCutoff,
      alcoholAtNight: _alcoholAtNight,
      lateScreenExposure: _lateScreenExposure,
      morningLightDone: _morningLightDone,
      heavyDinner: _heavyDinner,
      intenseExerciseLate: _intenseExerciseLate,
      hotBathDone: _hotBathDone,
      stretchingDone: _stretchingDone,
      whiteNoiseUsed: _whiteNoiseUsed,
      whiteNoiseSourceId: _whiteNoiseUsed && (preferredNoiseId ?? '').isNotEmpty
          ? preferredNoiseId
          : null,
      bedroomTooHot: _bedroomTooHot,
      bedroomTooBright: _bedroomTooBright,
      bedroomTooNoisy: _bedroomTooNoisy,
      clockChecking: _clockChecking,
      stressPeakLevel: _stressPeakLevel.round(),
      worryLoadLevel: _worryLoadLevel.round(),
      windDownMinutes: _parseInt(_windDownMinutesController.text),
      napMinutes: _parseInt(_napMinutesController.text) ?? 0,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );
  }

  void _save() {
    final appState = context.read<AppState>();
    final i18n = AppI18n(appState.uiLanguage);
    appState.saveSleepDailyLog(_draftLog());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          pickSleepText(i18n, zh: '睡眠日志已保存', en: 'Sleep log saved'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final i18n = AppI18n(appState.uiLanguage);
    if (!appState.isModuleEnabled(ModuleIds.toolboxSleepAssistant)) {
      return ToolboxToolPage(
        title: pickSleepText(i18n, zh: '睡眠助手', en: 'Sleep assistant'),
        subtitle: pickSleepText(
          i18n,
          zh: '模块已停用，无法继续访问睡眠助手页面。',
          en: 'This module is disabled and unavailable right now.',
        ),
        child: ModuleDisabledView(
          i18n: i18n,
          moduleId: ModuleIds.toolboxSleepAssistant,
        ),
      );
    }
    final currentLog = _draftLog();
    final adviceItems = buildSleepDailyAdvice(
      i18n,
      profile: appState.sleepProfile,
      log: currentLog,
    );
    final recentKeys = recentSleepDateKeys(count: 7);
    final latest = appState.latestSleepDailyLog;
    return ToolboxToolPage(
      title: pickSleepText(i18n, zh: '连续睡眠日志', en: 'Continuous sleep log'),
      subtitle: pickSleepText(
        i18n,
        zh: '围绕日期连续编辑同一份日志，用更细的时间点和影响因子复盘昨晚。',
        en: 'Edit logs continuously by date with finer time points and behavior factors.',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (latest != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    Chip(label: Text(sleepDateLabel(latest.dateKey))),
                    Chip(
                      label: Text(
                        '${pickSleepText(i18n, zh: '睡眠', en: 'Sleep')} ${sleepMinutesLabel(latest.estimatedTotalSleepMinutes)}',
                      ),
                    ),
                    Chip(
                      label: Text(
                        '${pickSleepText(i18n, zh: '效率', en: 'Efficiency')} ${sleepPercentLabel(latest.sleepEfficiency)}',
                      ),
                    ),
                    Chip(
                      label: Text(
                        '${pickSleepText(i18n, zh: '晨间精神', en: 'Energy')} ${sleepScoreLabel(latest.morningEnergy)}',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          pickSleepText(i18n, zh: '编辑日期', en: 'Editing date'),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_month_rounded),
                        label: Text(sleepDateLabel(_dateKey)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: recentKeys
                        .map(
                          (dateKey) => ChoiceChip(
                            label: Text(sleepDateLabel(dateKey).substring(5)),
                            selected: _dateKey == dateKey,
                            onSelected: (_) => _loadDate(dateKey),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    pickSleepText(i18n, zh: '时间轴', en: 'Timeline'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  _TimeRow(
                    label: pickSleepText(i18n, zh: '上床', en: 'Bedtime'),
                    value: _bedtime,
                    onTap: () => _pickTime(
                      initial: _bedtime,
                      onPicked: (value) => _bedtime = value,
                    ),
                  ),
                  _TimeRow(
                    label: pickSleepText(i18n, zh: '熄灯', en: 'Lights off'),
                    value: _lightsOff,
                    onTap: () => _pickTime(
                      initial: _lightsOff,
                      onPicked: (value) => _lightsOff = value,
                    ),
                  ),
                  _TimeRow(
                    label: pickSleepText(i18n, zh: '估计入睡', en: 'Sleep onset'),
                    value: _sleepOnset,
                    onTap: () => _pickTime(
                      initial: _sleepOnset,
                      onPicked: (value) => _sleepOnset = value,
                    ),
                  ),
                  _TimeRow(
                    label: pickSleepText(i18n, zh: '最后醒来', en: 'Final wake'),
                    value: _finalWake,
                    onTap: () => _pickTime(
                      initial: _finalWake,
                      onPicked: (value) => _finalWake = value,
                    ),
                  ),
                  _TimeRow(
                    label: pickSleepText(i18n, zh: '离床', en: 'Out of bed'),
                    value: _outOfBed,
                    onTap: () => _pickTime(
                      initial: _outOfBed,
                      onPicked: (value) => _outOfBed = value,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: <Widget>[
                  _NumberField(
                    controller: _sleepMinutesController,
                    label: pickSleepText(
                      i18n,
                      zh: '估计总睡眠分钟数',
                      en: 'Estimated sleep minutes',
                    ),
                  ),
                  const SizedBox(height: 12),
                  _NumberField(
                    controller: _latencyController,
                    label: pickSleepText(
                      i18n,
                      zh: '入睡潜伏期（分钟）',
                      en: 'Sleep latency (minutes)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  _NumberField(
                    controller: _wakeCountController,
                    label: pickSleepText(i18n, zh: '夜醒次数', en: 'Wake count'),
                  ),
                  const SizedBox(height: 12),
                  _NumberField(
                    controller: _wakeMinutesController,
                    label: pickSleepText(
                      i18n,
                      zh: '夜醒总时长（分钟）',
                      en: 'Wake time total (minutes)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  _NumberField(
                    controller: _napMinutesController,
                    label: pickSleepText(i18n, zh: '午睡分钟数', en: 'Nap minutes'),
                  ),
                  const SizedBox(height: 12),
                  _NumberField(
                    controller: _windDownMinutesController,
                    label: pickSleepText(
                      i18n,
                      zh: '睡前减压时长（分钟）',
                      en: 'Wind-down minutes',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: pickSleepText(i18n, zh: '备注', en: 'Notes'),
                      hintText: pickSleepText(
                        i18n,
                        zh: '例如：加班、出差、反酸、房间太热、被噪声拉醒',
                        en: 'Example: overtime, travel, reflux, room too hot, woken by noise',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    pickSleepText(i18n, zh: '主观评分', en: 'Subjective scores'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${pickSleepText(i18n, zh: '晨间精神', en: 'Morning energy')} ${_morningEnergy.round()}/5',
                  ),
                  Slider(
                    value: _morningEnergy,
                    min: 1,
                    max: 5,
                    divisions: 4,
                    onChanged: (value) =>
                        setState(() => _morningEnergy = value),
                  ),
                  Text(
                    '${pickSleepText(i18n, zh: '白天困倦', en: 'Daytime sleepiness')} ${_daytimeSleepiness.round()}/5',
                  ),
                  Slider(
                    value: _daytimeSleepiness,
                    min: 1,
                    max: 5,
                    divisions: 4,
                    onChanged: (value) =>
                        setState(() => _daytimeSleepiness = value),
                  ),
                  Text(
                    '${pickSleepText(i18n, zh: '当日压力峰值', en: 'Stress peak')} ${_stressPeakLevel.round()}/5',
                  ),
                  Slider(
                    value: _stressPeakLevel,
                    min: 0,
                    max: 5,
                    divisions: 5,
                    onChanged: (value) =>
                        setState(() => _stressPeakLevel = value),
                  ),
                  Text(
                    '${pickSleepText(i18n, zh: '担忧负荷', en: 'Worry load')} ${_worryLoadLevel.round()}/5',
                  ),
                  Slider(
                    value: _worryLoadLevel,
                    min: 0,
                    max: 5,
                    divisions: 5,
                    onChanged: (value) =>
                        setState(() => _worryLoadLevel = value),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _DailySwitchGroup(
            title: pickSleepText(
              i18n,
              zh: '行为与环境因子',
              en: 'Behavior and environment',
            ),
            children: <Widget>[
              _FactorSwitch(
                value: _caffeineAfterCutoff,
                title: sleepDailyFactorTitle(i18n, 'caffeineAfterCutoff'),
                subtitle: sleepDailyFactorHint(i18n, 'caffeineAfterCutoff'),
                onChanged: (value) =>
                    setState(() => _caffeineAfterCutoff = value),
              ),
              _FactorSwitch(
                value: _lateScreenExposure,
                title: sleepDailyFactorTitle(i18n, 'lateScreenExposure'),
                subtitle: sleepDailyFactorHint(i18n, 'lateScreenExposure'),
                onChanged: (value) =>
                    setState(() => _lateScreenExposure = value),
              ),
              _FactorSwitch(
                value: _alcoholAtNight,
                title: sleepDailyFactorTitle(i18n, 'alcoholAtNight'),
                subtitle: sleepDailyFactorHint(i18n, 'alcoholAtNight'),
                onChanged: (value) => setState(() => _alcoholAtNight = value),
              ),
              _FactorSwitch(
                value: _morningLightDone,
                title: sleepDailyFactorTitle(i18n, 'morningLightDone'),
                subtitle: sleepDailyFactorHint(i18n, 'morningLightDone'),
                onChanged: (value) => setState(() => _morningLightDone = value),
              ),
              _FactorSwitch(
                value: _heavyDinner,
                title: sleepDailyFactorTitle(i18n, 'heavyDinner'),
                subtitle: pickSleepText(
                  i18n,
                  zh: '太晚、太重或太撑都会拖慢入睡。',
                  en: 'A heavy or late dinner can slow down sleep onset.',
                ),
                onChanged: (value) => setState(() => _heavyDinner = value),
              ),
              _FactorSwitch(
                value: _intenseExerciseLate,
                title: sleepDailyFactorTitle(i18n, 'intenseExerciseLate'),
                subtitle: pickSleepText(
                  i18n,
                  zh: '太晚高强度运动可能让身体还没降下来。',
                  en: 'Very late intense exercise can keep the body activated.',
                ),
                onChanged: (value) =>
                    setState(() => _intenseExerciseLate = value),
              ),
              _FactorSwitch(
                value: _hotBathDone,
                title: sleepDailyFactorTitle(i18n, 'hotBathDone'),
                subtitle: pickSleepText(
                  i18n,
                  zh: '如果配合更安静的过渡，通常比硬躺更有帮助。',
                  en: 'Used as a transition, it can help more than simply forcing bed.',
                ),
                onChanged: (value) => setState(() => _hotBathDone = value),
              ),
              _FactorSwitch(
                value: _stretchingDone,
                title: sleepDailyFactorTitle(i18n, 'stretchingDone'),
                subtitle: pickSleepText(
                  i18n,
                  zh: '轻柔拉伸适合降低身体残余紧绷。',
                  en: 'Gentle stretching can lower residual tension.',
                ),
                onChanged: (value) => setState(() => _stretchingDone = value),
              ),
              _FactorSwitch(
                value: _whiteNoiseUsed,
                title: sleepDailyFactorTitle(i18n, 'whiteNoiseUsed'),
                subtitle: sleepDailyFactorHint(i18n, 'whiteNoiseUsed'),
                onChanged: (value) => setState(() => _whiteNoiseUsed = value),
              ),
              _FactorSwitch(
                value: _bedroomTooHot,
                title: sleepDailyFactorTitle(i18n, 'bedroomTooHot'),
                subtitle: pickSleepText(
                  i18n,
                  zh: '卧室偏热很容易拖慢入睡并增加夜醒。',
                  en: 'A hot room can delay sleep and increase awakenings.',
                ),
                onChanged: (value) => setState(() => _bedroomTooHot = value),
              ),
              _FactorSwitch(
                value: _bedroomTooBright,
                title: sleepDailyFactorTitle(i18n, 'bedroomTooBright'),
                subtitle: pickSleepText(
                  i18n,
                  zh: '亮度过高会让睡意更难稳定下来。',
                  en: 'A bright room can make sleepiness less stable.',
                ),
                onChanged: (value) => setState(() => _bedroomTooBright = value),
              ),
              _FactorSwitch(
                value: _bedroomTooNoisy,
                title: sleepDailyFactorTitle(i18n, 'bedroomTooNoisy'),
                subtitle: pickSleepText(
                  i18n,
                  zh: '若是噪声不稳定，白噪音可能比忍耐更有效。',
                  en: 'If noise is inconsistent, white noise may help more than tolerating it.',
                ),
                onChanged: (value) => setState(() => _bedroomTooNoisy = value),
              ),
              _FactorSwitch(
                value: _clockChecking,
                title: sleepDailyFactorTitle(i18n, 'clockChecking'),
                subtitle: sleepDailyFactorHint(i18n, 'clockChecking'),
                onChanged: (value) => setState(() => _clockChecking = value),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    pickSleepText(i18n, zh: '实用工具', en: 'Practical tools'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: <Widget>[
                      SleepQuickToolButton(
                        title: pickSleepText(
                          i18n,
                          zh: '白噪音',
                          en: 'White noise',
                        ),
                        icon: Icons.graphic_eq_rounded,
                        onTap: () => showSleepWhiteNoiseSheet(context),
                      ),
                      SleepQuickToolButton(
                        title: pickSleepText(
                          i18n,
                          zh: '咖啡因截止线',
                          en: 'Caffeine cutoff',
                        ),
                        icon: Icons.local_cafe_rounded,
                        onTap: () => showCaffeineCutoffCalculatorSheet(
                          context,
                          bedtime: _bedtime,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    pickSleepText(i18n, zh: '直接建议', en: 'Direct advice'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  SleepAdviceList(items: adviceItems, i18n: i18n),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save_rounded),
            label: Text(pickSleepText(i18n, zh: '保存日志', en: 'Save log')),
          ),
        ],
      ),
    );
  }

  static int? _parseInt(String raw) {
    return int.tryParse(raw.trim());
  }
}

class _TimeRow extends StatelessWidget {
  const _TimeRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final TimeOfDay? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(sleepTimeOfDayLabel(value)),
      trailing: const Icon(Icons.schedule_rounded),
      onTap: onTap,
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
    );
  }
}

class _DailySwitchGroup extends StatelessWidget {
  const _DailySwitchGroup({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _FactorSwitch extends StatelessWidget {
  const _FactorSwitch({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.onChanged,
  });

  final bool value;
  final String title;
  final String subtitle;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SettingTile(
      icon: Icons.tune_rounded,
      title: title,
      subtitle: subtitle,
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }
}
