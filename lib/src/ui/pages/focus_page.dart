import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/module_system/module_id.dart';
import '../../i18n/app_i18n.dart';
import '../../models/focus_startup_tab.dart';
import '../../models/play_config.dart';
import '../../models/todo_item.dart';
import '../../models/tomato_timer.dart';
import '../../services/focus_service.dart';
import '../../services/system_speech_service.dart';
import '../../services/todo_reminder_service.dart';
import '../../state/app_state.dart';
import '../../state/app_state_provider.dart';
import '../../utils/asr_language.dart';
import '../layout/app_width_tier.dart';
import '../module/module_access.dart';
import '../sheets/ambient_sheet.dart';
import '../ui_copy.dart';
import '../widgets/section_header.dart';
import 'focus_page_controller.dart';
import 'focus_timer_widgets.dart';

part 'focus_page_dialogs.dart';
part 'focus_page_notes.dart';
part 'focus_page_support.dart';
part 'focus_page_timer.dart';
part 'focus_page_workspace.dart';
part 'focus_page_workspace_todo.dart';
part 'focus_page_workspace_notes.dart';
part 'focus_page_workspace_editor.dart';

enum _TodoSortMode { manual, priority, category }

enum _TodoFilterMode { all, active, today, overdue, deferred, completed }

enum _TodoViewMode { plan, list }

enum _TodoDraftState { active, deferred, completed }

enum _TodoSystemCalendarAlertMode { notification, alarm }

enum _NoteVoiceInputState { idle, starting, listening, finishing }

class FocusPage extends ConsumerStatefulWidget {
  const FocusPage({super.key});

  @override
  ConsumerState<FocusPage> createState() => _FocusPageState();
}

