part of '../toolbox_life_tools.dart';

enum _MindMapTemplate { blank, plan, meeting, study }

class _MindMapNode {
  const _MindMapNode({
    required this.id,
    required this.parentId,
    required this.title,
    required this.color,
  });

  final String id;
  final String? parentId;
  final String title;
  final Color color;

  _MindMapNode copyWith({String? title, Color? color}) {
    return _MindMapNode(
      id: id,
      parentId: parentId,
      title: title ?? this.title,
      color: color ?? this.color,
    );
  }
}

class _MindMapEditSnapshot {
  const _MindMapEditSnapshot({
    required this.nodes,
    required this.anchors,
    required this.selectedId,
  });

  final List<_MindMapNode> nodes;
  final Map<String, Offset> anchors;
  final String selectedId;
}

class _MindMapToolPage extends StatefulWidget {
  const _MindMapToolPage();

  @override
  State<_MindMapToolPage> createState() => _MindMapToolPageState();
}

class _MindMapToolPageState extends State<_MindMapToolPage> {
  static const double _snapGridSize = 24;

  static const List<Color> _palette = <Color>[
    Color(0xFF527A8D),
    Color(0xFFD2904F),
    Color(0xFF7D6BB3),
    Color(0xFF5F9C78),
    Color(0xFFC45E6C),
    Color(0xFF6A7A3D),
  ];

  final GlobalKey _canvasBoundaryKey = GlobalKey();
  final TextEditingController _titleController = TextEditingController();

  List<_MindMapNode> _nodes = const <_MindMapNode>[
    _MindMapNode(
      id: 'root',
      parentId: null,
      title: '中心主题',
      color: Color(0xFF527A8D),
    ),
  ];
  Map<String, Offset> _nodeAnchors = const <String, Offset>{};
  String _selectedId = 'root';
  int _serial = 1;
  _MindMapTemplate _template = _MindMapTemplate.plan;
  bool _snapToGrid = true;
  bool _initialized = false;
  bool _exporting = false;
  String? _statusMessage;
  String? _errorMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    final nodes = _templateNodes(_template);
    _nodes = nodes;
    _selectedId = 'root';
    _serial = nodes.length;
    _syncTitleController(nodes.first.title);
    _initialized = true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  _MindMapNode get _selectedNode {
    return _nodes.firstWhere(
      (node) => node.id == _selectedId,
      orElse: () => _nodes.first,
    );
  }

  int get _maxDepth {
    var maxDepth = 0;
    for (final node in _nodes) {
      maxDepth = math.max(maxDepth, _depthOf(node.id));
    }
    return maxDepth;
  }

  int get _branchCount {
    return _nodes.where((node) => node.parentId != null).length;
  }

