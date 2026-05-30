part of '../toolbox_life_tools.dart';

enum _UnitCategoryKind { scalar, photo }

class _UnitCategoryDefinition {
  const _UnitCategoryDefinition({
    required this.id,
    required this.labelKey,
    required this.units,
    this.kind = _UnitCategoryKind.scalar,
  });

  final String id;
  final String labelKey;
  final List<_UnitDefinition> units;
  final _UnitCategoryKind kind;

  String label(BuildContext context) {
    return _lifeI18nText(context, labelKey);
  }
}

class _UnitDefinition {
  const _UnitDefinition({
    required this.id,
    required this.labelKey,
    required this.symbol,
    required this.factorToAnchor,
    this.offsetToAnchor = 0,
  });

  final String id;
  final String labelKey;
  final String symbol;
  final double factorToAnchor;
  final double offsetToAnchor;

  String label(BuildContext context) {
    return _lifeI18nText(context, labelKey);
  }

  double toAnchor(double value) => value * factorToAnchor + offsetToAnchor;

  double fromAnchor(double value) => (value - offsetToAnchor) / factorToAnchor;
}

class _IdPhotoPreset {
  const _IdPhotoPreset({
    required this.id,
    required this.labelKey,
    required this.aliasInchWidth,
    required this.aliasInchHeight,
    required this.mmWidth,
    required this.mmHeight,
  });

  final String id;
  final String labelKey;
  final double aliasInchWidth;
  final double aliasInchHeight;
  final double mmWidth;
  final double mmHeight;

  String label(BuildContext context) {
    return _lifeI18nText(context, labelKey);
  }
}