class _FocusPageState extends ConsumerState<FocusPage>
    with
        SingleTickerProviderStateMixin,
        _FocusPageDialogsMixin,
        _FocusPageSupportMixin {
  static const List<int> _todoPalette = <int>[
    0xFFFDE68A,
    0xFFBFDBFE,
    0xFFC7D2FE,
    0xFFBBF7D0,
    0xFFFBCFE8,
    0xFFFED7AA,
  ];

  late final TabController _tabController;
  late final FocusPageController _pageController;
  final SystemSpeechService _systemSpeech = const PlatformSystemSpeechService();
  final Set<int> _selectedNoteIds = <int>{};
  bool _noteSelectionMode = false;
  _TodoSortMode _todoSortMode = _TodoSortMode.manual;
  _TodoFilterMode _todoFilterMode = _TodoFilterMode.all;
  _TodoViewMode _todoViewMode = _TodoViewMode.list;
  String? _expandedTodoMetricKey;
  bool _todoMetricsExpanded = false;
  double _notesDrawerProgress = 0;
  bool _notesDrawerDragging = false;
  bool _ambientLauncherExpanded = false;

  @override
  void initState() {
    super.initState();
    _pageController = FocusPageController();
    _tabController = TabController(length: 2, initialIndex: 1, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final focus = ref.read(appStateProvider).focusService;
    if (!_pageController.bindFocusService(
      focus,
      onPhaseComplete: _onPhaseComplete,
    )) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _maybeOpenPendingTodoReminder();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _tabController.dispose();
    unawaited(_systemSpeech.dispose());
    super.dispose();
  }

  void _onPhaseComplete(TomatoTimerPhase phase, int _) {
    if (!mounted) return;
    final state = ref.read(appStateProvider);
    final i18n = AppI18n(state.uiLanguage);
    if (state.focusService.config.reminder.visual) {
      _pageController.startVisualReminder(
        phase,
        refresh: () {
          if (!mounted) return;
          setState(() {});
        },
      );
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          phase == TomatoTimerPhase.focus
              ? i18n.t('focusPhaseComplete')
              : i18n.t('breakPhaseComplete'),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
    if (state.focusService.reminderAcknowledgementPending) {
      unawaited(
        _showReminderAcknowledgementDialog(state.focusService, phase, i18n),
      );
    }
  }

  Future<void> _maybeOpenPendingTodoReminder() async {
    final state = ref.read(appStateProvider);
    final action = await state.focusService.consumePendingTodoReminderAction();
    final fallbackTodoId = state.consumePendingTodoReminderLaunchId();
    final todoId = action?.todoId ?? fallbackTodoId;
    if (todoId == null || todoId <= 0) {
      return;
    }
    if (!_pageController.tryMarkReminderOpened(todoId)) {
      return;
    }
    final focus = state.focusService;
    final todo = focus
        .getTodos()
        .where((item) => item.id == todoId)
        .cast<TodoItem?>()
        .firstOrNull;
    if (todo == null) {
      return;
    }
    _tabController.animateTo(1);
    if (_todoViewMode != _TodoViewMode.list ||
        _todoFilterMode == _TodoFilterMode.completed) {
      setState(() {
        _todoViewMode = _TodoViewMode.list;
        if (_todoFilterMode == _TodoFilterMode.completed) {
          _todoFilterMode = _TodoFilterMode.active;
        }
      });
    }
    _highlightAndScrollToTodo(todoId);
    switch (action?.type) {
      case TodoReminderActionType.detail:
        unawaited(
          _showTodoEditor(focus, AppI18n(state.uiLanguage), todo: todo),
        );
        break;
      case TodoReminderActionType.complete:
        focus.completeTodo(todoId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                pickUiText(
                  AppI18n(state.uiLanguage),
                  zh: '待办已完成：${todo.content}',
                  en: 'Todo completed: ${todo.content}',
                ),
              ),
            ),
          );
        }
        break;
      case TodoReminderActionType.snooze:
        focus.snoozeTodoReminder(
          todoId,
          Duration(minutes: action?.snoozeMinutes ?? 10),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                pickUiText(
                  AppI18n(state.uiLanguage),
                  zh: '提醒已稍后 ${action?.snoozeMinutes ?? 10} 分钟',
                  en: 'Reminder snoozed for ${action?.snoozeMinutes ?? 10} minutes',
                ),
              ),
            ),
          );
        }
        break;
      case TodoReminderActionType.open:
      case null:
        break;
    }
  }

  void _highlightAndScrollToTodo(int todoId) {
    _pageController.highlightTodo(
      todoId,
      refresh: () {
        if (!mounted) return;
        setState(() {});
      },
      ensureVisible: () {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          final targetContext = _pageController
              .todoCardKey(todoId)
              .currentContext;
          if (targetContext != null) {
            Scrollable.ensureVisible(
              targetContext,
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              alignment: 0.18,
            );
          }
        });
      },
    );
  }

  Future<void> _showReminderAcknowledgementDialog(
    FocusService focus,
    TomatoTimerPhase phase,
    AppI18n i18n,
  ) async {
    if (_pageController.reminderDialogVisible || !mounted) {
      return;
    }
    _pageController.setReminderDialogVisible(true);
    final acknowledged = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            title: Text(
              phase == TomatoTimerPhase.focus
                  ? i18n.t('focusPhaseComplete')
                  : i18n.t('breakPhaseComplete'),
            ),
            content: Text(
              pickUiText(
                i18n,
                zh: '提醒会持续到你确认，或在超时后自动停止。',
                en: 'The reminder keeps playing until you confirm it, or it times out automatically.',
                ja: 'リマインダーは確認するまで続き、一定時間後に自動停止します。',
                de: 'Die Erinnerung laeuft weiter, bis du bestaetigst oder das Zeitlimit erreicht ist.',
                fr: 'Le rappel continue jusqu’a confirmation ou jusqu’a l’arret automatique apres delai.',
                es: 'El aviso seguira activo hasta que lo confirmes o se detendra al agotarse el tiempo.',
                ru: 'Напоминание будет продолжаться, пока вы не подтвердите его, либо остановится по тайм-ауту.',
              ),
            ),
            actions: <Widget>[
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(
                  pickUiText(
                    i18n,
                    zh: '知道了',
                    en: 'Acknowledge',
                    ja: '確認しました',
                    de: 'Bestaetigen',
                    fr: 'Confirmer',
                    es: 'Confirmar',
                    ru: 'Подтвердить',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
    _pageController.setReminderDialogVisible(false);
    if (!mounted || acknowledged != true) {
      return;
    }
    await focus.acknowledgeReminder();
  }

  void _setViewState(VoidCallback apply) => setState(apply);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final i18n = AppI18n(state.uiLanguage);
    if (!state.isModuleEnabled(ModuleIds.focus)) {
      return ModuleDisabledView(i18n: i18n, moduleId: ModuleIds.focus);
    }
    _syncConfiguredStartupTab(state.focusStartupTab);
    final focus = state.focusService;
    final timerListenable = Listenable.merge(<Listenable>[
      focus.timerListenable,
      focus.viewRevision,
    ]);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 52,
        titleSpacing: 14,
        scrolledUnderElevation: 0,
        title: Text(i18n.t('focusTitle')),
        bottom: TabBar(
          controller: _tabController,
          labelStyle: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
          unselectedLabelStyle: Theme.of(context).textTheme.labelMedium,
          indicatorWeight: 2,
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: Theme.of(context).colorScheme.outlineVariant,
          tabs: <Widget>[
            Tab(
              height: 54,
              icon: const Icon(Icons.hourglass_bottom_rounded),
              iconMargin: const EdgeInsets.only(bottom: 2),
              text: i18n.t('timerTab'),
            ),
            Tab(
              height: 54,
              icon: const Icon(Icons.view_week_rounded),
              iconMargin: const EdgeInsets.only(bottom: 2),
              text: i18n.t('todoTab'),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const BouncingScrollPhysics(),
        children: <Widget>[
          KeyedSubtree(
            key: const ValueKey<String>('focus-timer-tab'),
            child: ListenableBuilder(
              listenable: timerListenable,
              builder: (context, _) => _buildTimerTab(state, focus, i18n),
            ),
          ),
          KeyedSubtree(
            key: const ValueKey<String>('focus-workspace-tab'),
            child: ValueListenableBuilder<int>(
              valueListenable: focus.viewRevision,
              builder: (context, _, _) {
                final notes = focus.getNotes();
                _selectedNoteIds.removeWhere(
                  (id) => !notes.any((note) => note.id == id),
                );
                return _buildWorkspaceTab(focus, notes, i18n);
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget _buildNotesSheetContent(
    FocusService focus,
    List<PlanNote> notes,
    AppI18n i18n,
  ) => _buildNotesSheetContentImpl(focus, notes, i18n);
}
