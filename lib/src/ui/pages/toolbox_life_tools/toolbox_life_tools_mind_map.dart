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
      title: _lifeI18nText(
        context,
        'inline.plan295.life.simple_mind_map.e5993d3e2573',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.create_local_node_relations_organize.ef42d5588354',
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
      title: _lifeI18nText(
        context,
        'inline.plan295.life.mind_map_stage.e8d2ae744a80',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.the_selected_node_is_edited_below_or.c99223bad58b',
      ),
      children: <Widget>[
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            ToolboxMetricCard(
              label: _lifeI18nText(
                context,
                'inline.plan295.life.nodes.adf879e89029',
              ),
              value: '${_nodes.length}',
            ),
            ToolboxMetricCard(
              label: _lifeI18nText(
                context,
                'inline.plan295.life.branches.862abda12737',
              ),
              value: '$_branchCount',
            ),
            ToolboxMetricCard(
              label: _lifeI18nText(
                context,
                'inline.plan295.life.depth.4d7a23482351',
              ),
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
                  _lifeI18nText(
                    context,
                    'inline.plan295.life.fullscreen_quick_mode.c39aa66c28ac',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filledTonal(
              key: const ValueKey<String>('life_mind_map_reflow_inline_button'),
              tooltip: _lifeI18nText(
                context,
                'inline.plan295.life.auto_arrange.6010d89e52da',
              ),
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
                _lifeI18nText(
                  context,
                  'inline.plan295.life.active_node.88e5e196208c',
                ),
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
      title: _lifeI18nText(
        context,
        'inline.plan295.life.node_actions.ba9c814683d1',
      ),
      children: <Widget>[
        TextField(
          key: const ValueKey<String>('life_mind_map_title_field'),
          controller: _titleController,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: _lifeI18nText(
              context,
              'inline.plan295.life.node_title.56915dce29c0',
            ),
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
              label: Text(
                _lifeI18nText(
                  context,
                  'inline.plan295.life.add_child.c714076a5fea',
                ),
              ),
            ),
            FilledButton.tonalIcon(
              key: const ValueKey<String>('life_mind_map_add_sibling_button'),
              onPressed: _selectedNode.parentId == null ? null : _addSibling,
              icon: const Icon(Icons.call_split_rounded),
              label: Text(
                _lifeI18nText(
                  context,
                  'inline.plan295.life.add_sibling.3810e08aac41',
                ),
              ),
            ),
            OutlinedButton.icon(
              key: const ValueKey<String>('life_mind_map_delete_button'),
              onPressed: _selectedNode.parentId == null ? null : _deleteNode,
              icon: const Icon(Icons.delete_outline_rounded),
              label: Text(
                _lifeI18nText(
                  context,
                  'inline.plan295.life.delete.c500e9f9b9b5',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _LifeColorField(
          label: _lifeI18nText(
            context,
            'inline.plan295.life.node_color.095183641f1f',
          ),
          value: _selectedNode.color,
          options: const <_LifeColorOption>[
            _LifeColorOption(
              color: Color(0xFF527A8D),
              labelKey: 'inline.plan295.life.blue_gray.0d33ea7e8f46',
            ),
            _LifeColorOption(
              color: Color(0xFFD2904F),
              labelKey: 'inline.plan295.life.amber.f22e10c17a13',
            ),
            _LifeColorOption(
              color: Color(0xFF7D6BB3),
              labelKey: 'inline.plan295.life.wisteria.b4803a82ff2a',
            ),
            _LifeColorOption(
              color: Color(0xFF5F9C78),
              labelKey: 'inline.plan295.life.moss.73aada12e131',
            ),
            _LifeColorOption(
              color: Color(0xFFC45E6C),
              labelKey: 'inline.plan295.life.rose.01c14bd709f8',
            ),
            _LifeColorOption(
              color: Color(0xFF6A7A3D),
              labelKey: 'inline.plan295.life.olive.77f39e96b47c',
            ),
          ],
          onChanged: _setSelectedColor,
        ),
      ],
    );
  }

  Widget _buildTemplatePanel(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeI18nText(
        context,
        'inline.plan295.life.quick_templates.dcb3d6a1e678',
      ),
      children: <Widget>[
        _LifeSegmentedField<_MindMapTemplate>(
          label: _lifeI18nText(
            context,
            'inline.plan295.life.template.a5232ed073b1',
          ),
          value: _template,
          options: const <_LifeOption<_MindMapTemplate>>[
            _LifeOption<_MindMapTemplate>(
              value: _MindMapTemplate.blank,
              labelKey:
                  'inline.ui.pages.toolbox_human_tests_auditory_lab.blank_06d198',
            ),
            _LifeOption<_MindMapTemplate>(
              value: _MindMapTemplate.plan,
              labelKey: 'inline.plan295.life.project_plan.edce932a7b90',
            ),
            _LifeOption<_MindMapTemplate>(
              value: _MindMapTemplate.meeting,
              labelKey: 'inline.plan295.life.meeting_notes.aca47c111244',
            ),
            _LifeOption<_MindMapTemplate>(
              value: _MindMapTemplate.study,
              labelKey: 'inline.plan295.life.study_topic.486205b5348e',
            ),
          ],
          onChanged: (value) => _applyTemplate(value),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          key: const ValueKey<String>('life_mind_map_clear_button'),
          onPressed: () => _applyTemplate(_MindMapTemplate.blank),
          icon: const Icon(Icons.restart_alt_rounded),
          label: Text(
            _lifeI18nText(
              context,
              'inline.plan295.life.reset_blank.a9704e19fd43',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOutlinePanel(BuildContext context) {
    final root = _rootNode;
    return _LifeSettingsPanel(
      title: _lifeI18nText(context, 'inline.plan295.life.outline.d49be6c65948'),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.full_titles_remain_readable_here.016700e77a05',
      ),
      children: <Widget>[
        if (root == null)
          Text(
            _lifeI18nText(context, 'inline.plan295.life.no_nodes.14ea242f16aa'),
          )
        else
          ..._buildOutlineTiles(context, root, 0),
      ],
    );
  }

  Widget _buildExportPanel(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeI18nText(
        context,
        'inline.ui.pages.practice_notebook_page_actions.export_bc626a',
      ),
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
                      ? _lifeI18nText(
                          context,
                          'inline.plan295.life.exporting.4a7bae70c078',
                        )
                      : _lifeI18nText(
                          context,
                          'inline.plan295.life.export_png.ed4ae20882a0',
                        ),
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
                label: Text(
                  _lifeI18nText(
                    context,
                    'inline.plan295.life.copy_outline.68056499f12a',
                  ),
                ),
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
        ? _lifeI18nText(context, 'inline.plan295.life.untitled.23547dcf51dd')
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
          ? _lifeI18nText(
              context,
              'inline.plan295.life.template_applied.a71c16798a76',
            )
          : null;
    });
    _syncTitleController(nodes.first.title);
  }

  List<_MindMapNode> _templateNodes(_MindMapTemplate template) {
    _MindMapNode node(
      String id,
      String? parentId,
      String titleKey,
      int colorIndex,
    ) {
      return _MindMapNode(
        id: id,
        parentId: parentId,
        title: _lifeI18nText(context, titleKey),
        color: _palette[colorIndex % _palette.length],
      );
    }

    switch (template) {
      case _MindMapTemplate.blank:
        return <_MindMapNode>[
          node('root', null, 'life.mind_map.template.blank.root', 0),
        ];
      case _MindMapTemplate.plan:
        return <_MindMapNode>[
          node('root', null, 'life.mind_map.template.plan.root', 0),
          node('n1', 'root', 'life.mind_map.template.plan.goals', 1),
          node('n2', 'root', 'life.mind_map.template.plan.tasks', 2),
          node('n3', 'root', 'life.mind_map.template.plan.risks', 3),
        ];
      case _MindMapTemplate.meeting:
        return <_MindMapNode>[
          node('root', null, 'life.mind_map.template.meeting.root', 0),
          node('n1', 'root', 'life.mind_map.template.meeting.topics', 1),
          node('n2', 'root', 'life.mind_map.template.meeting.decisions', 2),
          node('n3', 'root', 'life.mind_map.template.meeting.actions', 3),
        ];
      case _MindMapTemplate.study:
        return <_MindMapNode>[
          node('root', null, 'life.mind_map.template.study.root', 0),
          node('n1', 'root', 'life.mind_map.template.study.concepts', 1),
          node('n2', 'root', 'life.mind_map.template.study.examples', 2),
          node('n3', 'root', 'life.mind_map.template.study.review', 3),
        ];
    }
  }

  String _nextId() {
    _serial += 1;
    return 'n$_serial';
  }

  String _nextBranchTitle(String parentId) {
    final next = _childrenOf(parentId).length + 1;
    return _lifeI18nText(
      context,
      'inline.plan296.ui.pages.toolbox.life.tools.toolbox.life.tools.mind.map.new_branch.e05996182d',
      params: <String, Object?>{'next': next},
    );
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
          ? _lifeI18nText(
              context,
              'inline.plan295.life.snap_enabled.0af04952424a',
            )
          : _lifeI18nText(
              context,
              'inline.plan295.life.snap_disabled.882c6c0f7464',
            );
      _errorMessage = null;
    });
  }

  void _resetNodeAnchors() {
    setState(() {
      _nodeAnchors = const <String, Offset>{};
      _statusMessage = _lifeI18nText(
        context,
        'inline.plan295.life.nodes_auto_arranged.ab1e661457cc',
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
      _statusMessage = _lifeI18nText(
        context,
        'inline.plan295.life.outline_copied.e8d64675d180',
      );
      _errorMessage = null;
    });
  }

  Future<void> _exportPng() async {
    final saveDialogTitle = _lifeI18nText(
      context,
      'inline.plan295.life.save_mind_map.b092bd048e1f',
    );
    final browserDownloadMessage = _lifeI18nText(
      context,
      'inline.plan295.crypto.browser_download_started_check_your.b28d392515b4',
    );
    final exportFailedPrefix = _lifeI18nText(
      context,
      'inline.plan295.life.export_failed.35703f3feaf8',
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
