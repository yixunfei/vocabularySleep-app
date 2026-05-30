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
        _error = _lifeI18nText(
          context,
          'inline.plan296.ui.pages.toolbox.life.tools.toolbox.life.tools.short.link.shorten_failed.5a82904b2f',
          params: <String, Object?>{'error': error},
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
        _error = _lifeI18nText(
          context,
          'inline.plan296.ui.pages.toolbox.life.tools.toolbox.life.tools.short.link.resolve_failed.6d15e64163',
          params: <String, Object?>{'error': error},
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
      SnackBar(
        content: Text(
          _lifeI18nText(context, 'inline.plan295.life.copied.a6c8d9ea9fe1'),
        ),
      ),
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
      ToolboxShortLinkProvider.tinyUrl => _lifeI18nText(
        context,
        'inline.plan295.life.public_short_link_service_with_broad.e4b33e3de4f0',
      ),
      ToolboxShortLinkProvider.isGd => _lifeI18nText(
        context,
        'inline.plan295.life.public_short_link_service_with_optio.37730165bd44',
      ),
      ToolboxShortLinkProvider.vGd => _lifeI18nText(
        context,
        'inline.plan295.life.sister_service_of_is_gd_useful_as_a.08585409239d',
      ),
      ToolboxShortLinkProvider.cleanUri => _lifeI18nText(
        context,
        'inline.plan295.life.public_json_api_without_custom_alias.60178585c953',
      ),
      ToolboxShortLinkProvider.localAlias => _lifeI18nText(
        context,
        'inline.plan295.life.offline_local_code_not_a_public_web.76a977be6189',
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final shortResult = _shortResult;
    final resolveResult = _resolveResult;
    final normalizedPreview = _previewNormalizedUrl();
    return ToolboxToolPage(
      title: _lifeI18nText(
        context,
        'inline.plan295.life.short_link_tool.001f0902e016',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.generate_public_short_links_create_l.be33e93db1c0',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _LifeSettingsPanel(
            title: _lifeI18nText(
              context,
              'inline.plan295.life.link_workspace.e59142692d69',
            ),
            subtitle: _lifeI18nText(
              context,
              'inline.plan295.life.enter_a_long_url_or_a_short_url_gene.07aa7b9f58bb',
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
                  labelText: _lifeI18nText(
                    context,
                    'inline.plan295.life.target_url.49ad3b681ba7',
                  ),
                  helperText: normalizedPreview,
                ),
              ),
              const SizedBox(height: 12),
              _LifeSegmentedField<ToolboxShortLinkProvider>(
                label: _lifeI18nText(
                  context,
                  'inline.plan295.life.short_link_service.6ca9834aadff',
                ),
                value: _provider,
                options: ToolboxShortLinkProvider.values
                    .map(
                      (provider) => _LifeOption<ToolboxShortLinkProvider>(
                        value: provider,
                        labelText: provider.label,
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
              Text(
                _providerHelp(_provider),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (_provider.supportsCustomAlias) ...<Widget>[
                const SizedBox(height: 12),
                TextField(
                  key: const ValueKey<String>('life-short-link-alias-field'),
                  controller: _aliasController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.badge_rounded),
                    border: const OutlineInputBorder(),
                    labelText: _lifeI18nText(
                      context,
                      'inline.plan295.life.custom_alias_optional.f3e5d7ebd0ac',
                    ),
                    helperText: _lifeI18nText(
                      context,
                      'inline.plan295.life.letters_digits_dash_and_underscore_o.7d3b3db6c033',
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
                            ? _lifeI18nText(
                                context,
                                'inline.plan295.crypto.working.c85bfe260dff',
                              )
                            : _lifeI18nText(
                                context,
                                'inline.plan295.life.shorten.bf4e585344eb',
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const ValueKey<String>(
                        'life-short-link-resolve-button',
                      ),
                      onPressed: _busy ? null : _resolve,
                      icon: const Icon(Icons.route_rounded),
                      label: Text(
                        _lifeI18nText(
                          context,
                          'inline.plan295.life.resolve.18c98f4fc74f',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_error != null)
            _buildMessagePanel(context, _error!, isError: true),
          if (shortResult != null) ...<Widget>[
            _buildShortResult(context, shortResult),
            const SizedBox(height: 12),
          ],
          if (resolveResult != null)
            _buildResolveResult(context, resolveResult),
          const SizedBox(height: 12),
          _buildBoundaryNote(context),
        ],
      ),
    );
  }

  String _previewNormalizedUrl() {
    try {
      return ToolboxShortLinkService.normalizeUrl(
        _urlController.text,
      ).toString();
    } catch (_) {
      return _lifeI18nText(
        context,
        'inline.plan295.life.you_may_omit_https_it_will_be_added.d8500797c41c',
      );
    }
  }

  Widget _buildShortResult(
    BuildContext context,
    ToolboxShortLinkResult result,
  ) {
    final theme = Theme.of(context);
    return _LifeSettingsPanel(
      title: _lifeI18nText(
        context,
        'inline.plan295.life.generated_link.29c1ecc58ebf',
      ),
      subtitle: result.provider.usesNetwork
          ? _lifeI18nText(
              context,
              'inline.plan296.ui.pages.toolbox.life.tools.toolbox.life.tools.short.link.public_short_link_returned_by.b564f951df',
              params: <String, Object?>{'label': result.provider.label},
            )
          : _lifeI18nText(
              context,
              'inline.plan295.life.local_alias_is_a_record_label_only.644852e91378',
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
              label: Text(
                _lifeI18nText(context, 'inline.plan295.life.copy.01b0f824dc50'),
              ),
            ),
            OutlinedButton.icon(
              onPressed: result.provider.usesNetwork ? _useShortAsInput : null,
              icon: const Icon(Icons.input_rounded),
              label: Text(
                _lifeI18nText(
                  context,
                  'inline.plan295.life.use_as_input.e33cf320293d',
                ),
              ),
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
      title: _lifeI18nText(
        context,
        'inline.plan295.life.redirect_chain.f12ecc1dc6b0',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan296.ui.pages.toolbox.life.tools.toolbox.life.tools.short.link.redirects_final_url_is_shown_below.d38584a55b',
        params: <String, Object?>{'redirectCount': result.redirectCount},
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
          label: Text(
            _lifeI18nText(
              context,
              'inline.plan295.life.copy_final_url.18edb20e6e6a',
            ),
          ),
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
            _lifeI18nText(
              context,
              'inline.plan295.life.max_redirect_depth_reached_the_final.9658f9e91af7',
            ),
            isError: true,
          ),
        ],
      ],
    );
  }

  Widget _buildHopTile(
    BuildContext context,
    int index,
    ToolboxShortLinkHop hop,
  ) {
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
            _lifeI18nText(
              context,
              'inline.plan296.ui.pages.toolbox.life.tools.toolbox.life.tools.short.link.step_http.dee4f01093',
              params: <String, Object?>{
                'index': index,
                'statusCode': hop.statusCode,
              },
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
    final color = isError
        ? theme.colorScheme.error
        : theme.colorScheme.tertiary;
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
      title: _lifeI18nText(
        context,
        'inline.plan295.life.boundary.b72c98dd2a1f',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.public_links_depend_on_third_party_s.4f4947e17a0a',
      ),
      children: <Widget>[
        Text(
          _lifeI18nText(
            context,
            'inline.plan295.life.keep_the_original_url_for_important.8458e4b56d33',
          ),
        ),
      ],
    );
  }
}
