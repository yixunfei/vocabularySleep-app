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
    required this.summaryZh,
    required this.summaryEn,
  });

  final String id;
  final String name;
  final _WallpaperSourceKind kind;
  final String homeUrl;
  final String summaryZh;
  final String summaryEn;
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
    summaryZh: '每日首页壁纸，附带原始摄影来源说明。',
    summaryEn: 'Daily homepage wallpapers with original attribution.',
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
      title: _lifeText(context, zh: '壁纸助手', en: 'Wallpaper helper'),
      subtitle: _lifeText(
        context,
        zh: '聚合公开资源页，默认加载 9 张随机壁纸，支持搜索、预览、下载和设置壁纸。',
        en: 'Aggregates public sources, loads 9 random wallpapers by default, and supports search, preview, download, and setting wallpaper.',
      ),
      appBarActions: <Widget>[
        IconButton(
          tooltip: _lifeText(
            context,
            zh: '刷新随机壁纸',
            en: 'Refresh random wallpapers',
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
                  title: _lifeText(
                    context,
                    zh: '正在获取壁纸',
                    en: 'Loading wallpapers',
                  ),
                  subtitle: _lifeText(
                    context,
                    zh: '正在从公开来源获取随机壁纸。',
                    en: 'Fetching random wallpapers from public sources.',
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
      title: _lifeText(context, zh: '壁纸检索', en: 'Wallpaper search'),
      subtitle: _lifeText(
        context,
        zh: '当前屏幕约 ${physicalSize.width.round()} x ${physicalSize.height.round()} px，可优先匹配接近比例和尺寸的图片。',
        en: 'Current screen is about ${physicalSize.width.round()} x ${physicalSize.height.round()} px; matching can prioritize similar ratio and size.',
      ),
      children: <Widget>[
        TextField(
          controller: _queryController,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search_rounded),
            border: const OutlineInputBorder(),
            labelText: _lifeText(
              context,
              zh: '搜索关键词，例如 nature / city / sky',
              en: 'Search keywords, e.g. nature / city / sky',
            ),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    tooltip: _lifeText(context, zh: '清空', en: 'Clear'),
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
              label: Text(_lifeText(context, zh: '全部来源', en: 'All sources')),
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
              label: Text(_lifeText(context, zh: '匹配当前屏幕', en: 'Match screen')),
            ),
            ButtonSegment<_WallpaperFitMode>(
              value: _WallpaperFitMode.any,
              icon: const Icon(Icons.grid_view_rounded),
              label: Text(_lifeText(context, zh: '不限尺寸', en: 'Any size')),
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
                  _lifeText(context, zh: '获取壁纸', en: 'Get wallpapers'),
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filledTonal(
              tooltip: _lifeText(context, zh: '随机刷新', en: 'Random refresh'),
              onPressed: _reload,
              icon: const Icon(Icons.shuffle_rounded),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          _lifeText(
            context,
            zh: '默认只聚合公开资源链接与运行时图片，不内置第三方壁纸文件；版权和使用范围请以来源页面说明为准。',
            en: 'This tool aggregates public links and runtime images without bundling third-party wallpaper files; copyright and usage rights follow each source page.',
          ),
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildCachePanel(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeText(context, zh: '图片缓存', en: 'Image cache'),
      subtitle: _lifeText(
        context,
        zh: '预览和下载会复用本地缓存；来源短暂不可用时也会尝试读取已缓存结果。',
        en: 'Previews and downloads reuse local cache; cached source results are used when a source is temporarily unavailable.',
      ),
      children: <Widget>[
        FutureBuilder<_WallpaperCacheStatus>(
          future: _cacheStatusFuture,
          builder: (context, snapshot) {
            final status = snapshot.data;
            final label = status == null
                ? _lifeText(context, zh: '正在读取缓存状态', en: 'Reading cache status')
                : _lifeText(
                    context,
                    zh: '来源快照 ${status.sourceSnapshots} 组 · 图片 ${status.imageFiles} 张 · ${_formatBytes(status.totalBytes)}',
                    en: '${status.sourceSnapshots} source snapshots · ${status.imageFiles} images · ${_formatBytes(status.totalBytes)}',
                  );
            return Row(
              children: <Widget>[
                Expanded(child: Text(label)),
                const SizedBox(width: 10),
                FilledButton.tonalIcon(
                  onPressed: status?.hasData == true ? _clearCache : null,
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: Text(
                    _lifeText(context, zh: '清理缓存', en: 'Clear cache'),
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
                      ? _lifeText(
                          context,
                          zh: '已使用本地缓存结果',
                          en: 'Using cached wallpaper results',
                        )
                      : _lifeText(
                          context,
                          zh: '随机壁纸 9 张',
                          en: '9 random wallpapers',
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
              _lifeText(
                context,
                zh: '部分来源暂时不可用，已保留可访问来源结果。',
                en: 'Some sources are temporarily unavailable; available results are still shown.',
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
      _WallpaperSourceErrorKind.timeout => _lifeText(
        context,
        zh: '请求超时',
        en: 'request timed out',
      ),
      _WallpaperSourceErrorKind.forbidden => _lifeText(
        context,
        zh: '来源拒绝访问',
        en: 'access denied',
      ),
      _WallpaperSourceErrorKind.protected => _lifeText(
        context,
        zh: '站点访问保护拦截',
        en: 'blocked by source protection',
      ),
      _WallpaperSourceErrorKind.http => _lifeText(
        context,
        zh: 'HTTP ${error.statusCode ?? ''}',
        en: 'HTTP ${error.statusCode ?? ''}',
      ),
      _WallpaperSourceErrorKind.network => _lifeText(
        context,
        zh: '网络连接失败',
        en: 'network unavailable',
      ),
      _WallpaperSourceErrorKind.parse => _lifeText(
        context,
        zh: '返回数据无法解析',
        en: 'response parse failed',
      ),
      _WallpaperSourceErrorKind.other => _lifeText(
        context,
        zh: '暂时不可用',
        en: 'temporarily unavailable',
      ),
    };
    final suffix = error.usedCache
        ? _lifeText(context, zh: '，已使用缓存', en: ', cache used')
        : '';
    return '${error.sourceName}: $reason$suffix';
  }

  Widget _buildErrorPanel(BuildContext context, String message) {
    return _LifeSettingsPanel(
      title: _lifeText(context, zh: '壁纸加载失败', en: 'Wallpaper load failed'),
      subtitle: _lifeText(
        context,
        zh: '请检查网络或直接打开下方来源页面。',
        en: 'Check the network or open the source pages below.',
      ),
      children: <Widget>[SelectableText(message)],
    );
  }

  Widget _buildEmptyPanel(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeText(context, zh: '没有匹配的壁纸', en: 'No matching wallpapers'),
      subtitle: _lifeText(
        context,
        zh: '可切换为不限尺寸，或换一个关键词后重新获取。',
        en: 'Switch to any size or try another keyword and fetch again.',
      ),
      children: <Widget>[
        FilledButton.tonalIcon(
          onPressed: () => setState(() => _fitMode = _WallpaperFitMode.any),
          icon: const Icon(Icons.grid_view_rounded),
          label: Text(_lifeText(context, zh: '不限尺寸查看', en: 'Show any size')),
        ),
      ],
    );
  }

  Widget _buildSourceLinks(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeText(context, zh: '来源入口', en: 'Source entries'),
      subtitle: _lifeText(
        context,
        zh: '壁纸助手当前仅保留 Bing Wallpaper 来源，版权、下载与使用范围以来源页面说明为准。',
        en: 'Wallpaper helper now keeps only Bing Wallpaper; rights, downloads, and usage follow the source page.',
      ),
      children: <Widget>[
        for (final source in _wallpaperSources)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.open_in_new_rounded),
            title: Text(source.name),
            subtitle: Text(
              _lifeText(context, zh: source.summaryZh, en: source.summaryEn),
            ),
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
          _lifeText(context, zh: '壁纸缓存已清理', en: 'Wallpaper cache cleared'),
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
            tooltip: _lifeText(context, zh: '打开来源', en: 'Open source'),
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
                      tooltip: _lifeText(context, zh: '重置缩放', en: 'Reset zoom'),
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
                        label: Text(_lifeText(context, zh: '桌面', en: 'Home')),
                      ),
                      ButtonSegment<_WallpaperTarget>(
                        value: _WallpaperTarget.lock,
                        icon: const Icon(Icons.lock_rounded),
                        label: Text(_lifeText(context, zh: '锁屏', en: 'Lock')),
                      ),
                      ButtonSegment<_WallpaperTarget>(
                        value: _WallpaperTarget.both,
                        icon: const Icon(Icons.wallpaper_rounded),
                        label: Text(_lifeText(context, zh: '两者', en: 'Both')),
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
                          label: Text(
                            _lifeText(context, zh: '下载', en: 'Download'),
                          ),
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
                            _lifeText(context, zh: '设为壁纸', en: 'Set wallpaper'),
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
            _lifeText(context, zh: '图片暂时无法加载', en: 'Image unavailable'),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 10),
          FilledButton.tonalIcon(
            onPressed: () => _openExternal(context, widget.item.sourceUrl),
            icon: const Icon(Icons.open_in_new_rounded),
            label: Text(_lifeText(context, zh: '打开来源', en: 'Open source')),
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
              ? _lifeText(
                  context,
                  zh: '已尝试设置壁纸',
                  en: 'Wallpaper set request completed',
                )
              : _lifeText(
                      context,
                      zh: '当前平台不支持直接设置壁纸，已保留本地缓存文件。',
                      en: 'This platform does not support direct wallpaper setting; the cached file was kept locally.',
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
              _lifeText(
                context,
                zh: '已保存: $messagePath',
                en: 'Saved: $messagePath',
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
            _lifeText(context, zh: '保存失败: $error', en: 'Save failed: $error'),
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
