import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/module_system/module_id.dart';
import '../../i18n/app_i18n.dart';
import '../../models/sleep_profile.dart';
import '../../state/app_state.dart';
import '../../services/app_log_service.dart';
import '../module/module_access.dart';
import 'sleep_support/sleep_day_form_widgets.dart';
import 'sleep_assistant_ui_support.dart';
import 'toolbox_tool_shell.dart';

class SleepAssessmentPage extends StatefulWidget {
  const SleepAssessmentPage({super.key});

  @override
  State<SleepAssessmentPage> createState() => _SleepAssessmentPageState();
}

class _SleepAssessmentPageState extends State<SleepAssessmentPage> {
  int _step = 0;
  bool _details = false;
  bool _moreIssues = false;
  bool _saved = false;
  late Set<SleepIssueType> _selectedIssues;
  late TextEditingController _goalController;
  late TimeOfDay? _bedtime;
  late TimeOfDay? _wakeTime;
  late bool _hasRacingThoughts;
  late bool _caffeineSensitive;
  late SleepRiskLevel _snoringRisk;
  late double _painImpactLevel;
  late double _stressLoadLevel;
  late double _screenDependenceLevel;
  late double _lateWorkFrequency;
  late double _exerciseLateFrequency;
  late bool _bedroomLightIssue;
  late bool _bedroomNoiseIssue;
  late bool _bedroomTempIssue;
  late bool _shiftWorkOrJetLag;
  late bool _refluxOrDigestiveDiscomfort;
  late bool _nightmaresOrDreamDistress;

  @override
  void initState() {
    super.initState();
    final draft = context.read<AppState>().sleepAssessmentDraft;
    _selectedIssues = Set<SleepIssueType>.from(draft.selectedIssues);
    _goalController = TextEditingController(text: draft.goal);
    _bedtime = tryParseTimeOfDay(draft.typicalBedtime);
    _wakeTime = tryParseTimeOfDay(draft.typicalWakeTime);
    _hasRacingThoughts = draft.hasRacingThoughts;
    _caffeineSensitive = draft.caffeineSensitive;
    _snoringRisk = draft.snoringRisk;
    _painImpactLevel = draft.painImpactLevel.toDouble();
    _stressLoadLevel = draft.stressLoadLevel.toDouble();
    _screenDependenceLevel = draft.screenDependenceLevel.toDouble();
    _lateWorkFrequency = draft.lateWorkFrequency.toDouble();
    _exerciseLateFrequency = draft.exerciseLateFrequency.toDouble();
    _bedroomLightIssue = draft.bedroomLightIssue;
    _bedroomNoiseIssue = draft.bedroomNoiseIssue;
    _bedroomTempIssue = draft.bedroomTempIssue;
    _shiftWorkOrJetLag = draft.shiftWorkOrJetLag;
    _refluxOrDigestiveDiscomfort = draft.refluxOrDigestiveDiscomfort;
    _nightmaresOrDreamDistress = draft.nightmaresOrDreamDistress;
    _goalController.addListener(_persistDraft);
  }

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  SleepAssessmentDraftState get _draft => SleepAssessmentDraftState(
    selectedIssues: _selectedIssues,
    typicalBedtime: timeOfDayToStorage(_bedtime),
    typicalWakeTime: timeOfDayToStorage(_wakeTime),
    hasRacingThoughts: _hasRacingThoughts,
    snoringRisk: _snoringRisk,
    caffeineSensitive: _caffeineSensitive,
    painImpactLevel: _painImpactLevel.round(),
    stressLoadLevel: _stressLoadLevel.round(),
    screenDependenceLevel: _screenDependenceLevel.round(),
    lateWorkFrequency: _lateWorkFrequency.round(),
    exerciseLateFrequency: _exerciseLateFrequency.round(),
    bedroomLightIssue: _bedroomLightIssue,
    bedroomNoiseIssue: _bedroomNoiseIssue,
    bedroomTempIssue: _bedroomTempIssue,
    shiftWorkOrJetLag: _shiftWorkOrJetLag,
    refluxOrDigestiveDiscomfort: _refluxOrDigestiveDiscomfort,
    nightmaresOrDreamDistress: _nightmaresOrDreamDistress,
    goal: _goalController.text.trim(),
  );

