part of '../toolbox_life_tools.dart';

enum _UnitCategoryKind { scalar, photo }

class _UnitCategoryDefinition {
  const _UnitCategoryDefinition({
    required this.id,
    required this.labelZh,
    required this.labelEn,
    required this.units,
    this.kind = _UnitCategoryKind.scalar,
  });

  final String id;
  final String labelZh;
  final String labelEn;
  final List<_UnitDefinition> units;
  final _UnitCategoryKind kind;

  String label(BuildContext context) {
    return _lifeText(context, zh: labelZh, en: labelEn);
  }
}

class _UnitDefinition {
  const _UnitDefinition({
    required this.id,
    required this.labelZh,
    required this.labelEn,
    required this.symbol,
    required this.factorToAnchor,
    this.offsetToAnchor = 0,
  });

  final String id;
  final String labelZh;
  final String labelEn;
  final String symbol;
  final double factorToAnchor;
  final double offsetToAnchor;

  String label(BuildContext context) {
    return _lifeText(context, zh: labelZh, en: labelEn);
  }

  double toAnchor(double value) => value * factorToAnchor + offsetToAnchor;

  double fromAnchor(double value) => (value - offsetToAnchor) / factorToAnchor;
}

class _IdPhotoPreset {
  const _IdPhotoPreset({
    required this.id,
    required this.labelZh,
    required this.labelEn,
    required this.aliasInchWidth,
    required this.aliasInchHeight,
    required this.mmWidth,
    required this.mmHeight,
  });

  final String id;
  final String labelZh;
  final String labelEn;
  final double aliasInchWidth;
  final double aliasInchHeight;
  final double mmWidth;
  final double mmHeight;

  String label(BuildContext context) {
    return _lifeText(context, zh: labelZh, en: labelEn);
  }
}

