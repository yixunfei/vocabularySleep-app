part of '../toolbox_life_tools.dart';

enum _WallpaperSourceKind { bing }

enum _WallpaperTarget { home, lock, both }

enum _WallpaperFitMode { any, screen }

enum _WallpaperSourceErrorKind {
  timeout,
  forbidden,
  protected,
  http,
  network,
  parse,
  other,
}

const Duration _wallpaperFastTimeout = Duration(seconds: 12);
const Duration _wallpaperImageTimeout = Duration(seconds: 30);
const String _wallpaperDesktopUserAgent =
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
    '(KHTML, like Gecko) Chrome/125.0 Safari/537.36';

final AppLogService _wallpaperLog = AppLogService.instance;

class _WallpaperSource {
  const _WallpaperSource({
    required this.id,
    required this.name,
    required this.kind,
    required this.homeUrl,
    required this.summaryKey,
  });

  final String id;
  final String name;
  final _WallpaperSourceKind kind;
  final String homeUrl;
  final String summaryKey;
}

class _WallpaperItem {
  const _WallpaperItem({
    required this.id,
    required this.title,
    required this.sourceName,
    required this.sourceUrl,
    required this.previewUrl,
    required this.imageUrl,
    required this.width,
    required this.height,
    this.author,
    this.attribution,
    this.fileType,
  });

  final String id;
  final String title;
  final String sourceName;
  final String sourceUrl;
  final String previewUrl;
  final String imageUrl;
  final int width;
  final int height;
  final String? author;
  final String? attribution;
  final String? fileType;

  String get resolution => width > 0 && height > 0 ? '${width}x$height' : 'N/A';

  String get extension {
    final fromUrl = Uri.tryParse(imageUrl)?.pathSegments.last.split('.').last;
    final clean = fromUrl?.split('?').first.toLowerCase();
    if (clean == 'jpg' ||
        clean == 'jpeg' ||
        clean == 'png' ||
        clean == 'webp' ||
        clean == 'avif') {
      return clean == 'jpeg' ? 'jpg' : clean!;
    }
    if (fileType?.contains('png') == true) {
      return 'png';
    }
    if (fileType?.contains('webp') == true) {
      return 'webp';
    }
    if (fileType?.contains('avif') == true) {
      return 'avif';
    }
    return 'jpg';
  }

  bool matchesQuery(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      return true;
    }
    final haystack = <String>[
      title,
      sourceName,
      author ?? '',
      attribution ?? '',
      resolution,
    ].join(' ').toLowerCase();
    return haystack.contains(q);
  }

  bool matchesScreen(Size screenSize) {
    if (width <= 0 || height <= 0) {
      return true;
    }
    final deviceRatio = screenSize.shortestSide / screenSize.longestSide;
    final itemRatio = math.min(width, height) / math.max(width, height);
    final longSide = math.max(width, height).toDouble();
    final requiredLongSide = screenSize.longestSide * 1.6;
    return (itemRatio - deviceRatio).abs() <= 0.22 &&
        longSide >= requiredLongSide;
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'title': title,
    'sourceName': sourceName,
    'sourceUrl': sourceUrl,
    'previewUrl': previewUrl,
    'imageUrl': imageUrl,
    'width': width,
    'height': height,
    if (author != null) 'author': author,
    if (attribution != null) 'attribution': attribution,
    if (fileType != null) 'fileType': fileType,
  };

  static _WallpaperItem? fromJson(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    final map = Map<String, Object?>.from(raw);
    final imageUrl = map['imageUrl']?.toString() ?? '';
    final previewUrl = map['previewUrl']?.toString() ?? imageUrl;
    if (imageUrl.isEmpty || previewUrl.isEmpty) {
      return null;
    }
    return _WallpaperItem(
      id: map['id']?.toString() ?? imageUrl,
      title: map['title']?.toString() ?? 'Wallpaper',
      sourceName: map['sourceName']?.toString() ?? 'Unknown',
      sourceUrl: map['sourceUrl']?.toString() ?? imageUrl,
      previewUrl: previewUrl,
      imageUrl: imageUrl,
      width: (map['width'] as num?)?.toInt() ?? 0,
      height: (map['height'] as num?)?.toInt() ?? 0,
      author: map['author']?.toString(),
      attribution: map['attribution']?.toString(),
      fileType: map['fileType']?.toString(),
    );
  }
}

class _WallpaperLoadResult {
  const _WallpaperLoadResult({
    required this.items,
    required this.errors,
    this.usedCache = false,
  });

  final List<_WallpaperItem> items;
  final List<_WallpaperSourceError> errors;
  final bool usedCache;
}

class _WallpaperSourceError {
  const _WallpaperSourceError({
    required this.sourceName,
    required this.kind,
    this.statusCode,
    this.usedCache = false,
  });

