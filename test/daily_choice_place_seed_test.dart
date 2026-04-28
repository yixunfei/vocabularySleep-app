import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:vocabulary_sleep_app/src/services/cstcloud_s3_compat_client.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/toolbox_daily_choice/daily_choice_place_library_store.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/toolbox_daily_choice/daily_choice_seed_data.dart';

void main() {
  group('DailyChoicePlaceLibraryStatus', () {
    test('empty status has correct defaults', () {
      const status = DailyChoicePlaceLibraryStatus.empty();
      expect(status.hasInstalledLibrary, isFalse);
      expect(status.placeCount, 0);
      expect(status.referenceTitles, isEmpty);
      expect(status.libraryId, '');
      expect(status.libraryVersion, '');
      expect(status.schemaId, '');
      expect(status.schemaVersion, 0);
      expect(status.installedAt, isNull);
      expect(status.updatedAt, isNull);
      expect(status.errorMessage, isNull);
    });

    test('copyWith preserves values and overrides specified fields', () {
      const status = DailyChoicePlaceLibraryStatus(
        hasInstalledLibrary: true,
        placeCount: 360,
        libraryId: 'test',
        libraryVersion: '1.0.0',
      );
      final copied = status.copyWith(placeCount: 400);
      expect(copied.hasInstalledLibrary, isTrue);
      expect(copied.placeCount, 400);
      expect(copied.libraryId, 'test');
      expect(copied.libraryVersion, '1.0.0');
    });
  });

  group('DailyChoicePlaceLibraryStore basic operations', () {
    late Directory tempDir;
    late DailyChoicePlaceLibraryStore store;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('place_library_test_');
      store = DailyChoicePlaceLibraryStore(
        supportDirectoryProvider: () async => tempDir,
      );
    });

    tearDown(() async {
      await store.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('inspectStatus returns empty when no library installed', () async {
      final status = await store.inspectStatus();
      expect(status.hasInstalledLibrary, isFalse);
      expect(status.placeCount, 0);
    });

    test(
      'loadBuiltInSummaries returns empty when no library installed',
      () async {
        final summaries = await store.loadBuiltInSummaries();
        expect(summaries, isEmpty);
      },
    );

    test('loadBuiltInDetail returns null when no library installed', () async {
      final detail = await store.loadBuiltInDetail('any_id');
      expect(detail, isNull);
    });

    test(
      'queryBuiltInSummaries returns empty when no library installed',
      () async {
        final results = await store.queryBuiltInSummaries();
        expect(results, isEmpty);
      },
    );

    test('installLibrary imports JSON into SQLite and reads details', () async {
      final sourceFile = File(
        p.join(tempDir.path, 'place_library_source.json'),
      );
      await sourceFile.writeAsString(jsonEncode(_samplePlaceLibrary()));
      await store.close();
      store = DailyChoicePlaceLibraryStore(
        supportDirectoryProvider: () async => tempDir,
        s3Client: _LocalPlaceLibraryClient(sourceFile),
      );

      final status = await store.installLibrary();
      expect(status.hasInstalledLibrary, isTrue);
      expect(status.placeCount, 2);
      expect(status.libraryId, 'toolbox_daily_choice_place_library');
      expect(status.schemaVersion, 1);

      final summaries = await store.loadBuiltInSummaries();
      expect(summaries, hasLength(2));
      expect(summaries.first.id, 'go_outside_food_park');
      expect(summaries.first.moduleId, 'go');
      expect(summaries.first.contextIds, contains('nature'));
      expect(summaries.first.materialsZh, contains('地图搜索词：公园'));

      final filtered = await store.queryBuiltInSummaries(
        categoryId: 'outside',
        contextId: 'food',
      );
      expect(filtered, hasLength(1));
      expect(filtered.single.id, 'go_outside_food_park');

      final detail = await store.loadBuiltInDetail('go_nearby_study_library');
      expect(detail, isNotNull);
      expect(detail!.stepsZh, hasLength(3));
      expect(detail.references, isEmpty);
      expect(detail.sourceLabel, isNull);
      expect(detail.attributes['map_query_zh'], <String>['图书馆']);
    });
  });

  test('place categories and scene categories remain stable', () {
    expect(placeCategories.length, 3);
    expect(placeCategories.map((c) => c.id).toList(), <String>[
      'outside',
      'nearby',
      'travel',
    ]);
    expect(placeSceneCategories.length, 15);
    expect(allPlaceSceneCategory.id, 'all');
  });

  test('static seed no longer contains go module hard-coded options', () {
    final goOptions = buildDailyChoiceStaticSeedOptions()
        .where((item) => item.moduleId == 'go')
        .toList(growable: false);
    expect(goOptions, isEmpty);
  });
}