const List<_UnitCategoryDefinition> _unitConverterCategories =
    <_UnitCategoryDefinition>[
      _UnitCategoryDefinition(
        id: 'length',
        labelZh: '长度',
        labelEn: 'Length',
        units: <_UnitDefinition>[
          _UnitDefinition(
            id: 'nm',
            labelZh: '纳米',
            labelEn: 'Nanometer',
            symbol: 'nm',
            factorToAnchor: 0.000000001,
          ),
          _UnitDefinition(
            id: 'um',
            labelZh: '微米',
            labelEn: 'Micrometer',
            symbol: 'um',
            factorToAnchor: 0.000001,
          ),
          _UnitDefinition(
            id: 'mm',
            labelZh: '毫米',
            labelEn: 'Millimeter',
            symbol: 'mm',
            factorToAnchor: 0.001,
          ),
          _UnitDefinition(
            id: 'cm',
            labelZh: '厘米',
            labelEn: 'Centimeter',
            symbol: 'cm',
            factorToAnchor: 0.01,
          ),
          _UnitDefinition(
            id: 'm',
            labelZh: '米',
            labelEn: 'Meter',
            symbol: 'm',
            factorToAnchor: 1,
          ),
          _UnitDefinition(
            id: 'km',
            labelZh: '千米',
            labelEn: 'Kilometer',
            symbol: 'km',
            factorToAnchor: 1000,
          ),
          _UnitDefinition(
            id: 'li',
            labelZh: '里',
            labelEn: 'Li',
            symbol: '里',
            factorToAnchor: 500,
          ),
          _UnitDefinition(
            id: 'inch',
            labelZh: '英寸',
            labelEn: 'Inch',
            symbol: 'in',
            factorToAnchor: 0.0254,
          ),
          _UnitDefinition(
            id: 'ft',
            labelZh: '英尺',
            labelEn: 'Foot',
            symbol: 'ft',
            factorToAnchor: 0.3048,
          ),
          _UnitDefinition(
            id: 'yd',
            labelZh: '码',
            labelEn: 'Yard',
            symbol: 'yd',
            factorToAnchor: 0.9144,
          ),
          _UnitDefinition(
            id: 'mile',
            labelZh: '英里',
            labelEn: 'Mile',
            symbol: 'mi',
            factorToAnchor: 1609.344,
          ),
          _UnitDefinition(
            id: 'nmi',
            labelZh: '海里',
            labelEn: 'Nautical mile',
            symbol: 'nmi',
            factorToAnchor: 1852,
          ),
          _UnitDefinition(
            id: 'au',
            labelZh: '天文单位',
            labelEn: 'Astronomical unit',
            symbol: 'AU',
            factorToAnchor: 149597870700,
          ),
          _UnitDefinition(
            id: 'ly',
            labelZh: '光年',
            labelEn: 'Light-year',
            symbol: 'ly',
            factorToAnchor: 9460730472580800,
          ),
        ],
      ),
      _UnitCategoryDefinition(
        id: 'weight',
        labelZh: '重量',
        labelEn: 'Weight',
        units: <_UnitDefinition>[
          _UnitDefinition(
            id: 'ug',
            labelZh: '微克',
            labelEn: 'Microgram',
            symbol: 'ug',
            factorToAnchor: 0.000000001,
          ),
          _UnitDefinition(
            id: 'mg',
            labelZh: '毫克',
            labelEn: 'Milligram',
            symbol: 'mg',
            factorToAnchor: 0.000001,
          ),
          _UnitDefinition(
            id: 'g',
            labelZh: '克',
            labelEn: 'Gram',
            symbol: 'g',
            factorToAnchor: 0.001,
          ),
          _UnitDefinition(
            id: 'jin',
            labelZh: '市斤',
            labelEn: 'Jin',
            symbol: '斤',
            factorToAnchor: 0.5,
          ),
          _UnitDefinition(
            id: 'kg',
            labelZh: '千克',
            labelEn: 'Kilogram',
            symbol: 'kg',
            factorToAnchor: 1,
          ),
          _UnitDefinition(
            id: 'ton',
            labelZh: '吨',
            labelEn: 'Metric ton',
            symbol: 't',
            factorToAnchor: 1000,
          ),
          _UnitDefinition(
            id: 'lb',
            labelZh: '磅',
            labelEn: 'Pound',
            symbol: 'lb',
            factorToAnchor: 0.45359237,
          ),
          _UnitDefinition(
            id: 'oz',
            labelZh: '盎司',
            labelEn: 'Ounce',
            symbol: 'oz',
            factorToAnchor: 0.028349523125,
          ),
          _UnitDefinition(
            id: 'stone',
            labelZh: '英石',
            labelEn: 'Stone',
            symbol: 'st',
            factorToAnchor: 6.35029318,
          ),
        ],
      ),
      _UnitCategoryDefinition(
        id: 'temperature',
        labelZh: '温度',
        labelEn: 'Temperature',
        units: <_UnitDefinition>[
          _UnitDefinition(
            id: 'c',
            labelZh: '摄氏度',
            labelEn: 'Celsius',
            symbol: '°C',
            factorToAnchor: 1,
            offsetToAnchor: 273.15,
          ),
          _UnitDefinition(
            id: 'f',
            labelZh: '华氏度',
            labelEn: 'Fahrenheit',
            symbol: '°F',
            factorToAnchor: 5 / 9,
            offsetToAnchor: 255.3722222222,
          ),
          _UnitDefinition(
            id: 'k',
            labelZh: '开尔文',
            labelEn: 'Kelvin',
            symbol: 'K',
            factorToAnchor: 1,
          ),
        ],
      ),
      _UnitCategoryDefinition(
        id: 'area',
        labelZh: '面积',
        labelEn: 'Area',
        units: <_UnitDefinition>[
          _UnitDefinition(
            id: 'sqm',
            labelZh: '平方米',
            labelEn: 'Square meter',
            symbol: 'm²',
            factorToAnchor: 1,
          ),
          _UnitDefinition(
            id: 'sqcm',
            labelZh: '平方厘米',
            labelEn: 'Square centimeter',
            symbol: 'cm²',
            factorToAnchor: 0.0001,
          ),
          _UnitDefinition(
            id: 'sqmm',
            labelZh: '平方毫米',
            labelEn: 'Square millimeter',
            symbol: 'mm²',
            factorToAnchor: 0.000001,
          ),
          _UnitDefinition(
            id: 'mu',
            labelZh: '亩',
            labelEn: 'Mu',
            symbol: '亩',
            factorToAnchor: 666.6666667,
          ),
          _UnitDefinition(
            id: 'sqft',
            labelZh: '平方英尺',
            labelEn: 'Square foot',
            symbol: 'ft²',
            factorToAnchor: 0.09290304,
          ),
          _UnitDefinition(
            id: 'acre',
            labelZh: '英亩',
            labelEn: 'Acre',
            symbol: 'ac',
            factorToAnchor: 4046.8564224,
          ),
          _UnitDefinition(
            id: 'hectare',
            labelZh: '公顷',
            labelEn: 'Hectare',
            symbol: 'ha',
            factorToAnchor: 10000,
          ),
        ],
      ),
      _UnitCategoryDefinition(
        id: 'volume',
        labelZh: '体积',
        labelEn: 'Volume',
        units: <_UnitDefinition>[
          _UnitDefinition(
            id: 'ml',
            labelZh: '毫升',
            labelEn: 'Milliliter',
            symbol: 'mL',
            factorToAnchor: 0.001,
          ),
          _UnitDefinition(
            id: 'l',
            labelZh: '升',
            labelEn: 'Liter',
            symbol: 'L',
            factorToAnchor: 1,
          ),
          _UnitDefinition(
            id: 'm3',
            labelZh: '立方米',
            labelEn: 'Cubic meter',
            symbol: 'm³',
            factorToAnchor: 1000,
          ),
          _UnitDefinition(
            id: 'cc',
            labelZh: '立方厘米',
            labelEn: 'Cubic centimeter',
            symbol: 'cm³',
            factorToAnchor: 0.001,
          ),
          _UnitDefinition(
            id: 'cup',
            labelZh: '杯',
            labelEn: 'Cup',
            symbol: 'cup',
            factorToAnchor: 0.2365882365,
          ),
          _UnitDefinition(
            id: 'pt',
            labelZh: '品脱',
            labelEn: 'Pint',
            symbol: 'pt',
            factorToAnchor: 0.473176473,
          ),
          _UnitDefinition(
            id: 'gal',
            labelZh: '加仑',
            labelEn: 'Gallon',
            symbol: 'gal',
            factorToAnchor: 3.785411784,
          ),
        ],
      ),
      _UnitCategoryDefinition(
        id: 'speed',
        labelZh: '速度',
        labelEn: 'Speed',
        units: <_UnitDefinition>[
          _UnitDefinition(
            id: 'mps',
            labelZh: '米/秒',
            labelEn: 'Meter per second',
            symbol: 'm/s',
            factorToAnchor: 1,
          ),
          _UnitDefinition(
            id: 'kph',
            labelZh: '千米/小时',
            labelEn: 'Kilometer per hour',
            symbol: 'km/h',
            factorToAnchor: 0.2777777778,
          ),
          _UnitDefinition(
            id: 'mph',
            labelZh: '英里/小时',
            labelEn: 'Mile per hour',
            symbol: 'mph',
            factorToAnchor: 0.44704,
          ),
          _UnitDefinition(
            id: 'knot',
            labelZh: '海里/小时（节）',
            labelEn: 'Nautical mile per hour',
            symbol: 'kn',
            factorToAnchor: 0.5144444444,
          ),
        ],
      ),
      _UnitCategoryDefinition(
        id: 'force',
        labelZh: '力',
        labelEn: 'Force',
        units: <_UnitDefinition>[
          _UnitDefinition(
            id: 'n',
            labelZh: '牛顿',
            labelEn: 'Newton',
            symbol: 'N',
            factorToAnchor: 1,
          ),
          _UnitDefinition(
            id: 'kn',
            labelZh: '千牛',
            labelEn: 'Kilonewton',
            symbol: 'kN',
            factorToAnchor: 1000,
          ),
          _UnitDefinition(
            id: 'gf',
            labelZh: '克力',
            labelEn: 'Gram-force',
            symbol: 'gf',
            factorToAnchor: 0.00980665,
          ),
          _UnitDefinition(
            id: 'kgf',
            labelZh: '公斤力',
            labelEn: 'Kilogram-force',
            symbol: 'kgf',
            factorToAnchor: 9.80665,
          ),
          _UnitDefinition(
            id: 'lbf',
            labelZh: '磅力',
            labelEn: 'Pound-force',
            symbol: 'lbf',
            factorToAnchor: 4.4482216153,
          ),
          _UnitDefinition(
            id: 'dyn',
            labelZh: '达因',
            labelEn: 'Dyne',
            symbol: 'dyn',
            factorToAnchor: 0.00001,
          ),
        ],
      ),
      _UnitCategoryDefinition(
        id: 'density',
        labelZh: '密度',
        labelEn: 'Density',
        units: <_UnitDefinition>[
          _UnitDefinition(
            id: 'kgm3',
            labelZh: '千克/立方米',
            labelEn: 'Kilogram per cubic meter',
            symbol: 'kg/m³',
            factorToAnchor: 1,
          ),
          _UnitDefinition(
            id: 'gl',
            labelZh: '克/升',
            labelEn: 'Gram per liter',
            symbol: 'g/L',
            factorToAnchor: 1,
          ),
          _UnitDefinition(
            id: 'gml',
            labelZh: '克/毫升',
            labelEn: 'Gram per milliliter',
            symbol: 'g/mL',
            factorToAnchor: 1000,
          ),
          _UnitDefinition(
            id: 'gcc',
            labelZh: '克/立方厘米',
            labelEn: 'Gram per cubic centimeter',
            symbol: 'g/cm³',
            factorToAnchor: 1000,
          ),
          _UnitDefinition(
            id: 'lbft3',
            labelZh: '磅/立方英尺',
            labelEn: 'Pound per cubic foot',
            symbol: 'lb/ft³',
            factorToAnchor: 16.01846337396,
          ),
          _UnitDefinition(
            id: 'lbin3',
            labelZh: '磅/立方英寸',
            labelEn: 'Pound per cubic inch',
            symbol: 'lb/in³',
            factorToAnchor: 27679.9047102,
          ),
        ],
      ),
      _UnitCategoryDefinition(
        id: 'power',
        labelZh: '功率',
        labelEn: 'Power',
        units: <_UnitDefinition>[
          _UnitDefinition(
            id: 'w',
            labelZh: '瓦',
            labelEn: 'Watt',
            symbol: 'W',
            factorToAnchor: 1,
          ),
          _UnitDefinition(
            id: 'kw',
            labelZh: '千瓦',
            labelEn: 'Kilowatt',
            symbol: 'kW',
            factorToAnchor: 1000,
          ),
          _UnitDefinition(
            id: 'mw',
            labelZh: '兆瓦',
            labelEn: 'Megawatt',
            symbol: 'MW',
            factorToAnchor: 1000000,
          ),
          _UnitDefinition(
            id: 'hp',
            labelZh: '英制马力',
            labelEn: 'Horsepower',
            symbol: 'hp',
            factorToAnchor: 745.699871582,
          ),
          _UnitDefinition(
            id: 'ps',
            labelZh: '公制马力',
            labelEn: 'Metric horsepower',
            symbol: 'PS',
            factorToAnchor: 735.49875,
          ),
          _UnitDefinition(
            id: 'cals',
            labelZh: '卡/秒',
            labelEn: 'Calorie per second',
            symbol: 'cal/s',
            factorToAnchor: 4.184,
          ),
        ],
      ),
      _UnitCategoryDefinition(
        id: 'energy',
        labelZh: '热量/能量',
        labelEn: 'Heat / energy',
        units: <_UnitDefinition>[
          _UnitDefinition(
            id: 'j',
            labelZh: '焦耳',
            labelEn: 'Joule',
            symbol: 'J',
            factorToAnchor: 1,
          ),
          _UnitDefinition(
            id: 'kj',
            labelZh: '千焦',
            labelEn: 'Kilojoule',
            symbol: 'kJ',
            factorToAnchor: 1000,
          ),
          _UnitDefinition(
            id: 'cal',
            labelZh: '卡',
            labelEn: 'Calorie',
            symbol: 'cal',
            factorToAnchor: 4.184,
          ),
          _UnitDefinition(
            id: 'kcal',
            labelZh: '千卡',
            labelEn: 'Kilocalorie',
            symbol: 'kcal',
            factorToAnchor: 4184,
          ),
          _UnitDefinition(
            id: 'wh',
            labelZh: '瓦时',
            labelEn: 'Watt-hour',
            symbol: 'Wh',
            factorToAnchor: 3600,
          ),
          _UnitDefinition(
            id: 'kwh',
            labelZh: '千瓦时',
            labelEn: 'Kilowatt-hour',
            symbol: 'kWh',
            factorToAnchor: 3600000,
          ),
          _UnitDefinition(
            id: 'btu',
            labelZh: '英热单位',
            labelEn: 'British thermal unit',
            symbol: 'BTU',
            factorToAnchor: 1055.05585262,
          ),
        ],
      ),
      _UnitCategoryDefinition(
        id: 'data',
        labelZh: '数据',
        labelEn: 'Data',
        units: <_UnitDefinition>[
          _UnitDefinition(
            id: 'byte',
            labelZh: '字节',
            labelEn: 'Byte',
            symbol: 'B',
            factorToAnchor: 1,
          ),
          _UnitDefinition(
            id: 'kb',
            labelZh: 'KB',
            labelEn: 'Kilobyte',
            symbol: 'KB',
            factorToAnchor: 1000,
          ),
          _UnitDefinition(
            id: 'mb',
            labelZh: 'MB',
            labelEn: 'Megabyte',
            symbol: 'MB',
            factorToAnchor: 1000000,
          ),
          _UnitDefinition(
            id: 'gb',
            labelZh: 'GB',
            labelEn: 'Gigabyte',
            symbol: 'GB',
            factorToAnchor: 1000000000,
          ),
          _UnitDefinition(
            id: 'tb',
            labelZh: 'TB',
            labelEn: 'Terabyte',
            symbol: 'TB',
            factorToAnchor: 1000000000000,
          ),
          _UnitDefinition(
            id: 'kib',
            labelZh: 'KiB',
            labelEn: 'Kibibyte',
            symbol: 'KiB',
            factorToAnchor: 1024,
          ),
          _UnitDefinition(
            id: 'mib',
            labelZh: 'MiB',
            labelEn: 'Mebibyte',
            symbol: 'MiB',
            factorToAnchor: 1048576,
          ),
          _UnitDefinition(
            id: 'gib',
            labelZh: 'GiB',
            labelEn: 'Gibibyte',
            symbol: 'GiB',
            factorToAnchor: 1073741824,
          ),
          _UnitDefinition(
            id: 'tib',
            labelZh: 'TiB',
            labelEn: 'Tebibyte',
            symbol: 'TiB',
            factorToAnchor: 1099511627776,
          ),
        ],
      ),
      _UnitCategoryDefinition(
        id: 'time',
        labelZh: '时间',
        labelEn: 'Time',
        units: <_UnitDefinition>[
          _UnitDefinition(
            id: 'sec',
            labelZh: '秒',
            labelEn: 'Second',
            symbol: 's',
            factorToAnchor: 1,
          ),
          _UnitDefinition(
            id: 'min',
            labelZh: '分钟',
            labelEn: 'Minute',
            symbol: 'min',
            factorToAnchor: 60,
          ),
          _UnitDefinition(
            id: 'hour',
            labelZh: '小时',
            labelEn: 'Hour',
            symbol: 'h',
            factorToAnchor: 3600,
          ),
          _UnitDefinition(
            id: 'day',
            labelZh: '天',
            labelEn: 'Day',
            symbol: 'd',
            factorToAnchor: 86400,
          ),
          _UnitDefinition(
            id: 'week',
            labelZh: '周',
            labelEn: 'Week',
            symbol: 'wk',
            factorToAnchor: 604800,
          ),
        ],
      ),
      _UnitCategoryDefinition(
        id: 'css',
        labelZh: 'CSS 尺寸',
        labelEn: 'CSS size',
        units: <_UnitDefinition>[
          _UnitDefinition(
            id: 'px',
            labelZh: '像素',
            labelEn: 'Pixel',
            symbol: 'px',
            factorToAnchor: 1,
          ),
          _UnitDefinition(
            id: 'rem',
            labelZh: '根字号倍数',
            labelEn: 'Root em',
            symbol: 'rem',
            factorToAnchor: 1,
          ),
          _UnitDefinition(
            id: 'em',
            labelZh: '当前字号倍数',
            labelEn: 'Em',
            symbol: 'em',
            factorToAnchor: 1,
          ),
          _UnitDefinition(
            id: 'pt',
            labelZh: '点',
            labelEn: 'Point',
            symbol: 'pt',
            factorToAnchor: 1,
          ),
          _UnitDefinition(
            id: 'pc',
            labelZh: '派卡',
            labelEn: 'Pica',
            symbol: 'pc',
            factorToAnchor: 1,
          ),
          _UnitDefinition(
            id: 'inch',
            labelZh: '英寸',
            labelEn: 'Inch',
            symbol: 'in',
            factorToAnchor: 1,
          ),
          _UnitDefinition(
            id: 'cm',
            labelZh: '厘米',
            labelEn: 'Centimeter',
            symbol: 'cm',
            factorToAnchor: 1,
          ),
          _UnitDefinition(
            id: 'mm',
            labelZh: '毫米',
            labelEn: 'Millimeter',
            symbol: 'mm',
            factorToAnchor: 1,
          ),
          _UnitDefinition(
            id: 'q',
            labelZh: '四分之一毫米',
            labelEn: 'Quarter-millimeter',
            symbol: 'Q',
            factorToAnchor: 1,
          ),
        ],
      ),
      _UnitCategoryDefinition(
        id: 'id_photo',
        labelZh: '证件照尺寸',
        labelEn: 'ID photo size',
        units: <_UnitDefinition>[],
        kind: _UnitCategoryKind.photo,
      ),
    ];

