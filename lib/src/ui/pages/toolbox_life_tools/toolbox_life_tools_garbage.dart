part of '../toolbox_life_tools.dart';

const String _garbageRemoteDataUrl =
    'https://static.res.qq.com/nav/qbtool/resource/garbage.json';
const Duration _garbageRemoteTimeout = Duration(seconds: 12);

enum _GarbageCategory {
  recyclable,
  hazardous,
  kitchen,
  residual,
  bulky,
  unknown,
}

class _GarbageCategoryInfo {
  const _GarbageCategoryInfo({
    required this.titleKey,
    required this.shortKey,
    required this.guideKey,
    required this.color,
    required this.icon,
  });

  final String titleKey;
  final String shortKey;
  final String guideKey;
  final Color color;
  final IconData icon;
}

class _RemoteGarbageItem {
  const _RemoteGarbageItem({
    required this.name,
    required this.category,
    required this.rawCategory,
  });

  final String name;
  final _GarbageCategory category;
  final int rawCategory;

  bool matches(String keyword) {
    final q = keyword.trim().toLowerCase();
    if (q.isEmpty) {
      return true;
    }
    final normalizedName = name.trim().toLowerCase();
    return normalizedName.contains(q) || q.contains(normalizedName);
  }
}

class _GarbageRemoteState {
  const _GarbageRemoteState({
    required this.loading,
    required this.items,
    this.error,
  });

  const _GarbageRemoteState.initial()
    : loading = false,
      items = const <_RemoteGarbageItem>[],
      error = null;

  final bool loading;
  final List<_RemoteGarbageItem> items;
  final Object? error;
}

const Map<_GarbageCategory, _GarbageCategoryInfo>
_garbageCategoryInfos = <_GarbageCategory, _GarbageCategoryInfo>{
  _GarbageCategory.recyclable: _GarbageCategoryInfo(
    titleKey: 'inline.plan295.life.recyclable.f9500e64e94d',
    shortKey:
        'inline.plan295.life.suitable_for_reuse_and_recycling.f010d7c8fbee',
    guideKey:
        'inline.plan295.life.empty_and_keep_items_dry_where_possi.76151a96209d',
    color: Color(0xFF2878C8),
    icon: Icons.recycling_rounded,
  ),
  _GarbageCategory.hazardous: _GarbageCategoryInfo(
    titleKey: 'inline.plan295.life.hazardous.d1634d861daf',
    shortKey: 'inline.plan295.life.contains_harmful_substances.ba36a3c60d57',
    guideKey:
        'inline.plan295.life.keep_sealed_and_intact_then_use_desi.b8d31f6df1da',
    color: Color(0xFFD34B4B),
    icon: Icons.warning_amber_rounded,
  ),
  _GarbageCategory.kitchen: _GarbageCategoryInfo(
    titleKey: 'inline.plan295.life.wet_or_kitchen_waste.71544bee65f0',
    shortKey:
        'inline.plan295.life.perishable_organic_household_waste.ad970a06df3f',
    guideKey:
        'inline.plan295.life.drain_liquid_first_and_remove_bags_t.fc03573af050',
    color: Color(0xFF3F8F57),
    icon: Icons.restaurant_rounded,
  ),
  _GarbageCategory.residual: _GarbageCategoryInfo(
    titleKey: 'inline.plan295.life.dry_or_residual_waste.59ffef94c58d',
    shortKey:
        'inline.plan295.life.not_currently_recyclable_or_composta.d4cedf254e4e',
    guideKey:
        'inline.plan295.life.compress_when_possible_contaminated.b9a8e4b3f959',
    color: Color(0xFF6F7480),
    icon: Icons.delete_outline_rounded,
  ),
  _GarbageCategory.bulky: _GarbageCategoryInfo(
    titleKey: 'inline.plan295.life.bulky_waste.50e657389b6d',
    shortKey:
        'inline.plan295.life.needs_appointment_or_special_handlin.44a00c5df6f7',
    guideKey:
        'inline.plan295.life.do_not_put_it_in_regular_bins_contac.f7ab69c9e407',
    color: Color(0xFF8B6B2F),
    icon: Icons.local_shipping_rounded,
  ),
  _GarbageCategory.unknown: _GarbageCategoryInfo(
    titleKey: 'inline.plan295.life.unknown.77495444af30',
    shortKey:
        'inline.plan295.life.no_mapped_category_from_remote_data.8569fd1e2c06',
    guideKey:
        'inline.plan295.life.open_the_source_page_or_confirm_with.b8d63013288a',
    color: Color(0xFF7C8794),
    icon: Icons.help_outline_rounded,
  ),
};

