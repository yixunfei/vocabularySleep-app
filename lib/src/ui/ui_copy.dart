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

String experienceModeTitle(AppI18n i18n, AppExperienceMode mode) {
  return switch (mode) {
    AppExperienceMode.sleep => i18n.t(
      'toolbox.sound.soothing.v2.mode.sleep.title',
    ),
    AppExperienceMode.focus => i18n.t('ambientCategoryFocus'),
  };
}

String experienceModeDescription(AppI18n i18n, AppExperienceMode mode) {
  return switch (mode) {
    AppExperienceMode.sleep => i18n.t(
      'inline.ui.ui_copy.calmer_visuals_centered_on_playback_and_ambient_sound_0c1474',
    ),
    AppExperienceMode.focus => i18n.t(
      'inline.ui.ui_copy.sharper_information_density_for_search_browsing_and_prac_a24f4e',
    ),
  };
}

String playOrderLabel(AppI18n i18n, PlayOrder order) {
  return switch (order) {
    PlayOrder.sequential => i18n.t('inline.ui.ui_copy.sequential_4b7b2d'),
    PlayOrder.random => i18n.t('inline.ui.ui_copy.shuffle_034c48'),
  };
}

String ttsProviderLabel(AppI18n i18n, TtsProviderType provider) {
  return switch (provider) {
    TtsProviderType.local => i18n.t('local'),
    TtsProviderType.api => i18n.t('siliconFlowApi'),
    TtsProviderType.aliyunBailian => i18n.t('speech.remote.provider.aliyun'),
    TtsProviderType.doubao => i18n.t('speech.remote.provider.doubao'),
    TtsProviderType.customApi => i18n.t('customApi'),
  };
}

String asrProviderLabel(AppI18n i18n, AsrProviderType provider) {
  return switch (provider) {
    AsrProviderType.api => i18n.t('siliconFlowApi'),
    AsrProviderType.aliyunBailian => i18n.t('speech.remote.provider.aliyun'),
    AsrProviderType.doubao => i18n.t('speech.remote.provider.doubao'),
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
    VoiceInputProviderType.aliyunBailian => i18n.t(
      'speech.remote.provider.aliyun',
    ),
    VoiceInputProviderType.doubao => i18n.t('speech.remote.provider.doubao'),
    VoiceInputProviderType.offline => i18n.t(
      'inline.ui.ui_copy.offline_engine_204382',
    ),
    VoiceInputProviderType.system => i18n.t(
      'inline.ui.pages.voice_input_settings_page.system_speech_recognition_4b0cef',
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
    'pronunciations' => i18n.t(
      'inline.ui.pages.playback_advanced_page.pronunciations_de7c4f',
    ),
    'parts_of_speech' => i18n.t(
      'inline.ui.pages.playback_advanced_page.parts_of_speech_b53f33',
    ),
    'examples' => i18n.t('fieldExamples'),
    'collocations' => i18n.t(
      'inline.ui.pages.playback_advanced_page.collocations_d8364a',
    ),
    'usage' => i18n.t('inline.ui.pages.playback_advanced_page.usage_71f840'),
    'confusions' => i18n.t(
      'inline.ui.pages.playback_advanced_page.confusions_75dad4',
    ),
    'etymology' => i18n.t('fieldEtymology'),
    'roots' => i18n.t('fieldRoots'),
    'affixes' => i18n.t('fieldAffixes'),
    'morphology' => i18n.t(
      'inline.ui.pages.playback_advanced_page.morphology_fda537',
    ),
    'variations' => i18n.t('fieldVariations'),
    'memory' => i18n.t('fieldMemory'),
    'culture' => i18n.t(
      'inline.ui.pages.playback_advanced_page.culture_faa85e',
    ),
    'story' => i18n.t('fieldStory'),
    _ => item.label.trim().isEmpty ? key : item.label.trim(),
  };
}

String localizedWordFieldGroupLabel(AppI18n i18n, String groupKey) {
  return switch (groupKey) {
    'core' => i18n.t('inline.ui.ui_copy.core_8a310a'),
    'usage' => i18n.t('inline.ui.pages.playback_advanced_page.usage_71f840'),
    'linguistics' => i18n.t('inline.ui.ui_copy.linguistics_a67ea5'),
    'memory' => i18n.t('fieldMemory'),
    _ => i18n.t('inline.ui.ui_copy.other_fields_0eb180'),
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
  final remoteKey = source.remoteKey?.replaceAll('\\', '/').trim();
  if (remoteKey != null &&
      remoteKey.isNotEmpty &&
      remoteKey.startsWith('ambient/moodist/')) {
    return remoteKey.substring('ambient/moodist/'.length);
  }

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

  final remote = buildFromId('ambient_');
  if (remote != null) {
    return remote;
  }
  final downloaded = buildFromId('downloaded_ambient_');
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
  'binaural/binaural-alpha': '双耳节拍 Alpha',
  'binaural/binaural-beta': '双耳节拍 Beta',
  'binaural/binaural-delta': '双耳节拍 Delta',
  'binaural/binaural-gamma': '双耳节拍 Gamma',
  'binaural/binaural-theta': '双耳节拍 Theta',
};

String pageLabelPlay(AppI18n i18n) => i18n.t('play');

String pageLabelStudy(AppI18n i18n) =>
    i18n.t('toolbox.sound.soothing.v2.mode.study.title');

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
    return i18n.t(
      isDay ? 'weather.condition.clear.day' : 'weather.condition.clear.night',
    );
  }
  if (weatherCode == 1 || weatherCode == 2) {
    return i18n.t('inline.ui.ui_copy.partly_cloudy_f3f0f7');
  }
  if (weatherCode == 3) {
    return i18n.t('inline.ui.ui_copy.overcast_f0fac7');
  }
  if (weatherCode == 45 || weatherCode == 48) {
    return i18n.t('inline.ui.ui_copy.foggy_3cb7a7');
  }
  if (<int>{51, 53, 55, 56, 57}.contains(weatherCode)) {
    return i18n.t('inline.ui.ui_copy.drizzle_8fa37d');
  }
  if (<int>{61, 63, 65, 66, 67, 80, 81, 82}.contains(weatherCode)) {
    return i18n.t('ambientCategoryRain');
  }
  if (<int>{71, 73, 75, 77, 85, 86}.contains(weatherCode)) {
    return i18n.t('inline.ui.ui_copy.snow_b0ef6c');
  }
  if (<int>{95, 96, 99}.contains(weatherCode)) {
    return i18n.t('inline.ui.ui_copy.thunderstorm_e9506c');
  }
  return i18n.t('inline.ui.ui_copy.changeable_725ceb');
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

String pageLabelLibrary(AppI18n i18n) =>
    i18n.t('inline.ui.ui_copy.library_304d85');

String pageLabelPractice(AppI18n i18n) =>
    i18n.t('inline.ui.module.module_access.practice_edc3b5');

String pageLabelFocus(AppI18n i18n) => i18n.t('focusTitle');

String pageLabelMore(AppI18n i18n) =>
    i18n.t('inline.ui.module.module_access.more_25e68b');

String pageLabelToolbox(AppI18n i18n) => i18n.t('toolbox.hub.page.title');
