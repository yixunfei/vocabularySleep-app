import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../i18n/app_i18n.dart';
import '../i18n/app_i18n_catalog.dart';
import '../services/app_log_service.dart';
import 'app_dependencies.dart';
import 'app_root.dart';

typedef VocabularySleepCatalogLoader = Future<void> Function();
typedef VocabularySleepApplicationBuilder = Widget Function();
typedef VocabularySleepInitializationErrorHandler =
    void Function(Object error, StackTrace stackTrace);

void runVocabularySleepApp({
  Future<void> Function()? beforeRunApp,
  VocabularySleepCatalogLoader? catalogLoader,
  VocabularySleepApplicationBuilder? applicationBuilder,
}) {
  final logger = AppLogService.instance;

  runZonedGuarded(
    () {
      WidgetsFlutterBinding.ensureInitialized();
      _installGlobalErrorHandlers(logger);
      unawaited(logger.init());
      runApp(
        VocabularySleepBootstrap(
          beforeRunApp: beforeRunApp,
          catalogLoader: catalogLoader ?? () => AppI18nCatalog.loadFromAssets(),
          applicationBuilder:
              applicationBuilder ?? _buildVocabularySleepApplication,
          onInitializationError: (error, stackTrace) {
            logger.e(
              'bootstrap',
              'application initialization failed',
              error: error,
              stackTrace: stackTrace,
            );
          },
        ),
      );
    },
    (Object error, StackTrace stackTrace) {
      if (_isKnownBenignFrameworkIssue(error)) {
        logger.w(
          'zone',
          'ignored known zone issue',
          data: <String, Object?>{'error': '$error'},
        );
        return;
      }
      logger.e(
        'zone',
        'uncaught zone error',
        error: error,
        stackTrace: stackTrace,
      );
    },
  );
}

class VocabularySleepBootstrap extends StatefulWidget {
  const VocabularySleepBootstrap({
    required this.catalogLoader,
    required this.applicationBuilder,
    this.beforeRunApp,
    this.onInitializationError,
    super.key,
  });

  final Future<void> Function()? beforeRunApp;
  final VocabularySleepCatalogLoader catalogLoader;
  final VocabularySleepApplicationBuilder applicationBuilder;
  final VocabularySleepInitializationErrorHandler? onInitializationError;

  @override
  State<VocabularySleepBootstrap> createState() =>
      _VocabularySleepBootstrapState();
}

class _VocabularySleepBootstrapState extends State<VocabularySleepBootstrap> {
  Widget? _application;
  Object? _initializationError;
  bool _beforeRunAppCompleted = false;
  bool _isInitializing = false;

  @override
  void initState() {
    super.initState();
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    if (_isInitializing || _application != null) {
      return;
    }
    _isInitializing = true;
    if (_initializationError != null) {
      setState(() => _initializationError = null);
    }

    try {
      if (!_beforeRunAppCompleted) {
        await widget.beforeRunApp?.call();
        _beforeRunAppCompleted = true;
      }
      await widget.catalogLoader();
      if (!mounted) {
        return;
      }
      final application = widget.applicationBuilder();
      if (!mounted) {
        return;
      }
      setState(() => _application = application);
    } on Object catch (error, stackTrace) {
      widget.onInitializationError?.call(error, stackTrace);
      if (mounted) {
        setState(() => _initializationError = error);
      }
    } finally {
      _isInitializing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final application = _application;
    if (application != null) {
      return application;
    }
    return _VocabularySleepStartupShell(
      hasError: _initializationError != null,
      onRetry: _initialize,
    );
  }
}

class _VocabularySleepStartupShell extends StatelessWidget {
  const _VocabularySleepStartupShell({
    required this.hasError,
    required this.onRetry,
  });

  final bool hasError;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final languageCode = AppI18n.normalizeLanguageCode(
      View.of(context).platformDispatcher.locale.languageCode,
    );
    final i18n = AppI18n(languageCode);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: hasError
                ? ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Icon(Icons.error_outline, size: 40),
                          const SizedBox(height: 16),
                          Text(
                            i18n.t('app.bootstrap.catalog_load_failed'),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            key: const ValueKey<String>('bootstrap.retry'),
                            onPressed: onRetry,
                            icon: const Icon(Icons.refresh),
                            label: Text(i18n.t('app.bootstrap.retry')),
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.square(
                    key: ValueKey<String>('bootstrap.loading'),
                    dimension: 48,
                    child: CircularProgressIndicator(),
                  ),
          ),
        ),
      ),
    );
  }
}

Widget _buildVocabularySleepApplication() {
  final dependencies = AppDependencies.create();
  return ProviderScope(
    overrides: dependencies.riverpodOverrides,
    child: dependencies.wrapWithProviders(const VocabularySleepApp()),
  );
}

void _installGlobalErrorHandlers(AppLogService logger) {
  FlutterError.onError = (FlutterErrorDetails details) {
    if (_isKnownBenignFrameworkIssue(details.exception)) {
      logger.w(
        'flutter',
        'ignored known framework issue',
        data: <String, Object?>{'error': '${details.exception}'},
      );
      return;
    }
    logger.e(
      'flutter',
      'uncaught Flutter framework error',
      error: details.exception,
      stackTrace: details.stack,
    );
    FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stackTrace) {
    if (_isKnownBenignFrameworkIssue(error)) {
      logger.w(
        'platform',
        'ignored known platform issue',
        data: <String, Object?>{'error': '$error'},
      );
      return true;
    }
    logger.e(
      'platform',
      'uncaught platform error',
      error: error,
      stackTrace: stackTrace,
    );
    return false;
  };
}

bool _isKnownBenignFrameworkIssue(Object error) {
  final message = '$error';
  return message.contains(
        'Attempted to send a key down event when no keys are in keysPressed',
      ) ||
      message.contains('Unable to parse JSON message:\nThe document is empty.');
}
