part of '../toolbox_life_tools.dart';

const String _postalSourceBaseUrl =
    'https://www.chinapost.com.cn/html1/folder/181312/9531-1.htm';
const String _postalChinaPostQueryBaseUrl =
    'https://iframe.chinapost.com.cn/jsp/type/institutionalsite/SiteSearchJT.jsp';
const Duration _postalRemoteTimeout = Duration(seconds: 12);

class _RemotePostalEntry {
  const _RemotePostalEntry({
    required this.area,
    required this.code,
    required this.detail,
    required this.phoneCode,
    required this.sourceUrl,
  });

  final String area;
  final String code;
  final String detail;
  final String phoneCode;
  final String sourceUrl;
}

class _PostalRemoteState {
  const _PostalRemoteState({
    required this.loading,
    required this.entries,
    this.query = '',
    this.sourceUrl = '',
    this.error,
  });

  const _PostalRemoteState.initial()
    : loading = false,
      entries = const <_RemotePostalEntry>[],
      query = '',
      sourceUrl = '',
      error = null;

  final bool loading;
  final List<_RemotePostalEntry> entries;
  final String query;
  final String sourceUrl;
  final Object? error;
}

String _stripHtml(String html) {
  final withoutScripts = html
      .replaceAll(
        RegExp(r'<script[\s\S]*?</script>', caseSensitive: false),
        ' ',
      )
      .replaceAll(RegExp(r'<style[\s\S]*?</style>', caseSensitive: false), ' ');
  final text = withoutScripts
      .replaceAll(RegExp(r'<[^>]+>'), ' ')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#039;', "'")
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  return text;
}

String _decodeHtmlText(String html) {
  return _stripHtml(html)
      .replaceAll(RegExp(r'\s*\(\s*'), '(')
      .replaceAll(RegExp(r'\s*\)\s*'), ')')
      .trim();
}

String _postalPageUrlFor(String query) {
  final trimmed = query.trim();
  if (trimmed.isEmpty) {
    return _postalSourceBaseUrl;
  }
  return '$_postalChinaPostQueryBaseUrl?community=ChinaPostJT&sitename=${Uri.encodeQueryComponent(trimmed)}';
}

List<_RemotePostalEntry> _parsePostalEntries(String html, String sourceUrl) {
  final rows = RegExp(
    r'<tr[^>]*>([\s\S]*?)</tr>',
    caseSensitive: false,
  ).allMatches(html);
  final entries = <_RemotePostalEntry>[];
  for (final row in rows) {
    final cells =
        RegExp(r'<t[dh][^>]*>([\s\S]*?)</t[dh]>', caseSensitive: false)
            .allMatches(row.group(1) ?? '')
            .map((match) {
              return _decodeHtmlText(match.group(1) ?? '');
            })
            .toList(growable: false);
    if (cells.length >= 9 && cells[4].contains('邮编')) {
      continue;
    }
    if (cells.length >= 9) {
      final codeMatch = RegExp(r'\b\d{6}\b').firstMatch(cells[4]);
      if (codeMatch == null) {
        continue;
      }
      final siteName = cells[3].replaceAll(RegExp(r'\s+'), ' ').trim();
      final address = cells[5].replaceAll(RegExp(r'\s+'), ' ').trim();
      final province = cells[0].trim();
      final city = cells[1].trim();
      final county = cells[2].trim();
      final areaParts = <String>[
        if (siteName.isNotEmpty) siteName,
        if (address.isNotEmpty) address,
      ];
      final detailParts = <String>[
        if (province.isNotEmpty) province,
        if (city.isNotEmpty) city,
        if (county.isNotEmpty) county,
      ];
      if (areaParts.isEmpty) {
        continue;
      }
      entries.add(
        _RemotePostalEntry(
          area: areaParts.join(' · '),
          code: codeMatch.group(0)!,
          detail: detailParts.join(' '),
          phoneCode: cells[7].trim(),
          sourceUrl: sourceUrl,
        ),
      );
      continue;
    }
    if (cells.length < 2 || cells.first.contains('地市')) {
      continue;
    }
    final codeMatch = RegExp(r'\b\d{6}\b').firstMatch(cells[1]);
    if (codeMatch == null) {
      continue;
    }
    final area = cells[0].replaceAll(RegExp(r'\s+'), ' ').trim();
    if (area.isEmpty) {
      continue;
    }
    entries.add(
      _RemotePostalEntry(
        area: area,
        code: codeMatch.group(0)!,
        detail: cells.length > 2 ? cells[2] : '',
        phoneCode: cells.length > 3 ? cells[3] : '',
        sourceUrl: sourceUrl,
      ),
    );
  }

  if (entries.isNotEmpty) {
    final seen = <String>{};
    return entries
        .where((entry) {
          final key = '${entry.area}|${entry.code}|${entry.phoneCode}';
          return seen.add(key);
        })
        .take(80)
        .toList(growable: false);
  }

  final title = RegExp(
    r'<h1[^>]*>([\s\S]*?)</h1>',
    caseSensitive: false,
  ).firstMatch(html);
  final area = title == null ? '' : _decodeHtmlText(title.group(1) ?? '');
  final description = RegExp(
    r'<meta\s+name="description"\s+content="([^"]*)"',
    caseSensitive: false,
  ).firstMatch(html);
  final descText = description == null
      ? _stripHtml(html)
      : _decodeHtmlText(description.group(1) ?? '');
  final codeMatches = RegExp(r'\b\d{6}\b').allMatches(descText).toList();
  if (codeMatches.isEmpty) {
    return const <_RemotePostalEntry>[];
  }
  final normalizedArea = area
      .replaceAll(RegExp(r'\s*邮政编码查询.*$'), '')
      .replaceAll(RegExp(r'^邮编'), '')
      .trim();
  return <_RemotePostalEntry>[
    _RemotePostalEntry(
      area: normalizedArea.isEmpty ? descText : normalizedArea,
      code: codeMatches.first.group(0)!,
      detail: descText,
      phoneCode: '',
      sourceUrl: sourceUrl,
    ),
  ];
}

