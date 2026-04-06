import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../i18n/app_i18n.dart';
import '../../services/ambient_service.dart';
import '../../services/online_ambient_catalog_service.dart';
import '../../state/app_state.dart';
import 'sleep_assistant_ui_support.dart';

Future<void> showSleepWhiteNoiseSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _SleepWhiteNoiseSheet(),
  );
}

Future<void> showCaffeineCutoffCalculatorSheet(
  BuildContext context, {
  TimeOfDay? bedtime,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => _CaffeineCutoffSheet(initialBedtime: bedtime),
  );
}

Future<void> showMorningLightTimerSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => const _MorningLightTimerSheet(),
  );
}

Future<void> showSleepinessDecisionSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => const _SleepinessDecisionSheet(),
  );
}

class SleepQuickToolButton extends StatelessWidget {
  const SleepQuickToolButton({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(title),
    );
  }
}

class _SleepWhiteNoiseSheet extends StatefulWidget {
  const _SleepWhiteNoiseSheet();

  @override
  State<_SleepWhiteNoiseSheet> createState() => _SleepWhiteNoiseSheetState();
}

class _SleepWhiteNoiseSheetState extends State<_SleepWhiteNoiseSheet> {
  late Future<List<OnlineAmbientSoundOption>> _catalogFuture;
  String? _downloadingId;

  @override
  void initState() {
    super.initState();
    _catalogFuture = context.read<AppState>().fetchOnlineAmbientCatalog();
  }

  Future<void> _downloadOption(OnlineAmbientSoundOption option) async {
    setState(() => _downloadingId = option.id);
    final appState = context.read<AppState>();
    await appState.downloadOnlineAmbientSource(option);
    await _activateSource('downloaded_${option.id}');
    if (!mounted) {
      return;
    }
    setState(() => _downloadingId = null);
  }

