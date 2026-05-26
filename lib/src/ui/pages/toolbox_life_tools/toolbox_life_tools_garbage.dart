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
    required this.titleZh,
    required this.titleEn,
    required this.shortZh,
    required this.shortEn,
    required this.guideZh,
    required this.guideEn,
    required this.color,
    required this.icon,
  });

  final String titleZh;
  final String titleEn;
  final String shortZh;
  final String shortEn;
  final String guideZh;
  final String guideEn;
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
    titleZh: '可回收物',
    titleEn: 'Recyclable',
    shortZh: '适宜回收循环利用',
    shortEn: 'Suitable for reuse and recycling',
    guideZh: '尽量清空内容物，保持干燥整洁；玻璃、金属和尖锐物请包好再投放。',
    guideEn:
        'Empty and keep items dry where possible; wrap glass, metal, and sharp edges before disposal.',
    color: Color(0xFF2878C8),
    icon: Icons.recycling_rounded,
  ),
  _GarbageCategory.hazardous: _GarbageCategoryInfo(
    titleZh: '有害垃圾',
    titleEn: 'Hazardous',
    shortZh: '含有毒有害成分',
    shortEn: 'Contains harmful substances',
    guideZh: '保持完整密封，优先投放到专用收集点；电池、灯管、药品不要混入普通垃圾桶。',
    guideEn:
        'Keep sealed and intact, then use designated collection points; do not mix batteries, lamps, or medicine with ordinary waste.',
    color: Color(0xFFD34B4B),
    icon: Icons.warning_amber_rounded,
  ),
  _GarbageCategory.kitchen: _GarbageCategoryInfo(
    titleZh: '湿垃圾 / 厨余垃圾',
    titleEn: 'Wet or kitchen waste',
    shortZh: '易腐烂的生物质生活废弃物',
    shortEn: 'Perishable organic household waste',
    guideZh: '投放前沥干水分，去掉塑料袋、牙签、餐巾纸、包装盒等非厨余物。',
    guideEn:
        'Drain liquid first and remove bags, toothpicks, napkins, wrappers, and containers.',
    color: Color(0xFF3F8F57),
    icon: Icons.restaurant_rounded,
  ),
  _GarbageCategory.residual: _GarbageCategoryInfo(
    titleZh: '干垃圾 / 其他垃圾',
    titleEn: 'Dry or residual waste',
    shortZh: '暂不适合回收或资源化',
    shortEn: 'Not currently recyclable or compostable',
    guideZh: '尽量压缩体积后投放；被污染、难清洗或复合材料通常归入干垃圾或其他垃圾。',
    guideEn:
        'Compress when possible; contaminated, hard-to-clean, or composite items are usually residual waste.',
    color: Color(0xFF6F7480),
    icon: Icons.delete_outline_rounded,
  ),
  _GarbageCategory.bulky: _GarbageCategoryInfo(
    titleZh: '大件垃圾',
    titleEn: 'Bulky waste',
    shortZh: '预约回收或专项收运',
    shortEn: 'Needs appointment or special handling',
    guideZh: '不要直接丢入普通桶，优先联系物业、社区或正规回收渠道处理。',
    guideEn:
        'Do not put it in regular bins; contact property management, community service, or certified recyclers.',
    color: Color(0xFF8B6B2F),
    icon: Icons.local_shipping_rounded,
  ),
  _GarbageCategory.unknown: _GarbageCategoryInfo(
    titleZh: '未知分类',
    titleEn: 'Unknown',
    shortZh: '远程数据未标明分类',
    shortEn: 'No mapped category from remote data',
    guideZh: '请打开来源页面或按当地分类规则确认。',
    guideEn: 'Open the source page or confirm with local sorting rules.',
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
    return _lifeText(
      context,
      zh: '远程数据暂不可用。',
      en: 'Remote data is unavailable.',
    );
  }
  if (error is TimeoutException) {
    return _lifeText(
      context,
      zh: '远程请求超时，请稍后重试或打开来源页面查询。',
      en: 'Remote request timed out. Try again later or open the source page.',
    );
  }
  if (error is FormatException) {
    return _lifeText(
      context,
      zh: '远程数据格式变化，暂时无法解析。',
      en: 'Remote data format changed and cannot be parsed yet.',
    );
  }
  return _lifeText(
    context,
    zh: '远程请求失败，请检查网络后重试。',
    en: 'Remote request failed. Check the network and retry.',
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
      title: _lifeText(context, zh: '垃圾分类查询', en: 'Garbage sorting'),
      subtitle: _lifeText(
        context,
        zh: '请求腾讯远程分类数据，输入物品名称后实时筛选结果。',
        en: 'Fetch Tencent remote sorting data and filter by item name.',
      ),
      appBarActions: <Widget>[
        IconButton(
          tooltip: _lifeText(context, zh: '刷新远程数据', en: 'Refresh remote data'),
          onPressed: _remoteState.loading ? null : _loadRemoteData,
          icon: const Icon(Icons.refresh_rounded),
        ),
        IconButton(
          tooltip: _lifeText(context, zh: '打开在线查询', en: 'Open online query'),
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
                      tooltip: _lifeText(context, zh: '清空', en: 'Clear'),
                      onPressed: () {
                        _controller.clear();
                        setState(() => _query = '');
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
              border: const OutlineInputBorder(),
              labelText: _lifeText(
                context,
                zh: '搜索远程数据，例如：纸巾、苹果核、电池',
                en: 'Search remote data, e.g. tissue, apple core, battery',
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
            title: _lifeText(context, zh: '查询结果', en: 'Results'),
            subtitle: _lifeText(
              context,
              zh: '输入物品名称后显示匹配结果；具体投放仍以所在城市和社区要求为准。',
              en: 'Enter an item name to show matches; local city and community rules still apply.',
            ),
          ),
          const SizedBox(height: 10),
          if (_remoteState.loading)
            _RemoteLoadingPanel(
              text: _lifeText(
                context,
                zh: '正在请求远程分类数据...',
                en: 'Fetching remote sorting data...',
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
                      _lifeText(
                        context,
                        zh: '远程分类数据',
                        en: 'Remote sorting data',
                      ),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      loading
                          ? _lifeText(
                              context,
                              zh: '正在请求腾讯远程资源',
                              en: 'Fetching Tencent remote resource',
                            )
                          : error == null
                          ? _lifeText(
                              context,
                              zh: '已加载 $totalCount 条远程分类记录',
                              en: '$totalCount remote sorting records loaded',
                            )
                          : _garbageRemoteErrorText(context, error),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (error != null && !loading)
                IconButton(
                  tooltip: _lifeText(context, zh: '重试', en: 'Retry'),
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
          label: Text(_lifeText(context, zh: '全部', en: 'All')),
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
                '${_lifeText(context, zh: _garbageCategoryInfos[category]!.titleZh, en: _garbageCategoryInfos[category]!.titleEn)} ${countFor(category)}',
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
    final label = _lifeText(context, zh: info.titleZh, en: info.titleEn);
    return Tooltip(
      message: _lifeText(context, zh: info.guideZh, en: info.guideEn),
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
                          text: _lifeText(
                            context,
                            zh: info.titleZh,
                            en: info.titleEn,
                          ),
                          color: info.color,
                        ),
                        _GarbagePill(
                          icon: Icons.cloud_done_rounded,
                          text: _lifeText(
                            context,
                            zh: '远程分类码 ${item.rawCategory}',
                            en: 'Remote category ${item.rawCategory}',
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
          Text(_lifeText(context, zh: info.shortZh, en: info.shortEn)),
          const SizedBox(height: 8),
          Text(
            _lifeText(context, zh: info.guideZh, en: info.guideEn),
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
            label: Text(_lifeText(context, zh: '重新请求', en: 'Retry')),
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
      title: _lifeText(context, zh: '开始查询', en: 'Start search'),
      subtitle: _lifeText(
        context,
        zh: '输入物品名称开始查询，或打开腾讯在线查询页继续查。',
        en: 'Enter an item name to search, or open Tencent online query.',
      ),
      children: <Widget>[
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: onOpenOnline,
            icon: const Icon(Icons.open_in_new_rounded),
            label: Text(
              _lifeText(context, zh: '打开在线查询', en: 'Open online query'),
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
            _lifeText(context, zh: '远程数据中暂未命中', en: 'No remote match yet'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _lifeText(
              context,
              zh: selectedCategory == null
                  ? '可以换一个常见名称试试，或打开在线查询确认「$query」。'
                  : '当前分类筛选下没有结果，可以取消分类筛选，或打开在线查询确认「$query」。',
              en: selectedCategory == null
                  ? 'Try another common name, or open the online query for "$query".'
                  : 'No result under this category filter. Clear it, or open the online query for "$query".',
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onOpenOnline,
            icon: const Icon(Icons.open_in_new_rounded),
            label: Text(
              _lifeText(context, zh: '打开腾讯查询', en: 'Open Tencent query'),
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
        labelZh: '塑料瓶',
        labelEn: 'Plastic bottle',
      ),
      _LifeOption<String>(
        value: '过期药品',
        labelZh: '过期药品',
        labelEn: 'Expired medicine',
      ),
      _LifeOption<String>(value: '茶叶渣', labelZh: '茶叶渣', labelEn: 'Tea leaves'),
      _LifeOption<String>(
        value: '外卖餐盒',
        labelZh: '外卖餐盒',
        labelEn: 'Takeout container',
      ),
      _LifeOption<String>(value: '沙发', labelZh: '沙发', labelEn: 'Sofa'),
    ];
    return _LifeSettingsPanel(
      title: _lifeText(context, zh: '远程查询提示', en: 'Remote query tips'),
      subtitle: _lifeText(
        context,
        zh: '当前页会先请求腾讯远程数据，再在应用内筛选；没命中时可换常用名称或打开来源页。',
        en: 'This page fetches Tencent remote data first, then filters locally; try common names or open the source page if missing.',
      ),
      children: <Widget>[
        _GarbageRuleRow(
          icon: Icons.cloud_sync_rounded,
          title: _lifeText(context, zh: '远程数据源', en: 'Remote data source'),
          body: _lifeText(
            context,
            zh: '分类记录来自腾讯 QQ 浏览器工具箱公开 JSON 资源，刷新按钮会重新请求。',
            en: 'Sorting records come from Tencent QQ Browser toolbox public JSON. Refresh fetches again.',
          ),
        ),
        _GarbageRuleRow(
          icon: Icons.search_rounded,
          title: _lifeText(context, zh: '输入常用物品名', en: 'Use common item names'),
          body: _lifeText(
            context,
            zh: '远程数据按物品名称匹配，复杂描述建议拆成短词查询。',
            en: 'Remote data matches item names, so split complex descriptions into short terms.',
          ),
        ),
        _GarbageRuleRow(
          icon: Icons.fact_check_outlined,
          title: _lifeText(context, zh: '地区口径仍需确认', en: 'Confirm local rules'),
          body: _lifeText(
            context,
            zh: '远程结果可作参考，投放时仍以所在城市和社区最新规则为准。',
            en: 'Remote results are references; city and community rules still apply.',
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
            _lifeText(context, zh: '来源说明', en: 'Source note'),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _lifeText(
              context,
              zh: '本页请求腾讯工具箱远程 JSON 并在应用内筛选；如果远程资源不可用，可打开来源页面继续查询。',
              en: 'This page requests Tencent toolbox remote JSON and filters in app. If unavailable, open the source page.',
            ),
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onOpenOnline,
            icon: const Icon(Icons.open_in_new_rounded),
            label: Text(
              _lifeText(context, zh: '打开来源页面', en: 'Open source page'),
            ),
          ),
        ],
      ),
    );
  }
}
