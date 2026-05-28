part of '../toolbox_life_tools.dart';

enum _TextTransformCategory {
  phonetic,
  number,
  calendar,
  ganzhi,
  language,
  encode,
  style,
  hidden,
  mojibake,
  codeTable,
}

enum _TextTransformMode {
  phoneticBundle,
  scriptConvert,
  numberBundle,
  solarToLunar,
  lunarToSolar,
  almanac,
  dateToGanzhi,
  baziSearch,
  sixtyJiaZi,
  languageLookup,
  base64Encode,
  base64Decode,
  urlEncode,
  urlDecode,
  htmlEscape,
  htmlUnescape,
  unicodeEscape,
  unicodeUnescape,
  jsonEscape,
  jsonUnescape,
  morseEncode,
  morseDecode,
  rc4Encode,
  rc4Decode,
  marsEncode,
  marsDecode,
  fullwidth,
  halfwidth,
  verticalLayout,
  hiddenEmbed,
  hiddenReveal,
  mojibakeCandidates,
  codePointTable,
  asciiTable,
  commonMapTable,
}

class _TextTransformModeDefinition {
  const _TextTransformModeDefinition({
    required this.mode,
    required this.category,
    required this.labelZh,
    required this.labelEn,
    required this.summaryZh,
    required this.summaryEn,
  });

  final _TextTransformMode mode;
  final _TextTransformCategory category;
  final String labelZh;
  final String labelEn;
  final String summaryZh;
  final String summaryEn;

  String label(BuildContext context) {
    return _lifeText(context, zh: labelZh, en: labelEn);
  }

  String summary(BuildContext context) {
    return _lifeText(context, zh: summaryZh, en: summaryEn);
  }
}

const List<_TextTransformModeDefinition>
_textTransformDefinitions = <_TextTransformModeDefinition>[
  _TextTransformModeDefinition(
    mode: _TextTransformMode.phoneticBundle,
    category: _TextTransformCategory.phonetic,
    labelZh: '拼音与注音',
    labelEn: 'Pinyin and zhuyin',
    summaryZh: '将中文转成拼音、首字母、简拼和注音。',
    summaryEn:
        'Convert Chinese into pinyin, initials, short pinyin, and zhuyin in one place.',
  ),
  _TextTransformModeDefinition(
    mode: _TextTransformMode.scriptConvert,
    category: _TextTransformCategory.phonetic,
    labelZh: '简繁转换',
    labelEn: 'Simplified and traditional',
    summaryZh: '进行简体与繁体互转，适合搭配拼音和文本清洗使用。',
    summaryEn:
        'Convert between simplified and traditional Chinese for cleanup or publishing.',
  ),
  _TextTransformModeDefinition(
    mode: _TextTransformMode.numberBundle,
    category: _TextTransformCategory.number,
    labelZh: '数字转写',
    labelEn: 'Number writing',
    summaryZh: '阿拉伯数字转罗马数字、中文数字与人民币大写。',
    summaryEn:
        'Turn Arabic numerals into Roman numerals, Chinese numerals, and RMB uppercase.',
  ),
  _TextTransformModeDefinition(
    mode: _TextTransformMode.solarToLunar,
    category: _TextTransformCategory.calendar,
    labelZh: '公历转农历',
    labelEn: 'Solar to lunar',
    summaryZh: '把选择的公历日期转换为农历、干支、节气等参考信息。',
    summaryEn:
        'Convert a solar date into lunar date, ganzhi, solar term, and related reference info.',
  ),
  _TextTransformModeDefinition(
    mode: _TextTransformMode.lunarToSolar,
    category: _TextTransformCategory.calendar,
    labelZh: '农历转公历',
    labelEn: 'Lunar to solar',
    summaryZh: '按农历年月日和闰月状态换算公历日期。',
    summaryEn: 'Convert a lunar date back into the corresponding solar date.',
  ),
  _TextTransformModeDefinition(
    mode: _TextTransformMode.almanac,
    category: _TextTransformCategory.calendar,
    labelZh: '万年历信息',
    labelEn: 'Almanac snapshot',
    summaryZh: '查看公历、农历、节气、月相、日出日落与节日信息。',
    summaryEn:
        'Show a daily snapshot with solar, lunar, solar term, moon phase, sunrise, and festivals.',
  ),
  _TextTransformModeDefinition(
    mode: _TextTransformMode.dateToGanzhi,
    category: _TextTransformCategory.ganzhi,
    labelZh: '日期转干支八字',
    labelEn: 'Date to ganzhi and bazi',
    summaryZh: '根据日期时间换算年柱、月柱、日柱、时柱与六十甲子序号。',
    summaryEn:
        'Convert a date and time into ganzhi pillars, bazi, and sixty-jiazi references.',
  ),
  _TextTransformModeDefinition(
    mode: _TextTransformMode.baziSearch,
    category: _TextTransformCategory.ganzhi,
    labelZh: '八字候选日期',
    labelEn: 'BaZi candidate search',
    summaryZh: '在受限年份范围内按两小时时辰搜索匹配的八字候选日期。',
    summaryEn:
        'Search limited year ranges for candidate dates matching a given BaZi pattern.',
  ),
  _TextTransformModeDefinition(
    mode: _TextTransformMode.sixtyJiaZi,
    category: _TextTransformCategory.ganzhi,
    labelZh: '六十甲子',
    labelEn: 'Sixty JiaZi',
    summaryZh: '查询六十甲子顺序、纳音与对应序号。',
    summaryEn: 'Look up sixty-jiazi order, na-yin, and index information.',
  ),
  _TextTransformModeDefinition(
    mode: _TextTransformMode.languageLookup,
    category: _TextTransformCategory.language,
    labelZh: '语言代码查询',
    labelEn: 'Language code lookup',
    summaryZh: '查询常见语言地区代码，并解析 BCP 47 / ISO 风格标签。',
    summaryEn:
        'Query common language and region codes and parse BCP 47 style tags.',
  ),
  _TextTransformModeDefinition(
    mode: _TextTransformMode.base64Encode,
    category: _TextTransformCategory.encode,
    labelZh: 'Base64 编码',
    labelEn: 'Base64 encode',
    summaryZh: '将文本编码为 Base64。',
    summaryEn: 'Encode text into Base64.',
  ),
  _TextTransformModeDefinition(
    mode: _TextTransformMode.base64Decode,
    category: _TextTransformCategory.encode,
    labelZh: 'Base64 解码',
    labelEn: 'Base64 decode',
    summaryZh: '将 Base64 还原为文本。',
    summaryEn: 'Decode Base64 back into text.',
  ),
  _TextTransformModeDefinition(
    mode: _TextTransformMode.urlEncode,
    category: _TextTransformCategory.encode,
    labelZh: 'URL 编码',
    labelEn: 'URL encode',
    summaryZh: '对文本进行 URL 安全编码。',
    summaryEn: 'Escape text into a URL-safe representation.',
  ),
  _TextTransformModeDefinition(
    mode: _TextTransformMode.urlDecode,
    category: _TextTransformCategory.encode,
    labelZh: 'URL 解码',
    labelEn: 'URL decode',
    summaryZh: '将 URL 编码文本还原。',
    summaryEn: 'Decode URL-escaped text.',
  ),
  _TextTransformModeDefinition(
    mode: _TextTransformMode.htmlEscape,
    category: _TextTransformCategory.encode,
    labelZh: 'HTML 转义',
    labelEn: 'HTML escape',
    summaryZh: '转义标签与常见特殊字符。',
    summaryEn: 'Escape HTML-sensitive characters.',
  ),
  _TextTransformModeDefinition(
    mode: _TextTransformMode.htmlUnescape,
    category: _TextTransformCategory.encode,
    labelZh: 'HTML 反转义',
    labelEn: 'HTML unescape',
    summaryZh: '还原常见 HTML 实体。',
    summaryEn: 'Restore common HTML entities.',
  ),
  _TextTransformModeDefinition(
    mode: _TextTransformMode.unicodeEscape,
    category: _TextTransformCategory.encode,
    labelZh: 'Unicode 编码',
    labelEn: 'Unicode escape',
    summaryZh: '将文本转为 \\uXXXX 形式。',
    summaryEn: 'Convert text into \\uXXXX sequences.',
  ),
  _TextTransformModeDefinition(
    mode: _TextTransformMode.unicodeUnescape,
    category: _TextTransformCategory.encode,
    labelZh: 'Unicode 解码',
    labelEn: 'Unicode unescape',
    summaryZh: '把 \\uXXXX 还原成字符。',
    summaryEn: 'Decode \\uXXXX sequences back into characters.',
  ),
  _TextTransformModeDefinition(
    mode: _TextTransformMode.jsonEscape,
    category: _TextTransformCategory.encode,
    labelZh: 'JSON 字符串转义',
    labelEn: 'JSON escape',
    summaryZh: '把文本转成可直接放入 JSON 的字符串内容。',
    summaryEn: 'Escape text for safe insertion into JSON strings.',
  ),
  _TextTransformModeDefinition(
    mode: _TextTransformMode.jsonUnescape,
    category: _TextTransformCategory.encode,
    labelZh: 'JSON 字符串还原',
    labelEn: 'JSON unescape',
    summaryZh: '把 JSON 字符串中的常见转义还原。',
    summaryEn: 'Restore common escape sequences from JSON string content.',
  ),
  _TextTransformModeDefinition(
    mode: _TextTransformMode.morseEncode,
    category: _TextTransformCategory.encode,
    labelZh: '摩斯编码',
    labelEn: 'Morse encode',
    summaryZh: '将英文与数字转为摩斯电码。',
    summaryEn: 'Encode letters and digits into Morse code.',
  ),
  _TextTransformModeDefinition(
    mode: _TextTransformMode.morseDecode,
    category: _TextTransformCategory.encode,
    labelZh: '摩斯解码',
    labelEn: 'Morse decode',
    summaryZh: '把空格分隔的摩斯电码还原。',
    summaryEn: 'Decode space-separated Morse code.',
  ),
  _TextTransformModeDefinition(
    mode: _TextTransformMode.rc4Encode,
    category: _TextTransformCategory.encode,
    labelZh: 'RC4 legacy 编码',
    labelEn: 'RC4 legacy encode',
    summaryZh: '使用旧 RC4 路径生成 Base64 密文，仅适合兼容用途。',
    summaryEn: 'Generate Base64 RC4 output for legacy compatibility only.',
  ),
  _TextTransformModeDefinition(
    mode: _TextTransformMode.rc4Decode,
    category: _TextTransformCategory.encode,
    labelZh: 'RC4 legacy 解码',
    labelEn: 'RC4 legacy decode',
    summaryZh: '按相同密钥解出 RC4 Base64 密文，仅适合兼容用途。',
    summaryEn:
        'Decode Base64 RC4 text with the same key for legacy compatibility.',
  ),
  _TextTransformModeDefinition(
    mode: _TextTransformMode.marsEncode,
    category: _TextTransformCategory.style,
    labelZh: '火星文转换',
    labelEn: 'Mars text encode',
    summaryZh: '把常见中文替换成轻量火星文写法。',
    summaryEn:
        'Convert common Chinese text into lightweight Mars-text variants.',
  ),
  _TextTransformModeDefinition(
    mode: _TextTransformMode.marsDecode,
    category: _TextTransformCategory.style,
    labelZh: '火星文还原',
    labelEn: 'Mars text decode',
    summaryZh: '尽量把常见火星文字形归一化回普通文本。',
    summaryEn: 'Normalize common Mars-text glyphs back into readable text.',
  ),
  _TextTransformModeDefinition(
    mode: _TextTransformMode.fullwidth,
    category: _TextTransformCategory.style,
    labelZh: '半角转全角',
    labelEn: 'Halfwidth to fullwidth',
    summaryZh: '把英文、数字和符号转成全角排版风格。',
    summaryEn:
        'Convert ASCII letters, digits, and symbols into fullwidth style.',
  ),
  _TextTransformModeDefinition(
    mode: _TextTransformMode.halfwidth,
    category: _TextTransformCategory.style,
    labelZh: '全角转半角',
    labelEn: 'Fullwidth to halfwidth',
    summaryZh: '把全角文本归一化为常见半角形式。',
    summaryEn: 'Normalize fullwidth text back into halfwidth form.',
  ),
  _TextTransformModeDefinition(
    mode: _TextTransformMode.verticalLayout,
    category: _TextTransformCategory.style,
    labelZh: '竖排排版',
    labelEn: 'Vertical layout',
    summaryZh: '输出适合复制预览的仿古竖排文本布局。',
    summaryEn: 'Generate a copyable vertical-text layout with simple borders.',
  ),
  _TextTransformModeDefinition(
    mode: _TextTransformMode.hiddenEmbed,
    category: _TextTransformCategory.hidden,
    labelZh: '文字隐藏',
    labelEn: 'Hide text',
    summaryZh: '把隐藏内容嵌入明文文本中。',
    summaryEn: 'Embed hidden content into visible cover text.',
  ),
  _TextTransformModeDefinition(
    mode: _TextTransformMode.hiddenReveal,
    category: _TextTransformCategory.hidden,
    labelZh: '隐藏提取',
    labelEn: 'Reveal hidden text',
    summaryZh: '从零宽字符文本中提取隐藏内容。',
    summaryEn: 'Extract hidden content from zero-width encoded text.',
  ),
  _TextTransformModeDefinition(
    mode: _TextTransformMode.mojibakeCandidates,
    category: _TextTransformCategory.mojibake,
    labelZh: '乱码候选修复',
    labelEn: 'Mojibake candidates',
    summaryZh: '输出常见编码重解释候选，不承诺唯一正确答案。',
    summaryEn:
        'Show common mojibake reinterpretation candidates instead of a guaranteed single fix.',
  ),
  _TextTransformModeDefinition(
    mode: _TextTransformMode.codePointTable,
    category: _TextTransformCategory.codeTable,
    labelZh: '字符码位',
    labelEn: 'Code point table',
    summaryZh: '查看字符的 Unicode、十进制和二进制值。',
    summaryEn:
        'Inspect Unicode, decimal, and binary values for each character.',
  ),
  _TextTransformModeDefinition(
    mode: _TextTransformMode.asciiTable,
    category: _TextTransformCategory.codeTable,
    labelZh: 'ASCII 对照表',
    labelEn: 'ASCII table',
    summaryZh: '查看 ASCII 0-127 对照表，也可按输入字符过滤。',
    summaryEn:
        'View the ASCII 0-127 reference table, optionally filtered by input.',
  ),
  _TextTransformModeDefinition(
    mode: _TextTransformMode.commonMapTable,
    category: _TextTransformCategory.codeTable,
    labelZh: '常用码表快照',
    labelEn: 'Common map snapshot',
    summaryZh: '同时查看 UTF-8、Base64、URL、Unicode 等常见表示。',
    summaryEn:
        'View UTF-8, Base64, URL, Unicode, and similar common representations together.',
  ),
];

