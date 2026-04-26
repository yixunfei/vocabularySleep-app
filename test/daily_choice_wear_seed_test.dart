import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/toolbox_daily_choice/daily_choice_seed_data.dart';

void main() {
  test('wear seed covers every temperature-scene pair with layered traits', () {
    final wearOptions = buildDailyChoiceStaticSeedOptions()
        .where((item) => item.moduleId == 'wear')
        .toList(growable: false);

    expect(wearOptions.length, greaterThanOrEqualTo(80));

    for (final temperature in temperatureCategories) {
      for (final scene in wearSceneCategories) {
        final matches = wearOptions
            .where(
              (item) =>
                  item.categoryId == temperature.id &&
                  item.contextId == scene.id,
            )
            .toList(growable: false);
        expect(
          matches.length,
          greaterThanOrEqualTo(2),
          reason:
              '${temperature.id}/${scene.id} should have at least 2 outfits',
        );
      }
    }

    for (final option in wearOptions) {
      expect(option.attributeValues('style'), isNotEmpty);
      expect(option.attributeValues('silhouette'), isNotEmpty);
      expect(option.attributeValues('key_piece'), isNotEmpty);
      expect(option.tagsZh.length, greaterThanOrEqualTo(4));
    }
  });

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
        containsAll(<String>['style', 'silhouette', 'key_piece']),
      );
    },
  );
}
