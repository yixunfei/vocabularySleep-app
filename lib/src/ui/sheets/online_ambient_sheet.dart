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
  String? _playingId;
  String? _downloadingId;
  late Future<List<OnlineAmbientSoundOption>> _catalogFuture;

  @override
  void initState() {
    super.initState();
    _catalogFuture = context.read<AppState>().fetchOnlineAmbientCatalog();
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
                            zh: '在线白噪音',
                            en: 'Online ambient sounds',
                          ),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          pickUiText(
                            i18n,
                            zh: '优先从 Moodist 站点解析和连接，失败后再回退 GitHub 音源。',
                            en: 'Prefer live parsing and playback from Moodist, with GitHub as fallback.',
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
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  ...entry.value.map(
                                    (option) => Card(
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
                                                    option.name,
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
                                            FilledButton.tonal(
                                              onPressed:
                                                  _playingId == option.id ||
                                                      _downloadingId ==
                                                          option.id
                                                  ? null
                                                  : () async {
                                                      setState(() {
                                                        _playingId = option.id;
                                                      });
                                                      await state
                                                          .addOnlineAmbientSource(
                                                            option,
                                                          );
                                                      if (!mounted ||
                                                          !context.mounted) {
                                                        return;
                                                      }
                                                      setState(() {
                                                        _playingId = null;
                                                      });
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            pickUiText(
                                                              i18n,
                                                              zh: '已开始在线播放：${option.name}',
                                                              en: 'Now streaming: ${option.name}',
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    },
                                              child: Text(
                                                _playingId == option.id
                                                    ? pickUiText(
                                                        i18n,
                                                        zh: '连接中',
                                                        en: 'Connecting',
                                                      )
                                                    : pickUiText(
                                                        i18n,
                                                        zh: '在线播放',
                                                        en: 'Play online',
                                                      ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            FilledButton(
                                              onPressed:
                                                  _playingId == option.id ||
                                                      _downloadingId ==
                                                          option.id
                                                  ? null
                                                  : () async {
                                                      setState(() {
                                                        _downloadingId =
                                                            option.id;
                                                      });
                                                      final path = await state
                                                          .downloadOnlineAmbientSource(
                                                            option,
                                                          );
                                                      if (!mounted ||
                                                          !context.mounted) {
                                                        return;
                                                      }
                                                      setState(() {
                                                        _downloadingId = null;
                                                      });
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
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
                                                                    zh: '已下载到本地：${option.name}',
                                                                    en: 'Downloaded locally: ${option.name}',
                                                                  ),
                                                          ),
                                                        ),
                                                      );
                                                    },
                                              child: Text(
                                                _downloadingId == option.id
                                                    ? pickUiText(
                                                        i18n,
                                                        zh: '下载中',
                                                        en: 'Downloading',
                                                      )
                                                    : pickUiText(
                                                        i18n,
                                                        zh: '下载本地',
                                                        en: 'Download',
                                                      ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
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
