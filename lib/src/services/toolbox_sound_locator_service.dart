import 'dart:math' as math;
import 'dart:typed_data';

enum SoundLocatorEngineMode { mobileMove, mobileStereo, odasOptional }

enum SoundLocatorQuality { unavailable, poor, usable, strong, professional }

enum SoundLocatorConfirmation { unconfirmed, tentative, tracking, locked }

enum SoundLocatorMoveCue { stay, stepLeft, stepRight, stepForward, stepBack }

class SoundLocatorDeviceProfile {
  const SoundLocatorDeviceProfile({
    required this.sampleRate,
    required this.channelCount,
    required this.micSpacingMeters,
    required this.engineMode,
    required this.notes,
  });

  factory SoundLocatorDeviceProfile.forPcmStream({
    required int sampleRate,
    required int channelCount,
    double micSpacingMeters = SoundLocatorService.defaultMicSpacingMeters,
  }) {
    final safeChannels = channelCount < 1 ? 1 : channelCount;
    return SoundLocatorDeviceProfile(
      sampleRate: sampleRate <= 0
          ? SoundLocatorService.defaultSampleRate
          : sampleRate,
      channelCount: safeChannels,
      micSpacingMeters: micSpacingMeters,
      engineMode: safeChannels >= 2
          ? SoundLocatorEngineMode.mobileStereo
          : SoundLocatorEngineMode.mobileMove,
      notes: <String>[
        if (safeChannels >= 2)
          'Stereo phone input can estimate horizontal direction and improve mobile movement confirmation.'
        else
          'Mono phone input needs movement samples to confirm the source area.',
      ],
    );
  }

  final int sampleRate;
  final int channelCount;
  final double micSpacingMeters;
  final SoundLocatorEngineMode engineMode;
  final List<String> notes;

  bool get canEstimateDirection => channelCount >= 2;
  bool get supportsMobileMoveConfirmation => true;
  bool get supportsProfessionalLocalization => false;
}

class SoundLocatorSource {
  const SoundLocatorSource({
    required this.id,
    required this.azimuthDegrees,
    required this.elevationDegrees,
    required this.distanceMeters,
    required this.level,
    required this.confidence,
    required this.snrDb,
    required this.reverbRisk,
    required this.confirmation,
    required this.label,
  });

  final String id;
  final double azimuthDegrees;
  final double elevationDegrees;
  final double distanceMeters;
  final double level;
  final double confidence;
  final double snrDb;
  final double reverbRisk;
  final SoundLocatorConfirmation confirmation;
  final String label;

  Offset3D get directionVector {
    final azimuth = azimuthDegrees * math.pi / 180.0;
    final elevation = elevationDegrees * math.pi / 180.0;
    final horizontal = math.cos(elevation);
    return Offset3D(
      x: math.sin(azimuth) * horizontal,
      y: math.sin(elevation),
      z: math.cos(azimuth) * horizontal,
    );
  }
}

class SoundLocatorFrame {
  const SoundLocatorFrame({
    required this.profile,
    required this.sources,
    required this.quality,
    required this.inputRms,
    required this.peak,
    required this.noiseFloor,
    required this.snrDb,
    required this.reverbRisk,
    required this.timestamp,
    required this.status,
  });

  factory SoundLocatorFrame.idle(SoundLocatorDeviceProfile profile) {
    return SoundLocatorFrame(
      profile: profile,
      sources: const <SoundLocatorSource>[],
      quality: SoundLocatorQuality.unavailable,
      inputRms: 0,
      peak: 0,
      noiseFloor: 0,
      snrDb: 0,
      reverbRisk: 1,
      timestamp: DateTime.now(),
      status: 'idle',
    );
  }

  final SoundLocatorDeviceProfile profile;
  final List<SoundLocatorSource> sources;
  final SoundLocatorQuality quality;
  final double inputRms;
  final double peak;
  final double noiseFloor;
  final double snrDb;
  final double reverbRisk;
  final DateTime timestamp;
  final String status;

