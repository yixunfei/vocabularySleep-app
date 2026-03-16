import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../i18n/app_i18n.dart';
import '../../models/focus_startup_tab.dart';
import '../../models/play_config.dart';
import '../../models/todo_item.dart';
import '../../models/tomato_timer.dart';
import '../../services/ambient_service.dart';
import '../../services/focus_service.dart';
import '../../services/system_speech_service.dart';
import '../../state/app_state.dart';
import '../../utils/asr_language.dart';
import '../layout/app_width_tier.dart';
import '../ui_copy.dart';
import '../widgets/section_header.dart';

enum _TodoSortMode { manual, priority, category }

enum _TodoFilterMode { all, active, today, overdue, deferred, completed }

enum _TodoViewMode { plan, list }

enum _TodoDraftState { active, deferred, completed }

enum _NoteVoiceInputState { idle, starting, listening, finishing }

class _TodoPlanSection {
  const _TodoPlanSection({
    required this.key,
    required this.title,
    required this.icon,
    required this.items,
    this.highlight = false,
  });

  final String key;
  final String title;
  final IconData icon;
  final List<TodoItem> items;
  final bool highlight;
}

class FocusPage extends StatefulWidget {
  const FocusPage({super.key});

  @override
  State<FocusPage> createState() => _FocusPageState();
}