const List<_UnitCategoryDefinition>
_unitConverterCategories = <_UnitCategoryDefinition>[
  _UnitCategoryDefinition(
    id: 'length',
    labelKey:
        'inline.ui.pages.toolbox_human_tests_typing_widgets.length_f37873',
    units: <_UnitDefinition>[
      _UnitDefinition(
        id: 'nm',
        labelKey: 'inline.plan295.life.nanometer.ecc4ab3fbc93',
        symbol: 'nm',
        factorToAnchor: 0.000000001,
      ),
      _UnitDefinition(
        id: 'um',
        labelKey: 'inline.plan295.life.micrometer.db208f28e0f4',
        symbol: 'um',
        factorToAnchor: 0.000001,
      ),
      _UnitDefinition(
        id: 'mm',
        labelKey: 'inline.plan295.life.millimeter.0e992d10bbbf',
        symbol: 'mm',
        factorToAnchor: 0.001,
      ),
      _UnitDefinition(
        id: 'cm',
        labelKey: 'inline.plan295.life.centimeter.16520bb8d303',
        symbol: 'cm',
        factorToAnchor: 0.01,
      ),
      _UnitDefinition(
        id: 'm',
        labelKey: 'inline.plan295.life.meter.3c62f9728481',
        symbol: 'm',
        factorToAnchor: 1,
      ),
      _UnitDefinition(
        id: 'km',
        labelKey: 'inline.plan295.life.kilometer.a4da246415c3',
        symbol: 'km',
        factorToAnchor: 1000,
      ),
      _UnitDefinition(
        id: 'li',
        labelKey: 'inline.plan295.life.li.0002e076dc15',
        symbol: '里',
        factorToAnchor: 500,
      ),
      _UnitDefinition(
        id: 'inch',
        labelKey: 'inline.plan295.life.inch.51e0faecfdb3',
        symbol: 'in',
        factorToAnchor: 0.0254,
      ),
      _UnitDefinition(
        id: 'ft',
        labelKey: 'inline.plan295.life.foot.0046a67e934f',
        symbol: 'ft',
        factorToAnchor: 0.3048,
      ),
      _UnitDefinition(
        id: 'yd',
        labelKey: 'inline.plan295.life.yard.99f0da222bb3',
        symbol: 'yd',
        factorToAnchor: 0.9144,
      ),
      _UnitDefinition(
        id: 'mile',
        labelKey: 'inline.plan295.life.mile.1115867cbc37',
        symbol: 'mi',
        factorToAnchor: 1609.344,
      ),
      _UnitDefinition(
        id: 'nmi',
        labelKey: 'inline.plan295.life.nautical_mile.5d139b2b21b6',
        symbol: 'nmi',
        factorToAnchor: 1852,
      ),
      _UnitDefinition(
        id: 'au',
        labelKey: 'inline.plan295.life.astronomical_unit.a46a19c83de0',
        symbol: 'AU',
        factorToAnchor: 149597870700,
      ),
      _UnitDefinition(
        id: 'ly',
        labelKey: 'inline.plan295.life.light_year.0d72aca83253',
        symbol: 'ly',
        factorToAnchor: 9460730472580800,
      ),
    ],
  ),
  _UnitCategoryDefinition(
    id: 'weight',
    labelKey: 'inline.plan295.life.weight.a353a17dc3f6',
    units: <_UnitDefinition>[
      _UnitDefinition(
        id: 'ug',
        labelKey: 'inline.plan295.life.microgram.ae520be50c79',
        symbol: 'ug',
        factorToAnchor: 0.000000001,
      ),
      _UnitDefinition(
        id: 'mg',
        labelKey: 'inline.plan295.life.milligram.3c2b08df842e',
        symbol: 'mg',
        factorToAnchor: 0.000001,
      ),
      _UnitDefinition(
        id: 'g',
        labelKey: 'inline.plan295.life.gram.d901d66d5e2f',
        symbol: 'g',
        factorToAnchor: 0.001,
      ),
      _UnitDefinition(
        id: 'jin',
        labelKey: 'inline.plan295.life.jin.308f3356f496',
        symbol: '斤',
        factorToAnchor: 0.5,
      ),
      _UnitDefinition(
        id: 'kg',
        labelKey: 'inline.plan295.life.kilogram.c4f0c9a02d5e',
        symbol: 'kg',
        factorToAnchor: 1,
      ),
      _UnitDefinition(
        id: 'ton',
        labelKey: 'inline.plan295.life.metric_ton.618eaab94808',
        symbol: 't',
        factorToAnchor: 1000,
      ),
      _UnitDefinition(
        id: 'lb',
        labelKey: 'inline.plan295.life.pound.0331b8d00c40',
        symbol: 'lb',
        factorToAnchor: 0.45359237,
      ),
      _UnitDefinition(
        id: 'oz',
        labelKey: 'inline.plan295.life.ounce.08f01b0cc4b4',
        symbol: 'oz',
        factorToAnchor: 0.028349523125,
      ),
      _UnitDefinition(
        id: 'stone',
        labelKey: 'inline.plan295.life.stone.7e89e734d1a3',
        symbol: 'st',
        factorToAnchor: 6.35029318,
      ),
    ],
  ),
  _UnitCategoryDefinition(
    id: 'temperature',
    labelKey:
        'inline.ui.pages.toolbox_daily_choice.daily_choice_wear_module.temperature_fb37d5',
    units: <_UnitDefinition>[
      _UnitDefinition(
        id: 'c',
        labelKey: 'inline.plan295.life.celsius.3926b11e39f5',
        symbol: '°C',
        factorToAnchor: 1,
        offsetToAnchor: 273.15,
      ),
      _UnitDefinition(
        id: 'f',
        labelKey: 'inline.plan295.life.fahrenheit.5601fa9cb868',
        symbol: '°F',
        factorToAnchor: 5 / 9,
        offsetToAnchor: 255.3722222222,
      ),
      _UnitDefinition(
        id: 'k',
        labelKey: 'inline.plan295.life.kelvin.e03397ee29c9',
        symbol: 'K',
        factorToAnchor: 1,
      ),
    ],
  ),
  _UnitCategoryDefinition(
    id: 'area',
    labelKey: 'inline.plan295.life.area.ebeca77e446f',
    units: <_UnitDefinition>[
      _UnitDefinition(
        id: 'sqm',
        labelKey: 'inline.plan295.life.square_meter.2da33b245fd4',
        symbol: 'm²',
        factorToAnchor: 1,
      ),
      _UnitDefinition(
        id: 'sqcm',
        labelKey: 'inline.plan295.life.square_centimeter.1f6333d475eb',
        symbol: 'cm²',
        factorToAnchor: 0.0001,
      ),
      _UnitDefinition(
        id: 'sqmm',
        labelKey: 'inline.plan295.life.square_millimeter.2a14d83230d2',
        symbol: 'mm²',
        factorToAnchor: 0.000001,
      ),
      _UnitDefinition(
        id: 'mu',
        labelKey: 'inline.plan295.life.mu.934b578f9dfe',
        symbol: '亩',
        factorToAnchor: 666.6666667,
      ),
      _UnitDefinition(
        id: 'sqft',
        labelKey: 'inline.plan295.life.square_foot.7504c5974f05',
        symbol: 'ft²',
        factorToAnchor: 0.09290304,
      ),
      _UnitDefinition(
        id: 'acre',
        labelKey: 'inline.plan295.life.acre.70db88a71864',
        symbol: 'ac',
        factorToAnchor: 4046.8564224,
      ),
      _UnitDefinition(
        id: 'hectare',
        labelKey: 'inline.plan295.life.hectare.f276a91d958a',
        symbol: 'ha',
        factorToAnchor: 10000,
      ),
    ],
  ),
  _UnitCategoryDefinition(
    id: 'volume',
    labelKey: 'inline.plan295.life.volume.e0cd499ede11',
    units: <_UnitDefinition>[
      _UnitDefinition(
        id: 'ml',
        labelKey: 'inline.plan295.life.milliliter.16d8765e56fd',
        symbol: 'mL',
        factorToAnchor: 0.001,
      ),
      _UnitDefinition(
        id: 'l',
        labelKey: 'inline.plan295.life.liter.073da36b9faf',
        symbol: 'L',
        factorToAnchor: 1,
      ),
      _UnitDefinition(
        id: 'm3',
        labelKey: 'inline.plan295.life.cubic_meter.5ce4ed9d3b79',
        symbol: 'm³',
        factorToAnchor: 1000,
      ),
      _UnitDefinition(
        id: 'cc',
        labelKey: 'inline.plan295.life.cubic_centimeter.960470b92fdd',
        symbol: 'cm³',
        factorToAnchor: 0.001,
      ),
      _UnitDefinition(
        id: 'cup',
        labelKey: 'inline.plan295.life.cup.6bc77c197220',
        symbol: 'cup',
        factorToAnchor: 0.2365882365,
      ),
      _UnitDefinition(
        id: 'pt',
        labelKey: 'inline.plan295.life.pint.00f9a4988ac9',
        symbol: 'pt',
        factorToAnchor: 0.473176473,
      ),
      _UnitDefinition(
        id: 'gal',
        labelKey: 'inline.plan295.life.gallon.d19992e15d49',
        symbol: 'gal',
        factorToAnchor: 3.785411784,
      ),
    ],
  ),
  _UnitCategoryDefinition(
    id: 'speed',
    labelKey:
        'inline.ui.pages.toolbox_human_tests_hand_eye_settings.speed_29ca97',
    units: <_UnitDefinition>[
      _UnitDefinition(
        id: 'mps',
        labelKey: 'inline.plan295.life.meter_per_second.471ca3f0431d',
        symbol: 'm/s',
        factorToAnchor: 1,
      ),
      _UnitDefinition(
        id: 'kph',
        labelKey: 'inline.plan295.life.kilometer_per_hour.e968e5a4ccdd',
        symbol: 'km/h',
        factorToAnchor: 0.2777777778,
      ),
      _UnitDefinition(
        id: 'mph',
        labelKey: 'inline.plan295.life.mile_per_hour.0da0ac90d1a7',
        symbol: 'mph',
        factorToAnchor: 0.44704,
      ),
      _UnitDefinition(
        id: 'knot',
        labelKey: 'inline.plan295.life.nautical_mile_per_hour.31bd520ae0dc',
        symbol: 'kn',
        factorToAnchor: 0.5144444444,
      ),
    ],
  ),
  _UnitCategoryDefinition(
    id: 'force',
    labelKey: 'inline.plan295.life.force.d3ff4a2991b4',
    units: <_UnitDefinition>[
      _UnitDefinition(
        id: 'n',
        labelKey: 'inline.plan295.life.newton.476680c0aadb',
        symbol: 'N',
        factorToAnchor: 1,
      ),
      _UnitDefinition(
        id: 'kn',
        labelKey: 'inline.plan295.life.kilonewton.a38073e6253d',
        symbol: 'kN',
        factorToAnchor: 1000,
      ),
      _UnitDefinition(
        id: 'gf',
        labelKey: 'inline.plan295.life.gram_force.c8ba8f4544e6',
        symbol: 'gf',
        factorToAnchor: 0.00980665,
      ),
      _UnitDefinition(
        id: 'kgf',
        labelKey: 'inline.plan295.life.kilogram_force.c798f61470c4',
        symbol: 'kgf',
        factorToAnchor: 9.80665,
      ),
      _UnitDefinition(
        id: 'lbf',
        labelKey: 'inline.plan295.life.pound_force.59555a2118fe',
        symbol: 'lbf',
        factorToAnchor: 4.4482216153,
      ),
      _UnitDefinition(
        id: 'dyn',
        labelKey: 'inline.plan295.life.dyne.a00ec75a643d',
        symbol: 'dyn',
        factorToAnchor: 0.00001,
      ),
    ],
  ),
  _UnitCategoryDefinition(
    id: 'density',
    labelKey: 'inline.plan295.life.density.02f64cf6bb37',
    units: <_UnitDefinition>[
      _UnitDefinition(
        id: 'kgm3',
        labelKey: 'inline.plan295.life.kilogram_per_cubic_meter.9adb4edbe879',
        symbol: 'kg/m³',
        factorToAnchor: 1,
      ),
      _UnitDefinition(
        id: 'gl',
        labelKey: 'inline.plan295.life.gram_per_liter.0a0becfa7b0c',
        symbol: 'g/L',
        factorToAnchor: 1,
      ),
      _UnitDefinition(
        id: 'gml',
        labelKey: 'inline.plan295.life.gram_per_milliliter.d27b10c02568',
        symbol: 'g/mL',
        factorToAnchor: 1000,
      ),
      _UnitDefinition(
        id: 'gcc',
        labelKey: 'inline.plan295.life.gram_per_cubic_centimeter.8745e803aaef',
        symbol: 'g/cm³',
        factorToAnchor: 1000,
      ),
      _UnitDefinition(
        id: 'lbft3',
        labelKey: 'inline.plan295.life.pound_per_cubic_foot.ccbd0deaad01',
        symbol: 'lb/ft³',
        factorToAnchor: 16.01846337396,
      ),
      _UnitDefinition(
        id: 'lbin3',
        labelKey: 'inline.plan295.life.pound_per_cubic_inch.eb936c9428e1',
        symbol: 'lb/in³',
        factorToAnchor: 27679.9047102,
      ),
    ],
  ),
  _UnitCategoryDefinition(
    id: 'power',
    labelKey: 'inline.plan295.life.power.0d91303bc14c',
    units: <_UnitDefinition>[
      _UnitDefinition(
        id: 'w',
        labelKey: 'inline.plan295.life.watt.cff24297126f',
        symbol: 'W',
        factorToAnchor: 1,
      ),
      _UnitDefinition(
        id: 'kw',
        labelKey: 'inline.plan295.life.kilowatt.43be899db17f',
        symbol: 'kW',
        factorToAnchor: 1000,
      ),
      _UnitDefinition(
        id: 'mw',
        labelKey: 'inline.plan295.life.megawatt.96f426ce27b3',
        symbol: 'MW',
        factorToAnchor: 1000000,
      ),
      _UnitDefinition(
        id: 'hp',
        labelKey: 'inline.plan295.life.horsepower.9db0efba78a6',
        symbol: 'hp',
        factorToAnchor: 745.699871582,
      ),
      _UnitDefinition(
        id: 'ps',
        labelKey: 'inline.plan295.life.metric_horsepower.c4b0668d3702',
        symbol: 'PS',
        factorToAnchor: 735.49875,
      ),
      _UnitDefinition(
        id: 'cals',
        labelKey: 'inline.plan295.life.calorie_per_second.751703d2167c',
        symbol: 'cal/s',
        factorToAnchor: 4.184,
      ),
    ],
  ),
  _UnitCategoryDefinition(
    id: 'energy',
    labelKey: 'inline.plan295.life.heat_energy.c9e48eb8aa38',
    units: <_UnitDefinition>[
      _UnitDefinition(
        id: 'j',
        labelKey: 'inline.plan295.life.joule.bc52d1e67c6a',
        symbol: 'J',
        factorToAnchor: 1,
      ),
      _UnitDefinition(
        id: 'kj',
        labelKey: 'inline.plan295.life.kilojoule.6d58fd31bfc7',
        symbol: 'kJ',
        factorToAnchor: 1000,
      ),
      _UnitDefinition(
        id: 'cal',
        labelKey: 'inline.plan295.life.calorie.b0fb9758a100',
        symbol: 'cal',
        factorToAnchor: 4.184,
      ),
      _UnitDefinition(
        id: 'kcal',
        labelKey: 'inline.plan295.life.kilocalorie.521ff534817d',
        symbol: 'kcal',
        factorToAnchor: 4184,
      ),
      _UnitDefinition(
        id: 'wh',
        labelKey: 'inline.plan295.life.watt_hour.c34dffcd30f8',
        symbol: 'Wh',
        factorToAnchor: 3600,
      ),
      _UnitDefinition(
        id: 'kwh',
        labelKey: 'inline.plan295.life.kilowatt_hour.245a969a0c6d',
        symbol: 'kWh',
        factorToAnchor: 3600000,
      ),
      _UnitDefinition(
        id: 'btu',
        labelKey: 'inline.plan295.life.british_thermal_unit.d9a26453ee8d',
        symbol: 'BTU',
        factorToAnchor: 1055.05585262,
      ),
    ],
  ),
  _UnitCategoryDefinition(
    id: 'data',
    labelKey: 'inline.plan295.life.data.79398b2fc733',
    units: <_UnitDefinition>[
      _UnitDefinition(
        id: 'byte',
        labelKey: 'inline.plan295.life.byte.1c46fd594f49',
        symbol: 'B',
        factorToAnchor: 1,
      ),
      _UnitDefinition(
        id: 'kb',
        labelKey: 'inline.plan295.life.kilobyte.aac0dfe8c4d6',
        symbol: 'KB',
        factorToAnchor: 1000,
      ),
      _UnitDefinition(
        id: 'mb',
        labelKey: 'inline.plan295.life.megabyte.606a4379513b',
        symbol: 'MB',
        factorToAnchor: 1000000,
      ),
      _UnitDefinition(
        id: 'gb',
        labelKey: 'inline.plan295.life.gigabyte.bdc580a612ed',
        symbol: 'GB',
        factorToAnchor: 1000000000,
      ),
      _UnitDefinition(
        id: 'tb',
        labelKey: 'inline.plan295.life.terabyte.9f9b2d8a5ff7',
        symbol: 'TB',
        factorToAnchor: 1000000000000,
      ),
      _UnitDefinition(
        id: 'kib',
        labelKey: 'inline.plan295.life.kibibyte.95d03d1627a6',
        symbol: 'KiB',
        factorToAnchor: 1024,
      ),
      _UnitDefinition(
        id: 'mib',
        labelKey: 'inline.plan295.life.mebibyte.cc784ed0ac16',
        symbol: 'MiB',
        factorToAnchor: 1048576,
      ),
      _UnitDefinition(
        id: 'gib',
        labelKey: 'inline.plan295.life.gibibyte.a18d7c01420c',
        symbol: 'GiB',
        factorToAnchor: 1073741824,
      ),
      _UnitDefinition(
        id: 'tib',
        labelKey: 'inline.plan295.life.tebibyte.6377168d14e0',
        symbol: 'TiB',
        factorToAnchor: 1099511627776,
      ),
    ],
  ),
  _UnitCategoryDefinition(
    id: 'time',
    labelKey: 'inline.ui.pages.toolbox_human_tests_typing.time_b4685a',
    units: <_UnitDefinition>[
      _UnitDefinition(
        id: 'sec',
        labelKey: 'inline.plan295.life.second.8bad2d2ed174',
        symbol: 's',
        factorToAnchor: 1,
      ),
      _UnitDefinition(
        id: 'min',
        labelKey: 'inline.plan295.life.minute.aed74b54c4c7',
        symbol: 'min',
        factorToAnchor: 60,
      ),
      _UnitDefinition(
        id: 'hour',
        labelKey: 'inline.plan295.life.hour.065840e3aa31',
        symbol: 'h',
        factorToAnchor: 3600,
      ),
      _UnitDefinition(
        id: 'day',
        labelKey: 'inline.plan295.life.day.63a96425451d',
        symbol: 'd',
        factorToAnchor: 86400,
      ),
      _UnitDefinition(
        id: 'week',
        labelKey: 'inline.plan295.life.week.3d541f151800',
        symbol: 'wk',
        factorToAnchor: 604800,
      ),
    ],
  ),
  _UnitCategoryDefinition(
    id: 'css',
    labelKey: 'inline.plan295.life.css_size.1538daa28190',
    units: <_UnitDefinition>[
      _UnitDefinition(
        id: 'px',
        labelKey: 'inline.plan295.life.pixel.d57e570585c6',
        symbol: 'px',
        factorToAnchor: 1,
      ),
      _UnitDefinition(
        id: 'rem',
        labelKey: 'inline.plan295.life.root_em.e5bdfd39e36c',
        symbol: 'rem',
        factorToAnchor: 1,
      ),
      _UnitDefinition(
        id: 'em',
        labelKey: 'inline.plan295.life.em.8707fe73bacd',
        symbol: 'em',
        factorToAnchor: 1,
      ),
      _UnitDefinition(
        id: 'pt',
        labelKey: 'inline.plan295.life.point.e07fc19463e0',
        symbol: 'pt',
        factorToAnchor: 1,
      ),
      _UnitDefinition(
        id: 'pc',
        labelKey: 'inline.plan295.life.pica.a766b1a6dc17',
        symbol: 'pc',
        factorToAnchor: 1,
      ),
      _UnitDefinition(
        id: 'inch',
        labelKey: 'inline.plan295.life.inch.51e0faecfdb3',
        symbol: 'in',
        factorToAnchor: 1,
      ),
      _UnitDefinition(
        id: 'cm',
        labelKey: 'inline.plan295.life.centimeter.16520bb8d303',
        symbol: 'cm',
        factorToAnchor: 1,
      ),
      _UnitDefinition(
        id: 'mm',
        labelKey: 'inline.plan295.life.millimeter.0e992d10bbbf',
        symbol: 'mm',
        factorToAnchor: 1,
      ),
      _UnitDefinition(
        id: 'q',
        labelKey: 'inline.plan295.life.quarter_millimeter.d2e43403fdfa',
        symbol: 'Q',
        factorToAnchor: 1,
      ),
    ],
  ),
  _UnitCategoryDefinition(
    id: 'id_photo',
    labelKey: 'inline.plan295.life.id_photo_size.284764ab0964',
    units: <_UnitDefinition>[],
    kind: _UnitCategoryKind.photo,
  ),
];

