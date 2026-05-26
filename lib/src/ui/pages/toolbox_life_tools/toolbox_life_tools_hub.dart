part of '../toolbox_life_tools.dart';

class LifeToolsHubPage extends StatefulWidget {
  const LifeToolsHubPage({super.key});

  @override
  State<LifeToolsHubPage> createState() => _LifeToolsHubPageState();
}

class _LifeToolsHubPageState extends State<LifeToolsHubPage> {
  String _query = '';
  String _category = 'all';

  List<String> get _categories {
    final base = _lifeTools.map((tool) => tool.category).toSet().toList()
      ..sort();
    return <String>['all', ...base];
  }

  String _categoryLabel(BuildContext context, String category) {
    return switch (category) {
      'all' => _lifeText(context, zh: '全部', en: 'All'),
      'display' => _lifeText(context, zh: '展示', en: 'Display'),
      'device' => _lifeText(context, zh: '设备', en: 'Device'),
      'image' => _lifeText(context, zh: '图像', en: 'Image'),
      'web' => _lifeText(context, zh: '网络', en: 'Web'),
      'text' => _lifeText(context, zh: '文本', en: 'Text'),
      'study' => _lifeText(context, zh: '学习', en: 'Study'),
      'calc' => _lifeText(context, zh: '计算', en: 'Calc'),
      _ => category,
    };
  }

  List<_LifeTool> get _filteredTools {
    return _lifeTools
        .where((tool) {
          final passCategory = _category == 'all' || tool.category == _category;
          if (!passCategory) {
            return false;
          }
          if (_query.trim().isEmpty) {
            return true;
          }
          final q = _query.toLowerCase();
          return tool.titleZh.toLowerCase().contains(q) ||
              tool.titleEn.toLowerCase().contains(q) ||
              tool.summaryZh.toLowerCase().contains(q) ||
              tool.summaryEn.toLowerCase().contains(q);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return ToolboxToolPage(
      title: _lifeText(context, zh: '生活实用', en: 'Life tools'),
      subtitle: _lifeText(
        context,
        zh: '37 个独立功能入口，一期优先落地可本地实现能力，并补全公开资源来源说明。',
        en: '37 standalone entries with local-first phase-1 implementations and source attributions.',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SectionHeader(
            title: _lifeText(context, zh: '功能总览', en: 'Overview'),
            subtitle: _lifeText(
              context,
              zh: '可按关键词搜索，或按分类筛选后进入独立工具页面。',
              en: 'Search by keyword or filter by category, then open each tool page.',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded),
              border: const OutlineInputBorder(),
              labelText: _lifeText(context, zh: '搜索工具', en: 'Search tools'),
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories
                .map((category) {
                  final selected = category == _category;
                  return ChoiceChip(
                    selected: selected,
                    label: Text(_categoryLabel(context, category)),
                    onSelected: (_) => setState(() => _category = category),
                  );
                })
                .toList(growable: false),
          ),
          const SizedBox(height: 14),
          for (final tool in _filteredTools)
            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                leading: CircleAvatar(child: Icon(tool.icon)),
                title: Text(
                  _lifeText(context, zh: tool.titleZh, en: tool.titleEn),
                ),
                subtitle: Text(
                  _lifeText(context, zh: tool.summaryZh, en: tool.summaryEn),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _openTool(tool),
              ),
            ),
        ],
      ),
    );
  }

  void _openTool(_LifeTool tool) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => switch (tool.id) {
          'time_screen' => const _TimeScreenToolPage(),
          'barrage' => const _BarrageToolPage(),
          'ruler' => const _RulerToolPage(),
          'scoreboard' => const _ScoreboardToolPage(),
          'color_helper' => const _ColorHelperToolPage(),
          'wallpaper_helper' => const _WallpaperHelperToolPage(),
          'postal_code' => const _PostalLookupToolPage(),
          'reverse_image' => const _ReverseImageToolPage(),
          'garbage' => const _GarbageSortingToolPage(),
          'relatives' => const _RelativesToolPage(),
          'steganography' => const _SteganographyToolPage(),
          'mind_map' => const _MindMapToolPage(),
          'text_count' ||
          'text_encoding' ||
          'rc4' ||
          'sup_sub' ||
          'unit_converter' ||
          'work_worth' ||
          'mortgage' ||
          'date_calculator' ||
          'bmi' ||
          'short_link' ||
          'qr' ||
          'image_compress' ||
          'pinyin' => _LifeUtilityToolPage(tool: tool),
          _ => _LifeToolInfoPage(tool: tool),
        },
      ),
    );
  }
}

class _LifeToolInfoPage extends StatelessWidget {
  const _LifeToolInfoPage({required this.tool});

  final _LifeTool tool;

  @override
  Widget build(BuildContext context) {
    return ToolboxToolPage(
      title: _lifeText(context, zh: tool.titleZh, en: tool.titleEn),
      subtitle: _lifeText(context, zh: tool.summaryZh, en: tool.summaryEn),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Text(
              _lifeText(
                context,
                zh: '一期版本已创建独立入口。该功能当前以稳定入口和资源桥接为主，后续会继续补充更完整的本地实现。',
                en: 'Phase-1 provides an independent entry. This tool currently focuses on stable access and resource bridging, and will be extended with deeper local implementation.',
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (tool.sources.isNotEmpty) ...<Widget>[
            SectionHeader(
              title: _lifeText(
                context,
                zh: '来源与版权说明',
                en: 'Sources and attribution',
              ),
            ),
            const SizedBox(height: 8),
            for (final source in tool.sources)
              Card(
                child: ListTile(
                  title: Text(source.name),
                  subtitle: Text(
                    source.copyrightNote.isEmpty
                        ? source.url
                        : '${source.url}\n${source.copyrightNote}',
                  ),
                  trailing: const Icon(Icons.open_in_new_rounded),
                  onTap: () => _openExternal(context, source.url),
                ),
              ),
            const SizedBox(height: 6),
            Text(
              _lifeText(
                context,
                zh: '版权和使用权请以来源网站政策及原作者声明为准。',
                en: 'Copyright and usage rights follow each source website policy and original author statement.',
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

Future<void> _openExternal(BuildContext context, String url) async {
  final uri = Uri.parse(url);
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('无法打开链接: $url')));
  }
}
