import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../services/app_log_service.dart';
import 'app_dependencies.dart';
import 'app_root.dart';

void runVocabularySleepApp() {
  final logger = AppLogService.instance;

  runZonedGuarded(
    () {
      WidgetsFlutterBinding.ensureInitialized();
      unawaited(logger.init());

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

      PlatformDispatcher.instance.onError =
          (Object error, StackTrace stackTrace) {
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

      final dependencies = AppDependencies.create();
      runApp(dependencies.wrapWithProviders(const VocabularySleepApp()));
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

bool _isKnownBenignFrameworkIssue(Object error) {
  final message = '$error';
  return message.contains(
        'Attempted to send a key down event when no keys are in keysPressed',
      ) ||
      message.contains('Unable to parse JSON message:\nThe document is empty.');
}
