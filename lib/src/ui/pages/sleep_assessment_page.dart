import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/module_system/module_id.dart';
import '../../i18n/app_i18n.dart';
import '../../models/sleep_profile.dart';
import '../../state/app_state.dart';
import '../module/module_access.dart';
import 'sleep_research_library.dart';
import 'sleep_assistant_ui_support.dart';
import 'toolbox_tool_shell.dart';

class SleepAssessmentPage extends StatefulWidget {
  const SleepAssessmentPage({super.key});

  @override
  State<SleepAssessmentPage> createState() => _SleepAssessmentPageState();
}

class _SleepAssessmentPageState extends State<SleepAssessmentPage> {
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
    context.read<AppState>().updateSleepAssessmentDraft(_draft);
  }

  Future<void> _pickTime({required bool bedtime}) async {
    final current = bedtime
        ? (_bedtime ?? const TimeOfDay(hour: 23, minute: 0))
        : (_wakeTime ?? const TimeOfDay(hour: 7, minute: 30));
    final picked = await showTimePicker(context: context, initialTime: current);
    if (picked == null) {
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
    final i18n = AppI18n(appState.uiLanguage);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          i18n.t('toolbox.sleep.assessment.saved'),
        ),
      ),
    );
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
    final adviceItems = buildSleepAssessmentAdvice(i18n, draft: _draft);
    return themed(
      ToolboxToolPage(
        title: i18n.t('toolbox.sleep.assessment.title'),
        subtitle: i18n.t('toolbox.sleep.assessment.intro'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      i18n.t('toolbox.sleep.assessment.mainConcerns'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: SleepIssueType.values
                          .map(
                            (issue) => FilterChip(
                              label: Text(sleepIssueLabel(i18n, issue)),
                              selected: _selectedIssues.contains(issue),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedIssues.add(issue);
                                  } else {
                                    _selectedIssues.remove(issue);
                                  }
                                });
                                _persistDraft();
                              },
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
                      i18n.t('toolbox.sleep.assessment.baselineSchedule'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        i18n.t('toolbox.sleep.assessment.typicalBedtime'),
                      ),
                      subtitle: Text(sleepTimeOfDayLabel(_bedtime)),
                      trailing: const Icon(Icons.schedule_rounded),
                      onTap: () => _pickTime(bedtime: true),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        i18n.t('toolbox.sleep.assessment.typicalWakeTime'),
                      ),
                      subtitle: Text(sleepTimeOfDayLabel(_wakeTime)),
                      trailing: const Icon(Icons.alarm_rounded),
                      onTap: () => _pickTime(bedtime: false),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _goalController,
                      maxLines: 2,
                      decoration: InputDecoration(
                         labelText: i18n.t('toolbox.sleep.assessment.currentGoal'),
                         hintText: i18n.t('toolbox.sleep.assessment.goalHint'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _AssessmentSliderCard(
              i18n: i18n,
              title: sleepAssessmentFactorTitle(i18n, 'stressLoadLevel'),
              hint: sleepAssessmentFactorHint(i18n, 'stressLoadLevel'),
              value: _stressLoadLevel,
              status: sleepIntensityLabel(i18n, _stressLoadLevel.round()),
              onChanged: (value) {
                setState(() => _stressLoadLevel = value);
                _persistDraft();
              },
            ),
            const SizedBox(height: 12),
            _AssessmentSliderCard(
              i18n: i18n,
              title: sleepAssessmentFactorTitle(i18n, 'screenDependenceLevel'),
              hint: sleepAssessmentFactorHint(i18n, 'screenDependenceLevel'),
              value: _screenDependenceLevel,
              status: sleepIntensityLabel(i18n, _screenDependenceLevel.round()),
              onChanged: (value) {
                setState(() => _screenDependenceLevel = value);
                _persistDraft();
              },
            ),
            const SizedBox(height: 12),
            _AssessmentSliderCard(
              i18n: i18n,
              title: sleepAssessmentFactorTitle(i18n, 'lateWorkFrequency'),
              hint: sleepAssessmentFactorHint(i18n, 'lateWorkFrequency'),
              value: _lateWorkFrequency,
              status: sleepFrequencyLabel(i18n, _lateWorkFrequency.round()),
              onChanged: (value) {
                setState(() => _lateWorkFrequency = value);
                _persistDraft();
              },
            ),
            const SizedBox(height: 12),
            _AssessmentSliderCard(
              i18n: i18n,
              title: sleepAssessmentFactorTitle(i18n, 'exerciseLateFrequency'),
              hint: sleepAssessmentFactorHint(i18n, 'exerciseLateFrequency'),
              value: _exerciseLateFrequency,
              status: sleepFrequencyLabel(i18n, _exerciseLateFrequency.round()),
              onChanged: (value) {
                setState(() => _exerciseLateFrequency = value);
                _persistDraft();
              },
            ),
            const SizedBox(height: 12),
            _AssessmentSliderCard(
              i18n: i18n,
              title: sleepAssessmentFactorTitle(i18n, 'painImpactLevel'),
              hint: sleepAssessmentFactorHint(i18n, 'painImpactLevel'),
              value: _painImpactLevel,
              status: sleepIntensityLabel(i18n, _painImpactLevel.round()),
              onChanged: (value) {
                setState(() => _painImpactLevel = value);
                _persistDraft();
              },
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      i18n.t('toolbox.sleep.assessment.riskAndContext'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        i18n.t('toolbox.sleep.assessment.racingThoughts'),
                      ),
                      value: _hasRacingThoughts,
                      onChanged: (value) {
                        setState(() => _hasRacingThoughts = value);
                        _persistDraft();
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        i18n.t('toolbox.sleep.assessment.caffeineSensitive'),
                      ),
                      value: _caffeineSensitive,
                      onChanged: (value) {
                        setState(() => _caffeineSensitive = value);
                        _persistDraft();
                      },
                    ),
                    DropdownButtonFormField<SleepRiskLevel>(
                      initialValue: _snoringRisk,
                      decoration: InputDecoration(
                         labelText: i18n.t('toolbox.sleep.assessment.snoringRisk'),
                      ),
                      items: SleepRiskLevel.values
                          .map(
                            (item) => DropdownMenuItem<SleepRiskLevel>(
                              value: item,
                              child: Text(sleepRiskLabel(i18n, item)),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setState(() => _snoringRisk = value);
                        _persistDraft();
                      },
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        i18n.t('toolbox.sleep.assessment.bedroomBright'),
                      ),
                      value: _bedroomLightIssue,
                      onChanged: (value) {
                        setState(() => _bedroomLightIssue = value);
                        _persistDraft();
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        i18n.t('toolbox.sleep.assessment.bedroomNoisy'),
                      ),
                      value: _bedroomNoiseIssue,
                      onChanged: (value) {
                        setState(() => _bedroomNoiseIssue = value);
                        _persistDraft();
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        i18n.t('toolbox.sleep.assessment.bedroomTemp'),
                      ),
                      value: _bedroomTempIssue,
                      onChanged: (value) {
                        setState(() => _bedroomTempIssue = value);
                        _persistDraft();
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        i18n.t('toolbox.sleep.assessment.shiftWork'),
                      ),
                      value: _shiftWorkOrJetLag,
                      onChanged: (value) {
                        setState(() => _shiftWorkOrJetLag = value);
                        _persistDraft();
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        i18n.t('toolbox.sleep.assessment.digestiveDiscomfort'),
                      ),
                      value: _refluxOrDigestiveDiscomfort,
                      onChanged: (value) {
                        setState(() => _refluxOrDigestiveDiscomfort = value);
                        _persistDraft();
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        i18n.t('toolbox.sleep.assessment.nightmares'),
                      ),
                      value: _nightmaresOrDreamDistress,
                      onChanged: (value) {
                        setState(() => _nightmaresOrDreamDistress = value);
                        _persistDraft();
                      },
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
                      i18n.t('toolbox.sleep.assessment.directAdvice'),
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
              label: Text(
                i18n.t('toolbox.sleep.assessment.save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssessmentSliderCard extends StatelessWidget {
  const _AssessmentSliderCard({
    required this.i18n,
    required this.title,
    required this.hint,
    required this.value,
    required this.status,
    required this.onChanged,
  });

  final AppI18n i18n;
  final String title;
  final String hint;
  final double value;
  final String status;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Chip(label: Text(status)),
              ],
            ),
            const SizedBox(height: 6),
            Text(hint, style: Theme.of(context).textTheme.bodySmall),
            Slider(
              value: value,
              min: 0,
              max: 5,
              divisions: 5,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}
