import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/toolbox_daily_choice/daily_choice_seed_data.dart';

void main() {
  test('cooking guide is a general kitchen manual instead of app help', () {
    final modules = buildCookingGuideModules(const <String>[
      'YunYouJun/cook（recipe.csv / 做菜之前）',
      '测试资料',
    ]);
    final text = modules
        .expand(
          (module) => <String>[
            module.id,
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

    expect(text, contains('入厨前基准'));
    expect(text, contains('采购与验收'));
    expect(text, contains('清洗与去污'));
    expect(text, contains('刀工与切配'));
    expect(text, contains('火候与锅具'));
    expect(text, contains('翻车排查'));

    for (final forbidden in <String>[
      'recipe.csv',
      'SQLite',
      'S3',
      '安装',
      '远端',
      '数据源',
      '字段说明',
      '页面会',
      '当前版本',
      '参考与延伸阅读',
      'References',
    ]) {
      expect(text, isNot(contains(forbidden)));
    }
  });
}
