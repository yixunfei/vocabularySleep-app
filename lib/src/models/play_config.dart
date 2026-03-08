import 'dart:math';

import 'word_entry.dart';
import 'word_field.dart';

enum PlayOrder { sequential, random }

enum TtsProviderType { local, api, customApi }

enum AsrProviderType {
  api,
  customApi,
  offline,
  offlineSmall,
  localSimilarity,
  multiEngine,
}

enum PronScoringMethod {
  sslEmbedding,
  gop,
  forcedAlignmentPer,
  ppgPosterior,
}

class FieldPlaybackSetting {
  const FieldPlaybackSetting({this.enabled, this.repeat, this.label});

  final bool? enabled;
  final int? repeat;
  final String? label;

  FieldPlaybackSetting copyWith({bool? enabled, int? repeat, String? label}) {
    return FieldPlaybackSetting(
      enabled: enabled ?? this.enabled,
      repeat: repeat ?? this.repeat,
      label: label ?? this.label,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'enabled': enabled,
    'repeat': repeat,
    'label': label,
  };

  factory FieldPlaybackSetting.fromJson(Map<String, Object?> json) {
    return FieldPlaybackSetting(
      enabled: json['enabled'] as bool?,
      repeat: (json['repeat'] as num?)?.toInt(),
      label: json['label']?.toString(),
    );
  }
}

class TtsConfig {
  const TtsConfig({
    required this.provider,
    required this.voice,
    required this.localVoice,
    required this.remoteVoice,
    required this.remoteVoiceTypes,
    required this.language,
    required this.speed,
    required this.volume,
    this.apiKey,
    this.model,
    this.baseUrl,
  });

  final TtsProviderType provider;
  final String voice;
  final String localVoice;
  final String remoteVoice;
  final List<String> remoteVoiceTypes;
  final String language;
  final double speed;
  final double volume;
  final String? apiKey;
  final String? model;
  final String? baseUrl;

  String get activeVoice =>
      provider == TtsProviderType.local ? localVoice : remoteVoice;

  List<String> get normalizedRemoteVoiceTypes {
    final values = <String>[];
    void addValue(String raw) {
      final value = raw.trim();
      if (value.isEmpty) return;
      if (!values.contains(value)) values.add(value);
    }

    for (final item in remoteVoiceTypes) {
      addValue(item);
    }
    addValue(remoteVoice);
    return values;
  }

  TtsConfig copyWith({
    TtsProviderType? provider,
    String? voice,
    String? localVoice,
    String? remoteVoice,
    List<String>? remoteVoiceTypes,
    String? language,
    double? speed,
    double? volume,
    String? apiKey,
    String? model,
    String? baseUrl,
  }) {
    return TtsConfig(
      provider: provider ?? this.provider,
      voice: voice ?? this.voice,
      localVoice: localVoice ?? this.localVoice,
      remoteVoice: remoteVoice ?? this.remoteVoice,
      remoteVoiceTypes: List<String>.from(
        remoteVoiceTypes ?? this.remoteVoiceTypes,
      ),
      language: language ?? this.language,
      speed: speed ?? this.speed,
      volume: volume ?? this.volume,
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
      baseUrl: baseUrl ?? this.baseUrl,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'provider': provider.name,
    'voice': voice,
    'localVoice': localVoice,
    'remoteVoice': remoteVoice,
    'remoteVoiceTypes': remoteVoiceTypes,
    'language': language,
    'speed': speed,
    'volume': volume,
    'apiKey': apiKey,
    'model': model,
    'baseUrl': baseUrl,
  };

  factory TtsConfig.fromJson(Map<String, Object?> json) {
    final provider = TtsProviderType.values.firstWhere(
      (item) => item.name == json['provider'],
      orElse: () => TtsProviderType.local,
    );
    final legacyVoice = json['voice']?.toString() ?? '';
    final localVoice =
        json['localVoice']?.toString() ??
        (provider == TtsProviderType.local ? legacyVoice : '');
    final remoteVoice =
        json['remoteVoice']?.toString() ??
        (provider == TtsProviderType.local ? '' : legacyVoice);
    final rawRemoteVoiceTypes = json['remoteVoiceTypes'];
    final remoteVoiceTypes = <String>[];
    if (rawRemoteVoiceTypes is List) {
      for (final item in rawRemoteVoiceTypes) {
        final value = '$item'.trim();
        if (value.isNotEmpty && !remoteVoiceTypes.contains(value)) {
          remoteVoiceTypes.add(value);
        }
      }
    }
    final activeVoice = provider == TtsProviderType.local
        ? localVoice
        : remoteVoice;
    if (remoteVoiceTypes.isEmpty && remoteVoice.trim().isNotEmpty) {
      remoteVoiceTypes.add(remoteVoice.trim());
    }

    return TtsConfig(
      provider: provider,
      voice: activeVoice,
      localVoice: localVoice,
      remoteVoice: remoteVoice,
      remoteVoiceTypes: remoteVoiceTypes,
      language: json['language']?.toString() ?? 'auto',
      speed: (json['speed'] as num?)?.toDouble() ?? 1.0,
      volume: (json['volume'] as num?)?.toDouble() ?? 1.0,
      apiKey: json['apiKey']?.toString(),
      model: json['model']?.toString(),
      baseUrl: json['baseUrl']?.toString(),
    );
  }
}

class AsrConfig {
  const AsrConfig({
    required this.enabled,
    required this.provider,
    required this.engineOrder,
    required this.scoringMethods,
    this.apiKey,
    required this.model,
    required this.language,
    this.baseUrl,
  });