class _TextTransformResultBlock {
  const _TextTransformResultBlock({
    required this.title,
    required this.content,
    this.highlight = false,
    this.isTable = false,
    this.copyContent,
  });

  final String title;
  final String content;
  final bool highlight;
  final bool isTable;
  final String? copyContent;
}

class _CommonLanguageItem {
  const _CommonLanguageItem({
    required this.code,
    required this.zh,
    required this.en,
  });

  final String code;
  final String zh;
  final String en;
}

class _TextTransformPage extends StatefulWidget {
  const _TextTransformPage();

  @override
  State<_TextTransformPage> createState() => _TextTransformPageState();
}

class _TextTransformPageState extends State<_TextTransformPage> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _secondaryController = TextEditingController();
  final TextEditingController _keyController = TextEditingController(
    text: 'life-tools',
  );
  final TextEditingController _lunarYearController = TextEditingController(
    text: '${DateTime.now().year}',
  );
  final TextEditingController _lunarDayController = TextEditingController(
    text: '${DateTime.now().day}',
  );
  final TextEditingController _searchStartYearController =
      TextEditingController(text: '${DateTime.now().year}');
  final TextEditingController _searchEndYearController = TextEditingController(
    text: '${DateTime.now().year}',
  );
  final TextEditingController _verticalColumnsController =
      TextEditingController(text: '6');
  final TextEditingController _verticalRowsController = TextEditingController(
    text: '10',
  );

  _TextTransformCategory _category = _TextTransformCategory.phonetic;
  _TextTransformMode _mode = _TextTransformMode.phoneticBundle;
  DateTime _selectedSolarDateTime = DateTime.now();
  String _selectedLunarMonth = '正';
  bool _selectedLunarLeap = false;
  int _verticalBorderStyle = 0;
  bool _verticalTraditional = false;
  List<_TextTransformResultBlock> _results =
      const <_TextTransformResultBlock>[];

  _TextTransformModeDefinition get _definition => _textTransformDefinitions
      .firstWhere((definition) => definition.mode == _mode);

  List<_TextTransformModeDefinition> get _categoryModes =>
      _textTransformDefinitions
          .where((definition) => definition.category == _category)
          .toList(growable: false);

  bool get _needsSecondaryInput => _mode == _TextTransformMode.hiddenEmbed;

  bool get _needsKey =>
      _mode == _TextTransformMode.rc4Encode ||
      _mode == _TextTransformMode.rc4Decode;

  bool get _needsVerticalOptions => _mode == _TextTransformMode.verticalLayout;

  bool get _needsSolarDate =>
      _mode == _TextTransformMode.solarToLunar ||
      _mode == _TextTransformMode.almanac;

  bool get _needsSolarDateTime =>
      _mode == _TextTransformMode.dateToGanzhi ||
      _mode == _TextTransformMode.baziSearch;

  bool get _needsLunarInput => _mode == _TextTransformMode.lunarToSolar;

  bool get _isHeavyMode => _mode == _TextTransformMode.baziSearch;
  bool _didRunInitialTransform = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didRunInitialTransform) {
      return;
    }
    _didRunInitialTransform = true;
    _runTransform();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _secondaryController.dispose();
    _keyController.dispose();
    _lunarYearController.dispose();
    _lunarDayController.dispose();
    _searchStartYearController.dispose();
    _searchEndYearController.dispose();
    _verticalColumnsController.dispose();
    _verticalRowsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ToolboxToolPage(
      title: _lifeText(context, zh: '文本转换', en: 'Text transform'),
      subtitle: _lifeText(
        context,
        zh: '整合拼音、简繁转换、数字转写、农历干支、语言代码与常用编码工具。',
        en: 'Pinyin, script conversion, numerals, calendar tools, language codes, and common encoders in one place.',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _LifeSettingsPanel(
            title: _lifeText(context, zh: '当前工具', en: 'Current tool'),
            subtitle: _lifeText(
              context,
              zh: '先选分组，再选需要的具体转换。',
              en: 'Choose a group, then the specific transform you need.',
            ),
            children: <Widget>[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  _buildInfoPill(
                    context,
                    _categoryLabel(context, _category),
                    icon: Icons.dashboard_customize_rounded,
                  ),
                  _buildInfoPill(
                    context,
                    _definition.label(context),
                    icon: Icons.auto_fix_high_rounded,
                  ),
                  if (_isHeavyMode)
                    _buildInfoPill(
                      context,
                      _lifeText(context, zh: '手动搜索', en: 'Manual search'),
                      icon: Icons.hourglass_top_rounded,
                    ),
                ],
              ),
              const SizedBox(height: 14),
              _LifeSegmentedField<_TextTransformCategory>(
                label: _lifeText(context, zh: '分组', en: 'Category'),
                value: _category,
                options: const <_LifeOption<_TextTransformCategory>>[
                  _LifeOption(
                    value: _TextTransformCategory.phonetic,
                    labelZh: '拼音',
                    labelEn: 'Phonetic',
                  ),
                  _LifeOption(
                    value: _TextTransformCategory.number,
                    labelZh: '数字',
                    labelEn: 'Number',
                  ),
                  _LifeOption(
                    value: _TextTransformCategory.calendar,
                    labelZh: '历法',
                    labelEn: 'Calendar',
                  ),
                  _LifeOption(
                    value: _TextTransformCategory.ganzhi,
                    labelZh: '干支',
                    labelEn: 'Ganzhi',
                  ),
                  _LifeOption(
                    value: _TextTransformCategory.language,
                    labelZh: '语言代码',
                    labelEn: 'Language',
                  ),
                  _LifeOption(
                    value: _TextTransformCategory.encode,
                    labelZh: '编码',
                    labelEn: 'Encoding',
                  ),
                  _LifeOption(
                    value: _TextTransformCategory.style,
                    labelZh: '风格',
                    labelEn: 'Style',
                  ),
                  _LifeOption(
                    value: _TextTransformCategory.hidden,
                    labelZh: '隐藏',
                    labelEn: 'Hidden',
                  ),
                  _LifeOption(
                    value: _TextTransformCategory.mojibake,
                    labelZh: '乱码',
                    labelEn: 'Mojibake',
                  ),
                  _LifeOption(
                    value: _TextTransformCategory.codeTable,
                    labelZh: '码表',
                    labelEn: 'Code table',
                  ),
                ],
                onChanged: (_TextTransformCategory value) {
                  final nextMode = _textTransformDefinitions
                      .firstWhere((definition) => definition.category == value)
                      .mode;
                  setState(() {
                    _category = value;
                    _mode = nextMode;
                  });
                  _runTransform();
                },
              ),
              const SizedBox(height: 14),
              _LifeSegmentedField<_TextTransformMode>(
                label: _lifeText(context, zh: '模式', en: 'Mode'),
                value: _mode,
                options: _categoryModes
                    .map(
                      (definition) => _LifeOption<_TextTransformMode>(
                        value: definition.mode,
                        labelZh: definition.labelZh,
                        labelEn: definition.labelEn,
                      ),
                    )
                    .toList(growable: false),
                onChanged: (_TextTransformMode value) {
                  setState(() => _mode = value);
                  _runTransform();
                },
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.55,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _definition.summary(context),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              if (_mode == _TextTransformMode.almanac ||
                  _mode == _TextTransformMode.dateToGanzhi ||
                  _mode == _TextTransformMode.baziSearch) ...<Widget>[
                const SizedBox(height: 10),
                Text(
                  _lifeText(
                    context,
                    zh: '历法与八字结果仅作本地参考，默认以北京时间与北京经纬度真太阳时辅助计算，不作为专业历书或命理结论。',
                    en: 'Calendar and BaZi results are local reference only. They use Beijing time and Beijing true-solar-time assistance by default, and are not an authoritative almanac or destiny reading.',
                  ),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          _LifeSettingsPanel(
            title: _lifeText(context, zh: '输入区', en: 'Input area'),
            subtitle: _lifeText(
              context,
              zh: '首屏只保留当前模式真正需要的字段，减少移动端的混乱感。',
              en: 'Only the fields truly needed by the active mode are shown on the first screen.',
            ),
            children: <Widget>[
              if (_usesPrimaryTextInput) ...<Widget>[
                TextField(
                  key: const ValueKey<String>(
                    'life_text_transform_input_field',
                  ),
                  controller: _inputController,
                  minLines: 4,
                  maxLines: 8,
                  onChanged: (_) => _runMaybeAuto(),
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: _primaryLabel(context),
                    alignLabelWithHint: true,
                  ),
                ),
              ],
              if (_needsSecondaryInput) ...<Widget>[
                const SizedBox(height: 12),
                TextField(
                  key: const ValueKey<String>(
                    'life_text_transform_secondary_field',
                  ),
                  controller: _secondaryController,
                  minLines: 3,
                  maxLines: 6,
                  onChanged: (_) => _runMaybeAuto(),
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: _lifeText(
                      context,
                      zh: '要隐藏的内容',
                      en: 'Hidden content',
                    ),
                    alignLabelWithHint: true,
                  ),
                ),
              ],
              if (_needsKey) ...<Widget>[
                const SizedBox(height: 12),
                TextField(
                  key: const ValueKey<String>('life_text_transform_key_field'),
                  controller: _keyController,
                  onChanged: (_) => _runMaybeAuto(),
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: _lifeText(context, zh: '密钥', en: 'Key'),
                  ),
                ),
              ],
              if (_needsSolarDate) ...<Widget>[
                if (_usesPrimaryTextInput) const SizedBox(height: 12),
                _buildDatePickerRow(context, includeTime: false),
              ],
              if (_needsSolarDateTime) ...<Widget>[
                if (_usesPrimaryTextInput || _needsSolarDate)
                  const SizedBox(height: 12),
                _buildDatePickerRow(context, includeTime: true),
              ],
              if (_needsLunarInput) ...<Widget>[
                if (_usesPrimaryTextInput) const SizedBox(height: 12),
                TextField(
                  controller: _lunarYearController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _runMaybeAuto(),
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: _lifeText(context, zh: '农历年份', en: 'Lunar year'),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedLunarMonth,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: _lifeText(
                      context,
                      zh: '农历月份',
                      en: 'Lunar month',
                    ),
                  ),
                  items: _lunarMonthNames
                      .map(
                        (month) => DropdownMenuItem<String>(
                          value: month,
                          child: Text(month),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    setState(() => _selectedLunarMonth = value ?? '正');
                    _runMaybeAuto();
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _lunarDayController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _runMaybeAuto(),
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: _lifeText(context, zh: '农历日期', en: 'Lunar day'),
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(_lifeText(context, zh: '闰月', en: 'Leap month')),
                  value: _selectedLunarLeap,
                  onChanged: (value) {
                    setState(() => _selectedLunarLeap = value);
                    _runMaybeAuto();
                  },
                ),
              ],
              if (_needsVerticalOptions) ...<Widget>[
                if (_usesPrimaryTextInput) const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        key: const ValueKey<String>(
                          'life_text_transform_vertical_columns',
                        ),
                        controller: _verticalColumnsController,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => _runMaybeAuto(),
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          labelText: _lifeText(
                            context,
                            zh: '列数',
                            en: 'Columns',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        key: const ValueKey<String>(
                          'life_text_transform_vertical_rows',
                        ),
                        controller: _verticalRowsController,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => _runMaybeAuto(),
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          labelText: _lifeText(context, zh: '行数', en: 'Rows'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: _verticalBorderStyle,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: _lifeText(context, zh: '边框样式', en: 'Border'),
                  ),
                  items: List<DropdownMenuItem<int>>.generate(
                    _verticalBorderStyles.length,
                    (index) => DropdownMenuItem<int>(
                      value: index,
                      child: Text(
                        _lifeText(
                          context,
                          zh: '样式 ${index + 1}',
                          en: 'Style ${index + 1}',
                        ),
                      ),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => _verticalBorderStyle = value ?? 0);
                    _runMaybeAuto();
                  },
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    _lifeText(
                      context,
                      zh: '先转繁体再排版',
                      en: 'Use traditional first',
                    ),
                  ),
                  value: _verticalTraditional,
                  onChanged: (value) {
                    setState(() => _verticalTraditional = value);
                    _runMaybeAuto();
                  },
                ),
              ],
              if (_mode == _TextTransformMode.baziSearch) ...<Widget>[
                if (_usesPrimaryTextInput || _needsSolarDateTime)
                  const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: _searchStartYearController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          labelText: _lifeText(
                            context,
                            zh: '起始年份',
                            en: 'Start year',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchEndYearController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          labelText: _lifeText(
                            context,
                            zh: '结束年份',
                            en: 'End year',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: FilledButton(
                      onPressed: _runTransform,
                      child: Text(
                        _lifeText(
                          context,
                          zh: _isHeavyMode ? '搜索候选' : '生成结果',
                          en: _isHeavyMode ? 'Search' : 'Run',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: _fillExample,
                      child: Text(_lifeText(context, zh: '示例', en: 'Example')),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          _LifeSettingsPanel(
            title: _lifeText(context, zh: '结果区', en: 'Results'),
            subtitle: _lifeText(
              context,
              zh: '结果会按主结论、补充说明和参考表格分层呈现，便于移动端快速浏览。',
              en: 'Results are layered into primary output, supporting notes, and reference tables for faster mobile scanning.',
            ),
            children: _results.isEmpty
                ? <Widget>[
                    Text(
                      _lifeText(context, zh: '当前还没有结果。', en: 'No result yet.'),
                    ),
                  ]
                : _results
                      .map((block) => _buildResultBlock(context, block))
                      .toList(growable: false),
          ),
        ],
      ),
    );
  }

  bool get _usesPrimaryTextInput {
    return switch (_mode) {
      _TextTransformMode.solarToLunar ||
      _TextTransformMode.lunarToSolar ||
      _TextTransformMode.almanac ||
      _TextTransformMode.dateToGanzhi => false,
      _ => true,
    };
  }

  Widget _buildDatePickerRow(
    BuildContext context, {
    required bool includeTime,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        FilledButton.tonal(
          onPressed: () async {
            final date = await showDatePicker(
              context: context,
              firstDate: DateTime(1900),
              lastDate: DateTime(2100),
              initialDate: _selectedSolarDateTime,
            );
            if (date == null) {
              return;
            }
            setState(() {
              _selectedSolarDateTime = DateTime(
                date.year,
                date.month,
                date.day,
                _selectedSolarDateTime.hour,
                _selectedSolarDateTime.minute,
              );
            });
            _runMaybeAuto();
          },
          child: Text(
            _lifeText(
              context,
              zh: '日期: ${_formatDate(_selectedSolarDateTime)}',
              en: 'Date: ${_formatDate(_selectedSolarDateTime)}',
            ),
          ),
        ),
        if (includeTime) ...<Widget>[
          const SizedBox(height: 8),
          FilledButton.tonal(
            onPressed: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(_selectedSolarDateTime),
              );
              if (time == null) {
                return;
              }
              setState(() {
                _selectedSolarDateTime = DateTime(
                  _selectedSolarDateTime.year,
                  _selectedSolarDateTime.month,
                  _selectedSolarDateTime.day,
                  time.hour,
                  time.minute,
                );
              });
              _runMaybeAuto();
            },
            child: Text(
              _lifeText(
                context,
                zh: '时间: ${_formatTime(_selectedSolarDateTime)}',
                en: 'Time: ${_formatTime(_selectedSolarDateTime)}',
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoPill(
    BuildContext context,
    String text, {
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(text),
        ],
      ),
    );
  }

  Widget _buildResultBlock(
    BuildContext context,
    _TextTransformResultBlock block,
  ) {
    final theme = Theme.of(context);
    final String displayContent = block.content.isEmpty
        ? _lifeText(context, zh: '无结果', en: 'No result')
        : block.content;
    final String copyContent = block.copyContent ?? block.content;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: block.highlight
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: block.highlight
              ? theme.colorScheme.primary.withValues(alpha: 0.35)
              : theme.colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  block.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                tooltip: _lifeText(context, zh: '复制结果', en: 'Copy result'),
                onPressed: copyContent.isEmpty
                    ? null
                    : () {
                        Clipboard.setData(ClipboardData(text: copyContent));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              _lifeText(
                                context,
                                zh: '已复制当前结果',
                                en: 'Result copied',
                              ),
                            ),
                          ),
                        );
                      },
                icon: const Icon(Icons.copy_rounded, size: 18),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            displayContent,
            style: block.isTable
                ? theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace')
                : theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  String _primaryLabel(BuildContext context) {
    return switch (_mode) {
      _TextTransformMode.phoneticBundle => _lifeText(
        context,
        zh: '输入中文',
        en: 'Chinese text',
      ),
      _TextTransformMode.scriptConvert => _lifeText(
        context,
        zh: '输入简体或繁体',
        en: 'Simplified or traditional text',
      ),
      _TextTransformMode.numberBundle => _lifeText(
        context,
        zh: '输入数字',
        en: 'Number input',
      ),
      _TextTransformMode.languageLookup => _lifeText(
        context,
        zh: '输入语言代码或标签',
        en: 'Language code or locale tag',
      ),
      _TextTransformMode.baziSearch => _lifeText(
        context,
        zh: '输入四柱，例如 甲子 乙丑 丙寅 丁卯',
        en: 'Four pillars, for example JiaZi YiChou BingYin DingMao',
      ),
      _TextTransformMode.sixtyJiaZi => _lifeText(
        context,
        zh: '输入序号或甲子名',
        en: 'Index or JiaZi name',
      ),
      _TextTransformMode.hiddenReveal => _lifeText(
        context,
        zh: '输入待提取文本',
        en: 'Encoded text',
      ),
      _TextTransformMode.mojibakeCandidates => _lifeText(
        context,
        zh: '输入乱码文本',
        en: 'Possibly garbled text',
      ),
      _TextTransformMode.verticalLayout => _lifeText(
        context,
        zh: '输入要竖排的文本',
        en: 'Text for vertical layout',
      ),
      _TextTransformMode.marsDecode => _lifeText(
        context,
        zh: '输入火星文',
        en: 'Mars text',
      ),
      _TextTransformMode.marsEncode => _lifeText(
        context,
        zh: '输入普通文本',
        en: 'Plain text',
      ),
      _TextTransformMode.base64Decode => _lifeText(
        context,
        zh: '输入 Base64',
        en: 'Base64 input',
      ),
      _TextTransformMode.urlDecode => _lifeText(
        context,
        zh: '输入 URL 编码文本',
        en: 'URL-encoded input',
      ),
      _TextTransformMode.unicodeUnescape => _lifeText(
        context,
        zh: '输入 \\uXXXX 序列',
        en: '\\uXXXX input',
      ),
      _TextTransformMode.jsonUnescape => _lifeText(
        context,
        zh: '输入 JSON 字符串内容',
        en: 'JSON string content',
      ),
      _TextTransformMode.morseDecode => _lifeText(
        context,
        zh: '输入摩斯电码',
        en: 'Morse code',
      ),
      _TextTransformMode.rc4Decode => _lifeText(
        context,
        zh: '输入 Base64 密文',
        en: 'Base64 cipher text',
      ),
      _ => _lifeText(context, zh: '输入文本', en: 'Input text'),
    };
  }

  String _categoryLabel(BuildContext context, _TextTransformCategory category) {
    return switch (category) {
      _TextTransformCategory.phonetic => _lifeText(
        context,
        zh: '拼音',
        en: 'Phonetic',
      ),
      _TextTransformCategory.number => _lifeText(
        context,
        zh: '数字',
        en: 'Number',
      ),
      _TextTransformCategory.calendar => _lifeText(
        context,
        zh: '历法',
        en: 'Calendar',
      ),
      _TextTransformCategory.ganzhi => _lifeText(
        context,
        zh: '干支',
        en: 'Ganzhi',
      ),
      _TextTransformCategory.language => _lifeText(
        context,
        zh: '语言代码',
        en: 'Language',
      ),
      _TextTransformCategory.encode => _lifeText(
        context,
        zh: '编码',
        en: 'Encoding',
      ),
      _TextTransformCategory.style => _lifeText(context, zh: '风格', en: 'Style'),
      _TextTransformCategory.hidden => _lifeText(
        context,
        zh: '隐藏',
        en: 'Hidden',
      ),
      _TextTransformCategory.mojibake => _lifeText(
        context,
        zh: '乱码',
        en: 'Mojibake',
      ),
      _TextTransformCategory.codeTable => _lifeText(
        context,
        zh: '码表',
        en: 'Code table',
      ),
    };
  }

  void _runMaybeAuto() {
    if (_isHeavyMode) {
      return;
    }
    _runTransform();
  }

  void _fillExample() {
    switch (_mode) {
      case _TextTransformMode.phoneticBundle:
      case _TextTransformMode.scriptConvert:
        _inputController.text = '中文转拼音已合并到文本转换';
      case _TextTransformMode.numberBundle:
        _inputController.text = '1234567.89';
      case _TextTransformMode.solarToLunar:
      case _TextTransformMode.almanac:
        _selectedSolarDateTime = DateTime(2026, 5, 27, 9, 30);
      case _TextTransformMode.lunarToSolar:
        _lunarYearController.text = '2026';
        _selectedLunarMonth = '四';
        _lunarDayController.text = '11';
        _selectedLunarLeap = false;
      case _TextTransformMode.dateToGanzhi:
        _selectedSolarDateTime = DateTime(2026, 5, 27, 9, 30);
      case _TextTransformMode.baziSearch:
        _inputController.text = '丙午 癸巳 丙子 癸巳';
        _searchStartYearController.text = '2026';
        _searchEndYearController.text = '2026';
      case _TextTransformMode.sixtyJiaZi:
        _inputController.text = '甲子';
      case _TextTransformMode.languageLookup:
        _inputController.text = 'zh-Hant-TW';
      case _TextTransformMode.base64Encode:
      case _TextTransformMode.urlEncode:
      case _TextTransformMode.htmlEscape:
      case _TextTransformMode.unicodeEscape:
      case _TextTransformMode.jsonEscape:
      case _TextTransformMode.fullwidth:
      case _TextTransformMode.verticalLayout:
      case _TextTransformMode.hiddenEmbed:
      case _TextTransformMode.codePointTable:
      case _TextTransformMode.commonMapTable:
      case _TextTransformMode.mojibakeCandidates:
        _inputController.text = '你好, Text transform 123';
        if (_mode == _TextTransformMode.hiddenEmbed) {
          _secondaryController.text = '这是一段隐藏文本';
        }
      case _TextTransformMode.marsEncode:
        _inputController.text = '你好呀，我们今天一起去玩吗？';
      case _TextTransformMode.base64Decode:
        _inputController.text = '5L2g5aW9';
      case _TextTransformMode.urlDecode:
        _inputController.text = '%E4%BD%A0%E5%A5%BD';
      case _TextTransformMode.htmlUnescape:
        _inputController.text = '&lt;b&gt;hello&lt;/b&gt;';
      case _TextTransformMode.unicodeUnescape:
        _inputController.text = r'\u4F60\u597D';
      case _TextTransformMode.jsonUnescape:
        _inputController.text = r'hello\nworld';
      case _TextTransformMode.morseEncode:
        _inputController.text = 'SOS 2026';
      case _TextTransformMode.morseDecode:
        _inputController.text = '... --- ...';
      case _TextTransformMode.rc4Encode:
      case _TextTransformMode.rc4Decode:
        _inputController.text = 'legacy';
      case _TextTransformMode.marsDecode:
        _inputController.text = '伱ぬ，莪莱ㄋ';
      case _TextTransformMode.halfwidth:
        _inputController.text = 'Ｔｅｘｔ　１２３';
      case _TextTransformMode.hiddenReveal:
        _inputController.text = _embedHiddenText('可见文本', '隐藏内容');
      case _TextTransformMode.asciiTable:
        _inputController.text = 'ABC';
    }
    setState(() {});
    _runTransform();
  }

  void _runTransform() {
    final List<_TextTransformResultBlock> blocks =
        <_TextTransformResultBlock>[];
    try {
      final String input = _inputController.text;
      switch (_mode) {
        case _TextTransformMode.phoneticBundle:
          final String source = input.trim();
          blocks.addAll(_phoneticBlocks(source));
        case _TextTransformMode.scriptConvert:
          blocks.addAll(_scriptBlocks(input));
        case _TextTransformMode.numberBundle:
          blocks.addAll(_numberBlocks(input));
        case _TextTransformMode.solarToLunar:
          blocks.addAll(_solarToLunarBlocks(_selectedSolarDateTime));
        case _TextTransformMode.lunarToSolar:
          blocks.addAll(_lunarToSolarBlocks());
        case _TextTransformMode.almanac:
          blocks.addAll(_almanacBlocks(_selectedSolarDateTime));
        case _TextTransformMode.dateToGanzhi:
          blocks.addAll(_ganzhiBlocks(_selectedSolarDateTime));
        case _TextTransformMode.baziSearch:
          blocks.addAll(_baziSearchBlocks(input));
        case _TextTransformMode.sixtyJiaZi:
          blocks.addAll(_sixtyJiaZiBlocks(input));
        case _TextTransformMode.languageLookup:
          blocks.addAll(_languageLookupBlocks(input));
        case _TextTransformMode.base64Encode:
          blocks.add(
            _TextTransformResultBlock(
              title: 'Base64',
              content: base64Encode(utf8.encode(input)),
              highlight: true,
            ),
          );
        case _TextTransformMode.base64Decode:
          blocks.add(
            _TextTransformResultBlock(
              title: _lifeText(context, zh: '解码结果', en: 'Decoded'),
              content: utf8.decode(base64Decode(input.trim())),
              highlight: true,
            ),
          );
        case _TextTransformMode.urlEncode:
          blocks.add(
            _TextTransformResultBlock(
              title: 'URL',
              content: Uri.encodeComponent(input),
              highlight: true,
            ),
          );
        case _TextTransformMode.urlDecode:
          blocks.add(
            _TextTransformResultBlock(
              title: _lifeText(context, zh: '解码结果', en: 'Decoded'),
              content: Uri.decodeComponent(input),
              highlight: true,
            ),
          );
        case _TextTransformMode.htmlEscape:
          blocks.add(
            _TextTransformResultBlock(
              title: 'HTML',
              content: _htmlEscape(input),
              highlight: true,
            ),
          );
        case _TextTransformMode.htmlUnescape:
          blocks.add(
            _TextTransformResultBlock(
              title: _lifeText(context, zh: '还原结果', en: 'Restored'),
              content: _htmlUnescape(input),
              highlight: true,
            ),
          );
        case _TextTransformMode.unicodeEscape:
          blocks.add(
            _TextTransformResultBlock(
              title: 'Unicode',
              content: _unicodeEscape(input),
              highlight: true,
            ),
          );
        case _TextTransformMode.unicodeUnescape:
          blocks.add(
            _TextTransformResultBlock(
              title: _lifeText(context, zh: '还原结果', en: 'Restored'),
              content: _unicodeUnescape(input),
              highlight: true,
            ),
          );
        case _TextTransformMode.jsonEscape:
          blocks.add(
            _TextTransformResultBlock(
              title: 'JSON',
              content: _jsonStringSafe(input),
              highlight: true,
            ),
          );
        case _TextTransformMode.jsonUnescape:
          blocks.add(
            _TextTransformResultBlock(
              title: _lifeText(context, zh: '还原结果', en: 'Restored'),
              content: _jsonUnescape(input),
              highlight: true,
            ),
          );
        case _TextTransformMode.morseEncode:
          blocks.add(
            _TextTransformResultBlock(
              title: _lifeText(context, zh: '摩斯结果', en: 'Morse'),
              content: _toMorse(input),
              highlight: true,
            ),
          );
        case _TextTransformMode.morseDecode:
          blocks.add(
            _TextTransformResultBlock(
              title: _lifeText(context, zh: '解码结果', en: 'Decoded'),
              content: _fromMorse(input),
              highlight: true,
            ),
          );
        case _TextTransformMode.rc4Encode:
          blocks.add(
            _TextTransformResultBlock(
              title: 'RC4 Base64',
              content: _rc4Base64Encode(input, _keyController.text),
              highlight: true,
            ),
          );
        case _TextTransformMode.rc4Decode:
          blocks.add(
            _TextTransformResultBlock(
              title: _lifeText(context, zh: '解码结果', en: 'Decoded'),
              content: _rc4Base64Decode(input, _keyController.text),
              highlight: true,
            ),
          );
        case _TextTransformMode.marsEncode:
          blocks.add(
            _TextTransformResultBlock(
              title: _lifeText(context, zh: '火星文', en: 'Mars text'),
              content: _toMars(input),
              highlight: true,
            ),
          );
        case _TextTransformMode.marsDecode:
          blocks.add(
            _TextTransformResultBlock(
              title: _lifeText(context, zh: '还原结果', en: 'Normalized'),
              content: _fromMars(input),
              highlight: true,
            ),
          );
        case _TextTransformMode.fullwidth:
          blocks.add(
            _TextTransformResultBlock(
              title: _lifeText(context, zh: '全角结果', en: 'Fullwidth'),
              content: _toFullWidthString(input),
              highlight: true,
            ),
          );
        case _TextTransformMode.halfwidth:
          blocks.add(
            _TextTransformResultBlock(
              title: _lifeText(context, zh: '半角结果', en: 'Halfwidth'),
              content: _toHalfWidthString(input),
              highlight: true,
            ),
          );
        case _TextTransformMode.verticalLayout:
          blocks.add(
            _TextTransformResultBlock(
              title: _lifeText(context, zh: '竖排预览', en: 'Vertical preview'),
              content: _verticalLayout(
                input,
                columns: _safePositiveInt(_verticalColumnsController.text, 6),
                rows: _safePositiveInt(_verticalRowsController.text, 10),
                borderStyle: _verticalBorderStyle,
                useTraditional: _verticalTraditional,
              ),
              highlight: true,
              isTable: true,
            ),
          );
        case _TextTransformMode.hiddenEmbed:
          blocks.add(
            _TextTransformResultBlock(
              title: _lifeText(context, zh: '嵌入结果', en: 'Embedded result'),
              content: _embedHiddenText(input, _secondaryController.text),
              highlight: true,
            ),
          );
        case _TextTransformMode.hiddenReveal:
          blocks.add(
            _TextTransformResultBlock(
              title: _lifeText(context, zh: '提取结果', en: 'Revealed result'),
              content: _revealHiddenText(input),
              highlight: true,
            ),
          );
        case _TextTransformMode.mojibakeCandidates:
          blocks.addAll(_mojibakeCandidates(input));
        case _TextTransformMode.codePointTable:
          blocks.add(
            _TextTransformResultBlock(
              title: _lifeText(context, zh: '字符码位', en: 'Code points'),
              content: _buildCodePointTable(input),
              highlight: true,
              isTable: true,
            ),
          );
        case _TextTransformMode.asciiTable:
          blocks.add(
            _TextTransformResultBlock(
              title: 'ASCII',
              content: _buildAsciiTable(input),
              highlight: true,
              isTable: true,
            ),
          );
        case _TextTransformMode.commonMapTable:
          blocks.addAll(_commonMapTable(input));
      }
    } catch (error) {
      blocks
        ..clear()
        ..add(
          _TextTransformResultBlock(
            title: _lifeText(context, zh: '转换失败', en: 'Transform failed'),
            content: error.toString(),
            highlight: true,
          ),
        );
    }
    setState(() => _results = blocks);
  }

  List<_TextTransformResultBlock> _phoneticBlocks(String text) {
    if (text.trim().isEmpty) {
      return <_TextTransformResultBlock>[
        _TextTransformResultBlock(
          title: _lifeText(context, zh: '说明', en: 'Note'),
          content: _lifeText(
            context,
            zh: '输入中文后可同时查看拼音、注音、简拼和首字母。',
            en: 'Enter Chinese text to view pinyin, zhuyin, short pinyin, and initials together.',
          ),
          highlight: true,
        ),
      ];
    }
    return <_TextTransformResultBlock>[
      _TextTransformResultBlock(
        title: _lifeText(context, zh: '拼音（无声调）', en: 'Pinyin without tone'),
        content: PinyinHelper.getPinyin(
          text,
          format: PinyinFormat.WITHOUT_TONE,
        ),
        highlight: true,
      ),
      _TextTransformResultBlock(
        title: _lifeText(context, zh: '拼音（声调符号）', en: 'Pinyin tone marks'),
        content: PinyinHelper.getPinyin(
          text,
          format: PinyinFormat.WITH_TONE_MARK,
        ),
      ),
      _TextTransformResultBlock(
        title: _lifeText(context, zh: '拼音（声调数字）', en: 'Pinyin tone numbers'),
        content: PinyinHelper.getPinyin(
          text,
          format: PinyinFormat.WITH_TONE_NUMBER,
        ),
      ),
      _TextTransformResultBlock(
        title: _lifeText(context, zh: '注音', en: 'Zhuyin'),
        content: ZhuyinHelper.getZhuyin(
          text,
          format: PinyinFormat.WITH_TONE_MARK,
        ),
      ),
      _TextTransformResultBlock(
        title: _lifeText(context, zh: '简拼', en: 'Short pinyin'),
        content: PinyinHelper.getShortPinyin(text),
      ),
      _TextTransformResultBlock(
        title: _lifeText(context, zh: '首字母', en: 'First-letter initials'),
        content: PinyinHelper.getFirstWordPinyin(text),
      ),
    ];
  }

  List<_TextTransformResultBlock> _scriptBlocks(String text) {
    if (text.trim().isEmpty) {
      return <_TextTransformResultBlock>[
        _TextTransformResultBlock(
          title: _lifeText(context, zh: '说明', en: 'Note'),
          content: _lifeText(
            context,
            zh: '输入简体或繁体中文后可查看双向转换结果。',
            en: 'Enter simplified or traditional Chinese to view both conversion directions.',
          ),
          highlight: true,
        ),
      ];
    }
    return <_TextTransformResultBlock>[
      _TextTransformResultBlock(
        title: _lifeText(context, zh: '转繁体', en: 'To traditional'),
        content: ChineseHelper.convertToTraditionalChinese(text),
        highlight: true,
      ),
      _TextTransformResultBlock(
        title: _lifeText(context, zh: '转简体', en: 'To simplified'),
        content: ChineseHelper.convertToSimplifiedChinese(text),
      ),
    ];
  }

  List<_TextTransformResultBlock> _numberBlocks(String input) {
    final String source = input.trim();
    if (source.isEmpty) {
      return <_TextTransformResultBlock>[
        _TextTransformResultBlock(
          title: _lifeText(context, zh: '说明', en: 'Note'),
          content: _lifeText(
            context,
            zh: '输入阿拉伯数字，例如 1234567.89。',
            en: 'Enter an Arabic number such as 1234567.89.',
          ),
          highlight: true,
        ),
      ];
    }
    final num? parsed = num.tryParse(source.replaceAll(',', ''));
    if (parsed == null) {
      throw FormatException(
        _lifeText(context, zh: '请输入可解析的数字。', en: 'Enter a parseable number.'),
      );
    }
    final int integer = parsed.truncate();
    return <_TextTransformResultBlock>[
      _TextTransformResultBlock(
        title: _lifeText(context, zh: '中文数字', en: 'Chinese numerals'),
        content: _numberToChineseLower(source),
        highlight: true,
      ),
      _TextTransformResultBlock(
        title: _lifeText(context, zh: '人民币大写', en: 'RMB uppercase'),
        content: _numberToChineseFinancial(source),
      ),
      _TextTransformResultBlock(
        title: _lifeText(context, zh: '英文数字', en: 'English words'),
        content: _numberToEnglishWords(source),
      ),
      _TextTransformResultBlock(
        title: _lifeText(context, zh: '罗马数字', en: 'Roman numeral'),
        content: _toRoman(integer),
      ),
    ];
  }

  List<_TextTransformResultBlock> _solarToLunarBlocks(DateTime dateTime) {
    final AstroDateTime astro = AstroDateTime(
      dateTime.year,
      dateTime.month,
      dateTime.day,
      dateTime.hour,
      dateTime.minute,
      0,
    );
    final LunarDate lunar = LunarDate.fromSolar(astro);
    final DayInfo info = getSolarMonthDays(
      dateTime.year,
      dateTime.month,
      location: Location.beijing,
    ).withMoonPhase8().firstWhere((item) => item.solarDate.day == dateTime.day);
    final JieQiInfo? jieQiInfo = getJieQiInfo(astro);
    return <_TextTransformResultBlock>[
      _TextTransformResultBlock(
        title: _lifeText(context, zh: '农历日期', en: 'Lunar date'),
        content:
            '${lunar.historicalYear}年 ${lunar.monthNameStr}月${_lunarDayName(lunar.day)}\n${_lifeText(context, zh: '月大小', en: 'Month size')}: ${lunar.monthSize == 30 ? _lifeText(context, zh: '大月', en: '30-day month') : _lifeText(context, zh: '小月', en: '29-day month')}',
        highlight: true,
      ),
      _TextTransformResultBlock(
        title: _lifeText(context, zh: '干支与星期', en: 'Ganzhi and weekday'),
        content:
            '${info.ganZhi}  ·  ${info.weekdayName}  ·  ${info.constellation}',
      ),
      _TextTransformResultBlock(
        title: _lifeText(context, zh: '节气与月相', en: 'Solar term and moon phase'),
        content: [
          if (info.solarTerm != null)
            '${_lifeText(context, zh: '当前节气', en: 'Current solar term')}: ${info.solarTerm}${info.solarTermTime != null ? ' ${info.solarTermTime!.toTimeString()}' : ''}',
          if (info.moonPhase != null)
            '${_lifeText(context, zh: '月相', en: 'Moon phase')}: ${info.moonPhase}${info.moonPhaseTime != null ? ' ${info.moonPhaseTime!.toTimeString()}' : ''}',
          if (jieQiInfo != null)
            '${_lifeText(context, zh: '节气窗口', en: 'Solar-term window')}: ${jieQiInfo.prevJieQi.name} → ${jieQiInfo.nextJieQi.name} (${jieQiInfo.daysUntilNextJieQi.toStringAsFixed(1)}d)',
        ].join('\n').trim(),
      ),
      _TextTransformResultBlock(
        title: _lifeText(context, zh: '节日与民俗', en: 'Festivals and customs'),
        content: _festivalSummary(info),
      ),
    ];
  }

  List<_TextTransformResultBlock> _lunarToSolarBlocks() {
    final int year = _safePositiveInt(
      _lunarYearController.text,
      DateTime.now().year,
    );
    final int day = _safePositiveInt(
      _lunarDayController.text,
      DateTime.now().day,
    );
    final LunarDate lunar = LunarDate.fromString(
      year,
      _selectedLunarLeap ? '闰$_selectedLunarMonth' : _selectedLunarMonth,
      day,
      isLeap: _selectedLunarLeap,
    );
    final AstroDateTime solar = lunar.toSolar;
    return <_TextTransformResultBlock>[
      _TextTransformResultBlock(
        title: _lifeText(context, zh: '公历日期', en: 'Solar date'),
        content:
            '${solar.year}-${solar.month.toString().padLeft(2, '0')}-${solar.day.toString().padLeft(2, '0')}',
        highlight: true,
      ),
      _TextTransformResultBlock(
        title: _lifeText(context, zh: '农历确认', en: 'Lunar input'),
        content:
            '${lunar.lunarYear}年 ${lunar.monthNameStr}月${_lunarDayName(lunar.day)}',
      ),
    ];
  }

  List<_TextTransformResultBlock> _almanacBlocks(DateTime dateTime) {
    final DayInfo info = getSolarMonthDays(
      dateTime.year,
      dateTime.month,
      location: Location.beijing,
    ).withMoonPhase8().firstWhere((item) => item.solarDate.day == dateTime.day);
    final List<JieQiResult> yearJieQi = getYearJieQi(dateTime.year);
    final AstroDateTime target = AstroDateTime(
      dateTime.year,
      dateTime.month,
      dateTime.day,
      dateTime.hour,
      dateTime.minute,
      0,
    );
    final JieQiInfo? jieQiInfo = getJieQiInfo(target);
    return <_TextTransformResultBlock>[
      _TextTransformResultBlock(
        title: _lifeText(context, zh: '当天概览', en: 'Day snapshot'),
        content:
            '${_formatDate(dateTime)} ${_formatTime(dateTime)}\n${info.ganZhi} · ${info.weekdayName} · ${info.constellation}\n农历 ${info.lunarDate.monthNameStr}月${_lunarDayName(info.lunarDate.day)} (${info.lunarMonthSize == 30 ? _lifeText(context, zh: '大月', en: '30-day month') : _lifeText(context, zh: '小月', en: '29-day month')})',
        highlight: true,
      ),
      _TextTransformResultBlock(
        title: _lifeText(context, zh: '节气与月相', en: 'Solar term and moon phase'),
        content: [
          '${_lifeText(context, zh: '节气', en: 'Solar term')}: ${info.solarTerm ?? _lifeText(context, zh: '无', en: 'None')}${info.solarTermTime != null ? ' ${info.solarTermTime!.toTimeString()}' : ''}',
          '${_lifeText(context, zh: '月相', en: 'Moon phase')}: ${info.moonPhase ?? _lifeText(context, zh: '无', en: 'None')}${info.moonPhaseTime != null ? ' ${info.moonPhaseTime!.toTimeString()}' : ''}',
          if (jieQiInfo != null)
            '${_lifeText(context, zh: '节气窗口', en: 'Solar-term window')}: ${jieQiInfo.prevJieQi.name} → ${jieQiInfo.nextJieQi.name}',
        ].join('\n'),
      ),
      _TextTransformResultBlock(
        title: _lifeText(
          context,
          zh: '日出日落（北京）',
          en: 'Sunrise and sunset (Beijing)',
        ),
        content: [
          '${_lifeText(context, zh: '日出', en: 'Sunrise')}: ${info.sunrise?.toTimeString() ?? '--'}',
          '${_lifeText(context, zh: '日落', en: 'Sunset')}: ${info.sunset?.toTimeString() ?? '--'}',
        ].join('\n'),
      ),
      _TextTransformResultBlock(
        title: _lifeText(
          context,
          zh: '节日与当年节气摘录',
          en: 'Festivals and yearly solar terms',
        ),
        content: [
          _festivalSummary(info),
          ...yearJieQi
              .where((item) => item.dateTime.month == dateTime.month)
              .take(6)
              .map(
                (item) =>
                    '${item.name} ${item.dateTime.month.toString().padLeft(2, '0')}-${item.dateTime.day.toString().padLeft(2, '0')} ${item.dateTime.toTimeString()}',
              ),
        ].join('\n'),
        isTable: true,
      ),
    ];
  }

  List<_TextTransformResultBlock> _ganzhiBlocks(DateTime dateTime) {
    final AstroDateTime local = AstroDateTime(
      dateTime.year,
      dateTime.month,
      dateTime.day,
      dateTime.hour,
      dateTime.minute,
      0,
    );
    final AstroDateTime utc = local.subtract(const Duration(hours: 8));
    final SolarTimeResult solar = calcTrueSolarTime(local, Location.beijing);
    final GanZhiResult ganzhi = calcGanZhiAstroDate(utc, solar.trueSolarTime);
    final BaZiCalcResult bazi = calcBaZiAstroDate(utc, solar.trueSolarTime);
    final String dayIndex =
        (_sixtyJiaZi.indexWhere((item) => item == ganzhi.dayGanZhi) + 1)
            .toString();
    return <_TextTransformResultBlock>[
      _TextTransformResultBlock(
        title: _lifeText(context, zh: '四柱八字', en: 'Four pillars'),
        content: bazi.bazi.toString(),
        highlight: true,
      ),
      _TextTransformResultBlock(
        title: _lifeText(context, zh: '年柱 / 月柱 / 日柱 / 时柱', en: 'Pillars'),
        content:
            '${ganzhi.yearGanZhi} / ${ganzhi.monthGanZhi} / ${ganzhi.dayGanZhi} / ${ganzhi.timeGanZhi}',
      ),
      _TextTransformResultBlock(
        title: _lifeText(
          context,
          zh: '真太阳时（北京）',
          en: 'True solar time (Beijing)',
        ),
        content:
            '${solar.trueSolarTime.year}-${solar.trueSolarTime.month.toString().padLeft(2, '0')}-${solar.trueSolarTime.day.toString().padLeft(2, '0')} ${solar.trueSolarTime.toTimeString()}\n${_lifeText(context, zh: '当前时支', en: 'Current time branch')}: ${_timeBranchLabel(dateTime.hour)}',
      ),
      _TextTransformResultBlock(
        title: _lifeText(context, zh: '纳音与五行', en: 'NaYin and five elements'),
        content: [
          '${_lifeText(context, zh: '年柱', en: 'Year')}: ${bazi.bazi.year.naYin} / ${bazi.bazi.year.naYinWuXing}',
          '${_lifeText(context, zh: '月柱', en: 'Month')}: ${bazi.bazi.month.naYin} / ${bazi.bazi.month.naYinWuXing}',
          '${_lifeText(context, zh: '日柱', en: 'Day')}: ${bazi.bazi.day.naYin} / ${bazi.bazi.day.naYinWuXing}',
          '${_lifeText(context, zh: '时柱', en: 'Hour')}: ${bazi.bazi.time.naYin} / ${bazi.bazi.time.naYinWuXing}',
        ].join('\n'),
      ),
      _TextTransformResultBlock(
        title: _lifeText(context, zh: '六十甲子参考', en: 'Sixty JiaZi reference'),
        content:
            '${_lifeText(context, zh: '日柱序号', en: 'Day pillar index')}: $dayIndex\n${_lifeText(context, zh: '年柱序号', en: 'Year pillar index')}: ${_sixtyJiaZi.indexWhere((item) => item == ganzhi.yearGanZhi) + 1}',
      ),
    ];
  }

  List<_TextTransformResultBlock> _baziSearchBlocks(String input) {
    final List<String> pillars = _parseBaziInput(input);
    if (pillars.length != 4) {
      return <_TextTransformResultBlock>[
        _TextTransformResultBlock(
          title: _lifeText(context, zh: '说明', en: 'Note'),
          content: _lifeText(
            context,
            zh: '请输入四柱八字，例如“甲子 乙丑 丙寅 丁卯”。该搜索按北京时间和两小时时辰粒度给出候选结果。',
            en: 'Enter four pillars such as “JiaZi YiChou BingYin DingMao”. The search returns candidate matches using Beijing time and two-hour slots.',
          ),
          highlight: true,
        ),
      ];
    }
    int startYear =
        int.tryParse(_searchStartYearController.text) ?? DateTime.now().year;
    int endYear = int.tryParse(_searchEndYearController.text) ?? startYear;
    if (startYear > endYear) {
      final int temp = startYear;
      startYear = endYear;
      endYear = temp;
    }
    if (endYear - startYear > 5) {
      throw RangeError(
        _lifeText(
          context,
          zh: '为保证移动端可用性，八字候选搜索范围最多 6 个年份。',
          en: 'To keep this mobile-friendly, BaZi candidate search is limited to 6 years.',
        ),
      );
    }
    final List<String> matches = <String>[];
    for (int year = startYear; year <= endYear; year += 1) {
      final DateTime start = DateTime(year, 1, 1);
      final DateTime end = DateTime(year + 1, 1, 1);
      for (
        DateTime day = start;
        day.isBefore(end);
        day = day.add(const Duration(days: 1))
      ) {
        for (int hour = 0; hour < 24; hour += 2) {
          final DateTime sample = DateTime(day.year, day.month, day.day, hour);
          final AstroDateTime local = AstroDateTime(
            sample.year,
            sample.month,
            sample.day,
            sample.hour,
            sample.minute,
            0,
          );
          final AstroDateTime utc = local.subtract(const Duration(hours: 8));
          final AstroDateTime trueSolar = calcTrueSolarTime(
            local,
            Location.beijing,
          ).trueSolarTime;
          final BaZiCalcResult result = calcBaZiAstroDate(utc, trueSolar);
          final List<String> current = <String>[
            result.bazi.year.toString(),
            result.bazi.month.toString(),
            result.bazi.day.toString(),
            result.bazi.time.toString(),
          ];
          if (_listEquals(current, pillars)) {
            matches.add(
              '${_formatDateTime(sample)} (${_timeBranchLabel(hour)})',
            );
            if (matches.length >= 40) {
              break;
            }
          }
        }
        if (matches.length >= 40) {
          break;
        }
      }
    }
    return <_TextTransformResultBlock>[
      _TextTransformResultBlock(
        title: _lifeText(context, zh: '搜索条件', en: 'Search query'),
        content: '${pillars.join(' / ')}\n$startYear - $endYear',
        highlight: true,
      ),
      _TextTransformResultBlock(
        title: _lifeText(context, zh: '候选日期', en: 'Candidate dates'),
        content: matches.isEmpty
            ? _lifeText(
                context,
                zh: '当前范围内没有找到候选结果。',
                en: 'No candidate was found in the selected range.',
              )
            : matches.join('\n'),
        isTable: true,
      ),
    ];
  }

  List<_TextTransformResultBlock> _sixtyJiaZiBlocks(String input) {
    final String query = input.trim();
    final Iterable<String> matches = query.isEmpty
        ? _sixtyJiaZi
        : _sixtyJiaZi.where(
            (item) =>
                item.contains(query) ||
                '${_sixtyJiaZi.indexOf(item) + 1}' == query,
          );
    final StringBuffer table = StringBuffer('序号\t甲子\t纳音\n');
    for (final String item in matches) {
      final int index = _sixtyJiaZi.indexOf(item);
      final GanZhi ganZhi = GanZhi(
        TianGan.values[index % 10],
        DiZhi.values[index % 12],
      );
      table.writeln('${index + 1}\t$item\t${ganZhi.naYin}');
    }
    return <_TextTransformResultBlock>[
      _TextTransformResultBlock(
        title: _lifeText(context, zh: '六十甲子表', en: 'Sixty JiaZi table'),
        content: table.toString().trimRight(),
        copyContent: table.toString().trimRight(),
        highlight: true,
        isTable: true,
      ),
    ];
  }

  List<_TextTransformResultBlock> _languageLookupBlocks(String input) {
    final String query = input.trim();
    final Locale? locale = _tryParseLocale(query);
    final List<_TextTransformResultBlock> blocks =
        <_TextTransformResultBlock>[];
    if (locale != null) {
      blocks.add(
        _TextTransformResultBlock(
          title: _lifeText(context, zh: '标签解析', en: 'Parsed locale'),
          content: [
            'tag: ${_normalizeLocaleTag(locale)}',
            'language: ${locale.languageCode}',
            if ((locale.scriptCode ?? '').isNotEmpty)
              'script: ${locale.scriptCode}',
            if ((locale.countryCode ?? '').isNotEmpty)
              'region: ${locale.countryCode}',
            'english: ${locale.displayLanguageIn(const Locale('en'))}',
            'native: ${locale.nativeDisplayLanguage}',
            if ((locale.countryCode ?? '').isNotEmpty)
              'region name: ${locale.displayCountryIn(const Locale('en'))}',
            if ((locale.countryCode ?? '').isNotEmpty)
              'region native: ${locale.nativeDisplayCountry}',
          ].join('\n'),
          highlight: true,
        ),
      );
    }
    final List<_CommonLanguageItem> matches = _commonLanguages
        .where((item) {
          if (query.isEmpty) {
            return true;
          }
          final String q = query.toLowerCase();
          return item.code.toLowerCase().contains(q) ||
              item.zh.contains(query) ||
              item.en.toLowerCase().contains(q);
        })
        .take(18)
        .toList(growable: false);
    blocks.add(
      _TextTransformResultBlock(
        title: _lifeText(context, zh: '常见语言代码', en: 'Common language codes'),
        content: matches
            .map((item) => '${item.code}\t${item.zh}\t${item.en}')
            .join('\n'),
        copyContent: matches
            .map((item) => '${item.code}\t${item.zh}\t${item.en}')
            .join('\n'),
        isTable: true,
      ),
    );
    if (blocks.isEmpty) {
      blocks.add(
        _TextTransformResultBlock(
          title: _lifeText(context, zh: '说明', en: 'Note'),
          content: _lifeText(
            context,
            zh: '输入类似 en、zh-CN、zh-Hant-TW、fr-CA 的语言标签。',
            en: 'Enter tags such as en, zh-CN, zh-Hant-TW, or fr-CA.',
          ),
          highlight: true,
        ),
      );
    }
    return blocks;
  }

  String _toRoman(int value) {
    if (value <= 0) {
      return _lifeText(
        context,
        zh: '罗马数字不支持 0 和负数',
        en: 'Roman numerals do not support zero or negatives',
      );
    }
    if (value > 3999) {
      return _lifeText(
        context,
        zh: '当前仅支持 1-3999',
        en: 'Currently supports 1-3999 only',
      );
    }
    const List<MapEntry<int, String>> mapping = <MapEntry<int, String>>[
      MapEntry<int, String>(1000, 'M'),
      MapEntry<int, String>(900, 'CM'),
      MapEntry<int, String>(500, 'D'),
      MapEntry<int, String>(400, 'CD'),
      MapEntry<int, String>(100, 'C'),
      MapEntry<int, String>(90, 'XC'),
      MapEntry<int, String>(50, 'L'),
      MapEntry<int, String>(40, 'XL'),
      MapEntry<int, String>(10, 'X'),
      MapEntry<int, String>(9, 'IX'),
      MapEntry<int, String>(5, 'V'),
      MapEntry<int, String>(4, 'IV'),
      MapEntry<int, String>(1, 'I'),
    ];
    int remaining = value;
    final StringBuffer buffer = StringBuffer();
    for (final MapEntry<int, String> entry in mapping) {
      while (remaining >= entry.key) {
        buffer.write(entry.value);
        remaining -= entry.key;
      }
    }
    return buffer.toString();
  }

  String _numberToChineseLower(String source) {
    final bool negative = source.startsWith('-');
    final String normalized = source.replaceAll(',', '').replaceFirst('-', '');
    final List<String> parts = normalized.split('.');
    final int integer = int.parse(parts.first);
    final String fraction = parts.length > 1 ? parts[1] : '';
    final String integerPart = _integerToChinese(
      integer,
      digits: _lowerDigits,
      smallUnits: _lowerSmallUnits,
      bigUnits: _bigUnits,
      stripLeadingOneTen: true,
    );
    if (fraction.isEmpty) {
      return negative ? '负$integerPart' : integerPart;
    }
    final String decimalPart = fraction
        .split('')
        .map((char) => _lowerDigits[int.parse(char)])
        .join();
    return '${negative ? '负' : ''}$integerPart点$decimalPart';
  }

  String _numberToChineseFinancial(String source) {
    final bool negative = source.startsWith('-');
    final String normalized = source.replaceAll(',', '').replaceFirst('-', '');
    final num value = num.parse(normalized);
    final int fenTotal = (value * 100).round();
    final int integer = fenTotal ~/ 100;
    final int jiao = (fenTotal % 100) ~/ 10;
    final int fen = fenTotal % 10;
    final String integerPart = _integerToChinese(
      integer,
      digits: _financialDigits,
      smallUnits: _financialSmallUnits,
      bigUnits: _bigUnits,
      stripLeadingOneTen: false,
    );
    final StringBuffer buffer = StringBuffer();
    if (negative) {
      buffer.write('负');
    }
    buffer.write(integerPart);
    buffer.write('元');
    if (jiao == 0 && fen == 0) {
      buffer.write('整');
      return buffer.toString();
    }
    if (jiao > 0) {
      buffer.write('${_financialDigits[jiao]}角');
    } else if (fen > 0) {
      buffer.write('零');
    }
    if (fen > 0) {
      buffer.write('${_financialDigits[fen]}分');
    }
    return buffer.toString();
  }

  String _numberToEnglishWords(String source) {
    final bool negative = source.startsWith('-');
    final String normalized = source.replaceAll(',', '').replaceFirst('-', '');
    final List<String> parts = normalized.split('.');
    final int integer = int.parse(parts.first);
    final String fraction = parts.length > 1 ? parts[1] : '';
    final String integerPart = _integerToEnglishWords(integer);
    final StringBuffer buffer = StringBuffer();
    if (negative) {
      buffer.write('minus ');
    }
    buffer.write(integerPart);
    if (fraction.isNotEmpty) {
      buffer.write(' point ');
      buffer.write(
        fraction
            .split('')
            .map((char) => _englishDigitWords[int.parse(char)])
            .join(' '),
      );
    }
    return buffer.toString().trim();
  }

  String _integerToEnglishWords(int value) {
    if (value == 0) {
      return 'zero';
    }
    if (value < 20) {
      return _englishBelowTwenty[value];
    }
    if (value < 100) {
      final String tens = _englishTens[value ~/ 10];
      final int remain = value % 10;
      return remain == 0 ? tens : '$tens-${_englishBelowTwenty[remain]}';
    }
    if (value < 1000) {
      final String hundreds = '${_englishBelowTwenty[value ~/ 100]} hundred';
      final int remain = value % 100;
      return remain == 0
          ? hundreds
          : '$hundreds ${_integerToEnglishWords(remain)}';
    }
    final List<String> parts = <String>[];
    int remaining = value;
    int scaleIndex = 0;
    while (remaining > 0) {
      final int chunk = remaining % 1000;
      if (chunk != 0) {
        final String chunkText = _integerToEnglishWords(chunk);
        final String scale = _englishScaleWords[scaleIndex];
        parts.insert(0, scale.isEmpty ? chunkText : '$chunkText $scale');
      }
      remaining ~/= 1000;
      scaleIndex += 1;
    }
    return parts.join(' ');
  }

  String _integerToChinese(
    int value, {
    required List<String> digits,
    required List<String> smallUnits,
    required List<String> bigUnits,
    required bool stripLeadingOneTen,
  }) {
    if (value == 0) {
      return digits[0];
    }
    final List<String> groups = <String>[];
    int working = value.abs();
    while (working > 0) {
      groups.add((working % 10000).toString().padLeft(4, '0'));
      working ~/= 10000;
    }
    final StringBuffer buffer = StringBuffer();
    bool zeroPending = false;
    for (int i = groups.length - 1; i >= 0; i -= 1) {
      final int groupValue = int.parse(groups[i]);
      if (groupValue == 0) {
        zeroPending = buffer.isNotEmpty;
        continue;
      }
      if (zeroPending) {
        buffer.write(digits[0]);
        zeroPending = false;
      }
      final String groupText = _fourDigitsToChinese(
        groupValue,
        digits: digits,
        smallUnits: smallUnits,
      );
      buffer.write(groupText);
      if (i > 0) {
        buffer.write(bigUnits[i]);
      }
      if (groupValue < 1000 && i > 0) {
        zeroPending = true;
      }
    }
    String result = buffer.toString();
    if (stripLeadingOneTen && result.startsWith('一十')) {
      result = result.substring(1);
    }
    return result;
  }

  String _fourDigitsToChinese(
    int value, {
    required List<String> digits,
    required List<String> smallUnits,
  }) {
    final String text = value.toString().padLeft(4, '0');
    final StringBuffer buffer = StringBuffer();
    bool zeroPending = false;
    for (int i = 0; i < text.length; i += 1) {
      final int digit = int.parse(text[i]);
      final int unitIndex = text.length - 1 - i;
      if (digit == 0) {
        if (buffer.isNotEmpty) {
          zeroPending = true;
        }
        continue;
      }
      if (zeroPending) {
        buffer.write(digits[0]);
        zeroPending = false;
      }
      buffer.write(digits[digit]);
      if (unitIndex > 0) {
        buffer.write(smallUnits[unitIndex - 1]);
      }
    }
    return buffer.toString();
  }

  String _htmlEscape(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  String _htmlUnescape(String text) {
    return text
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&amp;', '&');
  }

  String _unicodeEscape(String text) {
    final StringBuffer buffer = StringBuffer();
    for (final int rune in text.runes) {
      buffer.write('\\u${rune.toRadixString(16).padLeft(4, '0')}');
    }
    return buffer.toString();
  }

  String _unicodeUnescape(String text) {
    return text.replaceAllMapped(
      RegExp(r'\\u([0-9a-fA-F]{4,6})'),
      (Match match) =>
          String.fromCharCode(int.parse(match.group(1)!, radix: 16)),
    );
  }

  String _jsonStringSafe(String text) {
    return text
        .replaceAll(r'\', r'\\')
        .replaceAll('"', r'\"')
        .replaceAll('\n', r'\n')
        .replaceAll('\r', r'\r')
        .replaceAll('\t', r'\t');
  }

  String _jsonUnescape(String text) {
    return text
        .replaceAll(r'\n', '\n')
        .replaceAll(r'\r', '\r')
        .replaceAll(r'\t', '\t')
        .replaceAll(r'\"', '"')
        .replaceAll(r'\\', r'\');
  }

  String _toMorse(String text) {
    return text
        .split('')
        .map((String char) => _morseMap[char.toLowerCase()] ?? char)
        .join(' ');
  }

  String _fromMorse(String text) {
    final Map<String, String> reversed = <String, String>{
      for (final MapEntry<String, String> entry in _morseMap.entries)
        entry.value: entry.key,
    };
    return text
        .trim()
        .split(RegExp(r'\s+'))
        .map((String token) => reversed[token] ?? token)
        .join();
  }

  String _rc4Base64Encode(String plain, String key) {
    return base64Encode(_rc4Bytes(utf8.encode(plain), key));
  }

  String _rc4Base64Decode(String cipher, String key) {
    final Uint8List decoded = _rc4Bytes(base64Decode(cipher.trim()), key);
    return utf8.decode(decoded);
  }

  Uint8List _rc4Bytes(List<int> data, String key) {
    final List<int> keyBytes = utf8.encode(key.isEmpty ? 'k' : key);
    final List<int> state = List<int>.generate(256, (int index) => index);
    int j = 0;
    for (int i = 0; i < 256; i += 1) {
      j = (j + state[i] + keyBytes[i % keyBytes.length]) & 255;
      final int temp = state[i];
      state[i] = state[j];
      state[j] = temp;
    }
    int i = 0;
    j = 0;
    final Uint8List out = Uint8List(data.length);
    for (int k = 0; k < data.length; k += 1) {
      i = (i + 1) & 255;
      j = (j + state[i]) & 255;
      final int temp = state[i];
      state[i] = state[j];
      state[j] = temp;
      final int t = (state[i] + state[j]) & 255;
      out[k] = data[k] ^ state[t];
    }
    return out;
  }

  String _toMars(String text) {
    final StringBuffer buffer = StringBuffer();
    int index = 0;
    while (index < text.length) {
      String? matched;
      String? replacement;
      for (final MapEntry<String, String> entry in _phraseToMarsMap.entries) {
        if (text.startsWith(entry.key, index)) {
          matched = entry.key;
          replacement = entry.value;
          break;
        }
      }
      if (matched != null && replacement != null) {
        buffer.write(replacement);
        index += matched.length;
        continue;
      }
      final String char = text[index];
      buffer.write(_simpleToMarsMap[char] ?? char);
      index += 1;
    }
    return buffer.toString();
  }

  String _fromMars(String text) {
    final StringBuffer buffer = StringBuffer();
    int index = 0;
    while (index < text.length) {
      String? matched;
      String? replacement;
      for (final MapEntry<String, String> entry in _phraseFromMarsMap.entries) {
        if (text.startsWith(entry.key, index)) {
          matched = entry.key;
          replacement = entry.value;
          break;
        }
      }
      if (matched != null && replacement != null) {
        buffer.write(replacement);
        index += matched.length;
        continue;
      }
      final String char = text[index];
      buffer.write(_marsToSimpleMap[char] ?? char);
      index += 1;
    }
    return buffer.toString();
  }

  String _toFullWidthString(String text) {
    final StringBuffer buffer = StringBuffer();
    for (final int rune in text.runes) {
      if (rune == 32) {
        buffer.writeCharCode(12288);
      } else if (rune >= 33 && rune <= 126) {
        buffer.writeCharCode(rune + 65248);
      } else {
        buffer.writeCharCode(rune);
      }
    }
    return buffer.toString();
  }

  String _toHalfWidthString(String text) {
    final StringBuffer buffer = StringBuffer();
    for (final int rune in text.runes) {
      if (rune == 12288) {
        buffer.writeCharCode(32);
      } else if (rune >= 65281 && rune <= 65374) {
        buffer.writeCharCode(rune - 65248);
      } else {
        buffer.writeCharCode(rune);
      }
    }
    return buffer.toString();
  }

  String _verticalLayout(
    String text, {
    required int columns,
    required int rows,
    required int borderStyle,
    required bool useTraditional,
  }) {
    final String normalized = useTraditional
        ? ChineseHelper.convertToTraditionalChinese(text)
        : text;
    final String source = normalized.replaceAll('\r', '');
    final List<List<String>> page = List<List<String>>.generate(
      columns,
      (_) => List<String>.filled(rows, '\u3000'),
    );
    int column = columns - 1;
    int row = 0;
    for (final String char in source.split('')) {
      if (char == '\n') {
        column -= 1;
        row = 0;
        if (column < 0) {
          break;
        }
        continue;
      }
      page[column][row] = _toFullWidthString(char);
      row += 1;
      if (row >= rows) {
        row = 0;
        column -= 1;
        if (column < 0) {
          break;
        }
      }
    }
    final _VerticalBorderChars chars =
        _verticalBorderStyles[borderStyle.clamp(
          0,
          _verticalBorderStyles.length - 1,
        )];
    final List<String> lines = <String>[
      '${chars.topLeft}${List<String>.filled(columns, chars.horizontal).join()}${chars.topRight}',
    ];
    for (int rowIndex = 0; rowIndex < rows; rowIndex += 1) {
      final StringBuffer line = StringBuffer();
      line.write(chars.left);
      for (int columnIndex = 0; columnIndex < columns; columnIndex += 1) {
        line.write(page[columnIndex][rowIndex]);
      }
      line.write(chars.right);
      lines.add(line.toString());
    }
    lines.add(
      '${chars.bottomLeft}${List<String>.filled(columns, chars.horizontal).join()}${chars.bottomRight}',
    );
    return lines.join('\n');
  }

  String _embedHiddenText(String cover, String hidden) {
    if (cover.isEmpty) {
      return hidden;
    }
    final String encoded = _encodeZeroWidth(hidden);
    return '${cover.characters.first}$encoded${cover.characters.skip(1).toString()}';
  }

  String _revealHiddenText(String text) {
    return _decodeZeroWidth(text);
  }

  String _encodeZeroWidth(String text) {
    final StringBuffer digits = StringBuffer();
    for (final int codeUnit in text.codeUnits) {
      digits.write(codeUnit.toRadixString(5).padLeft(7, '0'));
    }
    final StringBuffer output = StringBuffer();
    for (final String digit in digits.toString().split('')) {
      output.write(_zeroWidthAlphabet[int.parse(digit)]);
    }
    return output.toString();
  }

  String _decodeZeroWidth(String text) {
    final StringBuffer digits = StringBuffer();
    for (final String char in text.split('')) {
      final int index = _zeroWidthAlphabet.indexOf(char);
      if (index >= 0) {
        digits.write(index);
      }
    }
    if (digits.isEmpty || digits.length % 7 != 0) {
      return '';
    }
    final List<int> codeUnits = <int>[];
    for (int i = 0; i < digits.length; i += 7) {
      codeUnits.add(int.parse(digits.toString().substring(i, i + 7), radix: 5));
    }
    return String.fromCharCodes(codeUnits);
  }

  List<_TextTransformResultBlock> _mojibakeCandidates(String text) {
    final List<_TextTransformResultBlock> blocks = <_TextTransformResultBlock>[
      _TextTransformResultBlock(
        title: _lifeText(context, zh: '原文', en: 'Original'),
        content: text,
        highlight: true,
      ),
    ];
    final List<_MojibakeCandidate> candidates = _buildMojibakeCandidates(text);
    for (final _MojibakeCandidate candidate in candidates) {
      blocks.add(
        _TextTransformResultBlock(
          title: candidate.title(context),
          content: candidate.content,
        ),
      );
    }
    if (candidates.isEmpty) {
      blocks.add(
        _TextTransformResultBlock(
          title: _lifeText(context, zh: '说明', en: 'Note'),
          content: _lifeText(
            context,
            zh: '当前输入没有出现更清晰的常见候选，这通常意味着它不是典型乱码，或者仍然缺少原始编码上下文。',
            en: 'No clearer common candidate was found. The input may not be typical mojibake, or it may still need the original encoding context.',
          ),
        ),
      );
    }
    return blocks;
  }

  List<_MojibakeCandidate> _buildMojibakeCandidates(String text) {
    final List<_MojibakeCandidate> candidates = <_MojibakeCandidate>[];
    for (final _MojibakeCodecPair pair in _mojibakePairs) {
      final String content = pair.transform(text);
      if (content.isEmpty || content == text) {
        continue;
      }
      candidates.add(
        _MojibakeCandidate(
          fromZh: pair.fromZh,
          toZh: pair.toZh,
          fromEn: pair.fromEn,
          toEn: pair.toEn,
          content: content,
        ),
      );
    }
    return candidates;
  }

  String _buildCodePointTable(String text) {
    if (text.isEmpty) {
      return _lifeText(
        context,
        zh: '请输入文本后查看码位。',
        en: 'Enter text to inspect code points.',
      );
    }
    final StringBuffer buffer = StringBuffer('char\tU+\tdec\tbin\n');
    for (final int rune in text.runes) {
      final String char = String.fromCharCode(rune);
      buffer.writeln(
        '$char\tU+${rune.toRadixString(16).toUpperCase().padLeft(4, '0')}\t$rune\t${rune.toRadixString(2)}',
      );
    }
    return buffer.toString().trimRight();
  }

  String _buildAsciiTable(String filter) {
    final StringBuffer buffer = StringBuffer('dec\thex\tchar\tname\n');
    final Set<int> allowed = filter.isEmpty
        ? <int>{}
        : filter.codeUnits.toSet();
    for (int code = 0; code < 128; code += 1) {
      if (allowed.isNotEmpty && !allowed.contains(code)) {
        continue;
      }
      final String char = code < 32 || code == 127
          ? ' '
          : String.fromCharCode(code);
      buffer.writeln(
        '$code\t0x${code.toRadixString(16).padLeft(2, '0').toUpperCase()}\t$char\t${_asciiName(code)}',
      );
    }
    return buffer.toString().trimRight();
  }

  String _festivalSummary(DayInfo info) {
    if (info.festivals.isEmpty) {
      return _lifeText(
        context,
        zh: '当天没有收录到高频节日或民俗提示。',
        en: 'No major festivals or customs were recorded for this day.',
      );
    }
    final List<Festival> primary = info.getFestivalsByLevel();
    final List<Festival> commemorative = info.getFestivalsByLevel(
      levels: <FestivalLevel>{
        FestivalLevel.commemorative,
        FestivalLevel.historical,
      },
    );
    final List<Festival> ethnic = info.getFestivalsByLevel(
      levels: <FestivalLevel>{FestivalLevel.ethnic},
    );
    return <String>[
      if (primary.isNotEmpty)
        '${_lifeText(context, zh: '主要节日', en: 'Primary festivals')}: ${primary.join(' / ')}',
      if (commemorative.isNotEmpty)
        '${_lifeText(context, zh: '纪念与科普', en: 'Commemorative')}: ${commemorative.join(' / ')}',
      if (ethnic.isNotEmpty)
        '${_lifeText(context, zh: '民族与地方', en: 'Ethnic and local')}: ${ethnic.join(' / ')}',
      '${_lifeText(context, zh: '全量条目', en: 'All entries')}: ${info.festivals.join(' / ')}',
    ].join('\n');
  }

  String _asciiName(int code) {
    return _asciiControlNames[code] ?? (code == 127 ? 'DEL' : 'Printable');
  }

  List<_TextTransformResultBlock> _commonMapTable(String text) {
    final String safe = text.isEmpty ? ' ' : text;
    return <_TextTransformResultBlock>[
      _TextTransformResultBlock(
        title: 'UTF-8 bytes',
        content: utf8
            .encode(safe)
            .map((int byte) => byte.toRadixString(16).padLeft(2, '0'))
            .join(' '),
        highlight: true,
      ),
      _TextTransformResultBlock(
        title: 'Base64',
        content: base64Encode(utf8.encode(safe)),
      ),
      _TextTransformResultBlock(
        title: 'URL',
        content: Uri.encodeComponent(safe),
      ),
      _TextTransformResultBlock(
        title: 'Unicode',
        content: _unicodeEscape(safe),
      ),
      _TextTransformResultBlock(
        title: _lifeText(context, zh: '字符码位', en: 'Code points'),
        content: _buildCodePointTable(safe),
        isTable: true,
      ),
    ];
  }

  List<String> _parseBaziInput(String input) {
    final List<String> tokens = input
        .trim()
        .split(RegExp(r'[\s,/，、]+'))
        .where((token) => token.isNotEmpty)
        .toList(growable: false);
    if (tokens.length == 4) {
      return tokens;
    }
    final String compact = input.replaceAll(RegExp(r'[\s,/，、]+'), '');
    if (compact.length == 8) {
      return List<String>.generate(
        4,
        (index) => compact.substring(index * 2, index * 2 + 2),
      );
    }
    return const <String>[];
  }

  Locale? _tryParseLocale(String input) {
    if (input.trim().isEmpty) {
      return null;
    }
    final List<String> parts = input
        .trim()
        .replaceAll('-', '_')
        .split('_')
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) {
      return null;
    }
    final String languageCode = parts.first.toLowerCase();
    String? scriptCode;
    String? countryCode;
    for (final String part in parts.skip(1)) {
      if (part.length == 4 && scriptCode == null) {
        scriptCode =
            '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}';
      } else if (countryCode == null) {
        countryCode = part.toUpperCase();
      }
    }
    return Locale.fromSubtags(
      languageCode: languageCode,
      scriptCode: scriptCode,
      countryCode: countryCode,
    );
  }

  String _normalizeLocaleTag(Locale locale) {
    final List<String> parts = <String>[locale.languageCode];
    if ((locale.scriptCode ?? '').isNotEmpty) {
      parts.add(locale.scriptCode!);
    }
    if ((locale.countryCode ?? '').isNotEmpty) {
      parts.add(locale.countryCode!);
    }
    return parts.join('-');
  }

  String _lunarDayName(int day) {
    if (day <= 10) {
      return '初${_lowerDigits[day]}';
    }
    if (day < 20) {
      return '十${_lowerDigits[day - 10]}';
    }
    if (day == 20) {
      return '二十';
    }
    if (day < 30) {
      return '廿${_lowerDigits[day - 20]}';
    }
    return '三十';
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime date) {
    return '${_formatDate(date)} ${_formatTime(date)}';
  }

  String _timeBranchLabel(int hour) {
    final int index = ((hour + 1) ~/ 2) % 12;
    return _timeBranchNames[index];
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) {
      return false;
    }
    for (int i = 0; i < a.length; i += 1) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }

  int _safePositiveInt(String text, int fallback) {
    final int? parsed = int.tryParse(text);
    if (parsed == null || parsed <= 0) {
      return fallback;
    }
    return parsed;
  }
}

class _MojibakeCandidate {
  const _MojibakeCandidate({
    required this.fromZh,
    required this.toZh,
    required this.fromEn,
    required this.toEn,
    required this.content,
  });

  final String fromZh;
  final String toZh;
  final String fromEn;
  final String toEn;
  final String content;

  String title(BuildContext context) {
    return _lifeText(context, zh: '$fromZh -> $toZh', en: '$fromEn -> $toEn');
  }
}

class _MojibakeCodecPair {
  const _MojibakeCodecPair({
    required this.fromZh,
    required this.toZh,
    required this.fromEn,
    required this.toEn,
    required this.transform,
  });

  final String fromZh;
  final String toZh;
  final String fromEn;
  final String toEn;
  final String Function(String text) transform;
}

class _VerticalBorderChars {
  const _VerticalBorderChars({
    required this.topLeft,
    required this.topRight,
    required this.bottomLeft,
    required this.bottomRight,
    required this.left,
    required this.right,
    required this.horizontal,
  });

  final String topLeft;
  final String topRight;
  final String bottomLeft;
  final String bottomRight;
  final String left;
  final String right;
  final String horizontal;
}

const List<_VerticalBorderChars> _verticalBorderStyles = <_VerticalBorderChars>[
  _VerticalBorderChars(
    topLeft: '┌',
    topRight: '┐',
    bottomLeft: '└',
    bottomRight: '┘',
    left: '│',
    right: '│',
    horizontal: '─',
  ),
  _VerticalBorderChars(
    topLeft: '╭',
    topRight: '╮',
    bottomLeft: '╰',
    bottomRight: '╯',
    left: '│',
    right: '│',
    horizontal: '─',
  ),
  _VerticalBorderChars(
    topLeft: '┏',
    topRight: '┓',
    bottomLeft: '┗',
    bottomRight: '┛',
    left: '┃',
    right: '┃',
    horizontal: '━',
  ),
  _VerticalBorderChars(
    topLeft: ' ',
    topRight: ' ',
    bottomLeft: ' ',
    bottomRight: ' ',
    left: '│',
    right: '│',
    horizontal: '─',
  ),
  _VerticalBorderChars(
    topLeft: ' ',
    topRight: ' ',
    bottomLeft: ' ',
    bottomRight: ' ',
    left: ' ',
    right: ' ',
    horizontal: ' ',
  ),
];

const Map<String, String> _morseMap = <String, String>{
  'a': '.-',
  'b': '-...',
  'c': '-.-.',
  'd': '-..',
  'e': '.',
  'f': '..-.',
  'g': '--.',
  'h': '....',
  'i': '..',
  'j': '.---',
  'k': '-.-',
  'l': '.-..',
  'm': '--',
  'n': '-.',
  'o': '---',
  'p': '.--.',
  'q': '--.-',
  'r': '.-.',
  's': '...',
  't': '-',
  'u': '..-',
  'v': '...-',
  'w': '.--',
  'x': '-..-',
  'y': '-.--',
  'z': '--..',
  '0': '-----',
  '1': '.----',
  '2': '..---',
  '3': '...--',
  '4': '....-',
  '5': '.....',
  '6': '-....',
  '7': '--...',
  '8': '---..',
  '9': '----.',
};

const List<String> _zeroWidthAlphabet = <String>[
  '\u200B',
  '\u200C',
  '\u200D',
  '\u200E',
  '\u200F',
];

const Map<int, String> _asciiControlNames = <int, String>{
  0: 'NUL',
  1: 'SOH',
  2: 'STX',
  3: 'ETX',
  4: 'EOT',
  5: 'ENQ',
  6: 'ACK',
  7: 'BEL',
  8: 'BS',
  9: 'TAB',
  10: 'LF',
  11: 'VT',
  12: 'FF',
  13: 'CR',
  14: 'SO',
  15: 'SI',
  16: 'DLE',
  17: 'DC1',
  18: 'DC2',
  19: 'DC3',
  20: 'DC4',
  21: 'NAK',
  22: 'SYN',
  23: 'ETB',
  24: 'CAN',
  25: 'EM',
  26: 'SUB',
  27: 'ESC',
  28: 'FS',
  29: 'GS',
  30: 'RS',
  31: 'US',
};

const Map<String, String> _phraseToMarsMap = <String, String>{
  '为什么': '為什麼',
  '怎么了': '怎麼ㄋ',
  '怎么办': '怎麼辦',
  '不知道': '吥知道',
  '不是': '吥昰',
  '不要': '吥崾',
  '不能': '吥螚',
  '可以': '岢苡',
  '真的': '眞啲',
  '喜欢': '囍歡',
  '谢谢': '蟹蟹',
  '对不起': '對吥起',
  '没关系': '沒關係',
  '这样': '這樣',
  '那个': '內嗰',
  '感觉': '感覺',
  '东西': '東覀',
  '今天': '紟迗',
  '明天': '朙迗',
  '昨天': '昨迗',
  '一起': '①起',
  '已经': '巳經',
  '因为': '洇為',
  '所以': '葰苡',
  '什么': '什麼',
  '有没有': '冇沒有',
  '我是': '莪昰',
  '你好': '伱ぬ',
};

const Map<String, String> _simpleToMarsMap = <String, String>{
  '你': '伱',
  '我': '莪',
  '他': '祂',
  '她': '祂',
  '它': '牠',
  '们': '們',
  '来': '莱',
  '了': 'ㄋ',
  '吗': '嗎',
  '嘛': '嗎',
  '吧': '叭',
  '好': 'ぬ',
  '是': '昰',
  '的': '啲',
  '不': '吥',
  '爱': '噯',
  '想': '葙',
  '这': '這',
  '那': '那',
  '个': '嗰',
  '很': '狠',
  '啦': '喇',
  '呀': '吖',
  '啊': '吖',
  '哈': '蛤',
  '说': '說',
  '听': '聽',
  '见': '見',
  '会': '會',
  '给': '給',
  '让': '讓',
  '过': '過',
  '还': '還',
  '为': '為',
  '后': '後',
};

final Map<String, String> _marsToSimpleMap = <String, String>{
  for (final MapEntry<String, String> entry in _simpleToMarsMap.entries)
    entry.value: entry.key,
};

final Map<String, String> _phraseFromMarsMap = <String, String>{
  for (final MapEntry<String, String> entry in _phraseToMarsMap.entries)
    entry.value: entry.key,
};

const List<String> _lowerDigits = <String>[
  '零',
  '一',
  '二',
  '三',
  '四',
  '五',
  '六',
  '七',
  '八',
  '九',
];

const List<String> _financialDigits = <String>[
  '零',
  '壹',
  '贰',
  '叁',
  '肆',
  '伍',
  '陆',
  '柒',
  '捌',
  '玖',
];

const List<String> _lowerSmallUnits = <String>['十', '百', '千'];
const List<String> _financialSmallUnits = <String>['拾', '佰', '仟'];
const List<String> _bigUnits = <String>['', '万', '亿', '兆'];

const List<String> _englishBelowTwenty = <String>[
  'zero',
  'one',
  'two',
  'three',
  'four',
  'five',
  'six',
  'seven',
  'eight',
  'nine',
  'ten',
  'eleven',
  'twelve',
  'thirteen',
  'fourteen',
  'fifteen',
  'sixteen',
  'seventeen',
  'eighteen',
  'nineteen',
];

const List<String> _englishTens = <String>[
  '',
  '',
  'twenty',
  'thirty',
  'forty',
  'fifty',
  'sixty',
  'seventy',
  'eighty',
  'ninety',
];

const List<String> _englishDigitWords = <String>[
  'zero',
  'one',
  'two',
  'three',
  'four',
  'five',
  'six',
  'seven',
  'eight',
  'nine',
];

const List<String> _englishScaleWords = <String>[
  '',
  'thousand',
  'million',
  'billion',
  'trillion',
];

const List<String> _lunarMonthNames = <String>[
  '正',
  '二',
  '三',
  '四',
  '五',
  '六',
  '七',
  '八',
  '九',
  '十',
  '冬',
  '腊',
];

const List<String> _timeBranchNames = <String>[
  '子时',
  '丑时',
  '寅时',
  '卯时',
  '辰时',
  '巳时',
  '午时',
  '未时',
  '申时',
  '酉时',
  '戌时',
  '亥时',
];

final List<String> _sixtyJiaZi = List<String>.generate(
  60,
  (int index) =>
      GanZhi(TianGan.values[index % 10], DiZhi.values[index % 12]).toString(),
  growable: false,
);

const List<_CommonLanguageItem> _commonLanguages = <_CommonLanguageItem>[
  _CommonLanguageItem(code: 'zh', zh: '中文', en: 'Chinese'),
  _CommonLanguageItem(
    code: 'zh-CN',
    zh: '简体中文（中国）',
    en: 'Chinese (Simplified, China)',
  ),
  _CommonLanguageItem(code: 'zh-Hant', zh: '繁体中文', en: 'Chinese (Traditional)'),
  _CommonLanguageItem(
    code: 'zh-Hant-TW',
    zh: '繁体中文（台湾）',
    en: 'Chinese (Traditional, Taiwan)',
  ),
  _CommonLanguageItem(code: 'zh-HK', zh: '中文（香港）', en: 'Chinese (Hong Kong)'),
  _CommonLanguageItem(code: 'en', zh: '英语', en: 'English'),
  _CommonLanguageItem(
    code: 'en-US',
    zh: '英语（美国）',
    en: 'English (United States)',
  ),
  _CommonLanguageItem(
    code: 'en-GB',
    zh: '英语（英国）',
    en: 'English (United Kingdom)',
  ),
  _CommonLanguageItem(code: 'ja', zh: '日语', en: 'Japanese'),
  _CommonLanguageItem(code: 'ko', zh: '韩语', en: 'Korean'),
  _CommonLanguageItem(code: 'fr', zh: '法语', en: 'French'),
  _CommonLanguageItem(code: 'fr-CA', zh: '法语（加拿大）', en: 'French (Canada)'),
  _CommonLanguageItem(code: 'de', zh: '德语', en: 'German'),
  _CommonLanguageItem(code: 'es', zh: '西班牙语', en: 'Spanish'),
  _CommonLanguageItem(code: 'es-MX', zh: '西班牙语（墨西哥）', en: 'Spanish (Mexico)'),
  _CommonLanguageItem(code: 'pt', zh: '葡萄牙语', en: 'Portuguese'),
  _CommonLanguageItem(code: 'pt-BR', zh: '葡萄牙语（巴西）', en: 'Portuguese (Brazil)'),
  _CommonLanguageItem(code: 'ru', zh: '俄语', en: 'Russian'),
  _CommonLanguageItem(code: 'ar', zh: '阿拉伯语', en: 'Arabic'),
  _CommonLanguageItem(code: 'hi', zh: '印地语', en: 'Hindi'),
  _CommonLanguageItem(code: 'th', zh: '泰语', en: 'Thai'),
  _CommonLanguageItem(code: 'vi', zh: '越南语', en: 'Vietnamese'),
  _CommonLanguageItem(code: 'id', zh: '印尼语', en: 'Indonesian'),
  _CommonLanguageItem(code: 'ms', zh: '马来语', en: 'Malay'),
  _CommonLanguageItem(code: 'it', zh: '意大利语', en: 'Italian'),
  _CommonLanguageItem(code: 'tr', zh: '土耳其语', en: 'Turkish'),
];

final List<_MojibakeCodecPair> _mojibakePairs = <_MojibakeCodecPair>[
  _MojibakeCodecPair(
    fromZh: 'UTF-8 被当作 Latin-1',
    toZh: '按 Latin-1 回收后转 UTF-8',
    fromEn: 'UTF-8 as Latin-1',
    toEn: 'Recover Latin-1 then UTF-8',
    transform: (String text) {
      try {
        return utf8.decode(latin1.encode(text));
      } catch (_) {
        return '';
      }
    },
  ),
  _MojibakeCodecPair(
    fromZh: 'UTF-8 字节转十六进制',
    toZh: '观察原始字节',
    fromEn: 'UTF-8 to hex',
    toEn: 'Inspect raw bytes',
    transform: (String text) => utf8
        .encode(text)
        .map((int e) => e.toRadixString(16).padLeft(2, '0'))
        .join(' '),
  ),
  _MojibakeCodecPair(
    fromZh: 'Latin-1 字符转十进制',
    toZh: '观察码位',
    fromEn: 'Latin-1 chars to dec',
    toEn: 'Inspect code units',
    transform: (String text) => text.codeUnits.join(' '),
  ),
];
