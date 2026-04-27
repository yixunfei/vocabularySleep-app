import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/toolbox_daily_choice/daily_choice_models.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/toolbox_daily_choice/daily_choice_recipe_library.dart';

void main() {
  test(
    'recipe library document normalizes legacy payloads into standard schema',
    () {
      final option = DailyChoiceOption(
        id: 'recipe_1',
        moduleId: DailyChoiceModuleId.eat.storageValue,
        categoryId: 'lunch',
        contextId: 'pot',
        contextIds: const <String>['pot'],
        titleZh: '番茄鸡蛋',
        titleEn: 'Tomato Egg',
        subtitleZh: '家常快手',
        subtitleEn: 'Home style',
        detailsZh: '详细说明',
        detailsEn: 'Details',
        materialsZh: const <String>['番茄', '鸡蛋'],
        materialsEn: const <String>['Tomato', 'Egg'],
        stepsZh: const <String>['步骤 1'],
        stepsEn: const <String>['Step 1'],
      );

      final document = DailyChoiceRecipeLibraryDocument.fromJson(
        <String, Object?>{
          'version': '2026-04-25',
          'generatedAt': '2026-04-25T04:56:50.840094+00:00',
          'referenceTitles': const <String>['资料 A'],
          'stats': const <String, Object?>{'dedupedRecipeCount': 1},
          'recipes': <Map<String, Object?>>[option.toJson()],
        },
      );

      expect(
        document.libraryId,
        DailyChoiceRecipeLibraryDocument.defaultLibraryId,
      );
      expect(document.libraryVersion, '2026-04-25');
      expect(
        document.schemaId,
        DailyChoiceRecipeLibraryDocument.defaultSchemaId,
      );
      expect(
        document.schemaVersion,
        DailyChoiceRecipeLibraryDocument.defaultSchemaVersion,
      );
      expect(document.recipes.single.titleZh, '番茄鸡蛋');

      final exported = document.toJson();
      expect(
        exported['libraryId'],
        DailyChoiceRecipeLibraryDocument.defaultLibraryId,
      );
      expect(exported['libraryVersion'], '2026-04-25');
      expect(exported['schemaVersion'], 1);
      expect(exported['version'], '2026-04-25');
      expect((exported['recipes'] as List<Object?>), hasLength(1));
    },
  );
}
