import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/toolbox_daily_choice/daily_choice_seed_data.dart';

void main() {
  test('go seed exposes publish-scale place coverage', () {
    final goOptions = buildDailyChoiceStaticSeedOptions()
        .where((item) => item.moduleId == 'go')
        .toList(growable: false);

    expect(goOptions.length, inInclusiveRange(300, 500));

    for (final distance in placeCategories) {
      final optionsInDistance = goOptions
          .where((item) => item.categoryId == distance.id)
          .toList(growable: false);
      expect(optionsInDistance.length, greaterThanOrEqualTo(100));
    }

    for (final scene in placeSceneCategories) {
      final optionsInScene = goOptions
          .where(
            (item) =>
                item.contextId == scene.id ||
                item.contextIds.contains(scene.id),
          )
          .toList(growable: false);
      expect(optionsInScene.length, greaterThanOrEqualTo(24));
    }

    expect(goOptions.any((item) => item.titleZh.contains('公园')), isTrue);
    expect(goOptions.any((item) => item.titleZh.contains('体育中心')), isTrue);
    expect(goOptions.any((item) => item.titleZh.contains('精酿吧')), isTrue);
    expect(goOptions.any((item) => item.titleZh.contains('电竞馆 / 网吧')), isTrue);
    expect(goOptions.any((item) => item.titleZh.contains('综合博物馆')), isTrue);
    expect(goOptions.any((item) => item.titleZh.contains('公共图书馆')), isTrue);
    expect(goOptions.any((item) => item.titleZh.contains('纪念馆')), isTrue);
    expect(goOptions.any((item) => item.titleZh.contains('创意园区')), isTrue);
  });

  test('go seed keeps map-query and notes ready for detail view', () {
    final sample = buildDailyChoiceStaticSeedOptions().firstWhere(
      (item) => item.moduleId == 'go',
    );

    expect(sample.materialsZh.any((item) => item.startsWith('地图搜索词：')), isTrue);
    expect(sample.stepsZh, hasLength(3));
    expect(sample.notesZh.length, greaterThanOrEqualTo(3));
    expect(sample.contextId, isNotNull);
    expect(sample.contextIds, contains(sample.contextId));

    final visibleText = <String>[
      sample.detailsZh,
      sample.detailsEn,
      ...sample.notesZh,
      ...sample.notesEn,
    ].join('\n');
    for (final forbidden in <String>[
      '当前版本',
      '后续',
      '扩展边界',
      'Expansion path',
      'This version',
    ]) {
      expect(visibleText, isNot(contains(forbidden)));
    }
  });
}