  final String sourceName;
  final _WallpaperSourceErrorKind kind;
  final int? statusCode;
  final bool usedCache;

  static _WallpaperSourceError fromError({
    required _WallpaperSource source,
    required Object error,
    required bool usedCache,
  }) {
    final message = error.toString();
    final httpMatch = RegExp(r'HTTP\s+(\d+)').firstMatch(message);
    final statusCode = error is _WallpaperHttpException
        ? error.statusCode
        : httpMatch == null
        ? null
        : int.tryParse(httpMatch.group(1) ?? '');
    return _WallpaperSourceError(
      sourceName: source.name,
      statusCode: statusCode,
      usedCache: usedCache,
      kind: switch (error) {
        TimeoutException() => _WallpaperSourceErrorKind.timeout,
        SocketException() => _WallpaperSourceErrorKind.network,
        FormatException() => _WallpaperSourceErrorKind.parse,
        _WallpaperHttpException(isProtected: true) =>
          _WallpaperSourceErrorKind.protected,
        _ when statusCode == 403 => _WallpaperSourceErrorKind.forbidden,
        _ when statusCode != null => _WallpaperSourceErrorKind.http,
        _ => _WallpaperSourceErrorKind.other,
      },
    );
  }
}

class _WallpaperSaveResult {
  const _WallpaperSaveResult({required this.path, required this.bytes});

  final String path;
  final Uint8List bytes;
}

class _WallpaperHttpException implements Exception {
  const _WallpaperHttpException({
    required this.statusCode,
    required this.uri,
    this.contentType,
    this.isProtected = false,
  });

  final int statusCode;
  final Uri uri;
  final String? contentType;
  final bool isProtected;

  @override
  String toString() {
    final type = contentType == null || contentType!.isEmpty
        ? ''
        : ' $contentType';
    final protected = isProtected ? ' protected' : '';
    return 'HTTP $statusCode$protected$type (${uri.host})';
  }
}

class _WallpaperSourceLoadOutcome {
  const _WallpaperSourceLoadOutcome({
    required this.items,
    this.error,
    this.usedCache = false,
  });

  final List<_WallpaperItem> items;
  final _WallpaperSourceError? error;
  final bool usedCache;
}

const List<_WallpaperSource> _wallpaperSources = <_WallpaperSource>[
  _WallpaperSource(
    id: 'bing',
    name: 'Bing Wallpaper',
    kind: _WallpaperSourceKind.bing,
    homeUrl: 'https://www.bing.com',
    summaryKey:
        'inline.plan295.life.daily_homepage_wallpapers_with_origi.90a7340a6511',
  ),
];

class _WallpaperHelperToolPage extends StatefulWidget {
  const _WallpaperHelperToolPage();

  @override
  State<_WallpaperHelperToolPage> createState() =>
      _WallpaperHelperToolPageState();
}

class _WallpaperHelperToolPageState extends State<_WallpaperHelperToolPage> {
  late final TextEditingController _queryController;
  late Future<_WallpaperLoadResult> _loadFuture;
  late Future<_WallpaperCacheStatus> _cacheStatusFuture;

  String _query = '';
  String _sourceId = 'all';
  _WallpaperFitMode _fitMode = _WallpaperFitMode.screen;
  int _refreshNonce = 0;

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController();
    _loadFuture = _loadWallpapers();
    _cacheStatusFuture = _WallpaperCacheStore.instance.status();
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final physicalSize = mediaQuery.size * mediaQuery.devicePixelRatio;
    final logicalSize = mediaQuery.size;
    return ToolboxToolPage(
      title: _lifeI18nText(
        context,
        'inline.plan295.life.wallpaper_helper.bda912c53aec',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.aggregates_public_sources_loads_9_ra.ecb9232bbd34',
      ),
      appBarActions: <Widget>[
        IconButton(
          tooltip: _lifeI18nText(
            context,
            'inline.plan295.life.refresh_random_wallpapers.269a713f442d',
          ),
          onPressed: _reload,
          icon: const Icon(Icons.shuffle_rounded),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildSearchPanel(context, physicalSize),
          const SizedBox(height: 12),
          _buildCachePanel(context),
          const SizedBox(height: 12),
          FutureBuilder<_WallpaperLoadResult>(
            future: _loadFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done &&
                  !snapshot.hasData) {
                return _LifeSettingsPanel(
                  title: _lifeI18nText(
                    context,
                    'inline.plan295.life.loading_wallpapers.54ef9318f9ee',
                  ),
                  subtitle: _lifeI18nText(
                    context,
                    'inline.plan295.life.fetching_random_wallpapers_from_publ.b3bd1040999a',
                  ),
                  children: const <Widget>[LinearProgressIndicator()],
                );
              }

              final result = snapshot.data;
              if (snapshot.hasError && result == null) {
                return _buildErrorPanel(context, '${snapshot.error}');
              }

              final items = _filterItems(
                result?.items ?? const <_WallpaperItem>[],
                logicalSize,
              );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _buildSourceSummary(
                    context,
                    result?.errors ?? const <_WallpaperSourceError>[],
                    usedCache: result?.usedCache ?? false,
                  ),
                  const SizedBox(height: 12),
                  if (items.isEmpty)
                    _buildEmptyPanel(context)
                  else
                    _WallpaperGrid(
                      items: items.take(9).toList(growable: false),
                      onTap: _openPreview,
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          _buildSourceLinks(context),
        ],
      ),
    );
  }

