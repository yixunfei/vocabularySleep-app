import 'daily_choice_eat_support.dart';
import 'daily_choice_models.dart';

class DailyChoiceEatCatalogFilterResult {
  const DailyChoiceEatCatalogFilterResult({
    required this.eligibleOptions,
    required this.randomPool,
    required this.ingredientPriority,
  });

  final List<DailyChoiceOption> eligibleOptions;
  final List<DailyChoiceOption> randomPool;
  final DailyChoiceEatIngredientPriorityResult ingredientPriority;
}

class DailyChoiceEatCatalog {
  DailyChoiceEatCatalog._({
    required List<DailyChoiceOption> options,
    required Map<String, int> optionIndexById,
    required Map<String, Set<int>> mealIndex,
    required Map<String, Set<int>> toolIndex,
    required Map<String, Map<String, Set<int>>> traitIndex,
    required Map<String, Set<int>> containsIndex,
    required Map<String, Set<int>> ingredientIndex,
  }) : _options = List<DailyChoiceOption>.unmodifiable(options),
       _optionIndexById = optionIndexById,
       _mealIndex = mealIndex,
       _toolIndex = toolIndex,
       _traitIndex = traitIndex,
       _containsIndex = containsIndex,
       _ingredientIndex = ingredientIndex;

  factory DailyChoiceEatCatalog.fromOptions(
    Iterable<DailyChoiceOption> options,
  ) {
    final normalizedOptions = options
        .map(
          (option) => isEatOptionAttributeReady(option)
              ? option
              : ensureEatOptionAttributes(option),
        )
        .toList(growable: false);
    final mealIndex = <String, Set<int>>{};
    final toolIndex = <String, Set<int>>{};
    final traitIndex = <String, Map<String, Set<int>>>{};
    final containsIndex = <String, Set<int>>{};
    final ingredientIndex = <String, Set<int>>{};
    final optionIndexById = <String, int>{};

    for (var index = 0; index < normalizedOptions.length; index += 1) {
      final option = normalizedOptions[index];
      optionIndexById[option.id] = index;

      for (final mealId in eatMealIds(option)) {
        _indexValue(mealIndex, mealId, index);
      }

      final toolIds = <String>{
        ...option.contextIds,
        if (option.contextId != null) option.contextId!,
        ...option.attributeValues(eatAttributeTool),
      };
      for (final toolId in toolIds) {
        _indexValue(toolIndex, toolId, index);
      }

      for (final groupId in <String>[
        eatAttributeType,
        eatAttributeProfile,
        eatAttributeDiet,
      ]) {
        final values = option.attributeValues(groupId);
        if (values.isEmpty) {
          continue;
        }
        final groupIndex = traitIndex[groupId] ?? <String, Set<int>>{};
        for (final value in values) {
          _indexValue(groupIndex, value, index);
        }
        traitIndex[groupId] = groupIndex;
      }

      for (final value in option.attributeValues(eatAttributeContains)) {
        _indexValue(containsIndex, value, index);
      }

      for (final value in eatIngredientKeywords(option)) {
        _indexValue(ingredientIndex, value, index);
      }
    }

    return DailyChoiceEatCatalog._(
      options: normalizedOptions,
      optionIndexById: optionIndexById,
      mealIndex: mealIndex,
      toolIndex: toolIndex,
      traitIndex: traitIndex,
      containsIndex: containsIndex,
      ingredientIndex: ingredientIndex,
    );
  }

  static final DailyChoiceEatCatalog empty = DailyChoiceEatCatalog.fromOptions(
    const <DailyChoiceOption>[],
  );

  final List<DailyChoiceOption> _options;
  final Map<String, int> _optionIndexById;
  final Map<String, Set<int>> _mealIndex;
  final Map<String, Set<int>> _toolIndex;
  final Map<String, Map<String, Set<int>>> _traitIndex;
  final Map<String, Set<int>> _containsIndex;
  final Map<String, Set<int>> _ingredientIndex;

  List<DailyChoiceOption> get options => _options;