const List<_IdPhotoPreset> _idPhotoPresets = <_IdPhotoPreset>[
  _IdPhotoPreset(
    id: '1_inch',
    labelZh: '1寸',
    labelEn: '1 inch photo',
    aliasInchWidth: 1.0,
    aliasInchHeight: 1.4,
    mmWidth: 25,
    mmHeight: 35,
  ),
  _IdPhotoPreset(
    id: 'small_1_inch',
    labelZh: '小1寸',
    labelEn: 'Small 1 inch',
    aliasInchWidth: 0.9,
    aliasInchHeight: 1.3,
    mmWidth: 22,
    mmHeight: 32,
  ),
  _IdPhotoPreset(
    id: '2_inch',
    labelZh: '2寸',
    labelEn: '2 inch photo',
    aliasInchWidth: 1.4,
    aliasInchHeight: 2.0,
    mmWidth: 35,
    mmHeight: 49,
  ),
  _IdPhotoPreset(
    id: 'large_1_inch',
    labelZh: '大1寸',
    labelEn: 'Large 1 inch',
    aliasInchWidth: 1.3,
    aliasInchHeight: 1.9,
    mmWidth: 33,
    mmHeight: 48,
  ),
  _IdPhotoPreset(
    id: 'passport',
    labelZh: '护照',
    labelEn: 'Passport',
    aliasInchWidth: 1.3,
    aliasInchHeight: 1.9,
    mmWidth: 33,
    mmHeight: 48,
  ),
  _IdPhotoPreset(
    id: 'visa_2x2',
    labelZh: '2x2 签证照',
    labelEn: '2x2 visa',
    aliasInchWidth: 2,
    aliasInchHeight: 2,
    mmWidth: 51,
    mmHeight: 51,
  ),
];

