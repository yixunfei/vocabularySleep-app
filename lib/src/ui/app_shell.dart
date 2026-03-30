import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../i18n/app_i18n.dart';
import '../models/study_startup_tab.dart';
import '../models/todo_item.dart';
import '../models/weather_snapshot.dart';
import '../state/app_state.dart';
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

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const double _navigationBarHeight = 80;

  int _index = 0;
  StudyStartupTab _studyTab = StudyStartupTab.play;
  double _miniPlayerReservedHeight = 0;
  double _soothingMiniPlayerReservedHeight = 0;
  VoidCallback? _scrollLibraryToTop;
  bool _exitDialogVisible = false;
  bool _startupPromptShown = false;
  int? _lastHandledTodoReminderLaunchId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = context.read<AppState>();
      state.init().then((_) {
        if (!mounted) return;
        final nextIndex = state.startupPage.index;
        setState(() {
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

  Future<void> _maybeShowStartupTodoPrompt() async {
    if (_startupPromptShown || !mounted) {
      return;
    }
    final state = context.read<AppState>();
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
            return Consumer<AppState>(
              builder: (dialogContext, state, _) {
                final i18n = AppI18n(state.uiLanguage);
                return AlertDialog(
                  key: const ValueKey<String>('startup-todo-prompt-dialog'),
                  title: Text(
                    pickUiText(i18n, zh: '今日待办提示', en: 'Today at a glance'),
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
                              pickUiText(
                                i18n,
                                zh: '今日不再弹出',
                                en: "Don't show again today",
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
                      child: Text(pickUiText(i18n, zh: '知道了', en: 'Close')),
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
    if (_index == index) {
      if (index == 0 && _studyTab == StudyStartupTab.library) {
        _scrollLibraryToTop?.call();
      }
      return;
    }
    setState(() {
      _index = index;
    });
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
    context.read<AppState>().setStudyStartupTab(tab);
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
    if (_index != 2) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        setState(() {
          _index = 2;
        });
      });
    }
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
          pickUiText(
            i18n,
            zh: '当前处于专注锁屏状态，请长按底部解锁条退出专注。',
            en: 'Focus lock is active. Long press the unlock bar to exit focus.',
            ja: '集中ロック中です。下部の解除バーを長押しして終了してください。',
            de: 'Der Fokus-Sperrbildschirm ist aktiv. Halte die Entsperrleiste gedrückt, um den Fokus zu beenden.',
            fr: 'Le verrouillage du mode concentration est actif. Maintenez la barre de déverrouillage pour quitter.',
            es: 'El bloqueo de enfoque está activo. Mantén pulsada la barra de desbloqueo para salir del enfoque.',
            ru: 'Блокировка фокуса активна. Нажмите и удерживайте полосу разблокировки, чтобы выйти из режима.',
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
          title: Text(
            pickUiText(
              i18n,
              zh: '确认退出',
              en: 'Exit app?',
              ja: 'アプリを終了しますか',
              de: 'App beenden?',
              fr: 'Quitter l’application ?',
              es: '¿Salir de la app?',
              ru: 'Выйти из приложения?',
            ),
          ),
          content: Text(
            pickUiText(
              i18n,
              zh: '将退出当前应用，是否继续？',
              en: 'This will close the current app. Continue?',
              ja: '現在のアプリを終了します。続行しますか。',
              de: 'Die aktuelle App wird geschlossen. Fortfahren?',
              fr: 'L’application va se fermer. Continuer ?',
              es: 'La aplicación se cerrará. ¿Continuar?',
              ru: 'Приложение будет закрыто. Продолжить?',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                pickUiText(
                  i18n,
                  zh: '取消',
                  en: 'Cancel',
                  ja: 'キャンセル',
                  de: 'Abbrechen',
                  fr: 'Annuler',
                  es: 'Cancelar',
                  ru: 'Отмена',
                ),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                pickUiText(
                  i18n,
                  zh: '退出',
                  en: 'Exit',
                  ja: '終了',
                  de: 'Beenden',
                  fr: 'Quitter',
                  es: 'Salir',
                  ru: 'Выйти',
                ),
              ),
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
          title: pickUiText(i18n, zh: '今日进行中待办', en: 'Today\'s active todos'),
        ),
        const SizedBox(height: 8),
        if (todos.isEmpty)
          Text(
            pickUiText(
              i18n,
              zh: '今天没有进行中的待办事项。',
              en: 'No active todos scheduled for today.',
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
          title: pickUiText(i18n, zh: '每日一言', en: 'Daily quote'),
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
                  pickUiText(
                    i18n,
                    zh: '正在获取今日一言...',
                    en: 'Loading today\'s quote...',
                  ),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          )
        else
          Text(
            quote.isEmpty
                ? pickUiText(
                    i18n,
                    zh: '暂时无法获取每日一言。',
                    en: 'Unable to load the daily quote right now.',
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
            title: pickUiText(i18n, zh: '天气', en: 'Weather'),
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
                  pickUiText(
                    i18n,
                    zh: '正在更新天气...',
                    en: 'Refreshing weather...',
                  ),
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
          title: pickUiText(i18n, zh: '天气', en: 'Weather'),
        ),
        const SizedBox(height: 8),
        if (snapshot == null)
          Text(
            pickUiText(
              i18n,
              zh: '暂时无法获取天气信息。',
              en: 'Unable to load weather right now.',
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
                        pickUiText(
                          i18n,
                          zh: '最高 ${snapshot.todayMaxTemperatureCelsius?.round() ?? '--'}° / 最低 ${snapshot.todayMinTemperatureCelsius?.round() ?? '--'}°',
                          en: 'High ${snapshot.todayMaxTemperatureCelsius?.round() ?? '--'}° / Low ${snapshot.todayMinTemperatureCelsius?.round() ?? '--'}°',
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
                    pickUiText(
                      i18n,
                      zh: '提醒时间 ${_formatStartupPromptTime(todo.dueAt!)}',
                      en: 'Reminder ${_formatStartupPromptTime(todo.dueAt!)}',
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
      return pickUiText(i18n, zh: '今天', en: 'Today');
    }
    if (DateUtils.isSameDay(date, tomorrow)) {
      return pickUiText(i18n, zh: '明天', en: 'Tomorrow');
    }
    return '${date.month}/${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    _handlePendingTodoReminderLaunch(state);
    final i18n = AppI18n(state.uiLanguage);
    final media = MediaQuery.of(context);
    final bottomInset = media.padding.bottom;
    final navigationChromeHeight = _navigationBarHeight + bottomInset;
    final combinedMiniPlayerHeight =
        _miniPlayerReservedHeight + _soothingMiniPlayerReservedHeight;
    final ambientLauncherBottomClearance =
        navigationChromeHeight +
        (combinedMiniPlayerHeight > 0 ? combinedMiniPlayerHeight + 18 : 18);
    final message = state.error;
    final isInitializing = state.initializing && !state.initialized;
    final shellRouteIsCurrent = ModalRoute.of(context)?.isCurrent ?? true;
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
                                index: _index,
                                children: <Widget>[
                                  StudyPage(
                                    selectedTab: _studyTab,
                                    onSelectTab: _setStudyTab,
                                    onOpenPractice: () => _setIndex(1),
                                    onAttachLibraryScrollToTop: (callback) {
                                      _scrollLibraryToTop = callback;
                                    },
                                  ),
                                  const PracticePage(),
                                  const FocusPage(),
                                  const ToolboxPage(),
                                  const MorePage(),
                                ],
                              ),
                      ),
                    ),
                    SizedBox(
                      height: navigationChromeHeight,
                      child: Padding(
                        padding: EdgeInsets.only(bottom: bottomInset),
                        child: NavigationBar(
                          height: _navigationBarHeight,
                          selectedIndex: _index,
                          onDestinationSelected: _setIndex,
                          destinations: <NavigationDestination>[
                            NavigationDestination(
                              icon: const Icon(Icons.auto_stories_outlined),
                              selectedIcon: const Icon(
                                Icons.auto_stories_rounded,
                              ),
                              label: pageLabelStudy(i18n),
                            ),
                            NavigationDestination(
                              icon: const Icon(Icons.fitness_center_outlined),
                              selectedIcon: const Icon(
                                Icons.fitness_center_rounded,
                              ),
                              label: pageLabelPractice(i18n),
                            ),
                            NavigationDestination(
                              icon: const Icon(Icons.timer_outlined),
                              selectedIcon: const Icon(Icons.timer_rounded),
                              label: pageLabelFocus(i18n),
                            ),
                            NavigationDestination(
                              icon: const Icon(Icons.handyman_outlined),
                              selectedIcon: const Icon(Icons.handyman_rounded),
                              label: pageLabelToolbox(i18n),
                            ),
                            NavigationDestination(
                              icon: const Icon(Icons.widgets_outlined),
                              selectedIcon: const Icon(Icons.widgets_rounded),
                              label: pageLabelMore(i18n),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: bottomInset + _navigationBarHeight + 8,
                child: MiniPlayer(
                  state: state,
                  i18n: i18n,
                  onOpenPractice: () => _setIndex(1),
                  onOpenLibrary: () {
                    _setIndex(0);
                    _setStudyTab(StudyStartupTab.library);
                  },
                  onPresentationChanged: _handleMiniPlayerPresentation,
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom:
                    bottomInset +
                    _navigationBarHeight +
                    (_miniPlayerReservedHeight > 0
                        ? _miniPlayerReservedHeight + 16
                        : 8),
                child: ValueListenableBuilder<int>(
                  valueListenable: SoothingMusicRuntimeStore.revision,
                  builder: (context, _, _) {
                    final visible =
                        !isInitializing &&
                        shellRouteIsCurrent &&
                        _index != 3 &&
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
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const SoothingMusicV2Page(),
                            settings: const RouteSettings(
                              name: 'soothing_music',
                            ),
                          ),
                        );
                      },
                      onTogglePlayback: () async {
                        final player = SoothingMusicRuntimeStore.retainedPlayer;
                        if (player == null) {
                          _setIndex(3);
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
                pickUiText(
                  i18n,
                  zh: failed ? '资源预热失败' : '正在后台预热资源',
                  en: failed
                      ? 'Background prewarm failed'
                      : 'Prewarming resources in background',
                ),
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                failed
                    ? pickUiText(
                        i18n,
                        zh: '首次下载未完成，稍后会在实际使用时继续按需拉取。',
                        en: 'Initial downloads did not finish. Resources will still download on demand when opened.',
                      )
                    : pickUiText(
                        i18n,
                        zh: '已完成 ${state.remotePrewarmCompletedCount} / ${state.remotePrewarmTotalCount}，当前：${current.isEmpty ? '准备中' : current}',
                        en: '${state.remotePrewarmCompletedCount} / ${state.remotePrewarmTotalCount} complete. Current: ${current.isEmpty ? 'Preparing…' : current}',
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
        ? pickUiText(
            i18n,
            zh: '正在解析并导入，请稍候…',
            en: 'Parsing and importing, please wait...',
          )
        : pickUiText(
            i18n,
            zh: '已处理 $processed / $total',
            en: 'Processed $processed / $total',
          );
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
                      pickUiText(
                        i18n,
                        zh: '正在后台导入词本：${state.wordbookImportName}',
                        en: 'Importing in background: ${state.wordbookImportName}',
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