class _FocusPageState extends State<FocusPage>
    with SingleTickerProviderStateMixin {
  static const List<int> _todoPalette = <int>[
    0xFFFDE68A,
    0xFFBFDBFE,
    0xFFC7D2FE,
    0xFFBBF7D0,
    0xFFFBCFE8,
    0xFFFED7AA,
  ];

  late final TabController _tabController;
  final SystemSpeechService _systemSpeech = const PlatformSystemSpeechService();
  final Set<int> _selectedNoteIds = <int>{};
  FocusService? _boundFocusService;
  Timer? _visualReminderTimer;
  TomatoTimerPhase? _lastCompletedPhase;
  bool _noteSelectionMode = false;
  _TodoSortMode _todoSortMode = _TodoSortMode.manual;
  _TodoFilterMode _todoFilterMode = _TodoFilterMode.all;
  _TodoViewMode _todoViewMode = _TodoViewMode.list;
  String? _expandedTodoMetricKey;
  bool _todoMetricsExpanded = false;
  double _notesDrawerProgress = 0;
  bool _notesDrawerDragging = false;
  bool _reminderDialogVisible = false;
  bool _ambientLauncherExpanded = false;
  FocusStartupTab? _lastAppliedStartupTab;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, initialIndex: 1, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final focus = context.read<AppState>().focusService;
    if (identical(_boundFocusService, focus)) {
      return;
    }
    _boundFocusService?.setCallbacks();
    focus.setCallbacks(onPhaseComplete: _onPhaseComplete);
    _boundFocusService = focus;
  }

  @override
  void dispose() {
    _boundFocusService?.setCallbacks();
    _visualReminderTimer?.cancel();
    _tabController.dispose();
    unawaited(_systemSpeech.dispose());
    super.dispose();
  }

  void _onPhaseComplete(TomatoTimerPhase phase, int _) {
    if (!mounted) return;
    final state = context.read<AppState>();
    final i18n = AppI18n(state.uiLanguage);
    if (state.focusService.config.reminder.visual) {
      _visualReminderTimer?.cancel();
      setState(() {
        _lastCompletedPhase = phase;
      });
      _visualReminderTimer = Timer(const Duration(seconds: 2), () {
        if (!mounted) return;
        setState(() {
          _lastCompletedPhase = null;
        });
      });
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

  Future<void> _showReminderAcknowledgementDialog(
    FocusService focus,
    TomatoTimerPhase phase,
    AppI18n i18n,
  ) async {
    if (_reminderDialogVisible || !mounted) {
      return;
    }
    _reminderDialogVisible = true;
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
    _reminderDialogVisible = false;
    if (!mounted || acknowledged != true) {
      return;
    }
    await focus.acknowledgeReminder();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    _syncConfiguredStartupTab(state.focusStartupTab);
    final i18n = AppI18n(state.uiLanguage);
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

  Widget _buildTimerTab(AppState state, FocusService focus, AppI18n i18n) {
    final timerState = focus.state;
    final config = focus.config;
    final appearance = state.config.appearance;

    return LayoutBuilder(
      builder: (context, constraints) {
        final widthTier = AppWidthBreakpoints.tierFor(constraints.maxWidth);
        final availableWidth = math.max(0.0, constraints.maxWidth - 32);
        final contentWidth = math.min(
          availableWidth,
          _pageContentMaxWidth(widthTier),
        );
        return Stack(
          children: <Widget>[
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: contentWidth),
                  child: Column(
                    children: <Widget>[
                      _buildTimerDisplay(
                        timerState,
                        config,
                        i18n,
                        widthTier,
                        appearance.normalizedTimerStyle,
                      ),
                      const SizedBox(height: 20),
                      _buildTimerControls(focus, timerState, i18n),
                      const SizedBox(height: 20),
                      _buildTimerConfig(
                        focus,
                        config,
                        i18n,
                        contentWidth,
                        widthTier,
                      ),
                      const SizedBox(height: 20),
                      _buildTodayStats(focus, i18n, contentWidth, widthTier),
                    ],
                  ),
                ),
              ),
            ),
            Offstage(
              offstage: true,
              child: _buildAmbientLauncher(
                state,
                i18n,
                widthTier,
                constraints.maxWidth,
              ),
            ),
          ],
        );
      },
    );
  }

  void _syncConfiguredStartupTab(FocusStartupTab tab) {
    if (_lastAppliedStartupTab == tab) {
      return;
    }
    _lastAppliedStartupTab = tab;
    final targetIndex = tab.index;
    if (_tabController.index == targetIndex) {
      return;
    }
    _tabController.index = targetIndex;
  }

  Widget _buildAmbientLauncher(
    AppState state,
    AppI18n i18n,
    AppWidthTier widthTier,
    double maxWidth,
  ) {
    final theme = Theme.of(context);
    final enabledSources = state.ambientSources
        .where((source) => source.enabled)
        .toList(growable: false);
    final activeCount = enabledSources.length;
    final panelWidth = math.min(
      maxWidth - 32,
      widthTier.isCompact ? 280.0 : 320.0,
    );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: _ambientLauncherExpanded
          ? SizedBox(
              key: const ValueKey<String>('ambient-launcher-panel'),
              width: panelWidth,
              child: Stack(
                children: <Widget>[
                  _buildAmbientSummaryCard(state, i18n, widthTier),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: IconButton.filledTonal(
                      key: const ValueKey<String>('ambient-launcher-close'),
                      tooltip: i18n.t('close'),
                      onPressed: () {
                        setState(() {
                          _ambientLauncherExpanded = false;
                        });
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ),
                ],
              ),
            )
          : Material(
              key: const ValueKey<String>('ambient-launcher-toggle'),
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () {
                  setState(() {
                    _ambientLauncherExpanded = true;
                  });
                },
                child: Ink(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.surfaceContainerHigh.withValues(
                      alpha: 0.94,
                    ),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.8,
                      ),
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: theme.colorScheme.shadow.withValues(alpha: 0.16),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: <Widget>[
                      Icon(
                        activeCount > 0
                            ? Icons.surround_sound_rounded
                            : Icons.music_note_rounded,
                        color: theme.colorScheme.primary,
                      ),
                      if (activeCount > 0)
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '$activeCount',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildAmbientSummaryCard(
    AppState state,
    AppI18n i18n,
    AppWidthTier widthTier,
  ) {
    final theme = Theme.of(context);
    final enabledSources = state.ambientSources
        .where((source) => source.enabled)
        .toList(growable: false);
    final previewCount = widthTier.isCompact ? 2 : 3;
    final shownNames = enabledSources
        .take(previewCount)
        .map((source) => localizedAmbientName(i18n, source))
        .toList(growable: false);
    final remainingCount = enabledSources.length - shownNames.length;
    final headline = enabledSources.isEmpty
        ? pickUiText(
            i18n,
            zh: '背景音未开启',
            en: 'Background audio is off',
            ja: '環境音はオフです',
            de: 'Hintergrundaudio ist aus',
            fr: 'L’audio d’ambiance est coupe',
            es: 'El audio ambiental esta apagado',
            ru: 'Фоновый звук выключен',
          )
        : pickUiText(
            i18n,
            zh: '已启用 ${enabledSources.length} 条背景音',
            en: '${enabledSources.length} ambient tracks enabled',
            ja: '${enabledSources.length} 個の環境音を有効化中',
            de: '${enabledSources.length} Hintergrundspuren aktiv',
            fr: '${enabledSources.length} pistes d’ambiance actives',
            es: '${enabledSources.length} pistas ambientales activas',
            ru: 'Активно ${enabledSources.length} фоновых дорожек',
          );
    final details = enabledSources.isEmpty
        ? pickUiText(
            i18n,
            zh: '进入背景音面板后可以快速切换雨声、白噪音、图书馆等专注声景。',
            en: 'Open the audio panel to quickly switch between rain, noise, library, and other focus scenes.',
            ja: 'パネルを開くと、雨音、ノイズ、図書館などの集中サウンドをすばやく切り替えられます。',
            de: 'Im Audiobereich koennen Regen, Rauschen, Bibliothek und weitere Fokus-Szenen schnell umgeschaltet werden.',
            fr: 'Ouvrez le panneau audio pour basculer rapidement entre pluie, bruit, bibliotheque et autres ambiances.',
            es: 'Abre el panel para cambiar rapidamente entre lluvia, ruido, biblioteca y otras escenas de enfoque.',
            ru: 'Откройте панель аудио, чтобы быстро переключаться между дождём, шумом, библиотекой и другими звуковыми сценами.',
          )
        : '${shownNames.join(' · ')}${remainingCount > 0 ? ' +$remainingCount' : ''}';
    final progressColor = enabledSources.isEmpty
        ? theme.colorScheme.outlineVariant
        : theme.colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            theme.colorScheme.primaryContainer.withValues(alpha: 0.92),
            theme.colorScheme.secondaryContainer.withValues(alpha: 0.74),
          ],
        ),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.16),
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  enabledSources.isEmpty
                      ? Icons.music_off_rounded
                      : Icons.surround_sound_rounded,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      i18n.t('ambientAudio'),
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(headline, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text(details, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              Chip(
                avatar: const Icon(Icons.graphic_eq_rounded, size: 18),
                label: Text(
                  '${i18n.t('masterVolume')} ${(state.ambientMasterVolume * 100).round()}%',
                ),
              ),
              Chip(
                avatar: const Icon(Icons.queue_music_rounded, size: 18),
                label: Text(
                  enabledSources.isEmpty
                      ? pickUiText(
                          i18n,
                          zh: '未启用音轨',
                          en: 'No active tracks',
                          ja: '有効な音源なし',
                          de: 'Keine aktiven Spuren',
                          fr: 'Aucune piste active',
                          es: 'Sin pistas activas',
                          ru: 'Нет активных дорожек',
                        )
                      : pickUiText(
                          i18n,
                          zh: '${enabledSources.length} 条音轨',
                          en: '${enabledSources.length} tracks',
                          ja: '${enabledSources.length} トラック',
                          de: '${enabledSources.length} Spuren',
                          fr: '${enabledSources.length} pistes',
                          es: '${enabledSources.length} pistas',
                          ru: '${enabledSources.length} дорожек',
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: state.ambientMasterVolume.clamp(0.0, 1.0),
              color: progressColor,
              backgroundColor: theme.colorScheme.surface.withValues(
                alpha: 0.48,
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _openAmbientAudioSheet(context),
              icon: const Icon(Icons.tune_rounded),
              label: Text(
                pickUiText(
                  i18n,
                  zh: '打开背景音设置',
                  en: 'Open background audio settings',
                  ja: '環境音設定を開く',
                  de: 'Hintergrundaudio-Einstellungen oeffnen',
                  fr: 'Ouvrir les reglages audio',
                  es: 'Abrir ajustes de audio ambiental',
                  ru: 'Открыть настройки фонового звука',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerDisplay(
    TomatoTimerState timerState,
    TomatoTimerConfig config,
    AppI18n i18n,
    AppWidthTier widthTier,
    String timerStyle,
  ) {
    final phaseText = switch (timerState.phase) {
      TomatoTimerPhase.idle => i18n.t('timerIdle'),
      TomatoTimerPhase.focus => i18n.t('focusPhase'),
      TomatoTimerPhase.breakTime => i18n.t('breakPhase'),
      TomatoTimerPhase.breakReady => i18n.t('breakReady'),
      TomatoTimerPhase.focusReady => i18n.t('focusReady'),
    };
    final indicatorSize = switch (widthTier) {
      AppWidthTier.compact => 188.0,
      AppWidthTier.expanded => 256.0,
      AppWidthTier.regular => 220.0,
    };
    final helperText = timerState.isAwaitingManualTransition
        ? i18n.t('timerWaitingAction')
        : null;
    final theme = Theme.of(context);
    final alertActive = _lastCompletedPhase != null;
    final accent = alertActive
        ? (_lastCompletedPhase == TomatoTimerPhase.focus
              ? theme.colorScheme.tertiary
              : theme.colorScheme.secondary)
        : theme.colorScheme.primary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      decoration: BoxDecoration(
        color: alertActive
            ? accent.withValues(alpha: 0.12)
            : theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: alertActive
              ? accent.withValues(alpha: 0.38)
              : theme.colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: <Widget>[
            Text(phaseText, style: theme.textTheme.titleLarge),
            if (helperText != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                helperText,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (timerState.phase != TomatoTimerPhase.idle) ...<Widget>[
              const SizedBox(height: 10),
              Text(
                i18n.t(
                  'roundProgress',
                  params: <String, Object?>{
                    'current': timerState.currentRound,
                    'total': config.rounds,
                  },
                ),
              ),
            ],
            const SizedBox(height: 18),
            _buildTimerVisual(
              timerState,
              timerStyle: timerStyle,
              size: indicatorSize,
              accent: accent,
            ),
            const SizedBox(height: 18),
            Text(
              _formatTime(timerState.remainingSeconds),
              style: widthTier.isCompact
                  ? theme.textTheme.headlineLarge
                  : theme.textTheme.displaySmall,
            ),
            const SizedBox(height: 8),
            Text(
              '${_formatUnitSummary(timerState.totalSeconds, i18n)} · ${_formatPercent(timerState.remainingProgress)}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerVisual(
    TomatoTimerState timerState, {
    required String timerStyle,
    required double size,
    required Color accent,
  }) {
    final remaining = timerState.remainingProgress.clamp(0.0, 1.0).toDouble();
    final theme = Theme.of(context);
    final isActive = timerState.isActiveCountdown && !timerState.isPaused;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: remaining, end: remaining),
      duration: isActive
          ? const Duration(milliseconds: 920)
          : const Duration(milliseconds: 260),
      curve: Curves.easeInOutCubic,
      builder: (context, animatedRemaining, _) {
        final secondsLeft = animatedRemaining * timerState.totalSeconds;
        final fraction = secondsLeft - secondsLeft.floorToDouble();
        final pulse = isActive ? math.sin(fraction * math.pi) : 0.0;

        if (timerStyle == 'countdown') {
          return _buildCountdownVisual(
            size: size,
            accent: accent,
            theme: theme,
            remaining: animatedRemaining,
            pulse: pulse,
            paused: timerState.isPaused,
          );
        }

        return _buildHourglassVisual(
          size: size,
          accent: accent,
          theme: theme,
          remaining: animatedRemaining,
          pulse: pulse,
          paused: timerState.isPaused,
        );
      },
    );
  }

  Widget _buildCountdownVisual({
    required double size,
    required Color accent,
    required ThemeData theme,
    required double remaining,
    required double pulse,
    required bool paused,
  }) {
    final glowOpacity = paused ? 0.08 : 0.14 + pulse * 0.12;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: size * (0.86 + pulse * 0.05),
            height: size * (0.86 + pulse * 0.05),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: <Color>[
                  accent.withValues(alpha: glowOpacity),
                  accent.withValues(alpha: 0.02),
                ],
              ),
            ),
          ),
          Transform.rotate(
            angle: paused ? 0 : (0.5 - pulse) * 0.18,
            child: CustomPaint(
              size: Size.square(size),
              painter: _CountdownRingPainter(
                remaining: remaining,
                pulse: pulse,
                accent: accent,
                track: theme.colorScheme.surfaceContainerHighest,
                surface: theme.colorScheme.surface,
              ),
            ),
          ),
          Container(
            width: size * (0.32 + remaining * 0.16),
            height: size * (0.32 + remaining * 0.16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.surface.withValues(alpha: 0.94),
              border: Border.all(
                color: accent.withValues(alpha: 0.28),
                width: 1.6,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: accent.withValues(alpha: 0.10 + pulse * 0.06),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.hourglass_bottom_rounded,
              size: size * 0.16,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHourglassVisual({
    required double size,
    required Color accent,
    required ThemeData theme,
    required double remaining,
    required double pulse,
    required bool paused,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: size * (0.80 + pulse * 0.04),
            height: size * (0.80 + pulse * 0.04),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(size * 0.24),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  accent.withValues(alpha: 0.14 + pulse * 0.08),
                  theme.colorScheme.surfaceContainerLow,
                ],
              ),
            ),
          ),
          Transform.rotate(
            angle: paused ? 0 : (0.5 - pulse) * 0.08,
            child: CustomPaint(
              size: Size.square(size * 0.82),
              painter: _HourglassPainter(
                remaining: remaining,
                pulse: pulse,
                accent: accent,
                track: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerControls(
    FocusService focus,
    TomatoTimerState timerState,
    AppI18n i18n,
  ) {
    final phase = timerState.phase;
    if (phase == TomatoTimerPhase.idle) {
      return FilledButton.icon(
        onPressed: focus.start,
        icon: const Icon(Icons.play_arrow_rounded),
        label: Text(i18n.t('startFocus')),
      );
    }

    final buttons = <Widget>[];
    if (phase == TomatoTimerPhase.breakReady) {
      buttons.add(
        FilledButton.icon(
          onPressed: focus.advanceToNextPhase,
          icon: const Icon(Icons.self_improvement_rounded),
          label: Text(i18n.t('startBreak')),
        ),
      );
    } else if (phase == TomatoTimerPhase.focusReady) {
      buttons.add(
        FilledButton.icon(
          onPressed: focus.advanceToNextPhase,
          icon: const Icon(Icons.play_circle_outline_rounded),
          label: Text(i18n.t('startNextRound')),
        ),
      );
    } else {
      buttons.add(
        FilledButton.icon(
          onPressed: timerState.isPaused ? focus.resume : focus.pause,
          icon: Icon(
            timerState.isPaused
                ? Icons.play_arrow_rounded
                : Icons.pause_rounded,
          ),
          label: Text(i18n.t(timerState.isPaused ? 'resume' : 'pause')),
        ),
      );
      buttons.add(
        OutlinedButton.icon(
          onPressed: focus.skip,
          icon: const Icon(Icons.skip_next_rounded),
          label: Text(i18n.t('skip')),
        ),
      );
    }
    buttons.add(
      OutlinedButton.icon(
        onPressed: () => focus.setLockScreenActive(true),
        icon: const Icon(Icons.lock_rounded),
        label: Text(
          pickUiText(
            i18n,
            zh: '锁屏专注',
            en: 'Lock focus',
            ja: '集中をロック',
            de: 'Fokus sperren',
            fr: 'Verrouiller le focus',
            es: 'Bloquear enfoque',
            ru: 'Заблокировать фокус',
          ),
        ),
      ),
    );
    buttons.add(
      OutlinedButton.icon(
        onPressed: () => _confirmStop(focus, i18n),
        icon: const Icon(Icons.stop_rounded),
        label: Text(i18n.t('stop')),
      ),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              pickUiText(i18n, zh: '当前操作', en: 'Current actions'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              pickUiText(
                i18n,
                zh: '保持当前专注节奏，下一步操作会在这里集中显示。',
                en: 'Keep the current focus flow moving with the next actions collected here.',
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final availableWidth = constraints.maxWidth;
                final isSingleColumn = availableWidth < 460;
                final buttonWidth = isSingleColumn
                    ? availableWidth
                    : ((availableWidth - 12) / 2).clamp(180.0, availableWidth);

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: buttons
                      .map(
                        (button) => SizedBox(width: buttonWidth, child: button),
                      )
                      .toList(growable: false),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerConfig(
    FocusService focus,
    TomatoTimerConfig config,
    AppI18n i18n,
    double maxWidth,
    AppWidthTier widthTier,
  ) {
    final contentWidth = (maxWidth - 32).clamp(0.0, maxWidth).toDouble();
    final itemWidth = _responsiveItemWidth(contentWidth, widthTier, columns: 2);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SectionHeader(
              title: i18n.t('timerConfig'),
              subtitle: pickUiText(
                i18n,
                zh: '专注时长、休息节奏与提醒方式会在这里统一调整。',
                en: 'Tune session length, break cadence, and reminders in one place.',
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: <Widget>[
                SizedBox(
                  width: itemWidth,
                  child: _buildDurationCard(
                    label: i18n.t('focusMinutes'),
                    totalSeconds: config.focusDurationSeconds,
                    i18n: i18n,
                    onChanged: (seconds) => focus.saveConfig(
                      config.copyWith(focusDurationSeconds: seconds),
                    ),
                  ),
                ),
                SizedBox(
                  width: itemWidth,
                  child: _buildDurationCard(
                    label: i18n.t('breakMinutes'),
                    totalSeconds: config.breakDurationSeconds,
                    i18n: i18n,
                    onChanged: (seconds) => focus.saveConfig(
                      config.copyWith(breakDurationSeconds: seconds),
                    ),
                  ),
                ),
                SizedBox(
                  width: itemWidth,
                  child: _buildConfigField(
                    label: i18n.t('rounds'),
                    value: config.rounds,
                    min: 1,
                    max: 12,
                    onChanged: (value) =>
                        focus.saveConfig(config.copyWith(rounds: value)),
                  ),
                ),
                SizedBox(
                  width: itemWidth,
                  child: _buildReminderCard(focus, config, i18n),
                ),
                SizedBox(
                  width: itemWidth,
                  child: _buildConfigToggle(
                    label: i18n.t('autoStartBreak'),
                    value: config.autoStartBreak,
                    onChanged: (value) => focus.saveConfig(
                      config.copyWith(autoStartBreak: value),
                    ),
                  ),
                ),
                SizedBox(
                  width: itemWidth,
                  child: _buildConfigToggle(
                    label: i18n.t('autoStartNextRound'),
                    value: config.autoStartNextRound,
                    onChanged: (value) => focus.saveConfig(
                      config.copyWith(autoStartNextRound: value),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationCard({
    required String label,
    required int totalSeconds,
    required AppI18n i18n,
    required ValueChanged<int> onChanged,
  }) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(label, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            Text(
              _formatUnitSummary(totalSeconds, i18n),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: () => _showDurationPicker(
                  title: label,
                  totalSeconds: totalSeconds,
                  i18n: i18n,
                  onChanged: onChanged,
                ),
                icon: const Icon(Icons.tune_rounded),
                label: Text(
                  pickUiText(
                    i18n,
                    zh: '滚轮精调',
                    en: 'Wheel picker',
                    ja: 'ホイールで調整',
                    de: 'Mit Rad anpassen',
                    fr: 'Ajuster avec la molette',
                    es: 'Ajustar con rueda',
                    ru: 'Настроить колесом',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDurationPicker({
    required String title,
    required int totalSeconds,
    required AppI18n i18n,
    required ValueChanged<int> onChanged,
  }) async {
    var draft = Duration(seconds: totalSeconds.clamp(1, 359999));
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      enableDrag: false,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            /*
            final resolvedVoiceHelperText =
                voiceInputProvider == VoiceInputProviderType.system
                ? voiceHelperText
                : (voiceError ??
                          (_noteVoiceRecordingHelperText(
                                i18n,
                                voiceState,
                                speechLanguageTag,
                                voiceInputProvider,
                              ) +
                              (voiceState == _NoteVoiceInputState.idle
                                  ? ' ${pickUiText(
                                      i18n,
                                      zh: '识别结果会追加到正文，标题留空时会自动生成摘要。',
                                      en: 'Transcribed text is appended to the note body, and an empty title will be auto-filled.',
                                    )}'
                                  : '')));

            */
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    _formatUnitSummary(draft.inSeconds, i18n),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 220,
                    child: CupertinoTimerPicker(
                      mode: CupertinoTimerPickerMode.hms,
                      initialTimerDuration: draft,
                      onTimerDurationChanged: (value) {
                        setSheetState(() {
                          draft = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        child: Text(i18n.t('cancel')),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () {
                          onChanged(draft.inSeconds.clamp(1, 359999));
                          Navigator.of(sheetContext).pop();
                        },
                        child: Text(i18n.t('save')),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildReminderCard(
    FocusService focus,
    TomatoTimerConfig config,
    AppI18n i18n,
  ) {
    final theme = Theme.of(context);
    final reminder = config.reminder;

    Widget buildSwitch({
      required String label,
      required bool value,
      required TimerReminderConfig Function(bool next) map,
    }) {
      return SwitchListTile.adaptive(
        dense: true,
        contentPadding: EdgeInsets.zero,
        title: Text(label, style: theme.textTheme.bodyMedium),
        value: value,
        onChanged: (next) => focus.saveReminderConfig(map(next)),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(i18n.t('reminderSettings'), style: theme.textTheme.bodyMedium),
            const SizedBox(height: 6),
            buildSwitch(
              label: i18n.t('reminderHaptic'),
              value: reminder.haptic,
              map: (next) => reminder.copyWith(haptic: next),
            ),
            buildSwitch(
              label: i18n.t('reminderSound'),
              value: reminder.sound,
              map: (next) => reminder.copyWith(sound: next),
            ),
            buildSwitch(
              label: i18n.t('reminderVoice'),
              value: reminder.voice,
              map: (next) => reminder.copyWith(voice: next),
            ),
            buildSwitch(
              label: i18n.t('reminderPauseAmbient'),
              value: reminder.pauseAmbient,
              map: (next) => reminder.copyWith(pauseAmbient: next),
            ),
            buildSwitch(
              label: i18n.t('reminderVisual'),
              value: reminder.visual,
              map: (next) => reminder.copyWith(visual: next),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigField({
    required String label,
    required int value,
    int min = 1,
    int max = 60,
    required ValueChanged<int> onChanged,
  }) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(label, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                IconButton(
                  onPressed: value > min ? () => onChanged(value - 1) : null,
                  icon: const Icon(Icons.remove_rounded),
                ),
                Expanded(
                  child: Text(
                    '$value',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  onPressed: value < max ? () => onChanged(value + 1) : null,
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigToggle({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: SwitchListTile.adaptive(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        title: Text(label),
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildTodayStats(
    FocusService focus,
    AppI18n i18n,
    double maxWidth,
    AppWidthTier widthTier,
  ) {
    final contentWidth = (maxWidth - 32).clamp(0.0, maxWidth).toDouble();
    final itemWidth = _responsiveItemWidth(contentWidth, widthTier, columns: 3);
    final items = <_StatItem>[
      _StatItem(
        icon: Icons.timer_outlined,
        value: '${focus.getTodayFocusMinutes()}',
        label: i18n.t('focusMinutesLabel'),
      ),
      _StatItem(
        icon: Icons.schedule_rounded,
        value: '${focus.getTodaySessionMinutes()}',
        label: i18n.t('sessionMinutesLabel'),
      ),
      _StatItem(
        icon: Icons.refresh_rounded,
        value: '${focus.getTodayRoundsCompleted()}',
        label: i18n.t('roundsLabel'),
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SectionHeader(
              title: i18n.t('todayStats'),
              subtitle: pickUiText(
                i18n,
                zh: '今天的专注投入会按相同宽度的统计卡展示。',
                en: 'Today’s focus progress is summarized in equal-width cards.',
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: items
                  .map(
                    (item) => SizedBox(
                      width: itemWidth,
                      height: 122,
                      child: _buildStatCard(item),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(_StatItem item) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: <Widget>[
            Icon(item.icon, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text(item.value, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              item.label,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkspaceTab(
    FocusService focus,
    List<PlanNote> notes,
    AppI18n i18n,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final widthTier = AppWidthBreakpoints.tierFor(constraints.maxWidth);
        final contentWidth = math.min(
          constraints.maxWidth,
          _pageContentMaxWidth(widthTier),
        );
        final compactWorkspace = constraints.maxWidth < 600;
        final outerPadding = compactWorkspace ? 12.0 : 16.0;
        if (compactWorkspace) {
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: contentWidth),
              child: Padding(
                padding: EdgeInsets.all(outerPadding),
                child: _buildTodoPanel(focus, i18n, notes: notes),
              ),
            ),
          );
        }
        final layoutWidth = math.max(0.0, contentWidth - outerPadding * 2);
        final drawerWidth = _notesDrawerWidth(layoutWidth, focus);
        final railWidth = 60.0;
        final railGutter = railWidth + 10.0;
        final hiddenOffset = drawerWidth - railWidth;
        final progress = _notesDrawerProgress.clamp(0.0, 1.0).toDouble();

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: contentWidth),
            child: Padding(
              padding: EdgeInsets.all(outerPadding),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: progress, end: progress),
                duration: _notesDrawerDragging
                    ? Duration.zero
                    : const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                builder: (context, animatedProgress, _) {
                  return Stack(
                    children: <Widget>[
                      Positioned(
                        top: 0,
                        left: 0,
                        bottom: 0,
                        right: railGutter,
                        child: Transform.translate(
                          offset: Offset(-12 * animatedProgress, 0),
                          child: _buildTodoPanel(focus, i18n, notes: notes),
                        ),
                      ),
                      if (animatedProgress > 0.01)
                        Positioned.fill(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _settleNotesDrawer(open: false),
                            onHorizontalDragStart: (_) {
                              setState(() {
                                _notesDrawerDragging = true;
                              });
                            },
                            onHorizontalDragUpdate: (details) =>
                                _updateNotesDrawerProgress(
                                  details.delta.dx,
                                  drawerWidth,
                                ),
                            onHorizontalDragEnd: (details) =>
                                _settleNotesDrawerFromVelocity(
                                  details.primaryVelocity ?? 0,
                                ),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(
                                  alpha: 0.04 + animatedProgress * 0.10,
                                ),
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        top: 0,
                        bottom: 0,
                        right: -hiddenOffset * (1 - animatedProgress),
                        child: _buildNotesDrawer(
                          focus: focus,
                          notes: notes,
                          i18n: i18n,
                          width: drawerWidth,
                          handleWidth: railWidth,
                          progress: animatedProgress,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  /*  String _mobileNotesLabel(AppI18n i18n) {
    return pickUiText(
      i18n,
        i18n,
        zh: '待办',
        en: 'Tasks',
        ja: 'タスク',
        de: 'Aufgaben',
        fr: 'Taches',
        es: 'Tareas',
        ru: 'Задачи',
      ),
      _WorkspacePane.notes => pickUiText(
        i18n,
        zh: '笔记',
        en: 'Notes',
        ja: 'ノート',
        de: 'Notizen',
        fr: 'Notes',
        es: 'Notas',
        ru: 'Заметки',
      ),
    };
  }

*/
  /*  String _mobileNotesLabel(AppI18n i18n) {
    return pickUiText(
      zh: '绗旇',
      en: 'Notes',
      ja: '銉庛兗銉?,
      de: 'Notizen',
      fr: 'Notes',
      es: 'Notas',
      ru: '袟邪屑械褌泻懈',
    );
  }

*/
  /*  Widget _buildTodoPanel(
    FocusService focus,
    AppI18n i18n, {
    int noteCount = 0,
    VoidCallback? onOpenNotes,
  }) {
    final todos = focus.getTodos();
    final theme = Theme.of(context);
    final filteredTodos = _filterTodos(todos);
    final displayTodos = _sortedTodos(filteredTodos);
    final planSections = _buildTodoPlanSections(filteredTodos, i18n);
    final manualSort =
        _todoSortMode == _TodoSortMode.manual &&
        _todoFilterMode == _TodoFilterMode.all;
    final metrics = _buildTodoMetrics(todos);

    return Card(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compactHeight =
              constraints.maxHeight.isFinite && constraints.maxHeight < 720;
          final topSectionMaxHeight = constraints.maxHeight.isFinite
              ? compactHeight
                    ? math.min(
                        288.0,
                        math.max(184.0, constraints.maxHeight * 0.42),
                      )
                    : math.min(
                        232.0,
                        math.max(152.0, constraints.maxHeight * 0.34),
                      )
              : 232.0;

          return Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: topSectionMaxHeight),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        if (constraints.maxWidth < 220)
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Flexible(
                                  fit: FlexFit.loose,
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      minWidth: 88,
                                    ),
                                    child: Text(
                                      i18n.t('todoTab'),
                                      style: theme.textTheme.titleMedium,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => _showTodoEditor(focus, i18n),
                                  style: TextButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 0,
                                    ),
                                    minimumSize: const Size(0, 32),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(i18n.t('addTodo')),
                                ),
                                IconButton(
                                  key: const ValueKey<String>(
                                    'todo-metrics-toggle',
                                  ),
                                  tooltip: _todoMetricsExpanded
                                      ? pickUiText(
                                          i18n,
                                          zh: '收起统计',
                                          en: 'Collapse stats',
                                          ja: '統計を折りたたむ',
                                          de: 'Statistiken einklappen',
                                          fr: 'Replier les statistiques',
                                          es: 'Contraer estadisticas',
                                          ru: 'Свернуть статистику',
                                        )
                                      : pickUiText(
                                          i18n,
                                          zh: '展开统计',
                                          en: 'Expand stats',
                                          ja: '統計を展開',
                                          de: 'Statistiken ausklappen',
                                          fr: 'Developper les statistiques',
                                          es: 'Expandir estadisticas',
                                          ru: 'Развернуть статистику',
                                        ),
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () {
                                    setState(() {
                                      _todoMetricsExpanded =
                                          !_todoMetricsExpanded;
                                    });
                                  },
                                  icon: Icon(
                                    _todoMetricsExpanded
                                        ? Icons.unfold_less_rounded
                                        : Icons.unfold_more_rounded,
                                  ),
                                ),
                                if (todos.any((item) => item.completed))
                                  IconButton(
                                    tooltip: i18n.t('clearCompleted'),
                                    visualDensity: VisualDensity.compact,
                                    onPressed: focus.clearCompletedTodos,
                                    icon: const Icon(Icons.done_all_rounded),
                                  ),
                              ],
                            ),
                          )
                        else
                          _buildTodoHeader(
                            focus: focus,
                            i18n: i18n,
                            theme: theme,
                            hasCompletedTodos: todos.any(
                              (item) => item.completed,
                            ),
                          ),
                        const SizedBox(height: 8),
                        _buildTodoMetricsStrip(metrics, i18n),
                        const SizedBox(height: 10),
                        TextField(
                          key: const ValueKey<String>('todo-editor-entry'),
                          readOnly: true,
                          onTap: () => _showTodoEditor(focus, i18n),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: i18n.t('todoInputTapHint'),
                            prefixIcon: const Icon(Icons.add_task_rounded),
                            suffixIcon: const Icon(Icons.open_in_full_rounded),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildTodoControls(i18n, manualSort: manualSort),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _todoViewMode == _TodoViewMode.plan
                      ? _buildTodoPlanView(focus, planSections, i18n)
                      : displayTodos.isEmpty
                      ? Center(child: Text(i18n.t('todosEmpty')))
                      : manualSort
                      ? _buildReorderableTodosList(focus, displayTodos, i18n)
                      : _buildSortedTodosList(focus, displayTodos, i18n),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

*/
  Widget _buildTodoPanel(
    FocusService focus,
    AppI18n i18n, {
    List<PlanNote> notes = const <PlanNote>[],
  }) {
    final todos = focus.getTodos();
    final theme = Theme.of(context);
    final filteredTodos = _filterTodos(todos);
    final displayTodos = _sortedTodos(filteredTodos);
    final planSections = _buildTodoPlanSections(filteredTodos, i18n);
    final manualSort =
        _todoSortMode == _TodoSortMode.manual &&
        _todoFilterMode == _TodoFilterMode.all;
    final metrics = _buildTodoMetrics(todos);

    return Card(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compactLayout = constraints.maxWidth < 600;
          if (compactLayout) {
            return _buildCompactTodoPanel(
              focus: focus,
              i18n: i18n,
              theme: theme,
              notes: notes,
              metrics: metrics,
              displayTodos: displayTodos,
              planSections: planSections,
              manualSort: manualSort,
              hasCompletedTodos: todos.any((item) => item.completed),
              constraints: constraints,
            );
          }
          final topSection = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildTodoHeader(
                focus: focus,
                i18n: i18n,
                theme: theme,
                hasCompletedTodos: todos.any((item) => item.completed),
                compactLayout: compactLayout,
              ),
              const SizedBox(height: 8),
              _buildTodoWorkspaceSummary(metrics, i18n, compact: false),
              const SizedBox(height: 8),
              TextField(
                key: const ValueKey<String>('todo-editor-entry'),
                readOnly: true,
                onTap: () => _showTodoEditor(focus, i18n),
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerLowest,
                  hintText: pickUiText(
                    i18n,
                    zh: '\u70b9\u51fb\u6dfb\u52a0\u5f85\u529e\u4e8b\u9879',
                    en: 'Tap to add a task',
                    ja: 'タップしてタスクを追加',
                    de: 'Tippen, um eine Aufgabe hinzuzufuegen',
                    fr: 'Touchez pour ajouter une tache',
                    es: 'Toca para anadir una tarea',
                    ru: 'Нажмите, чтобы добавить задачу',
                  ),
                  prefixIcon: const Icon(Icons.add_task_rounded),
                  suffixIcon: const Icon(Icons.edit_note_rounded),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _buildTodoControls(
                i18n,
                manualSort: manualSort,
                compact: compactLayout,
              ),
              const SizedBox(height: 12),
              _buildTodoListBody(
                focus: focus,
                i18n: i18n,
                planSections: planSections,
                displayTodos: displayTodos,
                manualSort: manualSort,
                scrollable: false,
              ),
            ],
          );

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(10),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: math.max(0.0, constraints.maxHeight - 20),
              ),
              child: topSection,
            ),
          );
        },
      ),
    );
  }

  Widget _buildCompactTodoPanel({
    required FocusService focus,
    required AppI18n i18n,
    required ThemeData theme,
    required List<PlanNote> notes,
    required Map<String, int> metrics,
    required List<TodoItem> displayTodos,
    required List<_TodoPlanSection> planSections,
    required bool manualSort,
    required bool hasCompletedTodos,
    required BoxConstraints constraints,
  }) {
    final listBody = _buildTodoListBody(
      focus: focus,
      i18n: i18n,
      planSections: planSections,
      displayTodos: displayTodos,
      manualSort: manualSort,
      scrollable: true,
    );

    final metricsRow = _buildTodoMetricsStrip(metrics, i18n, compact: true);

    final commandRow = _buildTodoControls(
      i18n,
      manualSort: manualSort,
      compact: true,
    );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildTodoHeader(
          focus: focus,
          i18n: i18n,
          theme: theme,
          hasCompletedTodos: hasCompletedTodos,
          compactLayout: true,
          actions: <Widget>[
            IconButton(
              key: const ValueKey<String>('todo-notes-sheet-button'),
              tooltip: i18n.t('quickNotes'),
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints.tightFor(width: 30, height: 30),
              padding: EdgeInsets.zero,
              onPressed: () => _showNotesSheet(focus, i18n),
              icon: const Icon(Icons.sticky_note_2_outlined),
            ),
            _buildTodoMetricsToggleButton(i18n),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          key: const ValueKey<String>('todo-editor-entry'),
          readOnly: true,
          onTap: () => _showTodoEditor(focus, i18n),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerLowest,
            hintText: pickUiText(i18n, zh: '快速添加待办', en: 'Quick add a task'),
            prefixIcon: const Icon(Icons.add_task_rounded),
            suffixIcon: const Icon(Icons.edit_note_rounded),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 9,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
          ),
        ),
        const SizedBox(height: 6),
        metricsRow,
        const SizedBox(height: 6),
        commandRow,
        const SizedBox(height: 10),
        Expanded(child: listBody),
      ],
    );

    if (!constraints.maxHeight.isFinite) {
      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildTodoHeader(
              focus: focus,
              i18n: i18n,
              theme: theme,
              hasCompletedTodos: hasCompletedTodos,
              compactLayout: true,
              actions: <Widget>[
                IconButton(
                  key: const ValueKey<String>('todo-notes-sheet-button'),
                  tooltip: i18n.t('quickNotes'),
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints.tightFor(
                    width: 30,
                    height: 30,
                  ),
                  padding: EdgeInsets.zero,
                  onPressed: () => _showNotesSheet(focus, i18n),
                  icon: const Icon(Icons.sticky_note_2_outlined),
                ),
                _buildTodoMetricsToggleButton(i18n),
              ],
            ),
            const SizedBox(height: 6),
            TextField(
              key: const ValueKey<String>('todo-editor-entry'),
              readOnly: true,
              onTap: () => _showTodoEditor(focus, i18n),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerLowest,
                hintText: pickUiText(
                  i18n,
                  zh: '快速添加待办',
                  en: 'Quick add a task',
                ),
                prefixIcon: const Icon(Icons.add_task_rounded),
                suffixIcon: const Icon(Icons.edit_note_rounded),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 9,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
            const SizedBox(height: 6),
            metricsRow,
            const SizedBox(height: 6),
            commandRow,
            const SizedBox(height: 10),
            _buildTodoListBody(
              focus: focus,
              i18n: i18n,
              planSections: planSections,
              displayTodos: displayTodos,
              manualSort: manualSort,
              scrollable: false,
            ),
          ],
        ),
      );
    }

    return Padding(padding: const EdgeInsets.all(10), child: content);
  }

  Widget _buildTodoListBody({
    required FocusService focus,
    required AppI18n i18n,
    required List<_TodoPlanSection> planSections,
    required List<TodoItem> displayTodos,
    required bool manualSort,
    bool scrollable = false,
  }) {
    if (_todoViewMode == _TodoViewMode.plan) {
      return _buildTodoPlanView(
        focus,
        planSections,
        i18n,
        scrollable: scrollable,
      );
    }
    if (displayTodos.isEmpty) {
      final theme = Theme.of(context);
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Text(
          i18n.t('todosEmpty'),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    return manualSort
        ? _buildReorderableTodosList(
            focus,
            displayTodos,
            i18n,
            scrollable: scrollable,
          )
        : _buildSortedTodosList(
            focus,
            displayTodos,
            i18n,
            scrollable: scrollable,
          );
  }

  Widget _buildTodoHeader({
    required FocusService focus,
    required AppI18n i18n,
    required ThemeData theme,
    required bool hasCompletedTodos,
    bool compactLayout = false,
    List<Widget> actions = const <Widget>[],
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: Text(
            i18n.t('todoTab'),
            style:
                (compactLayout
                        ? theme.textTheme.titleSmall
                        : theme.textTheme.titleMedium)
                    ?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        ...actions,
        if (hasCompletedTodos) _buildTodoClearCompletedButton(focus, i18n),
      ],
    );
  }

  Widget _buildTodoWorkspaceSummary(
    Map<String, int> metrics,
    AppI18n i18n, {
    bool compact = false,
  }) {
    return _buildTodoMetricsStrip(metrics, i18n, compact: compact);
  }
  /*
      i18n,
      zh: '$active 进行中 · $today 今日计划 · $completed 已完成',
      en: '$active active · $today due today · $completed done',
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.view_list_rounded,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              summaryText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          if (overdue > 0)
            _buildTodoSummaryPill(
              label: pickUiText(
                i18n,
                zh: '逾期 $overdue',
                en: '$overdue overdue',
              ),
              color: theme.colorScheme.error,
            ),
          if (deferred > 0) ...<Widget>[
            const SizedBox(width: 6),
            _buildTodoSummaryPill(
              label: pickUiText(
                i18n,
                zh: '搁置 $deferred',
                en: '$deferred deferred',
              ),
              color: theme.colorScheme.tertiary,
            ),
          ],
        ],
      ),
    );
  }

    */

  // ignore: unused_element
  Widget _buildTodoMetricOrbit({
    required Key key,
    required int value,
    required String label,
    required Color color,
    required bool compact,
  }) {
    final theme = Theme.of(context);
    final size = compact ? 56.0 : 64.0;
    return Tooltip(
      message: label,
      child: InkWell(
        key: key,
        borderRadius: BorderRadius.circular(size / 2),
        onTap: () {
          setState(() {
            _todoMetricsExpanded = !_todoMetricsExpanded;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: size,
          height: size,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            shape: BoxShape.circle,
            border: Border.all(
              color: color.withValues(
                alpha: _todoMetricsExpanded ? 0.48 : 0.22,
              ),
              width: _todoMetricsExpanded ? 1.4 : 1,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: color.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                width: compact ? 10 : 11,
                height: compact ? 10 : 11,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  '$value',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildTodoMetricsToggleButton(AppI18n i18n) {
    return IconButton(
      key: const ValueKey<String>('todo-metrics-toggle'),
      tooltip: _todoMetricsExpanded
          ? pickUiText(i18n, zh: '收起统计', en: 'Collapse stats')
          : pickUiText(i18n, zh: '展开统计', en: 'Expand stats'),
      visualDensity: VisualDensity.compact,
      onPressed: () {
        setState(() {
          _todoMetricsExpanded = !_todoMetricsExpanded;
        });
      },
      icon: Icon(
        _todoMetricsExpanded
            ? Icons.unfold_less_rounded
            : Icons.unfold_more_rounded,
      ),
    );
  }

  Widget _buildTodoClearCompletedButton(FocusService focus, AppI18n i18n) {
    return IconButton(
      tooltip: i18n.t('clearCompleted'),
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 30, height: 30),
      padding: EdgeInsets.zero,
      onPressed: focus.clearCompletedTodos,
      icon: const Icon(Icons.done_all_rounded),
    );
  }

  Map<String, int> _buildTodoMetrics(List<TodoItem> todos) {
    final today = DateTime.now();
    final todayStart = _startOfDay(today);
    final tomorrowStart = todayStart.add(const Duration(days: 1));
    var active = 0;
    var completed = 0;
    var deferred = 0;
    var overdue = 0;
    var todayCount = 0;

    for (final todo in todos) {
      if (todo.completed) {
        completed += 1;
        continue;
      }
      if (todo.isDeferred) {
        deferred += 1;
        continue;
      }
      active += 1;
      final dueAt = todo.dueAt;
      if (dueAt == null) {
        continue;
      }
      if (dueAt.isBefore(todayStart)) {
        overdue += 1;
      } else if (dueAt.isBefore(tomorrowStart)) {
        todayCount += 1;
      }
    }

    return <String, int>{
      'all': todos.length,
      'active': active,
      'today': todayCount,
      'overdue': overdue,
      'deferred': deferred,
      'completed': completed,
    };
  }

  /*  Widget _buildTodoMetricsStrip(Map<String, int> metrics, AppI18n i18n) {
    final theme = Theme.of(context);
    final items = <({String key, String label, IconData icon, Color color})>[
      (
        key: 'active',
        label: pickUiText(
          i18n,
          zh: '进行中',
          en: 'Active',
          ja: '進行中',
          de: 'Aktiv',
          fr: 'Actives',
          es: 'Activas',
          ru: 'Активные',
        ),
        icon: Icons.flash_on_rounded,
        color: theme.colorScheme.primary,
      ),
      (
        key: 'today',
        label: pickUiText(
          i18n,
          zh: '今天到期',
          en: 'Due today',
          ja: '今日まで',
          de: 'Heute faellig',
          fr: 'Aujourd’hui',
          es: 'Para hoy',
          ru: 'На сегодня',
        ),
        icon: Icons.today_rounded,
        color: theme.colorScheme.tertiary,
      ),
      (
        key: 'overdue',
        label: pickUiText(
          i18n,
          zh: '已逾期',
          en: 'Overdue',
          ja: '期限超過',
          de: 'Ueberfaellig',
          fr: 'En retard',
          es: 'Vencidas',
          ru: 'Просрочено',
        ),
        icon: Icons.warning_amber_rounded,
        color: theme.colorScheme.error,
      ),
      (
        key: 'deferred',
        label: pickUiText(
          i18n,
          zh: '延后搁置',
          en: 'Deferred',
          ja: '保留中',
          de: 'Zurueckgestellt',
          fr: 'Reporte',
          es: 'Pospuestas',
          ru: 'Отложено',
        ),
        icon: Icons.snooze_rounded,
        color: theme.colorScheme.outline,
      ),
      (
        key: 'completed',
        label: pickUiText(
          i18n,
          zh: '已完成',
          en: 'Done',
          ja: '完了',
          de: 'Erledigt',
          fr: 'Terminees',
          es: 'Hechas',
          ru: 'Готово',
        ),
        icon: Icons.task_alt_rounded,
        color: theme.colorScheme.secondary,
      ),
    ];

    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: items
                  .asMap()
                  .entries
                  .map(
                    (entry) => Padding(
                      padding: EdgeInsets.only(
                        right: entry.key == items.length - 1 ? 0 : 8,
                      ),
                      child: _buildTodoMetricSummaryChip(
                        value: metrics[entry.value.key] ?? 0,
                        label: entry.value.label,
                        icon: entry.value.icon,
                        color: entry.value.color,
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
          if (_todoMetricsExpanded) ...<Widget>[
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth < 560 ? 2 : 5;
                final spacing = 8.0;
                final itemWidth =
                    (constraints.maxWidth - spacing * (columns - 1)) / columns;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: items
                      .map(
                        (item) => SizedBox(
                          key: ValueKey<String>('todo-metric-card-${item.key}'),
                          width: itemWidth.isFinite
                              ? math.max(0, itemWidth)
                              : constraints.maxWidth,
                          child: _buildTodoMetricCard(
                            value: metrics[item.key] ?? 0,
                            label: item.label,
                            icon: item.icon,
                            color: item.color,
                          ),
                        ),
                      )
                      .toList(growable: false),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

*/
  /*  List<({String key, String label, IconData icon, Color color})>
  _todoMetricItems(AppI18n i18n, ThemeData theme) {
    return <({String key, String label, IconData icon, Color color})>[
      (
        key: 'active',
        label: pickUiText(
          i18n,
          zh: '杩涜涓?,
          en: 'Active',
          ja: '閫茶涓?,
          de: 'Aktiv',
          fr: 'Actives',
          es: 'Activas',
          ru: '袗泻褌懈胁薪褘械',
        ),
        icon: Icons.flash_on_rounded,
        color: theme.colorScheme.primary,
      ),
      (
        key: 'today',
        label: pickUiText(
          i18n,
          zh: '浠婂ぉ鍒版湡',
          en: 'Due today',
          ja: '浠婃棩銇俱仹',
          de: 'Heute faellig',
          fr: 'Aujourd鈥檋ui',
          es: 'Para hoy',
          ru: '袧邪 褋械谐芯写薪褟',
        ),
        icon: Icons.today_rounded,
        color: theme.colorScheme.tertiary,
      ),
      (
        key: 'overdue',
        label: pickUiText(
          i18n,
          zh: '宸查€炬湡',
          en: 'Overdue',
          ja: '鏈熼檺瓒呴亷',
          de: 'Ueberfaellig',
          fr: 'En retard',
          es: 'Vencidas',
          ru: '袩褉芯褋褉芯褔械薪芯',
        ),
        icon: Icons.warning_amber_rounded,
        color: theme.colorScheme.error,
      ),
      (
        key: 'deferred',
        label: pickUiText(
          i18n,
          zh: '寤跺悗鎼佺疆',
          en: 'Deferred',
          ja: '淇濈暀涓?,
          de: 'Zurueckgestellt',
          fr: 'Reporte',
          es: 'Pospuestas',
          ru: '袨褌谢芯卸械薪芯',
        ),
        icon: Icons.snooze_rounded,
        color: theme.colorScheme.outline,
      ),
      (
        key: 'completed',
        label: pickUiText(
          i18n,
          zh: '宸插畬鎴?,
          en: 'Done',
          ja: '瀹屼簡',
          de: 'Erledigt',
          fr: 'Terminees',
          es: 'Hechas',
          ru: '袚芯褌芯胁芯',
        ),
        icon: Icons.task_alt_rounded,
        color: theme.colorScheme.secondary,
      ),
    ];
  }

*/
  List<({String key, String label, IconData icon, Color color})>
  _todoMetricItems(AppI18n i18n, ThemeData theme) {
    return <({String key, String label, IconData icon, Color color})>[
      (
        key: 'all',
        label: _todoFilterModeLabel(i18n, _TodoFilterMode.all),
        icon: Icons.apps_rounded,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      (
        key: 'active',
        label: _todoFilterModeLabel(i18n, _TodoFilterMode.active),
        icon: Icons.flash_on_rounded,
        color: theme.colorScheme.primary,
      ),
      (
        key: 'today',
        label: _todoFilterModeLabel(i18n, _TodoFilterMode.today),
        icon: Icons.today_rounded,
        color: theme.colorScheme.tertiary,
      ),
      (
        key: 'overdue',
        label: _todoFilterModeLabel(i18n, _TodoFilterMode.overdue),
        icon: Icons.warning_amber_rounded,
        color: theme.colorScheme.error,
      ),
      (
        key: 'deferred',
        label: _todoFilterModeLabel(i18n, _TodoFilterMode.deferred),
        icon: Icons.snooze_rounded,
        color: theme.colorScheme.outline,
      ),
      (
        key: 'completed',
        label: _todoFilterModeLabel(i18n, _TodoFilterMode.completed),
        icon: Icons.task_alt_rounded,
        color: theme.colorScheme.secondary,
      ),
    ];
  }

  Widget _buildTodoMetricsStrip(
    Map<String, int> metrics,
    AppI18n i18n, {
    bool compact = false,
  }) {
    final theme = Theme.of(context);
    final items = _todoMetricItems(i18n, theme);

    return Wrap(
      spacing: compact ? 6 : 8,
      runSpacing: compact ? 6 : 8,
      children: items
          .map(
            (item) => _buildTodoMetricCompactBadge(
              key: ValueKey<String>('todo-metric-badge-${item.key}'),
              metricKey: item.key,
              value: metrics[item.key] ?? 0,
              label: item.label,
              color: item.color,
              compact: compact,
            ),
          )
          .toList(growable: false),
    );
  }

  Widget _buildTodoMetricCompactBadge({
    required Key key,
    required String metricKey,
    required int value,
    required String label,
    required Color color,
    bool compact = false,
  }) {
    final theme = Theme.of(context);
    final filterMode = _todoFilterModeForMetricKey(metricKey);
    final expanded =
        _todoMetricsExpanded || _expandedTodoMetricKey == metricKey;
    final selected = _todoFilterMode == filterMode;
    final emphasized = expanded || selected;

    return Tooltip(
      message: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: key,
          borderRadius: BorderRadius.circular(999),
          onTap: () {
            setState(() {
              _todoFilterMode = filterMode;
              if (_todoMetricsExpanded) {
                _expandedTodoMetricKey = metricKey;
              } else {
                _expandedTodoMetricKey = expanded && selected
                    ? null
                    : metricKey;
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: expanded ? (compact ? 10 : 12) : (compact ? 8 : 10),
              vertical: compact ? 7 : 8,
            ),
            decoration: BoxDecoration(
              color: color.withValues(
                alpha: emphasized ? (selected ? 0.18 : 0.15) : 0.08,
              ),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: color.withValues(alpha: emphasized ? 0.38 : 0.18),
                width: selected ? 1.4 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '$value',
                  style:
                      (compact
                              ? theme.textTheme.labelLarge
                              : theme.textTheme.titleSmall)
                          ?.copyWith(
                            color: selected
                                ? color
                                : theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w800,
                          ),
                ),
                if (expanded) ...<Widget>[
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  _TodoFilterMode _todoFilterModeForMetricKey(String metricKey) {
    return switch (metricKey) {
      'all' => _TodoFilterMode.all,
      'active' => _TodoFilterMode.active,
      'today' => _TodoFilterMode.today,
      'overdue' => _TodoFilterMode.overdue,
      'deferred' => _TodoFilterMode.deferred,
      'completed' => _TodoFilterMode.completed,
      _ => _TodoFilterMode.all,
    };
  }

  /*  Widget _buildTodoControls(AppI18n i18n, {required bool manualSort}) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      key: const ValueKey<String>('todo-controls'),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildTodoControlSection(
            label: pickUiText(
              i18n,
              zh: '视图',
              en: 'View',
              ja: '表示',
              de: 'Ansicht',
              fr: 'Vue',
              es: 'Vista',
              ru: 'Вид',
            ),
            children: <Widget>[
              _buildTodoChoiceChip(
                key: const ValueKey<String>('todo-view-plan'),
                label: pickUiText(
                  i18n,
                  zh: '计划视图',
                  en: 'Plan view',
                  ja: '計画ビュー',
                  de: 'Planansicht',
                  fr: 'Vue planning',
                  es: 'Vista de plan',
                  ru: 'План',
                ),
                selected: _todoViewMode == _TodoViewMode.plan,
                onSelected: () {
                  setState(() {
                    _todoViewMode = _TodoViewMode.plan;
                  });
                },
              ),
              _buildTodoChoiceChip(
                key: const ValueKey<String>('todo-view-list'),
                label: pickUiText(
                  i18n,
                  zh: '列表视图',
                  en: 'List view',
                  ja: 'リストビュー',
                  de: 'Listenansicht',
                  fr: 'Vue liste',
                  es: 'Vista de lista',
                  ru: 'Список',
                ),
                selected: _todoViewMode == _TodoViewMode.list,
                onSelected: () {
                  setState(() {
                    _todoViewMode = _TodoViewMode.list;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildTodoControlSection(
            label: pickUiText(
              i18n,
              zh: '筛选',
              en: 'Filter',
              ja: '絞り込み',
              de: 'Filter',
              fr: 'Filtre',
              es: 'Filtro',
              ru: 'Фильтр',
            ),
            children: <Widget>[
              _buildTodoChoiceChip(
                key: const ValueKey<String>('todo-filter-all'),
                label: pickUiText(
                  i18n,
                  zh: '全部',
                  en: 'All',
                  ja: 'すべて',
                  de: 'Alle',
                  fr: 'Tous',
                  es: 'Todo',
                  ru: 'Все',
                ),
                selected: _todoFilterMode == _TodoFilterMode.all,
                onSelected: () {
                  setState(() {
                    _todoFilterMode = _TodoFilterMode.all;
                  });
                },
              ),
              _buildTodoChoiceChip(
                key: const ValueKey<String>('todo-filter-active'),
                label: pickUiText(
                  i18n,
                  zh: '进行中',
                  en: 'Active',
                  ja: '進行中',
                  de: 'Aktiv',
                  fr: 'Actives',
                  es: 'Activas',
                  ru: 'Активные',
                ),
                selected: _todoFilterMode == _TodoFilterMode.active,
                onSelected: () {
                  setState(() {
                    _todoFilterMode = _TodoFilterMode.active;
                  });
                },
              ),
              _buildTodoChoiceChip(
                key: const ValueKey<String>('todo-filter-deferred'),
                label: pickUiText(
                  i18n,
                  zh: '延后搁置',
                  en: 'Deferred',
                  ja: '保留中',
                  de: 'Zurueckgestellt',
                  fr: 'Reporte',
                  es: 'Pospuestas',
                  ru: 'Отложено',
                ),
                selected: _todoFilterMode == _TodoFilterMode.deferred,
                onSelected: () {
                  setState(() {
                    _todoFilterMode = _TodoFilterMode.deferred;
                  });
                },
              ),
              _buildTodoChoiceChip(
                key: const ValueKey<String>('todo-filter-completed'),
                label: pickUiText(
                  i18n,
                  zh: '已完成',
                  en: 'Completed',
                  ja: '完了',
                  de: 'Erledigt',
                  fr: 'Terminées',
                  es: 'Completadas',
                  ru: 'Выполненные',
                ),
                selected: _todoFilterMode == _TodoFilterMode.completed,
                onSelected: () {
                  setState(() {
                    _todoFilterMode = _TodoFilterMode.completed;
                  });
                },
              ),
            ],
          ),
          if (_todoViewMode == _TodoViewMode.list) ...<Widget>[
            const SizedBox(height: 8),
            _buildTodoControlSection(
              label: pickUiText(
                i18n,
                zh: '排序',
                en: 'Sort',
                ja: '並び替え',
                de: 'Sortierung',
                fr: 'Tri',
                es: 'Orden',
                ru: 'Сортировка',
              ),
              children: <Widget>[
                _buildTodoChoiceChip(
                  label: i18n.t('dragToReorder'),
                  selected: manualSort,
                  onSelected: () {
                    setState(() {
                      _todoSortMode = _TodoSortMode.manual;
                    });
                  },
                ),
                _buildTodoChoiceChip(
                  label: i18n.t('todoPriority'),
                  selected: _todoSortMode == _TodoSortMode.priority,
                  onSelected: () {
                    setState(() {
                      _todoSortMode = _TodoSortMode.priority;
                    });
                  },
                ),
                _buildTodoChoiceChip(
                  label: i18n.t('todoCategory'),
                  selected: _todoSortMode == _TodoSortMode.category,
                  onSelected: () {
                    setState(() {
                      _todoSortMode = _TodoSortMode.category;
                    });
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

*/
  /*  String _todoViewModeLabel(AppI18n i18n, _TodoViewMode mode) {
    return switch (mode) {
      _TodoViewMode.plan => pickUiText(
          i18n,
          zh: '璁″垝瑙嗗浘',
          en: 'Plan view',
          ja: '瑷堢敾銉撱儱銉?,
          de: 'Planansicht',
          fr: 'Vue planning',
          es: 'Vista de plan',
          ru: '袩谢邪薪',
        ),
      _TodoViewMode.list => pickUiText(
          i18n,
          zh: '鍒楄〃瑙嗗浘',
          en: 'List view',
          ja: '銉偣銉堛儞銉ャ兗',
          de: 'Listenansicht',
          fr: 'Vue liste',
          es: 'Vista de lista',
          ru: '小锌懈褋芯泻',
        ),
    };
  }

  String _todoFilterModeLabel(AppI18n i18n, _TodoFilterMode mode) {
    return switch (mode) {
      _TodoFilterMode.all => pickUiText(
          i18n,
          zh: '鍏ㄩ儴',
          en: 'All',
          ja: '銇欍伖銇?,
          de: 'Alle',
          fr: 'Tous',
          es: 'Todo',
          ru: '袙褋械',
        ),
      _TodoFilterMode.active => pickUiText(
          i18n,
          zh: '杩涜涓?,
          en: 'Active',
          ja: '閫茶涓?,
          de: 'Aktiv',
          fr: 'Actives',
          es: 'Activas',
          ru: '袗泻褌懈胁薪褘械',
        ),
      _TodoFilterMode.deferred => pickUiText(
          i18n,
          zh: '寤跺悗鎼佺疆',
          en: 'Deferred',
          ja: '淇濈暀涓?,
          de: 'Zurueckgestellt',
          fr: 'Reporte',
          es: 'Pospuestas',
          ru: '袨褌谢芯卸械薪芯',
        ),
      _TodoFilterMode.completed => pickUiText(
          i18n,
          zh: '宸插畬鎴?,
          en: 'Completed',
          ja: '瀹屼簡',
          de: 'Erledigt',
          fr: 'Terminees',
          es: 'Completadas',
          ru: '袙褘锌芯谢薪械薪薪褘械',
        ),
    };
  }

*/
  String _todoViewModeLabel(AppI18n i18n, _TodoViewMode mode) {
    return switch (mode) {
      _TodoViewMode.plan => pickUiText(
        i18n,
        zh: '\u8ba1\u5212\u89c6\u56fe',
        en: 'Plan view',
      ),
      _TodoViewMode.list => pickUiText(
        i18n,
        zh: '\u5217\u8868\u89c6\u56fe',
        en: 'List view',
      ),
    };
  }

  String _todoFilterModeLabel(AppI18n i18n, _TodoFilterMode mode) {
    return switch (mode) {
      _TodoFilterMode.all => pickUiText(i18n, zh: '\u5168\u90e8', en: 'All'),
      _TodoFilterMode.active => pickUiText(
        i18n,
        zh: '\u8fdb\u884c\u4e2d',
        en: 'Active',
      ),
      _TodoFilterMode.today => pickUiText(
        i18n,
        zh: '\u4eca\u5929\u5230\u671f',
        en: 'Due today',
      ),
      _TodoFilterMode.overdue => pickUiText(
        i18n,
        zh: '\u5df2\u903e\u671f',
        en: 'Overdue',
      ),
      _TodoFilterMode.deferred => pickUiText(
        i18n,
        zh: '\u5ef6\u540e\u6401\u7f6e',
        en: 'Deferred',
      ),
      _TodoFilterMode.completed => pickUiText(
        i18n,
        zh: '\u5df2\u5b8c\u6210',
        en: 'Completed',
      ),
    };
  }

  String _todoSortModeLabel(AppI18n i18n, _TodoSortMode mode) {
    return switch (mode) {
      _TodoSortMode.manual => i18n.t('dragToReorder'),
      _TodoSortMode.priority => i18n.t('todoPriority'),
      _TodoSortMode.category => i18n.t('todoCategory'),
    };
  }

  /*  Widget _buildTodoControls(
    AppI18n i18n, {
    required bool manualSort,
    bool compact = false,
  }) {
    final theme = Theme.of(context);
    if (compact) {
      return Container(
        width: double.infinity,
        key: const ValueKey<String>('todo-controls'),
        padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Wrap(
          spacing: 6,
          runSpacing: 6,
          children: <Widget>[
            _buildTodoCompactMenuButton<_TodoViewMode>(
              key: const ValueKey<String>('todo-view-menu'),
              icon: Icons.view_week_rounded,
              label: _todoViewModeLabel(i18n, _todoViewMode),
              items: <PopupMenuEntry<_TodoViewMode>>[
                CheckedPopupMenuItem<_TodoViewMode>(
                  key: const ValueKey<String>('todo-view-plan'),
                  value: _TodoViewMode.plan,
                  checked: _todoViewMode == _TodoViewMode.plan,
                  child: Text(_todoViewModeLabel(i18n, _TodoViewMode.plan)),
                ),
                CheckedPopupMenuItem<_TodoViewMode>(
                  key: const ValueKey<String>('todo-view-list'),
                  value: _TodoViewMode.list,
                  checked: _todoViewMode == _TodoViewMode.list,
                  child: Text(_todoViewModeLabel(i18n, _TodoViewMode.list)),
                ),
              ],
              onSelected: (value) {
                setState(() {
                  _todoViewMode = value;
                });
              },
            ),
            if (_todoViewMode == _TodoViewMode.list)
              _buildTodoCompactMenuButton<_TodoSortMode>(
                key: const ValueKey<String>('todo-sort-menu'),
                icon: Icons.swap_vert_rounded,
                label: _todoSortModeLabel(i18n, _todoSortMode),
                items: <PopupMenuEntry<_TodoSortMode>>[
                  CheckedPopupMenuItem<_TodoSortMode>(
                    key: const ValueKey<String>('todo-sort-manual'),
                    value: _TodoSortMode.manual,
                    checked: manualSort,
                    child: Text(_todoSortModeLabel(i18n, _TodoSortMode.manual)),
                  ),
                  CheckedPopupMenuItem<_TodoSortMode>(
                    key: const ValueKey<String>('todo-sort-priority'),
                    value: _TodoSortMode.priority,
                    checked: _todoSortMode == _TodoSortMode.priority,
                    child: Text(
                      _todoSortModeLabel(i18n, _TodoSortMode.priority),
                    ),
                  ),
                  CheckedPopupMenuItem<_TodoSortMode>(
                    key: const ValueKey<String>('todo-sort-category'),
                    value: _TodoSortMode.category,
                    checked: _todoSortMode == _TodoSortMode.category,
                    child: Text(
                      _todoSortModeLabel(i18n, _TodoSortMode.category),
                    ),
                  ),
                ],
                onSelected: (value) {
                  setState(() {
                    _todoSortMode = value;
                  });
                },
              ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      key: const ValueKey<String>('todo-controls'),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildTodoControlSection(
            label: pickUiText(
              i18n,
              zh: '瑙嗗浘',
              en: 'View',
              ja: '琛ㄧず',
              de: 'Ansicht',
              fr: 'Vue',
              es: 'Vista',
              ru: '袙懈写',
            ),
            children: <Widget>[
              _buildTodoChoiceChip(
                key: const ValueKey<String>('todo-view-plan'),
                label: _todoViewModeLabel(i18n, _TodoViewMode.plan),
                selected: _todoViewMode == _TodoViewMode.plan,
                onSelected: () {
                  setState(() {
                    _todoViewMode = _TodoViewMode.plan;
                  });
                },
              ),
              _buildTodoChoiceChip(
                key: const ValueKey<String>('todo-view-list'),
                label: _todoViewModeLabel(i18n, _TodoViewMode.list),
                selected: _todoViewMode == _TodoViewMode.list,
                onSelected: () {
                  setState(() {
                    _todoViewMode = _TodoViewMode.list;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildTodoControlSection(
            label: pickUiText(
              i18n,
              zh: '绛涢€?,
              en: 'Filter',
              ja: '绲炪倞杈笺伩',
              de: 'Filter',
              fr: 'Filtre',
              es: 'Filtro',
              ru: '肖懈谢褜褌褉',
            ),
            children: <Widget>[
              _buildTodoChoiceChip(
                key: const ValueKey<String>('todo-filter-all'),
                label: _todoFilterModeLabel(i18n, _TodoFilterMode.all),
                selected: _todoFilterMode == _TodoFilterMode.all,
                onSelected: () {
                  setState(() {
                    _todoFilterMode = _TodoFilterMode.all;
                  });
                },
              ),
              _buildTodoChoiceChip(
                key: const ValueKey<String>('todo-filter-active'),
                label: _todoFilterModeLabel(i18n, _TodoFilterMode.active),
                selected: _todoFilterMode == _TodoFilterMode.active,
                onSelected: () {
                  setState(() {
                    _todoFilterMode = _TodoFilterMode.active;
                  });
                },
              ),
              _buildTodoChoiceChip(
                key: const ValueKey<String>('todo-filter-deferred'),
                label: _todoFilterModeLabel(i18n, _TodoFilterMode.deferred),
                selected: _todoFilterMode == _TodoFilterMode.deferred,
                onSelected: () {
                  setState(() {
                    _todoFilterMode = _TodoFilterMode.deferred;
                  });
                },
              ),
              _buildTodoChoiceChip(
                key: const ValueKey<String>('todo-filter-completed'),
                label: _todoFilterModeLabel(i18n, _TodoFilterMode.completed),
                selected: _todoFilterMode == _TodoFilterMode.completed,
                onSelected: () {
                  setState(() {
                    _todoFilterMode = _TodoFilterMode.completed;
                  });
                },
              ),
            ],
          ),
          if (_todoViewMode == _TodoViewMode.list) ...<Widget>[
            const SizedBox(height: 8),
            _buildTodoControlSection(
              label: pickUiText(
                i18n,
                zh: '鎺掑簭',
                en: 'Sort',
                ja: '涓︺伋鏇裤亪',
                de: 'Sortierung',
                fr: 'Tri',
                es: 'Orden',
                ru: '小芯褉褌懈褉芯胁泻邪',
              ),
              children: <Widget>[
                _buildTodoChoiceChip(
                  key: const ValueKey<String>('todo-sort-manual'),
                  label: _todoSortModeLabel(i18n, _TodoSortMode.manual),
                  selected: manualSort,
                  onSelected: () {
                    setState(() {
                      _todoSortMode = _TodoSortMode.manual;
                    });
                  },
                ),
                _buildTodoChoiceChip(
                  key: const ValueKey<String>('todo-sort-priority'),
                  label: _todoSortModeLabel(i18n, _TodoSortMode.priority),
                  selected: _todoSortMode == _TodoSortMode.priority,
                  onSelected: () {
                    setState(() {
                      _todoSortMode = _TodoSortMode.priority;
                    });
                  },
                ),
                _buildTodoChoiceChip(
                  key: const ValueKey<String>('todo-sort-category'),
                  label: _todoSortModeLabel(i18n, _TodoSortMode.category),
                  selected: _todoSortMode == _TodoSortMode.category,
                  onSelected: () {
                    setState(() {
                      _todoSortMode = _TodoSortMode.category;
                    });
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

*/
  Widget _buildTodoControls(
    AppI18n i18n, {
    required bool manualSort,
    bool compact = false,
  }) {
    final theme = Theme.of(context);
    if (compact) {
      return Container(
        width: double.infinity,
        key: const ValueKey<String>('todo-controls'),
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            _buildTodoCompactMenuButton<_TodoViewMode>(
              key: const ValueKey<String>('todo-view-menu'),
              icon: Icons.view_week_rounded,
              label: _todoViewModeLabel(i18n, _todoViewMode),
              items: <PopupMenuEntry<_TodoViewMode>>[
                CheckedPopupMenuItem<_TodoViewMode>(
                  key: const ValueKey<String>('todo-view-plan'),
                  value: _TodoViewMode.plan,
                  checked: _todoViewMode == _TodoViewMode.plan,
                  child: Text(_todoViewModeLabel(i18n, _TodoViewMode.plan)),
                ),
                CheckedPopupMenuItem<_TodoViewMode>(
                  key: const ValueKey<String>('todo-view-list'),
                  value: _TodoViewMode.list,
                  checked: _todoViewMode == _TodoViewMode.list,
                  child: Text(_todoViewModeLabel(i18n, _TodoViewMode.list)),
                ),
              ],
              onSelected: (value) {
                setState(() {
                  _todoViewMode = value;
                });
              },
            ),
            _buildTodoCompactMenuButton<_TodoFilterMode>(
              key: const ValueKey<String>('todo-filter-menu'),
              icon: Icons.filter_alt_rounded,
              label: _todoFilterModeLabel(i18n, _todoFilterMode),
              items: _buildTodoFilterMenuItems(i18n),
              onSelected: (value) {
                setState(() {
                  _todoFilterMode = value;
                  _expandedTodoMetricKey = null;
                });
              },
            ),
            if (_todoViewMode == _TodoViewMode.list)
              _buildTodoCompactMenuButton<_TodoSortMode>(
                key: const ValueKey<String>('todo-sort-menu'),
                icon: Icons.swap_vert_rounded,
                label: _todoSortModeLabel(i18n, _todoSortMode),
                items: <PopupMenuEntry<_TodoSortMode>>[
                  CheckedPopupMenuItem<_TodoSortMode>(
                    key: const ValueKey<String>('todo-sort-manual'),
                    value: _TodoSortMode.manual,
                    checked: manualSort,
                    child: Text(_todoSortModeLabel(i18n, _TodoSortMode.manual)),
                  ),
                  CheckedPopupMenuItem<_TodoSortMode>(
                    key: const ValueKey<String>('todo-sort-priority'),
                    value: _TodoSortMode.priority,
                    checked: _todoSortMode == _TodoSortMode.priority,
                    child: Text(
                      _todoSortModeLabel(i18n, _TodoSortMode.priority),
                    ),
                  ),
                  CheckedPopupMenuItem<_TodoSortMode>(
                    key: const ValueKey<String>('todo-sort-category'),
                    value: _TodoSortMode.category,
                    checked: _todoSortMode == _TodoSortMode.category,
                    child: Text(
                      _todoSortModeLabel(i18n, _TodoSortMode.category),
                    ),
                  ),
                ],
                onSelected: (value) {
                  setState(() {
                    _todoSortMode = value;
                  });
                },
              ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      key: const ValueKey<String>('todo-controls'),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildTodoControlSection(
            label: pickUiText(i18n, zh: '\u89c6\u56fe', en: 'View'),
            children: <Widget>[
              _buildTodoChoiceChip(
                key: const ValueKey<String>('todo-view-plan'),
                label: _todoViewModeLabel(i18n, _TodoViewMode.plan),
                selected: _todoViewMode == _TodoViewMode.plan,
                onSelected: () {
                  setState(() {
                    _todoViewMode = _TodoViewMode.plan;
                  });
                },
              ),
              _buildTodoChoiceChip(
                key: const ValueKey<String>('todo-view-list'),
                label: _todoViewModeLabel(i18n, _TodoViewMode.list),
                selected: _todoViewMode == _TodoViewMode.list,
                onSelected: () {
                  setState(() {
                    _todoViewMode = _TodoViewMode.list;
                  });
                },
              ),
            ],
          ),
          if (_todoViewMode == _TodoViewMode.list) ...<Widget>[
            const SizedBox(height: 8),
            _buildTodoControlSection(
              label: pickUiText(i18n, zh: '\u6392\u5e8f', en: 'Sort'),
              children: <Widget>[
                _buildTodoChoiceChip(
                  key: const ValueKey<String>('todo-sort-manual'),
                  label: _todoSortModeLabel(i18n, _TodoSortMode.manual),
                  selected: manualSort,
                  onSelected: () {
                    setState(() {
                      _todoSortMode = _TodoSortMode.manual;
                    });
                  },
                ),
                _buildTodoChoiceChip(
                  key: const ValueKey<String>('todo-sort-priority'),
                  label: _todoSortModeLabel(i18n, _TodoSortMode.priority),
                  selected: _todoSortMode == _TodoSortMode.priority,
                  onSelected: () {
                    setState(() {
                      _todoSortMode = _TodoSortMode.priority;
                    });
                  },
                ),
                _buildTodoChoiceChip(
                  key: const ValueKey<String>('todo-sort-category'),
                  label: _todoSortModeLabel(i18n, _TodoSortMode.category),
                  selected: _todoSortMode == _TodoSortMode.category,
                  onSelected: () {
                    setState(() {
                      _todoSortMode = _TodoSortMode.category;
                    });
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTodoCompactMenuButton<T>({
    required Key key,
    required IconData icon,
    required String label,
    required List<PopupMenuEntry<T>> items,
    required PopupMenuItemSelected<T> onSelected,
  }) {
    final theme = Theme.of(context);

    return PopupMenuButton<T>(
      key: key,
      itemBuilder: (_) => items,
      onSelected: onSelected,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 176),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Icon(icon, size: 15, color: theme.colorScheme.primary),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.expand_more_rounded,
                size: 15,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<PopupMenuEntry<_TodoFilterMode>> _buildTodoFilterMenuItems(
    AppI18n i18n,
  ) {
    return <PopupMenuEntry<_TodoFilterMode>>[
      CheckedPopupMenuItem<_TodoFilterMode>(
        key: const ValueKey<String>('todo-filter-all'),
        value: _TodoFilterMode.all,
        checked: _todoFilterMode == _TodoFilterMode.all,
        child: Text(_todoFilterModeLabel(i18n, _TodoFilterMode.all)),
      ),
      CheckedPopupMenuItem<_TodoFilterMode>(
        key: const ValueKey<String>('todo-filter-active'),
        value: _TodoFilterMode.active,
        checked: _todoFilterMode == _TodoFilterMode.active,
        child: Text(_todoFilterModeLabel(i18n, _TodoFilterMode.active)),
      ),
      CheckedPopupMenuItem<_TodoFilterMode>(
        key: const ValueKey<String>('todo-filter-today'),
        value: _TodoFilterMode.today,
        checked: _todoFilterMode == _TodoFilterMode.today,
        child: Text(_todoFilterModeLabel(i18n, _TodoFilterMode.today)),
      ),
      CheckedPopupMenuItem<_TodoFilterMode>(
        key: const ValueKey<String>('todo-filter-overdue'),
        value: _TodoFilterMode.overdue,
        checked: _todoFilterMode == _TodoFilterMode.overdue,
        child: Text(_todoFilterModeLabel(i18n, _TodoFilterMode.overdue)),
      ),
      CheckedPopupMenuItem<_TodoFilterMode>(
        key: const ValueKey<String>('todo-filter-deferred'),
        value: _TodoFilterMode.deferred,
        checked: _todoFilterMode == _TodoFilterMode.deferred,
        child: Text(_todoFilterModeLabel(i18n, _TodoFilterMode.deferred)),
      ),
      CheckedPopupMenuItem<_TodoFilterMode>(
        key: const ValueKey<String>('todo-filter-completed'),
        value: _TodoFilterMode.completed,
        checked: _todoFilterMode == _TodoFilterMode.completed,
        child: Text(_todoFilterModeLabel(i18n, _TodoFilterMode.completed)),
      ),
    ];
  }

  Widget _buildTodoControlSection({
    required String label,
    required List<Widget> children,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildTodoControlLabel(label),
        const SizedBox(width: 8),
        Expanded(child: Wrap(spacing: 6, runSpacing: 6, children: children)),
      ],
    );
  }

  Widget _buildTodoChoiceChip({
    Key? key,
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      key: key,
      label: Text(label),
      selected: selected,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      onSelected: (_) => onSelected(),
    );
  }

  Widget _buildTodoControlLabel(String label) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  List<TodoItem> _sortedTodos(List<TodoItem> todos) {
    final items = List<TodoItem>.from(todos);
    switch (_todoSortMode) {
      case _TodoSortMode.manual:
        return items;
      case _TodoSortMode.priority:
        items.sort(_compareTodosByPriority);
        return items;
      case _TodoSortMode.category:
        items.sort(_compareTodosByCategory);
        return items;
    }
  }

  List<TodoItem> _filterTodos(List<TodoItem> todos) {
    final now = DateTime.now();
    final todayStart = _startOfDay(now);
    final tomorrowStart = todayStart.add(const Duration(days: 1));

    return todos
        .where((item) {
          final dueAt = item.dueAt;
          return switch (_todoFilterMode) {
            _TodoFilterMode.all => true,
            _TodoFilterMode.active => !item.completed && !item.isDeferred,
            _TodoFilterMode.today =>
              !item.completed &&
                  !item.isDeferred &&
                  dueAt != null &&
                  !dueAt.isBefore(todayStart) &&
                  dueAt.isBefore(tomorrowStart),
            _TodoFilterMode.overdue =>
              !item.completed &&
                  !item.isDeferred &&
                  dueAt != null &&
                  dueAt.isBefore(todayStart),
            _TodoFilterMode.deferred => item.isDeferred,
            _TodoFilterMode.completed => item.completed,
          };
        })
        .toList(growable: false);
  }

  List<_TodoPlanSection> _buildTodoPlanSections(
    List<TodoItem> todos,
    AppI18n i18n,
  ) {
    final now = DateTime.now();
    final todayStart = _startOfDay(now);
    final tomorrowStart = todayStart.add(const Duration(days: 1));

    final overdue = <TodoItem>[];
    final today = <TodoItem>[];
    final upcoming = <TodoItem>[];
    final deferred = <TodoItem>[];
    final inbox = <TodoItem>[];
    final completed = <TodoItem>[];

    for (final todo in todos) {
      if (todo.completed) {
        completed.add(todo);
        continue;
      }
      if (todo.isDeferred) {
        deferred.add(todo);
        continue;
      }
      final dueAt = todo.dueAt;
      if (dueAt == null) {
        inbox.add(todo);
      } else if (dueAt.isBefore(todayStart)) {
        overdue.add(todo);
      } else if (dueAt.isBefore(tomorrowStart)) {
        today.add(todo);
      } else {
        upcoming.add(todo);
      }
    }

    final sections = <_TodoPlanSection>[
      _TodoPlanSection(
        key: 'todo-plan-overdue',
        title: pickUiText(
          i18n,
          zh: '逾期待处理',
          en: 'Overdue',
          ja: '期限超過',
          de: 'Ueberfaellig',
          fr: 'En retard',
          es: 'Vencidas',
          ru: 'Просрочено',
        ),
        icon: Icons.warning_amber_rounded,
        items: _sortedTodos(overdue),
        highlight: overdue.isNotEmpty,
      ),
      _TodoPlanSection(
        key: 'todo-plan-today',
        title: pickUiText(
          i18n,
          zh: '今天计划',
          en: 'Today',
          ja: '今日',
          de: 'Heute',
          fr: 'Aujourd’hui',
          es: 'Hoy',
          ru: 'Сегодня',
        ),
        icon: Icons.today_rounded,
        items: _sortedTodos(today),
      ),
      _TodoPlanSection(
        key: 'todo-plan-upcoming',
        title: pickUiText(
          i18n,
          zh: '接下来',
          en: 'Upcoming',
          ja: 'これから',
          de: 'Als naechstes',
          fr: 'A venir',
          es: 'Proximas',
          ru: 'Дальше',
        ),
        icon: Icons.upcoming_rounded,
        items: _sortedTodos(upcoming),
      ),
      _TodoPlanSection(
        key: 'todo-plan-deferred',
        title: pickUiText(
          i18n,
          zh: '延后搁置',
          en: 'Deferred',
          ja: '保留中',
          de: 'Zurueckgestellt',
          fr: 'Reporte',
          es: 'Pospuestas',
          ru: 'Отложено',
        ),
        icon: Icons.snooze_rounded,
        items: _sortedTodos(deferred),
      ),
      _TodoPlanSection(
        key: 'todo-plan-inbox',
        title: pickUiText(
          i18n,
          zh: '收件箱',
          en: 'Inbox',
          ja: '受信箱',
          de: 'Inbox',
          fr: 'Boite de reception',
          es: 'Bandeja',
          ru: 'Входящие',
        ),
        icon: Icons.inbox_rounded,
        items: _sortedTodos(inbox),
      ),
    ];

    if (_todoFilterMode == _TodoFilterMode.deferred) {
      return <_TodoPlanSection>[
        _TodoPlanSection(
          key: 'todo-plan-deferred',
          title: pickUiText(
            i18n,
            zh: '延后搁置',
            en: 'Deferred',
            ja: '保留中',
            de: 'Zurueckgestellt',
            fr: 'Reporte',
            es: 'Pospuestas',
            ru: 'Отложено',
          ),
          icon: Icons.snooze_rounded,
          items: _sortedTodos(deferred),
        ),
      ];
    }

    if (_todoFilterMode == _TodoFilterMode.completed) {
      return <_TodoPlanSection>[
        _TodoPlanSection(
          key: 'todo-plan-completed',
          title: pickUiText(
            i18n,
            zh: '已完成',
            en: 'Completed',
            ja: '完了',
            de: 'Erledigt',
            fr: 'Terminees',
            es: 'Completadas',
            ru: 'Выполнено',
          ),
          icon: Icons.task_alt_rounded,
          items: _sortedTodos(completed),
        ),
      ];
    }

    final visible = sections
        .where((section) => section.items.isNotEmpty)
        .toList(growable: true);
    if (_todoFilterMode == _TodoFilterMode.all && completed.isNotEmpty) {
      visible.add(
        _TodoPlanSection(
          key: 'todo-plan-completed',
          title: pickUiText(
            i18n,
            zh: '已完成',
            en: 'Completed',
            ja: '完了',
            de: 'Erledigt',
            fr: 'Terminees',
            es: 'Completadas',
            ru: 'Выполнено',
          ),
          icon: Icons.task_alt_rounded,
          items: _sortedTodos(completed),
        ),
      );
    }
    return visible;
  }

  Widget _buildTodoPlanView(
    FocusService focus,
    List<_TodoPlanSection> sections,
    AppI18n i18n, {
    bool scrollable = false,
  }) {
    if (sections.isEmpty) {
      return Center(
        child: Text(
          pickUiText(
            i18n,
            zh: '当前筛选下还没有任务，先添加一个今天要完成的小目标吧。',
            en: 'No tasks match this view yet. Add one small goal for today.',
            ja: 'この表示にはまだタスクがありません。まずは今日の小さな目標を追加しましょう。',
            de: 'In dieser Ansicht gibt es noch keine Aufgaben. Fuege zuerst ein kleines Ziel fuer heute hinzu.',
            fr: 'Aucune tache pour cette vue. Ajoutez d’abord un petit objectif pour aujourd’hui.',
            es: 'Aun no hay tareas en esta vista. Agrega primero un pequeno objetivo para hoy.',
            ru: 'Для этого представления пока нет задач. Добавьте сначала одну небольшую цель на сегодня.',
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (scrollable) {
      return ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: sections.length,
        itemBuilder: (context, index) {
          final section = sections[index];
          return Padding(
            padding: EdgeInsets.only(
              bottom: index == sections.length - 1 ? 0 : 12,
            ),
            child: _buildTodoPlanSection(focus, section, i18n),
          );
        },
      );
    }

    return Column(
      children: List<Widget>.generate(sections.length, (index) {
        final section = sections[index];
        return Padding(
          padding: EdgeInsets.only(
            bottom: index == sections.length - 1 ? 0 : 12,
          ),
          child: _buildTodoPlanSection(focus, section, i18n),
        );
      }),
    );
  }

  Widget _buildTodoPlanSection(
    FocusService focus,
    _TodoPlanSection section,
    AppI18n i18n,
  ) {
    final theme = Theme.of(context);
    final tint = section.highlight
        ? theme.colorScheme.error
        : theme.colorScheme.primary;

    return Container(
      key: ValueKey<String>(section.key),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: section.highlight ? 0.08 : 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tint.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(section.icon, size: 18, color: tint),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  section.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${section.items.length}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: tint,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...List<Widget>.generate(section.items.length, (index) {
            final todo = section.items[index];
            return _buildTodoCard(
              focus: focus,
              todo: todo,
              i18n: i18n,
              index: index,
              showDragHandle: false,
            );
          }),
        ],
      ),
    );
  }

  int _compareTodosByPriority(TodoItem a, TodoItem b) {
    final completed = _compareTodoCompletion(a, b);
    if (completed != 0) return completed;
    final priority = b.priority.compareTo(a.priority);
    if (priority != 0) return priority;
    final category = _compareTodoCategory(a.category, b.category);
    if (category != 0) return category;
    return _compareTodoManualOrder(a, b);
  }

  int _compareTodosByCategory(TodoItem a, TodoItem b) {
    final completed = _compareTodoCompletion(a, b);
    if (completed != 0) return completed;
    final category = _compareTodoCategory(a.category, b.category);
    if (category != 0) return category;
    final priority = b.priority.compareTo(a.priority);
    if (priority != 0) return priority;
    return _compareTodoManualOrder(a, b);
  }

  int _todoLifecycleRank(TodoItem todo) {
    if (todo.completed) {
      return 2;
    }
    if (todo.isDeferred) {
      return 1;
    }
    return 0;
  }

  int _compareTodoCompletion(TodoItem a, TodoItem b) {
    final left = _todoLifecycleRank(a);
    final right = _todoLifecycleRank(b);
    return left.compareTo(right);
  }

  int _compareTodoCategory(String? left, String? right) {
    final a = (left ?? '').trim().toLowerCase();
    final b = (right ?? '').trim().toLowerCase();
    if (a.isEmpty && b.isEmpty) return 0;
    if (a.isEmpty) return 1;
    if (b.isEmpty) return -1;
    return a.compareTo(b);
  }

  int _compareTodoManualOrder(TodoItem a, TodoItem b) {
    final sort = a.sortOrder.compareTo(b.sortOrder);
    if (sort != 0) return sort;
    final created = (b.createdAt?.millisecondsSinceEpoch ?? 0).compareTo(
      a.createdAt?.millisecondsSinceEpoch ?? 0,
    );
    if (created != 0) return created;
    return (a.id ?? 0).compareTo(b.id ?? 0);
  }

  Widget _buildReorderableTodosList(
    FocusService focus,
    List<TodoItem> todos,
    AppI18n i18n, {
    bool scrollable = false,
  }) {
    return ReorderableListView.builder(
      physics: scrollable
          ? const BouncingScrollPhysics()
          : const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      shrinkWrap: !scrollable,
      buildDefaultDragHandles: false,
      itemCount: todos.length,
      onReorder: (oldIndex, newIndex) {
        final ordered = List<TodoItem>.from(todos);
        if (newIndex > oldIndex) {
          newIndex -= 1;
        }
        final item = ordered.removeAt(oldIndex);
        ordered.insert(newIndex, item);
        focus.reorderTodos(ordered);
      },
      itemBuilder: (context, index) {
        final todo = todos[index];
        return _buildTodoCard(
          focus: focus,
          todo: todo,
          i18n: i18n,
          index: index,
          showDragHandle: true,
        );
      },
    );
  }

  Widget _buildSortedTodosList(
    FocusService focus,
    List<TodoItem> todos,
    AppI18n i18n, {
    bool scrollable = false,
  }) {
    return ListView.builder(
      physics: scrollable
          ? const BouncingScrollPhysics()
          : const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      shrinkWrap: !scrollable,
      itemCount: todos.length,
      itemBuilder: (context, index) {
        final todo = todos[index];
        return _buildTodoCard(
          focus: focus,
          todo: todo,
          i18n: i18n,
          index: index,
          showDragHandle: false,
        );
      },
    );
  }

  Widget _buildTodoCard({
    required FocusService focus,
    required TodoItem todo,
    required AppI18n i18n,
    required int index,
    required bool showDragHandle,
  }) {
    final theme = Theme.of(context);
    final accent = _todoAccentColor(theme, todo);
    final category = (todo.category ?? '').trim();
    final scheduleBadge = _buildTodoScheduleBadge(todo, i18n, theme);
    final compactCard = MediaQuery.sizeOf(context).width < 430;

    return Card(
      key: ValueKey<int>(todo.id ?? index),
      margin: const EdgeInsets.only(bottom: 4),
      color: _todoCardColor(todo, theme),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showTodoEditor(focus, i18n, todo: todo),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 4, 2, 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 5,
                height: compactCard ? 40 : 44,
                decoration: BoxDecoration(
                  color: accent.withValues(
                    alpha: todo.completed ? 0.55 : (todo.isDeferred ? 0.78 : 1),
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 6),
              Checkbox(
                value: todo.completed,
                visualDensity: const VisualDensity(
                  horizontal: -4,
                  vertical: -4,
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onChanged: todo.id == null
                    ? null
                    : (_) => focus.toggleTodo(todo.id!),
              ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        _buildTodoPriorityBadge(
                          todo,
                          i18n,
                          theme,
                          compact: compactCard,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            todo.content,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              decoration: todo.completed
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: todo.completed
                                  ? theme.colorScheme.onSurfaceVariant
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: <Widget>[
                        _buildTodoStatusBadge(todo, i18n, theme),
                        if (category.isNotEmpty)
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: compactCard ? 102 : 126,
                            ),
                            child: _buildTodoCategoryBadge(category, theme),
                          ),
                        if (scheduleBadge != null)
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: compactCard ? 128 : 152,
                            ),
                            child: scheduleBadge,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  IconButton(
                    tooltip: i18n.t('delete'),
                    visualDensity: const VisualDensity(
                      horizontal: -4,
                      vertical: -4,
                    ),
                    constraints: BoxConstraints.tightFor(
                      width: compactCard ? 28 : 30,
                      height: compactCard ? 28 : 30,
                    ),
                    onPressed: todo.id == null
                        ? null
                        : () => focus.deleteTodo(todo.id!),
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                  if (showDragHandle)
                    ReorderableDelayedDragStartListener(
                      index: index,
                      child: Padding(
                        padding: EdgeInsets.all(compactCard ? 4 : 6),
                        child: Icon(
                          Icons.drag_handle_rounded,
                          size: compactCard ? 18 : 20,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodoPriorityBadge(
    TodoItem todo,
    AppI18n i18n,
    ThemeData theme, {
    bool compact = false,
  }) {
    final color = _todoPriorityColor(theme, todo.priority);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 10,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: todo.completed ? 0.20 : 0.92),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _todoPriorityLabel(i18n, todo.priority),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style:
            (compact ? theme.textTheme.labelSmall : theme.textTheme.labelMedium)
                ?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.1,
                ),
      ),
    );
  }

  Widget _buildTodoCategoryBadge(String label, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: theme.colorScheme.secondary.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.label_outline_rounded,
            size: 11,
            color: theme.colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildTodoScheduleBadge(
    TodoItem todo,
    AppI18n i18n,
    ThemeData theme,
  ) {
    final dueAt = todo.dueAt;
    if (dueAt == null) {
      return null;
    }

    final now = DateTime.now();
    final todayStart = _startOfDay(now);
    final tomorrowStart = todayStart.add(const Duration(days: 1));
    final text = dueAt.isBefore(todayStart)
        ? pickUiText(
            i18n,
            zh: '已逾期',
            en: 'Overdue',
            ja: '期限超過',
            de: 'Ueberfaellig',
            fr: 'En retard',
            es: 'Vencida',
            ru: 'Просрочено',
          )
        : dueAt.isBefore(tomorrowStart)
        ? pickUiText(
            i18n,
            zh: '今天 ${_formatTodoTime(dueAt)}',
            en: 'Today ${_formatTodoTime(dueAt)}',
            ja: '今日 ${_formatTodoTime(dueAt)}',
            de: 'Heute ${_formatTodoTime(dueAt)}',
            fr: 'Aujourd’hui ${_formatTodoTime(dueAt)}',
            es: 'Hoy ${_formatTodoTime(dueAt)}',
            ru: 'Сегодня ${_formatTodoTime(dueAt)}',
          )
        : _isSameDay(dueAt, tomorrowStart)
        ? pickUiText(
            i18n,
            zh: '明天 ${_formatTodoTime(dueAt)}',
            en: 'Tomorrow ${_formatTodoTime(dueAt)}',
            ja: '明日 ${_formatTodoTime(dueAt)}',
            de: 'Morgen ${_formatTodoTime(dueAt)}',
            fr: 'Demain ${_formatTodoTime(dueAt)}',
            es: 'Manana ${_formatTodoTime(dueAt)}',
            ru: 'Завтра ${_formatTodoTime(dueAt)}',
          )
        : _formatTodoDateTime(dueAt);
    final color = dueAt.isBefore(todayStart)
        ? theme.colorScheme.error
        : theme.colorScheme.tertiary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: todo.completed ? 0.10 : 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildNotesDrawer({
    required FocusService focus,
    required List<PlanNote> notes,
    required AppI18n i18n,
    required double width,
    required double handleWidth,
    required double progress,
  }) {
    final theme = Theme.of(context);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: (_) {
        setState(() {
          _notesDrawerDragging = true;
        });
      },
      onHorizontalDragUpdate: (details) =>
          _updateNotesDrawerProgress(details.delta.dx, width),
      onHorizontalDragEnd: (details) =>
          _settleNotesDrawerFromVelocity(details.primaryVelocity ?? 0),
      child: Material(
        color: Colors.transparent,
        elevation: 0,
        borderRadius: BorderRadius.circular(24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: SizedBox(
              key: const ValueKey<String>('notes-drawer'),
              width: width,
              child: Row(
                children: <Widget>[
                  _buildNotesDrawerHandle(
                    i18n,
                    notes.length,
                    progress,
                    handleWidth,
                  ),
                  Expanded(
                    child: IgnorePointer(
                      ignoring: progress < 0.2,
                      child: _buildNotesPanel(focus, notes, i18n),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotesDrawerHandle(
    AppI18n i18n,
    int noteCount,
    double progress,
    double width,
  ) {
    final theme = Theme.of(context);
    final compactHandle = width <= 54;
    final handleColor = Color.lerp(
      theme.colorScheme.surfaceContainerHigh,
      theme.colorScheme.secondaryContainer,
      0.28 + progress * 0.42,
    )!;
    final foregroundColor = Color.lerp(
      theme.colorScheme.onSurfaceVariant,
      theme.colorScheme.onSecondaryContainer,
      0.30 + progress * 0.50,
    )!;

    return InkWell(
      key: const ValueKey<String>('notes-drawer-handle'),
      onTap: _toggleNotesDrawer,
      child: Ink(
        width: width,
        decoration: BoxDecoration(
          color: handleColor,
          border: Border(
            right: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.75),
            ),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compactHandle ? 6 : 8,
            vertical: compactHandle ? 14 : 18,
          ),
          child: Column(
            children: <Widget>[
              Icon(
                progress >= 0.5
                    ? Icons.chevron_right_rounded
                    : Icons.chevron_left_rounded,
                size: compactHandle ? 20 : 24,
                color: foregroundColor,
              ),
              SizedBox(height: compactHandle ? 10 : 14),
              Expanded(
                child: Center(
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: Text(
                      i18n.t('quickNotes'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          (compactHandle
                                  ? theme.textTheme.labelMedium
                                  : theme.textTheme.labelLarge)
                              ?.copyWith(
                                color: foregroundColor,
                                fontWeight: FontWeight.w700,
                              ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: compactHandle ? 10 : 14),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: compactHandle ? 6 : 8,
                  vertical: compactHandle ? 3 : 4,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$noteCount',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotesPanel(
    FocusService focus,
    List<PlanNote> notes,
    AppI18n i18n,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  i18n.t('quickNotes'),
                  style: theme.textTheme.titleMedium,
                ),
              ),
              if (_noteSelectionMode)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    i18n.t(
                      'selectedNotesCount',
                      params: <String, Object?>{
                        'count': _selectedNoteIds.length,
                      },
                    ),
                    style: theme.textTheme.labelLarge,
                  ),
                ),
              IconButton(
                tooltip: _noteSelectionMode
                    ? i18n.t('cancel')
                    : i18n.t('selectNotes'),
                onPressed: () {
                  setState(() {
                    _noteSelectionMode = !_noteSelectionMode;
                    if (!_noteSelectionMode) {
                      _selectedNoteIds.clear();
                    }
                  });
                },
                icon: Icon(
                  _noteSelectionMode
                      ? Icons.close_rounded
                      : Icons.checklist_rtl_rounded,
                ),
              ),
              IconButton(
                tooltip: i18n.t('addNote'),
                onPressed: () => _showNoteDialog(focus, i18n),
                icon: const Icon(Icons.note_add_rounded),
              ),
              if (_noteSelectionMode)
                IconButton(
                  tooltip: i18n.t('deleteSelectedNotes'),
                  onPressed: _selectedNoteIds.isEmpty
                      ? null
                      : () => _confirmDeleteSelectedNotes(focus, i18n),
                  icon: const Icon(Icons.delete_sweep_rounded),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(i18n.t('dragToReorder'), style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          Expanded(
            child: notes.isEmpty
                ? Center(child: Text(i18n.t('notesEmpty')))
                : _noteSelectionMode
                ? _buildSelectableNotesList(notes)
                : _buildReorderableNotesList(focus, notes, i18n),
          ),
        ],
      ),
    );
  }

  Future<void> _showNotesSheet(FocusService focus, AppI18n i18n) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        final mediaQuery = MediaQuery.of(sheetContext);
        final sheetHeight = math.max(320.0, mediaQuery.size.height * 0.72);
        return ValueListenableBuilder<int>(
          valueListenable: focus.viewRevision,
          builder: (context, revision, child) {
            final notes = focus.getNotes();
            return SizedBox(
              key: const ValueKey<String>('notes-sheet'),
              height: sheetHeight,
              child: _buildNotesSheetContent(focus, notes, i18n),
            );
          },
        );
      },
    );
  }

  Widget _buildNotesSheetContent(
    FocusService focus,
    List<PlanNote> notes,
    AppI18n i18n,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  i18n.t('quickNotes'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                tooltip: i18n.t('addNote'),
                onPressed: () => _showNoteDialog(focus, i18n),
                icon: const Icon(Icons.note_add_rounded),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(i18n.t('dragToReorder'), style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          Expanded(
            child: notes.isEmpty
                ? Center(child: Text(i18n.t('notesEmpty')))
                : _buildReorderableNotesList(focus, notes, i18n),
          ),
        ],
      ),
    );
  }

  double _notesDrawerWidth(double maxWidth, FocusService focus) {
    final maxAllowed = math.max(0.0, maxWidth - 12);
    if (maxWidth < 520) {
      return math.min(maxAllowed, math.max(220.0, maxWidth * 0.88));
    }
    final preferredRatio = focus.config.normalizedWorkspaceSplitRatio
        .clamp(0.42, 0.68)
        .toDouble();
    return math.min(maxAllowed, math.max(320.0, maxWidth * preferredRatio));
  }

  void _toggleNotesDrawer() {
    _settleNotesDrawer(open: _notesDrawerProgress < 0.5);
  }

  void _updateNotesDrawerProgress(double deltaX, double drawerWidth) {
    final safeWidth = math.max(drawerWidth, 1);
    setState(() {
      _notesDrawerDragging = true;
      _notesDrawerProgress = (_notesDrawerProgress - deltaX / safeWidth)
          .clamp(0.0, 1.0)
          .toDouble();
    });
  }

  void _settleNotesDrawerFromVelocity(double velocity) {
    final shouldOpen =
        velocity < -220 ||
        (velocity.abs() < 220 && _notesDrawerProgress >= 0.45);
    _settleNotesDrawer(open: shouldOpen);
  }

  void _settleNotesDrawer({required bool open}) {
    setState(() {
      _notesDrawerDragging = false;
      _notesDrawerProgress = open ? 1.0 : 0.0;
    });
  }

  Widget _buildSelectableNotesList(List<PlanNote> notes) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: _selectedNoteIds.contains(note.id)
              ? Theme.of(context).colorScheme.secondaryContainer
              : _noteColor(note),
          child: CheckboxListTile(
            value: _selectedNoteIds.contains(note.id),
            onChanged: (_) => _toggleSelectedNote(note),
            title: Text(note.title),
            subtitle: (note.content ?? '').trim().isEmpty
                ? null
                : Text(
                    note.content!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
        );
      },
    );
  }

  Widget _buildReorderableNotesList(
    FocusService focus,
    List<PlanNote> notes,
    AppI18n i18n,
  ) {
    return ReorderableListView.builder(
      physics: const BouncingScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: notes.length,
      onReorder: (oldIndex, newIndex) {
        final ordered = List<PlanNote>.from(notes);
        if (newIndex > oldIndex) {
          newIndex -= 1;
        }
        final item = ordered.removeAt(oldIndex);
        ordered.insert(newIndex, item);
        focus.reorderNotes(ordered);
      },
      itemBuilder: (context, index) {
        final note = notes[index];
        return Card(
          key: ValueKey<int>(note.id ?? index),
          margin: const EdgeInsets.only(bottom: 8),
          color: _noteColor(note),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 4,
            ),
            title: Text(note.title),
            subtitle: (note.content ?? '').trim().isEmpty
                ? null
                : Text(
                    note.content!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
            onTap: () => _showNoteDialog(focus, i18n, note: note),
            onLongPress: () {
              setState(() {
                _noteSelectionMode = true;
                if (note.id != null) {
                  _selectedNoteIds.add(note.id!);
                }
              });
            },
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                IconButton(
                  tooltip: i18n.t('delete'),
                  onPressed: () => _confirmDeleteSingleNote(focus, note, i18n),
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
                ReorderableDelayedDragStartListener(
                  index: index,
                  child: const Icon(Icons.drag_handle_rounded),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _toggleSelectedNote(PlanNote note) {
    final id = note.id;
    if (id == null) return;
    setState(() {
      if (_selectedNoteIds.contains(id)) {
        _selectedNoteIds.remove(id);
      } else {
        _selectedNoteIds.add(id);
      }
    });
  }

  Color? _noteColor(PlanNote note) {
    return _parseHexColor(note.color);
  }

  Color? _parseHexColor(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      return Color(int.parse(value, radix: 16));
    } catch (_) {
      return null;
    }
  }

  _TodoDraftState _todoDraftStateOf(TodoItem todo) {
    if (todo.completed) {
      return _TodoDraftState.completed;
    }
    if (todo.isDeferred) {
      return _TodoDraftState.deferred;
    }
    return _TodoDraftState.active;
  }

  String _todoDraftStateLabel(AppI18n i18n, _TodoDraftState state) {
    return switch (state) {
      _TodoDraftState.active => pickUiText(
        i18n,
        zh: '进行中',
        en: 'Active',
        ja: '進行中',
        de: 'Aktiv',
        fr: 'Actives',
        es: 'Activas',
        ru: 'Активные',
      ),
      _TodoDraftState.deferred => pickUiText(
        i18n,
        zh: '延后搁置',
        en: 'Deferred',
        ja: '保留中',
        de: 'Zurueckgestellt',
        fr: 'Reporte',
        es: 'Pospuestas',
        ru: 'Отложено',
      ),
      _TodoDraftState.completed => pickUiText(
        i18n,
        zh: '已完成',
        en: 'Completed',
        ja: '完了',
        de: 'Erledigt',
        fr: 'Terminees',
        es: 'Completadas',
        ru: 'Выполнено',
      ),
    };
  }

  String _todoStatusLabel(AppI18n i18n, TodoItem todo) {
    return _todoDraftStateLabel(i18n, _todoDraftStateOf(todo));
  }

  IconData _todoStatusIcon(TodoItem todo) {
    if (todo.completed) {
      return Icons.task_alt_rounded;
    }
    if (todo.isDeferred) {
      return Icons.snooze_rounded;
    }
    return Icons.flash_on_rounded;
  }

  Color _todoStatusColor(ThemeData theme, TodoItem todo) {
    if (todo.completed) {
      return theme.colorScheme.secondary;
    }
    if (todo.isDeferred) {
      return theme.colorScheme.tertiary;
    }
    return theme.colorScheme.primary;
  }

  Widget _buildTodoStatusBadge(TodoItem todo, AppI18n i18n, ThemeData theme) {
    final color = _todoStatusColor(theme, todo);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: todo.completed ? 0.16 : 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(_todoStatusIcon(todo), size: 13, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              _todoStatusLabel(i18n, todo),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _todoCardColor(TodoItem todo, ThemeData theme) {
    final accent = _parseHexColor(todo.color);
    if (accent == null && todo.isDeferred) {
      return Color.alphaBlend(
        theme.colorScheme.tertiaryContainer.withValues(alpha: 0.36),
        theme.colorScheme.surfaceContainerLow,
      );
    }
    if (accent == null) {
      return theme.colorScheme.surfaceContainerLow;
    }
    return Color.alphaBlend(
      accent.withValues(alpha: todo.completed ? 0.12 : 0.24),
      theme.colorScheme.surfaceContainerLow,
    );
  }

  Color _todoAccentColor(ThemeData theme, TodoItem todo) {
    return _parseHexColor(todo.color) ??
        (todo.completed || todo.isDeferred
            ? _todoStatusColor(theme, todo)
            : _todoPriorityColor(theme, todo.priority));
  }

  String _todoPriorityLabel(AppI18n i18n, int priority) {
    return switch (priority.clamp(0, 2)) {
      2 => i18n.t('todoPriorityHigh'),
      1 => i18n.t('todoPriorityMedium'),
      _ => i18n.t('todoPriorityLow'),
    };
  }

  Color _todoPriorityColor(ThemeData theme, int priority) {
    return switch (priority.clamp(0, 2)) {
      2 => theme.colorScheme.error,
      1 => theme.colorScheme.primary,
      _ => theme.colorScheme.tertiary,
    };
  }

  String _formatTodoDateTime(DateTime value) {
    final localizations = MaterialLocalizations.of(context);
    final date = localizations.formatMediumDate(value);
    final time = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(value),
      alwaysUse24HourFormat: MediaQuery.of(context).alwaysUse24HourFormat,
    );
    return '$date $time';
  }

  String _formatTodoTime(DateTime value) {
    return MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(value),
      alwaysUse24HourFormat: MediaQuery.of(context).alwaysUse24HourFormat,
    );
  }

  DateTime _startOfDay(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  bool _isSameDay(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  String? _normalizeOptionalText(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String? _colorToHex(Color? value) {
    if (value == null) return null;
    return value.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase();
  }

  Future<DateTime?> _pickTodoReminderDateTime(DateTime? current) async {
    final seed = current ?? DateTime.now().add(const Duration(hours: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: seed,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(seed),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _showTodoEditor(
    FocusService focus,
    AppI18n i18n, {
    TodoItem? todo,
  }) async {
    final titleController = TextEditingController(text: todo?.content ?? '');
    final categoryController = TextEditingController(
      text: todo?.category ?? '',
    );
    final noteController = TextEditingController(text: todo?.note ?? '');
    var priority = (todo?.priority ?? 1).clamp(0, 2).toInt();
    var draftState = todo == null
        ? _TodoDraftState.active
        : _todoDraftStateOf(todo);
    var selectedColor = _parseHexColor(todo?.color);
    var dueAt = todo?.dueAt;
    var alarmEnabled = todo?.alarmEnabled ?? false;
    var syncToSystemCalendar = todo?.syncToSystemCalendar ?? true;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            Future<void> pickReminder() async {
              final picked = await _pickTodoReminderDateTime(dueAt);
              if (picked == null) return;
              setSheetState(() {
                dueAt = picked;
                alarmEnabled = true;
              });
            }

            final theme = Theme.of(sheetContext);
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                16 + MediaQuery.viewInsetsOf(sheetContext).bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      i18n.t(
                        todo == null ? 'addTodoDetails' : 'editTodoDetails',
                      ),
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const ValueKey<String>('todo-title-field'),
                      controller: titleController,
                      autofocus: todo == null,
                      decoration: InputDecoration(
                        labelText: i18n.t('todoTitle'),
                        hintText: i18n.t('todoTitleHint'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const ValueKey<String>('todo-category-field'),
                      controller: categoryController,
                      decoration: InputDecoration(
                        labelText: i18n.t('todoCategory'),
                        hintText: i18n.t('todoCategoryHint'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      pickUiText(
                        i18n,
                        zh: '状态',
                        en: 'Status',
                        ja: '状態',
                        de: 'Status',
                        fr: 'Statut',
                        es: 'Estado',
                        ru: 'Статус',
                      ),
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        for (final value in _TodoDraftState.values)
                          ChoiceChip(
                            key: ValueKey<String>('todo-status-${value.name}'),
                            label: Text(_todoDraftStateLabel(i18n, value)),
                            selected: draftState == value,
                            onSelected: (_) {
                              setSheetState(() {
                                draftState = value;
                              });
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      i18n.t('todoPriority'),
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        for (final value in <int>[0, 1, 2])
                          ChoiceChip(
                            label: Text(_todoPriorityLabel(i18n, value)),
                            selected: priority == value,
                            onSelected: (_) {
                              setSheetState(() {
                                priority = value;
                              });
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      i18n.t('todoColor'),
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        ChoiceChip(
                          label: Text(i18n.t('todoNoColor')),
                          selected: selectedColor == null,
                          onSelected: (_) {
                            setSheetState(() {
                              selectedColor = null;
                            });
                          },
                        ),
                        for (final raw in _todoPalette)
                          ChoiceChip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: Color(raw),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(i18n.t('todoColorOption')),
                              ],
                            ),
                            selected: selectedColor?.toARGB32() == raw,
                            onSelected: (_) {
                              setSheetState(() {
                                selectedColor = Color(raw);
                              });
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const ValueKey<String>('todo-note-field'),
                      controller: noteController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: i18n.t('todoNotes'),
                        hintText: i18n.t('todoNotesHint'),
                        alignLabelWithHint: true,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: alarmEnabled,
                      title: Text(i18n.t('todoReminder')),
                      subtitle: Text(
                        dueAt == null
                            ? i18n.t('todoReminderHint')
                            : _formatTodoDateTime(dueAt!),
                      ),
                      onChanged: (value) {
                        setSheetState(() {
                          alarmEnabled = value;
                          if (!alarmEnabled) {
                            dueAt = null;
                          }
                        });
                      },
                    ),
                    if (alarmEnabled) ...<Widget>[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: <Widget>[
                          OutlinedButton.icon(
                            onPressed: pickReminder,
                            icon: const Icon(Icons.schedule_rounded),
                            label: Text(
                              dueAt == null
                                  ? i18n.t('todoPickReminder')
                                  : _formatTodoDateTime(dueAt!),
                            ),
                          ),
                          if (dueAt != null)
                            TextButton(
                              onPressed: () {
                                setSheetState(() {
                                  dueAt = null;
                                  alarmEnabled = false;
                                });
                              },
                              child: Text(i18n.t('clearValue')),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        i18n.t('todoReminderStorageHint'),
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: syncToSystemCalendar,
                        title: Text(
                          pickUiText(
                            i18n,
                            zh: '同步到系统日历',
                            en: 'Sync to system calendar',
                            ja: 'システムカレンダーに同期',
                            de: 'Mit Systemkalender synchronisieren',
                            fr: 'Synchroniser avec le calendrier systeme',
                            es: 'Sincronizar con el calendario del sistema',
                            ru: 'Синхронизировать с системным календарем',
                          ),
                        ),
                        subtitle: Text(
                          pickUiText(
                            i18n,
                            zh: '开启后会写入系统日历事件；关闭后只保留应用内提醒。',
                            en: 'When enabled, reminders are written to the system calendar. When disabled, they stay only inside the app.',
                            ja: '有効にするとシステムカレンダーへ予定を作成し、無効にするとアプリ内のリマインダーだけを保持します。',
                            de: 'Wenn aktiviert, werden Erinnerungen in den Systemkalender geschrieben. Andernfalls bleiben sie nur in der App.',
                            fr: 'Lorsque cette option est activee, le rappel est ajoute au calendrier systeme. Sinon, il reste uniquement dans l’application.',
                            es: 'Al activarlo, el recordatorio se agrega al calendario del sistema. Si se desactiva, solo se conserva dentro de la app.',
                            ru: 'При включении напоминание будет сохранено в системный календарь. При выключении оно останется только внутри приложения.',
                          ),
                        ),
                        onChanged: (value) {
                          setSheetState(() {
                            syncToSystemCalendar = value;
                          });
                        },
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        TextButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          child: Text(i18n.t('cancel')),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          key: const ValueKey<String>('todo-save-button'),
                          onPressed: () {
                            final content = titleController.text.trim();
                            if (content.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(i18n.t('todoTitleRequired')),
                                ),
                              );
                              return;
                            }
                            focus.saveTodo(
                              TodoItem(
                                id: todo?.id,
                                content: content,
                                completed:
                                    draftState == _TodoDraftState.completed,
                                deferred:
                                    draftState == _TodoDraftState.deferred,
                                priority: priority,
                                category: _normalizeOptionalText(
                                  categoryController.text,
                                ),
                                note: _normalizeOptionalText(
                                  noteController.text,
                                ),
                                color: _colorToHex(selectedColor),
                                sortOrder: todo?.sortOrder ?? 0,
                                dueAt: dueAt,
                                alarmEnabled: alarmEnabled && dueAt != null,
                                syncToSystemCalendar: syncToSystemCalendar,
                                createdAt: todo?.createdAt ?? DateTime.now(),
                                completedAt:
                                    draftState == _TodoDraftState.completed
                                    ? (todo?.completedAt ?? DateTime.now())
                                    : null,
                              ),
                            );
                            Navigator.pop(sheetContext);
                          },
                          icon: const Icon(Icons.save_outlined),
                          label: Text(i18n.t('save')),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmStop(FocusService focus, AppI18n i18n) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(i18n.t('stopTimer')),
        content: Text(i18n.t('stopTimerConfirm')),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(i18n.t('cancel')),
          ),
          FilledButton(
            onPressed: () {
              focus.stop();
              Navigator.pop(context);
            },
            child: Text(i18n.t('stop')),
          ),
        ],
      ),
    );
  }

  String _mergeRecognizedNoteContent(String current, String recognized) {
    final next = recognized.trim();
    if (next.isEmpty) {
      return current.trim();
    }
    final existing = current.trimRight();
    if (existing.isEmpty) {
      return next;
    }
    if (existing.endsWith('\n')) {
      return '$existing$next';
    }
    return '$existing\n$next';
  }

  String? _noteSpeechLanguageTag(AppState state) {
    final normalized = normalizeAsrLanguageTag(
      state.config.voiceInput.language,
    );
    if (normalized == 'auto') {
      return null;
    }
    return normalized;
  }

  String _noteSpeechLanguageLabel(AppI18n i18n, String? languageTag) {
    return asrLanguageLabel(i18n, languageTag);
  }

  String _noteSpeechHelperText(
    AppI18n i18n,
    _NoteVoiceInputState voiceState,
    String? languageTag,
    VoiceInputProviderType provider,
  ) {
    final languageLabel = _noteSpeechLanguageLabel(i18n, languageTag);
    return switch (voiceState) {
      _NoteVoiceInputState.starting => pickUiText(
        i18n,
        zh: '正在调用系统语音识别，请稍候。',
        en: 'Opening system speech recognition. Please wait.',
      ),
      _NoteVoiceInputState.listening => pickUiText(
        i18n,
        zh: '系统听写已开始，完成后再点一次即可写入笔记。',
        en: 'System dictation is active. Finish in the system panel, then tap again to insert the text.',
      ),
      _NoteVoiceInputState.finishing => pickUiText(
        i18n,
        zh: '正在整理识别文本并写入笔记。',
        en: 'Finalizing the transcript and inserting it into the note.',
      ),
      _NoteVoiceInputState.idle => pickUiText(
        i18n,
        zh: '使用系统语音识别直接转成笔记文本，当前语言：$languageLabel。',
        en: 'Use system speech recognition to append text directly to the note. Language: $languageLabel.',
      ),
    };
  }

  String _noteSpeechErrorText(
    AppI18n i18n,
    String? errorCode,
    String? errorMessage,
  ) {
    final fallback = errorMessage?.trim();
    return switch ((errorCode ?? '').trim()) {
      'permission_denied' => pickUiText(
        i18n,
        zh: '系统语音权限未开启，请允许麦克风与语音识别权限后重试。',
        en: 'Speech permission is not granted. Please allow microphone and speech recognition access.',
      ),
      'busy' => pickUiText(
        i18n,
        zh: '系统语音识别当前正忙，请稍后再试。',
        en: 'System speech recognition is busy. Please try again shortly.',
      ),
      'no_match' => pickUiText(
        i18n,
        zh: '没有识别到可用文本，请再说一次。',
        en: 'No usable transcript was captured. Please try again.',
      ),
      'language_not_supported' => pickUiText(
        i18n,
        zh: '当前语音识别语言不受系统支持，请更换语言代码。',
        en: 'The selected recognition language is not supported. Try the system default language or a full locale such as en-US or zh-CN.',
      ),
      'not_listening' => pickUiText(
        i18n,
        zh: '当前没有进行中的系统听写。',
        en: 'There is no active system dictation session.',
      ),
      'unsupported' || 'unavailable' => pickUiText(
        i18n,
        zh: '当前设备暂不支持系统语音识别。',
        en: 'No system speech recognizer or dictation panel is available on this device.',
      ),
      'cancelled' => pickUiText(
        i18n,
        zh: '系统听写已取消。',
        en: 'System dictation was cancelled.',
      ),
      _ =>
        fallback?.isNotEmpty == true
            ? fallback!
            : pickUiText(
                i18n,
                zh: '系统语音识别失败，请稍后重试。',
                en: 'System speech recognition failed. Please try again.',
              ),
    };
  }

  String _noteVoiceInputErrorText(
    AppI18n i18n,
    String? errorKey,
    Map<String, Object?> errorParams,
  ) {
    final key = (errorKey ?? '').trim();
    if (key.isEmpty) {
      return pickUiText(
        i18n,
        zh: '语音输入失败，请稍后重试。',
        en: 'Voice input failed. Please try again.',
      );
    }
    try {
      return i18n.t(key, params: errorParams);
    } catch (_) {
      return key;
    }
  }

  String _noteVoiceRecorderErrorText(AppI18n i18n) {
    return pickUiText(
      i18n,
      zh: '无法启动语音输入录音，请检查麦克风权限后重试。',
      en: 'Unable to start the voice input recorder. Please check microphone permission and try again.',
    );
  }

  String _noteVoiceRecordingHelperText(
    AppI18n i18n,
    _NoteVoiceInputState voiceState,
    String? languageTag,
    VoiceInputProviderType provider,
  ) {
    final languageLabel = _noteSpeechLanguageLabel(i18n, languageTag);
    final providerLabel = voiceInputProviderLabel(i18n, provider);
    return switch (voiceState) {
      _NoteVoiceInputState.starting => pickUiText(
        i18n,
        zh: '正在准备语音输入录音，请稍候。',
        en: 'Preparing the voice input recorder. Please wait.',
      ),
      _NoteVoiceInputState.listening => pickUiText(
        i18n,
        zh: '语音输入录音中，再点一次即可结束并转写到笔记。',
        en: 'Voice input recording is active. Tap again to finish and transcribe the note.',
      ),
      _NoteVoiceInputState.finishing => pickUiText(
        i18n,
        zh: '正在转写语音输入并写入笔记。',
        en: 'Transcribing the voice input and inserting it into the note.',
      ),
      _NoteVoiceInputState.idle => pickUiText(
        i18n,
        zh: '使用$providerLabel将语音内容追加到笔记正文。当前语言：$languageLabel。',
        en: 'Use $providerLabel to append speech text directly to the note. Language: $languageLabel.',
      ),
    };
  }

  String _defaultNoteTitle(AppI18n i18n) {
    final now = DateTime.now();
    final localizations = MaterialLocalizations.of(context);
    final date = localizations.formatShortDate(now);
    final time = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(now),
      alwaysUse24HourFormat: MediaQuery.of(context).alwaysUse24HourFormat,
    );
    final prefix = pickUiText(
      i18n,
      zh: '快速笔记',
      en: 'Quick note',
      ja: 'クイックノート',
      de: 'Schnellnotiz',
      fr: 'Note rapide',
      es: 'Nota rapida',
      ru: 'Быстрая заметка',
    );
    return '$prefix $date $time';
  }

  void _showNoteDialog(FocusService focus, AppI18n i18n, {PlanNote? note}) {
    final state = context.read<AppState>();
    final titleController = TextEditingController(text: note?.title ?? '');
    final contentController = TextEditingController(text: note?.content ?? '');
    var selectedColor = _parseHexColor(note?.color);
    var voiceState = _NoteVoiceInputState.idle;
    String? voiceError;
    var sheetClosed = false;
    final speechLanguageTag = _noteSpeechLanguageTag(state);
    final voiceInputProvider = state.config.voiceInput.provider;

    Future<void> cleanupVoiceInput() async {
      if (voiceState != _NoteVoiceInputState.idle) {
        await _systemSpeech.cancelListening();
        await state.cancelVoiceInputRecording();
        state.stopVoiceInputProcessing();
      }
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final theme = Theme.of(sheetContext);

            void updateSheet(VoidCallback action) {
              if (sheetClosed || !sheetContext.mounted) {
                return;
              }
              setSheetState(action);
            }

            String voiceButtonLabel() {
              if (voiceInputProvider != VoiceInputProviderType.system) {
                switch (voiceState) {
                  case _NoteVoiceInputState.starting:
                    return pickUiText(
                      i18n,
                      zh: '正在启动语音输入…',
                      en: 'Starting voice input...',
                    );
                  case _NoteVoiceInputState.listening:
                    return pickUiText(
                      i18n,
                      zh: '点击结束语音输入',
                      en: 'Tap to stop voice input',
                    );
                  case _NoteVoiceInputState.finishing:
                    return pickUiText(
                      i18n,
                      zh: '正在转写语音输入…',
                      en: 'Transcribing voice input...',
                    );
                  case _NoteVoiceInputState.idle:
                    return pickUiText(
                      i18n,
                      zh: '点击开始语音输入',
                      en: 'Tap to start voice input',
                    );
                }
              }
              switch (voiceState) {
                case _NoteVoiceInputState.starting:
                  return pickUiText(
                    i18n,
                    zh: '正在启动听写…',
                    en: 'Starting dictation...',
                  );
                case _NoteVoiceInputState.listening:
                  return pickUiText(
                    i18n,
                    zh: '点击结束听写',
                    en: 'Tap to stop dictation',
                  );
                case _NoteVoiceInputState.finishing:
                  return pickUiText(
                    i18n,
                    zh: '正在整理识别结果…',
                    en: 'Finishing dictation...',
                  );
                case _NoteVoiceInputState.idle:
                  return pickUiText(
                    i18n,
                    zh: '点击开始听写',
                    en: 'Tap to start dictation',
                  );
              }
            }

            Future<void> toggleVoiceInput() async {
              if (voiceState == _NoteVoiceInputState.starting ||
                  voiceState == _NoteVoiceInputState.finishing) {
                return;
              }
              if (voiceState == _NoteVoiceInputState.listening) {
                updateSheet(() {
                  voiceState = _NoteVoiceInputState.finishing;
                  voiceError = null;
                });
                if (voiceInputProvider != VoiceInputProviderType.system) {
                  final audioPath = await state.stopVoiceInputRecording();
                  if (sheetClosed || !sheetContext.mounted) {
                    return;
                  }
                  if ((audioPath ?? '').trim().isEmpty) {
                    updateSheet(() {
                      voiceState = _NoteVoiceInputState.idle;
                      voiceError = _noteVoiceRecorderErrorText(i18n);
                    });
                    return;
                  }

                  final result = await state.transcribeVoiceInputRecording(
                    audioPath!,
                  );
                  if (sheetClosed || !sheetContext.mounted) {
                    return;
                  }
                  if (!result.success) {
                    updateSheet(() {
                      voiceState = _NoteVoiceInputState.idle;
                      voiceError = _noteVoiceInputErrorText(
                        i18n,
                        result.error,
                        result.errorParams,
                      );
                    });
                    return;
                  }

                  final recognizedText = result.text?.trim() ?? '';
                  if (recognizedText.isEmpty) {
                    updateSheet(() {
                      voiceState = _NoteVoiceInputState.idle;
                      voiceError = _noteVoiceInputErrorText(
                        i18n,
                        result.error ?? 'asrEmptyResult',
                        result.errorParams,
                      );
                    });
                    return;
                  }

                  final merged = _mergeRecognizedNoteContent(
                    contentController.text,
                    recognizedText,
                  );
                  contentController.value = contentController.value.copyWith(
                    text: merged,
                    selection: TextSelection.collapsed(offset: merged.length),
                    composing: TextRange.empty,
                  );
                  updateSheet(() {
                    voiceState = _NoteVoiceInputState.idle;
                    voiceError = null;
                  });
                  return;
                }
                final result = await _systemSpeech.stopListening();
                if (sheetClosed || !sheetContext.mounted) {
                  return;
                }
                if (!result.success) {
                  updateSheet(() {
                    voiceState = _NoteVoiceInputState.idle;
                    voiceError = _noteSpeechErrorText(
                      i18n,
                      result.errorCode,
                      result.errorMessage,
                    );
                  });
                  return;
                }

                final recognizedText = result.text?.trim() ?? '';
                if (recognizedText.isEmpty) {
                  updateSheet(() {
                    voiceState = _NoteVoiceInputState.idle;
                    voiceError = _noteSpeechErrorText(
                      i18n,
                      result.errorCode ?? 'no_match',
                      result.errorMessage,
                    );
                  });
                  return;
                }

                final merged = _mergeRecognizedNoteContent(
                  contentController.text,
                  recognizedText,
                );
                contentController.value = contentController.value.copyWith(
                  text: merged,
                  selection: TextSelection.collapsed(offset: merged.length),
                  composing: TextRange.empty,
                );
                updateSheet(() {
                  voiceState = _NoteVoiceInputState.idle;
                  voiceError = null;
                });
                return;
              }

              updateSheet(() {
                voiceState = _NoteVoiceInputState.starting;
                voiceError = null;
              });
              if (voiceInputProvider != VoiceInputProviderType.system) {
                final audioPath = await state.startVoiceInputRecording();
                if (sheetClosed || !sheetContext.mounted) {
                  return;
                }
                if ((audioPath ?? '').trim().isEmpty) {
                  updateSheet(() {
                    voiceState = _NoteVoiceInputState.idle;
                    voiceError = _noteVoiceRecorderErrorText(i18n);
                  });
                  return;
                }
                updateSheet(() {
                  voiceState = _NoteVoiceInputState.listening;
                });
                return;
              }
              final startResult = await _systemSpeech.startListening(
                languageTag: speechLanguageTag,
              );
              if (sheetClosed || !sheetContext.mounted) {
                return;
              }
              if (!startResult.success) {
                updateSheet(() {
                  voiceState = _NoteVoiceInputState.idle;
                  voiceError = _noteSpeechErrorText(
                    i18n,
                    startResult.errorCode,
                    startResult.errorMessage,
                  );
                });
                return;
              }
              updateSheet(() {
                voiceState = _NoteVoiceInputState.listening;
              });
            }

            final isVoiceBusy =
                voiceState == _NoteVoiceInputState.starting ||
                voiceState == _NoteVoiceInputState.finishing;
            final isRecording = voiceState == _NoteVoiceInputState.listening;
            final voiceHelperText =
                voiceError ??
                (voiceState == _NoteVoiceInputState.idle
                    ? pickUiText(
                        i18n,
                        zh: '识别结果会追加到正文，标题留空时会自动生成摘要。',
                        en: 'Transcribed text is appended to the note body, and an empty title will be auto-filled.',
                        ja: '認識結果は本文に追記され、タイトルが空なら自動で要約が入ります。',
                        de: 'Erkannter Text wird an den Inhalt angehängt, und ein leerer Titel wird automatisch ergänzt.',
                        fr: 'Le texte reconnu est ajoute au contenu, et un titre vide sera complete automatiquement.',
                        es: 'El texto reconocido se anade al contenido y el titulo vacio se completa automaticamente.',
                        ru: 'Распознанный текст добавляется в заметку, а пустой заголовок заполняется автоматически.',
                      )
                    : _noteSpeechHelperText(
                        i18n,
                        voiceState,
                        speechLanguageTag,
                        voiceInputProvider,
                      ));
            final resolvedVoiceHelperText =
                voiceInputProvider == VoiceInputProviderType.system
                ? voiceHelperText
                : (voiceError ??
                      (_noteVoiceRecordingHelperText(
                            i18n,
                            voiceState,
                            speechLanguageTag,
                            voiceInputProvider,
                          ) +
                          (voiceState == _NoteVoiceInputState.idle
                              ? ' ${pickUiText(i18n, zh: '识别结果会追加到正文，标题留空时会自动生成摘要。', en: 'Transcribed text is appended to the note body, and an empty title will be auto-filled.')}'
                              : '')));

            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                16 + MediaQuery.viewInsetsOf(sheetContext).bottom,
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          i18n.t(note == null ? 'addNote' : 'editNote'),
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          key: const ValueKey<String>('note-title-field'),
                          controller: titleController,
                          autofocus: note == null,
                          decoration: InputDecoration(
                            labelText: i18n.t('noteTitle'),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          key: const ValueKey<String>('note-content-field'),
                          controller: contentController,
                          maxLines: 6,
                          decoration: InputDecoration(
                            labelText: i18n.t('noteContent'),
                            alignLabelWithHint: true,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.tonalIcon(
                          key: const ValueKey<String>(
                            'note-voice-input-button',
                          ),
                          onPressed: isVoiceBusy ? null : toggleVoiceInput,
                          icon: isVoiceBusy
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: theme.colorScheme.primary,
                                  ),
                                )
                              : Icon(
                                  isRecording
                                      ? Icons.stop_circle_outlined
                                      : Icons.mic_none_rounded,
                                ),
                          label: Text(voiceButtonLabel()),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          resolvedVoiceHelperText,
                          key: const ValueKey<String>('note-voice-helper-text'),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: voiceError == null
                                ? theme.colorScheme.onSurfaceVariant
                                : theme.colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          i18n.t('todoColor'),
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: <Widget>[
                            ChoiceChip(
                              label: Text(i18n.t('todoNoColor')),
                              selected: selectedColor == null,
                              onSelected: (_) {
                                setSheetState(() {
                                  selectedColor = null;
                                });
                              },
                            ),
                            for (final raw in _todoPalette)
                              ChoiceChip(
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Container(
                                      width: 14,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        color: Color(raw),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(i18n.t('todoColorOption')),
                                  ],
                                ),
                                selected: selectedColor?.toARGB32() == raw,
                                onSelected: (_) {
                                  setSheetState(() {
                                    selectedColor = Color(raw);
                                  });
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            TextButton(
                              onPressed: () => Navigator.pop(sheetContext),
                              child: Text(i18n.t('cancel')),
                            ),
                            const SizedBox(width: 8),
                            FilledButton.icon(
                              onPressed: () {
                                final rawTitle = titleController.text.trim();
                                final content = contentController.text.trim();
                                if (rawTitle.isEmpty && content.isEmpty) {
                                  return;
                                }
                                final title = rawTitle.isEmpty
                                    ? _defaultNoteTitle(i18n)
                                    : rawTitle;
                                if (note == null) {
                                  focus.addNote(
                                    title,
                                    content.isEmpty ? null : content,
                                    _colorToHex(selectedColor),
                                  );
                                } else {
                                  focus.updateNote(
                                    note.copyWith(
                                      title: title,
                                      content: content.isEmpty ? null : content,
                                      color: _colorToHex(selectedColor),
                                    ),
                                  );
                                }
                                Navigator.pop(sheetContext);
                              },
                              icon: const Icon(Icons.save_outlined),
                              label: Text(i18n.t('save')),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() async {
      sheetClosed = true;
      await cleanupVoiceInput();
    });
  }

  void _confirmDeleteSingleNote(
    FocusService focus,
    PlanNote note,
    AppI18n i18n,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(i18n.t('deleteNote')),
        content: Text(i18n.t('deleteNoteConfirm')),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(i18n.t('cancel')),
          ),
          FilledButton(
            onPressed: () {
              if (note.id != null) {
                focus.deleteNote(note.id!);
              }
              Navigator.pop(context);
            },
            child: Text(i18n.t('delete')),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteSelectedNotes(FocusService focus, AppI18n i18n) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(i18n.t('deleteSelectedNotes')),
        content: Text(
          i18n.t(
            'selectedNotesCount',
            params: <String, Object?>{'count': _selectedNoteIds.length},
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(i18n.t('cancel')),
          ),
          FilledButton(
            onPressed: () {
              focus.deleteNotes(_selectedNoteIds.toList(growable: false));
              setState(() {
                _selectedNoteIds.clear();
                _noteSelectionMode = false;
              });
              Navigator.pop(context);
            },
            child: Text(i18n.t('delete')),
          ),
        ],
      ),
    );
  }

  Future<void> _openAmbientAudioSheet(BuildContext context) async {
    final i18n = AppI18n(context.read<AppState>().uiLanguage);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return Consumer<AppState>(
          builder: (context, state, _) {
            final sources = state.ambientSources;
            final builtinSources = sources
                .where((item) => item.isAsset)
                .toList();
            final customSources = sources
                .where((item) => !item.isAsset)
                .toList();

            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                16 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          i18n.t('ambientAudio'),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: state.addAmbientFileSource,
                        icon: const Icon(Icons.library_music_rounded),
                        label: Text(i18n.t('importAudio')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(i18n.t('masterVolume')),
                  Slider(
                    value: state.ambientMasterVolume.clamp(0.0, 1.0),
                    onChanged: state.setAmbientMasterVolume,
                  ),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      children: <Widget>[
                        ..._buildAmbientGroups(
                          sources: builtinSources,
                          i18n: i18n,
                          state: state,
                        ),
                        if (customSources.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 8),
                          Text(
                            i18n.t('importedAudio'),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          ...customSources.map(
                            (source) => _buildAmbientTile(
                              source: source,
                              i18n: i18n,
                              state: state,
                              removable: true,
                            ),
                          ),
                        ],
                        if (sources.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Text(i18n.t('noAudioSources')),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<Widget> _buildAmbientGroups({
    required List<AmbientSource> sources,
    required AppI18n i18n,
    required AppState state,
  }) {
    final grouped = <String, List<AmbientSource>>{};
    for (final source in sources) {
      final key = _ambientCategoryKey(source.id);
      grouped.putIfAbsent(key, () => <AmbientSource>[]).add(source);
    }

    final widgets = <Widget>[];
    for (final entry in grouped.entries) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Text(
            i18n.t(entry.key),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      );
      for (final source in entry.value) {
        widgets.add(
          _buildAmbientTile(
            source: source,
            i18n: i18n,
            state: state,
            removable: false,
          ),
        );
      }
    }
    return widgets;
  }

  Widget _buildAmbientTile({
    required AmbientSource source,
    required AppI18n i18n,
    required AppState state,
    required bool removable,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(child: Text(localizedAmbientName(i18n, source))),
                Switch(
                  value: source.enabled,
                  onChanged: (enabled) =>
                      state.setAmbientSourceEnabled(source.id, enabled),
                ),
                if (removable)
                  IconButton(
                    onPressed: () => state.removeAmbientSource(source.id),
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
              ],
            ),
            Slider(
              value: source.volume.clamp(0.0, 1.0),
              onChanged: (value) =>
                  state.setAmbientSourceVolume(source.id, value),
            ),
          ],
        ),
      ),
    );
  }

  String _ambientCategoryKey(String id) {
    if (id.startsWith('noise_')) return 'ambientCategoryNoise';
    if (id.startsWith('nature_')) return 'ambientCategoryNature';
    if (id.startsWith('rain_')) return 'ambientCategoryRain';
    return 'ambientCategoryFocus';
  }

  String _formatTime(int seconds) {
    final duration = Duration(seconds: seconds.clamp(0, 359999));
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final secs = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String _formatUnitSummary(int seconds, AppI18n i18n) {
    final parts = _DurationParts.fromSeconds(seconds);
    final segments = <String>[];
    if (parts.hours > 0) {
      segments.add('${parts.hours}${i18n.t('hoursUnit')}');
    }
    if (parts.minutes > 0 || segments.isNotEmpty) {
      segments.add('${parts.minutes}${i18n.t('minutesUnit')}');
    }
    segments.add('${parts.seconds}${i18n.t('secondsUnit')}');
    return segments.join(' ');
  }

  String _formatPercent(double value) {
    return '${(value.clamp(0.0, 1.0) * 100).round()}%';
  }

  double _responsiveItemWidth(
    double maxWidth,
    AppWidthTier widthTier, {
    required int columns,
  }) {
    if (widthTier.isCompact) {
      return maxWidth;
    }
    final spacing = 12.0 * (columns - 1);
    if (widthTier.isExpanded) {
      return ((maxWidth - spacing) / columns).clamp(220.0, maxWidth).toDouble();
    }
    return ((maxWidth - 12) / 2).clamp(220.0, maxWidth).toDouble();
  }

  double _pageContentMaxWidth(AppWidthTier widthTier) {
    return switch (widthTier) {
      AppWidthTier.compact => 560.0,
      AppWidthTier.regular => 860.0,
      AppWidthTier.expanded => 980.0,
    };
  }
}

class _DurationParts {
  const _DurationParts({
    required this.hours,
    required this.minutes,
    required this.seconds,
  });

  final int hours;
  final int minutes;
  final int seconds;

  factory _DurationParts.fromSeconds(int totalSeconds) {
    final safe = totalSeconds.clamp(0, 359999);
    final duration = Duration(seconds: safe);
    return _DurationParts(
      hours: duration.inHours,
      minutes: duration.inMinutes.remainder(60),
      seconds: duration.inSeconds.remainder(60),
    );
  }

  int toSeconds() {
    final total = hours * 3600 + minutes * 60 + seconds;
    return total <= 0 ? 1 : total;
  }
}

class _StatItem {
  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;
}

class _CountdownRingPainter extends CustomPainter {
  const _CountdownRingPainter({
    required this.remaining,
    required this.pulse,
    required this.accent,
    required this.track,
    required this.surface,
  });

  final double remaining;
  final double pulse;
  final Color accent;
  final Color track;
  final Color surface;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final stroke = size.shortestSide * 0.08;
    final radius = size.shortestSide / 2 - stroke;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final clampedRemaining = remaining.clamp(0.0, 1.0).toDouble();
    final sweep = math.pi * 2 * clampedRemaining;

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: math.pi * 1.5,
        colors: <Color>[
          accent.withValues(alpha: 0.34),
          accent,
          accent.withValues(alpha: 0.72),
        ],
      ).createShader(rect);

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke + 6
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16)
      ..color = accent.withValues(alpha: 0.16 + pulse * 0.18);

    if (clampedRemaining > 0) {
      canvas.drawArc(rect, -math.pi / 2, sweep, false, glowPaint);
      canvas.drawArc(rect, -math.pi / 2, sweep, false, ringPaint);
    }

    final markerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.shortestSide * 0.018;
    for (var index = 0; index < 12; index++) {
      final angle = -math.pi / 2 + math.pi * 2 * (index / 12);
      final activeThreshold = clampedRemaining * 12;
      markerPaint.color = index < activeThreshold
          ? accent.withValues(alpha: 0.62)
          : accent.withValues(alpha: 0.14);
      final outer = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      final inner =
          center +
          Offset(math.cos(angle), math.sin(angle)) * (radius - stroke * 0.55);
      canvas.drawLine(inner, outer, markerPaint);
    }

    if (clampedRemaining > 0) {
      final handleAngle = -math.pi / 2 + sweep;
      final dotCenter =
          center +
          Offset(math.cos(handleAngle), math.sin(handleAngle)) * radius;
      final dotGlow = Paint()
        ..color = accent.withValues(alpha: 0.28 + pulse * 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawCircle(dotCenter, stroke * 0.52 + pulse * 4, dotGlow);
      canvas.drawCircle(
        dotCenter,
        stroke * 0.34 + pulse * 1.2,
        Paint()..color = surface,
      );
      canvas.drawCircle(
        dotCenter,
        stroke * 0.24 + pulse * 1.2,
        Paint()..color = accent,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CountdownRingPainter oldDelegate) {
    return oldDelegate.remaining != remaining ||
        oldDelegate.pulse != pulse ||
        oldDelegate.accent != accent ||
        oldDelegate.track != track ||
        oldDelegate.surface != surface;
  }
}

class _HourglassPainter extends CustomPainter {
  const _HourglassPainter({
    required this.remaining,
    required this.pulse,
    required this.accent,
    required this.track,
  });

  final double remaining;
  final double pulse;
  final Color accent;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final clampedRemaining = remaining.clamp(0.0, 1.0).toDouble();
    final sandPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = accent.withValues(alpha: 0.90);
    final glassPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = track.withValues(alpha: 0.54);
    final framePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.055
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = accent.withValues(alpha: 0.92);
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.075
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14)
      ..color = accent.withValues(alpha: 0.14 + pulse * 0.12);

    final topChamber = Path()
      ..moveTo(width * 0.28, height * 0.18)
      ..lineTo(width * 0.72, height * 0.18)
      ..lineTo(width * 0.50, height * 0.47)
      ..close();
    final bottomChamber = Path()
      ..moveTo(width * 0.50, height * 0.53)
      ..lineTo(width * 0.72, height * 0.82)
      ..lineTo(width * 0.28, height * 0.82)
      ..close();

    canvas.drawPath(topChamber, glassPaint);
    canvas.drawPath(bottomChamber, glassPaint);

    final topFillHeight = height * 0.29 * clampedRemaining;
    canvas.save();
    canvas.clipPath(topChamber);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          width * 0.24,
          height * 0.48 - topFillHeight,
          width * 0.52,
          topFillHeight + 4,
        ),
        Radius.circular(width * 0.04),
      ),
      sandPaint,
    );
    canvas.restore();

    final bottomFillHeight = height * 0.29 * (1 - clampedRemaining);
    canvas.save();
    canvas.clipPath(bottomChamber);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          width * 0.24,
          height * 0.82 - bottomFillHeight,
          width * 0.52,
          bottomFillHeight + 4,
        ),
        Radius.circular(width * 0.04),
      ),
      sandPaint,
    );
    canvas.restore();

    if (clampedRemaining > 0 && clampedRemaining < 1) {
      final streamPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.shortestSide * (0.014 + pulse * 0.010)
        ..strokeCap = StrokeCap.round
        ..color = accent.withValues(alpha: 0.78);
      canvas.drawLine(
        Offset(width * 0.50, height * 0.44),
        Offset(width * 0.50, height * 0.60),
        streamPaint,
      );
      canvas.drawCircle(
        Offset(width * 0.50, height * (0.60 + pulse * 0.07)),
        size.shortestSide * 0.018,
        Paint()..color = accent,
      );
    }

    final framePath = Path()
      ..moveTo(width * 0.22, height * 0.10)
      ..lineTo(width * 0.78, height * 0.10)
      ..moveTo(width * 0.30, height * 0.18)
      ..lineTo(width * 0.50, height * 0.45)
      ..lineTo(width * 0.70, height * 0.18)
      ..moveTo(width * 0.30, height * 0.82)
      ..lineTo(width * 0.50, height * 0.55)
      ..lineTo(width * 0.70, height * 0.82)
      ..moveTo(width * 0.22, height * 0.90)
      ..lineTo(width * 0.78, height * 0.90);

    canvas.drawPath(framePath, glowPaint);
    canvas.drawPath(framePath, framePaint);
  }

  @override
  bool shouldRepaint(covariant _HourglassPainter oldDelegate) {
    return oldDelegate.remaining != remaining ||
        oldDelegate.pulse != pulse ||
        oldDelegate.accent != accent ||
        oldDelegate.track != track;
  }
}