  final bool enabled;
  final AsrProviderType provider;
  final List<AsrProviderType> engineOrder;
  final List<PronScoringMethod> scoringMethods;
  final String? apiKey;
  final String model;
  final String language;
  final String? baseUrl;

  List<AsrProviderType> get normalizedEngineOrder {
    final input = engineOrder.isEmpty
        ? const <AsrProviderType>[
            AsrProviderType.api,
            AsrProviderType.localSimilarity,
          ]
        : engineOrder;
    final output = <AsrProviderType>[];
    for (final item in input) {
      if (item == AsrProviderType.multiEngine) continue;
      if (!output.contains(item)) output.add(item);
    }
    if (output.isEmpty) {
      output.add(AsrProviderType.api);
    }
    return output;
  }

  List<PronScoringMethod> get normalizedScoringMethods {
    final input = scoringMethods.isEmpty
        ? const <PronScoringMethod>[PronScoringMethod.sslEmbedding]
        : scoringMethods;
    final output = <PronScoringMethod>[];
    for (final item in input) {
      if (!output.contains(item)) output.add(item);
    }
    if (output.isEmpty) {
      output.add(PronScoringMethod.sslEmbedding);
    }
    return output;
  }

  AsrConfig copyWith({
    bool? enabled,
    AsrProviderType? provider,
    List<AsrProviderType>? engineOrder,
    List<PronScoringMethod>? scoringMethods,
    String? apiKey,
    String? model,
    String? language,
    String? baseUrl,
  }) {
    return AsrConfig(
      enabled: enabled ?? this.enabled,
      provider: provider ?? this.provider,
      engineOrder: List<AsrProviderType>.from(
        engineOrder ?? this.engineOrder,
      ),
      scoringMethods: List<PronScoringMethod>.from(
        scoringMethods ?? this.scoringMethods,
      ),
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
      language: language ?? this.language,
      baseUrl: baseUrl ?? this.baseUrl,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'enabled': enabled,
    'provider': provider.name,
    'engineOrder': engineOrder.map((item) => item.name).toList(growable: false),
    'scoringMethods': scoringMethods
        .map((item) => item.name)
        .toList(growable: false),
    'apiKey': apiKey,
    'model': model,
    'language': language,
    'baseUrl': baseUrl,
  };

  factory AsrConfig.fromJson(Map<String, Object?> json) {
    final provider = AsrProviderType.values.firstWhere(
      (item) => item.name == json['provider'],
      orElse: () => AsrProviderType.api,
    );
    final parsedEngineOrder = <AsrProviderType>[];
    final rawEngineOrder = json['engineOrder'];
    if (rawEngineOrder is List) {
      for (final item in rawEngineOrder) {
        final name = '$item';
        final provider = AsrProviderType.values.firstWhere(
          (candidate) => candidate.name == name,
          orElse: () => AsrProviderType.multiEngine,
        );
        if (provider == AsrProviderType.multiEngine) continue;
        if (!parsedEngineOrder.contains(provider)) {
          parsedEngineOrder.add(provider);
        }
      }
    }
    if (parsedEngineOrder.isEmpty) {
      parsedEngineOrder.addAll(
        const <AsrProviderType>[
          AsrProviderType.api,
          AsrProviderType.localSimilarity,
        ],
      );
    }
    final parsedScoringMethods = <PronScoringMethod>[];
    final rawScoringMethods = json['scoringMethods'];
    if (rawScoringMethods is List) {
      for (final item in rawScoringMethods) {
        final name = '$item';
        final method = PronScoringMethod.values.firstWhere(
          (candidate) => candidate.name == name,
          orElse: () => PronScoringMethod.sslEmbedding,
        );
        if (!parsedScoringMethods.contains(method)) {
          parsedScoringMethods.add(method);
        }
      }
    }
    if (parsedScoringMethods.isEmpty) {
      parsedScoringMethods.add(PronScoringMethod.sslEmbedding);
    }

    return AsrConfig(
      enabled: json['enabled'] as bool? ?? false,
      provider: provider,
      engineOrder: parsedEngineOrder,
      scoringMethods: parsedScoringMethods,
      apiKey: json['apiKey']?.toString(),
      model: json['model']?.toString() ?? 'FunAudioLLM/SenseVoiceSmall',
      language: json['language']?.toString() ?? 'en',
      baseUrl: json['baseUrl']?.toString(),
    );
  }
}

class PlayConfig {
  const PlayConfig({
    required this.repeats,
    required this.fieldSettings,
    required this.overallRepeat,
    required this.order,
    required this.tts,
    required this.asr,
    required this.showText,
    required this.delayBetweenUnitsMs,
  });