  DailyChoiceEatCatalogFilterResult filter({
    required String mealId,
    required String toolId,
    required Map<String, Set<String>> selectedTraitFilters,
    required Set<String> excludedContains,
    Iterable<String> customExcludedIngredients = const <String>[],
    Iterable<String> availableIngredients = const <String>[],
    bool preferAvailableIngredients = false,
    Iterable<String>? allowedOptionIds,
  }) {
    var matched = mealId == 'all'
        ? Set<int>.of(Iterable<int>.generate(_options.length))
        : (_mealIndex[mealId] ?? const <int>{}).toSet();

    final allowed = _allowedIndices(allowedOptionIds);
    if (allowed != null) {
      matched = matched.intersection(allowed);
    }

    if (toolId != 'all') {
      matched = matched.intersection(_toolIndex[toolId] ?? const <int>{});
    }

    for (final entry in selectedTraitFilters.entries) {
      if (entry.value.isEmpty) {
        continue;
      }
      final groupIndex = _traitIndex[entry.key];
      if (groupIndex == null) {
        return const DailyChoiceEatCatalogFilterResult(
          eligibleOptions: <DailyChoiceOption>[],
          randomPool: <DailyChoiceOption>[],
          ingredientPriority: DailyChoiceEatIngredientPriorityResult.empty(),
        );
      }
      final union = <int>{};
      for (final optionId in entry.value) {
        union.addAll(groupIndex[optionId] ?? const <int>{});
      }
      matched = matched.intersection(union);
      if (matched.isEmpty) {
        break;
      }
    }

    if (matched.isNotEmpty && excludedContains.isNotEmpty) {
      final excluded = <int>{};
      for (final rawToken in excludedContains) {
        for (final token in eatContainsExpandedTokens(rawToken)) {
          excluded.addAll(_containsIndex[token] ?? const <int>{});
          excluded.addAll(_ingredientIndex[token] ?? const <int>{});
        }
      }
      matched.removeAll(excluded);
    }

    final normalizedCustomExcluded = normalizeEatIngredientInputs(
      customExcludedIngredients,
    ).toSet();
    if (matched.isNotEmpty && normalizedCustomExcluded.isNotEmpty) {
      final excluded = <int>{};
      for (final token in normalizedCustomExcluded) {
        excluded.addAll(_containsIndex[token] ?? const <int>{});
        excluded.addAll(_ingredientIndex[token] ?? const <int>{});
      }
      matched.removeAll(excluded);
    }

    final eligibleOptions = _optionsFromIndices(matched);
    final ingredientPriority = preferAvailableIngredients
        ? chooseIngredientPrioritizedEatOptions(
            eligibleOptions,
            availableIngredients,
          )
        : const DailyChoiceEatIngredientPriorityResult.empty();
    final randomPool =
        preferAvailableIngredients && ingredientPriority.hasMatchedCandidates
        ? ingredientPriority.options
        : eligibleOptions;

    return DailyChoiceEatCatalogFilterResult(
      eligibleOptions: eligibleOptions,
      randomPool: randomPool,
      ingredientPriority: ingredientPriority,
    );
  }

  Set<int>? _allowedIndices(Iterable<String>? optionIds) {
    if (optionIds == null) {
      return null;
    }
    final allowed = <int>{};
    for (final optionId in optionIds) {
      final index = _optionIndexById[optionId.trim()];
      if (index != null) {
        allowed.add(index);
      }
    }
    return allowed;
  }

  List<DailyChoiceOption> _optionsFromIndices(Set<int> indices) {
    if (indices.isEmpty) {
      return const <DailyChoiceOption>[];
    }
    final sortedIndices = indices.toList(growable: false)..sort();
    return List<DailyChoiceOption>.unmodifiable(
      sortedIndices.map((index) => _options[index]),
    );
  }
}

void _indexValue(Map<String, Set<int>> index, String key, int optionIndex) {
  final normalizedKey = key.trim();
  if (normalizedKey.isEmpty) {
    return;
  }
  final values = index[normalizedKey] ?? <int>{};
  values.add(optionIndex);
  index[normalizedKey] = values;
}
