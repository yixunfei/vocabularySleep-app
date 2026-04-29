import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:vocabulary_sleep_app/src/services/cstcloud_s3_compat_client.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/toolbox_daily_choice/daily_choice_activity_library_store.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/toolbox_daily_choice/daily_choice_models.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/toolbox_daily_choice/daily_choice_seed_data.dart';

void main() {
  group('DailyChoiceActivityLibraryStatus', () {
    test('empty status has correct defaults', () {
      const status = DailyChoiceActivityLibraryStatus.empty();
      expect(status.hasInstalledLibrary, isFalse);
      expect(status.actionCount, 0);
      expect(status.referenceTitles, isEmpty);
      expect(status.libraryId, '');
      expect(status.libraryVersion, '');
      expect(status.schemaId, '');
      expect(status.schemaVersion, 0);
      expect(status.installedAt, isNull);
      expect(status.updatedAt, isNull);
      expect(status.errorMessage, isNull);
    });
  });

  group('DailyChoiceActivityLibraryStore', () {
    late Directory tempDir;
    late DailyChoiceActivityLibraryStore store;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('activity_library_test_');
      store = DailyChoiceActivityLibraryStore(
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
      expect(status.actionCount, 0);
    });

    test('installLibrary imports JSON into SQLite and reads actions', () async {
      final sourceFile = File(
        p.join(tempDir.path, 'activity_library_source.json'),
      );
      await sourceFile.writeAsString(jsonEncode(_sampleActivityLibrary()));
      await store.close();
      final client = _LocalActivityLibraryClient(sourceFile);
      store = DailyChoiceActivityLibraryStore(
        supportDirectoryProvider: () async => tempDir,
        s3Client: client,
      );

      final status = await store.installLibrary();
      expect(status.hasInstalledLibrary, isTrue);
      expect(status.actionCount, 2);
      expect(status.libraryId, 'toolbox_daily_choice_activity_library');
      expect(status.schemaVersion, 1);
      expect(status.referenceTitles, contains('测试行动库'));
      expect(status.errorMessage, isNull);
      expect(
        client.objectKey,
        'activity_data/daily_choice_activity_library.json',
      );

      final summaries = await store.loadBuiltInSummaries();
      expect(summaries, hasLength(2));
      expect(summaries.first.id, 'activity_focus_drift_review');
      expect(
        summaries.first.moduleId,
        DailyChoiceModuleId.activity.storageValue,
      );
      expect(summaries.first.contextIds, contains('screen'));
      expect(summaries.first.materialsZh, contains('计时器 3 分钟'));

      final filtered = await store.queryBuiltInSummaries(
        categoryId: 'focus',
        contextId: 'screen',
      );
      expect(filtered, hasLength(1));
      expect(filtered.single.id, 'activity_focus_drift_review');

      final detail = await store.loadBuiltInDetail('activity_outdoor_walk');
      expect(detail, isNotNull);
      expect(detail!.stepsZh, hasLength(3));
      expect(detail.notesZh, contains('如果身体明显疲惫，只走到楼下也算完成。'));
      expect(detail.attributes['trigger'], <String>['stuck', 'restless']);
    });

    test('keeps installed SQLite when remote refresh fails', () async {
      final sourceFile = File(
        p.join(tempDir.path, 'activity_library_source.json'),
      );
      await sourceFile.writeAsString(jsonEncode(_sampleActivityLibrary()));
      await store.close();
      final installStore = DailyChoiceActivityLibraryStore(
        supportDirectoryProvider: () async => tempDir,
        s3Client: _LocalActivityLibraryClient(sourceFile),
      );
      final failingStore = DailyChoiceActivityLibraryStore(
        supportDirectoryProvider: () async => tempDir,
        s3Client: _FailingActivityLibraryClient(),
      );
      addTearDown(() async {
        await installStore.close();
        await failingStore.close();
      });

      final installedStatus = await installStore.installLibrary();
      expect(installedStatus.hasInstalledLibrary, isTrue);
      await installStore.close();

      final failedStatus = await failingStore.installLibrary();
      expect(failedStatus.hasInstalledLibrary, isTrue);
      expect(failedStatus.actionCount, 2);
      expect(failedStatus.errorMessage, contains('s3 unavailable'));

      final summaries = await failingStore.loadBuiltInSummaries();
      expect(summaries, hasLength(2));
    });
  });

  test('static seed no longer contains activity module hard-coded options', () {
    final activityOptions = buildDailyChoiceStaticSeedOptions()
        .where(
          (item) => item.moduleId == DailyChoiceModuleId.activity.storageValue,
        )
        .toList(growable: false);
    expect(activityOptions, isEmpty);
  });
}

