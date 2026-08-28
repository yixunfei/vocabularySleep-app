import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vocabulary_sleep_app/src/app/app_bootstrap.dart';

void main() {
  testWidgets(
    'shows the loading shell before initialization and builds the app once',
    (tester) async {
      final beforeRunAppGate = Completer<void>();
      final catalogGate = Completer<void>();
      var beforeRunAppCalls = 0;
      var catalogCalls = 0;
      var applicationBuilderCalls = 0;

      await tester.pumpWidget(
        VocabularySleepBootstrap(
          beforeRunApp: () {
            beforeRunAppCalls++;
            return beforeRunAppGate.future;
          },
          catalogLoader: () {
            catalogCalls++;
            return catalogGate.future;
          },
          applicationBuilder: () {
            applicationBuilderCalls++;
            return const SizedBox(key: ValueKey<String>('test.application'));
          },
        ),
      );

      expect(find.byKey(const ValueKey<String>('bootstrap.loading')), findsOne);
      expect(beforeRunAppCalls, 1);
      expect(catalogCalls, 0);
      expect(applicationBuilderCalls, 0);

      beforeRunAppGate.complete();
      await tester.pump();
      expect(catalogCalls, 1);
      expect(applicationBuilderCalls, 0);

      catalogGate.complete();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey<String>('test.application')), findsOne);
      expect(applicationBuilderCalls, 1);

      await tester.pump();
      expect(applicationBuilderCalls, 1);
    },
  );

  testWidgets(
    'reports catalog failure and retries without repeating prior setup',
    (tester) async {
      var beforeRunAppCalls = 0;
      var catalogCalls = 0;
      var applicationBuilderCalls = 0;
      final reportedErrors = <Object>[];

      await tester.pumpWidget(
        VocabularySleepBootstrap(
          beforeRunApp: () async {
            beforeRunAppCalls++;
          },
          catalogLoader: () async {
            catalogCalls++;
            if (catalogCalls == 1) {
              throw StateError('catalog unavailable');
            }
          },
          applicationBuilder: () {
            applicationBuilderCalls++;
            return const SizedBox(key: ValueKey<String>('test.application'));
          },
          onInitializationError: (error, stackTrace) {
            reportedErrors.add(error);
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey<String>('bootstrap.retry')), findsOne);
      expect(beforeRunAppCalls, 1);
      expect(catalogCalls, 1);
      expect(applicationBuilderCalls, 0);
      expect(reportedErrors, hasLength(1));

      await tester.tap(find.byKey(const ValueKey<String>('bootstrap.retry')));
      await tester.pumpAndSettle();

      expect(beforeRunAppCalls, 1);
      expect(catalogCalls, 2);
      expect(applicationBuilderCalls, 1);
      expect(find.byKey(const ValueKey<String>('test.application')), findsOne);
    },
  );
}
