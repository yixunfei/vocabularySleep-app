part of 'focus_page.dart';

extension _FocusPageWorkspaceNotesExtension on _FocusPageState {
  Widget _buildNotesDrawer({
    required FocusService focus,
    required List<PlanNote> notes,
    required AppI18n i18n,
    required double width,
    required double handleWidth,
    required double progress,
  }) {
    final theme = Theme.of(context);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: (_) {
        _setViewState(() {
          _notesDrawerDragging = true;
        });
      },
      onHorizontalDragUpdate: (details) =>
          _updateNotesDrawerProgress(details.delta.dx, width),
      onHorizontalDragEnd: (details) =>
          _settleNotesDrawerFromVelocity(details.primaryVelocity ?? 0),
      child: Material(
        color: Colors.transparent,
        elevation: 0,
        borderRadius: BorderRadius.circular(24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: SizedBox(
              key: const ValueKey<String>('notes-drawer'),
              width: width,
              child: Row(
                children: <Widget>[
                  _buildNotesDrawerHandle(
                    i18n,
                    notes.length,
                    progress,
                    handleWidth,
                  ),
                  Expanded(
                    child: IgnorePointer(
                      ignoring: progress < 0.2,
                      child: _buildNotesPanel(focus, notes, i18n),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotesDrawerHandle(
    AppI18n i18n,
    int noteCount,
    double progress,
    double width,
  ) {
    final theme = Theme.of(context);
    final compactHandle = width <= 54;
    final handleColor = Color.lerp(
      theme.colorScheme.surfaceContainerHigh,
      theme.colorScheme.secondaryContainer,
      0.28 + progress * 0.42,
    )!;
    final foregroundColor = Color.lerp(
      theme.colorScheme.onSurfaceVariant,
      theme.colorScheme.onSecondaryContainer,
      0.30 + progress * 0.50,
    )!;

    return InkWell(
      key: const ValueKey<String>('notes-drawer-handle'),
      onTap: _toggleNotesDrawer,
      child: Ink(
        width: width,
        decoration: BoxDecoration(
          color: handleColor,
          border: Border(
            right: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.75),
            ),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compactHandle ? 6 : 8,
            vertical: compactHandle ? 14 : 18,
          ),
          child: Column(
            children: <Widget>[
              Icon(
                progress >= 0.5
                    ? Icons.chevron_right_rounded
                    : Icons.chevron_left_rounded,
                size: compactHandle ? 20 : 24,
                color: foregroundColor,
              ),
              SizedBox(height: compactHandle ? 10 : 14),
              Expanded(
                child: Center(
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: Text(
                      i18n.t('quickNotes'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          (compactHandle
                                  ? theme.textTheme.labelMedium
                                  : theme.textTheme.labelLarge)
                              ?.copyWith(
                                color: foregroundColor,
                                fontWeight: FontWeight.w700,
                              ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: compactHandle ? 10 : 14),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: compactHandle ? 6 : 8,
                  vertical: compactHandle ? 3 : 4,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$noteCount',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotesPanel(
    FocusService focus,
    List<PlanNote> notes,
    AppI18n i18n,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  i18n.t('quickNotes'),
                  style: theme.textTheme.titleMedium,
                ),
              ),
              if (_noteSelectionMode)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    i18n.t(
                      'selectedNotesCount',
                      params: <String, Object?>{
                        'count': _selectedNoteIds.length,
                      },
                    ),
                    style: theme.textTheme.labelLarge,
                  ),
                ),
              IconButton(
                tooltip: _noteSelectionMode
                    ? i18n.t('cancel')
                    : i18n.t('selectNotes'),
                onPressed: () {
                  _setViewState(() {
                    _noteSelectionMode = !_noteSelectionMode;
                    if (!_noteSelectionMode) {
                      _selectedNoteIds.clear();
                    }
                  });
                },
                icon: Icon(
                  _noteSelectionMode
                      ? Icons.close_rounded
                      : Icons.checklist_rtl_rounded,
                ),
              ),
              IconButton(
                tooltip: i18n.t('addNote'),
                onPressed: () => _showNoteDialog(focus, i18n),
                icon: const Icon(Icons.note_add_rounded),
              ),
              if (_noteSelectionMode)
                IconButton(
                  tooltip: i18n.t('deleteSelectedNotes'),
                  onPressed: _selectedNoteIds.isEmpty
                      ? null
                      : () => _confirmDeleteSelectedNotes(focus, i18n),
                  icon: const Icon(Icons.delete_sweep_rounded),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(i18n.t('dragToReorder'), style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          Expanded(
            child: notes.isEmpty
                ? Center(child: Text(i18n.t('notesEmpty')))
                : _noteSelectionMode
                ? _buildSelectableNotesList(notes)
                : _buildReorderableNotesList(focus, notes, i18n),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSheetContentImpl(
    FocusService focus,
    List<PlanNote> notes,
    AppI18n i18n,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  i18n.t('quickNotes'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                tooltip: i18n.t('addNote'),
                onPressed: () => _showNoteDialog(focus, i18n),
                icon: const Icon(Icons.note_add_rounded),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(i18n.t('dragToReorder'), style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          Expanded(
            child: notes.isEmpty
                ? Center(child: Text(i18n.t('notesEmpty')))
                : _buildReorderableNotesList(focus, notes, i18n),
          ),
        ],
      ),
    );
  }

  double _notesDrawerWidth(double maxWidth, FocusService focus) {
    final maxAllowed = math.max(0.0, maxWidth - 12);
    if (maxWidth < 520) {
      return math.min(maxAllowed, math.max(220.0, maxWidth * 0.88));
    }
    final preferredRatio = focus.config.normalizedWorkspaceSplitRatio
        .clamp(0.42, 0.68)
        .toDouble();
    return math.min(maxAllowed, math.max(320.0, maxWidth * preferredRatio));
  }

  void _toggleNotesDrawer() {
    _settleNotesDrawer(open: _notesDrawerProgress < 0.5);
  }

  void _updateNotesDrawerProgress(double deltaX, double drawerWidth) {
    final safeWidth = math.max(drawerWidth, 1);
    _setViewState(() {
      _notesDrawerDragging = true;
      _notesDrawerProgress = (_notesDrawerProgress - deltaX / safeWidth)
          .clamp(0.0, 1.0)
          .toDouble();
    });
  }

  void _settleNotesDrawerFromVelocity(double velocity) {
    final shouldOpen =
        velocity < -220 ||
        (velocity.abs() < 220 && _notesDrawerProgress >= 0.45);
    _settleNotesDrawer(open: shouldOpen);
  }

  void _settleNotesDrawer({required bool open}) {
    _setViewState(() {
      _notesDrawerDragging = false;
      _notesDrawerProgress = open ? 1.0 : 0.0;
    });
  }

  Widget _buildSelectableNotesList(List<PlanNote> notes) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: _selectedNoteIds.contains(note.id)
              ? Theme.of(context).colorScheme.secondaryContainer
              : _noteColor(note),
          child: CheckboxListTile(
            value: _selectedNoteIds.contains(note.id),
            onChanged: (_) => _toggleSelectedNote(note),
            title: Text(note.title),
            subtitle: (note.content ?? '').trim().isEmpty
                ? null
                : Text(
                    note.content!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
        );
      },
    );
  }

  Widget _buildReorderableNotesList(
    FocusService focus,
    List<PlanNote> notes,
    AppI18n i18n,
  ) {
    return ReorderableListView.builder(
      physics: const BouncingScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: notes.length,
      onReorder: (oldIndex, newIndex) {
        final ordered = List<PlanNote>.from(notes);
        if (newIndex > oldIndex) {
          newIndex -= 1;
        }
        final item = ordered.removeAt(oldIndex);
        ordered.insert(newIndex, item);
        focus.reorderNotes(ordered);
      },
      itemBuilder: (context, index) {
        final note = notes[index];
        return Card(
          key: ValueKey<int>(note.id ?? index),
          margin: const EdgeInsets.only(bottom: 8),
          color: _noteColor(note),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 4,
            ),
            title: Text(note.title),
            subtitle: (note.content ?? '').trim().isEmpty
                ? null
                : Text(
                    note.content!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
            onTap: () => _showNoteDialog(focus, i18n, note: note),
            onLongPress: () {
              _setViewState(() {
                _noteSelectionMode = true;
                if (note.id != null) {
                  _selectedNoteIds.add(note.id!);
                }
              });
            },
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                IconButton(
                  tooltip: i18n.t('delete'),
                  onPressed: () => _confirmDeleteSingleNote(focus, note, i18n),
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
                ReorderableDelayedDragStartListener(
                  index: index,
                  child: const Icon(Icons.drag_handle_rounded),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _toggleSelectedNote(PlanNote note) {
    final id = note.id;
    if (id == null) return;
    _setViewState(() {
      if (_selectedNoteIds.contains(id)) {
        _selectedNoteIds.remove(id);
      } else {
        _selectedNoteIds.add(id);
      }
    });
  }

  Color? _noteColor(PlanNote note) {
    return _parseHexColor(note.color);
  }

  Color? _parseHexColor(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      return Color(int.parse(value, radix: 16));
    } catch (_) {
      return null;
    }
  }
}
