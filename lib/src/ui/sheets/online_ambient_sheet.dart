import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../i18n/app_i18n.dart';
import '../../services/online_ambient_catalog_service.dart';
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
  String? _pendingId;
  late Future<List<OnlineAmbientSoundOption>> _catalogFuture;
  late Future<Set<String>> _downloadedPathsFuture;

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    _catalogFuture = state.fetchOnlineAmbientCatalog();
    _downloadedPathsFuture = state.fetchDownloadedOnlineAmbientRelativePaths();
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
                            zh: '优先从 Moodist 站点解析资源并下载，本地存在时可直接删除。',
                            en: 'Prefer catalog parsing from Moodist and download locally. Delete when already downloaded.',
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
                  future: Future.wait<Object>(<Future<Object>>[
                    _catalogFuture,
                    _downloadedPathsFuture,
                  ]),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done ||
                        snapshot.data is! List<Object>) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final data = snapshot.data! as List<Object>;
                    final options =
                        data[0] as List<OnlineAmbientSoundOption>? ??
                        OnlineAmbientCatalogService.fallbackOptions;
                    final downloadedPaths =
                        data[1] as Set<String>? ?? <String>{};

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
                                    final downloaded = downloadedPaths.contains(
                                      option.relativePath,
                                    );
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
                                            FilledButton(
                                              onPressed: _pendingId == option.id
                                                  ? null
                                                  : () async {
                                                      setState(() {
                                                        _pendingId = option.id;
                                                      });
                                                      final deleted = downloaded
                                                          ? await state
                                                                .deleteDownloadedOnlineAmbientSource(
                                                                  option,
                                                                )
                                                          : null;
                                                      final path = downloaded
                                                          ? null
                                                          : await state
                                                                .downloadOnlineAmbientSource(
                                                                  option,
                                                                );
                                                      if (!mounted ||
                                                          !context.mounted) {
                                                        return;
                                                      }
                                                      setState(() {
                                                        _pendingId = null;
                                                        _downloadedPathsFuture =
                                                            state
                                                                .fetchDownloadedOnlineAmbientRelativePaths();
                                                      });
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            downloaded
                                                                ? (deleted ==
                                                                          true
                                                                      ? pickUiText(
                                                                          i18n,
                                                                          zh: '已删除本地音频：$localizedName',
                                                                          en: 'Deleted local audio: $localizedName',
                                                                        )
                                                                      : pickUiText(
                                                                          i18n,
                                                                          zh: '删除失败，请稍后重试。',
                                                                          en: 'Delete failed. Please try again later.',
                                                                        ))
                                                                : (path == null
                                                                      ? pickUiText(
                                                                          i18n,
                                                                          zh: '下载失败，请稍后重试。',
                                                                          en: 'Download failed. Please try again later.',
                                                                        )
                                                                      : pickUiText(
                                                                          i18n,
                                                                          zh: '已下载到本地：$localizedName',
                                                                          en: 'Downloaded locally: $localizedName',
                                                                        )),
                                                          ),
                                                        ),
                                                      );
                                                    },
                                              child: Text(
                                                _pendingId == option.id
                                                    ? pickUiText(
                                                        i18n,
                                                        zh: downloaded
                                                            ? '删除中'
                                                            : '下载中',
                                                        en: downloaded
                                                            ? 'Deleting'
                                                            : 'Downloading',
                                                      )
                                                    : pickUiText(
                                                        i18n,
                                                        zh: downloaded
                                                            ? '删除白噪音'
                                                            : '下载白噪音',
                                                        en: downloaded
                                                            ? 'Delete'
                                                            : 'Download',
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
      },
    );
  }
}