_GarbageCategory _garbageCategoryFromRemote(int category) {
  return switch (category) {
    1 => _GarbageCategory.recyclable,
    2 => _GarbageCategory.hazardous,
    4 => _GarbageCategory.kitchen,
    8 => _GarbageCategory.residual,
    16 => _GarbageCategory.bulky,
    _ => _GarbageCategory.unknown,
  };
}

String _garbageRemoteErrorText(BuildContext context, Object? error) {
  if (error == null) {
    return _lifeI18nText(
      context,
      'inline.plan295.life.remote_data_is_unavailable.0ab147a67d91',
    );
  }
  if (error is TimeoutException) {
    return _lifeI18nText(
      context,
      'inline.plan295.life.remote_request_timed_out_try_again_l.89a0262b1fe1',
    );
  }
  if (error is FormatException) {
    return _lifeI18nText(
      context,
      'inline.plan295.life.remote_data_format_changed_and_canno.5cf415e18f7c',
    );
  }
  return _lifeI18nText(
    context,
    'inline.plan295.life.remote_request_failed_check_the_netw.240a58074f47',
  );
}

class _GarbageSortingToolPage extends StatefulWidget {
  const _GarbageSortingToolPage();

  @override
  State<_GarbageSortingToolPage> createState() =>
      _GarbageSortingToolPageState();
}

class _GarbageSortingToolPageState extends State<_GarbageSortingToolPage> {
  final TextEditingController _controller = TextEditingController();
  _GarbageCategory? _selectedCategory;
  String _query = '';
  _GarbageRemoteState _remoteState = const _GarbageRemoteState.initial();

  @override
  void initState() {
    super.initState();
    unawaited(_loadRemoteData());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadRemoteData() async {
    setState(() {
      _remoteState = const _GarbageRemoteState(
        loading: true,
        items: <_RemoteGarbageItem>[],
      );
    });
    try {
      final response = await http
          .get(
            Uri.parse(_garbageRemoteDataUrl),
            headers: const <String, String>{
              'Accept': 'application/json,text/plain,*/*',
              'User-Agent': 'Mozilla/5.0 vocabulary-sleep-app',
            },
          )
          .timeout(_garbageRemoteTimeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('HTTP ${response.statusCode}');
      }
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! List) {
        throw const FormatException('Garbage remote data is not a list.');
      }
      final items = decoded
          .map((raw) {
            if (raw is! Map) {
              return null;
            }
            final name = raw['name']?.toString().trim() ?? '';
            final category = int.tryParse(raw['category']?.toString() ?? '');
            if (name.isEmpty || category == null) {
              return null;
            }
            return _RemoteGarbageItem(
              name: name,
              category: _garbageCategoryFromRemote(category),
              rawCategory: category,
            );
          })
          .whereType<_RemoteGarbageItem>()
          .toList(growable: false);
      if (!mounted) {
        return;
      }
      setState(() {
        _remoteState = _GarbageRemoteState(loading: false, items: items);
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _remoteState = _GarbageRemoteState(
          loading: false,
          items: const <_RemoteGarbageItem>[],
          error: error,
        );
      });
    }
  }

  List<_RemoteGarbageItem> get _results {
    final query = _query.trim();
    if (query.isEmpty) {
      return const <_RemoteGarbageItem>[];
    }
    final filtered = _remoteState.items
        .where((item) {
          final passQuery = item.matches(query);
          final passCategory =
              _selectedCategory == null || item.category == _selectedCategory;
          return passQuery && passCategory;
        })
        .toList(growable: false);
    return filtered.take(80).toList(growable: false);
  }

  int _categoryCount(_GarbageCategory category) {
    return _remoteState.items.where((item) => item.category == category).length;
  }

