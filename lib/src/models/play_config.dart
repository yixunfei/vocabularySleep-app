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

enum PronScoringMethod { sslEmbedding, gop, forcedAlignmentPer, ppgPosterior }

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
    this.dumpRecognitionAudioArtifacts = false,
    this.apiKey,
    required this.model,
    required this.language,
    this.baseUrl,
  });

  final bool enabled;
  final AsrProviderType provider;
  final List<AsrProviderType> engineOrder;
  final List<PronScoringMethod> scoringMethods;
  final bool dumpRecognitionAudioArtifacts;
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
    if (provider == AsrProviderType.multiEngine) {
      const allowed = <AsrProviderType>[
        AsrProviderType.offline,
        AsrProviderType.offlineSmall,
        AsrProviderType.localSimilarity,
      ];
      final filtered = <AsrProviderType>[];
      for (final item in allowed) {
        if (input.contains(item)) {
          filtered.add(item);
        }
      }
      if (filtered.isEmpty) {
        filtered.addAll(const <AsrProviderType>[
          AsrProviderType.offline,
          AsrProviderType.localSimilarity,
        ]);
      }
      return filtered;
    }
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
    bool? dumpRecognitionAudioArtifacts,
    String? apiKey,
    String? model,
    String? language,
    String? baseUrl,
  }) {
    return AsrConfig(
      enabled: enabled ?? this.enabled,
      provider: provider ?? this.provider,
      engineOrder: List<AsrProviderType>.from(engineOrder ?? this.engineOrder),
      scoringMethods: List<PronScoringMethod>.from(
        scoringMethods ?? this.scoringMethods,
      ),
      dumpRecognitionAudioArtifacts:
          dumpRecognitionAudioArtifacts ?? this.dumpRecognitionAudioArtifacts,
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
    'dumpRecognitionAudioArtifacts': dumpRecognitionAudioArtifacts,
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
      parsedEngineOrder.addAll(const <AsrProviderType>[
        AsrProviderType.api,
        AsrProviderType.localSimilarity,
      ]);
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
      dumpRecognitionAudioArtifacts:
          json['dumpRecognitionAudioArtifacts'] as bool? ?? false,
      apiKey: json['apiKey']?.toString(),
      model: json['model']?.toString() ?? 'FunAudioLLM/SenseVoiceSmall',
      language: json['language']?.toString() ?? 'en',
      baseUrl: json['baseUrl']?.toString(),
    );
  }
}

class AppearanceConfig {
  const AppearanceConfig({
    this.theme = 'flat',
    this.compactLayout = false,
    this.highContrastText = false,
    this.enhancedBackground = true,
    this.frostedPanels = false,
    this.gradientIntensity = 0.08,
    this.effectIntensity = 0.12,
    this.sidebarOpacity = 0.94,
    this.detailOpacity = 0.95,
    this.playbackOpacity = 0.93,
    this.fieldOpacity = 0.94,
    this.fieldGradientAccent = true,
    this.fieldGlow = false,
    this.playbackGlow = false,
    this.pageBackgroundHex = '',
    this.backgroundGradientStartHex = '',
    this.backgroundGradientEndHex = '',
    this.sidebarColorHex = '',
    this.detailColorHex = '',
    this.playbackColorHex = '',
    this.fieldColorHex = '',
    this.borderColorHex = '',
    this.accentColorHex = '',
    this.backgroundImagePath = '',
    this.backgroundImageMode = 'cover',
    this.backgroundImageOpacity = 0.28,
    this.fontFamilyKey = 'system',
    this.fontScale = 1.0,
    this.titleWeightKey = 'semibold',
    this.bodyWeightKey = 'regular',
    this.randomEntryColors = false,
    this.rainbowText = false,
    this.marqueeText = false,
    this.breathingEffect = false,
    this.flowingEffect = false,
  });

  static const List<String> supportedThemes = <String>[
    'flat',
    'tech',
    'dark',
    'fantasy',
    'nature',
    'sunset',
    'ocean',
    'mono',
  ];

  static const List<String> supportedBackgroundImageModes = <String>[
    'cover',
    'contain',
    'stretch',
    'top',
    'tile',
  ];

