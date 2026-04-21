import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:vocabulary_sleep_app/src/services/toolbox_audio_service.dart';

const int _defaultAudioCacheEntries = 320;
const int _defaultAudioCacheMaxBytes = 48 * 1024 * 1024;

void main() {
  group('ToolboxAudioBank regression', () {
    setUp(() {
      ToolboxAudioBank.configureCache(
        maxEntries: _defaultAudioCacheEntries,
        maxBytes: _defaultAudioCacheMaxBytes,
      );
      ToolboxAudioBank.clearCache();
    });

    tearDown(() {
      ToolboxAudioBank.configureCache(
        maxEntries: _defaultAudioCacheEntries,
        maxBytes: _defaultAudioCacheMaxBytes,
      );
      ToolboxAudioBank.clearCache();
    });

    test('flute note emits valid wav and decays toward tail', () {
      final bytes = ToolboxAudioBank.fluteNote(
        523.25,
        style: 'airy',
        material: 'wood',
        breath: 0.62,
        reverb: 0.24,
        tail: 0.58,
        sustained: false,
      );
      final wav = _decodeWavPcm16(bytes);

      expect(wav.sampleRate, 32000);
      expect(wav.samples.length, greaterThan(20000));
      expect(_rms(wav.samples), greaterThan(0.01));

      final midStart = wav.samples.length ~/ 3;
      final midRms = _rms(
        wav.samples.sublist(midStart, midStart + wav.samples.length ~/ 8),
      );
      final tailRms = _rms(
        wav.samples.sublist(wav.samples.length - wav.samples.length ~/ 8),
      );

      expect(midRms, greaterThan(0.015));
      expect(tailRms, lessThan(midRms * 0.9));
    });

    test('violin variants remain audibly distinct by waveform', () {
      final variantA = ToolboxAudioBank.violinNote(
        440.0,
        style: 'solo',
        variant: 'a',
        bow: 0.66,
        reverb: 0.2,
      );
      final variantB = ToolboxAudioBank.violinNote(
        440.0,
        style: 'solo',
        variant: 'b',
        bow: 0.66,
        reverb: 0.2,
      );

      expect(variantA, isNot(equals(variantB)));
      final rmsA = _rms(_decodeWavPcm16(variantA).samples);
      final rmsB = _rms(_decodeWavPcm16(variantB).samples);
      expect((rmsA - rmsB).abs(), greaterThan(0.001));
    });

    test('flute sustain layers produce valid non-silent wav', () {
      final core = _decodeWavPcm16(
        ToolboxAudioBank.fluteSustainCore(
          392.0,
          style: 'alto',
          material: 'jade',
        ),
      );
      final air = _decodeWavPcm16(
        ToolboxAudioBank.fluteSustainAir(
          392.0,
          style: 'alto',
          material: 'jade',
        ),
      );
      final edge = _decodeWavPcm16(
        ToolboxAudioBank.fluteSustainEdge(
          392.0,
          style: 'alto',
          material: 'jade',
        ),
      );

      expect(core.sampleRate, 32000);
      expect(air.sampleRate, 32000);
      expect(edge.sampleRate, 32000);
      expect(_rms(core.samples), greaterThan(0.01));
      expect(_rms(air.samples), greaterThan(0.005));
      expect(_rms(edge.samples), greaterThan(0.005));
    });

    test('same parameters keep deterministic wav bytes in-process', () {
      final first = ToolboxAudioBank.violinRoomTail(
        329.63,
        style: 'warm',
        variant: 'a',
        bow: 0.58,
        reverb: 0.26,
      );
      final second = ToolboxAudioBank.violinRoomTail(
        329.63,
        style: 'warm',
        variant: 'a',
        bow: 0.58,
        reverb: 0.26,
      );

      expect(first, equals(second));
    });

    test('cache obeys max entries with LRU eviction', () {
      ToolboxAudioBank.configureCache(maxEntries: 2);

      final first = ToolboxAudioBank.harpNote(220.0, variant: 0);
      final second = ToolboxAudioBank.harpNote(220.0, variant: 1);

      expect(
        identical(first, ToolboxAudioBank.harpNote(220.0, variant: 0)),
        isTrue,
      );

      ToolboxAudioBank.harpNote(220.0, variant: 2);
      final reloadedSecond = ToolboxAudioBank.harpNote(220.0, variant: 1);

      expect(ToolboxAudioBank.cacheEntryCount, lessThanOrEqualTo(2));
      expect(identical(second, reloadedSecond), isFalse);
    });

    test('cache obeys max bytes with LRU eviction', () {
      final first = ToolboxAudioBank.harpNote(261.63, variant: 0);
      final second = ToolboxAudioBank.harpNote(261.63, variant: 1);
      final maxBytes = first.lengthInBytes + second.lengthInBytes;

      ToolboxAudioBank.configureCache(maxEntries: 8, maxBytes: maxBytes);

      final secondAgain = ToolboxAudioBank.harpNote(261.63, variant: 1);
      expect(identical(secondAgain, second), isTrue);

      ToolboxAudioBank.harpNote(261.63, variant: 2);
      final firstReloaded = ToolboxAudioBank.harpNote(261.63, variant: 0);

      expect(ToolboxAudioBank.cacheBytesEstimate, lessThanOrEqualTo(maxBytes));
      expect(ToolboxAudioBank.cacheMaxBytes, maxBytes);
      expect(identical(firstReloaded, first), isFalse);
      expect(ToolboxAudioBank.cacheEntryCount, lessThanOrEqualTo(2));
    });

    test('clearDomainCache removes only selected key space', () {
      final harp = ToolboxAudioBank.harpNote(261.63, variant: 5);
      final piano = ToolboxAudioBank.pianoNote(261.63, variant: 5);

      final removed = ToolboxAudioBank.clearDomainCache('harp');

      expect(removed, greaterThan(0));
      expect(
        identical(harp, ToolboxAudioBank.harpNote(261.63, variant: 5)),
        isFalse,
      );
      expect(
        identical(piano, ToolboxAudioBank.pianoNote(261.63, variant: 5)),
        isTrue,
      );
    });
  });
}

({int sampleRate, List<double> samples}) _decodeWavPcm16(Uint8List bytes) {
  expect(bytes.length, greaterThanOrEqualTo(46));
  expect(String.fromCharCodes(bytes.sublist(0, 4)), 'RIFF');
  expect(String.fromCharCodes(bytes.sublist(8, 12)), 'WAVE');
  expect(String.fromCharCodes(bytes.sublist(12, 16)), 'fmt ');
  expect(String.fromCharCodes(bytes.sublist(36, 40)), 'data');

  final data = ByteData.sublistView(bytes);
  final sampleRate = data.getUint32(24, Endian.little);
  final bitsPerSample = data.getUint16(34, Endian.little);
  final dataBytes = data.getUint32(40, Endian.little);
  expect(bitsPerSample, 16);
  expect(dataBytes + 44, bytes.length);

  final sampleCount = dataBytes ~/ 2;
  final samples = List<double>.generate(sampleCount, (index) {
    final value = data.getInt16(44 + index * 2, Endian.little) / 32768.0;
    expect(value.isFinite, isTrue);
    return value;
  }, growable: false);
  return (sampleRate: sampleRate, samples: samples);
}

double _rms(List<double> values) {
  if (values.isEmpty) return 0;
  var sum = 0.0;
  for (final value in values) {
    sum += value * value;
  }
  return math.sqrt(sum / values.length);
}
