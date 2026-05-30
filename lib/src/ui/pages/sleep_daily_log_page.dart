import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/module_system/module_id.dart';
import '../../i18n/app_i18n.dart';
import '../../models/sleep_daily_log.dart';
import '../../state/app_state.dart';
import '../module/module_access.dart';
import '../widgets/setting_tile.dart';
import 'sleep_quick_tools.dart';
import 'sleep_research_library.dart';
import 'sleep_assistant_ui_support.dart';
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
    _loadDate(_dateKey, updateDashboard: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _updateSelectedLogDate(_dateKey);
    });
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

  void _loadDate(String dateKey, {bool updateDashboard = true}) {
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
    if (!updateDashboard) {
      return;
    }
    _updateSelectedLogDate(dateKey);
  }

  void _updateSelectedLogDate(String dateKey) {
    final appState = context.read<AppState>();
    if (appState.sleepDashboardState.selectedLogDateKey == dateKey) {
      return;
    }
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(i18n.t('toolbox.sleep.log.saved'))));
  }

  void _applyLogPreset(_SleepLogPreset preset) {
    setState(() {
      _sleepMinutesController.text = preset.sleepMinutes.toString();
      _latencyController.text = preset.latencyMinutes.toString();
      _wakeCountController.text = preset.wakeCount.toString();
      _wakeMinutesController.text = preset.wakeMinutes.toString();
      _morningEnergy = preset.morningEnergy.toDouble();
      _daytimeSleepiness = preset.daytimeSleepiness.toDouble();
      _stressPeakLevel = preset.stressPeakLevel.toDouble();
      _worryLoadLevel = preset.worryLoadLevel.toDouble();
      if (preset.lateScreenExposure) {
        _lateScreenExposure = true;
      }
      if (preset.clockChecking) {
        _clockChecking = true;
      }
    });
  }

  void _setNumber(TextEditingController controller, int value) {
    setState(() => controller.text = value.toString());
  }

  void _appendNoteTag(String tag) {
    final current = _notesController.text.trim();
    setState(() {
      _notesController.text = current.isEmpty ? tag : '$current�?tag';
      _notesController.selection = TextSelection.collapsed(
        offset: _notesController.text.length,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final i18n = AppI18n(appState.uiLanguage);
    Widget themed(Widget child) {
      return sleepModuleTheme(
        context: context,
        enabled: appState.sleepDashboardState.sleepDarkModeEnabled,
        child: child,
      );
    }

    if (!appState.isModuleEnabled(ModuleIds.toolboxSleepAssistant)) {
      return themed(
        ToolboxToolPage(
          title: i18n.t('toolbox.sleep.core.title'),
          subtitle: i18n.t('toolbox.sleep.assessment.moduleDisabled'),
          child: ModuleDisabledView(
            i18n: i18n,
            moduleId: ModuleIds.toolboxSleepAssistant,
          ),
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
    return themed(
      ToolboxToolPage(
        title: i18n.t('toolbox.sleep.log.title'),
        subtitle: i18n.t('toolbox.sleep.log.intro'),
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
                          '${i18n.t('toolbox.sleep.log.sleep')} ${sleepMinutesLabel(latest.estimatedTotalSleepMinutes)}',
                        ),
                      ),
                      Chip(
                        label: Text(
                          '${i18n.t('toolbox.sleep.log.efficiency')} ${sleepPercentLabel(latest.sleepEfficiency)}',
                        ),
                      ),
                      Chip(
                        label: Text(
                          '${i18n.t('toolbox.sleep.log.morningEnergy')} ${sleepScoreLabel(latest.morningEnergy)}',
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
                            i18n.t('toolbox.sleep.log.editingDate'),
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
                      i18n.t('toolbox.sleep.log.log30sec'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(i18n.t('toolbox.sleep.log.log30secHint')),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          <_SleepLogPreset>[
                                _SleepLogPreset(
                                  label: i18n.t('toolbox.sleep.log.presetOkay'),
                                  sleepMinutes: 420,
                                  latencyMinutes: 20,
                                  wakeCount: 1,
                                  wakeMinutes: 10,
                                  morningEnergy: 3,
                                  daytimeSleepiness: 3,
                                  stressPeakLevel: 2,
                                  worryLoadLevel: 2,
                                ),
                                _SleepLogPreset(
                                  label: i18n.t(
                                    'toolbox.sleep.log.presetShort',
                                  ),
                                  sleepMinutes: 330,
                                  latencyMinutes: 45,
                                  wakeCount: 2,
                                  wakeMinutes: 35,
                                  morningEnergy: 2,
                                  daytimeSleepiness: 4,
                                  stressPeakLevel: 3,
                                  worryLoadLevel: 3,
                                  lateScreenExposure: true,
                                ),
                                _SleepLogPreset(
                                  label: i18n.t(
                                    'toolbox.sleep.log.presetWokeOften',
                                  ),
                                  sleepMinutes: 390,
                                  latencyMinutes: 20,
                                  wakeCount: 3,
                                  wakeMinutes: 60,
                                  morningEnergy: 2,
                                  daytimeSleepiness: 4,
                                  stressPeakLevel: 2,
                                  worryLoadLevel: 3,
                                  clockChecking: true,
                                ),
                              ]
                              .map(
                                (preset) => ActionChip(
                                  avatar: const Icon(
                                    Icons.bolt_rounded,
                                    size: 18,
                                  ),
                                  label: Text(preset.label),
                                  onPressed: () => _applyLogPreset(preset),
                                ),
                              )
                              .toList(growable: false),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.tonalIcon(
                      onPressed: _save,
                      icon: const Icon(Icons.done_rounded),
                      label: Text(i18n.t('toolbox.sleep.log.saveCurrent')),
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
                      i18n.t('toolbox.sleep.log.timeline'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    _TimeRow(
                      label: i18n.t('toolbox.sleep.log.bedtime'),
                      value: _bedtime,
                      onTap: () => _pickTime(
                        initial: _bedtime,
                        onPicked: (value) => _bedtime = value,
                      ),
                    ),
                    _TimeRow(
                      label: i18n.t('toolbox.sleep.log.lightsOff'),
                      value: _lightsOff,
                      onTap: () => _pickTime(
                        initial: _lightsOff,
                        onPicked: (value) => _lightsOff = value,
                      ),
                    ),
                    _TimeRow(
                      label: i18n.t('toolbox.sleep.log.sleepOnset'),
                      value: _sleepOnset,
                      onTap: () => _pickTime(
                        initial: _sleepOnset,
                        onPicked: (value) => _sleepOnset = value,
                      ),
                    ),
                    _TimeRow(
                      label: i18n.t('toolbox.sleep.log.finalWake'),
                      value: _finalWake,
                      onTap: () => _pickTime(
                        initial: _finalWake,
                        onPicked: (value) => _finalWake = value,
                      ),
                    ),
                    _TimeRow(
                      label: i18n.t('toolbox.sleep.log.outOfBed'),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      i18n.t('toolbox.sleep.log.commonValues'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    _NumberField(
                      controller: _sleepMinutesController,
                      label: i18n.t('toolbox.sleep.log.estimatedSleepMinutes'),
                    ),
                    _QuickValueChips(
                      values: const <int>[330, 360, 390, 420, 450, 480],
                      labelFor: (value) =>
                          sleepMinutesLabel(value, long: true, i18n: i18n),
                      onSelected: (value) =>
                          _setNumber(_sleepMinutesController, value),
                    ),
                    const SizedBox(height: 12),
                    _NumberField(
                      controller: _latencyController,
                      label: i18n.t('toolbox.sleep.log.sleepLatency'),
                    ),
                    _QuickValueChips(
                      values: const <int>[10, 20, 30, 45, 60],
                      labelFor: (value) => '$value min',
                      onSelected: (value) =>
                          _setNumber(_latencyController, value),
                    ),
                    const SizedBox(height: 12),
                    _NumberField(
                      controller: _wakeCountController,
                      label: i18n.t('toolbox.sleep.log.wakeCount'),
                    ),
                    _QuickValueChips(
                      values: const <int>[0, 1, 2, 3, 4],
                      labelFor: (value) => value == 4
                          ? i18n.t('toolbox.sleep.log.fourPlus')
                          : '$value',
                      onSelected: (value) =>
                          _setNumber(_wakeCountController, value),
                    ),
                    const SizedBox(height: 12),
                    _NumberField(
                      controller: _wakeMinutesController,
                      label: i18n.t('toolbox.sleep.log.wakeTotal'),
                    ),
                    _QuickValueChips(
                      values: const <int>[0, 10, 20, 40, 60],
                      labelFor: (value) => '$value min',
                      onSelected: (value) =>
                          _setNumber(_wakeMinutesController, value),
                    ),
                    const SizedBox(height: 12),
                    _NumberField(
                      controller: _napMinutesController,
                      label: i18n.t('toolbox.sleep.log.napMinutes'),
                    ),
                    _QuickValueChips(
                      values: const <int>[0, 10, 20, 30, 45],
                      labelFor: (value) => '$value min',
                      onSelected: (value) =>
                          _setNumber(_napMinutesController, value),
                    ),
                    const SizedBox(height: 12),
                    _NumberField(
                      controller: _windDownMinutesController,
                      label: i18n.t('toolbox.sleep.log.windDownMinutes'),
                    ),
                    _QuickValueChips(
                      values: const <int>[0, 8, 15, 30, 45],
                      labelFor: (value) => '$value min',
                      onSelected: (value) =>
                          _setNumber(_windDownMinutesController, value),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: i18n.t('toolbox.sleep.log.contextNotes'),
                        hintText: i18n.t('toolbox.sleep.log.notesHint'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          <String>[
                                i18n.t('toolbox.sleep.log.overtime'),
                                i18n.t('toolbox.sleep.log.roomHot'),
                                i18n.t('toolbox.sleep.log.noise'),
                                i18n.t('toolbox.sleep.log.travel'),
                                i18n.t('toolbox.sleep.log.reflux'),
                                i18n.t('toolbox.sleep.log.tagDreams'),
                              ]
                              .map(
                                (tag) => ActionChip(
                                  label: Text(tag),
                                  onPressed: () => _appendNoteTag(tag),
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
                      i18n.t('toolbox.sleep.log.subjectiveScores'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${i18n.t('toolbox.sleep.log.morningEnergy')} ${_morningEnergy.round()}/5',
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
                      '${i18n.t('toolbox.sleep.log.daytimeSleepiness')} ${_daytimeSleepiness.round()}/5',
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
                      '${i18n.t('toolbox.sleep.log.stressPeak')} ${_stressPeakLevel.round()}/5',
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
                      '${i18n.t('toolbox.sleep.log.worryLoad')} ${_worryLoadLevel.round()}/5',
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
              title: i18n.t('toolbox.sleep.log.behaviorEnv'),
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
                  onChanged: (value) =>
                      setState(() => _morningLightDone = value),
                ),
                _FactorSwitch(
                  value: _heavyDinner,
                  title: sleepDailyFactorTitle(i18n, 'heavyDinner'),
                  subtitle: i18n.t('toolbox.sleep.log.heavyDinnerHint'),
                  onChanged: (value) => setState(() => _heavyDinner = value),
                ),
                _FactorSwitch(
                  value: _intenseExerciseLate,
                  title: sleepDailyFactorTitle(i18n, 'intenseExerciseLate'),
                  subtitle: i18n.t('toolbox.sleep.log.intenseExerciseHint'),
                  onChanged: (value) =>
                      setState(() => _intenseExerciseLate = value),
                ),
                _FactorSwitch(
                  value: _hotBathDone,
                  title: sleepDailyFactorTitle(i18n, 'hotBathDone'),
                  subtitle: i18n.t('toolbox.sleep.log.hotBathHint'),
                  onChanged: (value) => setState(() => _hotBathDone = value),
                ),
                _FactorSwitch(
                  value: _stretchingDone,
                  title: sleepDailyFactorTitle(i18n, 'stretchingDone'),
                  subtitle: i18n.t('toolbox.sleep.log.stretchingHint'),
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
                  subtitle: i18n.t('toolbox.sleep.log.bedroomHotHint'),
                  onChanged: (value) => setState(() => _bedroomTooHot = value),
                ),
                _FactorSwitch(
                  value: _bedroomTooBright,
                  title: sleepDailyFactorTitle(i18n, 'bedroomTooBright'),
                  subtitle: i18n.t('toolbox.sleep.log.bedroomBrightHint'),
                  onChanged: (value) =>
                      setState(() => _bedroomTooBright = value),
                ),
                _FactorSwitch(
                  value: _bedroomTooNoisy,
                  title: sleepDailyFactorTitle(i18n, 'bedroomTooNoisy'),
                  subtitle: i18n.t('toolbox.sleep.log.bedroomNoisyHint'),
                  onChanged: (value) =>
                      setState(() => _bedroomTooNoisy = value),
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
                      i18n.t('toolbox.sleep.log.practicalTools'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: <Widget>[
                        SleepQuickToolButton(
                          title: i18n.t('toolbox.sleep.log.whiteNoise'),
                          icon: Icons.graphic_eq_rounded,
                          onTap: () => showSleepWhiteNoiseSheet(context),
                        ),
                        SleepQuickToolButton(
                          title: i18n.t('toolbox.sleep.log.caffeineCutoff'),
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
                      i18n.t('toolbox.sleep.log.directAdvice'),
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
              label: Text(i18n.t('toolbox.sleep.log.saveLog')),
            ),
          ],
        ),
      ),
    );
  }

  static int? _parseInt(String raw) {
    return int.tryParse(raw.trim());
  }
}

class _SleepLogPreset {
  const _SleepLogPreset({
    required this.label,
    required this.sleepMinutes,
    required this.latencyMinutes,
    required this.wakeCount,
    required this.wakeMinutes,
    required this.morningEnergy,
    required this.daytimeSleepiness,
    required this.stressPeakLevel,
    required this.worryLoadLevel,
    this.lateScreenExposure = false,
    this.clockChecking = false,
  });

  final String label;
  final int sleepMinutes;
  final int latencyMinutes;
  final int wakeCount;
  final int wakeMinutes;
  final int morningEnergy;
  final int daytimeSleepiness;
  final int stressPeakLevel;
  final int worryLoadLevel;
  final bool lateScreenExposure;
  final bool clockChecking;
}

class _QuickValueChips extends StatelessWidget {
  const _QuickValueChips({
    required this.values,
    required this.labelFor,
    required this.onSelected,
  });

  final List<int> values;
  final String Function(int value) labelFor;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: values
            .map(
              (value) => ActionChip(
                label: Text(labelFor(value)),
                onPressed: () => onSelected(value),
              ),
            )
            .toList(growable: false),
      ),
    );
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
