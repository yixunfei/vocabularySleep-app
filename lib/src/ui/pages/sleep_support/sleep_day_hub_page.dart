import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/module_system/module_id.dart';
import '../../../i18n/app_i18n.dart';
import '../../../state/app_state.dart';
import '../../module/module_access.dart';
import '../sleep_assessment_page.dart';
import '../sleep_daily_log_page.dart';
import '../sleep_day_rhythm_page.dart';
import '../sleep_report_page.dart';
import '../sleep_routine_library_page.dart';
import '../sleep_science_page.dart';
import '../toolbox_tool_shell.dart';

class SleepDayHubPage extends StatefulWidget {
  const SleepDayHubPage({super.key});

  @override
  State<SleepDayHubPage> createState() => _SleepDayHubPageState();
}

class _SleepDayHubPageState extends State<SleepDayHubPage> {
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final state = context.read<AppState>();
      if (state.isModuleEnabled(ModuleIds.toolboxSleepAssistant)) {
        await state.loadSleepAssistantData();
      }
    } on Object {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = context.select<AppState, String>((s) => s.uiLanguage);
    final enabled = context.select<AppState, bool>(
      (s) => s.isModuleEnabled(ModuleIds.toolboxSleepAssistant),
    );
    final i18n = AppI18n(language);
    return ToolboxToolPage(
      title: i18n.t('toolbox.sleep.day.title'),
      subtitle: i18n.t('toolbox.sleep.day.body'),
      showPageHeader: false,
      child: !enabled
          ? ModuleDisabledView(
              i18n: i18n,
              moduleId: ModuleIds.toolboxSleepAssistant,
            )
          : _content(context, i18n),
    );
  }

  Widget _content(BuildContext context, AppI18n i18n) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_failed) {
      return Column(
        children: [
          Text(i18n.t('toolbox.sleep.day.load_failed')),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _load,
            child: Text(i18n.t('toolbox.sleep.day.retry')),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          i18n.t('toolbox.sleep.day.body'),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 20),
        _entry(i18n, 'log', Icons.edit_note_rounded, const SleepDailyLogPage()),
        _entry(
          i18n,
          'rhythm',
          Icons.wb_sunny_outlined,
          const SleepDayRhythmPage(),
        ),
        _entry(
          i18n,
          'report',
          Icons.insights_outlined,
          const SleepReportPage(),
        ),
        _entry(
          i18n,
          'assessment',
          Icons.tune_rounded,
          const SleepAssessmentPage(),
        ),
        _entry(
          i18n,
          'routine',
          Icons.bedtime_outlined,
          const SleepRoutineLibraryPage(),
        ),
        _entry(
          i18n,
          'science',
          Icons.menu_book_outlined,
          const SleepSciencePage(),
        ),
      ],
    );
  }

  Widget _entry(AppI18n i18n, String name, IconData icon, Widget page) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        margin: EdgeInsets.zero,
        child: ListTile(
          key: ValueKey('sleep-day-$name'),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Icon(icon),
          title: Text(i18n.t('toolbox.sleep.day.$name')),
          subtitle: Text(i18n.t('toolbox.sleep.day.$name.hint')),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (_) => page)),
        ),
      ),
    );
  }
}