  Future<void> _activateSource(String sourceId) async {
    final appState = context.read<AppState>();
    await appState.setAmbientEnabled(true);
    for (final source in appState.ambientSources) {
      final shouldDisable = source.id != sourceId &&
          (source.categoryKey?.contains('Noise') == true ||
              source.categoryKey?.contains('Rain') == true ||
              source.categoryKey?.contains('Nature') == true);
      if (shouldDisable && source.enabled) {
        await appState.setAmbientSourceEnabled(source.id, false);
      }
    }
    await appState.setAmbientSourceEnabled(sourceId, true);
    final state = appState.sleepDashboardState.copyWith(
      preferredWhiteNoiseId: sourceId,
    );
    appState.updateSleepDashboardState(state);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final i18n = AppI18n(appState.uiLanguage);
    final downloadedSources = appState.ambientSources
        .where(
          (item) =>
              item.categoryKey?.contains('Noise') == true ||
              item.categoryKey?.contains('Rain') == true,
        )
        .toList(growable: false);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: <Widget>[
          Text(
            pickSleepText(i18n, zh: '环境白噪音', en: 'Ambient white noise'),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            pickSleepText(
              i18n,
              zh: '它更适合遮蔽不稳定噪声，不必把它当成人人必需的助眠剂。',
              en: 'Use it to mask unstable noise. It does not need to be a mandatory sleep aid.',
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(pickSleepText(i18n, zh: '启用环境音', en: 'Enable ambient audio')),
            subtitle: Text(pickSleepText(i18n, zh: '全局开关', en: 'Master switch')),
            value: appState.ambientEnabled,
            onChanged: (value) => appState.setAmbientEnabled(value),
          ),
          const SizedBox(height: 12),
          if (downloadedSources.isNotEmpty) ...<Widget>[
            Text(
              pickSleepText(i18n, zh: '我的可用声音', en: 'My available sounds'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            ...downloadedSources.map(
              (source) => _AmbientSourceRow(
                source: source,
                i18n: i18n,
                onEnable: (enabled) async {
                  if (enabled) {
                    await _activateSource(source.id);
                  } else {
                    await appState.setAmbientSourceEnabled(source.id, false);
                  }
                },
                onVolume: (value) => appState.setAmbientSourceVolume(
                  source.id,
                  value,
                ),
              ),
            ),
            const SizedBox(height: 18),
          ],
          Text(
            pickSleepText(i18n, zh: '在线白噪音库', en: 'Online ambient catalog'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          FutureBuilder<List<OnlineAmbientSoundOption>>(
            future: _catalogFuture,
            builder: (context, snapshot) {
              final options = snapshot.data ?? const <OnlineAmbientSoundOption>[];
              if (snapshot.connectionState == ConnectionState.waiting &&
                  options.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return Column(
                children: options
                    .map(
                      (option) => _OnlineAmbientOptionRow(
                        option: option,
                        ambientSources: appState.ambientSources,
                        downloading: _downloadingId == option.id,
                        i18n: i18n,
                        onDownload: () => _downloadOption(option),
                        onActivate: (sourceId) => _activateSource(sourceId),
                      ),
                    )
                    .toList(growable: false),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AmbientSourceRow extends StatelessWidget {
  const _AmbientSourceRow({
    required this.source,
    required this.i18n,
    required this.onEnable,
    required this.onVolume,
  });

  final AmbientSource source;
  final AppI18n i18n;
  final ValueChanged<bool> onEnable;
  final ValueChanged<double> onVolume;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(source.name),
              subtitle: Text(
                source.enabled
                    ? pickSleepText(i18n, zh: '正在可用', en: 'Available now')
                    : pickSleepText(i18n, zh: '未启用', en: 'Disabled'),
              ),
              value: source.enabled,
              onChanged: onEnable,
            ),
            Text(
              pickSleepText(i18n, zh: '音量 ${source.volume.toStringAsFixed(2)}', en: 'Volume ${source.volume.toStringAsFixed(2)}'),
            ),
            Slider(
              value: source.volume.clamp(0.0, 1.0),
              onChanged: onVolume,
            ),
          ],
        ),
      ),
    );
  }
}

class _OnlineAmbientOptionRow extends StatelessWidget {
  const _OnlineAmbientOptionRow({
    required this.option,
    required this.ambientSources,
    required this.downloading,
    required this.i18n,
    required this.onDownload,
    required this.onActivate,
  });

  final OnlineAmbientSoundOption option;
  final List<AmbientSource> ambientSources;
  final bool downloading;
  final AppI18n i18n;
  final VoidCallback onDownload;
  final ValueChanged<String> onActivate;

  @override
  Widget build(BuildContext context) {
    final sourceId = 'downloaded_${option.id}';
    final existing = ambientSources.where((item) => item.id == sourceId).firstOrNull;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(option.name),
        subtitle: Text(
          existing == null
              ? pickSleepText(i18n, zh: '未下载', en: 'Not downloaded')
              : pickSleepText(i18n, zh: '已下载，可直接启用', en: 'Downloaded and ready'),
        ),
        trailing: existing == null
            ? FilledButton.tonal(
                onPressed: downloading ? null : onDownload,
                child: Text(
                  downloading
                      ? pickSleepText(i18n, zh: '下载中', en: 'Downloading')
                      : pickSleepText(i18n, zh: '下载', en: 'Download'),
                ),
              )
            : FilledButton.tonal(
                onPressed: () => onActivate(existing.id),
                child: Text(
                  existing.enabled
                      ? pickSleepText(i18n, zh: '已启用', en: 'Active')
                      : pickSleepText(i18n, zh: '启用', en: 'Use'),
                ),
              ),
      ),
    );
  }
}

class _CaffeineCutoffSheet extends StatefulWidget {
  const _CaffeineCutoffSheet({this.initialBedtime});

  final TimeOfDay? initialBedtime;

  @override
  State<_CaffeineCutoffSheet> createState() => _CaffeineCutoffSheetState();
}

class _CaffeineCutoffSheetState extends State<_CaffeineCutoffSheet> {
  late TimeOfDay _bedtime;
  bool _sensitive = false;

  @override
  void initState() {
    super.initState();
    _bedtime = widget.initialBedtime ?? const TimeOfDay(hour: 23, minute: 0);
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(context.watch<AppState>().uiLanguage);
    final cutoffHours = _sensitive ? 10 : 8;
    final cutoff = _subtractHours(_bedtime, cutoffHours);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              pickSleepText(i18n, zh: '咖啡因截止线', en: 'Caffeine cutoff'),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(pickSleepText(i18n, zh: '计划上床时间', en: 'Planned bedtime')),
              subtitle: Text(sleepTimeOfDayLabel(_bedtime)),
              trailing: const Icon(Icons.schedule_rounded),
              onTap: () async {
                final picked = await showTimePicker(context: context, initialTime: _bedtime);
                if (picked != null) {
                  setState(() => _bedtime = picked);
                }
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(pickSleepText(i18n, zh: '我对咖啡因较敏感', en: 'I am caffeine sensitive')),
              value: _sensitive,
              onChanged: (value) => setState(() => _sensitive = value),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  pickSleepText(
                    i18n,
                    zh: '建议最后一杯含咖啡因饮品不晚于 ${sleepTimeOfDayLabel(cutoff)}。',
                    en: 'Suggested latest caffeine time: ${sleepTimeOfDayLabel(cutoff)}.',
                  ),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TimeOfDay _subtractHours(TimeOfDay input, int hours) {
    final totalMinutes = input.hour * 60 + input.minute - hours * 60;
    final normalized = (totalMinutes % (24 * 60) + 24 * 60) % (24 * 60);
    return TimeOfDay(hour: normalized ~/ 60, minute: normalized % 60);
  }
}

class _MorningLightTimerSheet extends StatefulWidget {
  const _MorningLightTimerSheet();

  @override
  State<_MorningLightTimerSheet> createState() => _MorningLightTimerSheetState();
}

class _MorningLightTimerSheetState extends State<_MorningLightTimerSheet> {
  Timer? _timer;
  int _targetMinutes = 15;
  int _remainingSeconds = 15 * 60;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(context.watch<AppState>().uiLanguage);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              pickSleepText(i18n, zh: '晨光计时器', en: 'Morning light timer'),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(pickSleepText(i18n, zh: '起床后尽快见光，先从一个短而稳的时长开始。', en: 'Get light soon after waking and start with a short consistent duration.')),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              children: <int>[10, 15, 20, 30]
                  .map(
                    (minutes) => ChoiceChip(
                      label: Text('${minutes}m'),
                      selected: _targetMinutes == minutes,
                      onSelected: (_) {
                        setState(() {
                          _targetMinutes = minutes;
                          _remainingSeconds = minutes * 60;
                          _timer?.cancel();
                          _timer = null;
                        });
                      },
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 18),
            Center(
              child: Text(
                sleepSecondsLabel(_remainingSeconds, i18n: i18n),
                style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                FilledButton.icon(
                  onPressed: _toggleTimer,
                  icon: Icon(_timer == null ? Icons.play_arrow_rounded : Icons.pause_rounded),
                  label: Text(_timer == null ? pickSleepText(i18n, zh: '开始', en: 'Start') : pickSleepText(i18n, zh: '暂停', en: 'Pause')),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _timer?.cancel();
                      _timer = null;
                      _remainingSeconds = _targetMinutes * 60;
                    });
                  },
                  icon: const Icon(Icons.replay_rounded),
                  label: Text(pickSleepText(i18n, zh: '重置', en: 'Reset')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _toggleTimer() {
    if (_timer != null) {
      setState(() {
        _timer?.cancel();
        _timer = null;
      });
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() {
          _timer = null;
          _remainingSeconds = 0;
        });
        return;
      }
      setState(() => _remainingSeconds -= 1);
    });
    setState(() {});
  }
}

class _SleepinessDecisionSheet extends StatefulWidget {
  const _SleepinessDecisionSheet();

  @override
  State<_SleepinessDecisionSheet> createState() => _SleepinessDecisionSheetState();
}

class _SleepinessDecisionSheetState extends State<_SleepinessDecisionSheet> {
  bool _awakeLong = true;
  bool _sleepy = false;
  bool _mindBusy = false;
  bool _bodyUncomfortable = false;

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(context.watch<AppState>().uiLanguage);
    final recommendation = _buildRecommendation(i18n);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              pickSleepText(i18n, zh: '我该离床吗', en: 'Should I leave bed'),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _awakeLong,
              title: Text(pickSleepText(i18n, zh: '我已经清醒了一会', en: 'I have been awake for a while')),
              onChanged: (value) => setState(() => _awakeLong = value ?? false),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _sleepy,
              title: Text(pickSleepText(i18n, zh: '我现在还是困的', en: 'I still feel sleepy')),
              onChanged: (value) => setState(() => _sleepy = value ?? false),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _mindBusy,
              title: Text(pickSleepText(i18n, zh: '脑子很忙', en: 'My mind is busy')),
              onChanged: (value) => setState(() => _mindBusy = value ?? false),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _bodyUncomfortable,
              title: Text(pickSleepText(i18n, zh: '身体很热/紧/不舒服', en: 'My body feels hot, tense, or uncomfortable')),
              onChanged: (value) => setState(() => _bodyUncomfortable = value ?? false),
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  recommendation,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildRecommendation(AppI18n i18n) {
    if (_bodyUncomfortable) {
      return pickSleepText(i18n, zh: '先处理热、冷、紧绷或不适，再判断要不要离床。', en: 'Fix heat, discomfort, or tension first, then decide whether to leave bed.');
    }
    if (_awakeLong && !_sleepy) {
      return pickSleepText(i18n, zh: '更像是已经完全清醒。先离床做低刺激活动，等困意回来再回床。', en: 'This looks more like full wakefulness. Leave bed for a low-stimulation activity and return when sleepy.');
    }
    if (_mindBusy) {
      return pickSleepText(i18n, zh: '先不要在床上继续想问题。把念头停放，回到呼吸。', en: 'Do not keep thinking in bed. Park the thought, then return to breathing.');
    }
    return pickSleepText(i18n, zh: '如果你还困，先保持低刺激，不急着做更多事。', en: 'If you are still sleepy, keep things low-stim and avoid doing more.');
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) {
      return null;
    }
    return iterator.current;
  }
}
