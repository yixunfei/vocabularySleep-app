import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/module_system/module_id.dart';
import '../../i18n/app_i18n.dart';
import '../../services/sleep/sleep_log_draft.dart';
import '../../state/app_state.dart';
import '../../services/app_log_service.dart';
import '../module/module_access.dart';
import 'sleep_assistant_ui_support.dart';
import 'sleep_support/sleep_day_form_widgets.dart';
import 'sleep_support/sleep_log_detail_form.dart';
import 'toolbox_tool_shell.dart';

class SleepDailyLogPage extends StatefulWidget {
  const SleepDailyLogPage({super.key});
  @override
  State<SleepDailyLogPage> createState() => _SleepDailyLogPageState();
}

class _SleepDailyLogPageState extends State<SleepDailyLogPage> {
  late String _dateKey;
  late SleepLogDraft _draft;
  int _step = 0;
  bool _details = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    final selected = context
        .read<AppState>()
        .sleepDashboardState
        .selectedLogDateKey;
    final date = tryParseSleepDateKey(selected);
    _loadDate(
      date == null || date.isAfter(DateTime.now())
          ? todaySleepDateKey()
          : selected,
    );
  }

  void _loadDate(String key) {
    _dateKey = key;
    _draft = SleepLogDraft(
      dateKey: key,
      existing: context.read<AppState>().sleepDailyLogByDateKey(key),
    );
    _step = 0;
    _details = false;
    _saved = false;
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: tryParseSleepDateKey(_dateKey) ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (date == null || !mounted) return;
    setState(() => _loadDate(sleepDateKeyFromDateTime(date)));
  }

  void _answer(String field, int value) {
    setState(() {
      _draft.set(field, value);
      _saved = false;
      _step += 1;
    });
  }

  void _save(AppI18n i18n) {
    try {
      context.read<AppState>().saveSleepDailyLog(_draft.build());
      setState(() => _saved = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(i18n.t('toolbox.sleep.log.saved'))),
      );
    } catch (error, stackTrace) {
      AppLogService.instance.e(
        'SleepDailyLog',
        'Could not save diary',
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
          title: i18n.t('toolbox.sleep.log.title'),
          subtitle: i18n.t('toolbox.sleep.log.flow.intro'),
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
      OutlinedButton.icon(
        onPressed: _pickDate,
        icon: const Icon(Icons.calendar_month_rounded),
        label: Text(
          '${i18n.t('toolbox.sleep.log.editingDate')} ${sleepDateLabel(_dateKey)}',
        ),
      ),
      const SizedBox(height: 12),
      Text(i18n.t('toolbox.sleep.log.flow.intro')),
      const SizedBox(height: 12),
      if (_step < 3) _question(i18n) else _review(i18n),
      const SizedBox(height: 12),
      TextButton.icon(
        onPressed: () => setState(() => _details = !_details),
        icon: Icon(_details ? Icons.expand_less : Icons.tune_rounded),
        label: Text(i18n.t('toolbox.sleep.day.details')),
      ),
      if (_details)
        SleepLogDetailForm(
          key: ValueKey(_dateKey),
          draft: _draft,
          dateKey: _dateKey,
          i18n: i18n,
          onChanged: () => setState(() => _saved = false),
        ),
      if (_details && _step < 3) _saveButton(i18n),
    ],
  );

  Widget _question(AppI18n i18n) {
    final fields = ['morning_energy', 'daytime_sleepiness', 'night_wake_count'];
    final titles = [
      'toolbox.sleep.log.flow.energy',
      'toolbox.sleep.log.flow.sleepiness',
      'toolbox.sleep.log.flow.wakes',
    ];
    final field = fields[_step];
    final options = _step == 2 ? [0, 1, 2, 3, 4] : [1, 2, 3, 4, 5];
    return SleepDayPanel(
      title: i18n.t(titles[_step]),
      children: [
        for (final value in options)
          SleepDayChoice<int>(
            label: _optionLabel(i18n, value),
            value: value,
            selected: _draft.value(field) == value,
            onSelected: (value) => _answer(field, value),
          ),
        TextButton(
          onPressed: () => setState(() => _step += 1),
          child: Text(i18n.t('toolbox.sleep.day.skip')),
        ),
        if (_step > 0)
          TextButton(
            onPressed: () => setState(() => _step -= 1),
            child: Text(i18n.t('toolbox.sleep.day.back')),
          ),
      ],
    );
  }

  String _optionLabel(AppI18n i18n, int value) {
    if (_step == 2) {
      return i18n.t(
        'toolbox.sleep.log.flow.wake_count',
        params: {'count': value},
      );
    }
    final prefix = _step == 0 ? 'energy' : 'sleepiness';
    return i18n.t('toolbox.sleep.log.flow.$prefix.$value');
  }

  Widget _review(AppI18n i18n) => SleepDayPanel(
    title: i18n.t('toolbox.sleep.log.flow.review'),
    children: [
      for (final item in <(String, String)>[
        ('morning_energy', 'toolbox.sleep.log.morningEnergy'),
        ('daytime_sleepiness', 'toolbox.sleep.log.daytimeSleepiness'),
        ('night_wake_count', 'toolbox.sleep.log.wakeCount'),
      ])
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            '${i18n.t(item.$2)}: ${_draft.value(item.$1) ?? i18n.t('toolbox.sleep.day.unknown')}',
          ),
        ),
      _saveButton(i18n),
      TextButton(
        onPressed: () => setState(() => _step = 0),
        child: Text(i18n.t('toolbox.sleep.day.back')),
      ),
    ],
  );

  Widget _saveButton(AppI18n i18n) => FilledButton.icon(
    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
    onPressed: _saved || !_draft.changed ? null : () => _save(i18n),
    icon: Icon(_saved ? Icons.check_rounded : Icons.save_rounded),
    label: Text(
      i18n.t(
        _saved ? 'toolbox.sleep.log.saved' : 'toolbox.sleep.log.saveCurrent',
      ),
    ),
  );
}
