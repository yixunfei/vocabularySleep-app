import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/module_system/module_id.dart';
import '../../../i18n/app_i18n.dart';
import '../../../models/sleep_daily_log.dart';
import '../../../models/sleep_support_session.dart';
import '../../../services/sleep/sleep_support_session_controller.dart';
import '../../../state/app_state.dart';
import '../../module/module_access.dart';
import '../sleep_assistant_ui_support.dart';
import 'sleep_night_stage.dart';

class SleepSupportGuidePage extends StatefulWidget {
  const SleepSupportGuidePage({
    super.key,
    required this.intent,
    this.initialMode,
  });

  final SleepSupportIntent intent;
  final SleepNightRescueMode? initialMode;

  @override
  State<SleepSupportGuidePage> createState() => _SleepSupportGuidePageState();
}

class _SleepSupportGuidePageState extends State<SleepSupportGuidePage> {
  late final SleepSupportSessionController _controller;
  bool _continuePrevious = false;
  bool _exitPending = false;

  @override
  void initState() {
    super.initState();
    final appState = context.read<AppState>();
    _controller = appState.sleepSupportSessionController;
    if (appState.isModuleEnabled(ModuleIds.toolboxSleepAssistant)) {
      _controller.start(widget.intent, initialMode: widget.initialMode);
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = context.select<AppState, String>((s) => s.uiLanguage);
    final enabled = context.select<AppState, bool>(
      (s) => s.isModuleEnabled(ModuleIds.toolboxSleepAssistant),
    );
    final i18n = AppI18n(language);
    return sleepModuleTheme(
      context: context,
      enabled: true,
      child: Builder(
        builder: (context) => ListenableBuilder(
          listenable: _controller,
          builder: (context, _) => _buildScaffold(context, i18n, enabled),
        ),
      ),
    );
  }

  Widget _buildScaffold(BuildContext context, AppI18n i18n, bool enabled) {
    final state = _controller.state;
    final resting = state?.isResting == true && state?.isFinished != true;
    return Scaffold(
      backgroundColor: resting
          ? Theme.of(context).colorScheme.surfaceContainerLowest
          : null,
      appBar: resting
          ? null
          : AppBar(
              title: Text(i18n.t('toolbox.sleep.core.title')),
              actions: [
                if (enabled && state != null)
                  TextButton(
                    onPressed: state.isPersisting ? null : _finish,
                    child: Text(i18n.t('toolbox.sleep.night.exit')),
                  ),
              ],
            ),
      body: SafeArea(
        child: !enabled
            ? ModuleDisabledView(
                i18n: i18n,
                moduleId: ModuleIds.toolboxSleepAssistant,
              )
            : _buildSession(context, i18n, state),
      ),
    );
  }

  Widget _buildSession(
    BuildContext context,
    AppI18n i18n,
    SleepSupportSession? state,
  ) {
    if (state == null) return const SizedBox.shrink();
    if (state.isFinished) {
      return SleepNightSaveStatus(
        i18n: i18n,
        saving: state.isPersisting,
        failed: state.saveFailed,
        onRetry: _retry,
        onLeave: _leaveWithoutSaving,
        onDone: () => _closeAfterSave(true),
      );
    }
    if (state.intent != widget.intent && !_continuePrevious) {
      return SleepPreviousSession(
        i18n: i18n,
        onResume: () => setState(() => _continuePrevious = true),
        onReplace: () {
          _controller.discard();
          _controller.start(widget.intent, initialMode: widget.initialMode);
        },
      );
    }
    return SleepNightStage(
      i18n: i18n,
      session: state,
      onChoice: _controller.choose,
      onSkip: _controller.skip,
      onChangeMethod: _controller.changeMethod,
      onRest: _controller.rest,
      onResume: _controller.resumeGuide,
      onFinish: _finish,
    );
  }

  Future<void> _finish() async {
    if (_exitPending) return;
    _exitPending = true;
    final saved = await _controller.finish();
    _closeAfterSave(saved);
  }

  Future<void> _retry() async {
    if (_exitPending) return;
    _exitPending = true;
    final saved = await _controller.retrySave();
    _closeAfterSave(saved);
  }

  void _closeAfterSave(bool saved) {
    if (!mounted) return;
    if (saved && ModalRoute.of(context)?.isCurrent == true) {
      // Ending the support flow also ends the sound started by this module.
      // The controller is module-owned, so unrelated audio remains untouched.
      context.read<AppState>().sleepSoundController.stop();
      Navigator.of(context).pop();
    } else {
      _exitPending = false;
    }
  }

  void _leaveWithoutSaving() {
    if (_exitPending) return;
    _exitPending = true;
    _controller.discard();
    context.read<AppState>().sleepSoundController.stop();
    Navigator.of(context).pop();
  }
}
