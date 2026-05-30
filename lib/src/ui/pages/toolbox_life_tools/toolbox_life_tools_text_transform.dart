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
    required this.labelKey,
    required this.summaryKey,
  });

  final _TextTransformMode mode;
  final _TextTransformCategory category;
  final String labelKey;
  final String summaryKey;

  String label(BuildContext context) {
    return _lifeI18nText(context, labelKey);
  }

  String summary(BuildContext context) {
    return _lifeI18nText(context, summaryKey);
  }
}

const List<_TextTransformModeDefinition>
_textTransformDefinitions = <_TextTransformModeDefinition>[
  _TextTransformModeDefinition(
    mode: _TextTransformMode.phoneticBundle,
    category: _TextTransformCategory.phonetic,
    labelKey: 'inline.plan295.life.pinyin_and_zhuyin.88e3d544cfe1',
    summaryKey:
        'inline.plan295.life.convert_chinese_into_pinyin_initials.c7887643cd6f',
  ),
  _TextTransformModeDefinition(
    mode: _TextTransformMode.scriptConvert,
    category: _TextTransformCategory.phonetic,
    labelKey: 'inline.plan295.life.simplified_and_traditional.384ff540c259',
    summaryKey:
        'inline.plan295.life.convert_between_simplified_and_tradi.7e7c3a033251',
  ),
  _TextTransformModeDefinition(
    mode: _TextTransformMode.numberBundle,
    category: _TextTransformCategory.number,
    labelKey: 'inline.plan295.life.number_writing.2333611f8a6b',
    summaryKey:
        'inline.plan295.life.turn_arabic_numerals_into_roman_nume.c296bcc09c65',
  ),
  _TextTransformModeDefinition(
    mode: _TextTransformMode.solarToLunar,
    category: _TextTransformCategory.calendar,
    labelKey: 'inline.plan295.life.solar_to_lunar.c819bf4094a6',
    summaryKey:
        'inline.plan295.life.convert_a_solar_date_into_lunar_date.bb2b584507fa',
  ),
  _TextTransformModeDefinition(
    mode: _TextTransformMode.lunarToSolar,
    category: _TextTransformCategory.calendar,
    labelKey: 'inline.plan295.life.lunar_to_solar.5aaa3f42067c',
    summaryKey:
        'inline.plan295.life.convert_a_lunar_date_back_into_the_c.187b534c0c5d',
  ),
  _TextTransformModeDefinition(
    mode: _TextTransformMode.almanac,
    category: _TextTransformCategory.calendar,
    labelKey: 'inline.plan295.life.almanac_snapshot.1740672734e4',
    summaryKey:
        'inline.plan295.life.show_a_daily_snapshot_with_solar_lun.73477242d896',
  ),
  _TextTransformModeDefinition(
    mode: _TextTransformMode.dateToGanzhi,
    category: _TextTransformCategory.ganzhi,
    labelKey: 'inline.plan295.life.date_to_ganzhi_and_bazi.982cb8408d5e',
    summaryKey:
        'inline.plan295.life.convert_a_date_and_time_into_ganzhi.bdb027425c82',
  ),
  _TextTransformModeDefinition(
    mode: _TextTransformMode.baziSearch,
    category: _TextTransformCategory.ganzhi,
    labelKey: 'inline.plan295.life.bazi_candidate_search.6764c17c44dd',
    summaryKey:
        'inline.plan295.life.search_limited_year_ranges_for_candi.1f36769db9b1',
  ),
  _TextTransformModeDefinition(
    mode: _TextTransformMode.sixtyJiaZi,
    category: _TextTransformCategory.ganzhi,
    labelKey: 'inline.plan295.life.sixty_jiazi.07153f8697e7',
    summaryKey:
        'inline.plan295.life.look_up_sixty_jiazi_order_na_yin_and.4368f064fa6f',
  ),
  _TextTransformModeDefinition(
    mode: _TextTransformMode.languageLookup,
    category: _TextTransformCategory.language,
    labelKey: 'inline.plan295.life.language_code_lookup.74089c4fc079',
    summaryKey:
        'inline.plan295.life.query_common_language_and_region_cod.b08f8831b4b2',
  ),
  _TextTransformModeDefinition(
    mode: _TextTransformMode.base64Encode,
    category: _TextTransformCategory.encode,
    labelKey: 'inline.plan295.life.base64_encode.ff03c2751c21',
    summaryKey: 'inline.plan295.life.encode_text_into_base64.f81b4f144fce',
  ),
  _TextTransformModeDefinition(
    mode: _TextTransformMode.base64Decode,
    category: _TextTransformCategory.encode,
    labelKey: 'inline.plan295.life.base64_decode.34f2a5dfe8af',
    summaryKey: 'inline.plan295.life.decode_base64_back_into_text.e1ac19b60beb',
  ),
  _TextTransformModeDefinition(
    mode: _TextTransformMode.urlEncode,
    category: _TextTransformCategory.encode,
    labelKey: 'inline.plan295.life.url_encode.22ba723dbaf8',
    summaryKey:
        'inline.plan295.life.escape_text_into_a_url_safe_represen.14029fad8051',
  ),
  _TextTransformModeDefinition(
    mode: _TextTransformMode.urlDecode,
    category: _TextTransformCategory.encode,
    labelKey: 'inline.plan295.life.url_decode.2bbaf7686a4d',
    summaryKey: 'inline.plan295.life.decode_url_escaped_text.4d6c380d339c',
  ),
  _TextTransformModeDefinition(
    mode: _TextTransformMode.htmlEscape,
    category: _TextTransformCategory.encode,
    labelKey: 'inline.plan295.life.html_escape.bdd8c9a3566d',
    summaryKey:
        'inline.plan295.life.escape_html_sensitive_characters.9eea0c864bab',
  ),
  _TextTransformModeDefinition(
    mode: _TextTransformMode.htmlUnescape,
    category: _TextTransformCategory.encode,
    labelKey: 'inline.plan295.life.html_unescape.67ae45cdb20b',
    summaryKey: 'inline.plan295.life.restore_common_html_entities.5e8244146f83',
  ),
  _TextTransformModeDefinition(
    mode: _TextTransformMode.unicodeEscape,
    category: _TextTransformCategory.encode,
    labelKey: 'inline.plan295.life.unicode_escape.ff47ff475926',
    summaryKey:
        'inline.plan295.life.convert_text_into_uxxxx_sequences.575a407bab52',
  ),
  _TextTransformModeDefinition(
    mode: _TextTransformMode.unicodeUnescape,
    category: _TextTransformCategory.encode,
    labelKey: 'inline.plan295.life.unicode_unescape.c28f726724a7',
    summaryKey:
        'inline.plan295.life.decode_uxxxx_sequences_back_into_cha.43ba9e4c6224',
  ),
  _TextTransformModeDefinition(
    mode: _TextTransformMode.jsonEscape,
    category: _TextTransformCategory.encode,
    labelKey: 'inline.plan295.life.json_escape.e1ec7f71ffd5',
    summaryKey:
        'inline.plan295.life.escape_text_for_safe_insertion_into.0bf7e085ab9b',
  ),
  _TextTransformModeDefinition(
    mode: _TextTransformMode.jsonUnescape,
    category: _TextTransformCategory.encode,
    labelKey: 'inline.plan295.life.json_unescape.d57584070a8c',
    summaryKey:
        'inline.plan295.life.restore_common_escape_sequences_from.21597c889ab0',
  ),
  _TextTransformModeDefinition(
    mode: _TextTransformMode.morseEncode,
    category: _TextTransformCategory.encode,
    labelKey: 'inline.plan295.life.morse_encode.fdb81340184b',
    summaryKey:
        'inline.plan295.life.encode_letters_and_digits_into_morse.ddc4500829d7',
  ),
  _TextTransformModeDefinition(
    mode: _TextTransformMode.morseDecode,
    category: _TextTransformCategory.encode,
    labelKey: 'inline.plan295.life.morse_decode.c233a2bfc2b0',
    summaryKey:
        'inline.plan295.life.decode_space_separated_morse_code.aed4ec495bfd',
  ),
  _TextTransformModeDefinition(
    mode: _TextTransformMode.rc4Encode,
    category: _TextTransformCategory.encode,
    labelKey: 'inline.plan295.life.rc4_legacy_encode.a761c8f15c07',
    summaryKey:
        'inline.plan295.life.generate_base64_rc4_output_for_legac.d9a63cf47878',
  ),
  _TextTransformModeDefinition(
    mode: _TextTransformMode.rc4Decode,
    category: _TextTransformCategory.encode,
    labelKey: 'inline.plan295.life.rc4_legacy_decode.8b0070d3ba3b',
    summaryKey:
        'inline.plan295.life.decode_base64_rc4_text_with_the_same.cb8eb2db19f2',
  ),
  _TextTransformModeDefinition(
    mode: _TextTransformMode.marsEncode,
    category: _TextTransformCategory.style,
    labelKey: 'inline.plan295.life.mars_text_encode.0392a3230bd5',
    summaryKey:
        'inline.plan295.life.convert_common_chinese_text_into_lig.eb4344d74a32',
  ),
  _TextTransformModeDefinition(
    mode: _TextTransformMode.marsDecode,
    category: _TextTransformCategory.style,
    labelKey: 'inline.plan295.life.mars_text_decode.a98f07ab1872',
    summaryKey:
        'inline.plan295.life.normalize_common_mars_text_glyphs_ba.7e2f37454041',
  ),
  _TextTransformModeDefinition(
    mode: _TextTransformMode.fullwidth,
    category: _TextTransformCategory.style,
    labelKey: 'inline.plan295.life.halfwidth_to_fullwidth.f7e184336496',
    summaryKey:
        'inline.plan295.life.convert_ascii_letters_digits_and_sym.510c9b203e26',
  ),
  _TextTransformModeDefinition(
    mode: _TextTransformMode.halfwidth,
    category: _TextTransformCategory.style,
    labelKey: 'inline.plan295.life.fullwidth_to_halfwidth.65e130a9970b',
    summaryKey:
        'inline.plan295.life.normalize_fullwidth_text_back_into_h.b53401f99bd5',
  ),
  _TextTransformModeDefinition(
    mode: _TextTransformMode.verticalLayout,
    category: _TextTransformCategory.style,
    labelKey: 'inline.plan295.life.vertical_layout.2251a31a1583',
    summaryKey:
        'inline.plan295.life.generate_a_copyable_vertical_text_la.5dd4b9b6e3d1',
  ),
  _TextTransformModeDefinition(
    mode: _TextTransformMode.hiddenEmbed,
    category: _TextTransformCategory.hidden,
    labelKey: 'inline.plan295.life.hide_text.a55b7e65bef2',
    summaryKey:
        'inline.plan295.life.embed_hidden_content_into_visible_co.033f8dbb01c1',
  ),
  _TextTransformModeDefinition(
    mode: _TextTransformMode.hiddenReveal,
    category: _TextTransformCategory.hidden,
    labelKey: 'inline.plan295.life.reveal_hidden_text.3fa853b6dd4f',
    summaryKey:
        'inline.plan295.life.extract_hidden_content_from_zero_wid.42950201e4d6',
  ),
  _TextTransformModeDefinition(
    mode: _TextTransformMode.mojibakeCandidates,
    category: _TextTransformCategory.mojibake,
    labelKey: 'inline.plan295.life.mojibake_candidates.f627a946b616',
    summaryKey:
        'inline.plan295.life.show_common_mojibake_reinterpretatio.98dc83c8524f',
  ),
  _TextTransformModeDefinition(
    mode: _TextTransformMode.codePointTable,
    category: _TextTransformCategory.codeTable,
    labelKey: 'inline.plan295.life.code_point_table.9637ce86691f',
    summaryKey:
        'inline.plan295.life.inspect_unicode_decimal_and_binary_v.ae86f90ae53e',
  ),
  _TextTransformModeDefinition(
    mode: _TextTransformMode.asciiTable,
    category: _TextTransformCategory.codeTable,
    labelKey: 'inline.plan295.life.ascii_table.3a35ec7b3c0c',
    summaryKey:
        'inline.plan295.life.view_the_ascii_0_127_reference_table.29af0052f732',
  ),
  _TextTransformModeDefinition(
    mode: _TextTransformMode.commonMapTable,
    category: _TextTransformCategory.codeTable,
    labelKey: 'inline.plan295.life.common_map_snapshot.8ccc408fdde8',
    summaryKey:
        'inline.plan295.life.view_utf_8_base64_url_unicode_and_si.61684d52a744',
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
      title: _lifeI18nText(
        context,
        'inline.plan295.life.text_transform.9571d3b531bd',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.pinyin_script_conversion_numerals_ca.5df8d40c966a',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _LifeSettingsPanel(
            title: _lifeI18nText(
              context,
              'inline.plan295.life.current_tool.f97ecb5a047b',
            ),
            subtitle: _lifeI18nText(
              context,
              'inline.plan295.life.choose_a_group_then_the_specific_tra.748cf79c874c',
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
                      _lifeI18nText(
                        context,
                        'inline.plan295.life.manual_search.dff1d0a48724',
                      ),
                      icon: Icons.hourglass_top_rounded,
                    ),
                ],
              ),
              const SizedBox(height: 14),
              _LifeSegmentedField<_TextTransformCategory>(
                label: _lifeI18nText(
                  context,
                  'inline.plan295.life.category.81d75b9e39e2',
                ),
                value: _category,
                options: const <_LifeOption<_TextTransformCategory>>[
                  _LifeOption(
                    value: _TextTransformCategory.phonetic,
                    labelKey: 'inline.plan295.life.phonetic.e7161053d1cc',
                  ),
                  _LifeOption(
                    value: _TextTransformCategory.number,
                    labelKey: 'inline.plan295.life.number.3d22ab57560e',
                  ),
                  _LifeOption(
                    value: _TextTransformCategory.calendar,
                    labelKey: 'inline.plan295.life.calendar.5a5bd958f4bd',
                  ),
                  _LifeOption(
                    value: _TextTransformCategory.ganzhi,
                    labelKey: 'inline.plan295.life.ganzhi.0799141a38b3',
                  ),
                  _LifeOption(
                    value: _TextTransformCategory.language,
                    labelKey: 'inline.plan295.life.language.44f257751ce8',
                  ),
                  _LifeOption(
                    value: _TextTransformCategory.encode,
                    labelKey: 'inline.plan295.life.encoding.1ebce0020d08',
                  ),
                  _LifeOption(
                    value: _TextTransformCategory.style,
                    labelKey: 'ref.toolbox.sound.piano.style',
                  ),
                  _LifeOption(
                    value: _TextTransformCategory.hidden,
                    labelKey:
                        'inline.ui.pages.toolbox_daily_choice.daily_choice_manager_sheet.hidden_00098e',
                  ),
                  _LifeOption(
                    value: _TextTransformCategory.mojibake,
                    labelKey: 'inline.plan295.life.mojibake.02c7cab07424',
                  ),
                  _LifeOption(
                    value: _TextTransformCategory.codeTable,
                    labelKey: 'inline.plan295.life.code_table.f23056665b43',
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
                label: _lifeI18nText(
                  context,
                  'inline.ui.pages.toolbox_human_tests_aim.mode_35c458',
                ),
                value: _mode,
                options: _categoryModes
                    .map(
                      (definition) => _LifeOption<_TextTransformMode>(
                        value: definition.mode,
                        labelKey: definition.labelKey,
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
                  _lifeI18nText(
                    context,
                    'inline.plan295.life.calendar_and_bazi_results_are_local.d6cfb5055e81',
                  ),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          _LifeSettingsPanel(
            title: _lifeI18nText(
              context,
              'inline.plan295.life.input_area.e860077e9f2c',
            ),
            subtitle: _lifeI18nText(
              context,
              'inline.plan295.life.only_the_fields_truly_needed_by_the.16c3b5753a08',
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
                    labelText: _lifeI18nText(
                      context,
                      'inline.plan295.life.hidden_content.9db5f0835845',
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
                    labelText: _lifeI18nText(
                      context,
                      'inline.plan295.life.key.ed8c29bbe3cd',
                    ),
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
                    labelText: _lifeI18nText(
                      context,
                      'inline.plan295.life.lunar_year.9cc1bac91e7d',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedLunarMonth,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: _lifeI18nText(
                      context,
                      'inline.plan295.life.lunar_month.62a3978ba718',
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
                    labelText: _lifeI18nText(
                      context,
                      'inline.plan295.life.lunar_day.cc02f4f8939f',
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    _lifeI18nText(
                      context,
                      'inline.plan295.life.leap_month.34b88bb7c62e',
                    ),
                  ),
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
                          labelText: _lifeI18nText(
                            context,
                            'inline.plan295.life.columns.2248b862a9a7',
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
                          labelText: _lifeI18nText(
                            context,
                            'inline.plan295.life.rows.344a069abe45',
                          ),
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
                    labelText: _lifeI18nText(
                      context,
                      'inline.plan295.life.border.8cf87cd26895',
                    ),
                  ),
                  items: List<DropdownMenuItem<int>>.generate(
                    _verticalBorderStyles.length,
                    (index) => DropdownMenuItem<int>(
                      value: index,
                      child: Text(
                        _lifeI18nText(
                          context,
                          'inline.plan296.ui.pages.toolbox.life.tools.toolbox.life.tools.text.transform.style.76d78f39ab',
                          params: <String, Object?>{'p0': index + 1},
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
                    _lifeI18nText(
                      context,
                      'inline.plan295.life.use_traditional_first.0ac9f530e589',
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
                          labelText: _lifeI18nText(
                            context,
                            'inline.plan295.life.start_year.15eb75b645aa',
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
                          labelText: _lifeI18nText(
                            context,
                            'inline.plan295.life.end_year.437ff22c3343',
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
                        _isHeavyMode
                            ? _lifeI18nText(
                                context,
                                'inline.plan295.life.search.bf8945a2bda5',
                              )
                            : _lifeI18nText(
                                context,
                                'inline.plan295.life.run.5ebec292bc10',
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: _fillExample,
                      child: Text(
                        _lifeI18nText(
                          context,
                          'inline.plan295.life.example.848c52eede84',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          _LifeSettingsPanel(
            title: _lifeI18nText(
              context,
              'inline.plan295.life.results.d270a6b4ac1d',
            ),
            subtitle: _lifeI18nText(
              context,
              'inline.plan295.life.results_are_layered_into_primary_out.1db88e879148',
            ),
            children: _results.isEmpty
                ? <Widget>[
                    Text(
                      _lifeI18nText(
                        context,
                        'inline.plan295.life.no_result_yet.9be0775ffd8d',
                      ),
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
            _lifeI18nText(
              context,
              'inline.plan296.ui.pages.toolbox.life.tools.toolbox.life.tools.text.transform.date.d8491956c9',
              params: <String, Object?>{
                'p0': _formatDate(_selectedSolarDateTime),
              },
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
              _lifeI18nText(
                context,
                'inline.plan296.ui.pages.toolbox.life.tools.toolbox.life.tools.text.transform.time.6d0c32848b',
                params: <String, Object?>{
                  'p0': _formatTime(_selectedSolarDateTime),
                },
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
        ? _lifeI18nText(context, 'inline.plan295.life.no_result.6bf6a428f240')
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
                tooltip: _lifeI18nText(
                  context,
                  'inline.plan295.life.copy_result.d4f7944c520b',
                ),
                onPressed: copyContent.isEmpty
                    ? null
                    : () {
                        Clipboard.setData(ClipboardData(text: copyContent));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              _lifeI18nText(
                                context,
                                'inline.plan295.life.result_copied.52ccf550adbc',
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
      _TextTransformMode.phoneticBundle => _lifeI18nText(
        context,
        'inline.plan295.life.chinese_text.fb55cc7d4b83',
      ),
      _TextTransformMode.scriptConvert => _lifeI18nText(
        context,
        'inline.plan295.life.simplified_or_traditional_text.944151f09a5a',
      ),
      _TextTransformMode.numberBundle => _lifeI18nText(
        context,
        'inline.plan295.life.number_input.19a80183aebd',
      ),
      _TextTransformMode.languageLookup => _lifeI18nText(
        context,
        'inline.plan295.life.language_code_or_locale_tag.529ba964ff1f',
      ),
      _TextTransformMode.baziSearch => _lifeI18nText(
        context,
        'inline.plan295.life.four_pillars_for_example_jiazi_yicho.d34d2a1be11c',
      ),
      _TextTransformMode.sixtyJiaZi => _lifeI18nText(
        context,
        'inline.plan295.life.index_or_jiazi_name.88fe728b3276',
      ),
      _TextTransformMode.hiddenReveal => _lifeI18nText(
        context,
        'inline.plan295.life.encoded_text.d275427febcf',
      ),
      _TextTransformMode.mojibakeCandidates => _lifeI18nText(
        context,
        'inline.plan295.life.possibly_garbled_text.ba7c6958b89e',
      ),
      _TextTransformMode.verticalLayout => _lifeI18nText(
        context,
        'inline.plan295.life.text_for_vertical_layout.7dee39fd73d7',
      ),
      _TextTransformMode.marsDecode => _lifeI18nText(
        context,
        'inline.plan295.life.mars_text.b71e84478da7',
      ),
      _TextTransformMode.marsEncode => _lifeI18nText(
        context,
        'inline.plan295.life.plain_text.8bf20e93b416',
      ),
      _TextTransformMode.base64Decode => _lifeI18nText(
        context,
        'inline.plan295.life.base64_input.1eab8c5306aa',
      ),
      _TextTransformMode.urlDecode => _lifeI18nText(
        context,
        'inline.plan295.life.url_encoded_input.60a4d59a4518',
      ),
      _TextTransformMode.unicodeUnescape => _lifeI18nText(
        context,
        'inline.plan295.life.uxxxx_input.6981190a6b44',
      ),
      _TextTransformMode.jsonUnescape => _lifeI18nText(
        context,
        'inline.plan295.life.json_string_content.0e4aa6f24816',
      ),
      _TextTransformMode.morseDecode => _lifeI18nText(
        context,
        'inline.plan295.life.morse_code.6179b9a35cf1',
      ),
      _TextTransformMode.rc4Decode => _lifeI18nText(
        context,
        'inline.plan295.life.base64_cipher_text.a25917e77390',
      ),
      _ => _lifeI18nText(
        context,
        'inline.plan295.life.input_text.7f94eb5eae24',
      ),
    };
  }

  String _categoryLabel(BuildContext context, _TextTransformCategory category) {
    return switch (category) {
      _TextTransformCategory.phonetic => _lifeI18nText(
        context,
        'inline.plan295.life.phonetic.e7161053d1cc',
      ),
      _TextTransformCategory.number => _lifeI18nText(
        context,
        'inline.plan295.life.number.3d22ab57560e',
      ),
      _TextTransformCategory.calendar => _lifeI18nText(
        context,
        'inline.plan295.life.calendar.5a5bd958f4bd',
      ),
      _TextTransformCategory.ganzhi => _lifeI18nText(
        context,
        'inline.plan295.life.ganzhi.0799141a38b3',
      ),
      _TextTransformCategory.language => _lifeI18nText(
        context,
        'inline.plan295.life.language.44f257751ce8',
      ),
      _TextTransformCategory.encode => _lifeI18nText(
        context,
        'inline.plan295.life.encoding.1ebce0020d08',
      ),
      _TextTransformCategory.style => _lifeI18nText(
        context,
        'ref.toolbox.sound.piano.style',
      ),
      _TextTransformCategory.hidden => _lifeI18nText(
        context,
        'inline.ui.pages.toolbox_daily_choice.daily_choice_manager_sheet.hidden_00098e',
      ),
      _TextTransformCategory.mojibake => _lifeI18nText(
        context,
        'inline.plan295.life.mojibake.02c7cab07424',
      ),
      _TextTransformCategory.codeTable => _lifeI18nText(
        context,
        'inline.plan295.life.code_table.f23056665b43',
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
              title: _lifeI18nText(
                context,
                'inline.plan295.life.decoded.1d572d3f8e8b',
              ),
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
              title: _lifeI18nText(
                context,
                'inline.plan295.life.decoded.1d572d3f8e8b',
              ),
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
              title: _lifeI18nText(
                context,
                'inline.plan295.life.restored.262bfef74568',
              ),
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
              title: _lifeI18nText(
                context,
                'inline.plan295.life.restored.262bfef74568',
              ),
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
              title: _lifeI18nText(
                context,
                'inline.plan295.life.restored.262bfef74568',
              ),
              content: _jsonUnescape(input),
              highlight: true,
            ),
          );
        case _TextTransformMode.morseEncode:
          blocks.add(
            _TextTransformResultBlock(
              title: _lifeI18nText(
                context,
                'inline.plan295.life.morse.95bd5c0297b1',
              ),
              content: _toMorse(input),
              highlight: true,
            ),
          );
        case _TextTransformMode.morseDecode:
          blocks.add(
            _TextTransformResultBlock(
              title: _lifeI18nText(
                context,
                'inline.plan295.life.decoded.1d572d3f8e8b',
              ),
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
              title: _lifeI18nText(
                context,
                'inline.plan295.life.decoded.1d572d3f8e8b',
              ),
              content: _rc4Base64Decode(input, _keyController.text),
              highlight: true,
            ),
          );
        case _TextTransformMode.marsEncode:
          blocks.add(
            _TextTransformResultBlock(
              title: _lifeI18nText(
                context,
                'inline.plan295.life.mars_text.685bbdd316d7',
              ),
              content: _toMars(input),
              highlight: true,
            ),
          );
        case _TextTransformMode.marsDecode:
          blocks.add(
            _TextTransformResultBlock(
              title: _lifeI18nText(
                context,
                'inline.plan295.life.normalized.5976ce0a3a23',
              ),
              content: _fromMars(input),
              highlight: true,
            ),
          );
        case _TextTransformMode.fullwidth:
          blocks.add(
            _TextTransformResultBlock(
              title: _lifeI18nText(
                context,
                'inline.plan295.life.fullwidth.c2d08c9da076',
              ),
              content: _toFullWidthString(input),
              highlight: true,
            ),
          );
        case _TextTransformMode.halfwidth:
          blocks.add(
            _TextTransformResultBlock(
              title: _lifeI18nText(
                context,
                'inline.plan295.life.halfwidth.12f64f2b644a',
              ),
              content: _toHalfWidthString(input),
              highlight: true,
            ),
          );
        case _TextTransformMode.verticalLayout:
          blocks.add(
            _TextTransformResultBlock(
              title: _lifeI18nText(
                context,
                'inline.plan295.life.vertical_preview.745b3387b42f',
              ),
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
              title: _lifeI18nText(
                context,
                'inline.plan295.life.embedded_result.18b6a4893118',
              ),
              content: _embedHiddenText(input, _secondaryController.text),
              highlight: true,
            ),
          );
        case _TextTransformMode.hiddenReveal:
          blocks.add(
            _TextTransformResultBlock(
              title: _lifeI18nText(
                context,
                'inline.plan295.life.revealed_result.c02aede48d70',
              ),
              content: _revealHiddenText(input),
              highlight: true,
            ),
          );
        case _TextTransformMode.mojibakeCandidates:
          blocks.addAll(_mojibakeCandidates(input));
        case _TextTransformMode.codePointTable:
          blocks.add(
            _TextTransformResultBlock(
              title: _lifeI18nText(
                context,
                'inline.plan295.life.code_points.6fcb0fabac0c',
              ),
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
            title: _lifeI18nText(
              context,
              'inline.plan295.life.transform_failed.b5c319282e30',
            ),
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
          title: _lifeI18nText(
            context,
            'inline.plan295.life.note.ecb81a92f39e',
          ),
          content: _lifeI18nText(
            context,
            'inline.plan295.life.enter_chinese_text_to_view_pinyin_zh.ce61b0fb5bba',
          ),
          highlight: true,
        ),
      ];
    }
    return <_TextTransformResultBlock>[
      _TextTransformResultBlock(
        title: _lifeI18nText(
          context,
          'inline.plan295.life.pinyin_without_tone.014847e9f7d6',
        ),
        content: PinyinHelper.getPinyin(
          text,
          format: PinyinFormat.WITHOUT_TONE,
        ),
        highlight: true,
      ),
      _TextTransformResultBlock(
        title: _lifeI18nText(
          context,
          'inline.plan295.life.pinyin_tone_marks.05779b6610aa',
        ),
        content: PinyinHelper.getPinyin(
          text,
          format: PinyinFormat.WITH_TONE_MARK,
        ),
      ),
      _TextTransformResultBlock(
        title: _lifeI18nText(
          context,
          'inline.plan295.life.pinyin_tone_numbers.554d9478baf3',
        ),
        content: PinyinHelper.getPinyin(
          text,
          format: PinyinFormat.WITH_TONE_NUMBER,
        ),
      ),
      _TextTransformResultBlock(
        title: _lifeI18nText(
          context,
          'inline.plan295.life.zhuyin.1a9abb770953',
        ),
        content: ZhuyinHelper.getZhuyin(
          text,
          format: PinyinFormat.WITH_TONE_MARK,
        ),
      ),
      _TextTransformResultBlock(
        title: _lifeI18nText(
          context,
          'inline.plan295.life.short_pinyin.f143847e5b0a',
        ),
        content: PinyinHelper.getShortPinyin(text),
      ),
      _TextTransformResultBlock(
        title: _lifeI18nText(
          context,
          'inline.plan295.life.first_letter_initials.8097b98322a6',
        ),
        content: PinyinHelper.getFirstWordPinyin(text),
      ),
    ];
  }

  List<_TextTransformResultBlock> _scriptBlocks(String text) {
    if (text.trim().isEmpty) {
      return <_TextTransformResultBlock>[
        _TextTransformResultBlock(
          title: _lifeI18nText(
            context,
            'inline.plan295.life.note.ecb81a92f39e',
          ),
          content: _lifeI18nText(
            context,
            'inline.plan295.life.enter_simplified_or_traditional_chin.feef558c0e6f',
          ),
          highlight: true,
        ),
      ];
    }
    return <_TextTransformResultBlock>[
      _TextTransformResultBlock(
        title: _lifeI18nText(
          context,
          'inline.plan295.life.to_traditional.b626a58a6d40',
        ),
        content: ChineseHelper.convertToTraditionalChinese(text),
        highlight: true,
      ),
      _TextTransformResultBlock(
        title: _lifeI18nText(
          context,
          'inline.plan295.life.to_simplified.06bb18e7d821',
        ),
        content: ChineseHelper.convertToSimplifiedChinese(text),
      ),
    ];
  }

  List<_TextTransformResultBlock> _numberBlocks(String input) {
    final String source = input.trim();
    if (source.isEmpty) {
      return <_TextTransformResultBlock>[
        _TextTransformResultBlock(
          title: _lifeI18nText(
            context,
            'inline.plan295.life.note.ecb81a92f39e',
          ),
          content: _lifeI18nText(
            context,
            'inline.plan295.life.enter_an_arabic_number_such_as_12345.73b43f82b153',
          ),
          highlight: true,
        ),
      ];
    }
    final num? parsed = num.tryParse(source.replaceAll(',', ''));
    if (parsed == null) {
      throw FormatException(
        _lifeI18nText(
          context,
          'inline.plan295.life.enter_a_parseable_number.3a24d1e0fcff',
        ),
      );
    }
    final int integer = parsed.truncate();
    return <_TextTransformResultBlock>[
      _TextTransformResultBlock(
        title: _lifeI18nText(
          context,
          'inline.plan295.life.chinese_numerals.c2f777fbad27',
        ),
        content: _numberToChineseLower(source),
        highlight: true,
      ),
      _TextTransformResultBlock(
        title: _lifeI18nText(
          context,
          'inline.plan295.life.rmb_uppercase.fa1ce2f20210',
        ),
        content: _numberToChineseFinancial(source),
      ),
      _TextTransformResultBlock(
        title: _lifeI18nText(
          context,
          'inline.plan295.life.english_words.808f35094eef',
        ),
        content: _numberToEnglishWords(source),
      ),
      _TextTransformResultBlock(
        title: _lifeI18nText(
          context,
          'inline.plan295.life.roman_numeral.4b66695af440',
        ),
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
        title: _lifeI18nText(
          context,
          'inline.plan295.life.lunar_date.a6aa38addd8f',
        ),
        content:
            '${lunar.historicalYear}年 ${lunar.monthNameStr}月${_lunarDayName(lunar.day)}\n${_lifeI18nText(context, 'inline.plan295.life.month_size.b5eb24fbbf35')}: ${lunar.monthSize == 30 ? _lifeI18nText(context, 'inline.plan295.life.30_day_month.7c803bda3b40') : _lifeI18nText(context, 'inline.plan295.life.29_day_month.0f945854d22b')}',
        highlight: true,
      ),
      _TextTransformResultBlock(
        title: _lifeI18nText(
          context,
          'inline.plan295.life.ganzhi_and_weekday.edbc217c6c60',
        ),
        content:
            '${info.ganZhi}  ·  ${info.weekdayName}  ·  ${info.constellation}',
      ),
      _TextTransformResultBlock(
        title: _lifeI18nText(
          context,
          'inline.plan295.life.solar_term_and_moon_phase.b738aa4781a8',
        ),
        content: [
          if (info.solarTerm != null)
            '${_lifeI18nText(context, 'inline.plan295.life.current_solar_term.5f7bf56e215e')}: ${info.solarTerm}${info.solarTermTime != null ? ' ${info.solarTermTime!.toTimeString()}' : ''}',
          if (info.moonPhase != null)
            '${_lifeI18nText(context, 'inline.plan295.life.moon_phase.5448f0b8b11e')}: ${info.moonPhase}${info.moonPhaseTime != null ? ' ${info.moonPhaseTime!.toTimeString()}' : ''}',
          if (jieQiInfo != null)
            '${_lifeI18nText(context, 'inline.plan295.life.solar_term_window.4ca4581e567b')}: ${jieQiInfo.prevJieQi.name} → ${jieQiInfo.nextJieQi.name} (${jieQiInfo.daysUntilNextJieQi.toStringAsFixed(1)}d)',
        ].join('\n').trim(),
      ),
      _TextTransformResultBlock(
        title: _lifeI18nText(
          context,
          'inline.plan295.life.festivals_and_customs.eacc3c512ab5',
        ),
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
        title: _lifeI18nText(
          context,
          'inline.plan295.life.solar_date.eff9166e5fd5',
        ),
        content:
            '${solar.year}-${solar.month.toString().padLeft(2, '0')}-${solar.day.toString().padLeft(2, '0')}',
        highlight: true,
      ),
      _TextTransformResultBlock(
        title: _lifeI18nText(
          context,
          'inline.plan295.life.lunar_input.79e6f760c684',
        ),
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
        title: _lifeI18nText(
          context,
          'inline.plan295.life.day_snapshot.4ecac7eaf399',
        ),
        content:
            '${_formatDate(dateTime)} ${_formatTime(dateTime)}\n${info.ganZhi} · ${info.weekdayName} · ${info.constellation}\n农历 ${info.lunarDate.monthNameStr}月${_lunarDayName(info.lunarDate.day)} (${info.lunarMonthSize == 30 ? _lifeI18nText(context, 'inline.plan295.life.30_day_month.7c803bda3b40') : _lifeI18nText(context, 'inline.plan295.life.29_day_month.0f945854d22b')})',
        highlight: true,
      ),
      _TextTransformResultBlock(
        title: _lifeI18nText(
          context,
          'inline.plan295.life.solar_term_and_moon_phase.b738aa4781a8',
        ),
        content: [
          '${_lifeI18nText(context, 'inline.plan295.life.solar_term.87f5921058ae')}: ${info.solarTerm ?? _lifeI18nText(context, 'ref.wordTransitionStyleNone')}${info.solarTermTime != null ? ' ${info.solarTermTime!.toTimeString()}' : ''}',
          '${_lifeI18nText(context, 'inline.plan295.life.moon_phase.5448f0b8b11e')}: ${info.moonPhase ?? _lifeI18nText(context, 'ref.wordTransitionStyleNone')}${info.moonPhaseTime != null ? ' ${info.moonPhaseTime!.toTimeString()}' : ''}',
          if (jieQiInfo != null)
            '${_lifeI18nText(context, 'inline.plan295.life.solar_term_window.4ca4581e567b')}: ${jieQiInfo.prevJieQi.name} → ${jieQiInfo.nextJieQi.name}',
        ].join('\n'),
      ),
      _TextTransformResultBlock(
        title: _lifeI18nText(
          context,
          'inline.plan295.life.sunrise_and_sunset_beijing.1d6f50e669d0',
        ),
        content: [
          '${_lifeI18nText(context, 'inline.plan295.life.sunrise.f210fad15103')}: ${info.sunrise?.toTimeString() ?? '--'}',
          '${_lifeI18nText(context, 'ref.themeSunset')}: ${info.sunset?.toTimeString() ?? '--'}',
        ].join('\n'),
      ),
      _TextTransformResultBlock(
        title: _lifeI18nText(
          context,
          'inline.plan295.life.festivals_and_yearly_solar_terms.209cb73461fd',
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
        title: _lifeI18nText(
          context,
          'inline.plan295.life.four_pillars.428414d86c32',
        ),
        content: bazi.bazi.toString(),
        highlight: true,
      ),
      _TextTransformResultBlock(
        title: _lifeI18nText(
          context,
          'inline.plan295.life.pillars.3b2ecc564b1f',
        ),
        content:
            '${ganzhi.yearGanZhi} / ${ganzhi.monthGanZhi} / ${ganzhi.dayGanZhi} / ${ganzhi.timeGanZhi}',
      ),
      _TextTransformResultBlock(
        title: _lifeI18nText(
          context,
          'inline.plan295.life.true_solar_time_beijing.014fc0fc6f13',
        ),
        content:
            '${solar.trueSolarTime.year}-${solar.trueSolarTime.month.toString().padLeft(2, '0')}-${solar.trueSolarTime.day.toString().padLeft(2, '0')} ${solar.trueSolarTime.toTimeString()}\n${_lifeI18nText(context, 'inline.plan295.life.current_time_branch.97f760aad051')}: ${_timeBranchLabel(dateTime.hour)}',
      ),
      _TextTransformResultBlock(
        title: _lifeI18nText(
          context,
          'inline.plan295.life.nayin_and_five_elements.fa9f33bd7533',
        ),
        content: [
          '${_lifeI18nText(context, 'inline.plan295.life.year.a9ca9a0e2481')}: ${bazi.bazi.year.naYin} / ${bazi.bazi.year.naYinWuXing}',
          '${_lifeI18nText(context, 'inline.plan295.life.month.eab5cd6329de')}: ${bazi.bazi.month.naYin} / ${bazi.bazi.month.naYinWuXing}',
          '${_lifeI18nText(context, 'inline.plan295.life.day.55b88c52240f')}: ${bazi.bazi.day.naYin} / ${bazi.bazi.day.naYinWuXing}',
          '${_lifeI18nText(context, 'inline.plan295.life.hour.73db88e1fba5')}: ${bazi.bazi.time.naYin} / ${bazi.bazi.time.naYinWuXing}',
        ].join('\n'),
      ),
      _TextTransformResultBlock(
        title: _lifeI18nText(
          context,
          'inline.plan295.life.sixty_jiazi_reference.33f4dd744ca0',
        ),
        content:
            '${_lifeI18nText(context, 'inline.plan295.life.day_pillar_index.8e52371808c4')}: $dayIndex\n${_lifeI18nText(context, 'inline.plan295.life.year_pillar_index.2f3459df31de')}: ${_sixtyJiaZi.indexWhere((item) => item == ganzhi.yearGanZhi) + 1}',
      ),
    ];
  }

  List<_TextTransformResultBlock> _baziSearchBlocks(String input) {
    final List<String> pillars = _parseBaziInput(input);
    if (pillars.length != 4) {
      return <_TextTransformResultBlock>[
        _TextTransformResultBlock(
          title: _lifeI18nText(
            context,
            'inline.plan295.life.note.ecb81a92f39e',
          ),
          content: _lifeI18nText(
            context,
            'inline.plan295.life.enter_four_pillars_such_as_jiazi_yic.ab25661c886d',
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
        _lifeI18nText(
          context,
          'inline.plan295.life.to_keep_this_mobile_friendly_bazi_ca.e5ee52767bc8',
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
        title: _lifeI18nText(
          context,
          'inline.plan295.life.search_query.c7ff2920ef96',
        ),
        content: '${pillars.join(' / ')}\n$startYear - $endYear',
        highlight: true,
      ),
      _TextTransformResultBlock(
        title: _lifeI18nText(
          context,
          'inline.plan295.life.candidate_dates.eca0bfbc56dc',
        ),
        content: matches.isEmpty
            ? _lifeI18nText(
                context,
                'inline.plan295.life.no_candidate_was_found_in_the_select.e8028c5032b8',
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
        title: _lifeI18nText(
          context,
          'inline.plan295.life.sixty_jiazi_table.0ca612afad15',
        ),
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
          title: _lifeI18nText(
            context,
            'inline.plan295.life.parsed_locale.e41bd91e490d',
          ),
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
        title: _lifeI18nText(
          context,
          'inline.plan295.life.common_language_codes.789dd3d00fbb',
        ),
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
          title: _lifeI18nText(
            context,
            'inline.plan295.life.note.ecb81a92f39e',
          ),
          content: _lifeI18nText(
            context,
            'inline.plan295.life.enter_tags_such_as_en_zh_cn_zh_hant.7e89b6e21690',
          ),
          highlight: true,
        ),
      );
    }
    return blocks;
  }

  String _toRoman(int value) {
    if (value <= 0) {
      return _lifeI18nText(
        context,
        'inline.plan295.life.roman_numerals_do_not_support_zero_o.a10fff3429ec',
      );
    }
    if (value > 3999) {
      return _lifeI18nText(
        context,
        'inline.plan295.life.currently_supports_1_3999_only.d43aba4df656',
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
        title: _lifeI18nText(
          context,
          'inline.plan295.life.original.d4d312c37935',
        ),
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
          title: _lifeI18nText(
            context,
            'inline.plan295.life.note.ecb81a92f39e',
          ),
          content: _lifeI18nText(
            context,
            'inline.plan295.life.no_clearer_common_candidate_was_foun.cdadf175d570',
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
      return _lifeI18nText(
        context,
        'inline.plan295.life.enter_text_to_inspect_code_points.a3f32291ad2d',
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
      return _lifeI18nText(
        context,
        'inline.plan295.life.no_major_festivals_or_customs_were_r.a417a5f96174',
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
        '${_lifeI18nText(context, 'inline.plan295.life.primary_festivals.e715a97e267e')}: ${primary.join(' / ')}',
      if (commemorative.isNotEmpty)
        '${_lifeI18nText(context, 'inline.plan295.life.commemorative.c073e6550204')}: ${commemorative.join(' / ')}',
      if (ethnic.isNotEmpty)
        '${_lifeI18nText(context, 'inline.plan295.life.ethnic_and_local.15328bea0947')}: ${ethnic.join(' / ')}',
      '${_lifeI18nText(context, 'inline.plan295.life.all_entries.d2b653435017')}: ${info.festivals.join(' / ')}',
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
        title: _lifeI18nText(
          context,
          'inline.plan295.life.code_points.6fcb0fabac0c',
        ),
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
    return _lifeI18nText(
      context,
      'inline.plan296.ui.pages.toolbox.life.tools.toolbox.life.tools.text.transform.text.9144a09d99',
      params: <String, Object?>{
        'fromZh': fromZh,
        'toZh': toZh,
        'fromEn': fromEn,
        'toEn': toEn,
      },
    );
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