const List<_IdPhotoPreset> _idPhotoPresets = <_IdPhotoPreset>[
  _IdPhotoPreset(
    id: '1_inch',
    labelKey: 'inline.plan295.life.1_inch_photo.994b29d2e76c',
    aliasInchWidth: 1.0,
    aliasInchHeight: 1.4,
    mmWidth: 25,
    mmHeight: 35,
  ),
  _IdPhotoPreset(
    id: 'small_1_inch',
    labelKey: 'inline.plan295.life.small_1_inch.f35153b3d117',
    aliasInchWidth: 0.9,
    aliasInchHeight: 1.3,
    mmWidth: 22,
    mmHeight: 32,
  ),
  _IdPhotoPreset(
    id: '2_inch',
    labelKey: 'inline.plan295.life.2_inch_photo.d0e2f4cc1bad',
    aliasInchWidth: 1.4,
    aliasInchHeight: 2.0,
    mmWidth: 35,
    mmHeight: 49,
  ),
  _IdPhotoPreset(
    id: 'large_1_inch',
    labelKey: 'inline.plan295.life.large_1_inch.f39a9a731d05',
    aliasInchWidth: 1.3,
    aliasInchHeight: 1.9,
    mmWidth: 33,
    mmHeight: 48,
  ),
  _IdPhotoPreset(
    id: 'passport',
    labelKey: 'inline.plan295.life.passport.70b5caab0996',
    aliasInchWidth: 1.3,
    aliasInchHeight: 1.9,
    mmWidth: 33,
    mmHeight: 48,
  ),
  _IdPhotoPreset(
    id: 'visa_2x2',
    labelKey: 'inline.plan295.life.2x2_visa.4cba9cde051a',
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
          : _lifeI18nText(
              context,
              'inline.plan295.life.enter_a_valid_number.d75ca05f858f',
            );
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
          : _lifeI18nText(
              context,
              'inline.plan295.life.enter_a_valid_number.d75ca05f858f',
            );
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
      return _lifeI18nText(
        context,
        'inline.plan295.life.enter_a_number_to_see_the_conversion.21fd3c87f3fc',
      );
    }
    return '${_formatUnitNumber(sourceValue)} ${_sourceUnit.symbol} = '
        '${_formatUnitNumber(targetValue)} ${_targetUnit.symbol}';
  }

  String _subtitleText() {
    if (_isPhotoCategory) {
      return _lifeI18nText(
        context,
        'inline.plan295.life.common_id_photo_sizes_show_their_inc.9535498e58b7',
      );
    }
    if (_isCssCategory) {
      return _lifeI18nText(
        context,
        'inline.plan295.life.css_conversions_use_the_current_base.81006cbfb044',
      );
    }
    return _lifeI18nText(
      context,
      'inline.plan295.life.length_weight_temperature_force_dens.8d5a6e318455',
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
      title: _lifeI18nText(
        context,
        'inline.plan295.life.unit_converter.53644e92a340',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.covers_more_everyday_units_css_sizin.1a10d39c93f9',
      ),
      child: Column(
        key: const ValueKey<String>('life-unit-converter-page'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _LifeSettingsPanel(
            title: _lifeI18nText(
              context,
              'inline.plan295.life.summary.f651872ce10d',
            ),
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
                    label: _lifeI18nText(
                      context,
                      'inline.plan295.life.category.01bb8de30952',
                    ),
                    value: _category.label(context),
                  ),
                  if (_isPhotoCategory)
                    ToolboxMetricCard(
                      label: _lifeI18nText(
                        context,
                        'inline.plan295.life.pixel_size.5a00afad8a59',
                      ),
                      value: _photoPixelPair(_photoPreset),
                    )
                  else
                    ToolboxMetricCard(
                      label: _lifeI18nText(
                        context,
                        'inline.plan295.life.rate.b13e52582178',
                      ),
                      value:
                          '1 ${_sourceUnit.symbol} = $rateText ${_targetUnit.symbol}',
                    ),
                  if (_isCssCategory)
                    ToolboxMetricCard(
                      label: _lifeI18nText(
                        context,
                        'inline.plan295.life.base_size.418fa67607ac',
                      ),
                      value: '${_cssBasePx.round()} px',
                    )
                  else if (_isPhotoCategory)
                    ToolboxMetricCard(
                      label: _lifeI18nText(
                        context,
                        'inline.plan295.life.current_dpi.0f2fa03398d1',
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
            title: _lifeI18nText(
              context,
              'inline.plan295.life.conversion_setup.4f98927bdb29',
            ),
            subtitle: _lifeI18nText(
              context,
              'inline.plan295.life.pick_a_category_first_then_either_do.99b641cc39bc',
            ),
            children: <Widget>[
              _LifeSegmentedField<_UnitCategoryDefinition>(
                label: _lifeI18nText(
                  context,
                  'inline.plan295.life.category.d92f7dfb2767',
                ),
                value: _category,
                options: _unitConverterCategories
                    .map(
                      (category) => _LifeOption<_UnitCategoryDefinition>(
                        value: category,
                        labelKey: category.labelKey,
                      ),
                    )
                    .toList(growable: false),
                onChanged: _selectCategory,
              ),
              if (_isPhotoCategory) ...<Widget>[
                const SizedBox(height: 14),
                _LifeSegmentedField<_IdPhotoPreset>(
                  label: _lifeI18nText(
                    context,
                    'inline.plan295.life.photo_preset.69f15dc54716',
                  ),
                  value: _photoPreset,
                  options: _idPhotoPresets
                      .map(
                        (preset) => _LifeOption<_IdPhotoPreset>(
                          value: preset,
                          labelKey: preset.labelKey,
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) => setState(() => _photoPreset = value),
                ),
                const SizedBox(height: 12),
                _LifeSliderField(
                  label: _lifeI18nText(
                    context,
                    'inline.plan295.life.output_dpi.8d832829b304',
                  ),
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
                    label: _lifeI18nText(
                      context,
                      'inline.plan295.life.base_font_size.decc868f15e9',
                    ),
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
                      title: _lifeI18nText(
                        context,
                        'inline.plan295.life.from.b67ec9554275',
                      ),
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
                      title: _lifeI18nText(
                        context,
                        'inline.plan295.life.to.e5c80c4b289d',
                      ),
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
                                _lifeI18nText(
                                  context,
                                  'inline.plan295.life.swap.49c81e337f01',
                                ),
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
                              _lifeI18nText(
                                context,
                                'inline.plan295.life.swap.e65d1ed03269',
                              ),
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
            title: _isPhotoCategory
                ? _lifeI18nText(
                    context,
                    'inline.plan295.life.reference_sizes.28c01bd53f60',
                  )
                : _lifeI18nText(
                    context,
                    'inline.plan295.life.quick_results.c0cc60c70a24',
                  ),
            subtitle: _isPhotoCategory
                ? _lifeI18nText(
                    context,
                    'inline.plan295.life.see_inch_metric_and_pixel_references.2bb551f9b9d6',
                  )
                : _lifeI18nText(
                    context,
                    'inline.plan295.life.see_a_few_common_units_from_the_same.f52ca1227e2f',
                  ),
            children: <Widget>[
              if (_isPhotoCategory)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    ToolboxMetricCard(
                      label: _lifeI18nText(
                        context,
                        'inline.plan295.life.inch_alias.0aaa2c72e666',
                      ),
                      value: _formatPhotoPair(
                        _photoPreset.aliasInchWidth,
                        _photoPreset.aliasInchHeight,
                        'in',
                      ),
                    ),
                    ToolboxMetricCard(
                      label: _lifeI18nText(
                        context,
                        'inline.plan295.life.centimeter.a68ad2d8a79b',
                      ),
                      value: _formatPhotoPair(
                        _photoPreset.mmWidth / 10,
                        _photoPreset.mmHeight / 10,
                        'cm',
                      ),
                    ),
                    ToolboxMetricCard(
                      label: _lifeI18nText(
                        context,
                        'inline.plan295.life.millimeter.e2381e590a26',
                      ),
                      value: _formatPhotoPair(
                        _photoPreset.mmWidth,
                        _photoPreset.mmHeight,
                        'mm',
                      ),
                    ),
                    ToolboxMetricCard(
                      label: _lifeI18nText(
                        context,
                        'inline.plan295.life.pixel_size.a5584b17425b',
                      ),
                      value: _photoPixelPair(_photoPreset),
                    ),
                  ],
                )
              else if (quickUnits.isEmpty || sourceValue == null)
                Text(
                  _lifeI18nText(
                    context,
                    'inline.plan295.life.enter_a_number_and_this_area_will_sh.244f72c20d9e',
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
            title: _lifeI18nText(
              context,
              'inline.plan295.life.notes.e137c60482e9',
            ),
            children: <Widget>[
              Text(
                _isPhotoCategory
                    ? _lifeI18nText(
                        context,
                        'inline.plan295.life.chinese_id_photo_inch_names_are_comm.52ca6aaffe76',
                      )
                    : _isCssCategory
                    ? _lifeI18nText(
                        context,
                        'inline.plan295.life.in_css_rem_and_em_depend_on_font_siz.2baa3c5191b1',
                      )
                    : _lifeI18nText(
                        context,
                        'inline.plan295.life.all_conversions_run_locally_with_a_s.acd0d1faa44d',
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
              labelText: _lifeI18nText(
                context,
                'inline.plan295.life.unit.56e8aefdd46b',
              ),
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
              labelText: _lifeI18nText(
                context,
                'inline.plan295.life.value.0578b7f5768b',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
