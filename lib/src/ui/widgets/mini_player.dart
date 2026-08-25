import 'dart:async';

import 'package:flutter/material.dart';

import '../../i18n/app_i18n.dart';
import '../../models/word_entry.dart';
import '../../state/app_state.dart';
import '../sheets/ambient_sheet.dart';
import '../theme/app_theme.dart';

class MiniPlayer extends StatefulWidget {
  const MiniPlayer({
    super.key,
    required this.state,
    required this.i18n,
    this.onOpenPractice,
    this.onOpenLibrary,
    this.onPresentationChanged,
  });

  final AppState state;
  final AppI18n i18n;
  final VoidCallback? onOpenPractice;
  final VoidCallback? onOpenLibrary;
  final void Function(bool visible, bool collapsed, double reservedHeight)?
  onPresentationChanged;

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> {
  static const List<double> _playbackSpeedMenuValues = <double>[
    0.5,
    0.6,
    0.7,
    0.8,
    0.9,
    1.0,
    1.1,
    1.2,
    1.3,
    1.4,
    1.5,
  ];

  Timer? _sleepTimer;
  DateTime? _sleepTimerEndsAt;
  String _lastPresentationSignature = '';
  bool _collapsed = true;

  AppState get _state => widget.state;
  AppI18n get _i18n => widget.i18n;

  bool get _hasSleepTimer => _sleepTimer != null && _sleepTimerEndsAt != null;
  bool get _isVisible => _state.isPlaying || _hasSleepTimer;

  @override
  void initState() {
    super.initState();
    widget.state.playbackUnitProgressListenable.addListener(
      _handlePlaybackUnitProgressChanged,
    );
    widget.state.playbackRevisionListenable.addListener(
      _handlePlaybackUnitProgressChanged,
    );
  }

  @override
  void didUpdateWidget(covariant MiniPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state == widget.state) {
      return;
    }
    oldWidget.state.playbackUnitProgressListenable.removeListener(
      _handlePlaybackUnitProgressChanged,
    );
    oldWidget.state.playbackRevisionListenable.removeListener(
      _handlePlaybackUnitProgressChanged,
    );
    widget.state.playbackUnitProgressListenable.addListener(
      _handlePlaybackUnitProgressChanged,
    );
    widget.state.playbackRevisionListenable.addListener(
      _handlePlaybackUnitProgressChanged,
    );
  }

  void _handlePlaybackUnitProgressChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    widget.state.playbackUnitProgressListenable.removeListener(
      _handlePlaybackUnitProgressChanged,
    );
    widget.state.playbackRevisionListenable.removeListener(
      _handlePlaybackUnitProgressChanged,
    );
    _sleepTimer?.cancel();
    _sleepTimer = null;
    super.dispose();
  }

  double _reservedHeight(bool compact, double viewportHeight) {
    if (!_isVisible || _collapsed) return 0;
    final target = compact ? 300.0 : 340.0;
    final maxByViewport = (viewportHeight * 0.52).clamp(190.0, target);
    return maxByViewport.toDouble();
  }

  void _reportPresentation(bool compact, double viewportHeight) {
    final reservedHeight = _reservedHeight(compact, viewportHeight);
    final signature =
        '$_isVisible|$_collapsed|${reservedHeight.toStringAsFixed(1)}';
    if (signature == _lastPresentationSignature) return;
    _lastPresentationSignature = signature;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onPresentationChanged?.call(
        _isVisible,
        _collapsed,
        reservedHeight,
      );
    });
  }

  void _toggleCollapsed() {
    setState(() {
      _collapsed = !_collapsed;
    });
  }

  void _openToolsSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        final state = _state;
        final i18n = _i18n;
        final queue = _buildQueuePreview(state);
        final weakCount = state.recentWeakWordEntries.length;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: <Widget>[
            Text(
              i18n.t('inline.ui.widgets.mini_player.playback_tools_e9bb36'),
              style: Theme.of(sheetContext).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              i18n.t(
                'inline.ui.widgets.mini_player.review_queue_and_quick_tools_without_leaving_the_current_c9f182',
              ),
              style: Theme.of(sheetContext).textTheme.bodySmall,
            ),
            const SizedBox(height: 14),
            Card(
              child: ListTile(
                title: Text(
                  state.playingWord ?? state.currentWord?.word ?? '-',
                ),
                subtitle: Text(
                  state.isPlaying
                      ? '${state.playingWordbookName ?? state.selectedWordbook?.name ?? ''} · ${state.currentUnit}/${state.totalUnits}'
                      : i18n.t(
                          'inline.ui.widgets.mini_player.playback_is_currently_paused_b208ae',
                        ),
                ),
                trailing: Icon(
                  state.isPlaying
                      ? Icons.graphic_eq_rounded
                      : Icons.pause_circle_outline_rounded,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                if (state.isPlaying)
                  FilledButton.tonalIcon(
                    onPressed: state.pauseOrResume,
                    icon: Icon(
                      state.isPaused
                          ? Icons.play_arrow_rounded
                          : Icons.pause_rounded,
                    ),
                    label: Text(
                      state.isPaused ? i18n.t('resume') : i18n.t('pause'),
                    ),
                  )
                else
                  FilledButton.icon(
                    onPressed: state.playCurrentWordbook,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(i18n.t('play')),
                  ),
                if (state.isPlaying)
                  OutlinedButton.icon(
                    onPressed: state.stop,
                    icon: const Icon(Icons.stop_rounded),
                    label: Text(i18n.t('stop')),
                  ),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => AmbientSheet(state: state, i18n: i18n),
                    );
                  },
                  icon: const Icon(Icons.surround_sound_rounded),
                  label: Text(
                    i18n.t('inline.ui.pages.play_page.ambient_6e3e01'),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    _openSleepTimerSheet();
                  },
                  icon: const Icon(Icons.bedtime_outlined),
                  label: Text(i18n.t('toolbox.sound.soothing.v2.timer.button')),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      i18n.t(
                        'inline.ui.widgets.mini_player.queue_preview_90de94',
                      ),
                      style: Theme.of(sheetContext).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (queue.isEmpty)
                      Text(
                        i18n.t(
                          'inline.ui.widgets.mini_player.no_queue_items_available_in_the_current_scope_af3de2',
                        ),
                      )
                    else
                      for (final item in queue)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text('• $item'),
                        ),
                  ],
                ),
              ),
            ),
            if (weakCount > 0 || widget.onOpenPractice != null) ...<Widget>[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        i18n.t(
                          'inline.ui.widgets.mini_player.suggested_next_step_7aeb16',
                        ),
                        style: Theme.of(sheetContext).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        weakCount > 0
                            ? i18n.t(
                                'inline.ui.widgets.mini_player.you_have_weakcount_recent_weak_words_practice_is_recomme_ab5015',
                                params: <String, Object?>{
                                  'weakCount': weakCount,
                                },
                              )
                            : i18n.t(
                                'inline.ui.widgets.mini_player.you_can_continue_in_practice_or_return_to_the_library_b92564',
                              ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: <Widget>[
                          if (widget.onOpenPractice != null)
                            FilledButton.icon(
                              onPressed: () {
                                Navigator.of(sheetContext).pop();
                                widget.onOpenPractice?.call();
                              },
                              icon: const Icon(Icons.fitness_center_rounded),
                              label: Text(
                                i18n.t(
                                  'inline.ui.pages.play_page.open_practice_846215',
                                ),
                              ),
                            ),
                          if (widget.onOpenLibrary != null)
                            OutlinedButton.icon(
                              onPressed: () {
                                Navigator.of(sheetContext).pop();
                                widget.onOpenLibrary?.call();
                              },
                              icon: const Icon(Icons.menu_book_rounded),
                              label: Text(
                                i18n.t(
                                  'inline.ui.widgets.mini_player.open_library_75c639',
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  List<String> _buildQueuePreview(AppState state) {
    final words = state.visibleWords;
    if (words.isEmpty) return const <String>[];
    final current = state.currentWord;
    if (current == null) {
      return words.take(6).map((item) => item.word).toList(growable: false);
    }
    final index = words.indexWhere((item) => item.word == current.word);
    if (index < 0) {
      return words.take(6).map((item) => item.word).toList(growable: false);
    }
    final queue = <WordEntry>[words[index]];
    for (var offset = 1; offset <= 5; offset += 1) {
      queue.add(words[(index + offset) % words.length]);
    }
    return queue.map((item) => item.word).toList(growable: false);
  }

  String _sleepTimerLabel(AppI18n i18n) {
    final endsAt = _sleepTimerEndsAt;
    if (endsAt == null) return '';
    final remaining = endsAt.difference(DateTime.now());
    final minutes = remaining.inMinutes;
    if (minutes <= 0) {
      return i18n.t('inline.ui.widgets.mini_player.stopping_soon_6958ed');
    }
    return i18n.t(
      'inline.ui.widgets.mini_player.sleep_timer_enabled_stop_in_about_minutes_min_8b3e99',
      params: <String, Object?>{'minutes': minutes},
    );
  }

  void _setSleepTimer(Duration duration, BuildContext feedbackContext) {
    _sleepTimer?.cancel();
    _sleepTimer = Timer(duration, () {
      _state.stop();
      if (!mounted) return;
      setState(() {
        _sleepTimer = null;
        _sleepTimerEndsAt = null;
        _collapsed = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _i18n.t(
              'inline.ui.widgets.mini_player.playback_stopped_by_sleep_timer_b8b542',
            ),
          ),
        ),
      );
    });
    setState(() {
      _sleepTimerEndsAt = DateTime.now().add(duration);
    });
    ScaffoldMessenger.of(feedbackContext).showSnackBar(
      SnackBar(
        content: Text(
          _i18n.t(
            'inline.ui.widgets.mini_player.playback_will_stop_in_duration_inminutes_minutes_ab0716',
            params: <String, Object?>{'durationInMinutes': duration.inMinutes},
          ),
        ),
      ),
    );
  }

  void _cancelSleepTimer(BuildContext feedbackContext) {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    setState(() {
      _sleepTimerEndsAt = null;
    });
    ScaffoldMessenger.of(feedbackContext).showSnackBar(
      SnackBar(
        content: Text(
          _i18n.t('inline.ui.widgets.mini_player.sleep_timer_cancelled_bb75e9'),
        ),
      ),
    );
  }

  void _openSleepTimerSheet() {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (sheetContext) {
        final i18n = _i18n;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                i18n.t('toolbox.sound.soothing.v2.timer.button'),
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                i18n.t(
                  'inline.ui.widgets.mini_player.playback_may_continue_for_a_while_on_large_wordbooks_bc770e',
                ),
                style: Theme.of(sheetContext).textTheme.bodySmall,
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  OutlinedButton(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      _setSleepTimer(const Duration(minutes: 15), sheetContext);
                    },
                    child: const Text('15m'),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      _setSleepTimer(const Duration(minutes: 30), sheetContext);
                    },
                    child: const Text('30m'),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      _setSleepTimer(const Duration(minutes: 60), sheetContext);
                    },
                    child: const Text('60m'),
                  ),
                  if (_hasSleepTimer)
                    FilledButton.tonal(
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        _cancelSleepTimer(sheetContext);
                      },
                      child: Text(
                        i18n.t(
                          'inline.ui.widgets.mini_player.cancel_timer_e129ec',
                        ),
                      ),
                    ),
                ],
              ),
              if (_hasSleepTimer) ...<Widget>[
                const SizedBox(height: 10),
                Text(
                  _sleepTimerLabel(i18n),
                  style: Theme.of(sheetContext).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;
    final i18n = _i18n;
    final compact = state.config.appearance.compactLayout;
    final viewportHeight = MediaQuery.sizeOf(context).height;
    final expandedMaxHeight = _reservedHeight(
      compact,
      viewportHeight,
    ).clamp(190.0, 360.0);
    _reportPresentation(compact, viewportHeight);

    if (!_isVisible) {
      if (!_collapsed) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _collapsed = true;
          });
        });
      }
      return const SizedBox.shrink();
    }

    final currentWord = state.playingWord ?? state.currentWord?.word ?? '';
    final wordbookName =
        state.playingWordbookName ?? state.selectedWordbook?.name ?? '';
    final subtitle = state.isPlaying
        ? '$wordbookName · ${state.currentUnit}/${state.totalUnits}'
        : i18n.t('inline.ui.widgets.mini_player.playback_paused_f432d2');
    final progress = state.totalUnits <= 0
        ? 0.0
        : (state.currentUnit / state.totalUnits).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Align(
        alignment: Alignment.center,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: _collapsed
              ? _CollapsedMiniPlayer(
                  key: const ValueKey<String>('collapsed-mini-player'),
                  i18n: i18n,
                  isPaused: state.isPaused,
                  hasSleepTimer: _hasSleepTimer,
                  onTap: _toggleCollapsed,
                )
              : _ExpandedMiniPlayer(
                  key: const ValueKey<String>('expanded-mini-player'),
                  maxHeight: expandedMaxHeight,
                  i18n: i18n,
                  title: currentWord.isEmpty ? wordbookName : currentWord,
                  subtitle: subtitle,
                  progress: progress,
                  isPlaying: state.isPlaying,
                  isPaused: state.isPaused,
                  hasSleepTimer: _hasSleepTimer,
                  sleepTimerLabel: _sleepTimerLabel(i18n),
                  speed: state.config.tts.speed,
                  speedValues: _playbackSpeedMenuValues,
                  onCollapse: _toggleCollapsed,
                  onSpeedChanged: (value) {
                    state.updateConfig(
                      state.config.copyWith(
                        tts: state.config.tts.copyWith(speed: value),
                      ),
                    );
                  },
                  onPrevious: state.isPlaying
                      ? state.movePlaybackPreviousWord
                      : null,
                  onPlayPause: state.isPlaying
                      ? state.pauseOrResume
                      : state.playCurrentWordbook,
                  onNext: state.isPlaying ? state.movePlaybackNextWord : null,
                  onStop: state.isPlaying ? state.stop : null,
                  onAmbient: () {
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => AmbientSheet(state: state, i18n: i18n),
                    );
                  },
                  onSleepTimer: _openSleepTimerSheet,
                  onTools: _openToolsSheet,
                ),
        ),
      ),
    );
  }
}

