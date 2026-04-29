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

  DailyChoiceOption customActivityOption(String id) {
    return DailyChoiceOption(
      id: id,
      moduleId: DailyChoiceModuleId.activity.storageValue,
      categoryId: 'focus',
      titleZh: '无评价复盘走神',
      titleEn: 'Non-judgment drift review',
      subtitleZh: '把注意力带回当前目标',
      subtitleEn: 'Return attention to the current goal',
      detailsZh: '记录刚才想到了什么、为什么偏离，以及下一步目标。',
      detailsEn: 'Record the drift content, reason, and next goal.',
      materialsZh: const <String>['计时器 3 分钟', '纸笔或备忘录'],
      materialsEn: const <String>['3-minute timer', 'Notebook or memo'],
      stepsZh: const <String>['写下涣散内容', '标记触发原因', '重述当前目标'],
      stepsEn: const <String>[
        'Write down the drift',
        'Name the trigger',
        'Restate the current goal',
      ],
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

    expect(restored.eatCollections, hasLength(2));
    expect(
      restored.eatCollections.first.id,
      dailyChoiceFavoriteEatCollectionId,
    );
    expect(restored.eatCollections.last.id, 'set_weeknight');
    expect(restored.eatCollections.last.optionIds, <String>[
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

  test('favorite recipe collection is restored and protected', () {
    final restored = DailyChoiceCustomState.fromJson(const <String, Object?>{});

    expect(
      restored.eatCollections.single.id,
      dailyChoiceFavoriteEatCollectionId,
    );
    expect(
      restored.deleteEatCollection(dailyChoiceFavoriteEatCollectionId),
      same(restored),
    );
  });

  test('setting recipe collections rewrites membership exactly', () {
    final state = DailyChoiceCustomState(
      customOptions: <DailyChoiceOption>[customEatOption('custom_eat_1')],
      eatCollections: const <DailyChoiceEatCollection>[
        DailyChoiceEatCollection(
          id: 'set_a',
          titleZh: '清淡',
          titleEn: 'Light',
          optionIds: <String>['custom_eat_1'],
        ),
        DailyChoiceEatCollection(
          id: 'set_b',
          titleZh: '下饭',
          titleEn: 'Rice-friendly',
        ),
      ],
    );

    final next = state.setOptionEatCollections(
      optionId: 'custom_eat_1',
      collectionIds: <String>{'set_b'},
    );

    expect(next.eatCollectionById('set_a')?.optionIds, isEmpty);
    expect(next.eatCollectionById('set_b')?.optionIds, <String>[
      'custom_eat_1',
    ]);
  });

  test('custom state persists activity collections', () {
    final state = DailyChoiceCustomState(
      customOptions: <DailyChoiceOption>[
        customActivityOption('custom_activity_1'),
      ],
      activityCollections: const <DailyChoiceActivityCollection>[
        DailyChoiceActivityCollection(
          id: 'set_low_energy',
          titleZh: '低能量行动',
          titleEn: 'Low-energy actions',
          optionIds: <String>[
            'custom_activity_1',
            'library_focus_review',
            'custom_activity_1',
          ],
        ),
      ],
    );

    final restored = DailyChoiceCustomState.fromJson(state.toJson());

    expect(restored.activityCollections, hasLength(2));
    expect(
      restored.activityCollections.first.id,
      dailyChoiceFavoriteActivityCollectionId,
    );
    expect(restored.activityCollections.last.id, 'set_low_energy');
    expect(restored.activityCollections.last.optionIds, <String>[
      'custom_activity_1',
      'library_focus_review',
    ]);
  });

  test('deleting a custom activity removes it from activity sets', () {
    final state = DailyChoiceCustomState(
      customOptions: <DailyChoiceOption>[
        customActivityOption('custom_activity_1'),
      ],
      activityCollections: const <DailyChoiceActivityCollection>[
        DailyChoiceActivityCollection(
          id: 'set_focus',
          titleZh: '专注恢复',
          titleEn: 'Focus recovery',
          optionIds: <String>['custom_activity_1', 'library_walk'],
        ),
      ],
    );

    final next = state.deleteCustom('custom_activity_1');

    expect(next.customOptions, isEmpty);
    expect(next.activityCollections.first.optionIds, <String>['library_walk']);
  });

  test('favorite activity collection is restored and protected', () {
    final restored = DailyChoiceCustomState.fromJson(const <String, Object?>{});

    expect(
      restored.activityCollections.single.id,
      dailyChoiceFavoriteActivityCollectionId,
    );
    expect(
      restored.deleteActivityCollection(
        dailyChoiceFavoriteActivityCollectionId,
      ),
      same(restored),
    );
  });

  test('setting activity collections rewrites membership exactly', () {
    final state = DailyChoiceCustomState(
      customOptions: <DailyChoiceOption>[
        customActivityOption('custom_activity_1'),
      ],
      activityCollections: const <DailyChoiceActivityCollection>[
        DailyChoiceActivityCollection(
          id: 'set_focus',
          titleZh: '专注恢复',
          titleEn: 'Focus recovery',
          optionIds: <String>['custom_activity_1'],
        ),
        DailyChoiceActivityCollection(
          id: 'set_outdoor',
          titleZh: '出门透气',
          titleEn: 'Outdoor reset',
        ),
      ],
    );

    final next = state.setOptionActivityCollections(
      optionId: 'custom_activity_1',
      collectionIds: <String>{'set_outdoor'},
    );

    expect(next.activityCollectionById('set_focus')?.optionIds, isEmpty);
    expect(next.activityCollectionById('set_outdoor')?.optionIds, <String>[
      'custom_activity_1',
    ]);
  });
}