class _UnitConverterToolPage extends StatefulWidget {
  const _UnitConverterToolPage();

  @override
  State<_UnitConverterToolPage> createState() => _UnitConverterToolPageState();
}

class _UnitConverterToolPageState extends State<_UnitConverterToolPage> {
  final TextEditingController _sourceController = TextEditingController(
    text: '1',
  );
  final TextEditingController _targetController = TextEditingController();

  late _UnitCategoryDefinition _category;
  late _UnitDefinition _sourceUnit;
  late _UnitDefinition _targetUnit;
  _IdPhotoPreset _photoPreset = _idPhotoPresets.first;
  double _photoDpi = 300;
  double _cssBasePx = 16;
  bool _isSyncing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _category = _unitConverterCategories.first;
    _sourceUnit = _category.units.firstWhere((unit) => unit.id == 'm');
    _targetUnit = _category.units.firstWhere((unit) => unit.id == 'cm');
    _syncFromSource();
  }

  @override
  void dispose() {
    _sourceController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  bool get _isPhotoCategory => _category.kind == _UnitCategoryKind.photo;

  bool get _isCssCategory => _category.id == 'css';

  double? _parseInput(String text) {
    final normalized = text.trim().replaceAll(',', '');
    if (normalized.isEmpty) {
      return null;
    }
    return double.tryParse(normalized);
  }

  void _syncFromSource() {
    if (_isPhotoCategory || _isSyncing) {
      return;
    }
    _isSyncing = true;
    final value = _parseInput(_sourceController.text);
    if (value == null) {
      _targetController.text = '';
      _error = _sourceController.text.trim().isEmpty
          ? null
          : _lifeText(context, zh: '请输入有效数字', en: 'Enter a valid number');
    } else {
      final result = _convertValue(
        value: value,
        from: _sourceUnit,
        to: _targetUnit,
      );
      _targetController.text = _formatUnitNumber(result);
      _error = null;
    }
    _isSyncing = false;
    if (mounted) {
      setState(() {});
    }
  }

  void _syncFromTarget() {
    if (_isPhotoCategory || _isSyncing) {
      return;
    }
    _isSyncing = true;
    final value = _parseInput(_targetController.text);
    if (value == null) {
      _sourceController.text = '';
      _error = _targetController.text.trim().isEmpty
          ? null
          : _lifeText(context, zh: '请输入有效数字', en: 'Enter a valid number');
    } else {
      final result = _convertValue(
        value: value,
        from: _targetUnit,
        to: _sourceUnit,
      );
      _sourceController.text = _formatUnitNumber(result);
      _error = null;
    }
    _isSyncing = false;
    if (mounted) {
      setState(() {});
    }
  }

  double _convertValue({
    required double value,
    required _UnitDefinition from,
    required _UnitDefinition to,
  }) {
    if (_isCssCategory) {
      final anchorValue = _cssToPx(value, from.id);
      return _pxToCss(anchorValue, to.id);
    }
    final anchorValue = from.toAnchor(value);
    return to.fromAnchor(anchorValue);
  }

  double _cssToPx(double value, String unitId) {
    return switch (unitId) {
      'px' => value,
      'rem' || 'em' => value * _cssBasePx,
      'pt' => value * (96 / 72),
      'pc' => value * 16,
      'inch' => value * 96,
      'cm' => value * (96 / 2.54),
      'mm' => value * (96 / 25.4),
      'q' => value * (96 / 101.6),
      _ => value,
    };
  }

  double _pxToCss(double value, String unitId) {
    return switch (unitId) {
      'px' => value,
      'rem' || 'em' => value / _cssBasePx,
      'pt' => value / (96 / 72),
      'pc' => value / 16,
      'inch' => value / 96,
      'cm' => value / (96 / 2.54),
      'mm' => value / (96 / 25.4),
      'q' => value / (96 / 101.6),
      _ => value,
    };
  }

  String _formatUnitNumber(double value) {
    final abs = value.abs();
    final digits = abs >= 1000
        ? 0
        : abs >= 100
        ? 1
        : abs >= 10
        ? 2
        : abs >= 1
        ? 3
        : 5;
    final text = value
        .toStringAsFixed(digits)
        .replaceFirst(RegExp(r'(\.\d*?[1-9])0+$'), r'$1')
        .replaceFirst(RegExp(r'\.0+$'), '');
    return text == '-0' ? '0' : text;
  }

  void _selectCategory(_UnitCategoryDefinition category) {
    setState(() {
      _category = category;
      _error = null;
      if (category.kind == _UnitCategoryKind.scalar &&
          category.units.length >= 2) {
        if (category.id == 'length') {
          _sourceUnit = category.units.firstWhere((unit) => unit.id == 'm');
          _targetUnit = category.units.firstWhere((unit) => unit.id == 'cm');
        } else if (category.id == 'css') {
          _sourceUnit = category.units.firstWhere((unit) => unit.id == 'px');
          _targetUnit = category.units.firstWhere((unit) => unit.id == 'rem');
        } else {
          _sourceUnit = category.units.first;
          _targetUnit = category.units[1];
        }
      }
    });
    if (!_isPhotoCategory) {
      _syncFromSource();
    }
  }

  void _swapUnits() {
    if (_isPhotoCategory) {
      return;
    }
    setState(() {
      final oldSource = _sourceUnit;
      _sourceUnit = _targetUnit;
      _targetUnit = oldSource;
      final oldSourceText = _sourceController.text;
      _sourceController.text = _targetController.text;
      _targetController.text = oldSourceText;
    });
  }

  List<_UnitDefinition> _quickUnits() {
    if (_isPhotoCategory) {
      return const <_UnitDefinition>[];
    }
    return _category.units
        .where((unit) => unit.id != _sourceUnit.id && unit.id != _targetUnit.id)
        .take(4)
        .toList(growable: false);
  }

  String _formatPhotoPair(double width, double height, String unit) {
    return '${_formatUnitNumber(width)} x ${_formatUnitNumber(height)} $unit';
  }

  int _photoPixels(double millimeter) {
    return ((millimeter / 25.4) * _photoDpi).round();
  }

  String _photoPixelPair(_IdPhotoPreset preset) {
    final width = _photoPixels(preset.mmWidth);
    final height = _photoPixels(preset.mmHeight);
    return '$width x $height px';
  }

  String _summaryText() {
    if (_isPhotoCategory) {
      return '${_photoPreset.label(context)} = '
          '${_formatPhotoPair(_photoPreset.aliasInchWidth, _photoPreset.aliasInchHeight, 'in')} = '
          '${_formatPhotoPair(_photoPreset.mmWidth / 10, _photoPreset.mmHeight / 10, 'cm')}';
    }

    final sourceValue = _parseInput(_sourceController.text);
    final targetValue = _parseInput(_targetController.text);
    if (sourceValue == null || targetValue == null) {
      return _lifeText(
        context,
        zh: '输入数字后会实时显示换算结果。',
        en: 'Enter a number to see the conversion result live.',
      );
    }
    return '${_formatUnitNumber(sourceValue)} ${_sourceUnit.symbol} = '
        '${_formatUnitNumber(targetValue)} ${_targetUnit.symbol}';
  }

  String _subtitleText() {
    if (_isPhotoCategory) {
      return _lifeText(
        context,
        zh: '常见证件照尺寸会同时给出英制别名、公制尺寸和指定 DPI 下的像素参考。',
        en: 'Common ID photo sizes show their inch alias, metric size, and pixel reference at the selected DPI.',
      );
    }
    if (_isCssCategory) {
      return _lifeText(
        context,
        zh: 'CSS 换算会用当前基准字号计算 rem / em，并保留 96px = 1in 的常见浏览器口径。',
        en: 'CSS conversions use the current base font size for rem / em and keep the standard 96px = 1in browser reference.',
      );
    }
    return _lifeText(
      context,
      zh: '长度、重量、温度、力、密度、功率、热量等分类都可双向编辑换算。',
      en: 'Length, weight, temperature, force, density, power, heat, and more all support bidirectional conversion.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final sourceValue = _parseInput(_sourceController.text);
    final quickUnits = _quickUnits();
    final rateText = (!_isPhotoCategory)
        ? _formatUnitNumber(
            _convertValue(value: 1, from: _sourceUnit, to: _targetUnit),
          )
        : '';

    return ToolboxToolPage(
      title: _lifeText(context, zh: '全能单位换算', en: 'Unit converter'),
      subtitle: _lifeText(
        context,
        zh: '覆盖更多常用单位、CSS 尺寸和证件照尺寸参考；既能做日常标量换算，也能处理设计与打印场景。',
        en: 'Covers more everyday units, CSS sizing, and ID photo references so it works for both scalar conversions and design or print tasks.',
      ),
      child: Column(
        key: const ValueKey<String>('life-unit-converter-page'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _LifeSettingsPanel(
            title: _lifeText(context, zh: '换算摘要', en: 'Summary'),
            subtitle: _subtitleText(),
            children: <Widget>[
              Text(
                _summaryText(),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  ToolboxMetricCard(
                    label: _lifeText(context, zh: '当前类别', en: 'Category'),
                    value: _category.label(context),
                  ),
                  if (_isPhotoCategory)
                    ToolboxMetricCard(
                      label: _lifeText(context, zh: '像素参考', en: 'Pixel size'),
                      value: _photoPixelPair(_photoPreset),
                    )
                  else
                    ToolboxMetricCard(
                      label: _lifeText(context, zh: '换算率', en: 'Rate'),
                      value:
                          '1 ${_sourceUnit.symbol} = $rateText ${_targetUnit.symbol}',
                    ),
                  if (_isCssCategory)
                    ToolboxMetricCard(
                      label: _lifeText(context, zh: '基准字号', en: 'Base size'),
                      value: '${_cssBasePx.round()} px',
                    )
                  else if (_isPhotoCategory)
                    ToolboxMetricCard(
                      label: _lifeText(
                        context,
                        zh: '当前 DPI',
                        en: 'Current DPI',
                      ),
                      value: _photoDpi.round().toString(),
                    ),
                ],
              ),
              if (_error != null) ...<Widget>[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          _LifeSettingsPanel(
            title: _lifeText(context, zh: '换算设置', en: 'Conversion setup'),
            subtitle: _lifeText(
              context,
              zh: '先选类别，再决定是做普通单位换算，还是查看证件照的尺寸参考。',
              en: 'Pick a category first, then either do a normal conversion or inspect ID photo dimensions.',
            ),
            children: <Widget>[
              _LifeSegmentedField<_UnitCategoryDefinition>(
                label: _lifeText(context, zh: '换算类别', en: 'Category'),
                value: _category,
                options: _unitConverterCategories
                    .map(
                      (category) => _LifeOption<_UnitCategoryDefinition>(
                        value: category,
                        labelZh: category.labelZh,
                        labelEn: category.labelEn,
                      ),
                    )
                    .toList(growable: false),
                onChanged: _selectCategory,
              ),
              if (_isPhotoCategory) ...<Widget>[
                const SizedBox(height: 14),
                _LifeSegmentedField<_IdPhotoPreset>(
                  label: _lifeText(context, zh: '证件照规格', en: 'Photo preset'),
                  value: _photoPreset,
                  options: _idPhotoPresets
                      .map(
                        (preset) => _LifeOption<_IdPhotoPreset>(
                          value: preset,
                          labelZh: preset.labelZh,
                          labelEn: preset.labelEn,
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) => setState(() => _photoPreset = value),
                ),
                const SizedBox(height: 12),
                _LifeSliderField(
                  label: _lifeText(context, zh: '输出 DPI', en: 'Output DPI'),
                  valueText: _photoDpi.round().toString(),
                  value: _photoDpi,
                  min: 72,
                  max: 600,
                  divisions: 528,
                  onChanged: (value) => setState(() => _photoDpi = value),
                ),
              ] else ...<Widget>[
                const SizedBox(height: 14),
                if (_isCssCategory) ...<Widget>[
                  _LifeSliderField(
                    label: _lifeText(context, zh: '基准字号', en: 'Base font size'),
                    valueText: '${_cssBasePx.round()} px',
                    value: _cssBasePx,
                    min: 10,
                    max: 24,
                    divisions: 14,
                    onChanged: (value) {
                      setState(() => _cssBasePx = value);
                      _syncFromSource();
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                LayoutBuilder(
                  builder: (context, constraints) {
                    final vertical = constraints.maxWidth < 520;
                    final fromField = _UnitFieldCard(
                      title: _lifeText(context, zh: '源值', en: 'From'),
                      controller: _sourceController,
                      unit: _sourceUnit,
                      units: _category.units,
                      inputKey: const ValueKey<String>(
                        'life-unit-converter-source',
                      ),
                      onTextChanged: (_) => _syncFromSource(),
                      onUnitChanged: (unit) {
                        setState(() => _sourceUnit = unit);
                        _syncFromSource();
                      },
                    );
                    final toField = _UnitFieldCard(
                      title: _lifeText(context, zh: '目标值', en: 'To'),
                      controller: _targetController,
                      unit: _targetUnit,
                      units: _category.units,
                      inputKey: const ValueKey<String>(
                        'life-unit-converter-target',
                      ),
                      onTextChanged: (_) => _syncFromTarget(),
                      onUnitChanged: (unit) {
                        setState(() => _targetUnit = unit);
                        _syncFromSource();
                      },
                    );

                    if (vertical) {
                      return Column(
                        children: <Widget>[
                          fromField,
                          const SizedBox(height: 8),
                          Center(
                            child: FilledButton.tonalIcon(
                              key: const ValueKey<String>(
                                'life-unit-converter-swap',
                              ),
                              onPressed: _swapUnits,
                              icon: const Icon(Icons.swap_vert_rounded),
                              label: Text(
                                _lifeText(context, zh: '交换方向', en: 'Swap'),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          toField,
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(child: fromField),
                        const SizedBox(width: 10),
                        Padding(
                          padding: const EdgeInsets.only(top: 56),
                          child: FilledButton.tonalIcon(
                            key: const ValueKey<String>(
                              'life-unit-converter-swap',
                            ),
                            onPressed: _swapUnits,
                            icon: const Icon(Icons.swap_horiz_rounded),
                            label: Text(
                              _lifeText(context, zh: '交换', en: 'Swap'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: toField),
                      ],
                    );
                  },
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          _LifeSettingsPanel(
            title: _lifeText(
              context,
              zh: _isPhotoCategory ? '尺寸参考' : '常用结果',
              en: _isPhotoCategory ? 'Reference sizes' : 'Quick results',
            ),
            subtitle: _lifeText(
              context,
              zh: _isPhotoCategory
                  ? '直接给出英制、公制和像素口径，方便做证件照排版或下单核对。'
                  : '用当前源值快速查看同类里的几个常用单位，适合日常估算。',
              en: _isPhotoCategory
                  ? 'See inch, metric, and pixel references together for print or ordering checks.'
                  : 'See a few common units from the same category using the current source value.',
            ),
            children: <Widget>[
              if (_isPhotoCategory)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    ToolboxMetricCard(
                      label: _lifeText(context, zh: '英制别名', en: 'Inch alias'),
                      value: _formatPhotoPair(
                        _photoPreset.aliasInchWidth,
                        _photoPreset.aliasInchHeight,
                        'in',
                      ),
                    ),
                    ToolboxMetricCard(
                      label: _lifeText(context, zh: '公制厘米', en: 'Centimeter'),
                      value: _formatPhotoPair(
                        _photoPreset.mmWidth / 10,
                        _photoPreset.mmHeight / 10,
                        'cm',
                      ),
                    ),
                    ToolboxMetricCard(
                      label: _lifeText(context, zh: '公制毫米', en: 'Millimeter'),
                      value: _formatPhotoPair(
                        _photoPreset.mmWidth,
                        _photoPreset.mmHeight,
                        'mm',
                      ),
                    ),
                    ToolboxMetricCard(
                      label: _lifeText(context, zh: '像素尺寸', en: 'Pixel size'),
                      value: _photoPixelPair(_photoPreset),
                    ),
                  ],
                )
              else if (quickUnits.isEmpty || sourceValue == null)
                Text(
                  _lifeText(
                    context,
                    zh: '输入一个数字后，这里会显示同类常用单位的速览结果。',
                    en: 'Enter a number and this area will show quick results for common units in the same category.',
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: quickUnits
                      .map((unit) {
                        final value = _convertValue(
                          value: sourceValue,
                          from: _sourceUnit,
                          to: unit,
                        );
                        return ToolboxMetricCard(
                          label: unit.symbol,
                          value: _formatUnitNumber(value),
                        );
                      })
                      .toList(growable: false),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _LifeSettingsPanel(
            title: _lifeText(context, zh: '使用提示', en: 'Notes'),
            children: <Widget>[
              Text(
                _isPhotoCategory
                    ? _lifeText(
                        context,
                        zh: '证件照里的“寸”通常是市场称呼，页面同时给出英制别名和实际公制尺寸；像素结果按当前 DPI 计算，适合作为排版和打印前核对参考。',
                        en: 'Chinese ID photo inch names are common market aliases, so the page shows both the inch label and the actual metric size. Pixel values are calculated from the current DPI for layout and print checks.',
                      )
                    : _isCssCategory
                    ? _lifeText(
                        context,
                        zh: 'CSS 里的 rem / em 依赖字号上下文。这里为了便于换算，默认把 em 也按当前基准字号处理；真实页面里如果父级字号不同，结果会跟着变化。',
                        en: 'In CSS, rem and em depend on font-size context. This calculator treats em with the current base size for convenience; real pages may differ when parent font sizes change.',
                      )
                    : _lifeText(
                        context,
                        zh: '当前以本地静态单位表做换算，不依赖网络；温度使用开尔文作中间基准，数据单位同时保留十进制与二进制口径。',
                        en: 'All conversions run locally with a static unit table. Temperature uses Kelvin as the anchor, and data units keep both decimal and binary conventions.',
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UnitFieldCard extends StatelessWidget {
  const _UnitFieldCard({
    required this.title,
    required this.controller,
    required this.unit,
    required this.units,
    required this.inputKey,
    required this.onTextChanged,
    required this.onUnitChanged,
  });

  final String title;
  final TextEditingController controller;
  final _UnitDefinition unit;
  final List<_UnitDefinition> units;
  final Key inputKey;
  final ValueChanged<String> onTextChanged;
  final ValueChanged<_UnitDefinition> onUnitChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<_UnitDefinition>(
            key: ValueKey<String>('unit-dropdown-$title-${unit.id}'),
            initialValue: unit,
            isExpanded: true,
            items: units
                .map(
                  (item) => DropdownMenuItem<_UnitDefinition>(
                    value: item,
                    child: Text(
                      '${item.label(context)} (${item.symbol})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) {
              if (value != null) {
                onUnitChanged(value);
              }
            },
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: _lifeText(context, zh: '单位', en: 'Unit'),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            key: inputKey,
            controller: controller,
            onChanged: onTextChanged,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: _lifeText(context, zh: '数值', en: 'Value'),
            ),
          ),
        ],
      ),
    );
  }
}