  static const List<String> supportedFontFamilyKeys = <String>[
    'system',
    'serif',
    'mono',
    'rounded',
  ];

  static const List<String> supportedFontWeightKeys = <String>[
    'regular',
    'medium',
    'semibold',
    'bold',
  ];

  static const List<String> supportedEffectToggles = <String>[
    'randomEntryColors',
    'rainbowText',
    'marqueeText',
    'breathingEffect',
    'flowingEffect',
  ];

  static const AppearanceConfig defaults = AppearanceConfig();

  final String theme;
  final bool compactLayout;
  final bool highContrastText;
  final bool enhancedBackground;
  final bool frostedPanels;
  final double gradientIntensity;
  final double effectIntensity;
  final double sidebarOpacity;
  final double detailOpacity;
  final double playbackOpacity;
  final double fieldOpacity;
  final bool fieldGradientAccent;
  final bool fieldGlow;
  final bool playbackGlow;
  final String pageBackgroundHex;
  final String backgroundGradientStartHex;
  final String backgroundGradientEndHex;
  final String sidebarColorHex;
  final String detailColorHex;
  final String playbackColorHex;
  final String fieldColorHex;
  final String borderColorHex;
  final String accentColorHex;
  final String backgroundImagePath;
  final String backgroundImageMode;
  final double backgroundImageOpacity;
  final String fontFamilyKey;
  final double fontScale;
  final String titleWeightKey;
  final String bodyWeightKey;
  final bool randomEntryColors;
  final bool rainbowText;
  final bool marqueeText;
  final bool breathingEffect;
  final bool flowingEffect;

  double _clamp01(double value, {double fallback = 0.5}) {
    final normalized = value.isFinite ? value : fallback;
    if (normalized < 0) return 0;
    if (normalized > 1) return 1;
    return normalized;
  }

  double get normalizedGradientIntensity =>
      _clamp01(gradientIntensity, fallback: defaults.gradientIntensity);

  double get normalizedEffectIntensity =>
      _clamp01(effectIntensity, fallback: defaults.effectIntensity);

  double get normalizedSidebarOpacity =>
      _clamp01(sidebarOpacity, fallback: defaults.sidebarOpacity);

  double get normalizedDetailOpacity =>
      _clamp01(detailOpacity, fallback: defaults.detailOpacity);

  double get normalizedPlaybackOpacity =>
      _clamp01(playbackOpacity, fallback: defaults.playbackOpacity);

  double get normalizedFieldOpacity =>
      _clamp01(fieldOpacity, fallback: defaults.fieldOpacity);

  double get normalizedBackgroundImageOpacity => _clamp01(
    backgroundImageOpacity,
    fallback: defaults.backgroundImageOpacity,
  );

  double get normalizedFontScale {
    final value = fontScale.isFinite ? fontScale : defaults.fontScale;
    return value.clamp(0.85, 1.45).toDouble();
  }

  String get normalizedTheme {
    final value = theme.trim().toLowerCase();
    if (supportedThemes.contains(value)) return value;
    return defaults.theme;
  }

  String get normalizedBackgroundImageMode {
    final value = backgroundImageMode.trim().toLowerCase();
    if (supportedBackgroundImageModes.contains(value)) return value;
    return defaults.backgroundImageMode;
  }

  String get normalizedFontFamilyKey {
    final value = fontFamilyKey.trim().toLowerCase();
    if (supportedFontFamilyKeys.contains(value)) return value;
    return defaults.fontFamilyKey;
  }

  String get normalizedTitleWeightKey {
    final value = titleWeightKey.trim().toLowerCase();
    if (supportedFontWeightKeys.contains(value)) return value;
    return defaults.titleWeightKey;
  }

  String get normalizedBodyWeightKey {
    final value = bodyWeightKey.trim().toLowerCase();
    if (supportedFontWeightKeys.contains(value)) return value;
    return defaults.bodyWeightKey;
  }

