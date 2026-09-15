import 'package:flutter/material.dart';

import 'src/i18n/app_i18n.dart';
import 'src/i18n/app_i18n_catalog.dart';
import 'src/services/app_log_service.dart';
import 'src/services/asr_service.dart';
import 'src/services/database_service_web.dart';

class WebVocabularySleepApp extends StatefulWidget {
  const WebVocabularySleepApp({super.key});

  @override
  State<WebVocabularySleepApp> createState() => _WebVocabularySleepAppState();
}

class _WebVocabularySleepAppState extends State<WebVocabularySleepApp> {
  Object? _error;
  bool _loading = true;
  AppDatabaseService? _database;
  AsrService? _asr;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final logger = AppLogService.instance;
    await logger.init();
    final database = AppDatabaseService(null);
    try {
      await AppI18nCatalog.loadFromAssets();
      await database.init();
      _database = database;
      _asr = AsrService();
    } on Object catch (error, stackTrace) {
      database.dispose();
      logger.e(
        'web_bootstrap',
        'web application initialization failed',
        error: error,
        stackTrace: stackTrace,
      );
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _asr?.dispose();
    _database?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final language = AppI18n.normalizeLanguageCode(
      WidgetsBinding.instance.platformDispatcher.locale.languageCode,
    );
    final i18n = AppI18n(language);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Text(i18n.t('ref.toolbox.hub.entry.sleep_assistant.title')),
        ),
        body: Center(
          child: _loading
              ? const CircularProgressIndicator()
              : _error != null
              ? Text(i18n.t('app.bootstrap.catalog_load_failed'))
              : _WebCapabilityOverview(i18n: i18n),
        ),
      ),
    );
  }
}

class _WebCapabilityOverview extends StatelessWidget {
  const _WebCapabilityOverview({required this.i18n});

  final AppI18n i18n;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.language, size: 56),
          const SizedBox(height: 16),
          Text(i18n.t('ref.toolbox.hub.intro.summary_idle')),
          const SizedBox(height: 8),
          Text(i18n.t('ref.toolbox.sleep.assessment.moduleDisabled')),
        ],
      ),
    );
  }
}
