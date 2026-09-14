import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/toolbox_daily_choice/daily_choice_cook_service.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/toolbox_daily_choice/daily_choice_recipe_library.dart';

void main() {
  test('bundled recipe library asset loads into the standard schema', () async {
    final raw = await rootBundle.loadString(
      'assets/toolbox/daily_choice/recipe_library.json',
    );
    final document = DailyChoiceRecipeLibraryDocument.fromJson(
      jsonDecode(raw) as Map<String, Object?>,
    );
    expect(document.libraryId, 'toolbox_daily_choice_recipe_library');
    expect(document.recipes, isNotEmpty);

    final bundled = await DailyChoiceCookService().loadBundled();
    expect(bundled, isNotNull);
    expect(bundled!.options, isNotEmpty);
  });

  test('recipe library JSON loads into standard schema', () {
    final json = {
      'libraryId': 'toolbox_daily_choice_recipe_library',
      'libraryVersion': '2026-04-29',
      'schemaId': 'vocabulary_sleep.daily_choice.recipe_library',
      'schemaVersion': 1,
      'version': '2026-04-29',
      'generatedAt': '2026-09-14T13:23:07.082930+00:00',
      'referenceTitles': const <String>[],
      'stats': <String, Object?>{'dedupedRecipeCount': 7051},
      'recipes': const <Map<String, Object?>>[
        {
          'id': 'test_1',
          'moduleId': 'eat',
          'categoryId': 'lunch',
          'contextId': 'pot',
          'contextIds': const <String>['pot'],
          'titleZh': '番茄鸡蛋',
          'titleEn': '番茄鸡蛋',
          'subtitleZh': '家常快手',
          'subtitleEn': '家常快手',
          'detailsZh': '详细说明',
          'detailsEn': '详细说明',
          'materialsZh': const <String>['番茄', '鸡蛋'],
          'materialsEn': const <String>['番茄', '鸡蛋'],
          'stepsZh': const <String>['步骤 1'],
          'stepsEn': const <String>['步骤 1'],
          'notesZh': const <String>[],
          'notesEn': const <String>[],
          'tagsZh': const <String>[],
          'tagsEn': const <String>[],
          'attributes': const <String, List<String>>{},
          'custom': false,
        },
      ],
    };
    final document = DailyChoiceRecipeLibraryDocument.fromJson(json);
    expect(document.libraryId, 'toolbox_daily_choice_recipe_library');
    expect(document.libraryVersion, '2026-04-29');
    expect(document.recipes.single.titleZh, '番茄鸡蛋');
  });
}
