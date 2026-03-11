import '../i18n/app_i18n.dart';
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
}) {
  return switch (AppI18n.normalizeLanguageCode(i18n.languageCode)) {
    'zh' => zh,
    'ja' => ja ?? en,
    'de' => de ?? en,
    'fr' => fr ?? en,
    'es' => es ?? en,
    _ => en,
  };
}

String experienceModeTitle(AppI18n i18n, AppExperienceMode mode) {
  return switch (mode) {
    AppExperienceMode.sleep => pickUiText(
      i18n,
      zh: '助眠',
      en: 'Sleep',
      ja: 'スリープ',
      de: 'Schlaf',
      fr: 'Sommeil',
      es: 'Sueño',
    ),
    AppExperienceMode.focus => pickUiText(
      i18n,
      zh: '专注',
      en: 'Focus',
      ja: '集中',
      de: 'Fokus',
      fr: 'Concentration',
      es: 'Enfoque',
    ),
  };
}

String experienceModeDescription(AppI18n i18n, AppExperienceMode mode) {
  return switch (mode) {
    AppExperienceMode.sleep => pickUiText(
      i18n,
      zh: '降低刺激，围绕持续播放与环境音设计',
      en: 'Calmer visuals centered on playback and ambient sound.',
    ),
    AppExperienceMode.focus => pickUiText(
      i18n,
      zh: '提升信息效率，围绕搜索、浏览与练习设计',
      en: 'Sharper information density for search, browsing, and practice.',
    ),
  };
}

String playOrderLabel(AppI18n i18n, PlayOrder order) {
  return switch (order) {
    PlayOrder.sequential => pickUiText(i18n, zh: '顺序', en: 'Sequential'),
    PlayOrder.random => pickUiText(i18n, zh: '随机', en: 'Shuffle'),
  };
}

String ttsProviderLabel(AppI18n i18n, TtsProviderType provider) {
  return switch (provider) {
    TtsProviderType.local => pickUiText(i18n, zh: '本地语音', en: 'Local'),
    TtsProviderType.api => pickUiText(
      i18n,
      zh: '硅基流动 API',
      en: 'SiliconFlow API',
    ),
    TtsProviderType.customApi => pickUiText(
      i18n,
      zh: '自定义 API',
      en: 'Custom API',
    ),
  };
}

String asrProviderLabel(AppI18n i18n, AsrProviderType provider) {
  return switch (provider) {
    AsrProviderType.api => pickUiText(
      i18n,
      zh: '硅基流动 API',
      en: 'SiliconFlow API',
    ),
    AsrProviderType.customApi => pickUiText(
      i18n,
      zh: '自定义 API',
      en: 'Custom API',
    ),
    AsrProviderType.offline => pickUiText(
      i18n,
      zh: '离线识别（Whisper Base）',
      en: 'Offline (Whisper Base)',
    ),
    AsrProviderType.offlineSmall => pickUiText(
      i18n,
      zh: '离线识别（Whisper Small）',
      en: 'Offline (Whisper Small)',
    ),
    AsrProviderType.localSimilarity => pickUiText(
      i18n,
      zh: '本地相似度（无转写）',
      en: 'Local Similarity (No ASR)',
    ),
    AsrProviderType.multiEngine => pickUiText(
      i18n,
      zh: '多引擎模式',
      en: 'Multi-Engine',
    ),
  };
}

String searchModeLabel(AppI18n i18n, SearchMode mode) {
  return switch (mode) {
    SearchMode.all => pickUiText(i18n, zh: '全部', en: 'All'),
    SearchMode.word => pickUiText(i18n, zh: '单词', en: 'Word'),
    SearchMode.meaning => pickUiText(i18n, zh: '释义', en: 'Meaning'),
    SearchMode.fuzzy => pickUiText(i18n, zh: '模糊', en: 'Fuzzy'),
  };
}

String localizedFieldLabel(AppI18n i18n, WordFieldItem item) {
  final key = normalizeFieldKey(item.key);
  return switch (key) {
    'meaning' => pickUiText(i18n, zh: '释义', en: 'Meaning'),
    'examples' => pickUiText(i18n, zh: '例句', en: 'Examples'),
    'etymology' => pickUiText(i18n, zh: '词源', en: 'Etymology'),
    'roots' => pickUiText(i18n, zh: '词根', en: 'Roots'),
    'affixes' => pickUiText(i18n, zh: '词缀', en: 'Affixes'),
    'variations' => pickUiText(i18n, zh: '变形', en: 'Variations'),
    'memory' => pickUiText(i18n, zh: '记忆法', en: 'Memory'),
    'story' => pickUiText(i18n, zh: '故事', en: 'Story'),
    _ => item.label.trim().isEmpty ? key : item.label.trim(),
  };
}

String localizedAmbientName(AppI18n i18n, AmbientSource source) {
  return switch (source.id) {
    'noise_white' => pickUiText(i18n, zh: '白噪音', en: 'White Noise'),
    'noise_pink' => pickUiText(i18n, zh: '粉噪音', en: 'Pink Noise'),
    'noise_brown' => pickUiText(i18n, zh: '棕噪音', en: 'Brown Noise'),
    'nature_wind' => pickUiText(i18n, zh: '风声', en: 'Wind'),
    'nature_forest' => pickUiText(i18n, zh: '林间风', en: 'Wind in Trees'),
    'nature_fire' => pickUiText(i18n, zh: '篝火', en: 'Campfire'),
    'nature_ocean' => pickUiText(i18n, zh: '海浪', en: 'Waves'),
    'rain_light' => pickUiText(i18n, zh: '小雨', en: 'Light Rain'),
    'rain_heavy' => pickUiText(i18n, zh: '大雨', en: 'Heavy Rain'),
    'focus_library' => pickUiText(i18n, zh: '图书馆', en: 'Library'),
    'focus_cafe' => pickUiText(i18n, zh: '咖啡馆', en: 'Cafe'),
    'focus_night' => pickUiText(i18n, zh: '夜村', en: 'Night Village'),
    _ => source.name,
  };
}

String pageLabelPlay(AppI18n i18n) => pickUiText(i18n, zh: '播放', en: 'Play');

String pageLabelLibrary(AppI18n i18n) =>
    pickUiText(i18n, zh: '词库', en: 'Library');

String pageLabelPractice(AppI18n i18n) =>
    pickUiText(i18n, zh: '练习', en: 'Practice');

String pageLabelMore(AppI18n i18n) => pickUiText(i18n, zh: '更多', en: 'More');