  SoundLocatorSource? get primarySource =>
      sources.isEmpty ? null : sources.first;
}

class Offset3D {
  const Offset3D({required this.x, required this.y, required this.z});

  final double x;
  final double y;
  final double z;
}

class SoundLocatorAnchorSample {
  const SoundLocatorAnchorSample({
    required this.id,
    required this.cue,
    required this.level,
    required this.snrDb,
    required this.reverbRisk,
    required this.azimuthDegrees,
    required this.timestamp,
  });

  final String id;
  final SoundLocatorMoveCue cue;
  final double level;
  final double snrDb;
  final double reverbRisk;
  final double? azimuthDegrees;
  final DateTime timestamp;

  double get qualityScore {
    final levelScore = (level / 0.18).clamp(0.0, 1.0);
    final snrScore = ((snrDb - 4) / 22).clamp(0.0, 1.0);
    final reverbScore = 1 - reverbRisk.clamp(0.0, 1.0);
    return (levelScore * 0.34 + snrScore * 0.42 + reverbScore * 0.24).clamp(
      0.0,
      1.0,
    );
  }
}

class SoundLocatorMoveConfirmation {
  const SoundLocatorMoveConfirmation({
    required this.samples,
    required this.confidence,
    required this.confirmation,
    required this.recommendedCue,
    required this.summary,
    required this.estimatedAzimuthDegrees,
  });

  final List<SoundLocatorAnchorSample> samples;
  final double confidence;
  final SoundLocatorConfirmation confirmation;
  final SoundLocatorMoveCue recommendedCue;
  final String summary;
  final double? estimatedAzimuthDegrees;

  bool get hasEnoughSamples => samples.length >= 3;
}

class OdasIntegrationProfile {
  const OdasIntegrationProfile({
    required this.recommended,
    required this.reason,
    required this.requirements,
    required this.outputProtocol,
  });

  final bool recommended;
  final String reason;
  final List<String> requirements;
  final String outputProtocol;
}

class SoundLocatorService {
  const SoundLocatorService();

  static const int defaultSampleRate = 44100;
  static const double speedOfSoundMetersPerSecond = 343.0;
  static const double defaultMicSpacingMeters = 0.12;

  static const OdasIntegrationProfile odasProfile = OdasIntegrationProfile(
    recommended: true,
    reason:
        'ODAS remains a useful optional reference for dedicated microphone-array setups, but phone-first localization should guide the user through multiple movement samples before claiming a confirmed source area.',
    requirements: <String>[
      'Phone microphone permission and stable PCM capture.',
      'At least three movement samples around the suspected source.',
      'A target sound that stays active while the user changes position.',
      'Optional array bridge only for advanced deployments.',
    ],
    outputProtocol:
        'Merge phone movement samples, optional stereo bearing, and optional ODAS frames into one confidence-ranked source confirmation model.',
  );

  SoundLocatorAnchorSample sampleFromFrame({
    required SoundLocatorFrame frame,
    required SoundLocatorMoveCue cue,
    required int index,
  }) {
    return SoundLocatorAnchorSample(
      id: 'sample-$index',
      cue: cue,
      level: frame.inputRms,
      snrDb: frame.snrDb,
      reverbRisk: frame.reverbRisk,
      azimuthDegrees: frame.primarySource?.azimuthDegrees,
      timestamp: frame.timestamp,
    );
  }

