part of 'focus_page.dart';

extension _FocusPageWorkspaceTodoExtension on _FocusPageState {
  Widget _buildTodoPanel(
    FocusService focus,
    AppI18n i18n, {
    List<PlanNote> notes = const <PlanNote>[],
  }) {
    final todos = focus.getTodos();
    final theme = Theme.of(context);
    final filteredTodos = _filterTodos(todos);
    final displayTodos = _sortedTodos(filteredTodos);
    final planSections = _buildTodoPlanSections(filteredTodos, i18n);
    final manualSort =
        _todoSortMode == _TodoSortMode.manual &&
        _todoFilterMode == _TodoFilterMode.all;
    final metrics = _buildTodoMetrics(todos);

    return Card(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compactLayout = constraints.maxWidth < 600;
          if (compactLayout) {
            return _buildCompactTodoPanel(
              focus: focus,
              i18n: i18n,
              theme: theme,
              notes: notes,
              metrics: metrics,
              displayTodos: displayTodos,
              planSections: planSections,
              manualSort: manualSort,
              hasCompletedTodos: todos.any((item) => item.completed),
              constraints: constraints,
            );
          }
          final topSection = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildTodoHeader(
                focus: focus,
                i18n: i18n,
                theme: theme,
                hasCompletedTodos: todos.any((item) => item.completed),
                compactLayout: compactLayout,
              ),
              const SizedBox(height: 8),
              _buildTodoWorkspaceSummary(metrics, i18n, compact: false),
              const SizedBox(height: 8),
              TextField(
                key: const ValueKey<String>('todo-editor-entry'),
                readOnly: true,
                onTap: () => _showTodoEditor(focus, i18n),
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerLowest,
                  hintText: pickUiText(
                    i18n,
                    zh: '\u70b9\u51fb\u6dfb\u52a0\u5f85\u529e\u4e8b\u9879',
                    en: 'Tap to add a task',
                    ja: 'タップしてタスクを追加',
                    de: 'Tippen, um eine Aufgabe hinzuzufuegen',
                    fr: 'Touchez pour ajouter une tache',
                    es: 'Toca para anadir una tarea',
                    ru: 'Нажмите, чтобы добавить задачу',
                  ),
                  prefixIcon: const Icon(Icons.add_task_rounded),
                  suffixIcon: const Icon(Icons.edit_note_rounded),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _buildTodoControls(
                i18n,
                manualSort: manualSort,
                compact: compactLayout,
              ),
              const SizedBox(height: 12),
              _buildTodoListBody(
                focus: focus,
                i18n: i18n,
                planSections: planSections,
                displayTodos: displayTodos,
                manualSort: manualSort,
                scrollable: false,
              ),
            ],
          );

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(10),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: math.max(0.0, constraints.maxHeight - 20),
              ),
              child: topSection,
            ),
          );
        },
      ),
    );
  }

  Widget _buildCompactTodoPanel({
    required FocusService focus,
    required AppI18n i18n,
    required ThemeData theme,
    required List<PlanNote> notes,
    required Map<String, int> metrics,
    required List<TodoItem> displayTodos,
    required List<_TodoPlanSection> planSections,
    required bool manualSort,
    required bool hasCompletedTodos,
    required BoxConstraints constraints,
  }) {
    final listBody = _buildTodoListBody(
      focus: focus,
      i18n: i18n,
      planSections: planSections,
      displayTodos: displayTodos,
      manualSort: manualSort,
      scrollable: true,
    );

    final metricsRow = _buildTodoMetricsStrip(metrics, i18n, compact: true);

    final commandRow = _buildTodoControls(
      i18n,
      manualSort: manualSort,
      compact: true,
    );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildTodoHeader(
          focus: focus,
          i18n: i18n,
          theme: theme,
          hasCompletedTodos: hasCompletedTodos,
          compactLayout: true,
          actions: <Widget>[
            IconButton(
              key: const ValueKey<String>('todo-notes-sheet-button'),
              tooltip: i18n.t('quickNotes'),
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints.tightFor(width: 30, height: 30),
              padding: EdgeInsets.zero,
              onPressed: () => _showNotesSheet(focus, i18n),
              icon: const Icon(Icons.sticky_note_2_outlined),
            ),
            _buildTodoMetricsToggleButton(i18n),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          key: const ValueKey<String>('todo-editor-entry'),
          readOnly: true,
          onTap: () => _showTodoEditor(focus, i18n),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerLowest,
            hintText: pickUiText(i18n, zh: '快速添加待办', en: 'Quick add a task'),
            prefixIcon: const Icon(Icons.add_task_rounded),
            suffixIcon: const Icon(Icons.edit_note_rounded),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 9,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
          ),
        ),
        const SizedBox(height: 6),
        metricsRow,
        const SizedBox(height: 6),
        commandRow,
        const SizedBox(height: 10),
        Expanded(child: listBody),
      ],
    );

    if (!constraints.maxHeight.isFinite) {
      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildTodoHeader(
              focus: focus,
              i18n: i18n,
              theme: theme,
              hasCompletedTodos: hasCompletedTodos,
              compactLayout: true,
              actions: <Widget>[
                IconButton(
                  key: const ValueKey<String>('todo-notes-sheet-button'),
                  tooltip: i18n.t('quickNotes'),
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints.tightFor(
                    width: 30,
                    height: 30,
                  ),
                  padding: EdgeInsets.zero,
                  onPressed: () => _showNotesSheet(focus, i18n),
                  icon: const Icon(Icons.sticky_note_2_outlined),
                ),
                _buildTodoMetricsToggleButton(i18n),
              ],
            ),
            const SizedBox(height: 6),
            TextField(
              key: const ValueKey<String>('todo-editor-entry'),
              readOnly: true,
              onTap: () => _showTodoEditor(focus, i18n),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerLowest,
                hintText: pickUiText(
                  i18n,
                  zh: '快速添加待办',
                  en: 'Quick add a task',
                ),
                prefixIcon: const Icon(Icons.add_task_rounded),
                suffixIcon: const Icon(Icons.edit_note_rounded),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 9,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
            const SizedBox(height: 6),
            metricsRow,
            const SizedBox(height: 6),
            commandRow,
            const SizedBox(height: 10),
            _buildTodoListBody(
              focus: focus,
              i18n: i18n,
              planSections: planSections,
              displayTodos: displayTodos,
              manualSort: manualSort,
              scrollable: false,
            ),
          ],
        ),
      );
    }

    return Padding(padding: const EdgeInsets.all(10), child: content);
  }

  Widget _buildTodoListBody({
    required FocusService focus,
    required AppI18n i18n,
    required List<_TodoPlanSection> planSections,
    required List<TodoItem> displayTodos,
    required bool manualSort,
    bool scrollable = false,
  }) {
    if (_todoViewMode == _TodoViewMode.plan) {
      return _buildTodoPlanView(
        focus,
        planSections,
        i18n,
        scrollable: scrollable,
      );
    }
    if (displayTodos.isEmpty) {
      final theme = Theme.of(context);
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Text(
          i18n.t('todosEmpty'),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    return manualSort
        ? _buildReorderableTodosList(
            focus,
            displayTodos,
            i18n,
            scrollable: scrollable,
          )
        : _buildSortedTodosList(
            focus,
            displayTodos,
            i18n,
            scrollable: scrollable,
          );
  }

  Widget _buildTodoHeader({
    required FocusService focus,
    required AppI18n i18n,
    required ThemeData theme,
    required bool hasCompletedTodos,
    bool compactLayout = false,
    List<Widget> actions = const <Widget>[],
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: Text(
            i18n.t('todoTab'),
            style:
                (compactLayout
                        ? theme.textTheme.titleSmall
                        : theme.textTheme.titleMedium)
                    ?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        ...actions,
        if (hasCompletedTodos) _buildTodoClearCompletedButton(focus, i18n),
      ],
    );
  }

  Widget _buildTodoWorkspaceSummary(
    Map<String, int> metrics,
    AppI18n i18n, {
    bool compact = false,
  }) {
    return _buildTodoMetricsStrip(metrics, i18n, compact: compact);
  }

  // ignore: unused_element
  Widget _buildTodoMetricOrbit({
    required Key key,
    required int value,
    required String label,
    required Color color,
    required bool compact,
  }) {
    final theme = Theme.of(context);
    final size = compact ? 56.0 : 64.0;
    return Tooltip(
      message: label,
      child: InkWell(
        key: key,
        borderRadius: BorderRadius.circular(size / 2),
        onTap: () {
          _setViewState(() {
            _todoMetricsExpanded = !_todoMetricsExpanded;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: size,
          height: size,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            shape: BoxShape.circle,
            border: Border.all(
              color: color.withValues(
                alpha: _todoMetricsExpanded ? 0.48 : 0.22,
              ),
              width: _todoMetricsExpanded ? 1.4 : 1,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: color.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                width: compact ? 10 : 11,
                height: compact ? 10 : 11,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  '$value',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildTodoMetricsToggleButton(AppI18n i18n) {
    return IconButton(
      key: const ValueKey<String>('todo-metrics-toggle'),
      tooltip: _todoMetricsExpanded
          ? pickUiText(i18n, zh: '收起统计', en: 'Collapse stats')
          : pickUiText(i18n, zh: '展开统计', en: 'Expand stats'),
      visualDensity: VisualDensity.compact,
      onPressed: () {
        _setViewState(() {
          _todoMetricsExpanded = !_todoMetricsExpanded;
        });
      },
      icon: Icon(
        _todoMetricsExpanded
            ? Icons.unfold_less_rounded
            : Icons.unfold_more_rounded,
      ),
    );
  }

  Widget _buildTodoClearCompletedButton(FocusService focus, AppI18n i18n) {
    return IconButton(
      tooltip: i18n.t('clearCompleted'),
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 30, height: 30),
      padding: EdgeInsets.zero,
      onPressed: focus.clearCompletedTodos,
      icon: const Icon(Icons.done_all_rounded),
    );
  }

  Map<String, int> _buildTodoMetrics(List<TodoItem> todos) {
    final today = DateTime.now();
    final todayStart = _startOfDay(today);
    final tomorrowStart = todayStart.add(const Duration(days: 1));
    var active = 0;
    var completed = 0;
    var deferred = 0;
    var overdue = 0;
    var todayCount = 0;

    for (final todo in todos) {
      if (todo.completed) {
        completed += 1;
        continue;
      }
      if (todo.isDeferred) {
        deferred += 1;
        continue;
      }
      active += 1;
      final dueAt = todo.dueAt;
      if (dueAt == null) {
        continue;
      }
      if (dueAt.isBefore(todayStart)) {
        overdue += 1;
      } else if (dueAt.isBefore(tomorrowStart)) {
        todayCount += 1;
      }
    }

    return <String, int>{
      'all': todos.length,
      'active': active,
      'today': todayCount,
      'overdue': overdue,
      'deferred': deferred,
      'completed': completed,
    };
  }

  List<({String key, String label, IconData icon, Color color})>
  _todoMetricItems(AppI18n i18n, ThemeData theme) {
    return <({String key, String label, IconData icon, Color color})>[
      (
        key: 'all',
        label: _todoFilterModeLabel(i18n, _TodoFilterMode.all),
        icon: Icons.apps_rounded,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      (
        key: 'active',
        label: _todoFilterModeLabel(i18n, _TodoFilterMode.active),
        icon: Icons.flash_on_rounded,
        color: theme.colorScheme.primary,
      ),
      (
        key: 'today',
        label: _todoFilterModeLabel(i18n, _TodoFilterMode.today),
        icon: Icons.today_rounded,
        color: theme.colorScheme.tertiary,
      ),
      (
        key: 'overdue',
        label: _todoFilterModeLabel(i18n, _TodoFilterMode.overdue),
        icon: Icons.warning_amber_rounded,
        color: theme.colorScheme.error,
      ),
      (
        key: 'deferred',
        label: _todoFilterModeLabel(i18n, _TodoFilterMode.deferred),
        icon: Icons.snooze_rounded,
        color: theme.colorScheme.outline,
      ),
      (
        key: 'completed',
        label: _todoFilterModeLabel(i18n, _TodoFilterMode.completed),
        icon: Icons.task_alt_rounded,
        color: theme.colorScheme.secondary,
      ),
    ];
  }

  Widget _buildTodoMetricsStrip(
    Map<String, int> metrics,
    AppI18n i18n, {
    bool compact = false,
  }) {
    final theme = Theme.of(context);
    final items = _todoMetricItems(i18n, theme);

    return Wrap(
      spacing: compact ? 6 : 8,
      runSpacing: compact ? 6 : 8,
      children: items
          .map(
            (item) => _buildTodoMetricCompactBadge(
              key: ValueKey<String>('todo-metric-badge-${item.key}'),
              metricKey: item.key,
              value: metrics[item.key] ?? 0,
              label: item.label,
              color: item.color,
              compact: compact,
            ),
          )
          .toList(growable: false),
    );
  }

  Widget _buildTodoMetricCompactBadge({
    required Key key,
    required String metricKey,
    required int value,
    required String label,
    required Color color,
    bool compact = false,
  }) {
    final theme = Theme.of(context);
    final filterMode = _todoFilterModeForMetricKey(metricKey);
    final expanded =
        _todoMetricsExpanded || _expandedTodoMetricKey == metricKey;
    final selected = _todoFilterMode == filterMode;
    final emphasized = expanded || selected;

    return Tooltip(
      message: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: key,
          borderRadius: BorderRadius.circular(999),
          onTap: () {
            _setViewState(() {
              _todoFilterMode = filterMode;
              if (_todoMetricsExpanded) {
                _expandedTodoMetricKey = metricKey;
              } else {
                _expandedTodoMetricKey = expanded && selected
                    ? null
                    : metricKey;
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: expanded ? (compact ? 10 : 12) : (compact ? 8 : 10),
              vertical: compact ? 7 : 8,
            ),
            decoration: BoxDecoration(
              color: color.withValues(
                alpha: emphasized ? (selected ? 0.18 : 0.15) : 0.08,
              ),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: color.withValues(alpha: emphasized ? 0.38 : 0.18),
                width: selected ? 1.4 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '$value',
                  style:
                      (compact
                              ? theme.textTheme.labelLarge
                              : theme.textTheme.titleSmall)
                          ?.copyWith(
                            color: selected
                                ? color
                                : theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w800,
                          ),
                ),
                if (expanded) ...<Widget>[
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  _TodoFilterMode _todoFilterModeForMetricKey(String metricKey) {
    return switch (metricKey) {
      'all' => _TodoFilterMode.all,
      'active' => _TodoFilterMode.active,
      'today' => _TodoFilterMode.today,
      'overdue' => _TodoFilterMode.overdue,
      'deferred' => _TodoFilterMode.deferred,
      'completed' => _TodoFilterMode.completed,
      _ => _TodoFilterMode.all,
    };
  }

  String _todoViewModeLabel(AppI18n i18n, _TodoViewMode mode) {
    return switch (mode) {
      _TodoViewMode.plan => pickUiText(
        i18n,
        zh: '\u8ba1\u5212\u89c6\u56fe',
        en: 'Plan view',
      ),
      _TodoViewMode.list => pickUiText(
        i18n,
        zh: '\u5217\u8868\u89c6\u56fe',
        en: 'List view',
      ),
    };
  }

  String _todoFilterModeLabel(AppI18n i18n, _TodoFilterMode mode) {
    return switch (mode) {
      _TodoFilterMode.all => pickUiText(i18n, zh: '\u5168\u90e8', en: 'All'),
      _TodoFilterMode.active => pickUiText(
        i18n,
        zh: '\u8fdb\u884c\u4e2d',
        en: 'Active',
      ),
      _TodoFilterMode.today => pickUiText(
        i18n,
        zh: '\u4eca\u5929\u5230\u671f',
        en: 'Due today',
      ),
      _TodoFilterMode.overdue => pickUiText(
        i18n,
        zh: '\u5df2\u903e\u671f',
        en: 'Overdue',
      ),
      _TodoFilterMode.deferred => pickUiText(
        i18n,
        zh: '\u5ef6\u540e\u6401\u7f6e',
        en: 'Deferred',
      ),
      _TodoFilterMode.completed => pickUiText(
        i18n,
        zh: '\u5df2\u5b8c\u6210',
        en: 'Completed',
      ),
    };
  }

  String _todoSortModeLabel(AppI18n i18n, _TodoSortMode mode) {
    return switch (mode) {
      _TodoSortMode.manual => i18n.t('dragToReorder'),
      _TodoSortMode.priority => i18n.t('todoPriority'),
      _TodoSortMode.category => i18n.t('todoCategory'),
    };
  }

  Widget _buildTodoControls(
    AppI18n i18n, {
    required bool manualSort,
    bool compact = false,
  }) {
    final theme = Theme.of(context);
    if (compact) {
      return Container(
        width: double.infinity,
        key: const ValueKey<String>('todo-controls'),
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            _buildTodoCompactMenuButton<_TodoViewMode>(
              key: const ValueKey<String>('todo-view-menu'),
              icon: Icons.view_week_rounded,
              label: _todoViewModeLabel(i18n, _todoViewMode),
              items: <PopupMenuEntry<_TodoViewMode>>[
                CheckedPopupMenuItem<_TodoViewMode>(
                  key: const ValueKey<String>('todo-view-plan'),
                  value: _TodoViewMode.plan,
                  checked: _todoViewMode == _TodoViewMode.plan,
                  child: Text(_todoViewModeLabel(i18n, _TodoViewMode.plan)),
                ),
                CheckedPopupMenuItem<_TodoViewMode>(
                  key: const ValueKey<String>('todo-view-list'),
                  value: _TodoViewMode.list,
                  checked: _todoViewMode == _TodoViewMode.list,
                  child: Text(_todoViewModeLabel(i18n, _TodoViewMode.list)),
                ),
              ],
              onSelected: (value) {
                _setViewState(() {
                  _todoViewMode = value;
                });
              },
            ),
            _buildTodoCompactMenuButton<_TodoFilterMode>(
              key: const ValueKey<String>('todo-filter-menu'),
              icon: Icons.filter_alt_rounded,
              label: _todoFilterModeLabel(i18n, _todoFilterMode),
              items: _buildTodoFilterMenuItems(i18n),
              onSelected: (value) {
                _setViewState(() {
                  _todoFilterMode = value;
                  _expandedTodoMetricKey = null;
                });
              },
            ),
            if (_todoViewMode == _TodoViewMode.list)
              _buildTodoCompactMenuButton<_TodoSortMode>(
                key: const ValueKey<String>('todo-sort-menu'),
                icon: Icons.swap_vert_rounded,
                label: _todoSortModeLabel(i18n, _todoSortMode),
                items: <PopupMenuEntry<_TodoSortMode>>[
                  CheckedPopupMenuItem<_TodoSortMode>(
                    key: const ValueKey<String>('todo-sort-manual'),
                    value: _TodoSortMode.manual,
                    checked: manualSort,
                    child: Text(_todoSortModeLabel(i18n, _TodoSortMode.manual)),
                  ),
                  CheckedPopupMenuItem<_TodoSortMode>(
                    key: const ValueKey<String>('todo-sort-priority'),
                    value: _TodoSortMode.priority,
                    checked: _todoSortMode == _TodoSortMode.priority,
                    child: Text(
                      _todoSortModeLabel(i18n, _TodoSortMode.priority),
                    ),
                  ),
                  CheckedPopupMenuItem<_TodoSortMode>(
                    key: const ValueKey<String>('todo-sort-category'),
                    value: _TodoSortMode.category,
                    checked: _todoSortMode == _TodoSortMode.category,
                    child: Text(
                      _todoSortModeLabel(i18n, _TodoSortMode.category),
                    ),
                  ),
                ],
                onSelected: (value) {
                  _setViewState(() {
                    _todoSortMode = value;
                  });
                },
              ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      key: const ValueKey<String>('todo-controls'),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildTodoControlSection(
            label: pickUiText(i18n, zh: '\u89c6\u56fe', en: 'View'),
            children: <Widget>[
              _buildTodoChoiceChip(
                key: const ValueKey<String>('todo-view-plan'),
                label: _todoViewModeLabel(i18n, _TodoViewMode.plan),
                selected: _todoViewMode == _TodoViewMode.plan,
                onSelected: () {
                  _setViewState(() {
                    _todoViewMode = _TodoViewMode.plan;
                  });
                },
              ),
              _buildTodoChoiceChip(
                key: const ValueKey<String>('todo-view-list'),
                label: _todoViewModeLabel(i18n, _TodoViewMode.list),
                selected: _todoViewMode == _TodoViewMode.list,
                onSelected: () {
                  _setViewState(() {
                    _todoViewMode = _TodoViewMode.list;
                  });
                },
              ),
            ],
          ),
          if (_todoViewMode == _TodoViewMode.list) ...<Widget>[
            const SizedBox(height: 8),
            _buildTodoControlSection(
              label: pickUiText(i18n, zh: '\u6392\u5e8f', en: 'Sort'),
              children: <Widget>[
                _buildTodoChoiceChip(
                  key: const ValueKey<String>('todo-sort-manual'),
                  label: _todoSortModeLabel(i18n, _TodoSortMode.manual),
                  selected: manualSort,
                  onSelected: () {
                    _setViewState(() {
                      _todoSortMode = _TodoSortMode.manual;
                    });
                  },
                ),
                _buildTodoChoiceChip(
                  key: const ValueKey<String>('todo-sort-priority'),
                  label: _todoSortModeLabel(i18n, _TodoSortMode.priority),
                  selected: _todoSortMode == _TodoSortMode.priority,
                  onSelected: () {
                    _setViewState(() {
                      _todoSortMode = _TodoSortMode.priority;
                    });
                  },
                ),
                _buildTodoChoiceChip(
                  key: const ValueKey<String>('todo-sort-category'),
                  label: _todoSortModeLabel(i18n, _TodoSortMode.category),
                  selected: _todoSortMode == _TodoSortMode.category,
                  onSelected: () {
                    _setViewState(() {
                      _todoSortMode = _TodoSortMode.category;
                    });
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTodoCompactMenuButton<T>({
    required Key key,
    required IconData icon,
    required String label,
    required List<PopupMenuEntry<T>> items,
    required PopupMenuItemSelected<T> onSelected,
  }) {
    final theme = Theme.of(context);

    return PopupMenuButton<T>(
      key: key,
      itemBuilder: (_) => items,
      onSelected: onSelected,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 176),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Icon(icon, size: 15, color: theme.colorScheme.primary),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.expand_more_rounded,
                size: 15,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<PopupMenuEntry<_TodoFilterMode>> _buildTodoFilterMenuItems(
    AppI18n i18n,
  ) {
    return <PopupMenuEntry<_TodoFilterMode>>[
      CheckedPopupMenuItem<_TodoFilterMode>(
        key: const ValueKey<String>('todo-filter-all'),
        value: _TodoFilterMode.all,
        checked: _todoFilterMode == _TodoFilterMode.all,
        child: Text(_todoFilterModeLabel(i18n, _TodoFilterMode.all)),
      ),
      CheckedPopupMenuItem<_TodoFilterMode>(
        key: const ValueKey<String>('todo-filter-active'),
        value: _TodoFilterMode.active,
        checked: _todoFilterMode == _TodoFilterMode.active,
        child: Text(_todoFilterModeLabel(i18n, _TodoFilterMode.active)),
      ),
      CheckedPopupMenuItem<_TodoFilterMode>(
        key: const ValueKey<String>('todo-filter-today'),
        value: _TodoFilterMode.today,
        checked: _todoFilterMode == _TodoFilterMode.today,
        child: Text(_todoFilterModeLabel(i18n, _TodoFilterMode.today)),
      ),
      CheckedPopupMenuItem<_TodoFilterMode>(
        key: const ValueKey<String>('todo-filter-overdue'),
        value: _TodoFilterMode.overdue,
        checked: _todoFilterMode == _TodoFilterMode.overdue,
        child: Text(_todoFilterModeLabel(i18n, _TodoFilterMode.overdue)),
      ),
      CheckedPopupMenuItem<_TodoFilterMode>(
        key: const ValueKey<String>('todo-filter-deferred'),
        value: _TodoFilterMode.deferred,
        checked: _todoFilterMode == _TodoFilterMode.deferred,
        child: Text(_todoFilterModeLabel(i18n, _TodoFilterMode.deferred)),
      ),
      CheckedPopupMenuItem<_TodoFilterMode>(
        key: const ValueKey<String>('todo-filter-completed'),
        value: _TodoFilterMode.completed,
        checked: _todoFilterMode == _TodoFilterMode.completed,
        child: Text(_todoFilterModeLabel(i18n, _TodoFilterMode.completed)),
      ),
    ];
  }

  Widget _buildTodoControlSection({
    required String label,
    required List<Widget> children,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildTodoControlLabel(label),
        const SizedBox(width: 8),
        Expanded(child: Wrap(spacing: 6, runSpacing: 6, children: children)),
      ],
    );
  }

  Widget _buildTodoChoiceChip({
    Key? key,
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      key: key,
      label: Text(label),
      selected: selected,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      onSelected: (_) => onSelected(),
    );
  }

  Widget _buildTodoControlLabel(String label) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  List<TodoItem> _sortedTodos(List<TodoItem> todos) {
    final items = List<TodoItem>.from(todos);
    switch (_todoSortMode) {
      case _TodoSortMode.manual:
        return items;
      case _TodoSortMode.priority:
        items.sort(_compareTodosByPriority);
        return items;
      case _TodoSortMode.category:
        items.sort(_compareTodosByCategory);
        return items;
    }
  }

  List<TodoItem> _filterTodos(List<TodoItem> todos) {
    final now = DateTime.now();
    final todayStart = _startOfDay(now);
    final tomorrowStart = todayStart.add(const Duration(days: 1));

    return todos
        .where((item) {
          final dueAt = item.dueAt;
          return switch (_todoFilterMode) {
            _TodoFilterMode.all => true,
            _TodoFilterMode.active => !item.completed && !item.isDeferred,
            _TodoFilterMode.today =>
              !item.completed &&
                  !item.isDeferred &&
                  dueAt != null &&
                  !dueAt.isBefore(todayStart) &&
                  dueAt.isBefore(tomorrowStart),
            _TodoFilterMode.overdue =>
              !item.completed &&
                  !item.isDeferred &&
                  dueAt != null &&
                  dueAt.isBefore(todayStart),
            _TodoFilterMode.deferred => item.isDeferred,
            _TodoFilterMode.completed => item.completed,
          };
        })
        .toList(growable: false);
  }

  List<_TodoPlanSection> _buildTodoPlanSections(
    List<TodoItem> todos,
    AppI18n i18n,
  ) {
    final now = DateTime.now();
    final todayStart = _startOfDay(now);
    final tomorrowStart = todayStart.add(const Duration(days: 1));

    final overdue = <TodoItem>[];
    final today = <TodoItem>[];
    final upcoming = <TodoItem>[];
    final deferred = <TodoItem>[];
    final inbox = <TodoItem>[];
    final completed = <TodoItem>[];

    for (final todo in todos) {
      if (todo.completed) {
        completed.add(todo);
        continue;
      }
      if (todo.isDeferred) {
        deferred.add(todo);
        continue;
      }
      final dueAt = todo.dueAt;
      if (dueAt == null) {
        inbox.add(todo);
      } else if (dueAt.isBefore(todayStart)) {
        overdue.add(todo);
      } else if (dueAt.isBefore(tomorrowStart)) {
        today.add(todo);
      } else {
        upcoming.add(todo);
      }
    }

    final sections = <_TodoPlanSection>[
      _TodoPlanSection(
        key: 'todo-plan-overdue',
        title: pickUiText(
          i18n,
          zh: '逾期待处理',
          en: 'Overdue',
          ja: '期限超過',
          de: 'Ueberfaellig',
          fr: 'En retard',
          es: 'Vencidas',
          ru: 'Просрочено',
        ),
        icon: Icons.warning_amber_rounded,
        items: _sortedTodos(overdue),
        highlight: overdue.isNotEmpty,
      ),
      _TodoPlanSection(
        key: 'todo-plan-today',
        title: pickUiText(
          i18n,
          zh: '今天计划',
          en: 'Today',
          ja: '今日',
          de: 'Heute',
          fr: 'Aujourd’hui',
          es: 'Hoy',
          ru: 'Сегодня',
        ),
        icon: Icons.today_rounded,
        items: _sortedTodos(today),
      ),
      _TodoPlanSection(
        key: 'todo-plan-upcoming',
        title: pickUiText(
          i18n,
          zh: '接下来',
          en: 'Upcoming',
          ja: 'これから',
          de: 'Als naechstes',
          fr: 'A venir',
          es: 'Proximas',
          ru: 'Дальше',
        ),
        icon: Icons.upcoming_rounded,
        items: _sortedTodos(upcoming),
      ),
      _TodoPlanSection(
        key: 'todo-plan-deferred',
        title: pickUiText(
          i18n,
          zh: '延后搁置',
          en: 'Deferred',
          ja: '保留中',
          de: 'Zurueckgestellt',
          fr: 'Reporte',
          es: 'Pospuestas',
          ru: 'Отложено',
        ),
        icon: Icons.snooze_rounded,
        items: _sortedTodos(deferred),
      ),
      _TodoPlanSection(
        key: 'todo-plan-inbox',
        title: pickUiText(
          i18n,
          zh: '收件箱',
          en: 'Inbox',
          ja: '受信箱',
          de: 'Inbox',
          fr: 'Boite de reception',
          es: 'Bandeja',
          ru: 'Входящие',
        ),
        icon: Icons.inbox_rounded,
        items: _sortedTodos(inbox),
      ),
    ];

    if (_todoFilterMode == _TodoFilterMode.deferred) {
      return <_TodoPlanSection>[
        _TodoPlanSection(
          key: 'todo-plan-deferred',
          title: pickUiText(
            i18n,
            zh: '延后搁置',
            en: 'Deferred',
            ja: '保留中',
            de: 'Zurueckgestellt',
            fr: 'Reporte',
            es: 'Pospuestas',
            ru: 'Отложено',
          ),
          icon: Icons.snooze_rounded,
          items: _sortedTodos(deferred),
        ),
      ];
    }

    if (_todoFilterMode == _TodoFilterMode.completed) {
      return <_TodoPlanSection>[
        _TodoPlanSection(
          key: 'todo-plan-completed',
          title: pickUiText(
            i18n,
            zh: '已完成',
            en: 'Completed',
            ja: '完了',
            de: 'Erledigt',
            fr: 'Terminees',
            es: 'Completadas',
            ru: 'Выполнено',
          ),
          icon: Icons.task_alt_rounded,
          items: _sortedTodos(completed),
        ),
      ];
    }

    final visible = sections
        .where((section) => section.items.isNotEmpty)
        .toList(growable: true);
    if (_todoFilterMode == _TodoFilterMode.all && completed.isNotEmpty) {
      visible.add(
        _TodoPlanSection(
          key: 'todo-plan-completed',
          title: pickUiText(
            i18n,
            zh: '已完成',
            en: 'Completed',
            ja: '完了',
            de: 'Erledigt',
            fr: 'Terminees',
            es: 'Completadas',
            ru: 'Выполнено',
          ),
          icon: Icons.task_alt_rounded,
          items: _sortedTodos(completed),
        ),
      );
    }
    return visible;
  }

  Widget _buildTodoPlanView(
    FocusService focus,
    List<_TodoPlanSection> sections,
    AppI18n i18n, {
    bool scrollable = false,
  }) {
    if (sections.isEmpty) {
      return Center(
        child: Text(
          pickUiText(
            i18n,
            zh: '当前筛选下还没有任务，先添加一个今天要完成的小目标吧。',
            en: 'No tasks match this view yet. Add one small goal for today.',
            ja: 'この表示にはまだタスクがありません。まずは今日の小さな目標を追加しましょう。',
            de: 'In dieser Ansicht gibt es noch keine Aufgaben. Fuege zuerst ein kleines Ziel fuer heute hinzu.',
            fr: 'Aucune tache pour cette vue. Ajoutez d’abord un petit objectif pour aujourd’hui.',
            es: 'Aun no hay tareas en esta vista. Agrega primero un pequeno objetivo para hoy.',
            ru: 'Для этого представления пока нет задач. Добавьте сначала одну небольшую цель на сегодня.',
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (scrollable) {
      return ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: sections.length,
        itemBuilder: (context, index) {
          final section = sections[index];
          return Padding(
            padding: EdgeInsets.only(
              bottom: index == sections.length - 1 ? 0 : 12,
            ),
            child: _buildTodoPlanSection(focus, section, i18n),
          );
        },
      );
    }

    return Column(
      children: List<Widget>.generate(sections.length, (index) {
        final section = sections[index];
        return Padding(
          padding: EdgeInsets.only(
            bottom: index == sections.length - 1 ? 0 : 12,
          ),
          child: _buildTodoPlanSection(focus, section, i18n),
        );
      }),
    );
  }

  Widget _buildTodoPlanSection(
    FocusService focus,
    _TodoPlanSection section,
    AppI18n i18n,
  ) {
    final theme = Theme.of(context);
    final tint = section.highlight
        ? theme.colorScheme.error
        : theme.colorScheme.primary;

    return Container(
      key: ValueKey<String>(section.key),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: section.highlight ? 0.08 : 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tint.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(section.icon, size: 18, color: tint),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  section.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${section.items.length}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: tint,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...List<Widget>.generate(section.items.length, (index) {
            final todo = section.items[index];
            return _buildTodoCard(
              focus: focus,
              todo: todo,
              i18n: i18n,
              index: index,
              showDragHandle: false,
            );
          }),
        ],
      ),
    );
  }

  int _compareTodosByPriority(TodoItem a, TodoItem b) {
    final completed = _compareTodoCompletion(a, b);
    if (completed != 0) return completed;
    final priority = b.priority.compareTo(a.priority);
    if (priority != 0) return priority;
    final category = _compareTodoCategory(a.category, b.category);
    if (category != 0) return category;
    return _compareTodoManualOrder(a, b);
  }

  int _compareTodosByCategory(TodoItem a, TodoItem b) {
    final completed = _compareTodoCompletion(a, b);
    if (completed != 0) return completed;
    final category = _compareTodoCategory(a.category, b.category);
    if (category != 0) return category;
    final priority = b.priority.compareTo(a.priority);
    if (priority != 0) return priority;
    return _compareTodoManualOrder(a, b);
  }

  int _todoLifecycleRank(TodoItem todo) {
    if (todo.completed) {
      return 2;
    }
    if (todo.isDeferred) {
      return 1;
    }
    return 0;
  }

  int _compareTodoCompletion(TodoItem a, TodoItem b) {
    final left = _todoLifecycleRank(a);
    final right = _todoLifecycleRank(b);
    return left.compareTo(right);
  }

  int _compareTodoCategory(String? left, String? right) {
    final a = (left ?? '').trim().toLowerCase();
    final b = (right ?? '').trim().toLowerCase();
    if (a.isEmpty && b.isEmpty) return 0;
    if (a.isEmpty) return 1;
    if (b.isEmpty) return -1;
    return a.compareTo(b);
  }

  int _compareTodoManualOrder(TodoItem a, TodoItem b) {
    final sort = a.sortOrder.compareTo(b.sortOrder);
    if (sort != 0) return sort;
    final created = (b.createdAt?.millisecondsSinceEpoch ?? 0).compareTo(
      a.createdAt?.millisecondsSinceEpoch ?? 0,
    );
    if (created != 0) return created;
    return (a.id ?? 0).compareTo(b.id ?? 0);
  }

  Widget _buildReorderableTodosList(
    FocusService focus,
    List<TodoItem> todos,
    AppI18n i18n, {
    bool scrollable = false,
  }) {
    return ReorderableListView.builder(
      physics: scrollable
          ? const BouncingScrollPhysics()
          : const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      shrinkWrap: !scrollable,
      buildDefaultDragHandles: false,
      itemCount: todos.length,
      onReorder: (oldIndex, newIndex) {
        final ordered = List<TodoItem>.from(todos);
        if (newIndex > oldIndex) {
          newIndex -= 1;
        }
        final item = ordered.removeAt(oldIndex);
        ordered.insert(newIndex, item);
        focus.reorderTodos(ordered);
      },
      itemBuilder: (context, index) {
        final todo = todos[index];
        return _buildTodoCard(
          focus: focus,
          todo: todo,
          i18n: i18n,
          index: index,
          showDragHandle: true,
        );
      },
    );
  }

  Widget _buildSortedTodosList(
    FocusService focus,
    List<TodoItem> todos,
    AppI18n i18n, {
    bool scrollable = false,
  }) {
    return ListView.builder(
      physics: scrollable
          ? const BouncingScrollPhysics()
          : const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      shrinkWrap: !scrollable,
      itemCount: todos.length,
      itemBuilder: (context, index) {
        final todo = todos[index];
        return _buildTodoCard(
          focus: focus,
          todo: todo,
          i18n: i18n,
          index: index,
          showDragHandle: false,
        );
      },
    );
  }

  Widget _buildTodoCard({
    required FocusService focus,
    required TodoItem todo,
    required AppI18n i18n,
    required int index,
    required bool showDragHandle,
  }) {
    final theme = Theme.of(context);
    final accent = _todoAccentColor(theme, todo);
    final category = (todo.category ?? '').trim();
    final scheduleBadge = _buildTodoScheduleBadge(todo, i18n, theme);
    final compactCard = MediaQuery.sizeOf(context).width < 430;
    final todoId = todo.id;
    final cardKey = todoId == null ? null : _pageController.todoCardKey(todoId);
    final highlighted =
        todoId != null && _pageController.highlightedTodoId == todoId;

    return Card(
      key: cardKey ?? ValueKey<int>(todo.id ?? index),
      margin: const EdgeInsets.only(bottom: 4),
      color: highlighted
          ? Color.alphaBlend(
              theme.colorScheme.primary.withValues(alpha: 0.14),
              _todoCardColor(todo, theme),
            )
          : _todoCardColor(todo, theme),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: highlighted ? theme.colorScheme.primary : Colors.transparent,
          width: highlighted ? 1.6 : 0,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showTodoEditor(focus, i18n, todo: todo),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 4, 2, 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 5,
                height: compactCard ? 40 : 44,
                decoration: BoxDecoration(
                  color: accent.withValues(
                    alpha: todo.completed ? 0.55 : (todo.isDeferred ? 0.78 : 1),
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 6),
              Checkbox(
                value: todo.completed,
                visualDensity: const VisualDensity(
                  horizontal: -4,
                  vertical: -4,
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onChanged: todo.id == null
                    ? null
                    : (_) => focus.toggleTodo(todo.id!),
              ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        _buildTodoPriorityBadge(
                          todo,
                          i18n,
                          theme,
                          compact: compactCard,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            todo.content,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              decoration: todo.completed
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: todo.completed
                                  ? theme.colorScheme.onSurfaceVariant
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: <Widget>[
                        _buildTodoStatusBadge(todo, i18n, theme),
                        if (category.isNotEmpty)
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: compactCard ? 102 : 126,
                            ),
                            child: _buildTodoCategoryBadge(category, theme),
                          ),
                        if (scheduleBadge != null)
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: compactCard ? 128 : 152,
                            ),
                            child: scheduleBadge,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  IconButton(
                    tooltip: i18n.t('delete'),
                    visualDensity: const VisualDensity(
                      horizontal: -4,
                      vertical: -4,
                    ),
                    constraints: BoxConstraints.tightFor(
                      width: compactCard ? 28 : 30,
                      height: compactCard ? 28 : 30,
                    ),
                    onPressed: todo.id == null
                        ? null
                        : () => focus.deleteTodo(todo.id!),
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                  if (showDragHandle)
                    ReorderableDelayedDragStartListener(
                      index: index,
                      child: Padding(
                        padding: EdgeInsets.all(compactCard ? 4 : 6),
                        child: Icon(
                          Icons.drag_handle_rounded,
                          size: compactCard ? 18 : 20,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodoPriorityBadge(
    TodoItem todo,
    AppI18n i18n,
    ThemeData theme, {
    bool compact = false,
  }) {
    final color = _todoPriorityColor(theme, todo.priority);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 10,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: todo.completed ? 0.20 : 0.92),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _todoPriorityLabel(i18n, todo.priority),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style:
            (compact ? theme.textTheme.labelSmall : theme.textTheme.labelMedium)
                ?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.1,
                ),
      ),
    );
  }

  Widget _buildTodoCategoryBadge(String label, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: theme.colorScheme.secondary.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.label_outline_rounded,
            size: 11,
            color: theme.colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildTodoScheduleBadge(
    TodoItem todo,
    AppI18n i18n,
    ThemeData theme,
  ) {
    final dueAt = todo.dueAt;
    if (dueAt == null) {
      return null;
    }

    final now = DateTime.now();
    final todayStart = _startOfDay(now);
    final tomorrowStart = todayStart.add(const Duration(days: 1));
    final text = dueAt.isBefore(todayStart)
        ? pickUiText(
            i18n,
            zh: '已逾期',
            en: 'Overdue',
            ja: '期限超過',
            de: 'Ueberfaellig',
            fr: 'En retard',
            es: 'Vencida',
            ru: 'Просрочено',
          )
        : dueAt.isBefore(tomorrowStart)
        ? pickUiText(
            i18n,
            zh: '今天 ${_formatTodoTime(dueAt)}',
            en: 'Today ${_formatTodoTime(dueAt)}',
            ja: '今日 ${_formatTodoTime(dueAt)}',
            de: 'Heute ${_formatTodoTime(dueAt)}',
            fr: 'Aujourd’hui ${_formatTodoTime(dueAt)}',
            es: 'Hoy ${_formatTodoTime(dueAt)}',
            ru: 'Сегодня ${_formatTodoTime(dueAt)}',
          )
        : _isSameDay(dueAt, tomorrowStart)
        ? pickUiText(
            i18n,
            zh: '明天 ${_formatTodoTime(dueAt)}',
            en: 'Tomorrow ${_formatTodoTime(dueAt)}',
            ja: '明日 ${_formatTodoTime(dueAt)}',
            de: 'Morgen ${_formatTodoTime(dueAt)}',
            fr: 'Demain ${_formatTodoTime(dueAt)}',
            es: 'Manana ${_formatTodoTime(dueAt)}',
            ru: 'Завтра ${_formatTodoTime(dueAt)}',
          )
        : _formatTodoDateTime(dueAt);
    final color = dueAt.isBefore(todayStart)
        ? theme.colorScheme.error
        : theme.colorScheme.tertiary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: todo.completed ? 0.10 : 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