  AppearanceConfig copyWith({
    String? theme,
    bool? compactLayout,
    bool? highContrastText,
    bool? enhancedBackground,
    bool? frostedPanels,
    double? gradientIntensity,
    double? effectIntensity,
    double? sidebarOpacity,
    double? detailOpacity,
    double? playbackOpacity,
    double? fieldOpacity,
    bool? fieldGradientAccent,
    bool? fieldGlow,
    bool? playbackGlow,
    String? pageBackgroundHex,
    String? backgroundGradientStartHex,
    String? backgroundGradientEndHex,
    String? sidebarColorHex,
    String? detailColorHex,
    String? playbackColorHex,
    String? fieldColorHex,
    String? borderColorHex,
    String? accentColorHex,
    String? backgroundImagePath,
    String? backgroundImageMode,
    double? backgroundImageOpacity,
    String? fontFamilyKey,
    double? fontScale,
    String? titleWeightKey,
    String? bodyWeightKey,
    bool? randomEntryColors,
    bool? rainbowText,
    bool? marqueeText,
    bool? breathingEffect,
    bool? flowingEffect,
  }) {
    return AppearanceConfig(
      theme: theme ?? this.theme,
      compactLayout: compactLayout ?? this.compactLayout,
      highContrastText: highContrastText ?? this.highContrastText,
      enhancedBackground: enhancedBackground ?? this.enhancedBackground,
      frostedPanels: frostedPanels ?? this.frostedPanels,
      gradientIntensity: gradientIntensity ?? this.gradientIntensity,
      effectIntensity: effectIntensity ?? this.effectIntensity,
      sidebarOpacity: sidebarOpacity ?? this.sidebarOpacity,
      detailOpacity: detailOpacity ?? this.detailOpacity,
      playbackOpacity: playbackOpacity ?? this.playbackOpacity,
      fieldOpacity: fieldOpacity ?? this.fieldOpacity,
      fieldGradientAccent: fieldGradientAccent ?? this.fieldGradientAccent,
      fieldGlow: fieldGlow ?? this.fieldGlow,
      playbackGlow: playbackGlow ?? this.playbackGlow,
      pageBackgroundHex: pageBackgroundHex ?? this.pageBackgroundHex,
      backgroundGradientStartHex:
          backgroundGradientStartHex ?? this.backgroundGradientStartHex,
      backgroundGradientEndHex:
          backgroundGradientEndHex ?? this.backgroundGradientEndHex,
      sidebarColorHex: sidebarColorHex ?? this.sidebarColorHex,
      detailColorHex: detailColorHex ?? this.detailColorHex,
      playbackColorHex: playbackColorHex ?? this.playbackColorHex,
      fieldColorHex: fieldColorHex ?? this.fieldColorHex,
      borderColorHex: borderColorHex ?? this.borderColorHex,
      accentColorHex: accentColorHex ?? this.accentColorHex,
      backgroundImagePath: backgroundImagePath ?? this.backgroundImagePath,
      backgroundImageMode: backgroundImageMode ?? this.backgroundImageMode,
      backgroundImageOpacity:
          backgroundImageOpacity ?? this.backgroundImageOpacity,
      fontFamilyKey: fontFamilyKey ?? this.fontFamilyKey,
      fontScale: fontScale ?? this.fontScale,
      titleWeightKey: titleWeightKey ?? this.titleWeightKey,
      bodyWeightKey: bodyWeightKey ?? this.bodyWeightKey,
      randomEntryColors: randomEntryColors ?? this.randomEntryColors,
      rainbowText: rainbowText ?? this.rainbowText,
      marqueeText: marqueeText ?? this.marqueeText,
      breathingEffect: breathingEffect ?? this.breathingEffect,
      flowingEffect: flowingEffect ?? this.flowingEffect,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'theme': normalizedTheme,
    'compactLayout': compactLayout,
    'highContrastText': highContrastText,
    'enhancedBackground': enhancedBackground,
    'frostedPanels': frostedPanels,
    'gradientIntensity': normalizedGradientIntensity,
    'effectIntensity': normalizedEffectIntensity,
    'sidebarOpacity': normalizedSidebarOpacity,
    'detailOpacity': normalizedDetailOpacity,
    'playbackOpacity': normalizedPlaybackOpacity,
    'fieldOpacity': normalizedFieldOpacity,
    'fieldGradientAccent': fieldGradientAccent,
    'fieldGlow': fieldGlow,
    'playbackGlow': playbackGlow,
    'pageBackgroundHex': pageBackgroundHex,
    'backgroundGradientStartHex': backgroundGradientStartHex,
    'backgroundGradientEndHex': backgroundGradientEndHex,
    'sidebarColorHex': sidebarColorHex,
    'detailColorHex': detailColorHex,
    'playbackColorHex': playbackColorHex,
    'fieldColorHex': fieldColorHex,
    'borderColorHex': borderColorHex,
    'accentColorHex': accentColorHex,
    'backgroundImagePath': backgroundImagePath,
    'backgroundImageMode': normalizedBackgroundImageMode,
    'backgroundImageOpacity': normalizedBackgroundImageOpacity,
    'fontFamilyKey': normalizedFontFamilyKey,
    'fontScale': normalizedFontScale,
    'titleWeightKey': normalizedTitleWeightKey,
    'bodyWeightKey': normalizedBodyWeightKey,
    'randomEntryColors': randomEntryColors,
    'rainbowText': rainbowText,
    'marqueeText': marqueeText,
    'breathingEffect': breathingEffect,
    'flowingEffect': flowingEffect,
  };

  factory AppearanceConfig.fromJson(Map<String, Object?> json) {
    double readDouble(String key, double fallback) {
      return (json[key] as num?)?.toDouble() ?? fallback;
    }

    return AppearanceConfig(
      theme: json['theme']?.toString() ?? defaults.theme,
      compactLayout: json['compactLayout'] as bool? ?? defaults.compactLayout,
      highContrastText:
          json['highContrastText'] as bool? ?? defaults.highContrastText,
      enhancedBackground:
          json['enhancedBackground'] as bool? ?? defaults.enhancedBackground,
      frostedPanels: json['frostedPanels'] as bool? ?? defaults.frostedPanels,
      gradientIntensity: readDouble(
        'gradientIntensity',
        defaults.gradientIntensity,
      ),
      effectIntensity: readDouble('effectIntensity', defaults.effectIntensity),
      sidebarOpacity: readDouble('sidebarOpacity', defaults.sidebarOpacity),
      detailOpacity: readDouble('detailOpacity', defaults.detailOpacity),
      playbackOpacity: readDouble('playbackOpacity', defaults.playbackOpacity),
      fieldOpacity: readDouble('fieldOpacity', defaults.fieldOpacity),
      fieldGradientAccent:
          json['fieldGradientAccent'] as bool? ?? defaults.fieldGradientAccent,
      fieldGlow: json['fieldGlow'] as bool? ?? defaults.fieldGlow,
      playbackGlow: json['playbackGlow'] as bool? ?? defaults.playbackGlow,
      pageBackgroundHex: json['pageBackgroundHex']?.toString() ?? '',
      backgroundGradientStartHex:
          json['backgroundGradientStartHex']?.toString() ?? '',
      backgroundGradientEndHex:
          json['backgroundGradientEndHex']?.toString() ?? '',
      sidebarColorHex: json['sidebarColorHex']?.toString() ?? '',
      detailColorHex: json['detailColorHex']?.toString() ?? '',
      playbackColorHex: json['playbackColorHex']?.toString() ?? '',
      fieldColorHex: json['fieldColorHex']?.toString() ?? '',
      borderColorHex: json['borderColorHex']?.toString() ?? '',
      accentColorHex: json['accentColorHex']?.toString() ?? '',
      backgroundImagePath: json['backgroundImagePath']?.toString() ?? '',
      backgroundImageMode:
          json['backgroundImageMode']?.toString() ??
          defaults.backgroundImageMode,
      backgroundImageOpacity: readDouble(
        'backgroundImageOpacity',
        defaults.backgroundImageOpacity,
      ),
      fontFamilyKey:
          json['fontFamilyKey']?.toString() ?? defaults.fontFamilyKey,
      fontScale: readDouble('fontScale', defaults.fontScale),
      titleWeightKey:
          json['titleWeightKey']?.toString() ?? defaults.titleWeightKey,
      bodyWeightKey:
          json['bodyWeightKey']?.toString() ?? defaults.bodyWeightKey,
      randomEntryColors:
          json['randomEntryColors'] as bool? ?? defaults.randomEntryColors,
      rainbowText: json['rainbowText'] as bool? ?? defaults.rainbowText,
      marqueeText: json['marqueeText'] as bool? ?? defaults.marqueeText,
      breathingEffect:
          json['breathingEffect'] as bool? ?? defaults.breathingEffect,
      flowingEffect: json['flowingEffect'] as bool? ?? defaults.flowingEffect,
    );
  }
}

class AppearanceThemePreset {
  const AppearanceThemePreset({
    required this.id,
    required this.name,
    required this.appearance,
  });