  @override
  Widget build(BuildContext context) {
    return ToolboxToolPage(
      title: _lifeText(context, zh: '简易思维导图', en: 'Simple mind map'),
      subtitle: _lifeText(
        context,
        zh: '本地创建节点关系，整理想法并导出图片。',
        en: 'Create local node relations, organize ideas, and export an image.',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildStagePanel(context),
          const SizedBox(height: 12),
          _buildActionsPanel(context),
          const SizedBox(height: 12),
          _buildTemplatePanel(context),
          const SizedBox(height: 12),
          _buildOutlinePanel(context),
          const SizedBox(height: 12),
          _buildExportPanel(context),
          if (_errorMessage != null) ...<Widget>[
            const SizedBox(height: 10),
            _buildMessagePanel(context, message: _errorMessage!, error: true),
          ],
          if (_statusMessage != null) ...<Widget>[
            const SizedBox(height: 10),
            _buildMessagePanel(context, message: _statusMessage!, error: false),
          ],
        ],
      ),
    );
  }

  Widget _buildStagePanel(BuildContext context) {
    final theme = Theme.of(context);
    return _LifeSettingsPanel(
      title: _lifeText(context, zh: '导图舞台', en: 'Mind map stage'),
      subtitle: _lifeText(
        context,
        zh: '当前选中节点会在下方操作区同步编辑，也可以进入全屏便捷模式拖拽整理。',
        en: 'The selected node is edited below, or arranged by drag in fullscreen quick mode.',
      ),
      children: <Widget>[
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            ToolboxMetricCard(
              label: _lifeText(context, zh: '节点数', en: 'Nodes'),
              value: '${_nodes.length}',
            ),
            ToolboxMetricCard(
              label: _lifeText(context, zh: '分支数', en: 'Branches'),
              value: '$_branchCount',
            ),
            ToolboxMetricCard(
              label: _lifeText(context, zh: '层级', en: 'Depth'),
              value: '${_maxDepth + 1}',
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: FilledButton.tonalIcon(
                key: const ValueKey<String>('life_mind_map_fullscreen_button'),
                onPressed: _openFullscreenMode,
                icon: const Icon(Icons.open_in_full_rounded),
                label: Text(
                  _lifeText(context, zh: '全屏便捷模式', en: 'Fullscreen quick mode'),
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filledTonal(
              key: const ValueKey<String>('life_mind_map_reflow_inline_button'),
              tooltip: _lifeText(context, zh: '自动重排', en: 'Auto arrange'),
              onPressed: _nodeAnchors.isEmpty ? null : _resetNodeAnchors,
              icon: const Icon(Icons.auto_fix_high_rounded),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.5,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                Icons.radio_button_checked_rounded,
                color: _selectedNode.color,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                _lifeText(context, zh: '当前节点', en: 'Active node'),
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _selectedNode.title,
                  key: const ValueKey<String>('life_mind_map_active_label'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _MindMapCanvas(
          boundaryKey: _canvasBoundaryKey,
          nodes: _nodes,
          anchors: _nodeAnchors,
          selectedId: _selectedId,
          onSelect: _selectNode,
        ),
      ],
    );
  }

  Widget _buildActionsPanel(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeText(context, zh: '节点操作', en: 'Node actions'),
      children: <Widget>[
        TextField(
          key: const ValueKey<String>('life_mind_map_title_field'),
          controller: _titleController,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: _lifeText(context, zh: '节点标题', en: 'Node title'),
          ),
          onChanged: _renameSelected,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            FilledButton.icon(
              key: const ValueKey<String>('life_mind_map_add_child_button'),
              onPressed: _addChild,
              icon: const Icon(Icons.account_tree_rounded),
              label: Text(_lifeText(context, zh: '添加子节点', en: 'Add child')),
            ),
            FilledButton.tonalIcon(
              key: const ValueKey<String>('life_mind_map_add_sibling_button'),
              onPressed: _selectedNode.parentId == null ? null : _addSibling,
              icon: const Icon(Icons.call_split_rounded),
              label: Text(_lifeText(context, zh: '添加同级', en: 'Add sibling')),
            ),
            OutlinedButton.icon(
              key: const ValueKey<String>('life_mind_map_delete_button'),
              onPressed: _selectedNode.parentId == null ? null : _deleteNode,
              icon: const Icon(Icons.delete_outline_rounded),
              label: Text(_lifeText(context, zh: '删除节点', en: 'Delete')),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _LifeColorField(
          label: _lifeText(context, zh: '节点颜色', en: 'Node color'),
          value: _selectedNode.color,
          options: const <_LifeColorOption>[
            _LifeColorOption(
              color: Color(0xFF527A8D),
              labelZh: '蓝灰',
              labelEn: 'Blue gray',
            ),
            _LifeColorOption(
              color: Color(0xFFD2904F),
              labelZh: '琥珀',
              labelEn: 'Amber',
            ),
            _LifeColorOption(
              color: Color(0xFF7D6BB3),
              labelZh: '紫藤',
              labelEn: 'Wisteria',
            ),
            _LifeColorOption(
              color: Color(0xFF5F9C78),
              labelZh: '草绿',
              labelEn: 'Moss',
            ),
            _LifeColorOption(
              color: Color(0xFFC45E6C),
              labelZh: '玫瑰',
              labelEn: 'Rose',
            ),
            _LifeColorOption(
              color: Color(0xFF6A7A3D),
              labelZh: '橄榄',
              labelEn: 'Olive',
            ),
          ],
          onChanged: _setSelectedColor,
        ),
      ],
    );
  }

  Widget _buildTemplatePanel(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeText(context, zh: '快速模板', en: 'Quick templates'),
      children: <Widget>[
        _LifeSegmentedField<_MindMapTemplate>(
          label: _lifeText(context, zh: '模板', en: 'Template'),
          value: _template,
          options: const <_LifeOption<_MindMapTemplate>>[
            _LifeOption<_MindMapTemplate>(
              value: _MindMapTemplate.blank,
              labelZh: '空白',
              labelEn: 'Blank',
            ),
            _LifeOption<_MindMapTemplate>(
              value: _MindMapTemplate.plan,
              labelZh: '项目计划',
              labelEn: 'Project plan',
            ),
            _LifeOption<_MindMapTemplate>(
              value: _MindMapTemplate.meeting,
              labelZh: '会议记录',
              labelEn: 'Meeting notes',
            ),
            _LifeOption<_MindMapTemplate>(
              value: _MindMapTemplate.study,
              labelZh: '学习主题',
              labelEn: 'Study topic',
            ),
          ],
          onChanged: (value) => _applyTemplate(value),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          key: const ValueKey<String>('life_mind_map_clear_button'),
          onPressed: () => _applyTemplate(_MindMapTemplate.blank),
          icon: const Icon(Icons.restart_alt_rounded),
          label: Text(_lifeText(context, zh: '清空为单节点', en: 'Reset blank')),
        ),
      ],
    );
  }

  Widget _buildOutlinePanel(BuildContext context) {
    final root = _rootNode;
    return _LifeSettingsPanel(
      title: _lifeText(context, zh: '结构大纲', en: 'Outline'),
      subtitle: _lifeText(
        context,
        zh: '完整标题在这里保留，不受画布节点宽度影响。',
        en: 'Full titles remain readable here.',
      ),
      children: <Widget>[
        if (root == null)
          Text(_lifeText(context, zh: '暂无节点', en: 'No nodes'))
        else
          ..._buildOutlineTiles(context, root, 0),
      ],
    );
  }

  Widget _buildExportPanel(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeText(context, zh: '导出', en: 'Export'),
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: FilledButton.icon(
                key: const ValueKey<String>('life_mind_map_export_png_button'),
                onPressed: _exporting ? null : _exportPng,
                icon: _exporting
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.image_rounded),
                label: Text(
                  _exporting
                      ? _lifeText(context, zh: '导出中...', en: 'Exporting...')
                      : _lifeText(context, zh: '导出 PNG', en: 'Export PNG'),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                key: const ValueKey<String>(
                  'life_mind_map_copy_outline_button',
                ),
                onPressed: _copyMarkdownOutline,
                icon: const Icon(Icons.copy_rounded),
                label: Text(_lifeText(context, zh: '复制大纲', en: 'Copy outline')),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMessagePanel(
    BuildContext context, {
    required String message,
    required bool error,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: error ? scheme.errorContainer : scheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: error ? scheme.onErrorContainer : scheme.onPrimaryContainer,
        ),
      ),
    );
  }

  List<Widget> _buildOutlineTiles(
    BuildContext context,
    _MindMapNode node,
    int depth,
  ) {
    final children = _childrenOf(node.id);
    return <Widget>[
      Padding(
        padding: EdgeInsets.only(left: depth * 14.0, bottom: 6),
        child: Material(
          color: node.id == _selectedId
              ? node.color.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: ListTile(
            dense: true,
            minLeadingWidth: 24,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10),
            leading: CircleAvatar(
              radius: 11,
              backgroundColor: node.color,
              child: Text(
                '${depth + 1}',
                style: const TextStyle(fontSize: 10, color: Colors.white),
              ),
            ),
            title: Text(node.title),
            trailing: node.id == _selectedId
                ? const Icon(Icons.check_rounded, size: 18)
                : null,
            onTap: () => _selectNode(node.id),
          ),
        ),
      ),
      for (final child in children)
        ..._buildOutlineTiles(context, child, depth + 1),
    ];
  }

  _MindMapNode? get _rootNode {
    for (final node in _nodes) {
      if (node.parentId == null) {
        return node;
      }
    }
    return null;
  }

  _MindMapNode? _findNode(String id) {
    for (final node in _nodes) {
      if (node.id == id) {
        return node;
      }
    }
    return null;
  }

  List<_MindMapNode> _childrenOf(String parentId) {
    return _nodes
        .where((node) => node.parentId == parentId)
        .toList(growable: false);
  }

  int _depthOf(String nodeId) {
    var depth = 0;
    var current = _nodes.firstWhere((node) => node.id == nodeId);
    while (current.parentId != null) {
      final parentId = current.parentId;
      final parent = parentId == null ? null : _findNode(parentId);
      if (parent == null) {
        break;
      }
      depth += 1;
      current = parent;
    }
    return depth;
  }

  void _selectNode(String id) {
    final node = _findNode(id);
    if (node == null) {
      return;
    }
    setState(() {
      _selectedId = id;
      _errorMessage = null;
      _statusMessage = null;
    });
    _syncTitleController(node.title);
  }

  void _syncTitleController(String value) {
    _titleController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  void _renameSelected(String value) {
    final nextTitle = value.trim().isEmpty
        ? _lifeText(context, zh: '未命名', en: 'Untitled')
        : value.trim();
    setState(() {
      _nodes = _nodes
          .map(
            (node) =>
                node.id == _selectedId ? node.copyWith(title: nextTitle) : node,
          )
          .toList(growable: false);
      _statusMessage = null;
      _errorMessage = null;
    });
  }

  void _setSelectedColor(Color color) {
    setState(() {
      _nodes = _nodes
          .map(
            (node) =>
                node.id == _selectedId ? node.copyWith(color: color) : node,
          )
          .toList(growable: false);
      _statusMessage = null;
      _errorMessage = null;
    });
  }

  void _addChild() {
    final parent = _selectedNode;
    final id = _nextId();
    final title = _nextBranchTitle(parent.id);
    final depth = _depthOf(parent.id) + 1;
    final node = _MindMapNode(
      id: id,
      parentId: parent.id,
      title: title,
      color: _palette[depth % _palette.length],
    );
    setState(() {
      _nodes = <_MindMapNode>[..._nodes, node];
      _seedAnchorForNewNode(id: id, parentId: parent.id);
      _selectedId = id;
      _statusMessage = null;
      _errorMessage = null;
    });
    _syncTitleController(title);
  }

  void _addSibling() {
    final parentId = _selectedNode.parentId;
    if (parentId == null) {
      return;
    }
    final id = _nextId();
    final title = _nextBranchTitle(parentId);
    final depth = _depthOf(parentId) + 1;
    final node = _MindMapNode(
      id: id,
      parentId: parentId,
      title: title,
      color: _palette[depth % _palette.length],
    );
    setState(() {
      _nodes = <_MindMapNode>[..._nodes, node];
      _seedAnchorForNewNode(id: id, parentId: parentId);
      _selectedId = id;
      _statusMessage = null;
      _errorMessage = null;
    });
    _syncTitleController(title);
  }

  void _deleteNode() {
    final selected = _selectedNode;
    final parentId = selected.parentId;
    if (parentId == null) {
      return;
    }
    final removed = <String>{selected.id};
    var changed = true;
    while (changed) {
      changed = false;
      for (final node in _nodes) {
        if (node.parentId != null &&
            removed.contains(node.parentId) &&
            removed.add(node.id)) {
          changed = true;
        }
      }
    }
    final parent = _nodes.firstWhere((node) => node.id == parentId);
    setState(() {
      _nodes = _nodes
          .where((node) => !removed.contains(node.id))
          .toList(growable: false);
      _nodeAnchors = <String, Offset>{
        for (final entry in _nodeAnchors.entries)
          if (!removed.contains(entry.key)) entry.key: entry.value,
      };
      _selectedId = parent.id;
      _statusMessage = null;
      _errorMessage = null;
    });
    _syncTitleController(parent.title);
  }

  void _applyTemplate(_MindMapTemplate template, {bool announce = true}) {
    final nodes = _templateNodes(template);
    setState(() {
      _template = template;
      _nodes = nodes;
      _nodeAnchors = const <String, Offset>{};
      _selectedId = 'root';
      _serial = nodes.length;
      _errorMessage = null;
      _statusMessage = announce
          ? _lifeText(context, zh: '模板已应用。', en: 'Template applied.')
          : null;
    });
    _syncTitleController(nodes.first.title);
  }

  List<_MindMapNode> _templateNodes(_MindMapTemplate template) {
    String text({required String zh, required String en}) {
      return _lifeText(context, zh: zh, en: en);
    }

    _MindMapNode node(
      String id,
      String? parentId,
      String title,
      int colorIndex,
    ) {
      return _MindMapNode(
        id: id,
        parentId: parentId,
        title: title,
        color: _palette[colorIndex % _palette.length],
      );
    }

    switch (template) {
      case _MindMapTemplate.blank:
        return <_MindMapNode>[
          node('root', null, text(zh: '中心主题', en: 'Central topic'), 0),
        ];
      case _MindMapTemplate.plan:
        return <_MindMapNode>[
          node('root', null, text(zh: '项目计划', en: 'Project plan'), 0),
          node('n1', 'root', text(zh: '目标', en: 'Goals'), 1),
          node('n2', 'root', text(zh: '任务', en: 'Tasks'), 2),
          node('n3', 'root', text(zh: '风险', en: 'Risks'), 3),
        ];
      case _MindMapTemplate.meeting:
        return <_MindMapNode>[
          node('root', null, text(zh: '会议记录', en: 'Meeting notes'), 0),
          node('n1', 'root', text(zh: '议题', en: 'Topics'), 1),
          node('n2', 'root', text(zh: '结论', en: 'Decisions'), 2),
          node('n3', 'root', text(zh: '待办', en: 'Actions'), 3),
        ];
      case _MindMapTemplate.study:
        return <_MindMapNode>[
          node('root', null, text(zh: '学习主题', en: 'Study topic'), 0),
          node('n1', 'root', text(zh: '概念', en: 'Concepts'), 1),
          node('n2', 'root', text(zh: '例子', en: 'Examples'), 2),
          node('n3', 'root', text(zh: '复习', en: 'Review'), 3),
        ];
    }
  }

  String _nextId() {
    _serial += 1;
    return 'n$_serial';
  }

  String _nextBranchTitle(String parentId) {
    final next = _childrenOf(parentId).length + 1;
    return _lifeText(context, zh: '新分支 $next', en: 'New branch $next');
  }

  void _seedAnchorForNewNode({required String id, required String? parentId}) {
    if (_nodeAnchors.isEmpty) {
      return;
    }
    final siblingIndex = parentId == null ? 0 : _childrenOf(parentId).length;
    final parentAnchor = parentId == null
        ? const Offset(0.5, 0.2)
        : _nodeAnchors[parentId] ?? const Offset(0.5, 0.45);
    final horizontalStep = ((siblingIndex % 3) - 1) * 0.16;
    final verticalStep = 0.16 + (siblingIndex ~/ 3) * 0.08;
    _nodeAnchors = <String, Offset>{
      ..._nodeAnchors,
      id: _clampMindMapAnchor(
        Offset(
          parentAnchor.dx + horizontalStep,
          parentAnchor.dy + verticalStep,
        ),
      ),
    };
  }

  void _moveNodeAnchor(_MindMapNodePositionChange change) {
    setState(() {
      _nodeAnchors = <String, Offset>{
        ..._nodeAnchors,
        change.nodeId: _clampMindMapAnchor(change.anchor),
      };
      _selectedId = change.nodeId;
      _statusMessage = null;
      _errorMessage = null;
    });
    final node = _findNode(change.nodeId);
    if (node != null) {
      _syncTitleController(node.title);
    }
  }

  void _setSnapToGrid(bool value) {
    setState(() {
      _snapToGrid = value;
      _statusMessage = value
          ? _lifeText(context, zh: '吸附已开启。', en: 'Snap enabled.')
          : _lifeText(context, zh: '吸附已关闭。', en: 'Snap disabled.');
      _errorMessage = null;
    });
  }

  void _resetNodeAnchors() {
    setState(() {
      _nodeAnchors = const <String, Offset>{};
      _statusMessage = _lifeText(
        context,
        zh: '节点已自动重排。',
        en: 'Nodes auto arranged.',
      );
      _errorMessage = null;
    });
  }

  Future<void> _openFullscreenMode() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (context) {
          return _MindMapFullscreenPage(
            nodes: _nodes,
            anchors: _nodeAnchors,
            selectedId: _selectedId,
            snapToGrid: _snapToGrid,
            gridSize: _snapGridSize,
            onSelect: _selectNode,
            onMoveNode: _moveNodeAnchor,
            onSnapChanged: _setSnapToGrid,
            onResetLayout: _resetNodeAnchors,
            onRenameNode: _renameNodeFromFullscreen,
            onAddChild: _addChildFromFullscreen,
            onAddSibling: _addSiblingFromFullscreen,
            onDeleteNode: _deleteNodeFromFullscreen,
          );
        },
      ),
    );
  }

  _MindMapEditSnapshot _snapshotForFullscreen() {
    return _MindMapEditSnapshot(
      nodes: _nodes,
      anchors: _nodeAnchors,
      selectedId: _selectedId,
    );
  }

  _MindMapEditSnapshot _renameNodeFromFullscreen(String value) {
    _renameSelected(value);
    return _snapshotForFullscreen();
  }

  _MindMapEditSnapshot _addChildFromFullscreen() {
    _addChild();
    return _snapshotForFullscreen();
  }

  _MindMapEditSnapshot _addSiblingFromFullscreen() {
    _addSibling();
    return _snapshotForFullscreen();
  }

  _MindMapEditSnapshot _deleteNodeFromFullscreen() {
    _deleteNode();
    return _snapshotForFullscreen();
  }

  Future<void> _copyMarkdownOutline() async {
    await Clipboard.setData(ClipboardData(text: _markdownOutline()));
    if (!mounted) {
      return;
    }
    setState(() {
      _statusMessage = _lifeText(context, zh: '大纲已复制。', en: 'Outline copied.');
      _errorMessage = null;
    });
  }

  Future<void> _exportPng() async {
    final saveDialogTitle = _lifeText(
      context,
      zh: '保存思维导图',
      en: 'Save mind map',
    );
    final browserDownloadMessage = _lifeText(
      context,
      zh: '浏览器下载已触发，请查看下载列表。',
      en: 'Browser download started. Check your downloads.',
    );
    final exportFailedPrefix = _lifeText(
      context,
      zh: '导出失败',
      en: 'Export failed',
    );
    setState(() {
      _exporting = true;
      _statusMessage = null;
      _errorMessage = null;
    });
    try {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final boundary =
          _canvasBoundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) {
        throw StateError('Canvas is not ready');
      }
      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (byteData == null) {
        throw StateError('PNG encoding failed');
      }
      final bytes = byteData.buffer.asUint8List();
      final fileName = '${_safeFileName(_rootNode?.title ?? 'mind_map')}.png';

      String? savedPath;
      try {
        savedPath = await FilePicker.platform.saveFile(
          dialogTitle: saveDialogTitle,
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: const <String>['png'],
          bytes: bytes,
        );
      } on UnimplementedError {
        savedPath = null;
      }

      if (!mounted) {
        return;
      }

      if (savedPath == null || savedPath.trim().isEmpty) {
        if (kIsWeb) {
          setState(() {
            _statusMessage = browserDownloadMessage;
          });
          return;
        }
        final appDir = await getApplicationDocumentsDirectory();
        final exportDir = Directory(
          path.join(appDir.path, 'life_tools', 'mind_map'),
        );
        if (!await exportDir.exists()) {
          await exportDir.create(recursive: true);
        }
        final fallback = File(
          path.join(
            exportDir.path,
            '${_safeFileName(_rootNode?.title ?? 'mind_map')}_${DateTime.now().millisecondsSinceEpoch}.png',
          ),
        );
        await fallback.writeAsBytes(bytes, flush: true);
        if (!mounted) {
          return;
        }
        setState(() => _statusMessage = fallback.path);
        return;
      }

      setState(() => _statusMessage = savedPath);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = '$exportFailedPrefix: $error';
      });
    } finally {
      if (mounted) {
        setState(() => _exporting = false);
      }
    }
  }

  String _markdownOutline() {
    final root = _rootNode;
    if (root == null) {
      return '';
    }
    final lines = <String>[];
    void visit(_MindMapNode node, int depth) {
      lines.add('${'  ' * depth}- ${node.title}');
      for (final child in _childrenOf(node.id)) {
        visit(child, depth + 1);
      }
    }

    visit(root, 0);
    return lines.join('\n');
  }

  String _safeFileName(String raw) {
    final cleaned = raw
        .trim()
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '');
    if (cleaned.isEmpty) {
      return 'mind_map';
    }
    return cleaned.characters.take(32).toString();
  }
}