Map<String, Object?> _samplePlaceLibrary() {
  return <String, Object?>{
    'libraryId': 'toolbox_daily_choice_place_library',
    'libraryVersion': '2026-04-28-test',
    'schemaId': 'vocabulary_sleep.daily_choice.place_library',
    'schemaVersion': 1,
    'referenceTitles': <String>[],
    'options': <Map<String, Object?>>[
      _samplePlaceOption(
        id: 'go_outside_food_park',
        categoryId: 'outside',
        contextId: 'food',
        contextIds: <String>['food', 'nature'],
        titleZh: '附近公园',
        titleEn: 'Nearby park',
        subtitleZh: '适合散步和放松',
        subtitleEn: 'Good for a walk and relaxation',
        detailsZh: '公园详情',
        detailsEn: 'Park details',
        mapQueryZh: '公园',
        mapQueryEn: 'park',
      ),
      _samplePlaceOption(
        id: 'go_nearby_study_library',
        categoryId: 'nearby',
        contextId: 'study',
        contextIds: <String>['study', 'culture'],
        titleZh: '同城图书馆',
        titleEn: 'In-town library',
        subtitleZh: '适合安静学习',
        subtitleEn: 'Good for quiet study',
        detailsZh: '图书馆详情',
        detailsEn: 'Library details',
        mapQueryZh: '图书馆',
        mapQueryEn: 'library',
      ),
    ],
  };
}

Map<String, Object?> _samplePlaceOption({
  required String id,
  required String categoryId,
  required String contextId,
  required List<String> contextIds,
  required String titleZh,
  required String titleEn,
  required String subtitleZh,
  required String subtitleEn,
  required String detailsZh,
  required String detailsEn,
  required String mapQueryZh,
  required String mapQueryEn,
}) {
  return <String, Object?>{
    'id': id,
    'categoryId': categoryId,
    'contextId': contextId,
    'contextIds': contextIds,
    'titleZh': titleZh,
    'titleEn': titleEn,
    'subtitleZh': subtitleZh,
    'subtitleEn': subtitleEn,
    'detailsZh': detailsZh,
    'detailsEn': detailsEn,
    'materialsZh': <String>['建议时长：30 分钟', '地图搜索词：$mapQueryZh'],
    'materialsEn': <String>[
      'Suggested duration: 30 minutes',
      'Map query: $mapQueryEn',
    ],
    'stepsZh': <String>['确认时间', '搜索候选', '准备替代点'],
    'stepsEn': <String>['Confirm time', 'Search candidates', 'Prepare backup'],
    'notesZh': <String>['天气提醒'],
    'notesEn': <String>['Weather note'],
    'tagsZh': <String>['导入测试'],
    'tagsEn': <String>['Import test'],
    'sourceLabel': null,
    'sourceUrl': null,
    'references': <Map<String, String>>[],
    'attributes': <String, List<String>>{
      'map_query_zh': <String>[mapQueryZh],
      'map_query_en': <String>[mapQueryEn],
    },
    'custom': false,
  };
}

class _LocalPlaceLibraryClient extends CstCloudS3CompatClient {
  _LocalPlaceLibraryClient(this.sourceFile);

  final File sourceFile;

  @override
  Future<File> downloadObjectToFile(
    String objectKey,
    File targetFile, {
    void Function(int receivedBytes, int totalBytes)? onProgress,
  }) async {
    await targetFile.parent.create(recursive: true);
    final copied = await sourceFile.copy(targetFile.path);
    onProgress?.call(await copied.length(), await copied.length());
    return copied;
  }

  @override
  Future<void> close() async {}
}
