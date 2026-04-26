import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/toolbox_daily_choice/daily_choice_models.dart';

void main() {
  DailyChoiceOption customEatOption(String id) {
    return DailyChoiceOption(
      id: id,
      moduleId: DailyChoiceModuleId.eat.storageValue,
      categoryId: 'lunch',
      titleZh: '番茄鸡蛋',
      titleEn: 'Tomato egg',
      subtitleZh: '家常快手菜',
      subtitleEn: 'Quick home dish',
      detailsZh: '打散鸡蛋，炒番茄。',
      detailsEn: 'Cook tomato and egg.',
      custom: true,
    );
  }

  test('custom state persists eat recipe collections', () {
    final state = DailyChoiceCustomState(
      customOptions: <DailyChoiceOption>[customEatOption('custom_eat_1')],
      eatCollections: const <DailyChoiceEatCollection>[
        DailyChoiceEatCollection(
          id: 'set_weeknight',
          titleZh: '一周晚餐',
          titleEn: 'Weeknight dinners',
          optionIds: <String>['custom_eat_1', 'built_in_1', 'custom_eat_1'],
        ),
      ],
    );

    final restored = DailyChoiceCustomState.fromJson(state.toJson());

    expect(restored.eatCollections, hasLength(1));
    expect(restored.eatCollections.first.id, 'set_weeknight');
    expect(restored.eatCollections.first.optionIds, <String>[
      'custom_eat_1',
      'built_in_1',
    ]);
  });

  test('deleting a custom recipe removes it from recipe sets', () {
    final state = DailyChoiceCustomState(
      customOptions: <DailyChoiceOption>[customEatOption('custom_eat_1')],
      eatCollections: const <DailyChoiceEatCollection>[
        DailyChoiceEatCollection(
          id: 'set_weeknight',
          titleZh: '一周晚餐',
          titleEn: 'Weeknight dinners',
          optionIds: <String>['custom_eat_1', 'built_in_1'],
        ),
      ],
    );

    final next = state.deleteCustom('custom_eat_1');

    expect(next.customOptions, isEmpty);
    expect(next.eatCollections.first.optionIds, <String>['built_in_1']);
  });
}
