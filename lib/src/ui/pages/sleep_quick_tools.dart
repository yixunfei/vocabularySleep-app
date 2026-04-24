import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../i18n/app_i18n.dart';
import '../../services/ambient_service.dart';
import '../../services/online_ambient_catalog_service.dart';
import '../../state/app_state_provider.dart';
import 'sleep_assistant_ui_support.dart';

part 'sleep_quick_tools_sheets.dart';

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

Future<void> showSleepCyclePlannerSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _SleepCyclePlannerSheet(),
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

class _SleepWhiteNoiseSheet extends ConsumerStatefulWidget {
  const _SleepWhiteNoiseSheet();

  @override
  ConsumerState<_SleepWhiteNoiseSheet> createState() =>
      _SleepWhiteNoiseSheetState();
}

class _SleepWhiteNoiseSheetState extends ConsumerState<_SleepWhiteNoiseSheet> {
  late Future<List<OnlineAmbientSoundOption>> _catalogFuture;
  String? _downloadingId;

  @override
  void initState() {
    super.initState();
    _catalogFuture = ref.read(appStateProvider).fetchOnlineAmbientCatalog();
  }

  Future<void> _downloadOption(OnlineAmbientSoundOption option) async {
    setState(() => _downloadingId = option.id);
    final appState = ref.read(appStateProvider);
    await appState.downloadOnlineAmbientSource(option);
    await _activateSource('downloaded_${option.id}');
    if (!mounted) {
      return;
    }
    setState(() => _downloadingId = null);
  }

  Future<void> _activateSource(String sourceId) async {
    final appState = ref.read(appStateProvider);
    await appState.setAmbientEnabled(true);
    for (final source in appState.ambientSources) {
      final shouldDisable =
          source.id != sourceId &&
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
    final appState = ref.watch(appStateProvider);
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
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
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
            title: Text(
              pickSleepText(i18n, zh: '启用环境音', en: 'Enable ambient audio'),
            ),
            subtitle: Text(
              pickSleepText(i18n, zh: '全局开关', en: 'Master switch'),
            ),
            value: appState.ambientEnabled,
            onChanged: (value) => appState.setAmbientEnabled(value),
          ),
          const SizedBox(height: 12),
          if (downloadedSources.isNotEmpty) ...<Widget>[
            Text(
              pickSleepText(i18n, zh: '我的可用声音', en: 'My available sounds'),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
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
                onVolume: (value) =>
                    appState.setAmbientSourceVolume(source.id, value),
              ),
            ),
            const SizedBox(height: 18),
          ],
          Text(
            pickSleepText(i18n, zh: '在线白噪音库', en: 'Online ambient catalog'),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          FutureBuilder<List<OnlineAmbientSoundOption>>(
            future: _catalogFuture,
            builder: (context, snapshot) {
              final options =
                  snapshot.data ?? const <OnlineAmbientSoundOption>[];
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
              pickSleepText(
                i18n,
                zh: '音量 ${source.volume.toStringAsFixed(2)}',
                en: 'Volume ${source.volume.toStringAsFixed(2)}',
              ),
            ),
            Slider(value: source.volume.clamp(0.0, 1.0), onChanged: onVolume),
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
    final existing = ambientSources
        .where((item) => item.id == sourceId)
        .firstOrNull;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(option.name),
        subtitle: Text(
          existing == null
              ? pickSleepText(i18n, zh: '未下载', en: 'Not downloaded')
              : pickSleepText(
                  i18n,
                  zh: '已下载，可直接启用',
                  en: 'Downloaded and ready',
                ),
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

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) {
      return null;
    }
    return iterator.current;
  }
}
