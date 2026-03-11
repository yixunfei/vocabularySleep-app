import 'dart:async';

import 'package:flutter/material.dart';

import '../../i18n/app_i18n.dart';
import '../../models/word_entry.dart';
import '../../state/app_state.dart';
import '../sheets/ambient_sheet.dart';
import '../theme/app_theme.dart';
import '../ui_copy.dart';

class MiniPlayer extends StatefulWidget {
  const MiniPlayer({
    super.key,
    required this.state,
    required this.i18n,
    this.onOpenPractice,
    this.onOpenLibrary,
  });

  final AppState state;
  final AppI18n i18n;
  final VoidCallback? onOpenPractice;
  final VoidCallback? onOpenLibrary;

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> {
  Timer? _sleepTimer;
  DateTime? _sleepTimerEndsAt;

  AppState get _state => widget.state;
  AppI18n get _i18n => widget.i18n;

  bool get _hasSleepTimer => _sleepTimer != null && _sleepTimerEndsAt != null;

  @override
  void dispose() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    super.dispose();
  }

  void _openExpandedPanel() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        final state = _state;
        final i18n = _i18n;
        final queue = _buildQueuePreview(state);
        final weakCount = state.recentWeakWordEntries.length;

        return SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: <Widget>[
              Text(
                pickUiText(i18n, zh: '播放工具层', en: 'Playback tools'),
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                pickUiText(
                  i18n,
                  zh: '在不离开主流程的情况下查看队列和常用工具。',
                  en: 'Review queue and tools without leaving the main flow.',
                ),
                style: Theme.of(sheetContext).textTheme.bodySmall,
              ),
              const SizedBox(height: 14),
              Card(
                child: ListTile(
                  title: Text(
                    state.isPlaying
                        ? (state.playingWord ?? state.currentWord?.word ?? '-')
                        : (state.currentWord?.word ?? '-'),
                  ),
                  subtitle: Text(
                    state.isPlaying
                        ? '${state.playingWordbookName ?? state.selectedWordbook?.name ?? ''} · ${state.currentUnit}/${state.totalUnits}'
                        : pickUiText(
                            i18n,
                            zh: '尚未开始播放，点击下方按钮可直接启动。',
                            en: 'Playback is idle. Use controls below to start.',
                          ),
                  ),
                  trailing: state.isPlaying
                      ? const Icon(Icons.graphic_eq_rounded)
                      : const Icon(Icons.pause_circle_outline_rounded),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  if (!state.isPlaying)
                    FilledButton.icon(
                      onPressed: state.playCurrentWordbook,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(i18n.t('play')),
                    ),
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
                    ),
                  if (state.isPlaying)
                    FilledButton.tonalIcon(
                      onPressed: state.stop,
                      icon: const Icon(Icons.stop_rounded),
                      label: Text(i18n.t('stop')),
                    ),
                  if (state.isPlaying)
                    OutlinedButton.icon(
                      onPressed: state.movePlaybackPreviousWord,
                      icon: const Icon(Icons.skip_previous_rounded),
                      label: Text(i18n.t('prev')),
                    ),
                  if (state.isPlaying)
                    OutlinedButton.icon(
                      onPressed: state.movePlaybackNextWord,
                      icon: const Icon(Icons.skip_next_rounded),
                      label: Text(i18n.t('next')),
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
                        pickUiText(i18n, zh: '当前队列预览', en: 'Queue preview'),
                        style: Theme.of(sheetContext).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      if (queue.isEmpty)
                        Text(
                          pickUiText(
                            i18n,
                            zh: '当前范围暂无可展示项。',
                            en: 'No queue items available in current scope.',
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
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        pickUiText(i18n, zh: '场景工具', en: 'Scene tools'),
                        style: Theme.of(sheetContext).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: <Widget>[
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(sheetContext).pop();
                              showModalBottomSheet<void>(
                                context: context,
                                isScrollControlled: true,
                                builder: (_) =>
                                    AmbientSheet(state: state, i18n: i18n),
                              );
                            },
                            icon: const Icon(Icons.surround_sound_rounded),
                            label: Text(
                              pickUiText(i18n, zh: '环境音', en: 'Ambient'),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _setSleepTimer(
                              const Duration(minutes: 15),
                              sheetContext,
                            ),
                            icon: const Icon(Icons.bedtime_outlined),
                            label: Text(
                              pickUiText(
                                i18n,
                                zh: '15 分钟后停止',
                                en: 'Stop in 15m',
                              ),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _setSleepTimer(
                              const Duration(minutes: 30),
                              sheetContext,
                            ),
                            icon: const Icon(Icons.bedtime_outlined),
                            label: Text(
                              pickUiText(
                                i18n,
                                zh: '30 分钟后停止',
                                en: 'Stop in 30m',
                              ),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _setSleepTimer(
                              const Duration(minutes: 60),
                              sheetContext,
                            ),
                            icon: const Icon(Icons.bedtime_outlined),
                            label: Text(
                              pickUiText(
                                i18n,
                                zh: '60 分钟后停止',
                                en: 'Stop in 60m',
                              ),
                            ),
                          ),
                          if (_hasSleepTimer)
                            FilledButton.tonalIcon(
                              onPressed: () => _cancelSleepTimer(sheetContext),
                              icon: const Icon(Icons.alarm_off_rounded),
                              label: Text(
                                pickUiText(
                                  i18n,
                                  zh: '取消定时',
                                  en: 'Cancel timer',
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (_hasSleepTimer) ...[
                        const SizedBox(height: 8),
                        Text(
                          _sleepTimerLabel(i18n),
                          style: Theme.of(sheetContext).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (weakCount > 0 || widget.onOpenPractice != null) ...[
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          pickUiText(
                            i18n,
                            zh: '下一步建议',
                            en: 'Suggested next step',
                          ),
                          style: Theme.of(sheetContext).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          weakCount > 0
                              ? pickUiText(
                                  i18n,
                                  zh: '你有 $weakCount 个最近薄弱词，建议进入练习中心优先复习。',
                                  en: 'You have $weakCount recent weak words. Practice is recommended.',
                                )
                              : pickUiText(
                                  i18n,
                                  zh: '播放后建议去练习中心巩固当前内容。',
                                  en: 'After playback, reinforce in Practice.',
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
                                  pickUiText(
                                    i18n,
                                    zh: '打开练习中心',
                                    en: 'Open practice',
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
                                  pickUiText(
                                    i18n,
                                    zh: '打开词库',
                                    en: 'Open library',
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
          ),
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
    final queue = <WordEntry>[];
    queue.add(words[index]);
    for (var offset = 1; offset <= 5; offset += 1) {
      final next = words[(index + offset) % words.length];
      queue.add(next);
    }
    return queue.map((item) => item.word).toList(growable: false);
  }

  String _sleepTimerLabel(AppI18n i18n) {
    final endsAt = _sleepTimerEndsAt;
    if (endsAt == null) return '';
    final now = DateTime.now();
    final remaining = endsAt.difference(now);
    final minutes = remaining.inMinutes;
    if (minutes <= 0) {
      return pickUiText(i18n, zh: '即将停止播放', en: 'Stopping soon');
    }
    return pickUiText(
      i18n,
      zh: '定时停止已开启：约 $minutes 分钟后停止',
      en: 'Sleep timer enabled: stop in about $minutes min',
    );
  }

  void _setSleepTimer(Duration duration, BuildContext sheetContext) {
    _sleepTimer?.cancel();
    _sleepTimer = Timer(duration, () {
      _state.stop();
      if (!mounted) return;
      setState(() {
        _sleepTimer = null;
        _sleepTimerEndsAt = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            pickUiText(
              _i18n,
              zh: '已按定时器自动停止播放',
              en: 'Playback stopped by sleep timer',
            ),
          ),
        ),
      );
    });
    setState(() {
      _sleepTimerEndsAt = DateTime.now().add(duration);
    });
    ScaffoldMessenger.of(sheetContext).showSnackBar(
      SnackBar(
        content: Text(
          pickUiText(
            _i18n,
            zh: '${duration.inMinutes} 分钟后将自动停止播放',
            en: 'Playback will stop in ${duration.inMinutes} minutes',
          ),
        ),
      ),
    );
  }

  void _cancelSleepTimer(BuildContext sheetContext) {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    setState(() {
      _sleepTimerEndsAt = null;
    });
    ScaffoldMessenger.of(sheetContext).showSnackBar(
      SnackBar(
        content: Text(
          pickUiText(_i18n, zh: '已取消定时停止', en: 'Sleep timer cancelled'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;
    if (state.selectedWordbook == null) return const SizedBox.shrink();
    final i18n = _i18n;
    final tokens = AppThemeTokens.of(context);
    final compact = state.config.appearance.compactLayout;
    final isPlaying = state.isPlaying;
    final title = isPlaying
        ? (state.playingWord ?? state.currentWord?.word ?? '')
        : (state.currentWord?.word ?? state.selectedWordbook!.name);
    final subtitle = isPlaying
        ? '${state.playingWordbookName ?? state.selectedWordbook?.name ?? ''} · ${state.currentUnit}/${state.totalUnits}'
        : pickUiText(
            i18n,
            zh: '从当前词开始整本播放',
            en: 'Start the current wordbook from here.',
          );

    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, compact ? 10 : 12),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: tokens.surfaceOverlay,
            borderRadius: BorderRadius.circular(compact ? 22 : 26),
            border: Border.all(color: tokens.outline),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: tokens.glow.withValues(
                  alpha: tokens.isDark ? 0.18 : 0.08,
                ),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 14 : 18,
              vertical: compact ? 10 : 12,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 390;
                final titleSection = Expanded(
                  child: InkWell(
                    onTap: _openExpandedPanel,
                    borderRadius: BorderRadius.circular(18),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _hasSleepTimer
                                ? '$subtitle · ${pickUiText(i18n, zh: '定时中', en: 'Timer on')}'
                                : subtitle,
                            maxLines: isNarrow ? 2 : 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                );

                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          titleSection,
                          IconButton(
                            onPressed: _openExpandedPanel,
                            tooltip: pickUiText(
                              i18n,
                              zh: '展开播放器',
                              en: 'Expand player',
                            ),
                            icon: const Icon(Icons.expand_less_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (isPlaying)
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
                    ],
                  );
                }

                return Row(
                  children: <Widget>[
                    titleSection,
                    IconButton(
                      onPressed: _openExpandedPanel,
                      tooltip: pickUiText(
                        i18n,
                        zh: '展开播放器',
                        en: 'Expand player',
                      ),
                      icon: const Icon(Icons.expand_less_rounded),
                    ),
                    if (isPlaying) ...[
                      IconButton(
                        onPressed: state.movePlaybackPreviousWord,
                        icon: const Icon(Icons.skip_previous_rounded),
                      ),
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
                      ),
                      IconButton(
                        onPressed: state.movePlaybackNextWord,
                        icon: const Icon(Icons.skip_next_rounded),
                      ),
                    ] else
                      FilledButton.icon(
                        onPressed: state.playCurrentWordbook,
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: Text(i18n.t('play')),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