  final Map<String, int> repeats;
  final Map<String, FieldPlaybackSetting> fieldSettings;
  final int overallRepeat;
  final PlayOrder order;
  final TtsConfig tts;
  final AsrConfig asr;
  final bool showText;
  final int delayBetweenUnitsMs;

  static PlayConfig get defaults => PlayConfig(
    repeats: const <String, int>{
      'word': 1,
      'meaning': 1,
      'example': 1,
      'spelling': 0,
      'story': 0,
      'etymology': 0,
      'roots': 0,
      'affixes': 0,
      'variations': 0,
      'memory': 0,
    },
    fieldSettings: const <String, FieldPlaybackSetting>{},
    overallRepeat: 1,
    order: PlayOrder.sequential,
    tts: const TtsConfig(
      provider: TtsProviderType.local,
      voice: '',
      localVoice: '',
      remoteVoice: 'alex',
      remoteVoiceTypes: <String>['alex'],
      language: 'auto',
      speed: 1.0,
      volume: 1.0,
      model: 'FunAudioLLM/CosyVoice2-0.5B',
    ),
    asr: const AsrConfig(
      enabled: false,
      provider: AsrProviderType.api,
      engineOrder: <AsrProviderType>[
        AsrProviderType.api,
        AsrProviderType.localSimilarity,
      ],
      scoringMethods: <PronScoringMethod>[PronScoringMethod.sslEmbedding],
      model: 'FunAudioLLM/SenseVoiceSmall',
      language: 'en',
    ),
    showText: true,
    delayBetweenUnitsMs: 500,
  );

  PlayConfig copyWith({
    Map<String, int>? repeats,
    Map<String, FieldPlaybackSetting>? fieldSettings,
    int? overallRepeat,
    PlayOrder? order,
    TtsConfig? tts,
    AsrConfig? asr,
    bool? showText,
    int? delayBetweenUnitsMs,
  }) {
    return PlayConfig(
      repeats: repeats ?? this.repeats,
      fieldSettings: fieldSettings ?? this.fieldSettings,
      overallRepeat: overallRepeat ?? this.overallRepeat,
      order: order ?? this.order,
      tts: tts ?? this.tts,
      asr: asr ?? this.asr,
      showText: showText ?? this.showText,
      delayBetweenUnitsMs: delayBetweenUnitsMs ?? this.delayBetweenUnitsMs,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'repeats': repeats,
    'fieldSettings': fieldSettings.map(
      (key, value) => MapEntry(key, value.toJson()),
    ),
    'overallRepeat': overallRepeat,
    'order': order.name,
    'tts': tts.toJson(),
    'asr': asr.toJson(),
    'showText': showText,
    'delayBetweenUnits': delayBetweenUnitsMs,
  };

  factory PlayConfig.fromJson(Map<String, Object?> json) {
    final repeats = Map<String, int>.from(PlayConfig.defaults.repeats);
    final rawRepeats = json['repeats'];
    if (rawRepeats is Map) {
      for (final entry in rawRepeats.entries) {
        repeats['${entry.key}'] = (entry.value as num?)?.toInt() ?? 0;
      }
    }

    final settings = <String, FieldPlaybackSetting>{};
    final rawSettings = json['fieldSettings'];
    if (rawSettings is Map) {
      for (final entry in rawSettings.entries) {
        final value = entry.value;
        if (value is Map<String, Object?>) {
          settings['${entry.key}'] = FieldPlaybackSetting.fromJson(value);
        } else if (value is Map) {
          settings['${entry.key}'] = FieldPlaybackSetting.fromJson(
            value.map((key, data) => MapEntry('$key', data)),
          );
        }
      }
    }

    final order = PlayOrder.values.firstWhere(
      (item) => item.name == json['order'],
      orElse: () => PlayOrder.sequential,
    );

    final tts = json['tts'] is Map
        ? TtsConfig.fromJson((json['tts'] as Map).cast<String, Object?>())
        : PlayConfig.defaults.tts;
    final asr = json['asr'] is Map
        ? AsrConfig.fromJson((json['asr'] as Map).cast<String, Object?>())
        : PlayConfig.defaults.asr;

    return PlayConfig(
      repeats: repeats,
      fieldSettings: settings,
      overallRepeat: (json['overallRepeat'] as num?)?.toInt() ?? 1,
      order: order,
      tts: tts,
      asr: asr,
      showText: json['showText'] as bool? ?? true,
      delayBetweenUnitsMs: (json['delayBetweenUnits'] as num?)?.toInt() ?? 500,
    );
  }
}

class PlayUnit {
  const PlayUnit({required this.type, required this.text, this.label});

