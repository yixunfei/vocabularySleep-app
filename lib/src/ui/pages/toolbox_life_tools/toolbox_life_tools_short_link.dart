part of '../toolbox_life_tools.dart';

class _ShortLinkPage extends StatefulWidget {
  const _ShortLinkPage();

  @override
  State<_ShortLinkPage> createState() => _ShortLinkPageState();
}

class _ShortLinkPageState extends State<_ShortLinkPage> {
  final TextEditingController _urlController = TextEditingController(
    text: 'https://example.com/article?id=42&utm_source=share',
  );
  final TextEditingController _aliasController = TextEditingController();
  final ToolboxShortLinkService _service = const ToolboxShortLinkService();

  ToolboxShortLinkProvider _provider = ToolboxShortLinkProvider.tinyUrl;
  ToolboxShortLinkResult? _shortResult;
  ToolboxShortLinkResolveResult? _resolveResult;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _urlController.dispose();
    _aliasController.dispose();
    super.dispose();
  }

  Future<void> _shorten() async {
    setState(() {
      _busy = true;
      _error = null;
      _shortResult = null;
    });
    try {
      final result = await _service.shorten(
        inputUrl: _urlController.text,
        provider: _provider,
        alias: _aliasController.text,
      );
      if (!mounted) {
        return;
      }
      setState(() => _shortResult = result);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = _lifeText(
          context,
          zh: '生成失败: $error',
          en: 'Shorten failed: $error',
        );
      });
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _resolve() async {
    setState(() {
      _busy = true;
      _error = null;
      _resolveResult = null;
    });
    try {
      final result = await _service.resolve(inputUrl: _urlController.text);
      if (!mounted) {
        return;
      }
      setState(() => _resolveResult = result);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = _lifeText(
          context,
          zh: '还原失败: $error',
          en: 'Resolve failed: $error',
        );
      });
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _copy(String text) async {
    if (text.trim().isEmpty) {
      return;
    }
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_lifeText(context, zh: '已复制', en: 'Copied'))),
    );
  }

  void _useShortAsInput() {
    final shortUrl = _shortResult?.shortUrl.trim() ?? '';
    if (shortUrl.isEmpty || shortUrl.startsWith('vocab-sleep://')) {
      return;
    }
    _urlController.text = shortUrl;
    _urlController.selection = TextSelection.fromPosition(
      TextPosition(offset: _urlController.text.length),
    );
  }

  String _providerHelp(ToolboxShortLinkProvider provider) {
    return switch (provider) {
      ToolboxShortLinkProvider.tinyUrl => _lifeText(
        context,
        zh: '公开短链服务，兼容性较好，不支持自定义别名。',
        en: 'Public short-link service with broad compatibility; no custom alias.',
      ),
      ToolboxShortLinkProvider.isGd => _lifeText(
        context,
        zh: '公开短链服务，支持可用时的自定义别名。',
        en: 'Public short-link service with optional custom alias.',
      ),
      ToolboxShortLinkProvider.vGd => _lifeText(
        context,
        zh: 'is.gd 同源服务，适合备用生成。',
        en: 'Sister service of is.gd, useful as a fallback.',
      ),
      ToolboxShortLinkProvider.cleanUri => _lifeText(
        context,
        zh: '公开 API，响应为 JSON，不支持别名。',
        en: 'Public JSON API without custom alias support.',
      ),
      ToolboxShortLinkProvider.localAlias => _lifeText(
        context,
        zh: '离线生成本地短码，不是公网可访问短链接。',
        en: 'Offline local code; not a public web redirect.',
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final shortResult = _shortResult;
    final resolveResult = _resolveResult;
    final normalizedPreview = _previewNormalizedUrl();
    return ToolboxToolPage(
      title: _lifeText(context, zh: '短链接生成与还原', en: 'Short link tool'),
      subtitle: _lifeText(
        context,
        zh: '多服务短链生成、离线短码、重定向链路还原和可复制结果。',
        en: 'Generate public short links, create local aliases, and inspect redirect chains.',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _LifeSettingsPanel(
            title: _lifeText(context, zh: '链接工作台', en: 'Link workspace'),
            subtitle: _lifeText(
              context,
              zh: '输入原始长链接或短链接；生成与还原共用同一输入框。',
              en: 'Enter a long URL or a short URL; generation and resolving share this input.',
            ),
            children: <Widget>[
              TextField(
                key: const ValueKey<String>('life-short-link-url-field'),
                controller: _urlController,
                minLines: 2,
                maxLines: 4,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.link_rounded),
                  border: const OutlineInputBorder(),
                  labelText: _lifeText(context, zh: '目标网址', en: 'Target URL'),
                  helperText: normalizedPreview,
                ),
              ),
              const SizedBox(height: 12),
              _LifeSegmentedField<ToolboxShortLinkProvider>(
                label: _lifeText(context, zh: '短链服务', en: 'Short-link service'),
                value: _provider,
                options: ToolboxShortLinkProvider.values
                    .map(
                      (provider) => _LifeOption<ToolboxShortLinkProvider>(
                        value: provider,
                        labelZh: provider.label,
                        labelEn: provider.label,
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  setState(() {
                    _provider = value;
                    _error = null;
                  });
                },
              ),
              const SizedBox(height: 8),
              Text(_providerHelp(_provider), style: Theme.of(context).textTheme.bodySmall),
              if (_provider.supportsCustomAlias) ...<Widget>[
                const SizedBox(height: 12),
                TextField(
                  key: const ValueKey<String>('life-short-link-alias-field'),
                  controller: _aliasController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.badge_rounded),
                    border: const OutlineInputBorder(),
                    labelText: _lifeText(
                      context,
                      zh: '自定义别名（可选）',
                      en: 'Custom alias (optional)',
                    ),
                    helperText: _lifeText(
                      context,
                      zh: '仅保留字母、数字、短横线和下划线；公开服务可能因占用而失败。',
                      en: 'Letters, digits, dash, and underscore only; public services may reject taken aliases.',
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  Expanded(
                    child: FilledButton.icon(
                      key: const ValueKey<String>('life-short-link-run-button'),
                      onPressed: _busy ? null : _shorten,
                      icon: _busy
                          ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_fix_high_rounded),
                      label: Text(
                        _busy
                            ? _lifeText(context, zh: '处理中...', en: 'Working...')
                            : _lifeText(context, zh: '生成短链', en: 'Shorten'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const ValueKey<String>('life-short-link-resolve-button'),
                      onPressed: _busy ? null : _resolve,
                      icon: const Icon(Icons.route_rounded),
                      label: Text(_lifeText(context, zh: '还原链路', en: 'Resolve')),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_error != null) _buildMessagePanel(context, _error!, isError: true),
          if (shortResult != null) ...<Widget>[
            _buildShortResult(context, shortResult),
            const SizedBox(height: 12),
          ],
          if (resolveResult != null) _buildResolveResult(context, resolveResult),
          const SizedBox(height: 12),
          _buildBoundaryNote(context),
        ],
      ),
    );
  }

  String _previewNormalizedUrl() {
    try {
      return ToolboxShortLinkService.normalizeUrl(_urlController.text).toString();
    } catch (_) {
      return _lifeText(
        context,
        zh: '可省略 https://，会自动补全。',
        en: 'You may omit https://; it will be added automatically.',
      );
    }
  }

  Widget _buildShortResult(
    BuildContext context,
    ToolboxShortLinkResult result,
  ) {
    final theme = Theme.of(context);
    return _LifeSettingsPanel(
      title: _lifeText(context, zh: '生成结果', en: 'Generated link'),
      subtitle: result.provider.usesNetwork
          ? _lifeText(
              context,
              zh: '${result.provider.label} 返回的公网短链接',
              en: 'Public short link returned by ${result.provider.label}',
            )
          : _lifeText(
              context,
              zh: '本地短码仅适合作为记录标签',
              en: 'Local alias is a record label only',
            ),
      children: <Widget>[
        SelectableText(
          result.shortUrl,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            FilledButton.tonalIcon(
              onPressed: () => _copy(result.shortUrl),
              icon: const Icon(Icons.copy_rounded),
              label: Text(_lifeText(context, zh: '复制短链', en: 'Copy')),
            ),
            OutlinedButton.icon(
              onPressed: result.provider.usesNetwork ? _useShortAsInput : null,
              icon: const Icon(Icons.input_rounded),
              label: Text(_lifeText(context, zh: '放入输入框', en: 'Use as input')),
            ),
          ],
        ),
        if (result.warning.isNotEmpty) ...<Widget>[
          const SizedBox(height: 10),
          _buildMessagePanel(context, result.warning),
        ],
      ],
    );
  }

  Widget _buildResolveResult(
    BuildContext context,
    ToolboxShortLinkResolveResult result,
  ) {
    final theme = Theme.of(context);
    return _LifeSettingsPanel(
      title: _lifeText(context, zh: '还原链路', en: 'Redirect chain'),
      subtitle: _lifeText(
        context,
        zh: '共 ${result.redirectCount} 次跳转，最终地址如下。',
        en: '${result.redirectCount} redirects; final URL is shown below.',
      ),
      children: <Widget>[
        SelectableText(
          result.finalUrl.toString(),
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => _copy(result.finalUrl.toString()),
          icon: const Icon(Icons.copy_rounded),
          label: Text(_lifeText(context, zh: '复制最终地址', en: 'Copy final URL')),
        ),
        const SizedBox(height: 12),
        for (var index = 0; index < result.hops.length; index += 1)
          Padding(
            padding: EdgeInsets.only(top: index == 0 ? 0 : 8),
            child: _buildHopTile(context, index + 1, result.hops[index]),
          ),
        if (result.reachedLimit) ...<Widget>[
          const SizedBox(height: 10),
          _buildMessagePanel(
            context,
            _lifeText(
              context,
              zh: '已达到最大跳转层数，最终地址可能仍会继续跳转。',
              en: 'Max redirect depth reached; the final URL may still redirect.',
            ),
            isError: true,
          ),
        ],
      ],
    );
  }

  Widget _buildHopTile(BuildContext context, int index, ToolboxShortLinkHop hop) {
    final theme = Theme.of(context);
    final color = hop.isRedirect
        ? theme.colorScheme.tertiary
        : theme.colorScheme.primary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.26)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            _lifeText(
              context,
              zh: '第 $index 步 · HTTP ${hop.statusCode}',
              en: 'Step $index · HTTP ${hop.statusCode}',
            ),
            style: theme.textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          SelectableText(hop.url),
          if (hop.location != null) ...<Widget>[
            const SizedBox(height: 6),
            SelectableText('→ ${hop.location}'),
          ],
        ],
      ),
    );
  }

  Widget _buildMessagePanel(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    final theme = Theme.of(context);
    final color = isError ? theme.colorScheme.error : theme.colorScheme.tertiary;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(message, style: theme.textTheme.bodySmall),
    );
  }

  Widget _buildBoundaryNote(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeText(context, zh: '使用边界', en: 'Boundary'),
      subtitle: _lifeText(
        context,
        zh: '公开短链依赖第三方服务；还原链路只展示 HTTP 跳转，不检查目标页面安全性。',
        en: 'Public links depend on third-party services; resolving shows HTTP redirects only and does not audit page safety.',
      ),
      children: <Widget>[
        Text(
          _lifeText(
            context,
            zh: '建议对重要链接保留原始地址；可疑短链请先还原再打开。',
            en: 'Keep the original URL for important links; resolve suspicious short links before opening them.',
          ),
        ),
      ],
    );
  }
}
