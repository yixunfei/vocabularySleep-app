import 'package:flutter/material.dart';

import '../i18n/app_i18n.dart';
import '../models/app_home_tab.dart';
import '../models/focus_startup_tab.dart';
import '../models/play_config.dart';
import '../models/word_field.dart';
import '../services/ambient_service.dart';
import '../state/app_state.dart';
import 'theme/app_theme.dart';

String pickUiText(
  AppI18n i18n, {
  required String zh,
  required String en,
  String? ja,
  String? de,
  String? fr,
  String? es,
  String? ru,
}) {
  return switch (AppI18n.normalizeLanguageCode(i18n.languageCode)) {
    'zh' => zh,
    'ja' => ja ?? en,
    'de' => de ?? en,
    'fr' => fr ?? en,
    'es' => es ?? en,
    'ru' => ru ?? en,
    _ => en,
  };
}

String experienceModeTitle(AppI18n i18n, AppExperienceMode mode) {
  return switch (mode) {
    AppExperienceMode.sleep => pickUiText(
      i18n,
      zh: '助眠',
      en: 'Sleep',
      ja: '睡眠',
      de: 'Schlaf',
      fr: 'Sommeil',
      es: 'Sueño',
      ru: 'Сон',
    ),
    AppExperienceMode.focus => pickUiText(
      i18n,
      zh: '专注',
      en: 'Focus',
      ja: '集中',
      de: 'Fokus',
      fr: 'Concentration',
      es: 'Enfoque',
      ru: 'Фокус',
    ),
  };
}

String experienceModeDescription(AppI18n i18n, AppExperienceMode mode) {
  return switch (mode) {
    AppExperienceMode.sleep => pickUiText(
      i18n,
      zh: '更柔和的视觉与环境音，帮助放松和入睡。',
      en: 'Calmer visuals centered on playback and ambient sound.',
      ja: '再生と環境音を中心にした、より落ち着いた体験です。',
      de: 'Ruhigere Darstellung mit Fokus auf Wiedergabe und Umgebungsgeräusche.',
      fr: 'Une expérience plus apaisée autour de la lecture et de l’audio ambiant.',
      es: 'Una experiencia más calmada centrada en reproducción y audio ambiental.',
      ru: 'Более спокойный режим с упором на воспроизведение и фоновые звуки.',
    ),
    AppExperienceMode.focus => pickUiText(
      i18n,
      zh: '更高的信息密度，适合搜索、浏览与练习。',
      en: 'Sharper information density for search, browsing, and practice.',
      ja: '検索・閲覧・練習向けの高密度レイアウトです。',
      de: 'Höhere Informationsdichte für Suche, Lesen und Üben.',
      fr: 'Une densité d’information plus forte pour chercher, parcourir et pratiquer.',
      es: 'Más densidad de información para buscar, navegar y practicar.',
      ru: 'Более плотный интерфейс для поиска, просмотра и тренировки.',
    ),
  };
}

String playOrderLabel(AppI18n i18n, PlayOrder order) {
  return switch (order) {
    PlayOrder.sequential => pickUiText(
      i18n,
      zh: '顺序',
      en: 'Sequential',
      ja: '順序',
      de: 'Reihenfolge',
      fr: 'Séquentiel',
      es: 'Secuencial',
      ru: 'По порядку',
    ),
    PlayOrder.random => pickUiText(
      i18n,
      zh: '随机',
      en: 'Shuffle',
      ja: 'シャッフル',
      de: 'Zufällig',
      fr: 'Aléatoire',
      es: 'Aleatorio',
      ru: 'Случайно',
    ),
  };
}

String ttsProviderLabel(AppI18n i18n, TtsProviderType provider) {
  return switch (provider) {
    TtsProviderType.local => i18n.t('local'),
    TtsProviderType.api => i18n.t('siliconFlowApi'),
    TtsProviderType.customApi => i18n.t('customApi'),
  };
}

String asrProviderLabel(AppI18n i18n, AsrProviderType provider) {
  return switch (provider) {
    AsrProviderType.api => i18n.t('siliconFlowApi'),
    AsrProviderType.customApi => i18n.t('customApi'),
    AsrProviderType.offline => i18n.t('offlineWhisperBase'),
    AsrProviderType.offlineSmall => i18n.t('offlineWhisperSmall'),
    AsrProviderType.localSimilarity => i18n.t('asrLocalSimilarity'),
    AsrProviderType.multiEngine => i18n.t('asrMultiEngine'),
  };
}

String voiceInputProviderLabel(AppI18n i18n, VoiceInputProviderType provider) {
  return switch (provider) {
    VoiceInputProviderType.api => i18n.t('siliconFlowApi'),
    VoiceInputProviderType.offline => pickUiText(
      i18n,
      zh: '离线引擎',
      en: 'Offline engine',
    ),
    VoiceInputProviderType.system => pickUiText(
      i18n,
      zh: '系统语音识别',
      en: 'System speech recognition',
    ),
  };
}

String searchModeLabel(AppI18n i18n, SearchMode mode) {
  return switch (mode) {
    SearchMode.all => i18n.t('all'),
    SearchMode.word => i18n.t('word'),
    SearchMode.meaning => i18n.t('meaning'),
    SearchMode.fuzzy => i18n.t('fuzzy'),
  };
}

String localizedFieldLabel(AppI18n i18n, WordFieldItem item) {
  final key = normalizeFieldKey(item.key);
  return switch (key) {
    'meaning' => i18n.t('fieldMeaning'),
    'examples' => i18n.t('fieldExamples'),
    'etymology' => i18n.t('fieldEtymology'),
    'roots' => i18n.t('fieldRoots'),
    'affixes' => i18n.t('fieldAffixes'),
    'variations' => i18n.t('fieldVariations'),
    'memory' => i18n.t('fieldMemory'),
    'story' => i18n.t('fieldStory'),
    _ => item.label.trim().isEmpty ? key : item.label.trim(),
  };
}