  Widget _buildSearchPanel(BuildContext context, Size physicalSize) {
    final theme = Theme.of(context);
    return _LifeSettingsPanel(
      title: _lifeI18nText(
        context,
        'inline.plan295.life.wallpaper_search.20ae6f2d65a7',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan296.ui.pages.toolbox.life.tools.toolbox.life.tools.wallpaper.current_screen_is_about_x_px.0b0150fe3f',
        params: <String, Object?>{
          'p0': physicalSize.width.round(),
          'p1': physicalSize.height.round(),
        },
      ),
      children: <Widget>[
        TextField(
          controller: _queryController,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search_rounded),
            border: const OutlineInputBorder(),
            labelText: _lifeI18nText(
              context,
              'inline.plan295.life.search_keywords_e_g_nature_city_sky.2a0c22dfbb17',
            ),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    tooltip: _lifeI18nText(
                      context,
                      'inline.plan294.zen_sand.clear_ea17218b',
                    ),
                    onPressed: () {
                      _queryController.clear();
                      setState(() => _query = '');
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
          ),
          textInputAction: TextInputAction.search,
          onChanged: (value) => setState(() => _query = value),
          onSubmitted: (_) => _reload(),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            ChoiceChip(
              selected: _sourceId == 'all',
              label: Text(
                _lifeI18nText(
                  context,
                  'inline.plan295.life.all_sources.cac79d41a0ee',
                ),
              ),
              onSelected: (_) => _selectSource('all'),
            ),
            for (final source in _wallpaperSources)
              ChoiceChip(
                selected: _sourceId == source.id,
                label: Text(source.name),
                onSelected: (_) => _selectSource(source.id),
              ),
          ],
        ),
        const SizedBox(height: 12),
        SegmentedButton<_WallpaperFitMode>(
          segments: <ButtonSegment<_WallpaperFitMode>>[
            ButtonSegment<_WallpaperFitMode>(
              value: _WallpaperFitMode.screen,
              icon: const Icon(Icons.phone_iphone_rounded),
              label: Text(
                _lifeI18nText(
                  context,
                  'inline.plan295.life.match_screen.ef9aaee7bfdf',
                ),
              ),
            ),
            ButtonSegment<_WallpaperFitMode>(
              value: _WallpaperFitMode.any,
              icon: const Icon(Icons.grid_view_rounded),
              label: Text(
                _lifeI18nText(
                  context,
                  'inline.plan295.life.any_size.09b226e61c5a',
                ),
              ),
            ),
          ],
          selected: <_WallpaperFitMode>{_fitMode},
          onSelectionChanged: (value) => setState(() => _fitMode = value.first),
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: FilledButton.icon(
                onPressed: _reload,
                icon: const Icon(Icons.search_rounded),
                label: Text(
                  _lifeI18nText(
                    context,
                    'inline.plan295.life.get_wallpapers.751dbb1834eb',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filledTonal(
              tooltip: _lifeI18nText(
                context,
                'inline.plan295.life.random_refresh.179cec4dca87',
              ),
              onPressed: _reload,
              icon: const Icon(Icons.shuffle_rounded),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          _lifeI18nText(
            context,
            'inline.plan295.life.this_tool_aggregates_public_links_an.561d48c7edea',
          ),
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildCachePanel(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeI18nText(
        context,
        'inline.plan295.life.image_cache.745e273d4832',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.previews_and_downloads_reuse_local_c.157983715693',
      ),
      children: <Widget>[
        FutureBuilder<_WallpaperCacheStatus>(
          future: _cacheStatusFuture,
          builder: (context, snapshot) {
            final status = snapshot.data;
            final label = status == null
                ? _lifeI18nText(
                    context,
                    'inline.plan295.life.reading_cache_status.47ac666d97db',
                  )
                : _lifeI18nText(
                    context,
                    'inline.plan296.ui.pages.toolbox.life.tools.toolbox.life.tools.wallpaper.source_snapshots_images.62adf851d8',
                    params: <String, Object?>{
                      'sourceSnapshots': status.sourceSnapshots,
                      'imageFiles': status.imageFiles,
                      'p2': _formatBytes(status.totalBytes),
                    },
                  );
            return Row(
              children: <Widget>[
                Expanded(child: Text(label)),
                const SizedBox(width: 10),
                FilledButton.tonalIcon(
                  onPressed: status?.hasData == true ? _clearCache : null,
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: Text(
                    _lifeI18nText(
                      context,
                      'inline.plan295.life.clear_cache.3c05c3345557',
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildSourceSummary(
    BuildContext context,
    List<_WallpaperSourceError> errors, {
    required bool usedCache,
  }) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.photo_library_rounded,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  usedCache
                      ? _lifeI18nText(
                          context,
                          'inline.plan295.life.using_cached_wallpaper_results.0918f56e722e',
                        )
                      : _lifeI18nText(
                          context,
                          'inline.plan295.life.9_random_wallpapers.f1c30aad62d9',
                        ),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          if (errors.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              _lifeI18nText(
                context,
                'inline.plan295.life.some_sources_are_temporarily_unavail.f7ad15f7d26d',
              ),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 6),
            for (final error in errors.take(2))
              Text(
                _sourceErrorLabel(context, error),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
          ],
        ],
      ),
    );
  }

  String _sourceErrorLabel(BuildContext context, _WallpaperSourceError error) {
    final reason = switch (error.kind) {
      _WallpaperSourceErrorKind.timeout => _lifeI18nText(
        context,
        'inline.plan295.life.request_timed_out.8e3a6a7f1650',
      ),
      _WallpaperSourceErrorKind.forbidden => _lifeI18nText(
        context,
        'inline.plan295.life.access_denied.d3eea76644d1',
      ),
      _WallpaperSourceErrorKind.protected => _lifeI18nText(
        context,
        'inline.plan295.life.blocked_by_source_protection.0aa858ebed76',
      ),
      _WallpaperSourceErrorKind.http => _lifeI18nText(
        context,
        'inline.plan296.ui.pages.toolbox.life.tools.toolbox.life.tools.wallpaper.http.f4827c8db9',
        params: <String, Object?>{'p0': error.statusCode ?? ''},
      ),
      _WallpaperSourceErrorKind.network => _lifeI18nText(
        context,
        'inline.plan295.life.network_unavailable.055df1c6fae0',
      ),
      _WallpaperSourceErrorKind.parse => _lifeI18nText(
        context,
        'inline.plan295.life.response_parse_failed.f29595dc8b7a',
      ),
      _WallpaperSourceErrorKind.other => _lifeI18nText(
        context,
        'inline.plan295.life.temporarily_unavailable.230aa5e06a72',
      ),
    };
    final suffix = error.usedCache
        ? _lifeI18nText(context, 'inline.plan295.life.cache_used.9a3cc125e1e2')
        : '';
    return '${error.sourceName}: $reason$suffix';
  }

  Widget _buildErrorPanel(BuildContext context, String message) {
    return _LifeSettingsPanel(
      title: _lifeI18nText(
        context,
        'inline.plan295.life.wallpaper_load_failed.df82faabaaed',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.check_the_network_or_open_the_source.3f0b58f53180',
      ),
      children: <Widget>[SelectableText(message)],
    );
  }

  Widget _buildEmptyPanel(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeI18nText(
        context,
        'inline.plan295.life.no_matching_wallpapers.abb7d0238ca6',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.switch_to_any_size_or_try_another_ke.a01ed58fad9f',
      ),
      children: <Widget>[
        FilledButton.tonalIcon(
          onPressed: () => setState(() => _fitMode = _WallpaperFitMode.any),
          icon: const Icon(Icons.grid_view_rounded),
          label: Text(
            _lifeI18nText(
              context,
              'inline.plan295.life.show_any_size.b6c992ba70db',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSourceLinks(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeI18nText(
        context,
        'inline.plan295.life.source_entries.0dac5504cc85',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.wallpaper_helper_now_keeps_only_bing.93a8174ccaa9',
      ),
      children: <Widget>[
        for (final source in _wallpaperSources)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.open_in_new_rounded),
            title: Text(source.name),
            subtitle: Text(_lifeI18nText(context, source.summaryKey)),
            onTap: () => _openExternal(context, _sourceUrl(source)),
          ),
      ],
    );
  }

  List<_WallpaperItem> _filterItems(
    List<_WallpaperItem> items,
    Size screenSize,
  ) {
    final filtered = items
        .where((item) {
          final sourceMatches =
              _sourceId == 'all' ||
              item.sourceName.toLowerCase().contains(_sourceId.toLowerCase()) ||
              _sourceId == _sourceIdForItem(item);
          if (!sourceMatches || !item.matchesQuery(_query)) {
            return false;
          }
          if (_fitMode == _WallpaperFitMode.screen) {
            return item.matchesScreen(screenSize);
          }
          return true;
        })
        .toList(growable: false);

    if (filtered.length >= 9 || _fitMode == _WallpaperFitMode.any) {
      return filtered;
    }
    return items
        .where((item) {
          final sourceMatches =
              _sourceId == 'all' ||
              item.sourceName.toLowerCase().contains(_sourceId.toLowerCase()) ||
              _sourceId == _sourceIdForItem(item);
          return sourceMatches && item.matchesQuery(_query);
        })
        .toList(growable: false);
  }

  String _sourceIdForItem(_WallpaperItem item) {
    final source = item.sourceName.toLowerCase();
    if (source.contains('bing')) {
      return 'bing';
    }
    return source;
  }

  void _reload() {
    setState(() {
      _refreshNonce += 1;
      _loadFuture = _loadWallpapers();
    });
  }

  void _selectSource(String sourceId) {
    setState(() {
      _sourceId = sourceId;
      _refreshNonce += 1;
      _loadFuture = _loadWallpapers();
    });
  }

  Future<void> _clearCache() async {
    await _WallpaperCacheStore.instance.clear();
    if (!mounted) {
      return;
    }
    setState(() {
      _cacheStatusFuture = _WallpaperCacheStore.instance.status();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _lifeI18nText(
            context,
            'inline.plan295.life.wallpaper_cache_cleared.f248fecaf313',
          ),
        ),
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _sourceUrl(_WallpaperSource source) {
    return source.homeUrl;
  }

  Future<_WallpaperLoadResult> _loadWallpapers() async {
    final selected = _wallpaperSources
        .where((source) => _sourceId == 'all' || source.id == _sourceId)
        .toList(growable: false);
    final outcomes = await Future.wait(
      selected.map(_loadSourceWithCache),
      eagerError: false,
    );
    final items = <_WallpaperItem>[];
    final errors = <_WallpaperSourceError>[];
    var usedCache = false;
    for (final outcome in outcomes) {
      items.addAll(outcome.items);
      final error = outcome.error;
      if (error != null) {
        errors.add(error);
      }
      usedCache = usedCache || outcome.usedCache;
    }

    final deduped = <String, _WallpaperItem>{};
    for (final item in items) {
      deduped[item.imageUrl] = item;
    }
    final shuffled = deduped.values.toList(growable: false)
      ..shuffle(
        math.Random(DateTime.now().millisecondsSinceEpoch + _refreshNonce),
      );
    return _WallpaperLoadResult(
      items: shuffled,
      errors: errors,
      usedCache: usedCache,
    );
  }

  Future<_WallpaperSourceLoadOutcome> _loadSourceWithCache(
    _WallpaperSource source,
  ) async {
    final sourceQuery = _query.trim();
    final startedAt = DateTime.now();
    _wallpaperLog.d(
      'toolbox_wallpaper',
      'source load start',
      data: <String, Object?>{
        'source': source.id,
        'query': sourceQuery,
        'kind': source.kind.name,
      },
    );
    try {
      final loaded = await switch (source.kind) {
        _WallpaperSourceKind.bing => _loadBingWallpapers(source),
      };
      await _WallpaperCacheStore.instance.saveItems(
        source: source,
        query: sourceQuery,
        items: loaded,
      );
      _wallpaperLog.i(
        'toolbox_wallpaper',
        'source load complete',
        data: <String, Object?>{
          'source': source.id,
          'count': loaded.length,
          'elapsedMs': DateTime.now().difference(startedAt).inMilliseconds,
        },
      );
      return _WallpaperSourceLoadOutcome(items: loaded);
    } catch (error, stackTrace) {
      final cached = await _WallpaperCacheStore.instance.readItems(
        source: source,
        query: sourceQuery,
      );
      final usedCachedItems = cached != null;
      final sourceError = _WallpaperSourceError.fromError(
        source: source,
        error: error,
        usedCache: usedCachedItems,
      );
      _wallpaperLog.w(
        'toolbox_wallpaper',
        'source load failed',
        data: <String, Object?>{
          'source': source.id,
          'query': sourceQuery,
          'kind': sourceError.kind.name,
          'statusCode': sourceError.statusCode,
          'usedCache': usedCachedItems,
          'elapsedMs': DateTime.now().difference(startedAt).inMilliseconds,
          'error': '$error',
          if (stackTrace.toString().isNotEmpty)
            'stackTop': stackTrace.toString().split('\n').first,
        },
      );
      return _WallpaperSourceLoadOutcome(
        items: cached?.items ?? const <_WallpaperItem>[],
        error: sourceError,
        usedCache: usedCachedItems,
      );
    }
  }

  Future<List<_WallpaperItem>> _loadBingWallpapers(
    _WallpaperSource source,
  ) async {
    final uri = Uri.https(
      'www.bing.com',
      '/HPImageArchive.aspx',
      <String, String>{'format': 'js', 'idx': '0', 'n': '8', 'mkt': 'en-US'},
    );
    final json = await _getJson(
      uri,
      headers: _wallpaperHeadersForUrl(source.homeUrl),
    );
    final images = json['images'] as List<dynamic>? ?? const <dynamic>[];
    return images
        .whereType<Map<String, dynamic>>()
        .map((image) {
          final url = image['url']?.toString() ?? '';
          final fullUrl = url.startsWith('http')
              ? url
              : 'https://www.bing.com$url';
          final title = image['title']?.toString().trim();
          final copyright = image['copyright']?.toString();
          final copyrightLink = image['copyrightlink']?.toString();
          final sourceUrl = copyrightLink == null || copyrightLink.isEmpty
              ? source.homeUrl
              : (copyrightLink.startsWith('http')
                    ? copyrightLink
                    : 'https://www.bing.com$copyrightLink');
          return _WallpaperItem(
            id: 'bing-${image['hsh'] ?? fullUrl.hashCode}',
            title: title == null || title.isEmpty ? source.name : title,
            sourceName: source.name,
            sourceUrl: sourceUrl,
            previewUrl: fullUrl,
            imageUrl: fullUrl,
            width: 1920,
            height: 1080,
            attribution: copyright,
            fileType: 'image/jpeg',
          );
        })
        .toList(growable: false);
  }

  Future<Map<String, dynamic>> _getJson(
    Uri uri, {
    Map<String, String>? headers,
    Duration timeout = _wallpaperFastTimeout,
  }) async {
    final response = await _getWallpaperResponse(
      uri,
      headers: headers,
      timeout: timeout,
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<http.Response> _getWallpaperResponse(
    Uri uri, {
    Map<String, String>? headers,
    Duration timeout = _wallpaperFastTimeout,
  }) async {
    final response = await http
        .get(uri, headers: headers ?? _wallpaperHeadersForUrl(uri.toString()))
        .timeout(timeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _WallpaperHttpException(
        statusCode: response.statusCode,
        uri: uri,
        contentType: response.headers['content-type'],
        isProtected: _isProtectedResponse(response),
      );
    }
    if (_isProtectedResponse(response)) {
      throw _WallpaperHttpException(
        statusCode: response.statusCode,
        uri: uri,
        contentType: response.headers['content-type'],
        isProtected: true,
      );
    }
    return response;
  }

  void _openPreview(_WallpaperItem item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _WallpaperPreviewPage(item: item),
      ),
    );
  }
}

bool _isProtectedResponse(http.Response response) {
  final mitigated = response.headers['cf-mitigated']?.toLowerCase();
  if (mitigated == 'challenge') {
    return true;
  }
  final server = response.headers['server']?.toLowerCase() ?? '';
  final contentType = response.headers['content-type']?.toLowerCase() ?? '';
  if (!server.contains('cloudflare') && !contentType.contains('text/html')) {
    return false;
  }
  final body = response.body.toLowerCase();
  return body.contains('just a moment') ||
      body.contains('enable javascript and cookies') ||
      body.contains('/cdn-cgi/challenge-platform/');
}

Map<String, String> _wallpaperHeadersForUrl(String url) {
  final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
  final headers = <String, String>{
    'User-Agent': _wallpaperDesktopUserAgent,
    'Accept': 'application/json,text/plain,image/webp,image/apng,*/*',
    'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
    'Cache-Control': 'no-cache',
  };
  if (host.contains('bing.com')) {
    headers['Referer'] = 'https://www.bing.com/';
    headers['Accept'] = 'application/json,text/plain,*/*';
  }
  return headers;
}

class _WallpaperGrid extends StatelessWidget {
  const _WallpaperGrid({required this.items, required this.onTap});

  final List<_WallpaperItem> items;
  final ValueChanged<_WallpaperItem> onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 520 ? 3 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.72,
          ),
          itemBuilder: (context, index) {
            return _WallpaperTile(item: items[index], onTap: onTap);
          },
        );
      },
    );
  }
}

class _WallpaperTile extends StatelessWidget {
  const _WallpaperTile({required this.item, required this.onTap});

  final _WallpaperItem item;
  final ValueChanged<_WallpaperItem> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => onTap(item),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            _CachedWallpaperImage(
              url: item.previewUrl,
              extension: item.extension,
              fit: BoxFit.cover,
              fallbackIconColor: theme.colorScheme.onSurfaceVariant,
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.72),
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        item.sourceName,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.resolution,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CachedWallpaperImage extends StatefulWidget {
  const _CachedWallpaperImage({
    required this.url,
    required this.extension,
    required this.fit,
    this.fallbackIconColor,
  });

  final String url;
  final String extension;
  final BoxFit fit;
  final Color? fallbackIconColor;

  @override
  State<_CachedWallpaperImage> createState() => _CachedWallpaperImageState();
}

class _CachedWallpaperImageState extends State<_CachedWallpaperImage> {
  late Future<String> _pathFuture;

  @override
  void initState() {
    super.initState();
    _pathFuture = _cacheImage();
  }

  @override
  void didUpdateWidget(_CachedWallpaperImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url ||
        oldWidget.extension != widget.extension) {
      _pathFuture = _cacheImage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<String>(
      future: _pathFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Image.file(
            File(snapshot.data!),
            fit: widget.fit,
            errorBuilder: (context, error, stackTrace) => _brokenImage(theme),
          );
        }
        if (snapshot.hasError) {
          return Image.network(
            widget.url,
            fit: widget.fit,
            headers: _wallpaperHeadersForUrl(widget.url),
            errorBuilder: (context, error, stackTrace) => _brokenImage(theme),
          );
        }
        return DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
          ),
          child: const Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

  Future<String> _cacheImage() {
    return _WallpaperCacheStore.instance.cacheImage(
      widget.url,
      widget.extension,
      headers: _wallpaperHeadersForUrl(widget.url),
    );
  }

  Widget _brokenImage(ThemeData theme) {
    return ColoredBox(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.broken_image_rounded,
          color: widget.fallbackIconColor,
        ),
      ),
    );
  }
}

class _WallpaperPreviewPage extends StatefulWidget {
  const _WallpaperPreviewPage({required this.item});

  final _WallpaperItem item;

  @override
  State<_WallpaperPreviewPage> createState() => _WallpaperPreviewPageState();
}

class _WallpaperPreviewPageState extends State<_WallpaperPreviewPage> {
  late final TransformationController _transformController;
  late Future<String> _imagePathFuture;
  bool _busy = false;
  String? _savedPath;
  _WallpaperTarget _target = _WallpaperTarget.both;

  @override
  void initState() {
    super.initState();
    _transformController = TransformationController();
    _imagePathFuture = _cacheFullImage();
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(item.sourceName),
        actions: <Widget>[
          IconButton(
            tooltip: _lifeI18nText(
              context,
              'inline.plan295.life.open_source.7796cc613b9b',
            ),
            onPressed: () => _openExternal(context, item.sourceUrl),
            icon: const Icon(Icons.open_in_new_rounded),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ColoredBox(
              color: Colors.black,
              child: Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: InteractiveViewer(
                      transformationController: _transformController,
                      minScale: 0.7,
                      maxScale: 5,
                      child: Center(
                        child: FutureBuilder<String>(
                          future: _imagePathFuture,
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return Image.file(
                                File(snapshot.data!),
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    _previewError(context),
                              );
                            }
                            if (snapshot.hasError) {
                              return _previewError(context);
                            }
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 14,
                    bottom: 14,
                    child: IconButton.filled(
                      tooltip: _lifeI18nText(
                        context,
                        'inline.plan295.life.reset_zoom.5526c102ba3b',
                      ),
                      onPressed: () =>
                          _transformController.value = Matrix4.identity(),
                      icon: const Icon(Icons.center_focus_strong_rounded),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  top: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      item.resolution,
                      if (item.author != null && item.author!.isNotEmpty)
                        item.author!,
                    ].join(' · '),
                    style: theme.textTheme.bodySmall,
                  ),
                  if (item.attribution != null &&
                      item.attribution!.trim().isNotEmpty) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(
                      item.attribution!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 10),
                  SegmentedButton<_WallpaperTarget>(
                    segments: <ButtonSegment<_WallpaperTarget>>[
                      ButtonSegment<_WallpaperTarget>(
                        value: _WallpaperTarget.home,
                        icon: const Icon(Icons.home_rounded),
                        label: Text(
                          _lifeI18nText(
                            context,
                            'inline.plan295.life.home.23d554dfef88',
                          ),
                        ),
                      ),
                      ButtonSegment<_WallpaperTarget>(
                        value: _WallpaperTarget.lock,
                        icon: const Icon(Icons.lock_rounded),
                        label: Text(
                          _lifeI18nText(
                            context,
                            'inline.plan295.life.lock.512c333a1f18',
                          ),
                        ),
                      ),
                      ButtonSegment<_WallpaperTarget>(
                        value: _WallpaperTarget.both,
                        icon: const Icon(Icons.wallpaper_rounded),
                        label: Text(
                          _lifeI18nText(
                            context,
                            'inline.ui.pages.toolbox_human_tests_bimanual.both_897ba3',
                          ),
                        ),
                      ),
                    ],
                    selected: <_WallpaperTarget>{_target},
                    onSelectionChanged: _busy
                        ? null
                        : (value) => setState(() => _target = value.first),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: _busy ? null : _download,
                          icon: const Icon(Icons.download_rounded),
                          label: Text(_lifeI18nText(context, 'download')),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _busy ? null : _setWallpaper,
                          icon: _busy
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.wallpaper_rounded),
                          label: Text(
                            _lifeI18nText(
                              context,
                              'inline.plan295.life.set_wallpaper.5f52ac244d68',
                            ),
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
      ),
    );
  }

  Widget _previewError(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.broken_image_rounded, color: Colors.white, size: 48),
          const SizedBox(height: 10),
          Text(
            _lifeI18nText(
              context,
              'inline.plan295.life.image_unavailable.f6becb2de91e',
            ),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 10),
          FilledButton.tonalIcon(
            onPressed: () => _openExternal(context, widget.item.sourceUrl),
            icon: const Icon(Icons.open_in_new_rounded),
            label: Text(
              _lifeI18nText(
                context,
                'inline.plan295.life.open_source.7796cc613b9b',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _download() async {
    await _saveWallpaper(showSavedMessage: true);
  }

  Future<void> _setWallpaper() async {
    final saved = await _saveWallpaper(showSavedMessage: false);
    if (saved == null || !mounted) {
      return;
    }
    setState(() => _busy = true);
    final result = await _setLifeWallpaper(
      filePath: saved.path,
      target: switch (_target) {
        _WallpaperTarget.home => 'home',
        _WallpaperTarget.lock => 'lock',
        _WallpaperTarget.both => 'both',
      },
    );
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);
    final success = result['success'] == true;
    final errorCode = result['errorCode']?.toString();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? _lifeI18nText(
                  context,
                  'inline.plan295.life.wallpaper_set_request_completed.5e87f29d723a',
                )
              : _lifeI18nText(
                      context,
                      'inline.plan295.life.this_platform_does_not_support_direc.901cb43fec9e',
                    ) +
                    (errorCode == null ? '' : ' ($errorCode)'),
        ),
      ),
    );
  }

  Future<_WallpaperSaveResult?> _saveWallpaper({
    required bool showSavedMessage,
  }) async {
    setState(() => _busy = true);
    try {
      final savedPath = await _cacheFullImage();
      final bytes = await File(savedPath).readAsBytes();
      final fileName = _safeFileName(widget.item);
      var messagePath = savedPath;
      if (showSavedMessage) {
        messagePath = await _exportWallpaperFile(fileName, bytes) ?? savedPath;
      }
      if (!mounted) {
        return null;
      }
      setState(() {
        _savedPath = savedPath;
        _busy = false;
      });
      if (showSavedMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _lifeI18nText(
                context,
                'inline.plan296.ui.pages.toolbox.life.tools.toolbox.life.tools.wallpaper.saved.cb776c173a',
                params: <String, Object?>{'messagePath': messagePath},
              ),
            ),
          ),
        );
      }
      return _WallpaperSaveResult(path: savedPath, bytes: bytes);
    } catch (error) {
      if (!mounted) {
        return null;
      }
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _lifeI18nText(
              context,
              'inline.plan296.ui.pages.toolbox.crypto.security.toolbox.crypto.security.steganography.save_failed.733e2f2246',
              params: <String, Object?>{'error': error},
            ),
          ),
        ),
      );
      return null;
    }
  }

  Future<String> _cacheFullImage() {
    final savedPath = _savedPath;
    if (savedPath != null && File(savedPath).existsSync()) {
      return Future<String>.value(savedPath);
    }
    return _WallpaperCacheStore.instance.cacheImage(
      widget.item.imageUrl,
      widget.item.extension,
      headers: _wallpaperHeadersForUrl(widget.item.imageUrl),
    );
  }

  Future<String?> _exportWallpaperFile(String fileName, Uint8List bytes) async {
    try {
      final savedPath = await FilePicker.platform.saveFile(
        fileName: fileName,
        bytes: bytes,
        type: FileType.image,
        allowedExtensions: <String>[widget.item.extension],
      );
      return savedPath?.trim().isEmpty == true ? null : savedPath;
    } catch (_) {
      return null;
    }
  }

  String _safeFileName(_WallpaperItem item) {
    final raw = '${item.sourceName}-${item.id}.${item.extension}';
    return raw.replaceAll(RegExp(r'[\\/:*?"<>|\s]+'), '_');
  }
}
