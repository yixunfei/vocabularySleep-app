import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'src/app/app_bootstrap.dart';

Future<void> main() async {
  runVocabularySleepApp(
    beforeRunApp: () async {
      try {
        await dotenv.load(fileName: '.env', isOptional: true);
        debugPrint('Environment variables initialized');
      } catch (e) {
        debugPrint(
          'Warning: failed to load .env, using system environment ($e)',
        );
      }
    },
  );
}
