import 'package:flutter/material.dart';

import '../i18n/app_i18n.dart';
import '../models/app_home_tab.dart';
import '../models/focus_startup_tab.dart';
import '../models/play_config.dart';
import '../models/study_startup_tab.dart';
import '../models/word_field.dart';
import '../services/ambient_service.dart';
import '../services/online_ambient_catalog_service.dart';
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
  final moodistKey = _moodistTranslationKeyForSource(source);
  if (moodistKey != null) {
    return localizedOnlineAmbientName(
      i18n,
      relativePath: moodistKey,
      fallbackName: source.name,
    );
  }
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

String localizedOnlineAmbientName(
  AppI18n i18n, {
  required String relativePath,
  required String fallbackName,
}) {
  if (AppI18n.normalizeLanguageCode(i18n.languageCode) != 'zh') {
    return fallbackName;
  }
  final normalizedKey = relativePath
      .replaceAll('\\', '/')
      .replaceFirst(RegExp(r'\.(mp3|wav)$'), '');
  return _moodistZhNames[normalizedKey] ?? fallbackName;
}

String localizedOnlineAmbientOptionName(
  AppI18n i18n,
  OnlineAmbientSoundOption option,
) {
  return localizedOnlineAmbientName(
    i18n,
    relativePath: option.relativePath,
    fallbackName: option.name,
  );
}

String? _moodistTranslationKeyForSource(AmbientSource source) {
  String? buildFromId(String prefix) {
    if (!source.id.startsWith(prefix)) {
      return null;
    }
    final payload = source.id.substring(prefix.length);
    final separator = payload.indexOf('_');
    if (separator <= 0 || separator >= payload.length - 1) {
      return null;
    }
    final category = payload.substring(0, separator);
    final slug = payload.substring(separator + 1);
    return '$category/$slug';
  }

  final remote = buildFromId('remote_moodist_');
  if (remote != null) {
    return remote;
  }
  final downloaded = buildFromId('downloaded_remote_moodist_');
  if (downloaded != null) {
    return downloaded;
  }
  return null;
}

const Map<String, String> _moodistZhNames = <String, String>{
  'nature/river': '河流',
  'nature/waves': '海浪',
  'nature/campfire': '篝火',
  'nature/wind': '风声',
  'nature/howling-wind': '呼啸狂风',
  'nature/wind-in-trees': '林间风声',
  'nature/waterfall': '瀑布',
  'nature/walk-in-snow': '雪地行走',
  'nature/walk-on-leaves': '落叶脚步',
  'nature/walk-on-gravel': '砂石脚步',
  'nature/droplets': '水滴',
  'nature/jungle': '丛林',
  'rain/light-rain': '小雨',
  'rain/heavy-rain': '大雨',
  'rain/thunder': '雷声',
  'rain/rain-on-window': '雨打窗户',
  'rain/rain-on-car-roof': '雨打车顶',
  'rain/rain-on-umbrella': '雨打雨伞',
  'rain/rain-on-tent': '雨打帐篷',
  'rain/rain-on-leaves': '雨打树叶',
  'animals/birds': '鸟鸣',
  'animals/seagulls': '海鸥',
  'animals/beehive': '蜂巢',
  'animals/cows': '奶牛',
  'animals/sheep': '绵羊',
  'animals/crickets': '蟋蟀',
  'animals/crows': '乌鸦',
  'animals/frog': '青蛙',
  'animals/owl': '猫头鹰',
  'animals/whale': '鲸鸣',
  'animals/wolf': '狼嚎',
  'animals/chickens': '鸡群',
  'animals/cat-purring': '猫咪呼噜',
  'animals/dog-barking': '狗吠',
  'animals/horse-gallop': '马蹄奔跑',
  'animals/woodpecker': '啄木鸟',
  'urban/crowd': '人群',
  'urban/fireworks': '烟花',
  'urban/busy-street': '繁忙街道',
  'urban/highway': '高速公路',
  'urban/ambulance-siren': '救护车警笛',
  'urban/road': '道路',
  'urban/traffic': '交通车流',
  'places/church': '教堂',
  'places/restaurant': '餐厅',
  'places/airport': '机场',
  'places/office': '办公室',
  'places/subway-station': '地铁站',
  'places/temple': '寺庙',
  'places/library': '图书馆',
  'places/carousel': '旋转木马',
  'places/supermarket': '超市',
  'places/laundry-room': '洗衣房',
  'places/construction-site': '工地',
  'places/crowded-bar': '拥挤酒吧',
  'places/cafe': '咖啡馆',
  'places/laboratory': '实验室',
  'places/underwater': '水下',
  'transport/inside-a-train': '车厢内部',
  'transport/rowing-boat': '划船',
  'transport/airplane': '飞机',
  'transport/sailboat': '帆船',
  'transport/train': '火车',
  'transport/submarine': '潜艇',
  'things/keyboard': '键盘',
  'things/typewriter': '打字机',
  'things/paper': '纸张',
  'things/clock': '时钟',
  'things/wind-chimes': '风铃',
  'things/singing-bowl': '颂钵',
  'things/ceiling-fan': '吊扇',
  'things/dryer': '烘干机',
  'things/slide-projector': '幻灯机',
  'things/boiling-water': '沸水',
  'things/bubbles': '气泡',
  'things/tuning-radio': '调频收音机',
  'things/morse-code': '摩斯电码',
  'things/washing-machine': '洗衣机',
  'things/vinyl-effect': '黑胶唱片',
  'things/windshield-wipers': '雨刷',
  'noise/white-noise': '白噪音',
  'noise/pink-noise': '粉红噪音',
  'noise/brown-noise': '棕噪音',
  'binaural/binaural-alpha': '双耳节拍 Alpha',
  'binaural/binaural-beta': '双耳节拍 Beta',
  'binaural/binaural-delta': '双耳节拍 Delta',
  'binaural/binaural-gamma': '双耳节拍 Gamma',
  'binaural/binaural-theta': '双耳节拍 Theta',
};

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

String pageLabelStudy(AppI18n i18n) => pickUiText(
  i18n,
  zh: '学习',
  en: 'Study',
  ja: '学習',
  de: 'Lernen',
  fr: 'Étude',
  es: 'Estudio',
  ru: 'Учёба',
);

String appHomeTabLabel(AppI18n i18n, AppHomeTab tab) {
  return switch (tab) {
    AppHomeTab.study => pageLabelStudy(i18n),
    AppHomeTab.practice => pageLabelPractice(i18n),
    AppHomeTab.focus => pageLabelFocus(i18n),
    AppHomeTab.toolbox => pageLabelToolbox(i18n),
    AppHomeTab.more => pageLabelMore(i18n),
  };
}

String studyStartupTabLabel(AppI18n i18n, StudyStartupTab tab) {
  return switch (tab) {
    StudyStartupTab.play => pageLabelPlay(i18n),
    StudyStartupTab.library => pageLabelLibrary(i18n),
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

String pageLabelToolbox(AppI18n i18n) => pickUiText(
  i18n,
  zh: '工具箱',
  en: 'Toolbox',
  ja: 'ツール',
  de: 'Werkzeuge',
  fr: 'Outils',
  es: 'Caja',
  ru: 'Инструменты',
);
