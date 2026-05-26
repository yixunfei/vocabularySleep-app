part of '../toolbox_life_tools.dart';

enum _LifeColorExperience { chinese, nippon }

class _LifePaletteBundle {
  const _LifePaletteBundle({
    required this.chineseColors,
    required this.nipponColors,
  });

  final List<_LifePaletteColor> chineseColors;
  final List<_LifePaletteColor> nipponColors;

  List<_LifePaletteColor> get allColors => <_LifePaletteColor>[
    ...chineseColors,
    ...nipponColors,
  ];
}

class _LifePaletteColor {
  _LifePaletteColor({
    required this.experience,
    required this.id,
    required this.name,
    required this.phonetic,
    required this.hex,
    required this.rgb,
    required this.cmyk,
    this.index,
  }) : color = Color(
         int.parse('FF${hex.replaceFirst('#', '').toUpperCase()}', radix: 16),
       );

  factory _LifePaletteColor.fromChineseJson(Map<String, dynamic> json) {
    final pinyin = json['pinyin'] as String? ?? '';
    return _LifePaletteColor(
      experience: _LifeColorExperience.chinese,
      id: pinyin,
      name: json['name'] as String? ?? '',
      phonetic: pinyin,
      hex: (json['hex'] as String? ?? '').toUpperCase(),
      rgb: _readIntList(json['RGB']),
      cmyk: _readIntList(json['CMYK']),
    );
  }

  factory _LifePaletteColor.fromNipponJson(Map<String, dynamic> json) {
    final romanized = json['romanized'] as String? ?? '';
    return _LifePaletteColor(
      experience: _LifeColorExperience.nippon,
      id: romanized,
      index: (json['index'] as num?)?.toInt(),
      name: json['name'] as String? ?? '',
      phonetic: romanized,
      hex: (json['hex'] as String? ?? '').toUpperCase(),
      rgb: _readIntList(json['RGB']),
      cmyk: _readIntList(json['CMYK']),
    );
  }

  final _LifeColorExperience experience;
  final String id;
  final int? index;
  final String name;
  final String phonetic;
  final String hex;
  final List<int> rgb;
  final List<int> cmyk;
  final Color color;

  String get stableKey => '${experience.name}:$id';

  String get upperPhonetic => phonetic.toUpperCase();

  bool get isLight => color.computeLuminance() > 0.55;

  static List<int> _readIntList(Object? raw) {
    return (raw as List<dynamic>? ?? const <dynamic>[])
        .map((value) => (value as num).round())
        .toList(growable: false);
  }
}

class _LifePaletteRepository {
  static Future<_LifePaletteBundle>? _cache;

  static Future<_LifePaletteBundle> load() {
    return _cache ??= _loadInternal();
  }

  static Future<_LifePaletteBundle> _loadInternal() async {
    final chineseRaw = await _loadJsonAsset(
      'assets/toolbox/colors/zhongguose_colors.json',
    );
    final nipponRaw = await _loadJsonAsset(
      'assets/toolbox/colors/nippon_colors.json',
    );

    final chineseJson = jsonDecode(chineseRaw) as List<dynamic>;
    final nipponJson = jsonDecode(nipponRaw) as List<dynamic>;

    final chineseColors =
        chineseJson
            .map(
              (item) => _LifePaletteColor.fromChineseJson(
                item as Map<String, dynamic>,
              ),
            )
            .toList(growable: false)
          ..sort(_compareChineseColorsLikeSite);

    final nipponColors =
        nipponJson
            .map(
              (item) => _LifePaletteColor.fromNipponJson(
                item as Map<String, dynamic>,
              ),
            )
            .toList(growable: false)
          ..sort((a, b) => (a.index ?? 0).compareTo(b.index ?? 0));

    return _LifePaletteBundle(
      chineseColors: chineseColors,
      nipponColors: nipponColors,
    );
  }

  static Future<String> _loadJsonAsset(String assetPath) async {
    final assetData = await rootBundle.load(assetPath);
    return utf8
        .decode(assetData.buffer.asUint8List())
        .replaceFirst('\uFEFF', '');
  }

  static int _compareChineseColorsLikeSite(
    _LifePaletteColor left,
    _LifePaletteColor right,
  ) {
    final leftHsv = _rgbToHsv(left.rgb);
    final rightHsv = _rgbToHsv(right.rgb);
    final leftGray = leftHsv.saturation < 0.15 || leftHsv.value < 0.25;
    final rightGray = rightHsv.saturation < 0.15 || rightHsv.value < 0.25;

    if (!leftGray && !rightGray) {
      final hueDelta = leftHsv.hue - rightHsv.hue;
      if (hueDelta.abs() > 0.01) {
        return hueDelta < 0 ? -1 : 1;
      }
      return _luminance(left.rgb).compareTo(_luminance(right.rgb));
    }

    if (leftGray && rightGray) {
      return _luminance(left.rgb).compareTo(_luminance(right.rgb));
    }

    return leftGray ? 1 : -1;
  }

  static _LifeHsvColor _rgbToHsv(List<int> rgb) {
    final red = rgb[0] / 255.0;
    final green = rgb[1] / 255.0;
    final blue = rgb[2] / 255.0;
    final maxValue = math.max(red, math.max(green, blue));
    final minValue = math.min(red, math.min(green, blue));
    final delta = maxValue - minValue;
    var hue = 0.0;
    final saturation = maxValue == 0 ? 0.0 : delta / maxValue;

    if (delta != 0) {
      if (maxValue == red) {
        hue = ((green - blue) / delta + (green < blue ? 6 : 0)) / 6;
      } else if (maxValue == green) {
        hue = ((blue - red) / delta + 2) / 6;
      } else {
        hue = ((red - green) / delta + 4) / 6;
      }
    }

    return _LifeHsvColor(hue: hue, saturation: saturation, value: maxValue);
  }

  static double _luminance(List<int> rgb) {
    return 0.299 * rgb[0] + 0.587 * rgb[1] + 0.114 * rgb[2];
  }
}

class _LifeHsvColor {
  const _LifeHsvColor({
    required this.hue,
    required this.saturation,
    required this.value,
  });

  final double hue;
  final double saturation;
  final double value;
}