  final String type;
  final String text;
  final String? label;
}

const Map<String, String> _fieldToRepeatKey = <String, String>{
  'meaning': 'meaning',
  'examples': 'example',
  'etymology': 'etymology',
  'roots': 'roots',
  'affixes': 'affixes',
  'variations': 'variations',
  'memory': 'memory',
  'story': 'story',
};

const Map<String, String> _fieldToUnitType = <String, String>{
  'meaning': 'meaning',
  'examples': 'example',
  'etymology': 'etymology',
  'roots': 'roots',
  'affixes': 'affixes',
  'variations': 'variations',
  'memory': 'memory',
  'story': 'story',
};

int _resolveFieldRepeat(String key, PlayConfig config) {
  final setting = config.fieldSettings[key];
  if (setting?.repeat != null) return max(0, setting!.repeat!);

  final repeatKey = _fieldToRepeatKey[key];
  if (repeatKey != null) return max(0, config.repeats[repeatKey] ?? 0);
  return 0;
}

bool _isFieldEnabled(String key, PlayConfig config) {
  final setting = config.fieldSettings[key];
  if (setting?.enabled != null) return setting!.enabled!;
  return _resolveFieldRepeat(key, config) > 0;
}

String spellWord(String word) => word.split('').join(' - ').toUpperCase();

List<T> shuffled<T>(List<T> list) {
  final random = Random();
  final copied = List<T>.from(list);
  for (var i = copied.length - 1; i > 0; i--) {
    final j = random.nextInt(i + 1);
    final temp = copied[i];
    copied[i] = copied[j];
    copied[j] = temp;
  }
  return copied;
}

List<PlayUnit> buildPlayQueue(WordEntry word, PlayConfig config) {
  final queue = <PlayUnit>[];
  final wordRepeat = max(0, config.repeats['word'] ?? 1);
  for (var i = 0; i < wordRepeat; i++) {
    queue.add(PlayUnit(type: 'word', text: word.word));
  }

  final fallbackFields = buildFieldItemsFromRecord(<String, Object?>{
    'meaning': word.meaning,
    'examples': word.examples,
    'etymology': word.etymology,
    'roots': word.roots,
    'affixes': word.affixes,
    'variations': word.variations,
    'memory': word.memory,
    'story': word.story,
  });

  final fields = word.fields.isNotEmpty ? word.fields : fallbackFields;
  for (final field in fields) {
    if (field.key.isEmpty) continue;
    if (!_isFieldEnabled(field.key, config)) continue;

    final repeat = _resolveFieldRepeat(field.key, config);
    if (repeat <= 0) continue;

    final unitType = _fieldToUnitType[field.key] ?? 'custom';
    final label = config.fieldSettings[field.key]?.label ?? field.label;
    for (final value in field.asList()) {
      final text = value.trim();
      if (text.isEmpty) continue;
      for (var i = 0; i < repeat; i++) {
        queue.add(PlayUnit(type: unitType, text: text, label: label));
      }
    }
  }

  final spellingRepeat = max(0, config.repeats['spelling'] ?? 0);
  if (spellingRepeat > 0) {
    final spelling = spellWord(word.word);
    for (var i = 0; i < spellingRepeat; i++) {
      queue.add(PlayUnit(type: 'spelling', text: spelling));
    }
  }

  if (queue.isEmpty) queue.add(PlayUnit(type: 'word', text: word.word));

  final overall = max(1, config.overallRepeat);
  final finalQueue = <PlayUnit>[];
  for (var i = 0; i < overall; i++) {
    finalQueue.addAll(queue);
  }
  return finalQueue;
}