  @override
  Widget build(BuildContext context) {
    return ToolboxToolPage(
      title: _lifeI18nText(
        context,
        'inline.plan295.life.garbage_sorting.3e693c2be494',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.fetch_tencent_remote_sorting_data_an.eea3a46eac10',
      ),
      appBarActions: <Widget>[
        IconButton(
          tooltip: _lifeI18nText(
            context,
            'inline.plan295.life.refresh_remote_data.6a4c3aad5934',
          ),
          onPressed: _remoteState.loading ? null : _loadRemoteData,
          icon: const Icon(Icons.refresh_rounded),
        ),
        IconButton(
          tooltip: _lifeI18nText(
            context,
            'inline.plan295.life.open_online_query.f769c47dbfe1',
          ),
          onPressed: () {
            _openExternal(context, 'https://tool.browser.qq.com/garbage.html');
          },
          icon: const Icon(Icons.open_in_new_rounded),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _GarbageHeroCard(
            totalCount: _remoteState.items.length,
            loading: _remoteState.loading,
            error: _remoteState.error,
            selectedCategory: _selectedCategory,
            onCategoryTap: (category) {
              setState(() {
                _selectedCategory = _selectedCategory == category
                    ? null
                    : category;
              });
            },
            onRetry: _loadRemoteData,
          ),
          const SizedBox(height: 14),
          TextField(
            key: const ValueKey<String>('life_garbage_search_field'),
            controller: _controller,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: _lifeI18nText(
                        context,
                        'inline.plan294.zen_sand.clear_ea17218b',
                      ),
                      onPressed: () {
                        _controller.clear();
                        setState(() => _query = '');
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
              border: const OutlineInputBorder(),
              labelText: _lifeI18nText(
                context,
                'inline.plan295.life.search_remote_data_e_g_tissue_apple.16ca974913a8',
              ),
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 12),
          _GarbageCategoryFilters(
            selectedCategory: _selectedCategory,
            countFor: _categoryCount,
            onChanged: (category) {
              setState(() {
                _selectedCategory = _selectedCategory == category
                    ? null
                    : category;
              });
            },
          ),
          const SizedBox(height: 16),
          SectionHeader(
            title: _lifeI18nText(
              context,
              'inline.plan295.life.results.f26b34f465de',
            ),
            subtitle: _lifeI18nText(
              context,
              'inline.plan295.life.enter_an_item_name_to_show_matches_l.1f117f850486',
            ),
          ),
          const SizedBox(height: 10),
          if (_remoteState.loading)
            _RemoteLoadingPanel(
              text: _lifeI18nText(
                context,
                'inline.plan295.life.fetching_remote_sorting_data.abf2d5749d24',
              ),
            )
          else if (_remoteState.error != null)
            _GarbageErrorPanel(
              error: _remoteState.error,
              onRetry: _loadRemoteData,
            )
          else if (_query.trim().isEmpty)
            _GarbageStartPanel(
              onOpenOnline: () {
                _openExternal(
                  context,
                  'https://tool.browser.qq.com/garbage.html',
                );
              },
            )
          else if (_results.isEmpty)
            _GarbageEmptyState(
              query: _query,
              selectedCategory: _selectedCategory,
              onOpenOnline: () {
                _openExternal(
                  context,
                  'https://tool.browser.qq.com/garbage.html',
                );
              },
            )
          else
            for (final item in _results) ...<Widget>[
              _GarbageResultCard(item: item),
              const SizedBox(height: 8),
            ],
          const SizedBox(height: 8),
          _GarbageRulePanel(
            onExampleTap: (text) {
              _controller.text = text;
              _controller.selection = TextSelection.collapsed(
                offset: text.length,
              );
              setState(() => _query = text);
            },
          ),
          const SizedBox(height: 12),
          _GarbageSourcePanel(
            onOpenOnline: () {
              _openExternal(
                context,
                'https://tool.browser.qq.com/garbage.html',
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RemoteLoadingPanel extends StatelessWidget {
  const _RemoteLoadingPanel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        children: <Widget>[
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _GarbageHeroCard extends StatelessWidget {
  const _GarbageHeroCard({
    required this.totalCount,
    required this.loading,
    required this.error,
    required this.selectedCategory,
    required this.onCategoryTap,
    required this.onRetry,
  });

  final int totalCount;
  final bool loading;
  final Object? error;
  final _GarbageCategory? selectedCategory;
  final ValueChanged<_GarbageCategory> onCategoryTap;
  final VoidCallback onRetry;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.cloud_sync_rounded,
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
                        'inline.plan295.life.remote_sorting_data.4e956901969a',
                      ),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      loading
                          ? _lifeI18nText(
                              context,
                              'inline.plan295.life.fetching_tencent_remote_resource.368123ac9337',
                            )
                          : error == null
                          ? _lifeI18nText(
                              context,
                              'inline.plan296.ui.pages.toolbox.life.tools.toolbox.life.tools.garbage.remote_sorting_records_loaded.7256467f49',
                              params: <String, Object?>{
                                'totalCount': totalCount,
                              },
                            )
                          : _garbageRemoteErrorText(context, error),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (error != null && !loading)
                IconButton(
                  tooltip: _lifeI18nText(
                    context,
                    'inline.plan295.life.retry.da2bb8aff35f',
                  ),
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _GarbageCategory.values
                .where((category) => category != _GarbageCategory.unknown)
                .map((category) {
                  final info = _garbageCategoryInfos[category]!;
                  final selected = selectedCategory == category;
                  return _GarbageCategoryChip(
                    info: info,
                    selected: selected,
                    onTap: () => onCategoryTap(category),
                  );
                })
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _GarbageCategoryFilters extends StatelessWidget {
  const _GarbageCategoryFilters({
    required this.selectedCategory,
    required this.countFor,
    required this.onChanged,
  });

  final _GarbageCategory? selectedCategory;
  final int Function(_GarbageCategory category) countFor;
  final ValueChanged<_GarbageCategory?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        ChoiceChip(
          selected: selectedCategory == null,
          label: Text(_lifeI18nText(context, 'all')),
          onSelected: (_) => onChanged(null),
        ),
        for (final category in _GarbageCategory.values)
          if (category != _GarbageCategory.unknown)
            ChoiceChip(
              selected: selectedCategory == category,
              avatar: Icon(
                _garbageCategoryInfos[category]!.icon,
                size: 18,
                color: selectedCategory == category
                    ? null
                    : _garbageCategoryInfos[category]!.color,
              ),
              label: Text(
                '${_lifeI18nText(context, _garbageCategoryInfos[category]!.titleKey)} ${countFor(category)}',
              ),
              onSelected: (_) => onChanged(category),
            ),
      ],
    );
  }
}

class _GarbageCategoryChip extends StatelessWidget {
  const _GarbageCategoryChip({
    required this.info,
    required this.selected,
    required this.onTap,
  });

  final _GarbageCategoryInfo info;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = _lifeI18nText(context, info.titleKey);
    return Tooltip(
      message: _lifeI18nText(context, info.guideKey),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? info.color.withValues(alpha: 0.18)
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? info.color : theme.colorScheme.outlineVariant,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(info.icon, size: 18, color: info.color),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GarbageResultCard extends StatelessWidget {
  const _GarbageResultCard({required this.item});

  final _RemoteGarbageItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final info = _garbageCategoryInfos[item.category]!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: info.color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: info.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(info.icon, color: info.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: <Widget>[
                        _GarbagePill(
                          icon: info.icon,
                          text: _lifeI18nText(context, info.titleKey),
                          color: info.color,
                        ),
                        _GarbagePill(
                          icon: Icons.cloud_done_rounded,
                          text: _lifeI18nText(
                            context,
                            'inline.plan296.ui.pages.toolbox.life.tools.toolbox.life.tools.garbage.remote_category.89f188c568',
                            params: <String, Object?>{
                              'rawCategory': item.rawCategory,
                            },
                          ),
                          color: theme.colorScheme.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(_lifeI18nText(context, info.shortKey)),
          const SizedBox(height: 8),
          Text(
            _lifeI18nText(context, info.guideKey),
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _GarbagePill extends StatelessWidget {
  const _GarbagePill({
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
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _GarbageErrorPanel extends StatelessWidget {
  const _GarbageErrorPanel({required this.error, required this.onRetry});

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
          Text(_garbageRemoteErrorText(context, error)),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(
              _lifeI18nText(context, 'inline.plan295.life.retry.5fa085a7caca'),
            ),
          ),
        ],
      ),
    );
  }
}

class _GarbageStartPanel extends StatelessWidget {
  const _GarbageStartPanel({required this.onOpenOnline});

  final VoidCallback onOpenOnline;

  @override
  Widget build(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeI18nText(
        context,
        'inline.plan295.life.start_search.cc85f951d7c6',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.enter_an_item_name_to_search_or_open.da89bcf2734a',
      ),
      children: <Widget>[
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: onOpenOnline,
            icon: const Icon(Icons.open_in_new_rounded),
            label: Text(
              _lifeI18nText(
                context,
                'inline.plan295.life.open_online_query.f769c47dbfe1',
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GarbageEmptyState extends StatelessWidget {
  const _GarbageEmptyState({
    required this.query,
    required this.selectedCategory,
    required this.onOpenOnline,
  });

  final String query;
  final _GarbageCategory? selectedCategory;
  final VoidCallback onOpenOnline;

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
              'inline.plan295.life.no_remote_match_yet.a0590bbf8514',
            ),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            selectedCategory == null
                ? _lifeI18nText(
                    context,
                    'inline.plan295.life.try_another_common_name_or_open_the.a1163c2aac83',
                    params: <String, Object?>{'query': query},
                  )
                : _lifeI18nText(
                    context,
                    'inline.plan295.life.no_result_under_this_category_filter.6e6727353522',
                    params: <String, Object?>{'query': query},
                  ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onOpenOnline,
            icon: const Icon(Icons.open_in_new_rounded),
            label: Text(
              _lifeI18nText(
                context,
                'inline.plan295.life.open_tencent_query.c1c53b74a1ee',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GarbageRulePanel extends StatelessWidget {
  const _GarbageRulePanel({required this.onExampleTap});

  final ValueChanged<String> onExampleTap;

  @override
  Widget build(BuildContext context) {
    const examples = <_LifeOption<String>>[
      _LifeOption<String>(
        value: '塑料瓶',
        labelKey: 'inline.plan295.life.plastic_bottle.16f3b703846d',
      ),
      _LifeOption<String>(
        value: '过期药品',
        labelKey: 'inline.plan295.life.expired_medicine.2c60ac5be890',
      ),
      _LifeOption<String>(
        value: '茶叶渣',
        labelKey: 'inline.plan297.life.tea_leaves.ea432679b184',
      ),
      _LifeOption<String>(
        value: '外卖餐盒',
        labelKey: 'inline.plan295.life.takeout_container.dee2e83fba1c',
      ),
      _LifeOption<String>(
        value: '沙发',
        labelKey: 'inline.plan295.life.sofa.f6fdf84ea12c',
      ),
    ];
    return _LifeSettingsPanel(
      title: _lifeI18nText(
        context,
        'inline.plan295.life.remote_query_tips.4f6057f2a755',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.this_page_fetches_tencent_remote_dat.56d23332af87',
      ),
      children: <Widget>[
        _GarbageRuleRow(
          icon: Icons.cloud_sync_rounded,
          title: _lifeI18nText(
            context,
            'inline.plan295.life.remote_data_source.3043ade89665',
          ),
          body: _lifeI18nText(
            context,
            'inline.plan295.life.sorting_records_come_from_tencent_qq.b5a0ba3f7461',
          ),
        ),
        _GarbageRuleRow(
          icon: Icons.search_rounded,
          title: _lifeI18nText(
            context,
            'inline.plan295.life.use_common_item_names.17723ca44d0e',
          ),
          body: _lifeI18nText(
            context,
            'inline.plan295.life.remote_data_matches_item_names_so_sp.1ba8e1861cb0',
          ),
        ),
        _GarbageRuleRow(
          icon: Icons.fact_check_outlined,
          title: _lifeI18nText(
            context,
            'inline.plan295.life.confirm_local_rules.858b7407350d',
          ),
          body: _lifeI18nText(
            context,
            'inline.plan295.life.remote_results_are_references_city_a.454266c7ac98',
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

class _GarbageRuleRow extends StatelessWidget {
  const _GarbageRuleRow({
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

class _GarbageSourcePanel extends StatelessWidget {
  const _GarbageSourcePanel({required this.onOpenOnline});

  final VoidCallback onOpenOnline;

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
              'inline.plan295.life.source_note.8ee4b62d5e8e',
            ),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _lifeI18nText(
              context,
              'inline.plan295.life.this_page_requests_tencent_toolbox_r.f998b6b611bf',
            ),
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onOpenOnline,
            icon: const Icon(Icons.open_in_new_rounded),
            label: Text(
              _lifeI18nText(
                context,
                'inline.plan295.life.open_source_page.037a8f6ca915',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