  SoundLocatorMoveConfirmation confirmFromMovementSamples(
    List<SoundLocatorAnchorSample> samples,
  ) {
    if (samples.isEmpty) {
      return const SoundLocatorMoveConfirmation(
        samples: <SoundLocatorAnchorSample>[],
        confidence: 0,
        confirmation: SoundLocatorConfirmation.unconfirmed,
        recommendedCue: SoundLocatorMoveCue.stepLeft,
        summary: 'Record the first position near the phone.',
        estimatedAzimuthDegrees: null,
      );
    }

    final sortedSamples = List<SoundLocatorAnchorSample>.from(samples)
      ..sort((a, b) => b.qualityScore.compareTo(a.qualityScore));
    final best = sortedSamples.first;
    final cueCoverage = samples.map((sample) => sample.cue).toSet().length;
    final meanQuality =
        samples.fold<double>(0, (sum, sample) => sum + sample.qualityScore) /
        samples.length;
    final strongest = samples.fold<double>(
      0,
      (value, sample) => math.max(value, sample.level),
    );
    final weakest = samples.fold<double>(
      double.infinity,
      (value, sample) => math.min(value, sample.level),
    );
    final contrast = weakest.isFinite
        ? ((strongest - weakest) / math.max(strongest, 1e-6)).clamp(0.0, 1.0)
        : 0.0;
    final sampleScore = (samples.length / 4).clamp(0.0, 1.0);
    final coverageScore = (cueCoverage / 3).clamp(0.0, 1.0);
    final bearingScore = _bearingAgreement(samples);
    final confidence =
        (meanQuality * 0.34 +
                contrast * 0.24 +
                sampleScore * 0.22 +
                coverageScore * 0.12 +
                bearingScore * 0.08)
            .clamp(0.0, 1.0);
    final confirmation = confidence >= 0.78 && samples.length >= 3
        ? SoundLocatorConfirmation.locked
        : confidence >= 0.58 && samples.length >= 3
        ? SoundLocatorConfirmation.tracking
        : confidence >= 0.34
        ? SoundLocatorConfirmation.tentative
        : SoundLocatorConfirmation.unconfirmed;

    return SoundLocatorMoveConfirmation(
      samples: List<SoundLocatorAnchorSample>.unmodifiable(samples),
      confidence: confidence,
      confirmation: confirmation,
      recommendedCue: _nextMoveCue(samples),
      summary: _movementSummary(
        confirmation: confirmation,
        bestCue: best.cue,
        samples: samples.length,
      ),
      estimatedAzimuthDegrees: _meanBearing(samples),
    );
  }

  SoundLocatorFrame frameFromOdasSources({
    required SoundLocatorDeviceProfile profile,
    required List<SoundLocatorSource> sources,
    double inputRms = 0,
    double peak = 0,
    double noiseFloor = 0,
    double snrDb = 0,
    double reverbRisk = 0,
    DateTime? timestamp,
  }) {
    final sortedSources = List<SoundLocatorSource>.from(sources)
      ..sort((a, b) => b.confidence.compareTo(a.confidence));
    final topConfidence = sortedSources.isEmpty
        ? 0.0
        : sortedSources.first.confidence;
    return SoundLocatorFrame(
      profile: profile,
      sources: sortedSources,
      quality: _qualityFor(
        confidence: topConfidence,
        snrDb: snrDb,
        professional: profile.supportsProfessionalLocalization,
      ),
      inputRms: inputRms,
      peak: peak,
      noiseFloor: noiseFloor,
      snrDb: snrDb,
      reverbRisk: reverbRisk,
      timestamp: timestamp ?? DateTime.now(),
      status: profile.supportsProfessionalLocalization
          ? sortedSources.isEmpty
                ? 'odas_waiting_for_sources'
                : 'odas_tracking'
          : 'odas_profile_insufficient',
    );
  }