String localizedAmbientName(AppI18n i18n, AmbientSource source) {
  return switch (source.id) {
    'noise_white' => i18n.t('ambientNameNoiseWhite'),
    'noise_pink' => i18n.t('ambientNameNoisePink'),
    'noise_brown' => i18n.t('ambientNameNoiseBrown'),
    'nature_wind' => i18n.t('ambientNameNatureWind'),
    'nature_forest' => i18n.t('ambientNameNatureForest'),
    'nature_fire' => i18n.t('ambientNameNatureFire'),
    'nature_ocean' => i18n.t('ambientNameNatureOcean'),
    'rain_light' => i18n.t('ambientNameRainLight'),
    'rain_heavy' => i18n.t('ambientNameRainHeavy'),
    'focus_library' => i18n.t('ambientNameFocusLibrary'),
    'focus_cafe' => i18n.t('ambientNameFocusCafe'),
    'focus_night' => i18n.t('ambientNameFocusNightVillage'),
    _ => source.name,
  };
}

String pageLabelPlay(AppI18n i18n) => pickUiText(
  i18n,
  zh: '播放',
  en: 'Play',
  ja: '再生',
  de: 'Wiedergabe',
  fr: 'Lecture',
  es: 'Reproducir',
  ru: 'Воспроизведение',
);

String appHomeTabLabel(AppI18n i18n, AppHomeTab tab) {
  return switch (tab) {
    AppHomeTab.play => pageLabelPlay(i18n),
    AppHomeTab.library => pageLabelLibrary(i18n),
    AppHomeTab.practice => pageLabelPractice(i18n),
    AppHomeTab.focus => pageLabelFocus(i18n),
    AppHomeTab.more => pageLabelMore(i18n),
  };
}

String focusStartupTabLabel(AppI18n i18n, FocusStartupTab tab) {
  return switch (tab) {
    FocusStartupTab.timer => i18n.t('timerTab'),
    FocusStartupTab.todo => i18n.t('todoTab'),
  };
}

String weatherCodeLabel(AppI18n i18n, int weatherCode, {required bool isDay}) {
  if (weatherCode == 0) {
    return pickUiText(
      i18n,
      zh: isDay ? '晴朗' : '晴夜',
      en: isDay ? 'Clear' : 'Clear night',
    );
  }
  if (weatherCode == 1 || weatherCode == 2) {
    return pickUiText(i18n, zh: '多云间晴', en: 'Partly cloudy');
  }
  if (weatherCode == 3) {
    return pickUiText(i18n, zh: '阴天', en: 'Overcast');
  }
  if (weatherCode == 45 || weatherCode == 48) {
    return pickUiText(i18n, zh: '有雾', en: 'Foggy');
  }
  if (<int>{51, 53, 55, 56, 57}.contains(weatherCode)) {
    return pickUiText(i18n, zh: '毛毛雨', en: 'Drizzle');
  }
  if (<int>{61, 63, 65, 66, 67, 80, 81, 82}.contains(weatherCode)) {
    return pickUiText(i18n, zh: '下雨', en: 'Rain');
  }
  if (<int>{71, 73, 75, 77, 85, 86}.contains(weatherCode)) {
    return pickUiText(i18n, zh: '下雪', en: 'Snow');
  }
  if (<int>{95, 96, 99}.contains(weatherCode)) {
    return pickUiText(i18n, zh: '雷暴', en: 'Thunderstorm');
  }
  return pickUiText(i18n, zh: '天气变化', en: 'Changeable');
}

IconData weatherCodeIcon(int weatherCode, {required bool isDay}) {
  if (weatherCode == 0) {
    return isDay ? Icons.wb_sunny_rounded : Icons.nightlight_round;
  }
  if (weatherCode == 1 || weatherCode == 2) {
    return Icons.cloud_queue_rounded;
  }
  if (weatherCode == 3) {
    return Icons.cloud_rounded;
  }
  if (weatherCode == 45 || weatherCode == 48) {
    return Icons.blur_on_rounded;
  }
  if (<int>{
    51,
    53,
    55,
    56,
    57,
    61,
    63,
    65,
    66,
    67,
    80,
    81,
    82,
  }.contains(weatherCode)) {
    return Icons.water_drop_rounded;
  }
  if (<int>{71, 73, 75, 77, 85, 86}.contains(weatherCode)) {
    return Icons.ac_unit_rounded;
  }
  if (<int>{95, 96, 99}.contains(weatherCode)) {
    return Icons.thunderstorm_rounded;
  }
  return Icons.cloud_sync_rounded;
}

String pageLabelLibrary(AppI18n i18n) => pickUiText(
  i18n,
  zh: '词库',
  en: 'Library',
  ja: '単語帳',
  de: 'Bibliothek',
  fr: 'Bibliothèque',
  es: 'Biblioteca',
  ru: 'Словарь',
);

String pageLabelPractice(AppI18n i18n) => pickUiText(
  i18n,
  zh: '练习',
  en: 'Practice',
  ja: '練習',
  de: 'Üben',
  fr: 'Pratique',
  es: 'Práctica',
  ru: 'Практика',
);

String pageLabelFocus(AppI18n i18n) => i18n.t('focusTitle');

String pageLabelMore(AppI18n i18n) => pickUiText(
  i18n,
  zh: '更多',
  en: 'More',
  ja: 'その他',
  de: 'Mehr',
  fr: 'Plus',
  es: 'Más',
  ru: 'Ещё',
);
