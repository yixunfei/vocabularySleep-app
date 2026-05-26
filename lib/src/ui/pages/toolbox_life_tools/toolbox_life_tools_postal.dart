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
    return _lifeText(
      context,
      zh: '暂时无法查询邮编。',
      en: 'Postal lookup is unavailable.',
    );
  }
  if (error is TimeoutException) {
    return _lifeText(
      context,
      zh: '查询超时，请稍后重试或打开来源页面查询。',
      en: 'Lookup timed out. Try again later or open the source page.',
    );
  }
  if (error is FormatException) {
    return _lifeText(
      context,
      zh: '查询结果格式变化，暂时无法解析。',
      en: 'Lookup result format changed and cannot be parsed yet.',
    );
  }
  return _lifeText(
    context,
    zh: '查询失败，请检查网络后重试。',
    en: 'Lookup failed. Check the network and retry.',
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
      title: _lifeText(context, zh: '邮编查询', en: 'Postal lookup'),
      subtitle: _lifeText(
        context,
        zh: '输入城市、网点或地址片段，查询中国邮政网点邮编。',
        en: 'Enter a city, site, or address fragment to find China Post site postal codes.',
      ),
      appBarActions: <Widget>[
        IconButton(
          tooltip: _lifeText(context, zh: '打开中国邮政', en: 'Open China Post'),
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
                      tooltip: _lifeText(context, zh: '清空', en: 'Clear'),
                      onPressed: () {
                        _controller.clear();
                        setState(() {
                          _remoteState = const _PostalRemoteState.initial();
                        });
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
              border: const OutlineInputBorder(),
              labelText: _lifeText(
                context,
                zh: '输入城市/网点/地址，例如：深圳、深圳大学',
                en: 'Enter city/site/address, e.g. Shenzhen, Shenzhen University',
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
              label: Text(_lifeText(context, zh: '查询', en: 'Search')),
            ),
          ),
          const SizedBox(height: 16),
          SectionHeader(
            title: _lifeText(context, zh: '查询结果', en: 'Results'),
            subtitle: _lifeText(
              context,
              zh: '只显示网点、地址、邮编和必要电话；重要邮件仍建议按完整地址复核。',
              en: 'Only key site, address, postal code, and phone details are shown; verify important mail by full address.',
            ),
          ),
          const SizedBox(height: 10),
          if (_remoteState.loading)
            _RemoteLoadingPanel(
              text: _lifeText(
                context,
                zh: '正在查询邮编...',
                en: 'Looking up postal code...',
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
                  _lifeText(context, zh: '邮编查询', en: 'Postal lookup'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  remoteState.loading
                      ? _lifeText(context, zh: '正在查询', en: 'Looking up')
                      : remoteState.error != null
                      ? _postalRemoteErrorText(context, remoteState.error)
                      : remoteState.query.trim().isEmpty
                      ? _lifeText(
                          context,
                          zh: '输入地址、城市或邮编开始查询',
                          en: 'Enter an address, city, or code to search',
                        )
                      : _lifeText(
                          context,
                          zh: '已解析 ${remoteState.entries.length} 条结果',
                          en: '${remoteState.entries.length} results parsed',
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
      title: _lifeText(context, zh: '快速开始', en: 'Quick start'),
      subtitle: _lifeText(
        context,
        zh: '可以输入城市、网点名称或更具体的地址片段。',
        en: 'Enter a city, postal site name, or more specific address fragment.',
      ),
      children: <Widget>[
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              const <_LifeOption<String>>[
                    _LifeOption<String>(
                      value: '深圳',
                      labelZh: '深圳',
                      labelEn: 'Shenzhen',
                    ),
                    _LifeOption<String>(
                      value: '深圳大学',
                      labelZh: '深圳大学',
                      labelEn: 'Shenzhen University',
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
            label: Text(_lifeText(context, zh: '重试', en: 'Retry')),
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
            _lifeText(context, zh: '没有找到邮编', en: 'No postal code found'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _lifeText(
              context,
              zh: '可以换更完整的地址关键词，或打开来源页面继续查询「$query」。',
              en: 'Try a fuller address keyword, or open the source page for "$query".',
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onOpenSource,
            icon: const Icon(Icons.open_in_new_rounded),
            label: Text(_lifeText(context, zh: '打开来源页', en: 'Open source')),
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
      _LifeOption<String>(value: '深圳', labelZh: '深圳', labelEn: 'Shenzhen'),
      _LifeOption<String>(
        value: '深圳大学',
        labelZh: '深圳大学',
        labelEn: 'Shenzhen University',
      ),
      _LifeOption<String>(value: '上海', labelZh: '上海', labelEn: 'Shanghai'),
    ];
    return _LifeSettingsPanel(
      title: _lifeText(context, zh: '查询提示', en: 'Lookup tips'),
      subtitle: _lifeText(
        context,
        zh: '当前来源为中国邮政网点查询，结果通常对应具体邮政网点；寄送重要文件前请按完整地址复核。',
        en: 'The current source is China Post site lookup, so results usually map to specific postal service sites; verify important mail by full address.',
      ),
      children: <Widget>[
        _PostalRuleRow(
          icon: Icons.search_rounded,
          title: _lifeText(
            context,
            zh: '关键词越完整越准确',
            en: 'Fuller keywords help',
          ),
          body: _lifeText(
            context,
            zh: '输入网点名、城市名或更具体的地址片段，更容易定位到可用邮编。',
            en: 'Site names, city names, or more specific address fragments make it easier to find a useful code.',
          ),
        ),
        _PostalRuleRow(
          icon: Icons.fact_check_outlined,
          title: _lifeText(context, zh: '重要邮件先核验', en: 'Verify important mail'),
          body: _lifeText(
            context,
            zh: '证件、合同、发票等重要邮件请用完整地址和收件单位信息再次确认。',
            en: 'For IDs, contracts, invoices, and other important mail, verify with full address and recipient info.',
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
            _lifeText(context, zh: '数据来源', en: 'Data source'),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _lifeText(
              context,
              zh: '结果来自中国邮政网点查询页面。若查询结果不完整，请打开来源页面继续核验。',
              en: 'Results come from China Post site lookup pages. If results look incomplete, open the source page to verify.',
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
                  _lifeText(context, zh: '打开当前来源', en: 'Open source'),
                ),
              ),
              OutlinedButton.icon(
                onPressed: onOpenChinaPost,
                icon: const Icon(Icons.open_in_new_rounded),
                label: Text(_lifeText(context, zh: '中国邮政', en: 'China Post')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