  SoundLocatorFrame analyzePcm16({
    required Uint8List pcmBytes,
    required SoundLocatorDeviceProfile profile,
    double previousNoiseFloor = 0.012,
  }) {
    if (pcmBytes.lengthInBytes < profile.channelCount * 2 * 128) {
      return SoundLocatorFrame(
        profile: profile,
        sources: const <SoundLocatorSource>[],
        quality: SoundLocatorQuality.unavailable,
        inputRms: 0,
        peak: 0,
        noiseFloor: previousNoiseFloor,
        snrDb: 0,
        reverbRisk: 1,
        timestamp: DateTime.now(),
        status: 'waiting_for_audio',
      );
    }

    final channels = decodePcm16(pcmBytes, profile.channelCount);
    final mixed = mixDown(channels);
    final inputRms = rms(mixed);
    final peak = mixed.fold<double>(0, (max, value) {
      final absValue = value.abs();
      return absValue > max ? absValue : max;
    });
    final noiseFloor = estimateNoiseFloor(
      inputRms: inputRms,
      previousNoiseFloor: previousNoiseFloor,
    );
    final snrDb =
        20 * math.log(inputRms / math.max(1e-6, noiseFloor)) / math.ln10;
    final reverbRisk = estimateReverbRisk(mixed);

    if (!profile.canEstimateDirection) {
      return SoundLocatorFrame(
        profile: profile,
        sources: _monoActivitySources(
          level: inputRms,
          snrDb: snrDb,
          reverbRisk: reverbRisk,
        ),
        quality: inputRms > noiseFloor * 2.2
            ? SoundLocatorQuality.poor
            : SoundLocatorQuality.unavailable,
        inputRms: inputRms,
        peak: peak,
        noiseFloor: noiseFloor,
        snrDb: snrDb,
        reverbRisk: reverbRisk,
        timestamp: DateTime.now(),
        status: 'mono_direction_unavailable',
      );
    }

    final estimate = estimateStereoTdoa(
      left: channels[0],
      right: channels[1],
      sampleRate: profile.sampleRate,
      micSpacingMeters: profile.micSpacingMeters,
    );
    final confidence = _confidenceFrom(
      correlation: estimate.correlation,
      snrDb: snrDb,
      reverbRisk: reverbRisk,
    );
    final quality = _qualityFor(
      confidence: confidence,
      snrDb: snrDb,
      professional: false,
    );
    final sources = <SoundLocatorSource>[
      SoundLocatorSource(
        id: 'primary',
        azimuthDegrees: estimate.azimuthDegrees,
        elevationDegrees: 0,
        distanceMeters: profile.supportsProfessionalLocalization ? 2.0 : 1.4,
        level: inputRms.clamp(0.0, 1.0),
        confidence: confidence,
        snrDb: snrDb,
        reverbRisk: reverbRisk,
        confirmation: confidence >= 0.82
            ? SoundLocatorConfirmation.locked
            : confidence >= 0.62
            ? SoundLocatorConfirmation.tracking
            : SoundLocatorConfirmation.tentative,
        label: profile.supportsProfessionalLocalization
            ? 'Array fallback estimate'
            : 'Stereo estimate',
      ),
    ]..sort((a, b) => b.confidence.compareTo(a.confidence));

    return SoundLocatorFrame(
      profile: profile,
      sources: sources,
      quality: quality,
      inputRms: inputRms,
      peak: peak,
      noiseFloor: noiseFloor,
      snrDb: snrDb,
      reverbRisk: reverbRisk,
      timestamp: DateTime.now(),
      status: profile.supportsProfessionalLocalization
          ? 'array_pcm_pending_odas'
          : 'stereo_fallback',
    );
  }

  static List<List<double>> decodePcm16(Uint8List pcmBytes, int channelCount) {
    final channels = List<List<double>>.generate(
      channelCount,
      (_) => <double>[],
      growable: false,
    );
    final data = ByteData.sublistView(pcmBytes);
    final frameCount = data.lengthInBytes ~/ (2 * channelCount);
    for (var frame = 0; frame < frameCount; frame += 1) {
      for (var channel = 0; channel < channelCount; channel += 1) {
        final byteOffset = (frame * channelCount + channel) * 2;
        channels[channel].add(data.getInt16(byteOffset, Endian.little) / 32768);
      }
    }
    return channels;
  }

  static List<double> mixDown(List<List<double>> channels) {
    if (channels.isEmpty) {
      return const <double>[];
    }
    final length = channels.first.length;
    if (length == 0) {
      return const <double>[];
    }
    return List<double>.generate(length, (index) {
      var sum = 0.0;
      var count = 0;
      for (final channel in channels) {
        if (index >= channel.length) {
          continue;
        }
        sum += channel[index];
        count += 1;
      }
      return count == 0 ? 0.0 : sum / count;
    }, growable: false);
  }

