part of '../toolbox_life_tools.dart';

const Duration _reverseImageUploadTimeout = Duration(seconds: 30);
const Duration _reverseImageSearchTimeout = Duration(seconds: 18);
const Duration _reverseImageParseTimeout = Duration(seconds: 12);
const Duration _reverseImageGoogleResolveTimeout = Duration(seconds: 3);
const Duration _reverseImageGoogleRequestTimeout = Duration(seconds: 10);
const int _reverseImagePageSize = 20;
const String _reverseImageLegacyUploadEndpoint =
    'https://uguu.se/upload?output=json';
const String _reverseImageBaiduUploadEndpoint =
    'https://graph.baidu.com/upload';
const String _reverseImageSogouUploadPath = '/pic/upload_pic.jsp';
const String _reverseImageUserAgent = 'Mozilla/5.0 vocabulary-sleep-app';

enum _ReverseImageStage {
  idle,
  preparing,
  directUploading,
  parsingDirectResult,
  resolvingPublicUrl,
  searching,
  done,
  failed,
}

enum _ReverseImageResultKind { similar, source, product, page, unknown }

enum _ReverseImagePagingKind { sogouSim, googleSearchPage }

class _ReverseImageEngine {
  const _ReverseImageEngine({
    required this.id,
    required this.nameKey,
    required this.host,
    required this.path,
    required this.queryKey,
    this.directPreferred = false,
    this.fixedQuery = const <String, String>{},
  });

  final String id;
  final String nameKey;
  final String host;
  final String path;
  final String queryKey;
  final bool directPreferred;
  final Map<String, String> fixedQuery;

  String label(BuildContext context) {
    return _lifeI18nText(context, nameKey);
  }

  Uri buildSearchUri(Uri imageUri) {
    final query = <String, String>{
      ...fixedQuery,
      if (queryKey.isNotEmpty) queryKey: imageUri.toString(),
    };
    return Uri.https(host, path, query);
  }
}

class _ReverseImageResultItem {
  const _ReverseImageResultItem({
    required this.kind,
    required this.title,
    required this.sourceSite,
    required this.sourceUrl,
    required this.imageUrl,
    required this.previewUrl,
    required this.snippet,
    required this.rawType,
    required this.rank,
  });

  final _ReverseImageResultKind kind;
  final String title;
  final String sourceSite;
  final String sourceUrl;
  final String imageUrl;
  final String previewUrl;
  final String snippet;
  final String rawType;
  final int rank;
}

class _ReverseImageEngineResult {
  const _ReverseImageEngineResult({
    required this.engine,
    required this.requestUri,
    required this.resultUri,
    required this.elapsed,
    required this.statusCode,
    required this.items,
    required this.manualOnly,
    required this.usedDirectUpload,
    required this.noResultHint,
    this.pagingCursor,
    this.derivedImageUri,
    this.error,
  });

  final _ReverseImageEngine engine;
  final Uri requestUri;
  final Uri resultUri;
  final Duration elapsed;
  final int? statusCode;
  final List<_ReverseImageResultItem> items;
  final bool manualOnly;
  final bool usedDirectUpload;
  final bool noResultHint;
  final _ReverseImagePagingCursor? pagingCursor;
  final Uri? derivedImageUri;
  final Object? error;

  bool get success => error == null;
}

class _ReverseImagePreparedSearch {
  const _ReverseImagePreparedSearch({
    required this.urlSearchImageUri,
    required this.usedLegacyUploadFallback,
    this.searchUriOverrides = const <String, Uri>{},
    this.directBaiduResult,
  });

  final Uri urlSearchImageUri;
  final bool usedLegacyUploadFallback;
  final Map<String, Uri> searchUriOverrides;
  final _ReverseImageEngineResult? directBaiduResult;

  Uri imageUriForEngine(String engineId) {
    return searchUriOverrides[engineId] ?? urlSearchImageUri;
  }
}

class _BaiduStructuredPayload {
  const _BaiduStructuredPayload({
    required this.items,
    required this.publicImageUri,
  });

  final List<_ReverseImageResultItem> items;
  final Uri? publicImageUri;
}

class _ReverseImagePagingCursor {
  const _ReverseImagePagingCursor({
    required this.kind,
    required this.query,
    required this.plevel,
    required this.nextStart,
    required this.hasMore,
  });

  final _ReverseImagePagingKind kind;
  final String query;
  final String plevel;
  final int nextStart;
  final bool hasMore;

