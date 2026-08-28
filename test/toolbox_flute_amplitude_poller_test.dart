import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vocabulary_sleep_app/src/services/toolbox_flute_amplitude_poller.dart';

void main() {
  test('does not overlap slow amplitude reads', () {
    fakeAsync((async) {
      final requests = <Completer<int?>>[];
      final amplitudes = <int>[];
      final errors = <Object>[];
      var readCalls = 0;
      final poller = ToolboxFluteAmplitudePoller<int>(
        interval: const Duration(milliseconds: 10),
        read: () {
          readCalls++;
          final request = Completer<int?>();
          requests.add(request);
          return request.future;
        },
        onAmplitude: amplitudes.add,
        onError: (error, stackTrace) => errors.add(error),
      );

      poller.start();
      async.elapse(const Duration(milliseconds: 10));
      async.flushMicrotasks();
      expect(readCalls, 1);

      async.elapse(const Duration(milliseconds: 50));
      async.flushMicrotasks();
      expect(readCalls, 1);

      requests.removeAt(0).complete(3);
      async.flushMicrotasks();
      expect(amplitudes, <int>[3]);

      async.elapse(const Duration(milliseconds: 10));
      async.flushMicrotasks();
      expect(readCalls, 2);
      requests.removeAt(0).complete(7);
      async.flushMicrotasks();

      expect(amplitudes, <int>[3, 7]);
      expect(errors, isEmpty);
      poller.dispose();
    });
  });

  test('drops a late result after stop and resumes with a new generation', () {
    fakeAsync((async) {
      final requests = <Completer<int?>>[];
      final amplitudes = <int>[];
      final errors = <Object>[];
      var readCalls = 0;
      final poller = ToolboxFluteAmplitudePoller<int>(
        interval: const Duration(milliseconds: 10),
        read: () {
          readCalls++;
          final request = Completer<int?>();
          requests.add(request);
          return request.future;
        },
        onAmplitude: amplitudes.add,
        onError: (error, stackTrace) => errors.add(error),
      );

      poller.start();
      async.elapse(const Duration(milliseconds: 10));
      async.flushMicrotasks();
      expect(readCalls, 1);

      poller.stop();
      poller.start();
      requests.removeAt(0).completeError(StateError('late recorder failure'));
      async.flushMicrotasks();
      expect(amplitudes, isEmpty);
      expect(errors, isEmpty);

      async.elapse(const Duration(milliseconds: 10));
      async.flushMicrotasks();
      expect(readCalls, 2);
      requests.removeAt(0).complete(9);
      async.flushMicrotasks();

      expect(amplitudes, <int>[9]);
      expect(errors, isEmpty);
      poller.dispose();
    });
  });

  test('drops an in-flight result after dispose', () {
    fakeAsync((async) {
      final request = Completer<int?>();
      final amplitudes = <int>[];
      final errors = <Object>[];
      var readCalls = 0;
      final poller = ToolboxFluteAmplitudePoller<int>(
        interval: const Duration(milliseconds: 10),
        read: () {
          readCalls++;
          return request.future;
        },
        onAmplitude: amplitudes.add,
        onError: (error, stackTrace) => errors.add(error),
      );

      poller.start();
      async.elapse(const Duration(milliseconds: 10));
      async.flushMicrotasks();
      expect(readCalls, 1);

      poller.dispose();
      request.complete(5);
      async.flushMicrotasks();
      async.elapse(const Duration(milliseconds: 50));
      async.flushMicrotasks();

      expect(readCalls, 1);
      expect(amplitudes, isEmpty);
      expect(errors, isEmpty);
    });
  });
}
