import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/toolbox_daily_choice/daily_choice_models.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/toolbox_daily_choice/daily_choice_seed_data.dart';

void main() {
  test(
    'wear guide and trait filters expose publish-ready wardrobe guidance',
    () {
      expect(wearGuideModules.length, greaterThanOrEqualTo(7));
      expect(
        wearGuideModules
            .map((module) => module.entries.length)
            .reduce((a, b) => a + b),
        greaterThanOrEqualTo(14),
      );

      expect(wearTraitGroups.length, greaterThanOrEqualTo(5));
      expect(
        wearManagerTraitGroups.map((item) => item.id).toList(growable: false),
        containsAll(<String>[
          'gender',
          'age',
          'style',
          'silhouette',
          'key_piece',
        ]),
      );
      expect(wearTraitGroupById('gender'), isNotNull);
      expect(wearTraitGroupById('age'), isNotNull);

      final guideText = wearGuideModules
          .expand(
            (module) => <String>[
              module.titleZh,
              module.titleEn,
              module.subtitleZh,
              module.subtitleEn,
              ...module.entries.expand(
                (entry) => <String>[
                  entry.titleZh,
                  entry.titleEn,
                  entry.bodyZh,
                  entry.bodyEn,
                ],
              ),
            ],
          )
          .join('\n');
      for (final forbidden in <String>[
        '扩展边界',
        '本轮',
        '后续',
        'Expansion',
        'Future work',
        '源自',
        '《',
      ]) {
        expect(guideText, isNot(contains(forbidden)));
      }
    },
  );

  test(
    'wear wardrobe state keeps built-ins protected and custom wardrobes editable',
    () {
      final state = DailyChoiceCustomState.empty.withDefaultWearCollections();

      expect(
        state.wearCollections.map((item) => item.id),
        containsAll(<String>[
          dailyChoiceFavoriteWearCollectionId,
          'wear_builtin_commute',
        ]),
      );
      expect(
        wearBuiltInCollections.map((item) => item.titleZh),
        containsAll(<String>['通勤', '日常', '正式', '约会', '运动', '雨天']),
      );
      expect(
        wearBuiltInCollections.any((item) => item.titleZh.endsWith('穿搭')),
        isFalse,
      );
      expect(isProtectedWearCollectionId('wear_builtin_commute'), isTrue);
      expect(
        state
            .deleteWearCollection('wear_builtin_commute')
            .wearCollectionById('wear_builtin_commute'),
        isNotNull,
      );

      final customCollection = const DailyChoiceWearCollection(
        id: 'wear_collection_trip',
        titleZh: '旅行衣橱',
        titleEn: 'Trip wardrobe',
      );
      final updated = state
          .upsertWearCollection(customCollection)
          .addOptionToWearCollection(
            collectionId: customCollection.id,
            optionId: 'outfit_trip_01',
          );

      expect(
        updated.wearCollectionById(customCollection.id)?.optionIds,
        contains('outfit_trip_01'),
      );
      expect(
        updated
            .deleteWearCollection(customCollection.id)
            .wearCollectionById(customCollection.id),
        isNull,
      );

      final staleBuiltInState = const DailyChoiceCustomState(
        wearCollections: <DailyChoiceWearCollection>[
          dailyChoiceFavoriteWearCollection,
          DailyChoiceWearCollection(
            id: 'wear_builtin_commute',
            titleZh: '通勤穿搭',
            titleEn: 'Commute outfits',
            optionIds: <String>['outfit_a', 'outfit_a'],
          ),
        ],
      ).withDefaultWearCollections();
      final normalizedBuiltIn = staleBuiltInState.wearCollectionById(
        'wear_builtin_commute',
      );
      expect(normalizedBuiltIn?.titleZh, '通勤');
      expect(normalizedBuiltIn?.titleEn, 'Commute');
      expect(normalizedBuiltIn?.optionIds, <String>['outfit_a']);

      final eatStateWithWearLikeId = const DailyChoiceCustomState(
        eatCollections: <DailyChoiceEatCollection>[
          DailyChoiceEatCollection(
            id: 'wear_builtin_commute',
            titleZh: '我的备餐',
            titleEn: 'Meal prep',
            optionIds: <String>['dish_a', 'dish_a'],
          ),
        ],
      ).withDefaultEatCollections();
      expect(
        eatStateWithWearLikeId
            .eatCollectionById('wear_builtin_commute')
            ?.titleZh,
        '我的备餐',
      );
      expect(
        eatStateWithWearLikeId
            .eatCollectionById('wear_builtin_commute')
            ?.optionIds,
        <String>['dish_a'],
      );
    },
  );
}
