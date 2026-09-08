part of '../toolbox_life_tools.dart';

class _CalculatorCatalogSheet extends StatefulWidget {
  const _CalculatorCatalogSheet();

  @override
  State<_CalculatorCatalogSheet> createState() =>
      _CalculatorCatalogSheetState();
}

class _CalculatorCatalogSheetState extends State<_CalculatorCatalogSheet> {
  final TextEditingController _searchController = TextEditingController();
  _CalculatorCatalogCategory? _category;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_refreshSearch);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_refreshSearch)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = _filteredEntries(context);
    return Material(
      color: theme.colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Column(
          children: <Widget>[
            const SizedBox(height: 8),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            _buildHeader(context),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                children: <Widget>[
                  _buildSearchField(context),
                  const SizedBox(height: 10),
                  _buildCategoryMenu(context),
                ],
              ),
            ),
            Divider(height: 1, color: theme.colorScheme.outlineVariant),
            Expanded(
              child: entries.isEmpty
                  ? const _CalculatorCatalogEmpty()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
                      itemCount: entries.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 6),
                      itemBuilder: (context, index) =>
                          _CalculatorCatalogTile(entry: entries[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              _lifeI18nText(
                context,
                'toolbox.life.advanced_calculator.catalog.title',
              ),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
          IconButton(
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return TextField(
      key: const ValueKey<String>('advanced_calculator_catalog_search'),
      controller: _searchController,
      autofocus: true,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search_rounded),
        hintText: _lifeI18nText(
          context,
          'toolbox.life.advanced_calculator.catalog.search_hint',
        ),
        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(
                tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
                onPressed: _searchController.clear,
                icon: const Icon(Icons.clear_rounded),
              ),
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildCategoryMenu(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: _lifeI18nText(
          context,
          'toolbox.life.advanced_calculator.catalog.filter',
        ),
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<_CalculatorCatalogCategory?>(
          key: const ValueKey<String>('advanced_calculator_catalog_category'),
          value: _category,
          isExpanded: true,
          hint: Text(
            _lifeI18nText(
              context,
              'toolbox.life.advanced_calculator.catalog.category.all',
            ),
          ),
          items: <DropdownMenuItem<_CalculatorCatalogCategory?>>[
            DropdownMenuItem<_CalculatorCatalogCategory?>(
              value: null,
              child: Text(
                _lifeI18nText(
                  context,
                  'toolbox.life.advanced_calculator.catalog.category.all',
                ),
              ),
            ),
            ..._CalculatorCatalogCategory.values.map(
              (category) => DropdownMenuItem<_CalculatorCatalogCategory?>(
                value: category,
                child: Text(
                  _lifeI18nText(
                    context,
                    _calculatorCatalogCategoryKey(category),
                  ),
                ),
              ),
            ),
          ],
          onChanged: (value) => setState(() => _category = value),
        ),
      ),
    );
  }

  List<_CalculatorCatalogEntry> _filteredEntries(BuildContext context) {
    final query = _searchController.text;
    return _calculatorCatalogEntries
        .where((entry) {
          if (_category != null && entry.category != _category) return false;
          final category = _lifeI18nText(
            context,
            _calculatorCatalogCategoryKey(entry.category),
          );
          return entry.matches(query, category);
        })
        .toList(growable: false);
  }

  void _refreshSearch() => setState(() {});
}

class _CalculatorCatalogTile extends StatelessWidget {
  const _CalculatorCatalogTile({required this.entry});

  final _CalculatorCatalogEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final opensTool = entry.insertion == null;
    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.pop(context, entry),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: <Widget>[
                Icon(
                  _catalogCategoryIcon(entry.category),
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        entry.signature,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        _lifeI18nText(
                          context,
                          _calculatorCatalogCategoryKey(entry.category),
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Tooltip(
                  message: _lifeI18nText(
                    context,
                    opensTool
                        ? 'toolbox.life.advanced_calculator.catalog.open_tool'
                        : 'toolbox.life.advanced_calculator.catalog.insert',
                  ),
                  child: Icon(
                    opensTool
                        ? Icons.open_in_new_rounded
                        : Icons.add_circle_outline_rounded,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CalculatorCatalogEmpty extends StatelessWidget {
  const _CalculatorCatalogEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          _lifeI18nText(
            context,
            'toolbox.life.advanced_calculator.catalog.empty',
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

IconData _catalogCategoryIcon(_CalculatorCatalogCategory category) {
  return switch (category) {
    _CalculatorCatalogCategory.symbols => Icons.data_object_rounded,
    _CalculatorCatalogCategory.algebra => Icons.functions_rounded,
    _CalculatorCatalogCategory.trigonometry => Icons.change_history_rounded,
    _CalculatorCatalogCategory.hyperbolic => Icons.show_chart_rounded,
    _CalculatorCatalogCategory.complex => Icons.blur_circular_rounded,
    _CalculatorCatalogCategory.numberTheory => Icons.numbers_rounded,
    _CalculatorCatalogCategory.calculus => Icons.area_chart_rounded,
    _CalculatorCatalogCategory.linearAlgebra => Icons.grid_on_rounded,
    _CalculatorCatalogCategory.probability => Icons.casino_outlined,
  };
}

extension _CalculatorCatalogActions on _AdvancedCalculatorToolPageState {
  Future<void> _openCatalogSheet() async {
    final entry = await showModalBottomSheet<_CalculatorCatalogEntry>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => const FractionallySizedBox(
        heightFactor: 0.94,
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          child: _CalculatorCatalogSheet(),
        ),
      ),
    );
    if (!mounted || entry == null) return;
    final insertion = entry.insertion;
    if (insertion != null) {
      _insertText(insertion, cursorBack: entry.cursorBack);
      return;
    }
    _openToolSheet(
      category: entry.toolCategory,
      operation: entry.toolOperation,
    );
  }
}
