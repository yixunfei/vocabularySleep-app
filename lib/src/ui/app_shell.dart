import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/module_system/module_id.dart';
import '../i18n/app_i18n.dart';
import '../models/app_home_tab.dart';
import '../models/study_startup_tab.dart';
import '../models/todo_item.dart';
import '../models/weather_snapshot.dart';
import '../state/app_state.dart';
import '../state/app_state_provider.dart';
import 'module/module_access.dart';
import 'pages/focus_page.dart';
import 'pages/more_page.dart';
import 'pages/practice_page.dart';
import 'pages/study_page.dart';
import 'pages/toolbox_page.dart';
import 'pages/toolbox_soothing_music/runtime_store.dart';
import 'pages/toolbox_soothing_music_v2_page.dart';
import 'ui_copy.dart';
import 'widgets/app_background.dart';
import 'widgets/ambient_floating_dock.dart';
import 'widgets/busy_overlay.dart';
import 'widgets/focus_lock_overlay.dart';
import 'widgets/mini_player.dart';
import 'widgets/soothing_mini_player.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  static const double _navigationBarHeight = 80;
  static const Duration _navigationChromeDuration = Duration(milliseconds: 250);
  static const double _navigationTapSlop = 12;

  int _index = 0;
  List<AppHomeTab> _visibleTabs = List<AppHomeTab>.from(AppHomeTab.values);
  StudyStartupTab _studyTab = StudyStartupTab.play;
  double _miniPlayerReservedHeight = 0;
  double _soothingMiniPlayerReservedHeight = 0;
  Offset? _navigationPointerStart;
  bool _navigationPointerMoved = false;
  bool _navigationBarVisible = true;
  VoidCallback? _scrollLibraryToTop;
  bool _exitDialogVisible = false;
  bool _startupPromptShown = false;
  int? _lastHandledTodoReminderLaunchId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = ref.read(appStateProvider);
      state.init().then((_) {
        if (!mounted) return;
        final visibleTabs = _resolveVisibleTabs(state);
        final nextIndex = _resolveStartupIndex(state, visibleTabs);
        setState(() {
          _visibleTabs = visibleTabs;
          _index = nextIndex;
          _studyTab = state.studyStartupTab;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          unawaited(_maybeShowStartupTodoPrompt());
        });
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  List<AppHomeTab> _resolveVisibleTabs(AppState state) {
    final visible = <AppHomeTab>[
      for (final tab in AppHomeTab.values)
        if (state.isModuleEnabled(_moduleIdForTab(tab))) tab,
    ];
    if (!visible.contains(AppHomeTab.more)) {
      visible.add(AppHomeTab.more);
    }
    return visible;
  }

  int _resolveStartupIndex(AppState state, List<AppHomeTab> visibleTabs) {
    if (visibleTabs.isEmpty) {
      return 0;
    }
    final desired = state.startupPage;
    final desiredIndex = visibleTabs.indexOf(desired);
    if (desiredIndex >= 0) {
      return desiredIndex;
    }
    final focusIndex = visibleTabs.indexOf(AppHomeTab.focus);
    if (focusIndex >= 0) {
      return focusIndex;
    }
    return 0;
  }

  String _moduleIdForTab(AppHomeTab tab) {
    return switch (tab) {
      AppHomeTab.study => ModuleIds.study,
      AppHomeTab.practice => ModuleIds.practice,
      AppHomeTab.focus => ModuleIds.focus,
      AppHomeTab.toolbox => ModuleIds.toolbox,
      AppHomeTab.more => ModuleIds.more,
    };
  }

  int _indexForTab(AppHomeTab tab) => _visibleTabs.indexOf(tab);

  AppHomeTab _tabAt(int index) {
    if (index >= 0 && index < _visibleTabs.length) {
      return _visibleTabs[index];
    }
    return _visibleTabs.isEmpty ? AppHomeTab.more : _visibleTabs.first;
  }

  void _setTab(AppHomeTab tab) {
    final index = _indexForTab(tab);
    if (index < 0) {
      return;
    }
    _setIndex(index);
  }

  Future<void> _maybeShowStartupTodoPrompt() async {
    if (_startupPromptShown || !mounted) {
      return;
    }
    final state = ref.read(appStateProvider);
    if (!state.shouldShowStartupTodoPromptToday) {
      return;
    }

    _startupPromptShown = true;
    unawaited(state.refreshStartupTodoPromptContent(force: true));

    var suppressForToday = false;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return Consumer(
              builder: (dialogContext, ref, _) {
                final state = ref.watch(appStateProvider);
                final i18n = AppI18n(state.uiLanguage);
                return AlertDialog(
                  key: const ValueKey<String>('startup-todo-prompt-dialog'),
                  title: Text(
                    i18n.t('inline.ui.app_shell.today_at_a_glance_badd58'),
                  ),
                  content: SizedBox(
                    width: 440,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _buildStartupPromptTodoSection(i18n, state),
                          const SizedBox(height: 16),
                          _buildStartupPromptQuoteSection(i18n, state),
                          const SizedBox(height: 16),
                          _buildStartupPromptWeatherSection(i18n, state),
                          const SizedBox(height: 12),
                          CheckboxListTile.adaptive(
                            key: const ValueKey<String>(
                              'startup-todo-prompt-dont-show',
                            ),
                            contentPadding: EdgeInsets.zero,
                            value: suppressForToday,
                            title: Text(
                              i18n.t(
                                'inline.ui.app_shell.don_t_show_again_today_698b48',
                              ),
                            ),
                            onChanged: (value) {
                              setDialogState(() {
                                suppressForToday = value ?? false;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: <Widget>[
                    FilledButton(
                      key: const ValueKey<String>('startup-todo-prompt-close'),
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: Text(i18n.t('close')),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
    if (!mounted || !suppressForToday) {
      return;
    }
    state.suppressStartupTodoPromptForToday();
  }

  void _setIndex(int index) {
    _setNavigationBarVisible(true);
    final currentTab = _tabAt(_index);
    final nextTab = _tabAt(index);
    if (_index == index) {
      if (nextTab == AppHomeTab.study && _studyTab == StudyStartupTab.library) {
        _scrollLibraryToTop?.call();
      }
      return;
    }
    setState(() {
      _index = index;
    });
    if (currentTab != nextTab) {
      ref.read(appStateProvider).setStartupPage(nextTab);
    }
  }

  void _setStudyTab(StudyStartupTab tab) {
    if (_studyTab == tab) {
      if (tab == StudyStartupTab.library) {
        _scrollLibraryToTop?.call();
      }
      return;
    }
    setState(() {
      _studyTab = tab;
    });
    ref.read(appStateProvider).setStudyStartupTab(tab);
  }

  void _setNavigationBarVisible(bool visible) {
    if (_navigationBarVisible == visible || !mounted) {
      return;
    }
    setState(() {
      _navigationBarVisible = visible;
    });
  }

  void _handleNavigationPointerDown(
    PointerDownEvent event,
    bool autoHideEnabled,
  ) {
    if (!autoHideEnabled) {
      _clearNavigationPointerTracking();
      return;
    }
    _navigationPointerStart = event.position;
    _navigationPointerMoved = false;
  }

  void _handleNavigationPointerMove(PointerMoveEvent event) {
    final start = _navigationPointerStart;
    if (start == null || _navigationPointerMoved) {
      return;
    }
    final offset = event.position - start;
    if (offset.distanceSquared > _navigationTapSlop * _navigationTapSlop) {
      _navigationPointerMoved = true;
    }
  }

  void _handleNavigationPointerUp(bool autoHideEnabled) {
    final shouldReveal =
        autoHideEnabled &&
        _navigationPointerStart != null &&
        !_navigationPointerMoved;
    _clearNavigationPointerTracking();
    if (shouldReveal) {
      _setNavigationBarVisible(true);
    }
  }

  void _clearNavigationPointerTracking() {
    _navigationPointerStart = null;
    _navigationPointerMoved = false;
  }

  bool _handleNavigationScrollNotification(
    ScrollNotification notification,
    bool autoHideEnabled,
  ) {
    if (notification.metrics.axis != Axis.vertical) {
      return false;
    }
    if (!autoHideEnabled) {
      if (!_navigationBarVisible) {
        _setNavigationBarVisible(true);
      }
      return false;
    }

    if (notification is ScrollStartNotification) {
      return false;
    }

    if (notification is ScrollUpdateNotification) {
      final delta = notification.scrollDelta ?? 0;
      if (delta > 4 && notification.metrics.extentAfter > 0) {
        _setNavigationBarVisible(false);
      } else if (delta < -2) {
        _setNavigationBarVisible(true);
      }
      return false;
    }

    if (notification is OverscrollNotification && notification.overscroll < 0) {
      _setNavigationBarVisible(true);
      return false;
    }

    return false;
  }

  void _handlePendingTodoReminderLaunch(AppState state) {
    final pendingTodoId = state.pendingTodoReminderLaunchId;
    if (pendingTodoId == null || pendingTodoId <= 0) {
      return;
    }
    if (_lastHandledTodoReminderLaunchId == pendingTodoId) {
      return;
    }
    _lastHandledTodoReminderLaunchId = pendingTodoId;
    if (_indexForTab(AppHomeTab.focus) < 0 ||
        _tabAt(_index) == AppHomeTab.focus) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _setTab(AppHomeTab.focus);
    });
  }

  Widget _buildPageForTab(AppHomeTab tab) {
    return switch (tab) {
      AppHomeTab.study => StudyPage(
        selectedTab: _studyTab,
        onSelectTab: _setStudyTab,
        onOpenPractice: () => _setTab(AppHomeTab.practice),
        onAttachLibraryScrollToTop: (callback) {
          _scrollLibraryToTop = callback;
        },
      ),
      AppHomeTab.practice => const PracticePage(),
      AppHomeTab.focus => const FocusPage(),
      AppHomeTab.toolbox => const ToolboxPage(),
      AppHomeTab.more => const MorePage(),
    };
  }

  NavigationDestination _buildNavigationDestination(
    AppHomeTab tab,
    AppI18n i18n,
  ) {
    return switch (tab) {
      AppHomeTab.study => NavigationDestination(
        icon: const Icon(Icons.auto_stories_outlined),
        selectedIcon: const Icon(Icons.auto_stories_rounded),
        label: pageLabelStudy(i18n),
      ),
      AppHomeTab.practice => NavigationDestination(
        icon: const Icon(Icons.fitness_center_outlined),
        selectedIcon: const Icon(Icons.fitness_center_rounded),
        label: pageLabelPractice(i18n),
      ),
      AppHomeTab.focus => NavigationDestination(
        icon: const Icon(Icons.timer_outlined),
        selectedIcon: const Icon(Icons.timer_rounded),
        label: pageLabelFocus(i18n),
      ),
      AppHomeTab.toolbox => NavigationDestination(
        icon: const Icon(Icons.handyman_outlined),
        selectedIcon: const Icon(Icons.handyman_rounded),
        label: pageLabelToolbox(i18n),
      ),
      AppHomeTab.more => NavigationDestination(
        icon: const Icon(Icons.widgets_outlined),
        selectedIcon: const Icon(Icons.widgets_rounded),
        label: pageLabelMore(i18n),
      ),
    };
  }

  Widget _buildBottomNavigationChrome({
    required double height,
    required double bottomInset,
    required int selectedIndex,
    required AppI18n i18n,
    required bool visible,
  }) {
    return AnimatedContainer(
      key: const ValueKey<String>('app-shell-bottom-navigation-chrome'),
      duration: _navigationChromeDuration,
      curve: Curves.easeOutCubic,
      height: height,
      child: ClipRect(
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: <Widget>[
            Positioned(
              left: 0,
              right: 0,
              bottom: bottomInset,
              child: AnimatedOpacity(
                key: const ValueKey<String>(
                  'app-shell-bottom-navigation-opacity',
                ),
                duration: _navigationChromeDuration,
                curve: Curves.easeOutCubic,
                opacity: visible ? 1 : 0,
                child: IgnorePointer(
                  ignoring: !visible,
                  child: NavigationBar(
                    key: const ValueKey<String>(
                      'app-shell-bottom-navigation-bar',
                    ),
                    height: _navigationBarHeight,
                    selectedIndex: selectedIndex,
                    onDestinationSelected: _setIndex,
                    destinations: _visibleTabs
                        .map((tab) => _buildNavigationDestination(tab, i18n))
                        .toList(growable: false),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleMiniPlayerPresentation(
    bool visible,
    bool collapsed,
    double reservedHeight,
  ) {
    final nextHeight = visible && !collapsed ? reservedHeight : 0.0;
    if ((_miniPlayerReservedHeight - nextHeight).abs() < 0.5) {
      return;
    }
    setState(() {
      _miniPlayerReservedHeight = nextHeight;
    });
  }

  void _handleSoothingMiniPlayerPresentation(
    bool visible,
    double reservedHeight,
  ) {
    final nextHeight = visible ? reservedHeight : 0.0;
    if ((_soothingMiniPlayerReservedHeight - nextHeight).abs() < 0.5) {
      return;
    }
    setState(() {
      _soothingMiniPlayerReservedHeight = nextHeight;
    });
  }

  String? _busyDetail(AppI18n i18n, AppState state) {
    final explicitDetail = state.busyDetail;
    if ((explicitDetail ?? '').trim().isNotEmpty) {
      return explicitDetail;
    }
    final key = state.busyMessageKey;
    if (key == 'busyLoadingWordbook' ||
        key == 'busyImportingWordbook' ||
        key == 'busyMigratingLegacyData') {
      return i18n.t('busyPatienceHint');
    }
    return null;
  }

  Widget _buildInitializingView(BuildContext context, AppI18n i18n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2.8),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    i18n.t('busyInitializingApp'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    i18n.t('busyInitializingHint'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showFocusLockBackHint(AppI18n i18n) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        content: Text(
          i18n.t(
            'inline.ui.app_shell.focus_lock_is_active_long_press_the_unlock_bar_to_exit_f_2a0273',
          ),
        ),
      ),
    );
  }

  Future<void> _confirmExit(AppI18n i18n) async {
    if (_exitDialogVisible || !mounted) return;
    _exitDialogVisible = true;
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(i18n.t('inline.ui.app_shell.exit_app_9db3fc')),
          content: Text(
            i18n.t(
              'inline.ui.app_shell.this_will_close_the_current_app_continue_b96207',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(i18n.t('cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(i18n.t('inline.ui.app_shell.exit_b3ed31')),
            ),
          ],
        );
      },
    );
    _exitDialogVisible = false;
    if (shouldExit == true) {
      await SystemNavigator.pop();
    }
  }

  Widget _buildStartupPromptTodoSection(AppI18n i18n, AppState state) {
    final todos = state.todayActiveTodos;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildStartupPromptSectionHeader(
          i18n,
          icon: Icons.today_rounded,
          title: i18n.t('inline.ui.app_shell.today_s_active_todos_cc8a28'),
        ),
        const SizedBox(height: 8),
        if (todos.isEmpty)
          Text(
            i18n.t(
              'inline.ui.app_shell.no_active_todos_scheduled_for_today_aa0061',
            ),
            style: theme.textTheme.bodyMedium,
          )
        else
          ...todos.map((todo) => _buildStartupPromptTodoTile(i18n, todo)),
      ],
    );
  }

  Widget _buildStartupPromptQuoteSection(AppI18n i18n, AppState state) {
    final theme = Theme.of(context);
    final quote = state.startupDailyQuote?.trim() ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildStartupPromptSectionHeader(
          i18n,
          icon: Icons.format_quote_rounded,
          title: i18n.t('inline.ui.app_shell.daily_quote_09cf28'),
        ),
        const SizedBox(height: 8),
        if (state.startupDailyQuoteLoading && quote.isEmpty)
          Row(
            children: <Widget>[
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  i18n.t('inline.ui.app_shell.loading_today_s_quote_107d22'),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          )
        else
          Text(
            quote.isEmpty
                ? i18n.t(
                    'inline.ui.app_shell.unable_to_load_the_daily_quote_right_now_608b1d',
                  )
                : quote,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
          ),
      ],
    );
  }

  Widget _buildStartupPromptWeatherSection(AppI18n i18n, AppState state) {
    final theme = Theme.of(context);
    final snapshot = state.weatherSnapshot;
    if (state.weatherLoading && snapshot == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildStartupPromptSectionHeader(
            i18n,
            icon: Icons.cloud_rounded,
            title: i18n.t('inline.ui.app_shell.weather_783a11'),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  i18n.t('inline.ui.app_shell.refreshing_weather_ab623a'),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildStartupPromptSectionHeader(
          i18n,
          icon: Icons.cloud_rounded,
          title: i18n.t('inline.ui.app_shell.weather_783a11'),
        ),
        const SizedBox(height: 8),
        if (snapshot == null)
          Text(
            i18n.t(
              'inline.ui.app_shell.unable_to_load_weather_right_now_61fb76',
            ),
            style: theme.textTheme.bodyMedium,
          )
        else ...<Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(
                  weatherCodeIcon(snapshot.weatherCode, isDay: snapshot.isDay),
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '${snapshot.city}, ${snapshot.countryCode}',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${snapshot.temperatureCelsius.round()}°C · ${weatherCodeLabel(i18n, snapshot.weatherCode, isDay: snapshot.isDay)}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    if (snapshot.todayMaxTemperatureCelsius != null ||
                        snapshot.todayMinTemperatureCelsius != null)
                      Text(
                        i18n.t(
                          'inline.plan296.ui.app.shell.high_low.8bbbc30c46',
                          params: <String, Object?>{
                            'p0':
                                snapshot.todayMaxTemperatureCelsius?.round() ??
                                '--',
                            'p1':
                                snapshot.todayMinTemperatureCelsius?.round() ??
                                '--',
                          },
                        ),
                        style: theme.textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (snapshot.forecastDays.length > 1) ...<Widget>[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: snapshot.forecastDays
                  .skip(1)
                  .take(3)
                  .map((day) => _buildStartupForecastChip(i18n, day))
                  .toList(growable: false),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildStartupPromptSectionHeader(
    AppI18n i18n, {
    required IconData icon,
    required String title,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: <Widget>[
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStartupPromptTodoTile(AppI18n i18n, TodoItem todo) {
    final theme = Theme.of(context);
    final priorityColor = switch (todo.priority) {
      2 => theme.colorScheme.error,
      1 => theme.colorScheme.tertiary,
      _ => theme.colorScheme.primary,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.72,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: priorityColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  todo.content,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (todo.dueAt != null)
                  Text(
                    i18n.t(
                      'inline.ui.app_shell.reminder_formatstartupprompttime_todo_dueat_25a81e',
                    ),
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartupForecastChip(AppI18n i18n, WeatherForecastDay day) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            weatherCodeIcon(day.weatherCode, isDay: true),
            size: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            '${_startupForecastDayLabel(i18n, day.date)} ${day.maxTemperatureCelsius.round()}°/${day.minTemperatureCelsius.round()}°',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  String _formatStartupPromptTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _startupForecastDayLabel(AppI18n i18n, DateTime date) {
    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));
    if (DateUtils.isSameDay(date, today)) {
      return i18n.t('inline.ui.app_shell.today_23dc4e');
    }
    if (DateUtils.isSameDay(date, tomorrow)) {
      return i18n.t('inline.ui.app_shell.tomorrow_08dc97');
    }
    return '${date.month}/${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final visibleTabs = _resolveVisibleTabs(state);
    if (visibleTabs.length != _visibleTabs.length ||
        visibleTabs.any((tab) => !_visibleTabs.contains(tab))) {
      _visibleTabs = visibleTabs;
    }
    final safeIndex = _index.clamp(0, (_visibleTabs.length - 1).clamp(0, 999));
    if (safeIndex != _index) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _index = safeIndex;
        });
      });
    }
    _handlePendingTodoReminderLaunch(state);
    final i18n = AppI18n(state.uiLanguage);
    final currentTab = _tabAt(safeIndex);
    final media = MediaQuery.of(context);
    final bottomInset = media.padding.bottom;
    final message = state.error;
    final isInitializing = state.initializing && !state.initialized;
    final shellRouteIsCurrent = ModalRoute.of(context)?.isCurrent ?? true;
    final navigationAutoHideEnabled = state.bottomNavigationAutoHideEnabled;
    final navigationContentVisible =
        !navigationAutoHideEnabled || isInitializing || _navigationBarVisible;
    final navigationChromeHeight =
        bottomInset + (navigationContentVisible ? _navigationBarHeight : 0);
    final combinedMiniPlayerHeight =
        _miniPlayerReservedHeight + _soothingMiniPlayerReservedHeight;
    final ambientLauncherBottomClearance =
        navigationChromeHeight +
        (combinedMiniPlayerHeight > 0 ? combinedMiniPlayerHeight + 18 : 18);
    if ((!navigationAutoHideEnabled || isInitializing) &&
        !_navigationBarVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _setNavigationBarVisible(true);
      });
    }
    if (message != null && message.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
        state.clearMessage();
      });
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (state.focusService.lockScreenActive) {
          _showFocusLockBackHint(i18n);
          return;
        }
        _confirmExit(i18n);
      },
      child: Scaffold(
        body: AppBackground(
          appearance: state.config.appearance,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) =>
                _handleNavigationScrollNotification(
                  notification,
                  navigationAutoHideEnabled && !isInitializing,
                ),
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (event) => _handleNavigationPointerDown(
                event,
                navigationAutoHideEnabled && !isInitializing,
              ),
              onPointerMove: _handleNavigationPointerMove,
              onPointerUp: (_) => _handleNavigationPointerUp(
                navigationAutoHideEnabled && !isInitializing,
              ),
              onPointerCancel: (_) => _clearNavigationPointerTracking(),
              child: Stack(
                children: <Widget>[
                  SafeArea(
                    bottom: false,
                    child: Column(
                      children: <Widget>[
                        Expanded(
                          child: AnimatedPadding(
                            duration: const Duration(milliseconds: 240),
                            curve: Curves.easeOutCubic,
                            padding: EdgeInsets.only(
                              bottom: combinedMiniPlayerHeight,
                            ),
                            child: isInitializing
                                ? _buildInitializingView(context, i18n)
                                : IndexedStack(
                                    index: safeIndex,
                                    children: _visibleTabs
                                        .map(_buildPageForTab)
                                        .toList(growable: false),
                                  ),
                          ),
                        ),
                        _buildBottomNavigationChrome(
                          height: navigationChromeHeight,
                          bottomInset: bottomInset,
                          selectedIndex: safeIndex,
                          i18n: i18n,
                          visible: navigationContentVisible,
                        ),
                      ],
                    ),
                  ),
                  AnimatedPositioned(
                    duration: _navigationChromeDuration,
                    curve: Curves.easeOutCubic,
                    left: 0,
                    right: 0,
                    bottom: navigationChromeHeight + 8,
                    child: MiniPlayer(
                      state: state,
                      i18n: i18n,
                      onOpenPractice: () => _setTab(AppHomeTab.practice),
                      onOpenLibrary: () {
                        _setTab(AppHomeTab.study);
                        _setStudyTab(StudyStartupTab.library);
                      },
                      onPresentationChanged: _handleMiniPlayerPresentation,
                    ),
                  ),
                  AnimatedPositioned(
                    duration: _navigationChromeDuration,
                    curve: Curves.easeOutCubic,
                    left: 0,
                    right: 0,
                    bottom:
                        navigationChromeHeight +
                        (_miniPlayerReservedHeight > 0
                            ? _miniPlayerReservedHeight + 16
                            : 8),
                    child: ValueListenableBuilder<int>(
                      valueListenable: SoothingMusicRuntimeStore.revision,
                      builder: (context, _, _) {
                        final visible =
                            !isInitializing &&
                            shellRouteIsCurrent &&
                            currentTab != AppHomeTab.toolbox &&
                            SoothingMiniPlayer.isVisible;
                        final reservedHeight = visible ? 86.0 : 0.0;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted) return;
                          _handleSoothingMiniPlayerPresentation(
                            visible,
                            reservedHeight,
                          );
                        });
                        if (!visible) {
                          return const SizedBox.shrink();
                        }
                        return SoothingMiniPlayer(
                          i18n: i18n,
                          onOpen: () {
                            pushModuleRoute<void>(
                              context,
                              state: state,
                              moduleId: ModuleIds.toolboxSoothingMusic,
                              settings: const RouteSettings(
                                name: 'soothing_music',
                              ),
                              builder: (_) => const SoothingMusicV2Page(),
                            );
                          },
                          onTogglePlayback: () async {
                            final player =
                                SoothingMusicRuntimeStore.retainedPlayer;
                            if (player == null) {
                              _setTab(AppHomeTab.toolbox);
                              return;
                            }
                            if (SoothingMusicRuntimeStore.activePlaying) {
                              await player.pause();
                              SoothingMusicRuntimeStore.activePlaying = false;
                            } else {
                              await player.resume();
                              SoothingMusicRuntimeStore.activePlaying = true;
                            }
                            SoothingMusicRuntimeStore.notifyChanged();
                          },
                        );
                      },
                    ),
                  ),
                  if (!isInitializing)
                    Positioned.fill(
                      child: AmbientFloatingDock(
                        state: state,
                        i18n: i18n,
                        bottomClearance: ambientLauncherBottomClearance,
                      ),
                    ),
                  if (!isInitializing &&
                      (state.wordbookImportActive ||
                          state.remotePrewarmActive ||
                          state.remotePrewarmFailed))
                    Positioned(
                      top: media.padding.top + 10,
                      left: 16,
                      right: 16,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          if (state.wordbookImportActive)
                            _buildWordbookImportBanner(i18n, state),
                          if (state.wordbookImportActive &&
                              (state.remotePrewarmActive ||
                                  state.remotePrewarmFailed))
                            const SizedBox(height: 8),
                          if (state.remotePrewarmActive ||
                              state.remotePrewarmFailed)
                            _buildRemotePrewarmBanner(i18n, state),
                        ],
                      ),
                    ),
                  BusyOverlay(
                    visible: state.busy,
                    message: state.busyMessage ?? i18n.t('processing'),
                    detail: _busyDetail(i18n, state),
                    progress: state.busyProgress,
                  ),
                  ValueListenableBuilder<int>(
                    valueListenable: state.focusService.viewRevision,
                    builder: (context, _, _) {
                      if (!state.focusService.lockScreenActive) {
                        return const SizedBox.shrink();
                      }
                      return const Positioned.fill(child: FocusLockOverlay());
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRemotePrewarmBanner(AppI18n i18n, AppState state) {
    final failed = state.remotePrewarmFailed;
    final progress = state.remotePrewarmProgress;
    final current = state.remotePrewarmCurrentLabel;
    return Material(
      elevation: 4,
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: failed
                ? Theme.of(context).colorScheme.error.withValues(alpha: 0.32)
                : Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                i18n.t(
                  failed
                      ? 'appShell.remotePrewarm.failedTitle'
                      : 'appShell.remotePrewarm.runningTitle',
                ),
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                failed
                    ? i18n.t(
                        'inline.ui.app_shell.initial_downloads_did_not_finish_resources_will_still_do_01aa75',
                      )
                    : i18n.t(
                        'inline.plan296.ui.app.shell.complete_current.eb38379612',
                        params: <String, Object?>{
                          'remotePrewarmCompletedCount':
                              state.remotePrewarmCompletedCount,
                          'remotePrewarmTotalCount':
                              state.remotePrewarmTotalCount,
                          'p2': current.isEmpty ? '准备中' : current,
                          'p3': current.isEmpty ? 'Preparing…' : current,
                        },
                      ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (!failed) ...<Widget>[
                const SizedBox(height: 10),
                LinearProgressIndicator(value: progress.clamp(0.0, 1.0)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWordbookImportBanner(AppI18n i18n, AppState state) {
    final progress = state.wordbookImportProgress;
    final processed = state.wordbookImportProcessedEntries;
    final total = state.wordbookImportTotalEntries;
    final subtitle = total == null || total <= 0
        ? i18n.t('inline.ui.app_shell.parsing_and_importing_please_wait_1b254d')
        : i18n.t('inline.ui.app_shell.processed_processed_total_11a7cb');
    return Material(
      elevation: 4,
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      i18n.t(
                        'inline.ui.app_shell.importing_in_background_state_wordbookimportname_57cc79',
                      ),
                      style: Theme.of(context).textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: progress, minHeight: 4),
            ],
          ),
        ),
      ),
    );
  }
}