String _postalRemoteErrorText(BuildContext context, Object? error) {
  if (error == null) {
    return _lifeI18nText(
      context,
      'inline.plan295.life.postal_lookup_is_unavailable.dcd060fedd50',
    );
  }
  if (error is TimeoutException) {
    return _lifeI18nText(
      context,
      'inline.plan295.life.lookup_timed_out_try_again_later_or.fb63ba728330',
    );
  }
  if (error is FormatException) {
    return _lifeI18nText(
      context,
      'inline.plan295.life.lookup_result_format_changed_and_can.72a2868769e9',
    );
  }
  return _lifeI18nText(
    context,
    'inline.plan295.life.lookup_failed_check_the_network_and.dfa19d45fe2e',
  );
}

class _PostalLookupToolPage extends StatefulWidget {
  const _PostalLookupToolPage();

  @override
  State<_PostalLookupToolPage> createState() => _PostalLookupToolPageState();
}

class _PostalLookupToolPageState extends State<_PostalLookupToolPage> {
  final TextEditingController _controller = TextEditingController();
  _PostalRemoteState _remoteState = const _PostalRemoteState.initial();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _runRemoteQuery([String? rawQuery]) async {
    final query = (rawQuery ?? _controller.text).trim();
    if (query.isEmpty) {
      setState(() => _remoteState = const _PostalRemoteState.initial());
      return;
    }
    setState(() {
      _remoteState = _PostalRemoteState(
        loading: true,
        entries: const <_RemotePostalEntry>[],
        query: query,
        sourceUrl: _postalPageUrlFor(query),
      );
    });
    try {
      final sourceUrl = _postalPageUrlFor(query);
      final response = await http
          .get(
            Uri.parse(sourceUrl),
            headers: const <String, String>{
              'Accept':
                  'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
              'User-Agent': 'Mozilla/5.0 vocabulary-sleep-app',
            },
          )
          .timeout(_postalRemoteTimeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('HTTP ${response.statusCode}');
      }
      final html = utf8.decode(response.bodyBytes);
      final entries = _parsePostalEntries(html, sourceUrl);
      if (!mounted) {
        return;
      }
      setState(() {
        _remoteState = _PostalRemoteState(
          loading: false,
          entries: entries,
          query: query,
          sourceUrl: sourceUrl,
        );
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _remoteState = _PostalRemoteState(
          loading: false,
          entries: const <_RemotePostalEntry>[],
          query: query,
          sourceUrl: _postalPageUrlFor(query),
          error: error,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ToolboxToolPage(
      title: _lifeI18nText(
        context,
        'inline.plan295.life.postal_lookup.1ce6c88311a4',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.enter_a_city_site_or_address_fragmen.0435accd37ad',
      ),
      appBarActions: <Widget>[
        IconButton(
          tooltip: _lifeI18nText(
            context,
            'inline.plan295.life.open_china_post.cf77c8de48bb',
          ),
          onPressed: () {
            _openExternal(context, _postalSourceBaseUrl);
          },
          icon: const Icon(Icons.open_in_new_rounded),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _PostalHeroCard(remoteState: _remoteState),
          const SizedBox(height: 14),
          TextField(
            key: const ValueKey<String>('life_postal_search_field'),
            controller: _controller,
            textInputAction: TextInputAction.search,
            keyboardType: TextInputType.streetAddress,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _controller.text.trim().isEmpty
                  ? null
                  : IconButton(
                      tooltip: _lifeI18nText(
                        context,
                        'inline.plan294.zen_sand.clear_ea17218b',
                      ),
                      onPressed: () {
                        _controller.clear();
                        setState(() {
                          _remoteState = const _PostalRemoteState.initial();
                        });
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
              border: const OutlineInputBorder(),
              labelText: _lifeI18nText(
                context,
                'inline.plan295.life.enter_city_site_address_e_g_shenzhen.0723eca5c713',
              ),
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: _runRemoteQuery,
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _remoteState.loading ? null : _runRemoteQuery,
              icon: const Icon(Icons.search_rounded),
              label: Text(
                _lifeI18nText(
                  context,
                  'inline.plan295.life.search.229b0d36efee',
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SectionHeader(
            title: _lifeI18nText(
              context,
              'inline.plan295.life.results.f26b34f465de',
            ),
            subtitle: _lifeI18nText(
              context,
              'inline.plan295.life.only_key_site_address_postal_code_an.faab52cc9adb',
            ),
          ),
          const SizedBox(height: 10),
          if (_remoteState.loading)
            _RemoteLoadingPanel(
              text: _lifeI18nText(
                context,
                'inline.plan295.life.looking_up_postal_code.1d272437dd4a',
              ),
            )
          else if (_remoteState.error != null)
            _PostalErrorPanel(
              error: _remoteState.error,
              onRetry: () => _runRemoteQuery(_remoteState.query),
            )
          else if (_remoteState.query.trim().isEmpty)
            _PostalStartPanel(onExampleTap: _setExampleAndQuery)
          else if (_remoteState.entries.isEmpty)
            _PostalEmptyState(
              query: _remoteState.query,
              onOpenSource: () {
                _openExternal(context, _remoteState.sourceUrl);
              },
            )
          else
            for (final entry in _remoteState.entries) ...<Widget>[
              _PostalResultCard(entry: entry),
              const SizedBox(height: 8),
            ],
          const SizedBox(height: 8),
          _PostalRulePanel(onExampleTap: _setExampleAndQuery),
          const SizedBox(height: 12),
          _PostalSourcePanel(
            sourceUrl: _remoteState.sourceUrl.isEmpty
                ? _postalSourceBaseUrl
                : _remoteState.sourceUrl,
            onOpenChinaPost: () {
              _openExternal(
                context,
                'https://www.chinapost.com.cn/html1/folder/181312/9531-1.htm',
              );
            },
            onOpenSource: () {
              _openExternal(
                context,
                _remoteState.sourceUrl.isEmpty
                    ? _postalSourceBaseUrl
                    : _remoteState.sourceUrl,
              );
            },
          ),
        ],
      ),
    );
  }

  void _setExampleAndQuery(String text) {
    _controller.text = text;
    _controller.selection = TextSelection.collapsed(offset: text.length);
    unawaited(_runRemoteQuery(text));
  }
}

class _PostalHeroCard extends StatelessWidget {
  const _PostalHeroCard({required this.remoteState});

  final _PostalRemoteState remoteState;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.local_post_office_rounded,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _lifeI18nText(
                    context,
                    'inline.plan295.life.postal_lookup.1ce6c88311a4',
                  ),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  remoteState.loading
                      ? _lifeI18nText(
                          context,
                          'inline.plan295.life.looking_up.27bb54323dbd',
                        )
                      : remoteState.error != null
                      ? _postalRemoteErrorText(context, remoteState.error)
                      : remoteState.query.trim().isEmpty
                      ? _lifeI18nText(
                          context,
                          'inline.plan295.life.enter_an_address_city_or_code_to_sea.60f3a3f6fe21',
                        )
                      : _lifeI18nText(
                          context,
                          'inline.plan296.ui.pages.toolbox.life.tools.toolbox.life.tools.postal.results_parsed.72c3d609ff',
                          params: <String, Object?>{
                            'length': remoteState.entries.length,
                          },
                        ),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PostalResultCard extends StatelessWidget {
  const _PostalResultCard({required this.entry});

  final _RemotePostalEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const color = Color(0xFF2F8B74);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.local_post_office_rounded,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      entry.area,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: <Widget>[
                        _PostalPill(
                          icon: Icons.numbers_rounded,
                          text: entry.code,
                          color: color,
                        ),
                        if (entry.phoneCode.trim().isNotEmpty)
                          _PostalPill(
                            icon: Icons.call_rounded,
                            text: entry.phoneCode,
                            color: theme.colorScheme.primary,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PostalPill extends StatelessWidget {
  const _PostalPill({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PostalStartPanel extends StatelessWidget {
  const _PostalStartPanel({required this.onExampleTap});

  final ValueChanged<String> onExampleTap;

  @override
  Widget build(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeI18nText(
        context,
        'inline.ui.pages.practice_page.quick_start_c5b829',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.enter_a_city_postal_site_name_or_mor.995dc6c2042f',
      ),
      children: <Widget>[
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              const <_LifeOption<String>>[
                    _LifeOption<String>(
                      value: '深圳',
                      labelKey: 'inline.plan295.life.shenzhen.90fa94d03930',
                    ),
                    _LifeOption<String>(
                      value: '深圳大学',
                      labelKey:
                          'inline.plan295.life.shenzhen_university.ba2996aeb454',
                    ),
                  ]
                  .map((example) {
                    return ActionChip(
                      avatar: const Icon(Icons.search_rounded, size: 18),
                      label: Text(example.label(context)),
                      onPressed: () => onExampleTap(example.value),
                    );
                  })
                  .toList(growable: false),
        ),
      ],
    );
  }
}

class _PostalErrorPanel extends StatelessWidget {
  const _PostalErrorPanel({required this.error, required this.onRetry});

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context).colorScheme.error.withValues(alpha: 0.24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(_postalRemoteErrorText(context, error)),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(
              _lifeI18nText(context, 'inline.plan295.life.retry.da2bb8aff35f'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PostalEmptyState extends StatelessWidget {
  const _PostalEmptyState({required this.query, required this.onOpenSource});

  final String query;
  final VoidCallback onOpenSource;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            _lifeI18nText(
              context,
              'inline.plan295.life.no_postal_code_found.7c002ec4f4b1',
            ),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _lifeI18nText(
              context,
              'inline.plan296.ui.pages.toolbox.life.tools.toolbox.life.tools.postal.try_a_fuller_address_keyword_or.5b714b384e',
              params: <String, Object?>{'query': query},
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onOpenSource,
            icon: const Icon(Icons.open_in_new_rounded),
            label: Text(
              _lifeI18nText(
                context,
                'inline.plan295.life.open_source.132faf4b4128',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PostalRulePanel extends StatelessWidget {
  const _PostalRulePanel({required this.onExampleTap});

  final ValueChanged<String> onExampleTap;

  @override
  Widget build(BuildContext context) {
    const examples = <_LifeOption<String>>[
      _LifeOption<String>(
        value: '深圳',
        labelKey: 'inline.plan295.life.shenzhen.90fa94d03930',
      ),
      _LifeOption<String>(
        value: '深圳大学',
        labelKey: 'inline.plan295.life.shenzhen_university.ba2996aeb454',
      ),
      _LifeOption<String>(
        value: '上海',
        labelKey: 'inline.plan295.life.shanghai.ae22662abff7',
      ),
    ];
    return _LifeSettingsPanel(
      title: _lifeI18nText(
        context,
        'inline.plan295.life.lookup_tips.c209a8141692',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.the_current_source_is_china_post_sit.b2dc3aa7e571',
      ),
      children: <Widget>[
        _PostalRuleRow(
          icon: Icons.search_rounded,
          title: _lifeI18nText(
            context,
            'inline.plan295.life.fuller_keywords_help.ea56d11ee33a',
          ),
          body: _lifeI18nText(
            context,
            'inline.plan295.life.site_names_city_names_or_more_specif.fe1362941dcd',
          ),
        ),
        _PostalRuleRow(
          icon: Icons.fact_check_outlined,
          title: _lifeI18nText(
            context,
            'inline.plan295.life.verify_important_mail.f6fb9e5e7145',
          ),
          body: _lifeI18nText(
            context,
            'inline.plan295.life.for_ids_contracts_invoices_and_other.f295819ca4ae',
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: examples
              .map((example) {
                return ActionChip(
                  avatar: const Icon(Icons.search_rounded, size: 18),
                  label: Text(example.label(context)),
                  onPressed: () => onExampleTap(example.value),
                );
              })
              .toList(growable: false),
        ),
      ],
    );
  }
}

class _PostalRuleRow extends StatelessWidget {
  const _PostalRuleRow({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 21, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(body, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PostalSourcePanel extends StatelessWidget {
  const _PostalSourcePanel({
    required this.sourceUrl,
    required this.onOpenChinaPost,
    required this.onOpenSource,
  });

  final String sourceUrl;
  final VoidCallback onOpenChinaPost;
  final VoidCallback onOpenSource;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.secondary.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            _lifeI18nText(
              context,
              'inline.plan295.life.data_source.9dd4d43ace21',
            ),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _lifeI18nText(
              context,
              'inline.plan295.life.results_come_from_china_post_site_lo.42872ef54ddb',
            ),
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          SelectableText(sourceUrl, style: theme.textTheme.labelSmall),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: onOpenSource,
                icon: const Icon(Icons.open_in_new_rounded),
                label: Text(
                  _lifeI18nText(
                    context,
                    'inline.plan295.life.open_source.e9b30cc4cd21',
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: onOpenChinaPost,
                icon: const Icon(Icons.open_in_new_rounded),
                label: Text(
                  _lifeI18nText(
                    context,
                    'inline.plan295.life.china_post.b9253533d982',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