Map<String, Object?> _sampleActivityLibrary() {
  return <String, Object?>{
    'libraryId': 'toolbox_daily_choice_activity_library',
    'libraryVersion': '2026-04-29-test',
    'schemaId': 'vocabulary_sleep.daily_choice.activity_library',
    'schemaVersion': 1,
    'referenceTitles': <String>['测试行动库'],
    'options': <Map<String, Object?>>[
      _sampleActivityOption(
        id: 'activity_focus_drift_review',
        categoryId: 'focus',
        contextId: 'screen',
        contextIds: <String>['screen', 'desk'],
        titleZh: '无评价复盘走神',
        titleEn: 'Non-judgment drift review',
        subtitleZh: '先看见涣散内容，再回到当前目标',
        subtitleEn: 'Notice the drift, then return to the goal',
        detailsZh: '适合刷屏、发呆或脑内幻想把当前任务挤走时使用。',
        detailsEn: 'Use when scrolling, zoning out, or fantasy displaces work.',
        materialsZh: <String>['计时器 3 分钟', '纸笔或备忘录'],
        stepsZh: <String>['写下刚才想到了什么', '标记触发原因', '重述当前目标'],
        notesZh: <String>['只描述，不评价自己。'],
        tagsZh: <String>['注意力', '复盘'],
        attributes: <String, List<String>>{
          'duration': <String>['3m'],
          'trigger': <String>['drift', 'scrolling'],
        },
      ),
      _sampleActivityOption(
        id: 'activity_outdoor_walk',
        categoryId: 'outdoor',
        contextId: 'outside',
        contextIds: <String>['outside', 'solo'],
        titleZh: '出门散步十分钟',
        titleEn: 'Ten-minute walk outside',
        subtitleZh: '卡住、烦躁或久坐后换一个环境',
        subtitleEn: 'Change environment when stuck, restless, or sedentary',
        detailsZh: '适合连续坐太久、室内空气沉闷、情绪开始打结时使用。',
        detailsEn: 'Use after long sitting, stale air, or rising tension.',
        materialsZh: <String>['钥匙', '手机', '合适的鞋'],
        stepsZh: <String>['离开桌面', '走到楼下或最近路口', '回来后写下一步'],
        notesZh: <String>['如果身体明显疲惫，只走到楼下也算完成。'],
        tagsZh: <String>['散步', '换环境'],
        attributes: <String, List<String>>{
          'duration': <String>['10m'],
          'trigger': <String>['stuck', 'restless'],
        },
      ),
    ],
  };
}

Map<String, Object?> _sampleActivityOption({
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
  required List<String> materialsZh,
  required List<String> stepsZh,
  required List<String> notesZh,
  required List<String> tagsZh,
  required Map<String, List<String>> attributes,
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
    'materialsZh': materialsZh,
    'materialsEn': materialsZh,
    'stepsZh': stepsZh,
    'stepsEn': stepsZh,
    'notesZh': notesZh,
    'notesEn': notesZh,
    'tagsZh': tagsZh,
    'tagsEn': tagsZh,
    'sourceLabel': null,
    'sourceUrl': null,
    'references': <Map<String, String>>[],
    'attributes': attributes,
    'custom': false,
  };
}

class _LocalActivityLibraryClient extends CstCloudS3CompatClient {
  _LocalActivityLibraryClient(this.sourceFile);

  final File sourceFile;
  String? objectKey;

  @override
  Future<File> downloadObjectToFile(
    String objectKey,
    File targetFile, {
    void Function(int receivedBytes, int totalBytes)? onProgress,
  }) async {
    this.objectKey = objectKey;
    await targetFile.parent.create(recursive: true);
    final copied = await sourceFile.copy(targetFile.path);
    final length = await copied.length();
    onProgress?.call(length, length);
    return copied;
  }

  @override
  Future<void> close() async {}
}

class _FailingActivityLibraryClient extends CstCloudS3CompatClient {
  @override
  Future<File> downloadObjectToFile(
    String objectKey,
    File targetFile, {
    void Function(int receivedBytes, int totalBytes)? onProgress,
  }) {
    throw StateError('s3 unavailable');
  }

  @override
  Future<void> close() async {}
}