  _ReverseImagePagingCursor copyWith({int? nextStart, bool? hasMore}) {
    return _ReverseImagePagingCursor(
      kind: kind,
      query: query,
      plevel: plevel,
      nextStart: nextStart ?? this.nextStart,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class _SogouStructuredPayload {
  const _SogouStructuredPayload({required this.items, this.pagingCursor});

  final List<_ReverseImageResultItem> items;
  final _ReverseImagePagingCursor? pagingCursor;
}

class _SourcePageLoadResult {
  const _SourcePageLoadResult({
    required this.items,
    required this.rawFetchedCount,
    this.nextCursor,
  });

  final List<_ReverseImageResultItem> items;
  final int rawFetchedCount;
  final _ReverseImagePagingCursor? nextCursor;
}

class _GoogleStructuredPayload {
  const _GoogleStructuredPayload({required this.items, this.nextPageUri});

  final List<_ReverseImageResultItem> items;
  final Uri? nextPageUri;
}

final List<_ReverseImageEngine> _reverseImageEngines = <_ReverseImageEngine>[
  const _ReverseImageEngine(
    id: 'baidu',
    nameKey: 'literal.ui.pages.toolbox_life_tools.baidu_image_10eb00',
    host: 'graph.baidu.com',
    path: '/s',
    queryKey: 'image',
    fixedQuery: <String, String>{'src': 'pc'},
    directPreferred: true,
  ),
  const _ReverseImageEngine(
    id: 'sogou',
    nameKey: 'literal.ui.pages.toolbox_life_tools.sogou_image_9cffb2',
    host: 'image.sogou.com',
    path: '/ris',
    queryKey: 'query',
  ),
  const _ReverseImageEngine(
    id: 'google_lens',
    nameKey: 'literal.ui.pages.toolbox_life_tools.google_lens_5f5770',
    host: 'lens.google.com',
    path: '/uploadbyurl',
    queryKey: 'url',
  ),
  const _ReverseImageEngine(
    id: 'yandex',
    nameKey:
        'literal.ui.pages.toolbox_life_tools.toolbox_life_tools_reverse_image.yandex_images_2f8e1c',
    host: 'yandex.com',
    path: '/images/search',
    queryKey: 'url',
    fixedQuery: <String, String>{'rpt': 'imageview'},
  ),
];

class _ReverseImageToolPage extends StatefulWidget {
  const _ReverseImageToolPage();

  @override
  State<_ReverseImageToolPage> createState() => _ReverseImageToolPageState();
}

class _ReverseImageToolPageState extends State<_ReverseImageToolPage> {
  late final TextEditingController _imageUrlController;

  String? _selectedImagePath;
  String? _selectedImageName;
  _ReverseImageStage _stage = _ReverseImageStage.idle;
  bool _busy = false;
  Object? _lastError;
  Uri? _resolvedImageUri;
  bool _usedLegacyUploadFallback = false;
  List<_ReverseImageEngineResult> _results =
      const <_ReverseImageEngineResult>[];
  Map<String, int> _visibleResultCountByEngine = <String, int>{};
  Set<String> _loadingMoreEngineIds = <String>{};

  int get _totalEntries =>
      _results.fold<int>(0, (sum, result) => sum + result.items.length);

  int get _successCount => _results.where((result) => result.success).length;

  int _initialVisibleCount(int total) {
    if (total <= 0) {
      return 0;
    }
    return math.min(_reverseImagePageSize, total);
  }

  int _visibleCountForResult(_ReverseImageEngineResult result) {
    return _visibleResultCountByEngine[result.engine.id] ??
        _initialVisibleCount(result.items.length);
  }

  bool _hasRemoteMoreForResult(_ReverseImageEngineResult result) {
    return result.pagingCursor?.hasMore == true;
  }

  Future<void> _loadMoreResultsForEngine(
    _ReverseImageEngineResult result,
  ) async {
    final engineId = result.engine.id;
    final current = _visibleCountForResult(result);
    final total = result.items.length;
    if (current < total) {
      setState(() {
        _visibleResultCountByEngine = <String, int>{
          ..._visibleResultCountByEngine,
          engineId: math.min(current + _reverseImagePageSize, total),
        };
      });
      return;
    }

    final cursor = result.pagingCursor;
    if (cursor == null || !cursor.hasMore) {
      return;
    }
    if (_loadingMoreEngineIds.contains(engineId)) {
      return;
    }

    setState(() {
      _loadingMoreEngineIds = <String>{..._loadingMoreEngineIds, engineId};
    });

    try {
      final loaded = await _loadMoreFromSource(result, cursor);
      if (!mounted) {
        return;
      }
      final mergedItems = _dedupeResultItems(<_ReverseImageResultItem>[
        ...result.items,
        ...loaded.items,
      ]);
      final nextCursor =
          loaded.nextCursor ??
          cursor.copyWith(
            nextStart: cursor.nextStart + loaded.rawFetchedCount,
            hasMore: loaded.rawFetchedCount > 0,
          );
      final hasNextCursor = nextCursor.hasMore;
      final updatedResult = result.copyWith(
        items: mergedItems,
        pagingCursor: hasNextCursor ? nextCursor : null,
        clearPagingCursor: !hasNextCursor,
      );
      final updatedVisible = math.min<int>(
        current + math.max<int>(_reverseImagePageSize, loaded.items.length),
        mergedItems.length,
      );
      setState(() {
        _results = _results
            .map((entry) => entry.engine.id == engineId ? updatedResult : entry)
            .toList(growable: false);
        _visibleResultCountByEngine = <String, int>{
          ..._visibleResultCountByEngine,
          engineId: updatedVisible,
        };
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _lastError = error);
    } finally {
      if (mounted) {
        setState(() {
          _loadingMoreEngineIds = _loadingMoreEngineIds
              .where((id) => id != engineId)
              .toSet();
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _imageUrlController = TextEditingController();
  }

  @override
  void dispose() {
    _imageUrlController.dispose();
    super.dispose();
  }

  String get _normalizedUiLanguage => AppI18n.normalizeLanguageCode(
    Localizations.localeOf(context).languageCode,
  );

  String _acceptLanguageHeader({bool google = false}) {
    return switch (_normalizedUiLanguage) {
      'zh' => 'zh-CN,zh;q=0.9,en;q=0.7',
      'ja' => 'ja-JP,ja;q=0.9,en;q=0.7',
      'de' => 'de-DE,de;q=0.9,en;q=0.7',
      'fr' => 'fr-FR,fr;q=0.9,en;q=0.7',
      'es' => 'es-ES,es;q=0.9,en;q=0.7',
      'ru' => 'ru-RU,ru;q=0.9,en;q=0.7',
      _ => google ? 'en-US,en;q=0.9' : 'en-US,en;q=0.9,zh;q=0.5',
    };
  }

  String _googleHlParam() {
    return switch (_normalizedUiLanguage) {
      'zh' => 'zh-CN',
      'ja' => 'ja',
      'de' => 'de',
      'fr' => 'fr',
      'es' => 'es',
      'ru' => 'ru',
      _ => 'en',
    };
  }

  String _googleGlParam() {
    return switch (_normalizedUiLanguage) {
      'zh' => 'cn',
      'ja' => 'jp',
      'de' => 'de',
      'fr' => 'fr',
      'es' => 'es',
      'ru' => 'ru',
      _ => 'us',
    };
  }

  Map<String, String> _htmlHeaders({String? referer, bool google = false}) {
    final headers = <String, String>{
      'User-Agent': _reverseImageUserAgent,
      'Accept': 'text/html,application/xhtml+xml,*/*',
      'Accept-Language': _acceptLanguageHeader(google: google),
    };
    if (referer != null) {
      headers['Referer'] = referer;
    }
    return headers;
  }

  Map<String, String> _jsonHeaders({
    String? referer,
    String? origin,
    bool google = false,
  }) {
    final headers = <String, String>{
      'User-Agent': _reverseImageUserAgent,
      'Accept': 'application/json,text/plain,*/*',
      'Accept-Language': _acceptLanguageHeader(google: google),
    };
    if (referer != null) {
      headers['Referer'] = referer;
    }
    if (origin != null) {
      headers['Origin'] = origin;
    }
    return headers;
  }

  bool _isGoogleSearchHostName(String host) {
    final normalized = host.toLowerCase();
    return normalized == 'google.com' ||
        normalized == 'www.google.com' ||
        normalized.startsWith('www.google.') ||
        normalized.startsWith('google.');
  }

  Uri _withGoogleLanguageParams(Uri uri) {
    final host = uri.host.toLowerCase();
    final isGoogleHost = _isGoogleSearchHostName(host);
    final isLensHost = host == 'lens.google.com';
    if (!isGoogleHost && !isLensHost) {
      return uri;
    }

    final query = <String, String>{...uri.queryParameters};
    query['hl'] = _googleHlParam();
    query['gl'] = _googleGlParam();
    return uri.replace(queryParameters: query);
  }

  @override
  Widget build(BuildContext context) {
    final stageText = _stageLabel(context);
    return ToolboxToolPage(
      title: _lifeI18nText(
        context,
        'inline.plan295.life.reverse_image.c5edca6a6947',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.aggregate_linked_engines_and_show_un.64d754de340f',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildInputPanel(context),
          const SizedBox(height: 12),
          _buildEnginePanel(context),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: FilledButton.icon(
                  key: const ValueKey<String>(
                    'life_reverse_image_search_button',
                  ),
                  onPressed: _busy ? null : _startSearch,
                  icon: _busy
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.image_search_rounded),
                  label: Text(
                    _busy
                        ? _lifeI18nText(
                            context,
                            'inline.plan295.life.searching.5424fa75a5ab',
                          )
                        : _lifeI18nText(
                            context,
                            'inline.plan295.life.run_search.c6c7ff41669c',
                          ),
                  ),
                ),
              ),
              if (_resolvedImageUri != null) ...<Widget>[
                const SizedBox(width: 10),
                IconButton.filledTonal(
                  tooltip: _lifeI18nText(
                    context,
                    'inline.plan295.life.open_resolved_image_url.0523ec13db41',
                  ),
                  onPressed: () =>
                      _openExternal(context, _resolvedImageUri!.toString()),
                  icon: const Icon(Icons.image_outlined),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text(stageText, style: Theme.of(context).textTheme.bodySmall),
          if (_lastError != null) ...<Widget>[
            const SizedBox(height: 10),
            _buildErrorPanel(context),
          ],
          const SizedBox(height: 12),
          _buildResultsPanel(context),
          const SizedBox(height: 12),
          _buildSourcePanel(context),
        ],
      ),
    );
  }

  Widget _buildInputPanel(BuildContext context) {
    final theme = Theme.of(context);
    return _LifeSettingsPanel(
      title: _lifeI18nText(
        context,
        'inline.plan295.life.image_source.fed984e77bad',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.local_images_prefer_direct_baidu_upl.b2c505497b15',
      ),
      children: <Widget>[
        TextField(
          key: const ValueKey<String>('life_reverse_image_url_field'),
          controller: _imageUrlController,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: _lifeI18nText(
              context,
              'inline.plan295.life.public_image_url_optional.ebcc7c9d8fcb',
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (_selectedImagePath != null)
          _LifePreviewFrame(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _lifeI18nText(
                    context,
                    'inline.plan296.ui.pages.toolbox.life.tools.toolbox.life.tools.reverse.image.selected.5f7dbaecc6',
                    params: <String, Object?>{
                      'p0': _selectedImageName ?? _selectedImagePath!,
                    },
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                AspectRatio(
                  aspectRatio: 1,
                  child: Image.file(
                    File(_selectedImagePath!),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Text(
                          _lifeI18nText(
                            context,
                            'inline.plan295.life.preview_failed_pick_the_image_again.2b738c001158',
                          ),
                          style: theme.textTheme.bodySmall,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            Expanded(
              child: FilledButton.tonalIcon(
                key: const ValueKey<String>('life_reverse_image_pick_button'),
                onPressed: _busy ? null : _pickImage,
                icon: const Icon(Icons.photo_library_rounded),
                label: Text(
                  _lifeI18nText(
                    context,
                    'inline.plan295.life.pick_image.9ce43eb388b3',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filledTonal(
              tooltip: _lifeI18nText(
                context,
                'inline.plan295.life.clear_image.ffa3b6e8a706',
              ),
              onPressed: _busy
                  ? null
                  : () {
                      setState(() {
                        _selectedImagePath = null;
                        _selectedImageName = null;
                        _lastError = null;
                        _resolvedImageUri = null;
                        _usedLegacyUploadFallback = false;
                        _results = const <_ReverseImageEngineResult>[];
                        _visibleResultCountByEngine = <String, int>{};
                        _loadingMoreEngineIds = <String>{};
                        _stage = _ReverseImageStage.idle;
                      });
                    },
              icon: const Icon(Icons.clear_rounded),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEnginePanel(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeI18nText(
        context,
        'inline.plan295.life.aggregated_engines.4c2d8cb3bfe5',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.baidu_sogou_google_lens_and_yandex_a.b6ec02824730',
      ),
      children: <Widget>[
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _reverseImageEngines
              .map((engine) {
                return Chip(
                  avatar: const Icon(Icons.search_rounded, size: 16),
                  label: Text(engine.label(context)),
                );
              })
              .toList(growable: false),
        ),
      ],
    );
  }

  Widget _buildErrorPanel(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _lifeI18nText(
          context,
          'inline.plan296.ui.pages.toolbox.life.tools.toolbox.life.tools.reverse.image.aggregation_failed.59ef2d5565',
          params: <String, Object?>{'_lastError': _lastError},
        ),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onErrorContainer,
        ),
      ),
    );
  }

  Widget _buildResultsPanel(BuildContext context) {
    if (_results.isEmpty) {
      return _LifeSettingsPanel(
        title: _lifeI18nText(
          context,
          'inline.plan295.life.aggregated_results.1e856ca9e54b',
        ),
        subtitle: _lifeI18nText(
          context,
          'inline.plan295.life.engine_results_will_be_shown_in_a_un.6c44bb5e49f2',
        ),
        children: const <Widget>[],
      );
    }

    return _LifeSettingsPanel(
      title: _lifeI18nText(
        context,
        'inline.plan295.life.aggregated_results.1e856ca9e54b',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan296.ui.pages.toolbox.life.tools.toolbox.life.tools.reverse.image.engines_succeeded_with_entries.d49d89aaaf',
        params: <String, Object?>{
          '_successCount': _successCount,
          'length': _results.length,
          '_totalEntries': _totalEntries,
          'p3': _usedLegacyUploadFallback ? '（已使用临时上传兜底）' : '',
          'p4': _usedLegacyUploadFallback
              ? ' (temporary upload fallback used)'
              : '',
        },
      ),
      children: <Widget>[
        for (final result in _results) _buildEngineResultCard(context, result),
      ],
    );
  }

  Widget _buildEngineResultCard(
    BuildContext context,
    _ReverseImageEngineResult result,
  ) {
    final status = _statusMeta(context, result);
    final elapsedText = '${result.elapsed.inMilliseconds}ms';
    final visibleCount = _visibleCountForResult(result);
    final hasHiddenLocal = result.items.length > visibleCount;
    final canLoadFromSource = _hasRemoteMoreForResult(result);
    final loadingMore = _loadingMoreEngineIds.contains(result.engine.id);
    return Card(
      key: ValueKey<String>('life_reverse_image_result_${result.engine.id}'),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    result.engine.label(context),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: status.$1.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    status.$2,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: status.$1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              _engineSummary(context, result),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 6),
            Row(
              children: <Widget>[
                Text(
                  _lifeI18nText(
                    context,
                    'inline.plan296.ui.pages.toolbox.life.tools.toolbox.life.tools.reverse.image.elapsed.8cdbd72443',
                    params: <String, Object?>{'elapsedText': elapsedText},
                  ),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const Spacer(),
                IconButton(
                  tooltip: _lifeI18nText(
                    context,
                    'inline.plan295.life.open_result.00ed4e986374',
                  ),
                  onPressed: () =>
                      _openExternal(context, result.resultUri.toString()),
                  icon: const Icon(Icons.open_in_new_rounded),
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (result.items.isEmpty)
              Text(
                _lifeI18nText(
                  context,
                  'inline.plan295.life.no_structured_entries_parsed_open_th.5fa2dc22d5a5',
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            for (final item in result.items.take(visibleCount))
              _buildResultItemTile(context, item),
            if (hasHiddenLocal || canLoadFromSource)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    key: ValueKey<String>(
                      'life_reverse_image_load_more_${result.engine.id}',
                    ),
                    onPressed: loadingMore
                        ? null
                        : () => _loadMoreResultsForEngine(result),
                    icon: loadingMore
                        ? const SizedBox.square(
                            dimension: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.expand_more_rounded),
                    label: Text(
                      loadingMore
                          ? _lifeI18nText(context, 'toolbox.sleep.core.loading')
                          : hasHiddenLocal
                          ? _lifeI18nText(
                              context,
                              'inline.plan295.life.load_more_result_items_length_visibl.bcb782963be0',
                              params: <String, Object?>{
                                'result.items.length - visibleCount':
                                    result.items.length - visibleCount,
                              },
                            )
                          : _lifeI18nText(
                              context,
                              'inline.plan295.life.load_more_from_source_site.e744df7fdb3c',
                            ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultItemTile(
    BuildContext context,
    _ReverseImageResultItem item,
  ) {
    final previewUri = _parseHttpUri(item.previewUrl);
    final sourceUri = _parseHttpUri(item.sourceUrl);
    final imageUri = _parseHttpUri(item.imageUrl);
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.45,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 72,
              height: 72,
              color: theme.colorScheme.surfaceContainer,
              child: previewUri == null
                  ? Icon(
                      Icons.image_not_supported_outlined,
                      color: theme.colorScheme.outline,
                    )
                  : Image.network(
                      previewUri.toString(),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.broken_image_outlined,
                          color: theme.colorScheme.outline,
                        );
                      },
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.title.trim().isEmpty
                      ? _lifeI18nText(
                          context,
                          'inline.plan295.life.untitled_result.1b602e512c60',
                        )
                      : item.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.sourceSite.trim().isEmpty
                      ? _lifeI18nText(
                          context,
                          'inline.plan295.life.unknown_source_site.68eec2884254',
                        )
                      : item.sourceSite,
                  style: theme.textTheme.labelMedium,
                ),
                if (item.snippet.trim().isNotEmpty) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(item.snippet, style: theme.textTheme.bodySmall),
                ],
                const SizedBox(height: 4),
                Row(
                  children: <Widget>[
                    if (sourceUri != null)
                      IconButton(
                        tooltip: _lifeI18nText(
                          context,
                          'inline.plan295.life.open_source_url.0ccf29cc9e2e',
                        ),
                        onPressed: () =>
                            _openExternal(context, sourceUri.toString()),
                        icon: const Icon(Icons.open_in_new_rounded),
                      ),
                    if (imageUri != null)
                      IconButton(
                        tooltip: _lifeI18nText(
                          context,
                          'inline.plan295.life.open_image_url.7f732f74c611',
                        ),
                        onPressed: () =>
                            _openExternal(context, imageUri.toString()),
                        icon: const Icon(Icons.image_outlined),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourcePanel(BuildContext context) {
    final sourceTool = _lifeTools.firstWhere(
      (tool) => tool.id == 'reverse_image',
      orElse: () => const _LifeTool(
        id: 'reverse_image',
        titleKey: 'inline.plan295.life.reverse_image.c5edca6a6947',
        summaryKey: 'arb.all',
        category: 'web',
        icon: Icons.image_search_rounded,
      ),
    );

    if (sourceTool.sources.isEmpty) {
      return const SizedBox.shrink();
    }

    return _LifeSettingsPanel(
      title: _lifeI18nText(
        context,
        'inline.plan295.life.source_links.31a99f45d66b',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.if_an_engine_changes_its_strategy_op.4b5ef29295e4',
      ),
      children: <Widget>[
        for (final source in sourceTool.sources)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(source.name),
            subtitle: Text(source.url),
            trailing: const Icon(Icons.open_in_new_rounded),
            onTap: () => _openExternal(context, source.url),
          ),
      ],
    );
  }

  Future<void> _pickImage() async {
    final picked = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.image,
    );
    if (!mounted || picked == null || picked.files.isEmpty) {
      return;
    }
    final file = picked.files.first;
    final filePath = file.path;
    if (filePath == null || filePath.trim().isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _lifeI18nText(
              context,
              'inline.plan295.life.failed_to_read_file_path_please_retr.79be80c28b68',
            ),
          ),
        ),
      );
      return;
    }

    setState(() {
      _selectedImagePath = filePath;
      _selectedImageName = file.name;
      _lastError = null;
      _resolvedImageUri = null;
      _usedLegacyUploadFallback = false;
      _results = const <_ReverseImageEngineResult>[];
      _visibleResultCountByEngine = <String, int>{};
      _loadingMoreEngineIds = <String>{};
      _stage = _ReverseImageStage.idle;
    });
  }

  Future<void> _startSearch() async {
    final manualInput = _imageUrlController.text.trim();
    final manualImageUri = _parseHttpUri(manualInput);
    if (_selectedImagePath == null && manualImageUri == null) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _lifeI18nText(
              context,
              'inline.plan295.life.pick_an_image_first_or_provide_a_pub.62baaede8c59',
            ),
          ),
        ),
      );
      return;
    }

    setState(() {
      _busy = true;
      _lastError = null;
      _resolvedImageUri = null;
      _usedLegacyUploadFallback = false;
      _results = const <_ReverseImageEngineResult>[];
      _visibleResultCountByEngine = <String, int>{};
      _loadingMoreEngineIds = <String>{};
      _stage = _ReverseImageStage.preparing;
    });

    try {
      final prepared = await _prepareSearch(manualImageUri);
      if (!mounted) {
        return;
      }

      setState(() {
        _resolvedImageUri = prepared.urlSearchImageUri;
        _usedLegacyUploadFallback = prepared.usedLegacyUploadFallback;
        _stage = _ReverseImageStage.searching;
      });

      final futures = _reverseImageEngines
          .where((engine) {
            if (prepared.directBaiduResult == null) {
              return true;
            }
            return engine.id != 'baidu';
          })
          .map((engine) {
            final imageUri = prepared.imageUriForEngine(engine.id);
            return _searchWithUrlEngine(engine, imageUri);
          });
      final urlResults = await Future.wait(futures);

      if (!mounted) {
        return;
      }

      final merged = <_ReverseImageEngineResult>[
        if (prepared.directBaiduResult != null) prepared.directBaiduResult!,
        ...urlResults,
      ];

      setState(() {
        _results = merged;
        _visibleResultCountByEngine = <String, int>{
          for (final result in merged)
            result.engine.id: _initialVisibleCount(result.items.length),
        };
        _stage = _ReverseImageStage.done;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _lastError = error;
        _stage = _ReverseImageStage.failed;
      });
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<_ReverseImagePreparedSearch> _prepareSearch(
    Uri? manualImageUri,
  ) async {
    if (_selectedImagePath == null) {
      final resolvedManualUri = manualImageUri!;
      return _ReverseImagePreparedSearch(
        urlSearchImageUri: resolvedManualUri,
        usedLegacyUploadFallback: false,
        searchUriOverrides: <String, Uri>{
          'sogou': _toSogouQueryImageUri(resolvedManualUri),
        },
      );
    }

    final file = File(_selectedImagePath!);
    if (!await file.exists()) {
      throw FileSystemException('File does not exist', _selectedImagePath);
    }

    setState(() => _stage = _ReverseImageStage.directUploading);
    final searchUriOverrides = <String, Uri>{};
    try {
      searchUriOverrides['sogou'] = await _uploadFileToSogouQueryUri(file);
    } catch (_) {
      // Fallback to URL proxy mode if direct upload is unavailable.
    }

    _ReverseImageEngineResult? directBaiduResult;
    try {
      directBaiduResult = await _searchWithBaiduDirect(file);
    } catch (_) {
      directBaiduResult = null;
    }

    if (directBaiduResult != null &&
        directBaiduResult.success &&
        directBaiduResult.derivedImageUri != null) {
      return _ReverseImagePreparedSearch(
        urlSearchImageUri: directBaiduResult.derivedImageUri!,
        searchUriOverrides: searchUriOverrides,
        directBaiduResult: directBaiduResult,
        usedLegacyUploadFallback: false,
      );
    }

    setState(() => _stage = _ReverseImageStage.resolvingPublicUrl);
    final uploadedUri = await _uploadFileToPublicUrl(file);
    return _ReverseImagePreparedSearch(
      urlSearchImageUri: uploadedUri,
      searchUriOverrides: <String, Uri>{
        ...searchUriOverrides,
        if (!searchUriOverrides.containsKey('sogou'))
          'sogou': _toSogouQueryImageUri(uploadedUri),
      },
      directBaiduResult: directBaiduResult != null && directBaiduResult.success
          ? directBaiduResult
          : null,
      usedLegacyUploadFallback: true,
    );
  }

  Future<_ReverseImageEngineResult> _searchWithBaiduDirect(File file) async {
    final engine = _reverseImageEngines.firstWhere(
      (item) => item.id == 'baidu',
    );
    final watch = Stopwatch()..start();

    try {
      final searchUri = await _uploadFileToBaidu(file);
      if (mounted) {
        setState(() => _stage = _ReverseImageStage.parsingDirectResult);
      }
      final response = await http
          .get(searchUri, headers: _htmlHeaders())
          .timeout(_reverseImageSearchTimeout);
      final html = utf8.decode(response.bodyBytes, allowMalformed: true);
      final payload = await _parseBaiduStructuredPayload(
        html,
        response.request?.url ?? searchUri,
      );

      watch.stop();
      return _ReverseImageEngineResult(
        engine: engine,
        requestUri: searchUri,
        resultUri: response.request?.url ?? searchUri,
        elapsed: watch.elapsed,
        statusCode: response.statusCode,
        items: payload.items,
        manualOnly: false,
        usedDirectUpload: true,
        noResultHint: _hasNoResultHint(html),
        derivedImageUri: payload.publicImageUri,
        error: response.statusCode >= 200 && response.statusCode < 400
            ? null
            : HttpException('HTTP ${response.statusCode}'),
      );
    } catch (error) {
      watch.stop();
      return _ReverseImageEngineResult(
        engine: engine,
        requestUri: Uri.https('graph.baidu.com', '/'),
        resultUri: Uri.https('graph.baidu.com', '/'),
        elapsed: watch.elapsed,
        statusCode: null,
        items: const <_ReverseImageResultItem>[],
        manualOnly: false,
        usedDirectUpload: true,
        noResultHint: false,
        error: error,
      );
    }
  }

  Future<Uri> _uploadFileToBaidu(File file) async {
    final uploadUri = Uri.parse(
      '$_reverseImageBaiduUploadEndpoint?uptime=${DateTime.now().millisecondsSinceEpoch}',
    );
    final request = http.MultipartRequest('POST', uploadUri);
    request.headers.addAll(const <String, String>{
      'User-Agent': _reverseImageUserAgent,
      'Accept': 'application/json,text/plain,*/*',
      'Acs-Token': '601',
    });
    request.fields['tn'] = 'pc';
    request.fields['from'] = 'pc';
    request.fields['image_source'] = 'PC_UPLOAD_FILE';
    request.files.add(
      await http.MultipartFile.fromPath(
        'image',
        file.path,
        filename: path.basename(file.path),
      ),
    );

    final response = await request.send().timeout(_reverseImageUploadTimeout);
    final body = await response.stream.bytesToString();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('Baidu upload failed: HTTP ${response.statusCode}');
    }

    final decoded = jsonDecode(body);
    if (decoded is! Map) {
      throw const FormatException('Baidu upload response is not a JSON map.');
    }
    final status = decoded['status'];
    final data = decoded['data'];
    if (status != 0 || data is! Map) {
      throw const FormatException(
        'Baidu upload did not return success payload.',
      );
    }
    final searchUrl = data['url']?.toString().trim() ?? '';
    final searchUri = _parseHttpUri(searchUrl);
    if (searchUri == null) {
      throw const FormatException(
        'Baidu upload returned an invalid search URL.',
      );
    }
    return searchUri;
  }

  Future<_BaiduStructuredPayload> _parseBaiduStructuredPayload(
    String html,
    Uri baseUri,
  ) async {
    final items = <_ReverseImageResultItem>[];
    Uri? publicImageUri;

    final cardDataRaw = _extractScriptJsonBlock(
      html,
      marker: 'window.cardData',
      openChar: '[',
      closeChar: ']',
    );
    if (cardDataRaw != null) {
      final decoded = jsonDecode(cardDataRaw);
      if (decoded is List) {
        int rank = 0;
        Uri? simipicFirstUri;
        for (final rawCard in decoded) {
          if (rawCard is! Map) {
            continue;
          }
          final cardName = rawCard['cardName']?.toString() ?? '';
          final tplData = rawCard['tplData'];
          if (tplData is! Map) {
            continue;
          }

          if (cardName == 'cardHeader') {
            final imageUrl = tplData['imageUrl']?.toString() ?? '';
            publicImageUri ??= _parseHttpUri(imageUrl);
            continue;
          }

          if (cardName == 'same') {
            final list = tplData['list'];
            if (list is List) {
              for (final raw in list) {
                if (raw is! Map) {
                  continue;
                }
                final sourceUrl = _normalizeUrl(raw['url']) ?? '';
                final imageUrl = _normalizeUrl(raw['image_src']) ?? '';
                items.add(
                  _ReverseImageResultItem(
                    kind: _ReverseImageResultKind.source,
                    title: _firstNonEmpty(<String>[
                      raw['title']?.toString() ?? '',
                      raw['text']?.toString() ?? '',
                    ]),
                    sourceSite: _firstNonEmpty(<String>[
                      raw['website']?.toString() ?? '',
                      _hostFromUrl(sourceUrl),
                    ]),
                    sourceUrl: sourceUrl,
                    imageUrl: imageUrl,
                    previewUrl: imageUrl,
                    snippet: _firstNonEmpty(<String>[
                      raw['abstract']?.toString() ?? '',
                      raw['desc']?.toString() ?? '',
                    ]),
                    rawType: cardName,
                    rank: rank++,
                  ),
                );
              }
            }
            continue;
          }

          if (cardName == 'product') {
            final list = tplData['list'];
            if (list is List) {
              for (final raw in list) {
                if (raw is! Map) {
                  continue;
                }
                final sourceUrl = _normalizeUrl(raw['buyurl']) ?? '';
                final imageUrl = _normalizeUrl(raw['imgurl']) ?? '';
                final price = raw['text']?.toString() ?? '';
                final comments = raw['comments']?.toString() ?? '';
                final snippet = <String>[
                  price,
                  comments,
                ].where((part) => part.trim().isNotEmpty).join('  ');
                items.add(
                  _ReverseImageResultItem(
                    kind: _ReverseImageResultKind.product,
                    title: _firstNonEmpty(<String>[
                      raw['desc']?.toString() ?? '',
                      raw['title']?.toString() ?? '',
                      raw['text']?.toString() ?? '',
                    ]),
                    sourceSite: _firstNonEmpty(<String>[
                      raw['source']?.toString() ?? '',
                      _hostFromUrl(sourceUrl),
                    ]),
                    sourceUrl: sourceUrl,
                    imageUrl: imageUrl,
                    previewUrl: imageUrl,
                    snippet: snippet,
                    rawType: cardName,
                    rank: rank++,
                  ),
                );
              }
            }
            continue;
          }

          if (cardName == 'simipic') {
            final imageUrl = _normalizeUrl(tplData['imageUrl']) ?? '';
            publicImageUri ??= _parseHttpUri(imageUrl);
            final firstUrl = _normalizeUrl(tplData['firstUrl']);
            if (firstUrl != null) {
              simipicFirstUri = _resolveUri(baseUri, firstUrl);
            }
          }
        }

        if (simipicFirstUri != null) {
          final simipicItems = await _loadBaiduSimipicItems(simipicFirstUri);
          items.addAll(
            simipicItems.map((item) {
              return item.copyWith(rank: rank + item.rank);
            }),
          );
          rank += simipicItems.length;
        }
      }
    }

    final extDataRaw = _extractScriptJsonBlock(
      html,
      marker: 'window.extData',
      openChar: '{',
      closeChar: '}',
    );
    if (extDataRaw != null) {
      final decoded = jsonDecode(extDataRaw);
      if (decoded is Map) {
        final share = decoded['share'];
        if (share is Map) {
          publicImageUri ??= _parseHttpUri(share['shareImg']?.toString() ?? '');
        }
      }
    }

    final deduped = _dedupeResultItems(items);
    return _BaiduStructuredPayload(
      items: deduped,
      publicImageUri: publicImageUri,
    );
  }

  Future<List<_ReverseImageResultItem>> _loadBaiduSimipicItems(Uri uri) async {
    try {
      final response = await http
          .get(uri, headers: _jsonHeaders())
          .timeout(_reverseImageParseTimeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return const <_ReverseImageResultItem>[];
      }
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map) {
        return const <_ReverseImageResultItem>[];
      }
      final data = decoded['data'];
      if (data is! Map) {
        return const <_ReverseImageResultItem>[];
      }
      final list = data['list'];
      if (list is! List) {
        return const <_ReverseImageResultItem>[];
      }
      final items = <_ReverseImageResultItem>[];
      int rank = 0;
      for (final raw in list) {
        if (raw is! Map) {
          continue;
        }
        final sourceUrl = _normalizeUrl(raw['fromUrl']) ?? '';
        final imageUrl = _normalizeUrl(raw['objUrl']) ?? '';
        final previewUrl = _normalizeUrl(raw['thumbUrl']) ?? '';
        final width = raw['width']?.toString() ?? '';
        final height = raw['height']?.toString() ?? '';
        final sizeText = width.isNotEmpty && height.isNotEmpty
            ? '$width x $height'
            : '';

        items.add(
          _ReverseImageResultItem(
            kind: _ReverseImageResultKind.similar,
            title: _firstNonEmpty(<String>[
              _hostFromUrl(sourceUrl),
              'Similar image',
            ]),
            sourceSite: _hostFromUrl(sourceUrl),
            sourceUrl: sourceUrl,
            imageUrl: imageUrl,
            previewUrl: previewUrl,
            snippet: sizeText,
            rawType: 'simipic',
            rank: rank++,
          ),
        );
      }
      return items;
    } catch (_) {
      return const <_ReverseImageResultItem>[];
    }
  }

  Future<_ReverseImageEngineResult> _searchWithUrlEngine(
    _ReverseImageEngine engine,
    Uri imageUri,
  ) async {
    final watch = Stopwatch()..start();
    final queryImageUri = engine.id == 'sogou'
        ? _toSogouQueryImageUri(imageUri)
        : imageUri;
    final requestUri = engine.buildSearchUri(queryImageUri);
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);

    try {
      Uri effectiveRequestUri = requestUri;
      if (engine.id == 'google_lens' && _isGoogleVsridUri(requestUri)) {
        effectiveRequestUri = requestUri;
      } else if (engine.id == 'google_lens') {
        effectiveRequestUri = await _resolveGoogleSearchUri(
          lensUri: requestUri,
        );
        if (!_isGoogleVsridUri(effectiveRequestUri)) {
          effectiveRequestUri = requestUri;
        }
      }

      effectiveRequestUri = engine.id == 'google_lens'
          ? _withGoogleLanguageParams(effectiveRequestUri)
          : effectiveRequestUri;

      final response = await http
          .get(
            effectiveRequestUri,
            headers: _htmlHeaders(google: engine.id == 'google_lens'),
          )
          .timeout(
            engine.id == 'google_lens'
                ? _reverseImageGoogleRequestTimeout
                : _reverseImageSearchTimeout,
          );

      final html = utf8.decode(response.bodyBytes, allowMalformed: true);
      final resultUri = response.request?.url ?? effectiveRequestUri;
      final noResultHint = _hasNoResultHint(html);
      Uri? derivedImageUri;
      _ReverseImagePagingCursor? pagingCursor;
      List<_ReverseImageResultItem> items;
      if (engine.id == 'baidu') {
        final payload = await _parseBaiduStructuredPayload(html, resultUri);
        items = payload.items;
        derivedImageUri = payload.publicImageUri;
      } else if (engine.id == 'sogou') {
        final payload = await _parseSogouStructuredItems(
          html: html,
          resultUri: resultUri,
          queryImageUri: queryImageUri,
        );
        items = payload.items;
        pagingCursor = payload.pagingCursor;
      } else if (engine.id == 'google_lens') {
        final payload = _parseGoogleStructuredItems(
          html: html,
          resultUri: resultUri,
          queryImageUri: imageUri,
        );
        items = payload.items;
        final nextPageUri = payload.nextPageUri == null
            ? null
            : _withGoogleLanguageParams(payload.nextPageUri!);
        if (nextPageUri != null) {
          pagingCursor = _ReverseImagePagingCursor(
            kind: _ReverseImagePagingKind.googleSearchPage,
            query: nextPageUri.toString(),
            plevel: '',
            nextStart: 0,
            hasMore: true,
          );
        }
      } else {
        items = _buildGenericItemsFromHtml(
          html: html,
          resultUri: resultUri,
          queryImageUri: imageUri,
        );
      }
      items = _dedupeResultItems(items);

      if (items.isEmpty) {
        items = _fallbackPageItem(
          resultUri: resultUri,
          imageUri: imageUri,
          html: html,
          noResultHint: noResultHint,
        );
      }

      final isHttpSuccess =
          response.statusCode >= 200 && response.statusCode < 400;
      if (engine.id == 'google_lens' && !isHttpSuccess) {
        watch.stop();
        return _buildManualEngineResult(
          engine: engine,
          requestUri: effectiveRequestUri,
          resultUri: resultUri,
          imageUri: imageUri,
          elapsed: watch.elapsed,
          statusCode: response.statusCode,
          message: i18n.t(
            'toolbox.life.reverse_image.google_http_manual',
            params: <String, Object?>{'statusCode': response.statusCode},
          ),
        );
      }

      watch.stop();
      return _ReverseImageEngineResult(
        engine: engine,
        requestUri: effectiveRequestUri,
        resultUri: resultUri,
        elapsed: watch.elapsed,
        statusCode: response.statusCode,
        items: items,
        manualOnly: false,
        usedDirectUpload: false,
        noResultHint: noResultHint,
        pagingCursor: pagingCursor,
        derivedImageUri: derivedImageUri,
        error: isHttpSuccess
            ? null
            : HttpException('HTTP ${response.statusCode}'),
      );
    } catch (error) {
      watch.stop();
      if (engine.id == 'google_lens') {
        return _buildManualEngineResult(
          engine: engine,
          requestUri: requestUri,
          resultUri: requestUri,
          imageUri: imageUri,
          elapsed: watch.elapsed,
          statusCode: null,
          message: i18n.t('toolbox.life.reverse_image.google_timeout_manual'),
        );
      }
      return _ReverseImageEngineResult(
        engine: engine,
        requestUri: requestUri,
        resultUri: requestUri,
        elapsed: watch.elapsed,
        statusCode: null,
        items: const <_ReverseImageResultItem>[],
        manualOnly: false,
        usedDirectUpload: false,
        noResultHint: false,
        pagingCursor: null,
        error: error,
      );
    }
  }

  _ReverseImageEngineResult _buildManualEngineResult({
    required _ReverseImageEngine engine,
    required Uri requestUri,
    required Uri resultUri,
    required Uri imageUri,
    required Duration elapsed,
    required int? statusCode,
    required String message,
  }) {
    return _ReverseImageEngineResult(
      engine: engine,
      requestUri: requestUri,
      resultUri: resultUri,
      elapsed: elapsed,
      statusCode: statusCode,
      items: <_ReverseImageResultItem>[
        _ReverseImageResultItem(
          kind: _ReverseImageResultKind.page,
          title: engine.label(context),
          sourceSite: resultUri.host,
          sourceUrl: resultUri.toString(),
          imageUrl: imageUri.toString(),
          previewUrl: imageUri.toString(),
          snippet: message,
          rawType: 'manual',
          rank: 0,
        ),
      ],
      manualOnly: true,
      usedDirectUpload: false,
      noResultHint: false,
      pagingCursor: null,
      derivedImageUri: null,
      error: null,
    );
  }

  Future<Uri> _resolveGoogleSearchUri({required Uri lensUri}) async {
    if (_isGoogleVsridUri(lensUri)) {
      return lensUri;
    }
    try {
      final response = await http
          .get(
            _withGoogleLanguageParams(lensUri),
            headers: _htmlHeaders(google: true),
          )
          .timeout(_reverseImageGoogleResolveTimeout);
      final redirected = response.request?.url;
      if (_isGoogleVsridUri(redirected)) {
        return _withGoogleLanguageParams(redirected!);
      }

      final html = utf8.decode(response.bodyBytes, allowMalformed: true);
      final absoluteMatch = RegExp(
        r'''https:\/\/www\.google\.com\/search\?[^"'\s<]*vsrid=[^"'\s<]+''',
        caseSensitive: false,
      ).firstMatch(html);
      if (absoluteMatch != null) {
        final normalized = absoluteMatch.group(0)!.replaceAll(r'\/', '/');
        final uri = _parseHttpUri(normalized);
        if (_isGoogleVsridUri(uri)) {
          return _withGoogleLanguageParams(uri!);
        }
      }

      final vsridMatch = RegExp(r'vsrid=([A-Za-z0-9._%-]+)').firstMatch(html);
      if (vsridMatch != null) {
        return Uri.https('www.google.com', '/search', <String, String>{
          'vsrid': vsridMatch.group(1)!,
          'hl': _googleHlParam(),
          'gl': _googleGlParam(),
        });
      }

      return lensUri;
    } catch (_) {
      return lensUri;
    }
  }

  bool _isGoogleVsridUri(Uri? uri) {
    if (uri == null) {
      return false;
    }
    final host = uri.host.toLowerCase();
    if (!_isGoogleSearchHostName(host) || uri.path != '/search') {
      return false;
    }
    final token = uri.queryParameters['vsrid']?.trim() ?? '';
    return token.isNotEmpty;
  }

  Future<_SogouStructuredPayload> _parseSogouStructuredItems({
    required String html,
    required Uri resultUri,
    required Uri queryImageUri,
  }) async {
    final noResultHint = _hasNoResultHint(html);
    bool forbid = false;
    final routeQuery = <String, String>{};
    final items = <_ReverseImageResultItem>[];
    _ReverseImagePagingCursor? pagingCursor;

    final initialStateRaw = _extractScriptJsonBlock(
      html,
      marker: 'window.__INITIAL_STATE__',
      openChar: '{',
      closeChar: '}',
    );
    if (initialStateRaw != null) {
      try {
        final decoded = jsonDecode(initialStateRaw);
        if (decoded is Map) {
          final route = decoded['route'];
          if (route is Map) {
            final query = route['query'];
            if (query is Map) {
              for (final entry in query.entries) {
                final key = entry.key?.toString().trim() ?? '';
                final value = entry.value?.toString().trim() ?? '';
                if (key.isNotEmpty && value.isNotEmpty) {
                  routeQuery[key] = value;
                }
              }
            }
          }

          final risDetail = decoded['risDetail'];
          if (risDetail is Map) {
            final config = risDetail['config'];
            if (config is Map) {
              forbid = config['forbid'] == true;
            }
            final risResult = risDetail['risResult'];
            if (risResult != null) {
              items.addAll(
                _parseSogouRisPayload(payload: risResult, resultUri: resultUri),
              );
              final apiQuery = _firstNonEmpty(<String>[
                routeQuery['query'] ?? '',
                resultUri.queryParameters['query'] ?? '',
              ]);
              pagingCursor = _buildSogouPagingCursorFromPayload(
                payload: risResult,
                query: apiQuery,
              );
            }
          }
        }
      } catch (_) {
        // Ignore malformed script payload.
      }
    }

    if (items.isEmpty) {
      final payload = await _loadSogouRisApiItems(
        routeQuery: routeQuery,
        resultUri: resultUri,
      );
      items.addAll(payload.items);
      pagingCursor ??= payload.pagingCursor;
    }

    if (items.isEmpty) {
      final apiQuery = _firstNonEmpty(<String>[
        routeQuery['query'] ?? '',
        resultUri.queryParameters['query'] ?? '',
        queryImageUri.toString(),
      ]);
      if (apiQuery.isNotEmpty) {
        pagingCursor ??= _ReverseImagePagingCursor(
          kind: _ReverseImagePagingKind.sogouSim,
          query: apiQuery,
          plevel: '-1',
          nextStart: 0,
          hasMore: true,
        );
      }
    }

    if (items.isEmpty && !forbid && !noResultHint) {
      items.addAll(
        _buildGenericItemsFromHtml(
          html: html,
          resultUri: resultUri,
          queryImageUri: queryImageUri,
        ),
      );
    }

    return _SogouStructuredPayload(
      items: _dedupeResultItems(items),
      pagingCursor: pagingCursor,
    );
  }

  _ReverseImagePagingCursor? _buildSogouPagingCursorFromPayload({
    required Object payload,
    required String query,
  }) {
    if (query.trim().isEmpty || payload is! Map) {
      return null;
    }
    final sim = payload['sim'];
    if (sim is! Map) {
      return null;
    }
    final rawItems = sim['items'];
    if (rawItems is! List || rawItems.isEmpty) {
      return null;
    }
    final plevel = payload['plevel']?.toString().trim() ?? '-1';
    return _ReverseImagePagingCursor(
      kind: _ReverseImagePagingKind.sogouSim,
      query: query.trim(),
      plevel: plevel.isEmpty ? '-1' : plevel,
      nextStart: rawItems.length,
      hasMore: true,
    );
  }

  Future<_SogouStructuredPayload> _loadSogouRisApiItems({
    required Map<String, String> routeQuery,
    required Uri resultUri,
  }) async {
    final query = <String, String>{
      if (routeQuery.isNotEmpty)
        ...routeQuery
      else
        ...resultUri.queryParameters,
    };
    query.removeWhere((key, value) => value.trim().isEmpty);
    if (!query.containsKey('query')) {
      return const _SogouStructuredPayload(items: <_ReverseImageResultItem>[]);
    }

    final requestUri = Uri.https(
      'image.sogou.com',
      '/risapi/pc/risSearchlist',
      query,
    );
    try {
      final response = await http
          .get(
            requestUri,
            headers: _jsonHeaders(referer: 'https://image.sogou.com/ris'),
          )
          .timeout(_reverseImageParseTimeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return const _SogouStructuredPayload(
          items: <_ReverseImageResultItem>[],
        );
      }
      final decoded = jsonDecode(
        utf8.decode(response.bodyBytes, allowMalformed: true),
      );
      if (decoded is! Map) {
        return const _SogouStructuredPayload(
          items: <_ReverseImageResultItem>[],
        );
      }
      if (decoded['status'] != 0 || decoded['forbid'] == true) {
        return const _SogouStructuredPayload(
          items: <_ReverseImageResultItem>[],
        );
      }
      final data = decoded['data'];
      if (data == null) {
        return const _SogouStructuredPayload(
          items: <_ReverseImageResultItem>[],
        );
      }
      final items = _parseSogouRisPayload(payload: data, resultUri: resultUri);
      return _SogouStructuredPayload(
        items: items,
        pagingCursor: _buildSogouPagingCursorFromPayload(
          payload: data,
          query: query['query']?.trim() ?? '',
        ),
      );
    } catch (_) {
      return const _SogouStructuredPayload(items: <_ReverseImageResultItem>[]);
    }
  }

  Future<_SourcePageLoadResult> _loadMoreFromSource(
    _ReverseImageEngineResult result,
    _ReverseImagePagingCursor cursor,
  ) async {
    switch (cursor.kind) {
      case _ReverseImagePagingKind.sogouSim:
        return _loadSogouSimPage(resultUri: result.resultUri, cursor: cursor);
      case _ReverseImagePagingKind.googleSearchPage:
        final queryImageUri = _parseHttpUri(
          result.items.isEmpty ? '' : result.items.first.imageUrl,
        );
        return _loadGoogleSearchPage(
          resultUri: result.resultUri,
          queryImageUri: queryImageUri ?? result.resultUri,
          cursor: cursor,
        );
    }
  }

  Future<_SourcePageLoadResult> _loadSogouSimPage({
    required Uri resultUri,
    required _ReverseImagePagingCursor cursor,
  }) async {
    final query = <String, String>{
      'query': cursor.query,
      'start': cursor.nextStart.toString(),
      'plevel': cursor.plevel,
    };
    final requestUri = Uri.https('image.sogou.com', '/risapi/pc/sim', query);
    try {
      final response = await http
          .get(
            requestUri,
            headers: _jsonHeaders(referer: 'https://image.sogou.com/ris'),
          )
          .timeout(_reverseImageParseTimeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return const _SourcePageLoadResult(
          items: <_ReverseImageResultItem>[],
          rawFetchedCount: 0,
        );
      }
      final decoded = jsonDecode(
        utf8.decode(response.bodyBytes, allowMalformed: true),
      );
      if (decoded is! Map || decoded['status'] != 0) {
        return const _SourcePageLoadResult(
          items: <_ReverseImageResultItem>[],
          rawFetchedCount: 0,
        );
      }
      final data = decoded['data'];
      if (data is! Map) {
        return const _SourcePageLoadResult(
          items: <_ReverseImageResultItem>[],
          rawFetchedCount: 0,
        );
      }
      final rawItems = data['items'];
      if (rawItems is! List || rawItems.isEmpty) {
        return const _SourcePageLoadResult(
          items: <_ReverseImageResultItem>[],
          rawFetchedCount: 0,
        );
      }
      final items = _parseSogouRisPayload(payload: data, resultUri: resultUri);
      return _SourcePageLoadResult(
        items: _dedupeResultItems(items),
        rawFetchedCount: rawItems.length,
        nextCursor: cursor.copyWith(
          nextStart: cursor.nextStart + rawItems.length,
          hasMore: rawItems.isNotEmpty,
        ),
      );
    } catch (_) {
      return const _SourcePageLoadResult(
        items: <_ReverseImageResultItem>[],
        rawFetchedCount: 0,
      );
    }
  }

  Future<_SourcePageLoadResult> _loadGoogleSearchPage({
    required Uri resultUri,
    required Uri queryImageUri,
    required _ReverseImagePagingCursor cursor,
  }) async {
    final rawNextUri = _parseHttpUri(cursor.query);
    final nextUri = rawNextUri == null
        ? null
        : _withGoogleLanguageParams(rawNextUri);
    if (nextUri == null) {
      return const _SourcePageLoadResult(
        items: <_ReverseImageResultItem>[],
        rawFetchedCount: 0,
      );
    }
    try {
      final response = await http
          .get(
            nextUri,
            headers: _htmlHeaders(
              referer: 'https://www.google.com/',
              google: true,
            ),
          )
          .timeout(_reverseImageGoogleRequestTimeout);
      if (response.statusCode < 200 || response.statusCode >= 400) {
        return const _SourcePageLoadResult(
          items: <_ReverseImageResultItem>[],
          rawFetchedCount: 0,
        );
      }
      final html = utf8.decode(response.bodyBytes, allowMalformed: true);
      final parsed = _parseGoogleStructuredItems(
        html: html,
        resultUri: response.request?.url ?? nextUri,
        queryImageUri: queryImageUri,
      );
      final nextPageUri = parsed.nextPageUri == null
          ? null
          : _withGoogleLanguageParams(parsed.nextPageUri!);
      final nextCursor = nextPageUri == null
          ? cursor.copyWith(hasMore: false)
          : _ReverseImagePagingCursor(
              kind: _ReverseImagePagingKind.googleSearchPage,
              query: nextPageUri.toString(),
              plevel: '',
              nextStart: 0,
              hasMore: true,
            );
      return _SourcePageLoadResult(
        items: _dedupeResultItems(parsed.items),
        rawFetchedCount: parsed.items.length,
        nextCursor: nextCursor,
      );
    } catch (_) {
      return const _SourcePageLoadResult(
        items: <_ReverseImageResultItem>[],
        rawFetchedCount: 0,
      );
    }
  }

  List<_ReverseImageResultItem> _parseSogouRisPayload({
    required Object payload,
    required Uri resultUri,
  }) {
    final items = <_ReverseImageResultItem>[];
    _collectSogouPayloadItems(
      node: payload,
      resultUri: resultUri,
      output: items,
    );
    return items;
  }

  void _collectSogouPayloadItems({
    required Object? node,
    required Uri resultUri,
    required List<_ReverseImageResultItem> output,
  }) {
    if (node is Map) {
      final sourceUrl = _resolveToHttpUrl(
        resultUri,
        _firstNonEmpty(<String>[
          node['page_url']?.toString() ?? '',
          node['pageUrl']?.toString() ?? '',
          node['fromUrl']?.toString() ?? '',
          node['url']?.toString() ?? '',
          node['link']?.toString() ?? '',
        ]),
      );
      final imageUrl = _resolveToHttpUrl(
        resultUri,
        _firstNonEmpty(<String>[
          node['originImage']?.toString() ?? '',
          node['imgUrl']?.toString() ?? '',
          node['image']?.toString() ?? '',
          node['imageUrl']?.toString() ?? '',
          node['thumbUrl']?.toString() ?? '',
          node['objUrl']?.toString() ?? '',
        ]),
      );
      final previewUrl = _resolveToHttpUrl(
        resultUri,
        _firstNonEmpty(<String>[
          node['thumbUrl']?.toString() ?? '',
          node['thumburl']?.toString() ?? '',
          node['thumb_url']?.toString() ?? '',
          node['previewUrl']?.toString() ?? '',
          node['image']?.toString() ?? '',
          node['imgUrl']?.toString() ?? '',
        ]),
      );
      if (sourceUrl.isNotEmpty ||
          imageUrl.isNotEmpty ||
          previewUrl.isNotEmpty) {
        final width = node['width']?.toString() ?? '';
        final height = node['height']?.toString() ?? '';
        final sourceSite = _firstNonEmpty(<String>[
          node['origin']?.toString() ?? '',
          node['website']?.toString() ?? '',
          _hostFromUrl(sourceUrl),
        ]);
        final title = _firstNonEmpty(<String>[
          node['title']?.toString() ?? '',
          _cleanHtmlText(node['markedTitle']?.toString() ?? ''),
          node['groupName']?.toString() ?? '',
          node['desc']?.toString() ?? '',
          sourceSite,
        ]);
        final sizeText = width.isNotEmpty && height.isNotEmpty
            ? '$width x $height'
            : '';
        output.add(
          _ReverseImageResultItem(
            kind: _ReverseImageResultKind.source,
            title: title,
            sourceSite: sourceSite,
            sourceUrl: sourceUrl,
            imageUrl: imageUrl,
            previewUrl: previewUrl,
            snippet: sizeText,
            rawType: 'sogou',
            rank: output.length,
          ),
        );
      }

      for (final value in node.values) {
        _collectSogouPayloadItems(
          node: value,
          resultUri: resultUri,
          output: output,
        );
      }
      return;
    }

    if (node is List) {
      for (final value in node) {
        _collectSogouPayloadItems(
          node: value,
          resultUri: resultUri,
          output: output,
        );
      }
    }
  }

  String _resolveToHttpUrl(Uri baseUri, String rawValue) {
    final value = rawValue.trim();
    if (value.isEmpty) {
      return '';
    }
    final normalized = _normalizeUrl(value);
    if (normalized != null) {
      return normalized;
    }
    final resolved = _resolveUri(baseUri, value);
    if (resolved == null) {
      return '';
    }
    if (resolved.scheme != 'http' && resolved.scheme != 'https') {
      return '';
    }
    return resolved.toString();
  }

  Uri _toSogouQueryImageUri(Uri imageUri) {
    final host = imageUri.host.toLowerCase();
    if (host.endsWith('.sogoucdn.com')) {
      return imageUri;
    }
    final shard = imageUri.toString().hashCode.abs() % 4 + 1;
    return Uri.https(
      'img0$shard.sogoucdn.com',
      '/v2/thumb/retype_exclude_gif/ext/auto',
      <String, String>{'appid': '122', 'url': imageUri.toString()},
    );
  }

  Future<Uri> _uploadFileToSogouQueryUri(File file) async {
    final uuid =
        '${DateTime.now().millisecondsSinceEpoch}'
        '${math.Random().nextInt(1 << 20)}';
    final requestUri = Uri.https(
      'image.sogou.com',
      _reverseImageSogouUploadPath,
      <String, String>{'uuid': uuid},
    );
    final request = http.MultipartRequest('POST', requestUri);
    request.headers.addAll(const <String, String>{
      'User-Agent': _reverseImageUserAgent,
      'Accept': 'application/json,text/plain,*/*',
      'Referer': 'https://image.sogou.com/',
      'Origin': 'https://image.sogou.com',
    });
    request.files.add(
      await http.MultipartFile.fromPath(
        'pic_path',
        file.path,
        filename: path.basename(file.path),
      ),
    );

    final response = await request.send().timeout(_reverseImageUploadTimeout);
    final body = await response.stream.bytesToString();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('Sogou upload failed: HTTP ${response.statusCode}');
    }

    String candidate = body.trim();
    if (candidate.startsWith('{') || candidate.startsWith('[')) {
      try {
        final decoded = jsonDecode(candidate);
        if (decoded is String) {
          candidate = decoded;
        } else if (decoded is Map) {
          candidate = _firstNonEmpty(<String>[
            decoded['data']?.toString() ?? '',
            decoded['url']?.toString() ?? '',
            decoded['pic_url']?.toString() ?? '',
          ]);
        }
      } catch (_) {
        // Keep plain-text fallback.
      }
    }
    candidate = candidate.replaceAll('"', '').trim();
    final uri = _parseHttpUri(candidate);
    if (uri == null) {
      throw const FormatException('Sogou upload did not return a valid URL.');
    }
    return _toSogouQueryImageUri(uri);
  }

  Future<Uri> _uploadFileToPublicUrl(File file) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(_reverseImageLegacyUploadEndpoint),
    );
    request.headers.addAll(const <String, String>{
      'User-Agent': _reverseImageUserAgent,
      'Accept': 'application/json,text/plain,*/*',
    });
    request.files.add(
      await http.MultipartFile.fromPath(
        'files[]',
        file.path,
        filename: path.basename(file.path),
      ),
    );

    final response = await request.send().timeout(_reverseImageUploadTimeout);
    final body = await response.stream.bytesToString();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('Upload failed: HTTP ${response.statusCode}');
    }

    final decoded = jsonDecode(body);
    if (decoded is! Map) {
      throw const FormatException('Uploader response is not a JSON map.');
    }
    final success = decoded['success'] == true;
    final files = decoded['files'];
    if (!success || files is! List || files.isEmpty) {
      throw const FormatException('Uploader did not return file URLs.');
    }
    final first = files.first;
    if (first is! Map) {
      throw const FormatException('Uploader returned malformed file info.');
    }
    final url = first['url']?.toString().trim() ?? '';
    final uri = _parseHttpUri(url);
    if (uri == null) {
      throw const FormatException('Uploader returned an invalid URL.');
    }
    return uri;
  }

  String _stageLabel(BuildContext context) {
    return switch (_stage) {
      _ReverseImageStage.idle => _lifeI18nText(
        context,
        'literal.ui.pages.toolbox_life_tools.toolbox_life_tools_reverse_image.ready_pick_an_image_or_provide_a_url_65ca52',
      ),
      _ReverseImageStage.preparing => _lifeI18nText(
        context,
        'literal.ui.pages.toolbox_life_tools.toolbox_life_tools_reverse_image.preparing_aggregated_requests_7f0a45',
      ),
      _ReverseImageStage.directUploading => _lifeI18nText(
        context,
        'literal.ui.pages.toolbox_life_tools.toolbox_life_tools_reverse_image.uploading_local_image_directly_to_baidu_084463',
      ),
      _ReverseImageStage.parsingDirectResult => _lifeI18nText(
        context,
        'literal.ui.pages.toolbox_life_tools.toolbox_life_tools_reverse_image.parsing_structured_baidu_results_a15d87',
      ),
      _ReverseImageStage.resolvingPublicUrl => _lifeI18nText(
        context,
        'literal.ui.pages.toolbox_life_tools.toolbox_life_tools_reverse_image.direct_path_did_not_return_a_shareable_url_falling_back_0509a0',
      ),
      _ReverseImageStage.searching => _lifeI18nText(
        context,
        'literal.ui.pages.toolbox_life_tools.toolbox_life_tools_reverse_image.querying_engines_in_parallel_and_aggregating_structured_2c9af3',
      ),
      _ReverseImageStage.done => _lifeI18nText(
        context,
        'literal.ui.pages.toolbox_life_tools.toolbox_life_tools_reverse_image.aggregation_complete_review_image_info_source_site_and_s_58f01a',
      ),
      _ReverseImageStage.failed => _lifeI18nText(
        context,
        'literal.ui.pages.toolbox_life_tools.toolbox_life_tools_reverse_image.aggregation_failed_check_the_network_and_retry_603622',
      ),
    };
  }

  (Color, String) _statusMeta(
    BuildContext context,
    _ReverseImageEngineResult result,
  ) {
    final theme = Theme.of(context);
    if (result.manualOnly) {
      return (
        theme.colorScheme.tertiary,
        _lifeI18nText(
          context,
          'literal.ui.pages.toolbox_life_tools.toolbox_life_tools_reverse_image.manual_f955f2',
        ),
      );
    }
    if (!result.success) {
      return (
        theme.colorScheme.error,
        _lifeI18nText(
          context,
          'literal.ui.pages.toolbox_life_tools.toolbox_life_tools_reverse_image.failed_d94142',
        ),
      );
    }
    if (result.noResultHint) {
      return (
        const Color(0xFFE09200),
        _lifeI18nText(
          context,
          'literal.ui.pages.toolbox_life_tools.toolbox_life_tools_reverse_image.no_clear_match_4fdec7',
        ),
      );
    }
    if (result.usedDirectUpload) {
      return (
        theme.colorScheme.primary,
        _lifeI18nText(
          context,
          'literal.ui.pages.toolbox_life_tools.toolbox_life_tools_reverse_image.direct_1b13b3',
        ),
      );
    }
    return (
      theme.colorScheme.primary,
      _lifeI18nText(
        context,
        'literal.ui.pages.toolbox_life_tools.toolbox_life_tools_reverse_image.loaded_6f388d',
      ),
    );
  }

  String _engineSummary(
    BuildContext context,
    _ReverseImageEngineResult result,
  ) {
    if (result.manualOnly) {
      return _lifeI18nText(
        context,
        'toolbox.life.reverse_image.manual_summary',
      );
    }
    if (!result.success) {
      return _lifeI18nText(
        context,
        'toolbox.life.reverse_image.request_failed',
        params: <String, Object?>{'error': result.error},
      );
    }
    if (result.noResultHint && result.items.isEmpty) {
      return _lifeI18nText(
        context,
        'toolbox.life.reverse_image.no_clear_match',
      );
    }
    return _lifeI18nText(
      context,
      'toolbox.life.reverse_image.structured_entries',
      params: <String, Object?>{'count': result.items.length},
    );
  }
}

extension on _ReverseImageEngineResult {
  _ReverseImageEngineResult copyWith({
    List<_ReverseImageResultItem>? items,
    _ReverseImagePagingCursor? pagingCursor,
    bool clearPagingCursor = false,
  }) {
    return _ReverseImageEngineResult(
      engine: engine,
      requestUri: requestUri,
      resultUri: resultUri,
      elapsed: elapsed,
      statusCode: statusCode,
      items: items ?? this.items,
      manualOnly: manualOnly,
      usedDirectUpload: usedDirectUpload,
      noResultHint: noResultHint,
      pagingCursor: clearPagingCursor
          ? null
          : pagingCursor ?? this.pagingCursor,
      derivedImageUri: derivedImageUri,
      error: error,
    );
  }
}

extension on _ReverseImageResultItem {
  _ReverseImageResultItem copyWith({int? rank}) {
    return _ReverseImageResultItem(
      kind: kind,
      title: title,
      sourceSite: sourceSite,
      sourceUrl: sourceUrl,
      imageUrl: imageUrl,
      previewUrl: previewUrl,
      snippet: snippet,
      rawType: rawType,
      rank: rank ?? this.rank,
    );
  }
}

Uri? _parseHttpUri(String raw) {
  if (raw.trim().isEmpty) {
    return null;
  }
  final normalized = raw.trim();
  final uri = Uri.tryParse(normalized);
  if (uri == null || uri.host.isEmpty) {
    return null;
  }
  if (uri.scheme != 'http' && uri.scheme != 'https') {
    return null;
  }
  return uri;
}

Uri? _resolveUri(Uri base, String maybeRelativeUrl) {
  final uri = Uri.tryParse(maybeRelativeUrl);
  if (uri == null) {
    return null;
  }
  if (uri.hasScheme) {
    return uri;
  }
  return base.resolveUri(uri);
}

String _hostFromUrl(String url) {
  final uri = _parseHttpUri(url);
  if (uri == null) {
    return '';
  }
  return uri.host;
}

String _normalizeMetaText(String raw) {
  return raw
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

String _cleanHtmlText(String raw) {
  final noTags = raw.replaceAll(RegExp(r'<[^>]*>'), ' ');
  return _normalizeMetaText(noTags);
}

String _extractHtmlTitle(String html) {
  final match = RegExp(
    r'<title[^>]*>([\s\S]*?)</title>',
    caseSensitive: false,
  ).firstMatch(html);
  if (match == null) {
    return '';
  }
  return _cleanHtmlText(match.group(1) ?? '');
}

String _extractMetaDescription(String html) {
  final match = RegExp(
    r'''<meta[^>]+name=["']description["'][^>]+content=["']([^"']+)["']''',
    caseSensitive: false,
  ).firstMatch(html);
  if (match == null) {
    return '';
  }
  return _normalizeMetaText(match.group(1) ?? '');
}

String _extractMetaProperty(String html, String property) {
  final escaped = RegExp.escape(property);
  final match = RegExp(
    '<meta[^>]+property=["\']$escaped["\'][^>]+content=["\']([^"\']+)["\']',
    caseSensitive: false,
  ).firstMatch(html);
  if (match == null) {
    return '';
  }
  return _normalizeMetaText(match.group(1) ?? '');
}

String _extractCanonicalUrl(String html) {
  final match = RegExp(
    r'''<link[^>]+rel=["']canonical["'][^>]+href=["']([^"']+)["']''',
    caseSensitive: false,
  ).firstMatch(html);
  if (match == null) {
    return '';
  }
  return _normalizeMetaText(match.group(1) ?? '');
}

bool _hasNoResultHint(String html) {
  final lower = html.toLowerCase();
  return lower.contains('no exact match') ||
      lower.contains('no results') ||
      lower.contains('no result found') ||
      lower.contains('not found') ||
      lower.contains('try another image');
}

String? _normalizeUrl(Object? raw) {
  final value = raw?.toString().trim() ?? '';
  if (value.isEmpty) {
    return null;
  }
  if (value.startsWith('//')) {
    return 'https:$value';
  }
  if (value.startsWith('/')) {
    return null;
  }
  final parsed = Uri.tryParse(value);
  if (parsed == null) {
    return null;
  }
  if (!parsed.hasScheme) {
    return null;
  }
  if (parsed.scheme != 'http' && parsed.scheme != 'https') {
    return null;
  }
  return parsed.toString();
}

String _firstNonEmpty(List<String> candidates) {
  for (final raw in candidates) {
    final value = raw.trim();
    if (value.isNotEmpty) {
      return value;
    }
  }
  return '';
}

String? _extractScriptJsonBlock(
  String html, {
  required String marker,
  required String openChar,
  required String closeChar,
}) {
  final markerIndex = html.indexOf(marker);
  if (markerIndex < 0) {
    return null;
  }
  final start = html.indexOf(openChar, markerIndex);
  if (start < 0) {
    return null;
  }

  int depth = 0;
  bool inString = false;
  String quoteChar = '';
  bool escaped = false;
  for (int i = start; i < html.length; i++) {
    final char = html[i];
    if (inString) {
      if (escaped) {
        escaped = false;
        continue;
      }
      if (char == r'\') {
        escaped = true;
        continue;
      }
      if (char == quoteChar) {
        inString = false;
      }
      continue;
    }

    if (char == '"' || char == "'") {
      inString = true;
      quoteChar = char;
      continue;
    }

    if (char == openChar) {
      depth++;
      continue;
    }
    if (char == closeChar) {
      depth--;
      if (depth == 0) {
        return html.substring(start, i + 1);
      }
    }
  }
  return null;
}

List<_ReverseImageResultItem> _dedupeResultItems(
  List<_ReverseImageResultItem> items,
) {
  final byKey = <String, _ReverseImageResultItem>{};
  final order = <String>[];
  for (final item in items) {
    final source = _dedupeCanonicalUrl(item.sourceUrl);
    final image = _dedupeCanonicalUrl(item.imageUrl);
    final title = _dedupeCanonicalText(item.title);
    final sourceSite = _dedupeCanonicalText(item.sourceSite);
    final key = source.isNotEmpty
        ? 'source|$source'
        : image.isNotEmpty
        ? 'image|$image'
        : 'meta|$title|$sourceSite';

    final existing = byKey[key];
    if (existing == null) {
      byKey[key] = item;
      order.add(key);
      continue;
    }
    byKey[key] = _pickBetterResultItem(existing, item);
  }

  final output = <_ReverseImageResultItem>[];
  for (int i = 0; i < order.length; i++) {
    final item = byKey[order[i]];
    if (item == null) {
      continue;
    }
    output.add(item.copyWith(rank: i));
  }
  return output;
}

String _dedupeCanonicalUrl(String raw) {
  final uri = _parseHttpUri(raw);
  if (uri == null) {
    return '';
  }
  final query = <String, String>{...uri.queryParameters};
  query.removeWhere((key, value) {
    return key.startsWith('utm_') ||
        key == 'spm' ||
        key == 'from' ||
        key == 'ref';
  });
  final normalized = uri.replace(
    fragment: '',
    queryParameters: query.isEmpty ? null : query,
  );
  return normalized.toString();
}

String _dedupeCanonicalText(String raw) {
  return raw
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'[^a-z0-9\u4e00-\u9fa5 ]'), '')
      .trim();
}

_ReverseImageResultItem _pickBetterResultItem(
  _ReverseImageResultItem left,
  _ReverseImageResultItem right,
) {
  int score(_ReverseImageResultItem item) {
    return (item.sourceUrl.trim().isNotEmpty ? 3 : 0) +
        (item.imageUrl.trim().isNotEmpty ? 2 : 0) +
        (item.previewUrl.trim().isNotEmpty ? 2 : 0) +
        (item.snippet.trim().length > 10 ? 1 : 0) +
        (item.title.trim().length > 10 ? 1 : 0);
  }

  final leftScore = score(left);
  final rightScore = score(right);
  if (rightScore > leftScore) {
    return right;
  }
  if (rightScore == leftScore &&
      right.title.trim().length > left.title.trim().length) {
    return right;
  }
  return left;
}

_GoogleStructuredPayload _parseGoogleStructuredItems({
  required String html,
  required Uri resultUri,
  required Uri queryImageUri,
}) {
  final normalizedHtml = _decodeEscapedWebText(html);
  final items = <_ReverseImageResultItem>[
    ..._extractGoogleImgResItems(normalizedHtml, resultUri),
    ..._extractVisualMatchCardItems(normalizedHtml, resultUri),
    ..._extractGenericItemsFromJsonPairs(normalizedHtml, resultUri),
    ..._extractGenericItemsFromAnchorLinks(normalizedHtml, resultUri),
  ];
  if (items.isEmpty) {
    items.addAll(
      _buildGenericItemsFromHtml(
        html: normalizedHtml,
        resultUri: resultUri,
        queryImageUri: queryImageUri,
      ),
    );
  }
  return _GoogleStructuredPayload(
    items: _dedupeResultItems(items),
    nextPageUri: _extractGoogleNextPageUri(normalizedHtml, resultUri),
  );
}

String _decodeEscapedWebText(String raw) {
  return raw
      .replaceAll(r'\/', '/')
      .replaceAll(r'\u003d', '=')
      .replaceAll(r'\u003D', '=')
      .replaceAll(r'\u0026', '&')
      .replaceAll(r'\u002F', '/')
      .replaceAll(r'\x3d', '=')
      .replaceAll(r'\x3D', '=')
      .replaceAll(r'\x26', '&')
      .replaceAll(r'\x2F', '/')
      .replaceAll('&amp;', '&');
}

List<_ReverseImageResultItem> _extractGoogleImgResItems(
  String html,
  Uri resultUri,
) {
  final items = <_ReverseImageResultItem>[];
  final matches = RegExp(
    r'''(?:https?:\/\/(?:www\.)?google\.[^\/"'<\s]+)?\/imgres\?[^"'<\s]+''',
    caseSensitive: false,
  ).allMatches(html);
  for (final match in matches.take(320)) {
    final raw = _normalizeMetaText(match.group(0) ?? '');
    if (raw.isEmpty) {
      continue;
    }
    final imgResUrl = _resolveHttpUrlString(resultUri, raw);
    final imgResUri = _parseHttpUri(imgResUrl);
    if (imgResUri == null) {
      continue;
    }
    final nestedUrl = _extractGoogleOutboundUrl(imgResUri, resultUri);
    final imageUrl = _resolveHttpUrlString(
      resultUri,
      _firstNonEmpty(<String>[
        imgResUri.queryParameters['imgurl'] ?? '',
        imgResUri.queryParameters['img_url'] ?? '',
        imgResUri.queryParameters['mediaurl'] ?? '',
      ]),
    );
    final sourceUrl = _resolveHttpUrlString(
      resultUri,
      _firstNonEmpty(<String>[
        imgResUri.queryParameters['imgrefurl'] ?? '',
        imgResUri.queryParameters['imgref'] ?? '',
        imgResUri.queryParameters['fromurl'] ?? '',
        nestedUrl,
      ]),
    );
    if (imageUrl.isEmpty && sourceUrl.isEmpty) {
      continue;
    }
    items.add(
      _ReverseImageResultItem(
        kind: _ReverseImageResultKind.source,
        title: _firstNonEmpty(<String>[
          _hostFromUrl(sourceUrl),
          'Visual match',
        ]),
        sourceSite: _hostFromUrl(sourceUrl),
        sourceUrl: sourceUrl,
        imageUrl: imageUrl,
        previewUrl: imageUrl,
        snippet: '',
        rawType: 'google_imgres',
        rank: items.length,
      ),
    );
  }
  return items;
}

List<_ReverseImageResultItem> _extractVisualMatchCardItems(
  String html,
  Uri resultUri,
) {
  final items = <_ReverseImageResultItem>[];
  final anchorPattern = RegExp(
    r'''<a[^>]+href=["']([^"']+)["'][^>]*>([\s\S]{0,6000}?)</a>''',
    caseSensitive: false,
  );
  final imagePattern = RegExp(
    r'''<img[^>]+(?:src|data-src|data-iurl|data-lzy-src)=["']([^"']+)["']''',
    caseSensitive: false,
  );
  for (final match in anchorPattern.allMatches(html).take(1400)) {
    final rawHref = _normalizeMetaText(match.group(1) ?? '');
    if (rawHref.isEmpty ||
        rawHref.startsWith('javascript:') ||
        rawHref.startsWith('mailto:')) {
      continue;
    }
    final href = _resolveHttpUrlString(resultUri, rawHref);
    final hrefUri = _parseHttpUri(href);
    if (hrefUri == null) {
      continue;
    }

    final host = hrefUri.host.toLowerCase();
    final isGoogleHost = _isGoogleSearchHostName(host);
    final nestedUrl = _extractGoogleOutboundUrl(hrefUri, resultUri);
    final sourceUrl = _resolveHttpUrlString(
      resultUri,
      _firstNonEmpty(<String>[
        hrefUri.queryParameters['imgrefurl'] ?? '',
        hrefUri.queryParameters['url'] ?? '',
        hrefUri.queryParameters['q'] ?? '',
        nestedUrl,
        if (!isGoogleHost) href,
      ]),
    );
    final inner = match.group(2) ?? '';
    final imageMatch = imagePattern.firstMatch(inner);
    final imageUrl = _resolveHttpUrlString(
      resultUri,
      _firstNonEmpty(<String>[
        imageMatch?.group(1) ?? '',
        hrefUri.queryParameters['imgurl'] ?? '',
        hrefUri.queryParameters['img_url'] ?? '',
        hrefUri.queryParameters['mediaurl'] ?? '',
      ]),
    );

    if (sourceUrl.isEmpty && imageUrl.isEmpty) {
      continue;
    }
    if (sourceUrl.isNotEmpty && _hostFromUrl(sourceUrl).contains('google.')) {
      continue;
    }

    final titleRaw = _cleanHtmlText(inner);
    final title = titleRaw.length > 160
        ? '${titleRaw.substring(0, 160)}...'
        : titleRaw;
    items.add(
      _ReverseImageResultItem(
        kind: _ReverseImageResultKind.source,
        title: _firstNonEmpty(<String>[title, _hostFromUrl(sourceUrl)]),
        sourceSite: _hostFromUrl(sourceUrl),
        sourceUrl: sourceUrl,
        imageUrl: imageUrl,
        previewUrl: imageUrl,
        snippet: '',
        rawType: 'google_visual_card',
        rank: items.length,
      ),
    );
  }
  return _dedupeResultItems(items);
}

Uri? _extractGoogleNextPageUri(String html, Uri resultUri) {
  Uri? fallback;
  final anchorPattern = RegExp(
    r'''<a[^>]+href=["']([^"']+)["'][^>]*>([\s\S]*?)</a>''',
    caseSensitive: false,
  );
  for (final match in anchorPattern.allMatches(html).take(800)) {
    final rawHref = _normalizeMetaText(match.group(1) ?? '');
    final href = _resolveHttpUrlString(resultUri, rawHref);
    final hrefUri = _parseHttpUri(href);
    if (hrefUri == null) {
      continue;
    }
    final host = hrefUri.host.toLowerCase();
    if (!_isGoogleSearchHostName(host)) {
      continue;
    }
    if (hrefUri.path != '/search') {
      continue;
    }
    final vsrid = hrefUri.queryParameters['vsrid']?.trim() ?? '';
    if (vsrid.isEmpty || href == resultUri.toString()) {
      continue;
    }
    final text = _cleanHtmlText(match.group(2) ?? '').toLowerCase();
    final hasPageSignal =
        hrefUri.queryParameters.containsKey('start') ||
        hrefUri.queryParameters.containsKey('ijn') ||
        hrefUri.queryParameters.containsKey('asearch') ||
        hrefUri.queryParameters.containsKey('vet');
    if (text.contains('see more') ||
        text.contains('visual matches') ||
        text.contains('more results') ||
        text.contains('查看更多') ||
        text.contains('更多结果')) {
      return hrefUri;
    }
    final udm = hrefUri.queryParameters['udm']?.trim() ?? '';
    if (udm == '26' || udm == '44' || udm == '48' || udm == '50') {
      fallback ??= hrefUri;
    }
    if (hasPageSignal) {
      fallback ??= hrefUri;
    }
  }
  if (fallback != null) {
    return fallback;
  }
  final searchUrlPattern = RegExp(
    r'''https:\/\/(?:www\.)?google\.[^\/"'<\s]+\/search\?[^"'<\s]*vsrid=[^"'<\s]+''',
    caseSensitive: false,
  );
  for (final match in searchUrlPattern.allMatches(html).take(120)) {
    final rawUrl = _normalizeMetaText(match.group(0) ?? '');
    final uri = _parseHttpUri(rawUrl);
    if (uri == null || uri.toString() == resultUri.toString()) {
      continue;
    }
    final udm = uri.queryParameters['udm']?.trim() ?? '';
    if (udm == '26' || udm == '44' || udm == '48' || udm == '50') {
      return uri;
    }
    fallback ??= uri;
  }
  return fallback;
}

List<_ReverseImageResultItem> _buildGenericItemsFromHtml({
  required String html,
  required Uri resultUri,
  required Uri queryImageUri,
}) {
  final items = <_ReverseImageResultItem>[
    ..._extractGoogleImgResItems(html, resultUri),
    ..._extractGenericItemsFromJsonPairs(html, resultUri),
    ..._extractGenericItemsFromAnchorLinks(html, resultUri),
  ];

  final title = _extractHtmlTitle(html);
  final description = _extractMetaDescription(html);
  final canonical = _extractCanonicalUrl(html);
  final ogImage = _extractMetaProperty(html, 'og:image');
  final sourceUrl = _resolveHttpUrlString(
    resultUri,
    _firstNonEmpty(<String>[canonical, resultUri.toString()]),
  );
  final imageUrl = _resolveHttpUrlString(
    resultUri,
    _firstNonEmpty(<String>[ogImage, queryImageUri.toString()]),
  );
  items.add(
    _ReverseImageResultItem(
      kind: _ReverseImageResultKind.page,
      title: title,
      sourceSite: resultUri.host,
      sourceUrl: sourceUrl,
      imageUrl: imageUrl,
      previewUrl: imageUrl,
      snippet: description,
      rawType: 'page',
      rank: 0,
    ),
  );

  return _dedupeResultItems(items);
}

List<_ReverseImageResultItem> _extractGenericItemsFromJsonPairs(
  String html,
  Uri resultUri,
) {
  final patterns = <RegExp>[
    RegExp(
      r'imgurl\\?":\\?"([^"\\]+)"[\s\S]{0,280}?imgrefurl\\?":\\?"([^"\\]+)"',
      caseSensitive: false,
    ),
    RegExp(
      r'''imgurl["']?\s*[:=]\s*["']([^"']+)["'][\s\S]{0,280}?imgrefurl["']?\s*[:=]\s*["']([^"']+)["']''',
      caseSensitive: false,
    ),
    RegExp(
      r'''imgurl=([^&"'<\s]+)[\s\S]{0,280}?imgrefurl=([^&"'<\s]+)''',
      caseSensitive: false,
    ),
  ];
  final items = <_ReverseImageResultItem>[];
  for (final pattern in patterns) {
    final matches = pattern.allMatches(html).take(240);
    for (final match in matches) {
      final imageRaw = (match.group(1) ?? '').replaceAll(r'\/', '/');
      final sourceRaw = (match.group(2) ?? '').replaceAll(r'\/', '/');
      final imageUrl = _resolveHttpUrlString(resultUri, imageRaw);
      final sourceUrl = _resolveHttpUrlString(resultUri, sourceRaw);
      if (sourceUrl.isEmpty && imageUrl.isEmpty) {
        continue;
      }
      items.add(
        _ReverseImageResultItem(
          kind: _ReverseImageResultKind.source,
          title: _firstNonEmpty(<String>[
            _hostFromUrl(sourceUrl),
            'Image result',
          ]),
          sourceSite: _hostFromUrl(sourceUrl),
          sourceUrl: sourceUrl,
          imageUrl: imageUrl,
          previewUrl: imageUrl,
          snippet: '',
          rawType: 'json_pair',
          rank: items.length,
        ),
      );
    }
  }

  final queryPairPattern = RegExp(
    r'''(?:imgurl|mediaurl|image_url)=([^&"'<\s]+)(?:[^"'<\n\r]{0,240})(?:imgrefurl|fromurl)=([^&"'<\s]+)''',
    caseSensitive: false,
  );
  for (final match in queryPairPattern.allMatches(html).take(260)) {
    final imageRaw = match.group(1) ?? '';
    final sourceRaw = match.group(2) ?? '';
    final imageUrl = _resolveHttpUrlString(
      resultUri,
      imageRaw.replaceAll(r'\/', '/'),
    );
    final sourceUrl = _resolveHttpUrlString(
      resultUri,
      sourceRaw.replaceAll(r'\/', '/'),
    );
    if (sourceUrl.isEmpty && imageUrl.isEmpty) {
      continue;
    }
    items.add(
      _ReverseImageResultItem(
        kind: _ReverseImageResultKind.source,
        title: _firstNonEmpty(<String>[
          _hostFromUrl(sourceUrl),
          'Image result',
        ]),
        sourceSite: _hostFromUrl(sourceUrl),
        sourceUrl: sourceUrl,
        imageUrl: imageUrl,
        previewUrl: imageUrl,
        snippet: '',
        rawType: 'json_pair',
        rank: items.length,
      ),
    );
  }
  return _dedupeResultItems(items);
}

bool _isGoogleSearchHostName(String host) {
  final normalized = host.toLowerCase();
  return normalized == 'google.com' ||
      normalized == 'www.google.com' ||
      normalized.startsWith('www.google.') ||
      normalized.startsWith('google.');
}

String _extractGoogleOutboundUrl(Uri uri, Uri baseUri) {
  if (!_isGoogleSearchHostName(uri.host)) {
    return '';
  }
  final path = uri.path.toLowerCase();
  if (path != '/url' && path != '/imgres' && path != '/search') {
    return '';
  }
  final candidate = _firstNonEmpty(<String>[
    uri.queryParameters['url'] ?? '',
    uri.queryParameters['q'] ?? '',
    uri.queryParameters['imgrefurl'] ?? '',
    uri.queryParameters['imgref'] ?? '',
    uri.queryParameters['fromurl'] ?? '',
  ]);
  final decodedCandidate = Uri.decodeFull(candidate);
  final resolved = _resolveHttpUrlString(baseUri, decodedCandidate);
  final resolvedUri = _parseHttpUri(resolved);
  if (resolvedUri == null || _isGoogleSearchHostName(resolvedUri.host)) {
    return '';
  }
  return resolved;
}

List<_ReverseImageResultItem> _extractGenericItemsFromAnchorLinks(
  String html,
  Uri resultUri,
) {
  final anchorPattern = RegExp(
    r'''<a[^>]+href=["']([^"']+)["'][^>]*>([\s\S]*?)</a>''',
    caseSensitive: false,
  );
  final items = <_ReverseImageResultItem>[];
  for (final match in anchorPattern.allMatches(html).take(500)) {
    final rawHref = _normalizeMetaText(match.group(1) ?? '');
    if (rawHref.startsWith('javascript:') || rawHref.startsWith('mailto:')) {
      continue;
    }
    final href = _resolveHttpUrlString(resultUri, rawHref);
    if (href.isEmpty) {
      continue;
    }
    final hrefUri = _parseHttpUri(href);
    if (hrefUri == null) {
      continue;
    }

    final sourceUrl = _resolveHttpUrlString(
      resultUri,
      _firstNonEmpty(<String>[
        hrefUri.queryParameters['imgrefurl'] ?? '',
        hrefUri.queryParameters['fromurl'] ?? '',
        hrefUri.queryParameters['url'] ?? '',
        if (hrefUri.host != resultUri.host) href,
      ]),
    );
    final imageUrl = _resolveHttpUrlString(
      resultUri,
      _firstNonEmpty(<String>[
        hrefUri.queryParameters['imgurl'] ?? '',
        hrefUri.queryParameters['image_url'] ?? '',
        hrefUri.queryParameters['mediaurl'] ?? '',
        hrefUri.queryParameters['img'] ?? '',
      ]),
    );
    if (sourceUrl.isEmpty && imageUrl.isEmpty) {
      continue;
    }

    final title = _cleanHtmlText(match.group(2) ?? '');
    items.add(
      _ReverseImageResultItem(
        kind: _ReverseImageResultKind.source,
        title: _firstNonEmpty(<String>[title, _hostFromUrl(sourceUrl)]),
        sourceSite: _hostFromUrl(sourceUrl),
        sourceUrl: sourceUrl,
        imageUrl: imageUrl,
        previewUrl: imageUrl,
        snippet: '',
        rawType: 'anchor',
        rank: items.length,
      ),
    );
  }
  return items;
}

String _resolveHttpUrlString(Uri baseUri, String rawValue) {
  final value = rawValue.trim();
  if (value.isEmpty) {
    return '';
  }
  final normalized = _normalizeUrl(value);
  if (normalized != null) {
    return normalized;
  }
  final resolved = _resolveUri(baseUri, value);
  if (resolved == null || resolved.host.isEmpty) {
    return '';
  }
  if (resolved.scheme != 'http' && resolved.scheme != 'https') {
    return '';
  }
  return resolved.toString();
}

List<_ReverseImageResultItem> _fallbackPageItem({
  required Uri resultUri,
  required Uri imageUri,
  required String html,
  required bool noResultHint,
}) {
  final title = _extractHtmlTitle(html);
  final description = _extractMetaDescription(html);
  final snippet = _firstNonEmpty(<String>[
    description,
    if (noResultHint) 'No clear match',
  ]);
  return <_ReverseImageResultItem>[
    _ReverseImageResultItem(
      kind: _ReverseImageResultKind.unknown,
      title: title,
      sourceSite: resultUri.host,
      sourceUrl: resultUri.toString(),
      imageUrl: imageUri.toString(),
      previewUrl: imageUri.toString(),
      snippet: snippet,
      rawType: 'fallback',
      rank: 0,
    ),
  ];
}