  static ({double azimuthDegrees, int lagSamples, double correlation})
  estimateStereoTdoa({
    required List<double> left,
    required List<double> right,
    required int sampleRate,
    required double micSpacingMeters,
  }) {
    final maxLagSeconds = micSpacingMeters / speedOfSoundMetersPerSecond;
    final maxLag = math.max(1, (sampleRate * maxLagSeconds).ceil());
    var bestLag = 0;
    var bestScore = double.negativeInfinity;

    for (var lag = -maxLag; lag <= maxLag; lag += 1) {
      final score = _normalizedCorrelation(left, right, lag);
      if (score > bestScore) {
        bestScore = score;
        bestLag = lag;
      }
    }

    final lagSeconds = bestLag / sampleRate;
    final ratio = (lagSeconds * speedOfSoundMetersPerSecond / micSpacingMeters)
        .clamp(-1.0, 1.0);
    final azimuth = math.asin(ratio) * 180.0 / math.pi;
    return (
      azimuthDegrees: azimuth,
      lagSamples: bestLag,
      correlation: bestScore.isFinite ? bestScore.clamp(0.0, 1.0) : 0.0,
    );
  }

  static double rms(List<double> samples) {
    if (samples.isEmpty) {
      return 0;
    }
    var sumSquares = 0.0;
    for (final sample in samples) {
      sumSquares += sample * sample;
    }
    return math.sqrt(sumSquares / samples.length);
  }

  static double estimateNoiseFloor({
    required double inputRms,
    required double previousNoiseFloor,
  }) {
    if (inputRms <= 0) {
      return previousNoiseFloor.clamp(0.002, 0.18);
    }
    final target = inputRms < previousNoiseFloor * 1.4
        ? inputRms
        : previousNoiseFloor;
    return (previousNoiseFloor * 0.92 + target * 0.08).clamp(0.002, 0.18);
  }

  static double estimateReverbRisk(List<double> samples) {
    if (samples.length < 64) {
      return 1;
    }
    final earlyLength = math.max(16, samples.length ~/ 5);
    final tailStart = samples.length - earlyLength;
    final earlyRms = rms(samples.take(earlyLength).toList(growable: false));
    final tailRms = rms(samples.sublist(tailStart));
    final ratio = tailRms / math.max(earlyRms, 1e-6);
    return ((ratio - 0.38) / 0.62).clamp(0.0, 1.0);
  }

  static double _normalizedCorrelation(
    List<double> left,
    List<double> right,
    int lag,
  ) {
    final length = math.min(left.length, right.length);
    if (length < 16) {
      return 0;
    }
    var sum = 0.0;
    var leftEnergy = 0.0;
    var rightEnergy = 0.0;
    var count = 0;
    for (var i = 0; i < length; i += 1) {
      final rightIndex = i + lag;
      if (rightIndex < 0 || rightIndex >= length) {
        continue;
      }
      final a = left[i];
      final b = right[rightIndex];
      sum += a * b;
      leftEnergy += a * a;
      rightEnergy += b * b;
      count += 1;
    }
    if (count < 16 || leftEnergy <= 0 || rightEnergy <= 0) {
      return 0;
    }
    return (sum / math.sqrt(leftEnergy * rightEnergy)).abs();
  }

  static double _confidenceFrom({
    required double correlation,
    required double snrDb,
    required double reverbRisk,
  }) {
    final snrScore = ((snrDb - 4) / 22).clamp(0.0, 1.0);
    final reverbScore = 1 - reverbRisk.clamp(0.0, 1.0);
    return (correlation * 0.52 + snrScore * 0.30 + reverbScore * 0.18).clamp(
      0.0,
      1.0,
    );
  }

