import '../i18n/app_i18n.dart';
import '../models/play_config.dart';
import '../models/word_field.dart';
import '../services/ambient_service.dart';
import '../state/app_state.dart';
import 'theme/app_theme.dart';

const Map<String, String> _legacyZhExactTextFixes = <String, String>{
  '瑜版挸澧犻懠鍐ㄦ纯娴兼俺鐦?': '当前范围会话',
  '鐠佹澘绻傛潪锕備壕': '记忆轨道',
  '閹跺﹥婀版潪顔剧矊娑旂姷绮ㄩ弸婊冨瀻閹存劏鈧粌鍑＄拋棰佺秶閳ユ繂鎷伴垾婊冪窡閸旂姴宸遍垾婵呰⒈閺壜ゅ缓闁搫绱濇稉瀣╃濮濄儴绻涚紒顓犵矊娴犫偓娑斿牅绱伴弴瀛樼閺呰埇鈧?':
      '把每次练习结果分成“已记住”和“待加强”两条轨道，下一步练什么会更清晰。',
  '娴犲﹥妫╁鑼额唶娴?': '今日已记住',
  '娴犲﹥妫╁鍛瀵?': '今日待加强',
  '缁嬪啿鐣鹃梼鐔峰灙': '稳定队列',
  '閹垹顦查梼鐔峰灙': '恢复队列',
  '缁嬪啿鐣炬潪锕備壕': '稳定轨道',
  '閹跺﹤鍑＄拋棰佺秶閻ㄥ嫬宕熺拠宥呭晙閸嬫矮绔存潪顕嗙礉娣囨繃瀵旈崶鐐茬箓闁喎瀹抽崪灞藉絺闂婂磭菙鐎规碍鈧佲偓?':
      '把已记住的单词再练一轮，保持回忆速度和发音稳定性。',
  '鐎瑰本鍨氭稉鈧▎锛勭矊娑旂姴鎮楅敍灞藉嚒鐠侀缍囬惃鍕礋鐠囧秳绱伴崷銊ㄧ箹闁插瞼袧缁鳖垬鈧?': '完成一轮练习后，已记住的单词会沉淀到这里。',
  '婢跺秳绡勫鑼额唶娴?': '复习已记住',
  '閸忓牆鐣幋鎰鏉?': '先完成一轮',
  '瀹歌尪顔囨担蹇撳礋鐠囧秴顦叉稊?': '已记住单词复习',
  '閹垹顦叉潪锕備壕': '恢复轨道',
  '閹跺﹨鏉藉杈槤娑撳簼鎹㈤崝陇鐦濋崥鍫濊嫙婢跺秳绡勯敍灞藉帥閹跺﹤鐨绘稉宥嚽旂€规氨娈戦崡鏇＄槤閹峰娲栭弶銉ｂ偓?':
      '把薄弱词和任务词合并复习，优先补齐还不稳定的词。',
  '鏉╂瑩鍣锋导姘箽閻ｆ瑦鐥呯拋棰佺秶閻ㄥ嫬宕熺拠宥忕礉閸氬酣娼伴崣顖欎簰闂嗗棔鑵戦幁銏狀槻閵?': '没记住的单词会留在这里，后续可以集中恢复。',
  '瀵偓婵浠径宥咁槻娑?': '开始恢复复习',
  '閸忓牆绱戞慨瀣矊娑?': '先开始练习',
  '鏉╂ɑ鐥呴張澶婂礋鐠?': '还没有单词',
  '褰撳墠鑼冨洿鍐呮病鏈夊彲缁冧範鍗曡瘝銆?': '当前范围内没有可练习单词。',
  '鏈疆瀹屾垚': '本轮完成',
  '浣犲凡瀹屾垚鏈缁冧範浼氳瘽銆?': '你已完成本次练习会话。',
  '瀹歌尪顔囨担蹇曟畱鐠?': '已记住单词',
  '钖勫急璇?': '薄弱词',
  '鍐嶆潵涓€杞?': '再来一轮',
  '閸愬秶绮屽鑼额唶娴ｅ繒娈戠拠?': '复习已记住',
  '澶嶄範钖勫急璇?': '复习薄弱词',
  '缁撴潫浼氳瘽': '结束会话',
  '鐜闊?': '背景音',
  '鍦ㄦ挱鏀鹃〉淇濇寔浣庡共鎵般€佸彲鍗曟墜璋冭妭': '在任意页面快速调节背景音，不占用当前内容空间。',
  '鎬婚煶閲?': '总音量',
  '瀵煎叆鑷畾涔夐煶棰?': '导入自定义音频',
};

String _repairLegacyZhText(String value) {
  final exact = _legacyZhExactTextFixes[value];
  if (exact != null) return exact;

  final scopeWordsMatch = RegExp(r'^閸\?(\d+) 娑擃亣鐦\?$').firstMatch(value);
  if (scopeWordsMatch != null) {
    return '共 ${scopeWordsMatch.group(1)} 个词';
  }

  final rememberedWordsMatch = RegExp(
    r'^閸\?(\d+) 娑擃亜鍑＄拋棰佺秶閸楁洝鐦\?$',
  ).firstMatch(value);
  if (rememberedWordsMatch != null) {
    return '共 ${rememberedWordsMatch.group(1)} 个已记住单词';
  }

  final recoveryWordsMatch = RegExp(
    r'^閸\?(\d+) 娑擃亜绶熼崝鐘插繁閸楁洝鐦\?$',
  ).firstMatch(value);
  if (recoveryWordsMatch != null) {
    return '共 ${recoveryWordsMatch.group(1)} 个待加强单词';
  }

  final accuracyMatch = RegExp(r'^姝ｇ‘鐜囷細(\d+)%$').firstMatch(value);
  if (accuracyMatch != null) {
    return '正确率：${accuracyMatch.group(1)}%';
  }

  final summaryMatch = RegExp(
    r'^璁颁綇锛\?(\d+)锛岄渶鍔犲己锛\?(\d+)锛堝叡 (\d+)锛\?$',
  ).firstMatch(value);
  if (summaryMatch != null) {
    return '记住：${summaryMatch.group(1)}，待加强：${summaryMatch.group(2)}（共 ${summaryMatch.group(3)}）';
  }

  return value;
}

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
    'zh' => _repairLegacyZhText(zh),
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
