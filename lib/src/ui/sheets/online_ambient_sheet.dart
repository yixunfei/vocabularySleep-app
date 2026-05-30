import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../i18n/app_i18n.dart';
import '../../services/online_ambient_catalog_service.dart';
import '../../state/app_state.dart';
import '../../state/app_state_provider.dart';
import '../ui_copy.dart';

Future<void> showOnlineAmbientCatalogSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const FractionallySizedBox(
      heightFactor: 0.92,
      child: _OnlineAmbientCatalogSheet(),
    ),
  );
}

class _OnlineAmbientCatalogSheet extends ConsumerStatefulWidget {
  const _OnlineAmbientCatalogSheet();

  @override
  ConsumerState<_OnlineAmbientCatalogSheet> createState() =>
      _OnlineAmbientCatalogSheetState();
}

class _OnlineAmbientCatalogSheetState
    extends ConsumerState<_OnlineAmbientCatalogSheet> {
  late Future<List<OnlineAmbientSoundOption>> _catalogFuture;
  Set<String> _downloadedPaths = <String>{};
  final Map<String, double?> _downloadProgressById = <String, double?>{};
  final Set<String> _downloadingIds = <String>{};
  final Set<String> _deletingIds = <String>{};

  @override
  void initState() {
    super.initState();
    final state = ref.read(appStateProvider);
    _catalogFuture = state.fetchOnlineAmbientCatalog();
    _refreshDownloadedPaths();
  }

  Future<void> _refreshDownloadedPaths() async {
    final state = ref.read(appStateProvider);
    final paths = await state.fetchDownloadedOnlineAmbientRelativePaths();
    if (!mounted) {
      return;
    }
    setState(() {
      _downloadedPaths = paths;
    });
  }

  Future<void> _handleDownload(
    AppState state,
    AppI18n i18n,
    OnlineAmbientSoundOption option,
    String localizedName,
  ) async {
    if (_downloadingIds.contains(option.id)) {
      return;
    }
    setState(() {
      _downloadingIds.add(option.id);
      _downloadProgressById[option.id] = null;
    });

    try {
      final path = await state.downloadOnlineAmbientSourceWithProgress(option, (
        progress,
      ) {
        if (!mounted) {
          return;
        }
        setState(() {
          _downloadProgressById[option.id] = progress.progress;
        });
      });
      await _refreshDownloadedPaths();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            path == null
                ? i18n.t(
                    'inline.ui.sheets.online_ambient_sheet.download_failed_please_try_again_later_85b773',
                  )
                : i18n.t(
                    'inline.ui.sheets.online_ambient_sheet.downloaded_locally_localizedname_07c499',
                  ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _downloadingIds.remove(option.id);
          _downloadProgressById.remove(option.id);
        });
      }
    }
  }

  Future<void> _handleDelete(
    AppState state,
    AppI18n i18n,
    OnlineAmbientSoundOption option,
    String localizedName,
  ) async {
    if (_deletingIds.contains(option.id)) {
      return;
    }
    setState(() {
      _deletingIds.add(option.id);
      _downloadProgressById[option.id] = null;
    });

    try {
      final deleted = await state.deleteDownloadedOnlineAmbientSource(option);
      await _refreshDownloadedPaths();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            deleted
                ? i18n.t(
                    'inline.ui.sheets.online_ambient_sheet.deleted_local_audio_localizedname_7440f2',
                  )
                : i18n.t(
                    'inline.ui.sheets.online_ambient_sheet.delete_failed_please_try_again_later_ad76c3',
                  ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _deletingIds.remove(option.id);
          _downloadProgressById.remove(option.id);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final i18n = AppI18n(state.uiLanguage);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      i18n.t(
                        'inline.ui.sheets.online_ambient_sheet.ambient_sound_catalog_e70c2e',
                      ),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      i18n.t(
                        'inline.ui.sheets.online_ambient_sheet.download_ambient_sounds_from_the_remote_library_and_cach_d33f2b',
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: FutureBuilder<List<OnlineAmbientSoundOption>>(
              future: _catalogFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                final options =
                    snapshot.data ??
                    OnlineAmbientCatalogService.fallbackOptions;
                final grouped = <String, List<OnlineAmbientSoundOption>>{};
                for (final item in options) {
                  grouped
                      .putIfAbsent(
                        item.categoryKey,
                        () => <OnlineAmbientSoundOption>[],
                      )
                      .add(item);
                }
                return ListView(
                  children: grouped.entries
                      .map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                i18n.t(entry.key),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              ...entry.value.map((option) {
                                final downloaded = _downloadedPaths.contains(
                                  option.relativePath,
                                );
                                final localizedName =
                                    localizedOnlineAmbientOptionName(
                                      i18n,
                                      option,
                                    );
                                final progress =
                                    _downloadProgressById[option.id];
                                final downloading = _downloadingIds.contains(
                                  option.id,
                                );
                                final deleting = _deletingIds.contains(
                                  option.id,
                                );
                                final busy = downloading || deleting;
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: <Widget>[
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: <Widget>[
                                              Text(
                                                localizedName,
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.titleSmall,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                option.relativePath,
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodySmall,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        SizedBox(
                                          width: 118,
                                          child: downloaded
                                              ? OutlinedButton.icon(
                                                  onPressed: busy
                                                      ? null
                                                      : () => _handleDelete(
                                                          state,
                                                          i18n,
                                                          option,
                                                          localizedName,
                                                        ),
                                                  style:
                                                      OutlinedButton.styleFrom(
                                                        foregroundColor:
                                                            Colors.red,
                                                        side: const BorderSide(
                                                          color: Colors.red,
                                                        ),
                                                      ),
                                                  icon: _ProgressIcon(
                                                    progress: progress,
                                                    busy: deleting,
                                                    idleIcon: Icons
                                                        .delete_outline_rounded,
                                                  ),
                                                  label: Text(
                                                    deleting
                                                        ? i18n.t(
                                                            'inline.ui.sheets.online_ambient_sheet.deleting_6581ab',
                                                          )
                                                        : i18n.t('delete'),
                                                  ),
                                                )
                                              : FilledButton.icon(
                                                  onPressed: busy
                                                      ? null
                                                      : () => _handleDownload(
                                                          state,
                                                          i18n,
                                                          option,
                                                          localizedName,
                                                        ),
                                                  icon: _ProgressIcon(
                                                    progress: progress,
                                                    busy: downloading,
                                                    idleIcon:
                                                        Icons.download_rounded,
                                                  ),
                                                  label: Text(
                                                    downloading
                                                        ? i18n.t(
                                                            'inline.ui.sheets.online_ambient_sheet.downloading_ea6865',
                                                          )
                                                        : i18n.t('download'),
                                                  ),
                                                ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        );
                      })
                      .toList(growable: false),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressIcon extends StatelessWidget {
  const _ProgressIcon({
    required this.progress,
    required this.busy,
    required this.idleIcon,
  });

  final double? progress;
  final bool busy;
  final IconData idleIcon;

  @override
  Widget build(BuildContext context) {
    if (!busy) {
      return Icon(idleIcon, size: 18);
    }
    return SizedBox(
      width: 16,
      height: 16,
      child: CircularProgressIndicator(strokeWidth: 2, value: progress),
    );
  }
}