class _CollapsedMiniPlayer extends StatelessWidget {
  const _CollapsedMiniPlayer({
    super.key,
    required this.i18n,
    required this.isPaused,
    required this.hasSleepTimer,
    required this.onTap,
  });

  final AppI18n i18n;
  final bool isPaused;
  final bool hasSleepTimer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppThemeTokens.of(context);

    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Material(
            color: tokens.surfaceOverlay,
            elevation: 10,
            shadowColor: tokens.glow.withValues(alpha: 0.22),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(999)),
            ),
            child: InkWell(
              onTap: onTap,
              customBorder: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(999)),
              ),
              child: SizedBox(
                width: 84,
                height: 42,
                child: Icon(
                  isPaused
                      ? Icons.play_arrow_rounded
                      : Icons.graphic_eq_rounded,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
          if (hasSleepTimer)
            Positioned(
              top: 8,
              right: 12,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: theme.colorScheme.tertiary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ExpandedMiniPlayer extends StatefulWidget {
  const _ExpandedMiniPlayer({
    super.key,
    required this.maxHeight,
    required this.i18n,
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.isPlaying,
    required this.isPaused,
    required this.hasSleepTimer,
    required this.sleepTimerLabel,
    required this.speed,
    required this.speedValues,
    required this.onCollapse,
    required this.onSpeedChanged,
    this.onPrevious,
    required this.onPlayPause,
    this.onNext,
    this.onStop,
    required this.onAmbient,
    required this.onSleepTimer,
    required this.onTools,
  });

  final double maxHeight;
  final AppI18n i18n;
  final String title;
  final String subtitle;
  final double progress;
  final bool isPlaying;
  final bool isPaused;
  final bool hasSleepTimer;
  final String sleepTimerLabel;
  final double speed;
  final List<double> speedValues;
  final VoidCallback onCollapse;
  final ValueChanged<double> onSpeedChanged;
  final VoidCallback? onPrevious;
  final VoidCallback onPlayPause;
  final VoidCallback? onNext;
  final VoidCallback? onStop;
  final VoidCallback onAmbient;
  final VoidCallback onSleepTimer;
  final VoidCallback onTools;

  @override
  State<_ExpandedMiniPlayer> createState() => _ExpandedMiniPlayerState();
}

class _ExpandedMiniPlayerState extends State<_ExpandedMiniPlayer> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppThemeTokens.of(context);
    final maxHeight = widget.maxHeight;
    final i18n = widget.i18n;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 720, maxHeight: maxHeight),
      child: Material(
        color: tokens.surfaceOverlay,
        elevation: 12,
        shadowColor: tokens.glow.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(24),
        child: Scrollbar(
          controller: _scrollController,
          thumbVisibility: maxHeight < 250,
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            widget.title.isEmpty ? '-' : widget.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: widget.onCollapse,
                      tooltip: i18n.t(
                        'inline.plan295.daily_choice.collapse.ad0db950964e',
                      ),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    value: widget.progress,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: <Widget>[
                    if (widget.onPrevious != null)
                      OutlinedButton.icon(
                        onPressed: widget.onPrevious,
                        icon: const Icon(Icons.skip_previous_rounded),
                        label: Text(i18n.t('prev')),
                      ),
                    FilledButton.tonalIcon(
                      onPressed: widget.onPlayPause,
                      icon: Icon(
                        widget.isPlaying && !widget.isPaused
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                      ),
                      label: Text(
                        widget.isPlaying && !widget.isPaused
                            ? i18n.t('pause')
                            : (widget.isPaused
                                  ? i18n.t('resume')
                                  : i18n.t('play')),
                      ),
                    ),
                    if (widget.onNext != null)
                      OutlinedButton.icon(
                        onPressed: widget.onNext,
                        icon: const Icon(Icons.skip_next_rounded),
                        label: Text(i18n.t('next')),
                      ),
                    if (widget.onStop != null)
                      OutlinedButton.icon(
                        onPressed: widget.onStop,
                        icon: const Icon(Icons.stop_rounded),
                        label: Text(i18n.t('stop')),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: <Widget>[
                    OutlinedButton.icon(
                      onPressed: widget.onAmbient,
                      icon: const Icon(Icons.surround_sound_rounded),
                      label: Text(
                        i18n.t('inline.ui.pages.play_page.ambient_6e3e01'),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: widget.onSleepTimer,
                      icon: Icon(
                        widget.hasSleepTimer
                            ? Icons.bedtime_rounded
                            : Icons.bedtime_outlined,
                      ),
                      label: Text(
                        i18n.t('toolbox.sound.soothing.v2.timer.button'),
                      ),
                    ),
                    _PlaybackSpeedMenu(
                      i18n: i18n,
                      speed: widget.speed,
                      values: widget.speedValues,
                      onChanged: widget.onSpeedChanged,
                    ),
                    OutlinedButton.icon(
                      onPressed: widget.onTools,
                      icon: const Icon(Icons.tune_rounded),
                      label: Text(
                        i18n.t(
                          'inline.ui.widgets.mini_player.more_tools_3768f4',
                        ),
                      ),
                    ),
                  ],
                ),
                if (widget.hasSleepTimer &&
                    widget.sleepTimerLabel.trim().isNotEmpty) ...<Widget>[
                  const SizedBox(height: 10),
                  Text(
                    widget.sleepTimerLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.tertiary,
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
}

class _PlaybackSpeedMenu extends StatelessWidget {
  const _PlaybackSpeedMenu({
    required this.i18n,
    required this.speed,
    required this.values,
    required this.onChanged,
  });

  final AppI18n i18n;
  final double speed;
  final List<double> values;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentSpeed = speed.clamp(0.5, 1.5).toDouble();
    final currentPercent = (currentSpeed * 100).round();
    return PopupMenuButton<double>(
      key: const ValueKey<String>('mini-player-speed-menu'),
      tooltip: i18n.t(
        'play.playback.speed_label',
        params: <String, Object?>{'value': currentPercent},
      ),
      onSelected: onChanged,
      itemBuilder: (context) {
        return values
            .map(
              (value) => CheckedPopupMenuItem<double>(
                value: value,
                checked: (currentSpeed - value).abs() < 0.01,
                child: Text(_formatSpeed(value)),
              ),
            )
            .toList(growable: false);
      },
      child: InputChip(
        avatar: const Icon(Icons.speed_rounded, size: 18),
        label: Text(_formatSpeed(currentSpeed)),
        labelStyle: theme.textTheme.labelLarge,
        onPressed: null,
      ),
    );
  }

  String _formatSpeed(double value) {
    final rounded = (value * 10).round() / 10;
    return '${rounded.toStringAsFixed(1)}x';
  }
}
