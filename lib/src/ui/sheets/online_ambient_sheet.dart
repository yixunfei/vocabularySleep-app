import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../i18n/app_i18n.dart';
import '../../services/online_ambient_catalog_service.dart';
import '../../services/cstcloud_resource_cache_service.dart';
import '../../state/app_state.dart';
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

class _OnlineAmbientCatalogSheet extends StatefulWidget {
  const _OnlineAmbientCatalogSheet();

  @override
  State<_OnlineAmbientCatalogSheet> createState() =>
      _OnlineAmbientCatalogSheetState();
}

class _OnlineAmbientCatalogSheetState
    extends State<_OnlineAmbientCatalogSheet> {
  late Future<List<OnlineAmbientSoundOption>> _catalogFuture;
  late Future<Set<String>> _downloadedPathsFuture;
  Set<String> _downloadedPaths = <String>{};

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    _catalogFuture = state.fetchOnlineAmbientCatalog();
    _downloadedPathsFuture = state.fetchDownloadedOnlineAmbientRelativePaths();
    _downloadedPathsFuture.then((paths) {
      if (mounted) {
        setState(() {
          _downloadedPaths = paths;
        });
      }
    });
  }

  void _refreshDownloadedPaths() {
    final state = context.read<AppState>();
    state.fetchDownloadedOnlineAmbientRelativePaths().then((paths) {
      if (mounted) {
        setState(() {
          _downloadedPaths = paths;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
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
                          pickUiText(
                            i18n,
                            zh: '白噪音资源',
                            en: 'Ambient sound catalog',
                          ),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          pickUiText(
                            i18n,
                            zh: '从远程资源库下载并缓存环境音，已缓存的音频可直接删除。',
                            en: 'Browse ambient sounds from the remote library and cache them locally. Delete any cached file directly.',
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
                child: FutureBuilder<Object>(
                  future: Future.wait<Object>(<Future<Object>>[_catalogFuture]),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done ||
                        snapshot.data is! List<Object>) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final data = snapshot.data! as List<Object>;
                    final options =
                        data[0] as List<OnlineAmbientSoundOption>? ??
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
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  ...entry.value.map((option) {
                                    final downloaded = _downloadedPaths
                                        .contains(option.relativePath);
                                    final localizedName =
                                        localizedOnlineAmbientOptionName(
                                          i18n,
                                          option,
                                        );

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
                                            AmbientActionBuilder(
                                              option: option,
                                              downloaded: downloaded,
                                              localizedName: localizedName,
                                              onActionComplete: () {
                                                _refreshDownloadedPaths();
                                              },
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
      },
    );
  }
}

class AmbientActionBuilder extends StatefulWidget {
  const AmbientActionBuilder({
    super.key,
    required this.option,
    required this.downloaded,
    required this.localizedName,
    required this.onActionComplete,
  });

  final OnlineAmbientSoundOption option;
  final bool downloaded;
  final String localizedName;
  final VoidCallback onActionComplete;

  @override
  State<AmbientActionBuilder> createState() => _AmbientActionBuilderState();
}

class _AmbientActionBuilderState extends State<AmbientActionBuilder> {
  bool _isPending = false;
  double? _progress;
  bool _isDownloading = false;

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(context.read<AppState>().uiLanguage);
    final buttonWidth = 100.0;

    return SizedBox(width: buttonWidth, child: _buildButton(context, i18n));
  }

  Widget _buildButton(BuildContext context, AppI18n i18n) {
    if (widget.downloaded) {
      return _buildDeleteButton(context, i18n);
    } else {
      return _buildDownloadButton(context, i18n);
    }
  }

  Widget _buildDeleteButton(BuildContext context, AppI18n i18n) {
    final isDeleting = _isPending && _isDownloading;
    final progress = isDeleting ? _progress : null;

    return OutlinedButton.icon(
      icon: progress != null
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, value: progress),
            )
          : const Icon(Icons.delete_outline_rounded, size: 18),
      label: Text(
        isDeleting
            ? pickUiText(i18n, zh: '删除中', en: 'Deleting')
            : pickUiText(i18n, zh: '删除', en: 'Delete'),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.red,
        side: const BorderSide(color: Colors.red),
      ),
      onPressed: isDeleting ? null : _handleDelete,
    );
  }

  Widget _buildDownloadButton(BuildContext context, AppI18n i18n) {
    final isDownloadingNow = _isPending && _isDownloading;
    final progress = isDownloadingNow ? _progress : null;

    return FilledButton.icon(
      icon: progress != null
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, value: progress),
            )
          : const Icon(Icons.download_rounded, size: 18),
      label: Text(
        isDownloadingNow
            ? pickUiText(i18n, zh: '下载中', en: 'Downloading')
            : pickUiText(i18n, zh: '下载', en: 'Download'),
      ),
      onPressed: isDownloadingNow ? null : _handleDownload,
    );
  }

  Future<void> _handleDelete() async {
    if (!mounted) return;
    setState(() {
      _isPending = true;
      _isDownloading = true;
      _progress = 0.1;
    });

    try {
      final state = context.read<AppState>();
      final i18n = AppI18n(state.uiLanguage);
      final deleted = await state.deleteDownloadedOnlineAmbientSource(
        widget.option,
      );

      if (!mounted) return;

      widget.onActionComplete();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              deleted
                  ? pickUiText(
                      i18n,
                      zh: '已删除本地音频：${widget.localizedName}',
                      en: 'Deleted local audio: ${widget.localizedName}',
                    )
                  : pickUiText(
                      i18n,
                      zh: '删除失败，请稍后重试。',
                      en: 'Delete failed. Please try again later.',
                    ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPending = false;
          _isDownloading = false;
          _progress = null;
        });
      }
    }
  }

  Future<void> _handleDownload() async {
    if (!mounted) return;
    setState(() {
      _isPending = true;
      _isDownloading = true;
      _progress = 0.1;
    });

    try {
      final state = context.read<AppState>();
      final i18n = AppI18n(state.uiLanguage);
      final path = await state.downloadOnlineAmbientSourceWithProgress(
        widget.option,
        (progress) {
          if (mounted) {
            setState(() {
              _progress = progress.progress;
            });
          }
        },
      );

      if (!mounted) return;

      widget.onActionComplete();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              path == null
                  ? pickUiText(
                      i18n,
                      zh: '下载失败，请稍后重试。',
                      en: 'Download failed. Please try again later.',
                    )
                  : pickUiText(
                      i18n,
                      zh: '已下载到本地：${widget.localizedName}',
                      en: 'Downloaded locally: ${widget.localizedName}',
                    ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPending = false;
          _isDownloading = false;
          _progress = null;
        });
      }
    }
  }
}
