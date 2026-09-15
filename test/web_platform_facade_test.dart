import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_sleep_app/src/models/play_config.dart';
import 'package:vocabulary_sleep_app/src/services/app_log_service.dart';
import 'package:vocabulary_sleep_app/src/services/asr_service.dart';
import 'package:vocabulary_sleep_app/src/services/database_service_web.dart';

void main() {
  test('web-safe services expose stable startup contracts', () async {
    if (!kIsWeb) return;
    final database = AppDatabaseService(null);
    await database.init();
    expect(database.dbPath, contains('vocabulary'));
    database.setSetting('locale', 'en');
    expect(database.getSetting('locale'), 'en');

    final asr = AsrService();
    final result = await asr.transcribeFile(
      audioPath: 'unsupported',
      config: const AsrConfig(
        enabled: false,
        provider: AsrProviderType.api,
        engineOrder: <AsrProviderType>[],
        scoringMethods: <PronScoringMethod>[],
        model: '',
        language: 'en',
      ),
    );
    expect(result.success, isFalse);
    expect(result.error, 'unsupported');
    expect(
      (await asr.getOfflineModelStatus(AsrProviderType.offline)).installed,
      isFalse,
    );
    await asr.dispose();
    expect(await AppLogService.instance.getLogFilePath(), isNull);
    database.dispose();
  });
}
