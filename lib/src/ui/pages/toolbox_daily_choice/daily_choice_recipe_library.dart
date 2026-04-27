import 'daily_choice_models.dart';

class DailyChoiceRecipeLibraryDocument {
  const DailyChoiceRecipeLibraryDocument({
    required this.libraryId,
    required this.libraryVersion,
    required this.schemaId,
    required this.schemaVersion,
    required this.recipes,
    this.generatedAt,
    this.referenceTitles = const <String>[],
    this.stats = const <String, Object?>{},
  });

  static const String defaultLibraryId = 'toolbox_daily_choice_recipe_library';
  static const String defaultSchemaId =
      'vocabulary_sleep.daily_choice.recipe_library';
  static const int defaultSchemaVersion = 1;

  final String libraryId;
  final String libraryVersion;
  final String schemaId;
  final int schemaVersion;
  final DateTime? generatedAt;
  final List<String> referenceTitles;
  final Map<String, Object?> stats;
  final List<DailyChoiceOption> recipes;

  factory DailyChoiceRecipeLibraryDocument.fromJson(Map<String, Object?> json) {
    final rawRecipes = json['recipes'];
    final recipes = <DailyChoiceOption>[];
    if (rawRecipes is List) {
      for (final item in rawRecipes) {
        if (item is Map) {
          recipes.add(DailyChoiceOption.fromJson(item.cast<String, Object?>()));
        }
      }
    }

    return DailyChoiceRecipeLibraryDocument(
      libraryId: _stringValue(json['libraryId']).isEmpty
          ? defaultLibraryId
          : _stringValue(json['libraryId']),
      libraryVersion: _stringValue(json['libraryVersion']).isEmpty
          ? _stringValue(json['version'])
          : _stringValue(json['libraryVersion']),
      schemaId: _stringValue(json['schemaId']).isEmpty
          ? defaultSchemaId
          : _stringValue(json['schemaId']),
      schemaVersion: _intValue(json['schemaVersion']) ?? defaultSchemaVersion,
      generatedAt: _dateTimeValue(json['generatedAt']),
      referenceTitles: _stringList(json['referenceTitles']),
      stats: _mapValue(json['stats']),
      recipes: List<DailyChoiceOption>.unmodifiable(recipes),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'libraryId': libraryId,
      'libraryVersion': libraryVersion,
      'schemaId': schemaId,
      'schemaVersion': schemaVersion,
      // Keep the legacy field for backward compatibility with existing assets.
      'version': libraryVersion,
      'generatedAt': generatedAt?.toIso8601String(),
      'referenceTitles': referenceTitles.toList(growable: false),
      'stats': stats.map((key, value) => MapEntry(key, value)),
      'recipes': recipes.map((item) => item.toJson()).toList(growable: false),
    };
  }
}

String _stringValue(Object? value) => value == null ? '' : '$value'.trim();

int? _intValue(Object? value) {
  if (value is int) {
    return value;
  }
  return int.tryParse(_stringValue(value));
}

DateTime? _dateTimeValue(Object? value) {
  final raw = _stringValue(value);
  return raw.isEmpty ? null : DateTime.tryParse(raw);
}

List<String> _stringList(Object? value) {
  if (value is! List) {
    return const <String>[];
  }
  return value
      .map((item) => _stringValue(item))
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

Map<String, Object?> _mapValue(Object? value) {
  if (value is! Map) {
    return const <String, Object?>{};
  }
  return value.map((key, item) => MapEntry(_stringValue(key), item));
}
