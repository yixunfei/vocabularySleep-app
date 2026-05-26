part of '../toolbox_life_tools.dart';

class _MindMapFullscreenPage extends StatefulWidget {
  const _MindMapFullscreenPage({
    required this.nodes,
    required this.anchors,
    required this.selectedId,
    required this.snapToGrid,
    required this.gridSize,
    required this.onSelect,
    required this.onMoveNode,
    required this.onSnapChanged,
    required this.onResetLayout,
    required this.onRenameNode,
    required this.onAddChild,
    required this.onAddSibling,
    required this.onDeleteNode,
  });

  final List<_MindMapNode> nodes;
  final Map<String, Offset> anchors;
  final String selectedId;
  final bool snapToGrid;
  final double gridSize;
  final ValueChanged<String> onSelect;
  final ValueChanged<_MindMapNodePositionChange> onMoveNode;
  final ValueChanged<bool> onSnapChanged;
  final VoidCallback onResetLayout;
  final _MindMapEditSnapshot Function(String value) onRenameNode;
  final _MindMapEditSnapshot Function() onAddChild;
  final _MindMapEditSnapshot Function() onAddSibling;
  final _MindMapEditSnapshot Function() onDeleteNode;

  @override
  State<_MindMapFullscreenPage> createState() => _MindMapFullscreenPageState();
}

class _MindMapFullscreenPageState extends State<_MindMapFullscreenPage> {
  late List<_MindMapNode> _nodes;
  late Map<String, Offset> _anchors;
  late String _selectedId;
  late bool _snapToGrid;

  @override
  void initState() {
    super.initState();
    _nodes = widget.nodes;
    _anchors = <String, Offset>{...widget.anchors};
    _selectedId = widget.selectedId;
    _snapToGrid = widget.snapToGrid;
  }

  _MindMapNode get _selectedNode {
    return _nodes.firstWhere(
      (node) => node.id == _selectedId,
      orElse: () => _nodes.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selected = _selectedNode;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        leading: IconButton(
          key: const ValueKey<String>('life_mind_map_fullscreen_close_button'),
          tooltip: _lifeText(context, zh: '关闭', en: 'Close'),
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.close_rounded),
        ),
        title: Text(_lifeText(context, zh: '便捷整理', en: 'Quick arrange')),
        actions: <Widget>[
          _compactActionButton(
            key: const ValueKey<String>('life_mind_map_fullscreen_edit_button'),
            tooltip: _lifeText(context, zh: '编辑标题', en: 'Edit title'),
            icon: Icons.edit_rounded,
            onPressed: _editSelectedTitle,
          ),
          _compactActionButton(
            key: const ValueKey<String>(
              'life_mind_map_fullscreen_add_child_button',
            ),
            tooltip: _lifeText(context, zh: '添加子节点', en: 'Add child'),
            icon: Icons.account_tree_rounded,
            onPressed: _addChild,
          ),
          _compactActionButton(
            key: const ValueKey<String>(
              'life_mind_map_fullscreen_add_sibling_button',
            ),
            tooltip: _lifeText(context, zh: '添加同级', en: 'Add sibling'),
            icon: Icons.call_split_rounded,
            onPressed: _selectedNode.parentId == null ? null : _addSibling,
          ),
          _compactActionButton(
            key: const ValueKey<String>(
              'life_mind_map_fullscreen_delete_button',
            ),
            tooltip: _lifeText(context, zh: '删除节点', en: 'Delete node'),
            icon: Icons.delete_outline_rounded,
            onPressed: _selectedNode.parentId == null ? null : _deleteNode,
          ),
          _compactActionButton(
            key: const ValueKey<String>(
              'life_mind_map_fullscreen_reflow_button',
            ),
            tooltip: _lifeText(context, zh: '自动重排', en: 'Auto arrange'),
            onPressed: _resetLayout,
            icon: Icons.auto_fix_high_rounded,
          ),
          _compactActionButton(
            key: const ValueKey<String>('life_mind_map_fullscreen_snap_button'),
            tooltip: _snapToGrid
                ? _lifeText(context, zh: '关闭吸附', en: 'Turn snap off')
                : _lifeText(context, zh: '开启吸附', en: 'Turn snap on'),
            onPressed: () => _setSnap(!_snapToGrid),
            icon: _snapToGrid ? Icons.grid_on_rounded : Icons.grid_off_rounded,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: _buildStatusStrip(context, selected),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _MindMapCanvas(
                  canvasKey: const ValueKey<String>(
                    'life_mind_map_fullscreen_canvas',
                  ),
                  nodes: _nodes,
                  anchors: _anchors,
                  selectedId: _selectedId,
                  onSelect: _selectNode,
                  onMoveNode: _moveNode,
                  snapToGrid: _snapToGrid,
                  showGrid: _snapToGrid,
                  forceManualLayout: true,
                  gridSize: widget.gridSize,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: _buildBottomDock(context, selected),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusStrip(BuildContext context, _MindMapNode selected) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.touch_app_rounded, color: selected.color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              selected.title,
              key: const ValueKey<String>('life_mind_map_fullscreen_active'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 8),
          _MindMapModePill(
            label: _snapToGrid
                ? _lifeText(context, zh: '吸附开启', en: 'Snap on')
                : _lifeText(context, zh: '自由拖拽', en: 'Free drag'),
            icon: _snapToGrid
                ? Icons.grid_4x4_rounded
                : Icons.open_with_rounded,
          ),
        ],
      ),
    );
  }