  void _persistDraft() {
    if (_saved && mounted) {
      setState(() => _saved = false);
    }
    context.read<AppState>().updateSleepAssessmentDraft(_draft);
  }

  Future<void> _pickTime({required bool bedtime}) async {
    final current = bedtime
        ? (_bedtime ?? const TimeOfDay(hour: 23, minute: 0))
        : (_wakeTime ?? const TimeOfDay(hour: 7, minute: 30));
    final picked = await showTimePicker(context: context, initialTime: current);
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      if (bedtime) {
        _bedtime = picked;
      } else {
        _wakeTime = picked;
      }
    });
    _persistDraft();
  }

  void _save() {
    final appState = context.read<AppState>();
    final now = DateTime.now();
    final i18n = AppI18n(appState.uiLanguage);
    try {
      appState.saveSleepProfile(
        SleepProfile(
          primaryIssues: _selectedIssues,
          typicalBedtime: timeOfDayToStorage(_bedtime),
          typicalWakeTime: timeOfDayToStorage(_wakeTime),
          hasRacingThoughts: _hasRacingThoughts,
          caffeineSensitive: _caffeineSensitive,
          snoringRisk: _snoringRisk,
          painImpactLevel: _painImpactLevel.round(),
          stressLoadLevel: _stressLoadLevel.round(),
          screenDependenceLevel: _screenDependenceLevel.round(),
          lateWorkFrequency: _lateWorkFrequency.round(),
          exerciseLateFrequency: _exerciseLateFrequency.round(),
          bedroomLightIssue: _bedroomLightIssue,
          bedroomNoiseIssue: _bedroomNoiseIssue,
          bedroomTempIssue: _bedroomTempIssue,
          shiftWorkOrJetLag: _shiftWorkOrJetLag,
          refluxOrDigestiveDiscomfort: _refluxOrDigestiveDiscomfort,
          nightmaresOrDreamDistress: _nightmaresOrDreamDistress,
          goal: _goalController.text.trim(),
          createdAt: appState.sleepProfile?.createdAt ?? now,
          updatedAt: now,
        ),
      );
      setState(() => _saved = true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(i18n.t('toolbox.sleep.assessment.saved'))),
      );
    } catch (error, stackTrace) {
      AppLogService.instance.e(
        'SleepAssessment',
        'Could not save assessment',
        error: error,
        stackTrace: stackTrace,
      );
      setState(() => _saved = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(i18n.t('toolbox.sleep.day.save_failed'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = context.select<AppState, String>((s) => s.uiLanguage);
    final enabled = context.select<AppState, bool>(
      (s) => s.isModuleEnabled(ModuleIds.toolboxSleepAssistant),
    );
    final dark = context.select<AppState, bool>(
      (s) => s.sleepDashboardState.sleepDarkModeEnabled,
    );
    final i18n = AppI18n(language);
    return sleepModuleTheme(
      context: context,
      enabled: dark,
      child: Builder(
        builder: (context) => ToolboxToolPage(
          title: i18n.t('toolbox.sleep.assessment.title'),
          subtitle: i18n.t('toolbox.sleep.assessment.flow.intro'),
          showPageHeader: false,
          child: enabled
              ? _content(i18n)
              : ModuleDisabledView(
                  i18n: i18n,
                  moduleId: ModuleIds.toolboxSleepAssistant,
                ),
        ),
      ),
    );
  }

  Widget _content(AppI18n i18n) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(i18n.t('toolbox.sleep.assessment.flow.intro')),
      const SizedBox(height: 12),
      switch (_step) {
        0 => _issues(i18n),
        1 => _schedule(i18n),
        _ => _review(i18n),
      },
      TextButton.icon(
        onPressed: () => setState(() => _details = !_details),
        icon: Icon(_details ? Icons.expand_less : Icons.tune_rounded),
        label: Text(i18n.t('toolbox.sleep.day.details')),
      ),
      if (_details) ..._detailFields(i18n),
      if (_details && _step < 2) _saveButton(i18n),
    ],
  );

  Widget _issues(AppI18n i18n) => SleepDayPanel(
    title: i18n.t('toolbox.sleep.assessment.flow.issue'),
    children: [
      for (final issue
          in _moreIssues
              ? SleepIssueType.values
              : const [
                  SleepIssueType.difficultyFallingAsleep,
                  SleepIssueType.frequentAwakenings,
                  SleepIssueType.racingThoughts,
                  SleepIssueType.nonRestorativeSleep,
                ])
        SleepDayChoice<SleepIssueType>(
          label: sleepIssueLabel(i18n, issue),
          value: issue,
          selected: _selectedIssues.contains(issue),
          onSelected: (issue) {
            setState(() {
              if (!_selectedIssues.add(issue)) _selectedIssues.remove(issue);
            });
            _persistDraft();
          },
        ),
      TextButton(
        onPressed: () => setState(() => _moreIssues = !_moreIssues),
        child: Text(i18n.t('toolbox.sleep.day.details')),
      ),
      FilledButton(
        onPressed: () => setState(() => _step = 1),
        child: Text(i18n.t('toolbox.sleep.day.next')),
      ),
      TextButton(
        onPressed: () => setState(() => _step = 1),
        child: Text(i18n.t('toolbox.sleep.day.skip')),
      ),
    ],
  );

  Widget _schedule(AppI18n i18n) => SleepDayPanel(
    title: i18n.t('toolbox.sleep.assessment.baselineSchedule'),
    children: [
      Text(i18n.t('toolbox.sleep.assessment.flow.schedule_hint')),
      const SizedBox(height: 12),
      for (final item in <(bool, String, TimeOfDay?)>[
        (true, 'typicalBedtime', _bedtime),
        (false, 'typicalWakeTime', _wakeTime),
      ])
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(i18n.t('toolbox.sleep.assessment.${item.$2}')),
          subtitle: Text(
            item.$3 == null
                ? i18n.t('toolbox.sleep.day.unknown')
                : sleepTimeOfDayLabel(item.$3),
          ),
          trailing: const Icon(Icons.schedule_rounded),
          onTap: () => _pickTime(bedtime: item.$1),
        ),
      FilledButton(
        onPressed: () => setState(() => _step = 2),
        child: Text(i18n.t('toolbox.sleep.day.next')),
      ),
      TextButton(
        onPressed: () => setState(() => _step = 2),
        child: Text(i18n.t('toolbox.sleep.day.skip')),
      ),
      TextButton(
        onPressed: () => setState(() => _step = 0),
        child: Text(i18n.t('toolbox.sleep.day.back')),
      ),
    ],
  );

  Widget _review(AppI18n i18n) => SleepDayPanel(
    title: i18n.t('toolbox.sleep.assessment.flow.review'),
    children: [
      Text(
        _selectedIssues.isEmpty
            ? i18n.t('toolbox.sleep.day.unknown')
            : _selectedIssues
                  .map((issue) => sleepIssueLabel(i18n, issue))
                  .join(' · '),
      ),
      const SizedBox(height: 16),
      _saveButton(i18n),
      TextButton(
        onPressed: () => setState(() => _step = 0),
        child: Text(i18n.t('toolbox.sleep.day.back')),
      ),
    ],
  );

  Widget _saveButton(AppI18n i18n) => FilledButton.icon(
    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
    onPressed: _saved ? null : _save,
    icon: Icon(_saved ? Icons.check_rounded : Icons.save_rounded),
    label: Text(
      i18n.t(
        _saved
            ? 'toolbox.sleep.assessment.saved'
            : 'toolbox.sleep.assessment.save',
      ),
    ),
  );

  List<Widget> _detailFields(AppI18n i18n) => [
    SleepDayPanel(
      title: i18n.t('toolbox.sleep.assessment.currentGoal'),
      children: [
        TextField(
          controller: _goalController,
          decoration: InputDecoration(
            hintText: i18n.t('toolbox.sleep.assessment.goalHint'),
          ),
        ),
      ],
    ),
    for (final field in <(String, double, ValueChanged<double>)>[
      (
        'stressLoadLevel',
        _stressLoadLevel,
        (value) => _stressLoadLevel = value,
      ),
      (
        'screenDependenceLevel',
        _screenDependenceLevel,
        (value) => _screenDependenceLevel = value,
      ),
      (
        'lateWorkFrequency',
        _lateWorkFrequency,
        (value) => _lateWorkFrequency = value,
      ),
      (
        'exerciseLateFrequency',
        _exerciseLateFrequency,
        (value) => _exerciseLateFrequency = value,
      ),
      (
        'painImpactLevel',
        _painImpactLevel,
        (value) => _painImpactLevel = value,
      ),
    ])
      _score(i18n, field.$1, field.$2, field.$3),
    _contextFields(i18n),
  ];

  Widget _score(
    AppI18n i18n,
    String field,
    double value,
    ValueChanged<double> onChanged,
  ) => SleepDayPanel(
    title: sleepAssessmentFactorTitle(i18n, field),
    children: [
      Text(sleepAssessmentFactorHint(i18n, field)),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var number = 0; number <= 5; number++)
            ChoiceChip(
              label: Text(sleepIntensityLabel(i18n, number)),
              selected: value.round() == number,
              onSelected: (_) {
                setState(() => onChanged(number.toDouble()));
                _persistDraft();
              },
            ),
        ],
      ),
    ],
  );

  Widget _contextFields(AppI18n i18n) => SleepDayPanel(
    title: i18n.t('toolbox.sleep.assessment.riskAndContext'),
    children: [
      for (final item in <(String, bool, ValueChanged<bool>)>[
        ('racingThoughts', _hasRacingThoughts, (v) => _hasRacingThoughts = v),
        (
          'caffeineSensitive',
          _caffeineSensitive,
          (v) => _caffeineSensitive = v,
        ),
        ('bedroomBright', _bedroomLightIssue, (v) => _bedroomLightIssue = v),
        ('bedroomNoisy', _bedroomNoiseIssue, (v) => _bedroomNoiseIssue = v),
        ('bedroomTemp', _bedroomTempIssue, (v) => _bedroomTempIssue = v),
        ('shiftWork', _shiftWorkOrJetLag, (v) => _shiftWorkOrJetLag = v),
        (
          'digestiveDiscomfort',
          _refluxOrDigestiveDiscomfort,
          (v) => _refluxOrDigestiveDiscomfort = v,
        ),
        (
          'nightmares',
          _nightmaresOrDreamDistress,
          (v) => _nightmaresOrDreamDistress = v,
        ),
      ])
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(i18n.t('toolbox.sleep.assessment.${item.$1}')),
          value: item.$2,
          onChanged: (value) {
            setState(() => item.$3(value));
            _persistDraft();
          },
        ),
      Text(i18n.t('toolbox.sleep.assessment.snoringRisk')),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final risk in SleepRiskLevel.values)
            ChoiceChip(
              label: Text(sleepRiskLabel(i18n, risk)),
              selected: _snoringRisk == risk,
              onSelected: (_) {
                setState(() => _snoringRisk = risk);
                _persistDraft();
              },
            ),
        ],
      ),
    ],
  );
}
