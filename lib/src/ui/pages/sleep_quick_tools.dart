import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../i18n/app_i18n.dart';
import '../../services/ambient_service.dart';
import '../../services/app_log_service.dart';
import '../../services/online_ambient_catalog_service.dart';
import '../../state/app_state_provider.dart';
import '../sheets/ambient_sheet.dart';
import '../ui_copy.dart';
import 'sleep_assistant_ui_support.dart';

part 'sleep_quick_tools_sheets.dart';

Future<void> showSleepWhiteNoiseSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => Consumer(
      builder: (context, ref, _) {
        final appState = ref.watch(appStateProvider);
        return _SleepQuickToolTheme(
          child: AmbientSheet(
            state: appState,
            i18n: AppI18n(appState.uiLanguage),
          ),
        );
      },
    ),
  );
}

Future<void> showCaffeineCutoffCalculatorSheet(
  BuildContext context, {
  TimeOfDay? bedtime,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => _SleepQuickToolTheme(
      child: _CaffeineCutoffSheet(initialBedtime: bedtime),
    ),
  );
}

Future<void> showMorningLightTimerSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) =>
        const _SleepQuickToolTheme(child: _MorningLightTimerSheet()),
  );
}

Future<void> showSleepCyclePlannerSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) =>
        const _SleepQuickToolTheme(child: _SleepCyclePlannerSheet()),
  );
}

Future<void> showSleepinessDecisionSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) =>
        const _SleepQuickToolTheme(child: _SleepinessDecisionSheet()),
  );
}

class _SleepQuickToolTheme extends ConsumerWidget {
  const _SleepQuickToolTheme({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    return sleepModuleTheme(
      context: context,
      enabled: appState.sleepDashboardState.sleepDarkModeEnabled,
      child: child,
    );
  }
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

  void _reloadCatalog() {
    setState(() {
      _catalogFuture = ref.read(appStateProvider).fetchOnlineAmbientCatalog();
    });
  }

  Future<void> _downloadOption(OnlineAmbientSoundOption option) async {
    setState(() => _downloadingId = option.id);
    final appState = ref.read(appStateProvider);
    // [风险] 下载或激活任一环节失败都必须复位 _downloadingId，
    // 否则按钮会永久停留在 loading 态，用户只能重开页面。
    try {
      await appState.downloadOnlineAmbientSource(option);
      await _activateSource('downloaded_${option.id}');
    } catch (error, stackTrace) {
      AppLogService.instance.e(
        'SleepQuickTools',
        'Ambient source download failed: ${option.id}',
        error: error,
        stackTrace: stackTrace,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppI18n(
                appState.uiLanguage,
              ).t('toolbox.sleep.tools.downloadFailed'),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _downloadingId = null);
      }
    }
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
            i18n.t('toolbox.sleep.tools.ambientNoise'),
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(i18n.t('toolbox.sleep.tools.ambientNoiseHint')),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(i18n.t('toolbox.sleep.tools.enableAmbient')),
            subtitle: Text(i18n.t('toolbox.sleep.tools.masterSwitch')),
            value: appState.ambientEnabled,
            onChanged: (value) => appState.setAmbientEnabled(value),
          ),
          const SizedBox(height: 12),
          if (downloadedSources.isNotEmpty) ...<Widget>[
            Text(
              i18n.t('toolbox.sleep.tools.mySounds'),
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
            i18n.t('toolbox.sleep.tools.onlineCatalog'),
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
              // 加载失败必须给出独立可读的错误态和重试入口；
              // 加载成功但为空时也用独立空态，避免渲染成"空白区块"。
              if (snapshot.hasError) {
                return _AmbientCatalogStatus(
                  message: i18n.t('toolbox.sleep.tools.onlineCatalogError'),
                  actionLabel: i18n.t('app.bootstrap.retry'),
                  onAction: _reloadCatalog,
                );
              }
              if (!snapshot.hasData || options.isEmpty) {
                return _AmbientCatalogStatus(
                  message: i18n.t('toolbox.sleep.tools.onlineCatalogEmpty'),
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

class _AmbientCatalogStatus extends StatelessWidget {
  const _AmbientCatalogStatus({
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: <Widget>[
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (actionLabel != null && onAction != null) ...<Widget>[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(actionLabel!),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(112, 48),
                textStyle: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
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
              title: Text(localizedAmbientName(i18n, source)),
              subtitle: Text(
                source.enabled
                    ? i18n.t('toolbox.sleep.tools.available')
                    : i18n.t('toolbox.sleep.tools.disabled'),
              ),
              value: source.enabled,
              onChanged: onEnable,
            ),
            Text(
              i18n.t(
                'toolbox.sleep.tools.volume',
                params: {'pct': (source.volume * 100).round()},
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
        title: Text(localizedOnlineAmbientOptionName(i18n, option)),
        subtitle: Text(
          existing == null
              ? i18n.t('toolbox.sleep.tools.notDownloaded')
              : i18n.t('toolbox.sleep.tools.downloadedReady'),
        ),
        trailing: existing == null
            ? FilledButton.tonal(
                onPressed: downloading ? null : onDownload,
                child: Text(
                  downloading
                      ? i18n.t('toolbox.sleep.tools.downloading')
                      : i18n.t('toolbox.sleep.tools.download'),
                ),
              )
            : FilledButton.tonal(
                onPressed: () => onActivate(existing.id),
                child: Text(
                  existing.enabled
                      ? i18n.t('toolbox.sleep.tools.enabled')
                      : i18n.t('toolbox.sleep.tools.use'),
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