  static SoundLocatorQuality _qualityFor({
    required double confidence,
    required double snrDb,
    required bool professional,
  }) {
    if (professional && confidence >= 0.78 && snrDb >= 14) {
      return SoundLocatorQuality.professional;
    }
    if (confidence >= 0.72 && snrDb >= 12) {
      return SoundLocatorQuality.strong;
    }
    if (confidence >= 0.46 && snrDb >= 6) {
      return SoundLocatorQuality.usable;
    }
    if (confidence > 0.2) {
      return SoundLocatorQuality.poor;
    }
    return SoundLocatorQuality.unavailable;
  }

  static List<SoundLocatorSource> _monoActivitySources({
    required double level,
    required double snrDb,
    required double reverbRisk,
  }) {
    if (level < 0.01) {
      return const <SoundLocatorSource>[];
    }
    return <SoundLocatorSource>[
      SoundLocatorSource(
        id: 'activity',
        azimuthDegrees: 0,
        elevationDegrees: 0,
        distanceMeters: 0,
        level: level.clamp(0.0, 1.0),
        confidence: 0,
        snrDb: snrDb,
        reverbRisk: reverbRisk,
        confirmation: SoundLocatorConfirmation.unconfirmed,
        label: 'Sound activity',
      ),
    ];
  }

  static SoundLocatorMoveCue _nextMoveCue(
    List<SoundLocatorAnchorSample> samples,
  ) {
    const cues = <SoundLocatorMoveCue>[
      SoundLocatorMoveCue.stay,
      SoundLocatorMoveCue.stepLeft,
      SoundLocatorMoveCue.stepRight,
      SoundLocatorMoveCue.stepForward,
      SoundLocatorMoveCue.stepBack,
    ];
    final used = samples.map((sample) => sample.cue).toSet();
    for (final cue in cues) {
      if (!used.contains(cue)) {
        return cue;
      }
    }
    return SoundLocatorMoveCue.stay;
  }

  static String _movementSummary({
    required SoundLocatorConfirmation confirmation,
    required SoundLocatorMoveCue bestCue,
    required int samples,
  }) {
    final best = switch (bestCue) {
      SoundLocatorMoveCue.stay => 'the starting position',
      SoundLocatorMoveCue.stepLeft => 'the left-side sample',
      SoundLocatorMoveCue.stepRight => 'the right-side sample',
      SoundLocatorMoveCue.stepForward => 'the forward sample',
      SoundLocatorMoveCue.stepBack => 'the back sample',
    };
    return switch (confirmation) {
      SoundLocatorConfirmation.locked =>
        'Source area confirmed from $samples phone positions; strongest evidence is near $best.',
      SoundLocatorConfirmation.tracking =>
        'Source area is converging from $samples phone positions; keep the target sound active.',
      SoundLocatorConfirmation.tentative =>
        'Early source hint found near $best; collect more positions to confirm.',
      SoundLocatorConfirmation.unconfirmed =>
        'Need more movement samples before confirming a source area.',
    };
  }

  static double _bearingAgreement(List<SoundLocatorAnchorSample> samples) {
    final bearings = samples
        .map((sample) => sample.azimuthDegrees)
        .nonNulls
        .toList(growable: false);
    if (bearings.length < 2) {
      return 0;
    }
    final mean = _meanBearing(samples);
    if (mean == null) {
      return 0;
    }
    final averageError =
        bearings.fold<double>(
          0,
          (sum, bearing) => sum + (bearing - mean).abs(),
        ) /
        bearings.length;
    return (1 - averageError / 90).clamp(0.0, 1.0);
  }

  static double? _meanBearing(List<SoundLocatorAnchorSample> samples) {
    final bearings = samples
        .map((sample) => sample.azimuthDegrees)
        .nonNulls
        .toList(growable: false);
    if (bearings.isEmpty) {
      return null;
    }
    var x = 0.0;
    var y = 0.0;
    for (final bearing in bearings) {
      final radians = bearing * math.pi / 180;
      x += math.cos(radians);
      y += math.sin(radians);
    }
    return math.atan2(y, x) * 180 / math.pi;
  }
}