  final String id;
  final String name;
  final AppearanceConfig appearance;

  AppearanceThemePreset copyWith({
    String? id,
    String? name,
    AppearanceConfig? appearance,
  }) {
    return AppearanceThemePreset(
      id: id ?? this.id,
      name: name ?? this.name,
      appearance: appearance ?? this.appearance,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'name': name,
    'appearance': appearance.toJson(),
  };

  factory AppearanceThemePreset.fromJson(Map<String, Object?> json) {
    return AppearanceThemePreset(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      appearance: json['appearance'] is Map
          ? AppearanceConfig.fromJson(
              (json['appearance'] as Map).cast<String, Object?>(),
            )
          : AppearanceConfig.defaults,
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
    this.appearance = AppearanceConfig.defaults,
    this.appearancePresets = const <AppearanceThemePreset>[],
  });

  final Map<String, int> repeats;
  final Map<String, FieldPlaybackSetting> fieldSettings;
  final int overallRepeat;
  final PlayOrder order;
  final TtsConfig tts;
  final AsrConfig asr;
  final bool showText;
  final int delayBetweenUnitsMs;
  final AppearanceConfig appearance;
  final List<AppearanceThemePreset> appearancePresets;

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
    appearance: AppearanceConfig.defaults,
    appearancePresets: const <AppearanceThemePreset>[],
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
    AppearanceConfig? appearance,
    List<AppearanceThemePreset>? appearancePresets,
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
      appearance: appearance ?? this.appearance,
      appearancePresets: List<AppearanceThemePreset>.from(
        appearancePresets ?? this.appearancePresets,
      ),
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
    'appearance': appearance.toJson(),
    'appearancePresets': appearancePresets
        .map((item) => item.toJson())
        .toList(growable: false),
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
    final appearance = json['appearance'] is Map
        ? AppearanceConfig.fromJson(
            (json['appearance'] as Map).cast<String, Object?>(),
          )
        : AppearanceConfig(
            theme: json['appearanceTheme']?.toString() ?? 'flat',
          );
    final appearancePresets = <AppearanceThemePreset>[];
    final rawAppearancePresets = json['appearancePresets'];
    if (rawAppearancePresets is List) {
      for (final item in rawAppearancePresets) {
        if (item is Map<String, Object?>) {
          final preset = AppearanceThemePreset.fromJson(item);
          if (preset.id.trim().isEmpty || preset.name.trim().isEmpty) continue;
          appearancePresets.add(preset);
          continue;
        }
        if (item is Map) {
          final preset = AppearanceThemePreset.fromJson(
            item.cast<String, Object?>(),
          );
          if (preset.id.trim().isEmpty || preset.name.trim().isEmpty) continue;
          appearancePresets.add(preset);
        }
      }
    }

    return PlayConfig(
      repeats: repeats,
      fieldSettings: settings,
      overallRepeat: (json['overallRepeat'] as num?)?.toInt() ?? 1,
      order: order,
      tts: tts,
      asr: asr,
      showText: json['showText'] as bool? ?? true,
      delayBetweenUnitsMs: (json['delayBetweenUnits'] as num?)?.toInt() ?? 500,
      appearance: appearance,
      appearancePresets: appearancePresets,
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