  Widget _compactActionButton({
    required Key key,
    required String tooltip,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return IconButton(
      key: key,
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 38, height: 48),
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
    );
  }

  Widget _buildBottomDock(BuildContext context, _MindMapNode selected) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                _lifeText(
                  context,
                  zh: '按住节点拖拽，松手后位置会保留。',
                  en: 'Hold and drag a node; its position is kept.',
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(width: 10),
            Switch(
              key: const ValueKey<String>(
                'life_mind_map_fullscreen_snap_switch',
              ),
              value: _snapToGrid,
              onChanged: _setSnap,
            ),
          ],
        ),
      ),
    );
  }

  void _selectNode(String id) {
    setState(() => _selectedId = id);
    widget.onSelect(id);
  }

  void _moveNode(_MindMapNodePositionChange change) {
    setState(() {
      _selectedId = change.nodeId;
      _anchors = <String, Offset>{..._anchors, change.nodeId: change.anchor};
    });
    widget.onMoveNode(change);
  }

  Future<void> _editSelectedTitle() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) =>
          _MindMapTitleEditDialog(initialTitle: _selectedNode.title),
    );
    if (result == null || !mounted) {
      return;
    }
    _applySnapshot(widget.onRenameNode(result));
  }

  void _addChild() {
    _applySnapshot(widget.onAddChild());
  }

  void _addSibling() {
    _applySnapshot(widget.onAddSibling());
  }

  void _deleteNode() {
    _applySnapshot(widget.onDeleteNode());
  }

  void _applySnapshot(_MindMapEditSnapshot snapshot) {
    setState(() {
      _nodes = snapshot.nodes;
      _anchors = <String, Offset>{...snapshot.anchors};
      _selectedId = snapshot.selectedId;
    });
  }

  void _setSnap(bool value) {
    setState(() => _snapToGrid = value);
    widget.onSnapChanged(value);
  }

  void _resetLayout() {
    setState(() => _anchors = const <String, Offset>{});
    widget.onResetLayout();
  }
}

class _MindMapTitleEditDialog extends StatefulWidget {
  const _MindMapTitleEditDialog({required this.initialTitle});

  final String initialTitle;

  @override
  State<_MindMapTitleEditDialog> createState() =>
      _MindMapTitleEditDialogState();
}

class _MindMapTitleEditDialogState extends State<_MindMapTitleEditDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialTitle);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_lifeText(context, zh: '编辑节点', en: 'Edit node')),
      content: TextField(
        key: const ValueKey<String>('life_mind_map_fullscreen_title_field'),
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          labelText: _lifeText(context, zh: '节点标题', en: 'Node title'),
        ),
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(_lifeText(context, zh: '取消', en: 'Cancel')),
        ),
        FilledButton(
          key: const ValueKey<String>(
            'life_mind_map_fullscreen_title_save_button',
          ),
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(_lifeText(context, zh: '保存', en: 'Save')),
        ),
      ],
    );
  }
}

class _MindMapModePill extends StatelessWidget {
  const _MindMapModePill({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: scheme.onPrimaryContainer),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.onPrimaryContainer,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
