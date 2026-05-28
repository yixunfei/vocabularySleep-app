enum ToolboxWorldClockDstRule {
  none,
  northAmerica,
  europe,
  australiaEastern,
  newZealand,
}

enum ToolboxWorldClockPeriod {
  businessHours,
  earlyMorning,
  evening,
  night,
  weekend,
}

class ToolboxWorldClockCity {
  const ToolboxWorldClockCity({
    required this.id,
    required this.cityZh,
    required this.cityEn,
    required this.countryZh,
    required this.countryEn,
    required this.regionZh,
    required this.regionEn,
    required this.standardOffsetMinutes,
    this.dstRule = ToolboxWorldClockDstRule.none,
    this.defaultPinned = false,
    this.searchTags = const <String>[],
  });

  final String id;
  final String cityZh;
  final String cityEn;
  final String countryZh;
  final String countryEn;
  final String regionZh;
  final String regionEn;
  final int standardOffsetMinutes;
  final ToolboxWorldClockDstRule dstRule;
  final bool defaultPinned;
  final List<String> searchTags;

  String cityLabel(String languageCode) {
    return languageCode == 'zh' ? cityZh : cityEn;
  }

  String countryLabel(String languageCode) {
    return languageCode == 'zh' ? countryZh : countryEn;
  }

  String regionLabel(String languageCode) {
    return languageCode == 'zh' ? regionZh : regionEn;
  }

  bool matches(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return true;
    }
    final haystack = <String>[
      id,
      cityZh,
      cityEn,
      countryZh,
      countryEn,
      regionZh,
      regionEn,
      ...searchTags,
    ].join(' ').toLowerCase();
    return haystack.contains(normalized);
  }
}

class ToolboxWorldClockSnapshot {
  const ToolboxWorldClockSnapshot({
    required this.city,
    required this.utcNow,
    required this.localTime,
    required this.deviceLocalTime,
    required this.offsetMinutes,
    required this.deviceOffsetMinutes,
    required this.differenceFromDeviceMinutes,
    required this.isDst,
    required this.isBusinessHours,
    required this.period,
    required this.dayShift,
  });

  final ToolboxWorldClockCity city;
  final DateTime utcNow;
  final DateTime localTime;
  final DateTime deviceLocalTime;
  final int offsetMinutes;
  final int deviceOffsetMinutes;
  final int differenceFromDeviceMinutes;
  final bool isDst;
  final bool isBusinessHours;
  final ToolboxWorldClockPeriod period;
  final int dayShift;

  String get offsetLabel =>
      ToolboxWorldClockService.formatOffset(offsetMinutes);
}

class ToolboxWorldClockService {
  const ToolboxWorldClockService();

  static const List<ToolboxWorldClockCity> cities = <ToolboxWorldClockCity>[
    ToolboxWorldClockCity(
      id: 'utc',
      cityZh: '协调世界时',
      cityEn: 'UTC',
      countryZh: '标准时间',
      countryEn: 'Reference time',
      regionZh: '全球',
      regionEn: 'Global',
      standardOffsetMinutes: 0,
      defaultPinned: true,
      searchTags: <String>['gmt', 'zulu'],
    ),
    ToolboxWorldClockCity(
      id: 'beijing',
      cityZh: '北京',
      cityEn: 'Beijing',
      countryZh: '中国',
      countryEn: 'China',
      regionZh: '东亚',
      regionEn: 'East Asia',
      standardOffsetMinutes: 480,
      defaultPinned: true,
      searchTags: <String>['china', 'cn', 'pek', 'bj'],
    ),
    ToolboxWorldClockCity(
      id: 'shanghai',
      cityZh: '上海',
      cityEn: 'Shanghai',
      countryZh: '中国',
      countryEn: 'China',
      regionZh: '东亚',
      regionEn: 'East Asia',
      standardOffsetMinutes: 480,
      searchTags: <String>['china', 'cn', 'sha'],
    ),
    ToolboxWorldClockCity(
      id: 'hong_kong',
      cityZh: '香港',
      cityEn: 'Hong Kong',
      countryZh: '中国',
      countryEn: 'China',
      regionZh: '东亚',
      regionEn: 'East Asia',
      standardOffsetMinutes: 480,
      searchTags: <String>['hk', 'china'],
    ),
    ToolboxWorldClockCity(
      id: 'taipei',
      cityZh: '台北',
      cityEn: 'Taipei',
      countryZh: '中国',
      countryEn: 'China',
      regionZh: '东亚',
      regionEn: 'East Asia',
      standardOffsetMinutes: 480,
      searchTags: <String>['taiwan', 'tpe'],
    ),
    ToolboxWorldClockCity(
      id: 'tokyo',
      cityZh: '东京',
      cityEn: 'Tokyo',
      countryZh: '日本',
      countryEn: 'Japan',
      regionZh: '东亚',
      regionEn: 'East Asia',
      standardOffsetMinutes: 540,
      defaultPinned: true,
      searchTags: <String>['japan', 'jp', 'tyo'],
    ),
    ToolboxWorldClockCity(
      id: 'seoul',
      cityZh: '首尔',
      cityEn: 'Seoul',
      countryZh: '韩国',
      countryEn: 'South Korea',
      regionZh: '东亚',
      regionEn: 'East Asia',
      standardOffsetMinutes: 540,
      searchTags: <String>['korea', 'kr', 'sel'],
    ),
    ToolboxWorldClockCity(
      id: 'singapore',
      cityZh: '新加坡',
      cityEn: 'Singapore',
      countryZh: '新加坡',
      countryEn: 'Singapore',
      regionZh: '东南亚',
      regionEn: 'Southeast Asia',
      standardOffsetMinutes: 480,
      searchTags: <String>['sg', 'sin'],
    ),
    ToolboxWorldClockCity(
      id: 'bangkok',
      cityZh: '曼谷',
      cityEn: 'Bangkok',
      countryZh: '泰国',
      countryEn: 'Thailand',
      regionZh: '东南亚',
      regionEn: 'Southeast Asia',
      standardOffsetMinutes: 420,
      searchTags: <String>['thailand', 'bkk'],
    ),
    ToolboxWorldClockCity(
      id: 'dubai',
      cityZh: '迪拜',
      cityEn: 'Dubai',
      countryZh: '阿联酋',
      countryEn: 'United Arab Emirates',
      regionZh: '西亚',
      regionEn: 'West Asia',
      standardOffsetMinutes: 240,
      searchTags: <String>['uae', 'dxb'],
    ),
    ToolboxWorldClockCity(
      id: 'mumbai',
      cityZh: '孟买',
      cityEn: 'Mumbai',
      countryZh: '印度',
      countryEn: 'India',
      regionZh: '南亚',
      regionEn: 'South Asia',
      standardOffsetMinutes: 330,
      searchTags: <String>['india', 'ist', 'bom'],
    ),
    ToolboxWorldClockCity(
      id: 'moscow',
      cityZh: '莫斯科',
      cityEn: 'Moscow',
      countryZh: '俄罗斯',
      countryEn: 'Russia',
      regionZh: '欧洲',
      regionEn: 'Europe',
      standardOffsetMinutes: 180,
      searchTags: <String>['russia', 'msk'],
    ),
    ToolboxWorldClockCity(
      id: 'istanbul',
      cityZh: '伊斯坦布尔',
      cityEn: 'Istanbul',
      countryZh: '土耳其',
      countryEn: 'Turkiye',
      regionZh: '欧洲',
      regionEn: 'Europe',
      standardOffsetMinutes: 180,
      searchTags: <String>['turkey', 'turkiye'],
    ),
    ToolboxWorldClockCity(
      id: 'london',
      cityZh: '伦敦',
      cityEn: 'London',
      countryZh: '英国',
      countryEn: 'United Kingdom',
      regionZh: '欧洲',
      regionEn: 'Europe',
      standardOffsetMinutes: 0,
      dstRule: ToolboxWorldClockDstRule.europe,
      defaultPinned: true,
      searchTags: <String>['uk', 'gb', 'gmt', 'bst'],
    ),
    ToolboxWorldClockCity(
      id: 'paris',
      cityZh: '巴黎',
      cityEn: 'Paris',
      countryZh: '法国',
      countryEn: 'France',
      regionZh: '欧洲',
      regionEn: 'Europe',
      standardOffsetMinutes: 60,
      dstRule: ToolboxWorldClockDstRule.europe,
      searchTags: <String>['france', 'cet', 'cest'],
    ),
    ToolboxWorldClockCity(
      id: 'berlin',
      cityZh: '柏林',
      cityEn: 'Berlin',
      countryZh: '德国',
      countryEn: 'Germany',
      regionZh: '欧洲',
      regionEn: 'Europe',
      standardOffsetMinutes: 60,
      dstRule: ToolboxWorldClockDstRule.europe,
      searchTags: <String>['germany', 'cet', 'cest'],
    ),
    ToolboxWorldClockCity(
      id: 'rome',
      cityZh: '罗马',
      cityEn: 'Rome',
      countryZh: '意大利',
      countryEn: 'Italy',
      regionZh: '欧洲',
      regionEn: 'Europe',
      standardOffsetMinutes: 60,
      dstRule: ToolboxWorldClockDstRule.europe,
      searchTags: <String>['italy', 'cet', 'cest'],
    ),
    ToolboxWorldClockCity(
      id: 'madrid',
      cityZh: '马德里',
      cityEn: 'Madrid',
      countryZh: '西班牙',
      countryEn: 'Spain',
      regionZh: '欧洲',
      regionEn: 'Europe',
      standardOffsetMinutes: 60,
      dstRule: ToolboxWorldClockDstRule.europe,
      searchTags: <String>['spain', 'cet', 'cest'],
    ),
    ToolboxWorldClockCity(
      id: 'johannesburg',
      cityZh: '约翰内斯堡',
      cityEn: 'Johannesburg',
      countryZh: '南非',
      countryEn: 'South Africa',
      regionZh: '非洲',
      regionEn: 'Africa',
      standardOffsetMinutes: 120,
      searchTags: <String>['south africa', 'joburg'],
    ),
    ToolboxWorldClockCity(
      id: 'nairobi',
      cityZh: '内罗毕',
      cityEn: 'Nairobi',
      countryZh: '肯尼亚',
      countryEn: 'Kenya',
      regionZh: '非洲',
      regionEn: 'Africa',
      standardOffsetMinutes: 180,
      searchTags: <String>['kenya'],
    ),
    ToolboxWorldClockCity(
      id: 'new_york',
      cityZh: '纽约',
      cityEn: 'New York',
      countryZh: '美国',
      countryEn: 'United States',
      regionZh: '北美',
      regionEn: 'North America',
      standardOffsetMinutes: -300,
      dstRule: ToolboxWorldClockDstRule.northAmerica,
      defaultPinned: true,
      searchTags: <String>['usa', 'us', 'nyc', 'eastern'],
    ),
    ToolboxWorldClockCity(
      id: 'toronto',
      cityZh: '多伦多',
      cityEn: 'Toronto',
      countryZh: '加拿大',
      countryEn: 'Canada',
      regionZh: '北美',
      regionEn: 'North America',
      standardOffsetMinutes: -300,
      dstRule: ToolboxWorldClockDstRule.northAmerica,
      searchTags: <String>['canada', 'eastern'],
    ),
    ToolboxWorldClockCity(
      id: 'chicago',
      cityZh: '芝加哥',
      cityEn: 'Chicago',
      countryZh: '美国',
      countryEn: 'United States',
      regionZh: '北美',
      regionEn: 'North America',
      standardOffsetMinutes: -360,
      dstRule: ToolboxWorldClockDstRule.northAmerica,
      searchTags: <String>['usa', 'us', 'central'],
    ),
    ToolboxWorldClockCity(
      id: 'denver',
      cityZh: '丹佛',
      cityEn: 'Denver',
      countryZh: '美国',
      countryEn: 'United States',
      regionZh: '北美',
      regionEn: 'North America',
      standardOffsetMinutes: -420,
      dstRule: ToolboxWorldClockDstRule.northAmerica,
      searchTags: <String>['usa', 'us', 'mountain'],
    ),
    ToolboxWorldClockCity(
      id: 'los_angeles',
      cityZh: '洛杉矶',
      cityEn: 'Los Angeles',
      countryZh: '美国',
      countryEn: 'United States',
      regionZh: '北美',
      regionEn: 'North America',
      standardOffsetMinutes: -480,
      dstRule: ToolboxWorldClockDstRule.northAmerica,
      defaultPinned: true,
      searchTags: <String>['usa', 'us', 'la', 'pacific'],
    ),
    ToolboxWorldClockCity(
      id: 'san_francisco',
      cityZh: '旧金山',
      cityEn: 'San Francisco',
      countryZh: '美国',
      countryEn: 'United States',
      regionZh: '北美',
      regionEn: 'North America',
      standardOffsetMinutes: -480,
      dstRule: ToolboxWorldClockDstRule.northAmerica,
      searchTags: <String>['usa', 'us', 'sf', 'pacific'],
    ),
    ToolboxWorldClockCity(
      id: 'honolulu',
      cityZh: '檀香山',
      cityEn: 'Honolulu',
      countryZh: '美国',
      countryEn: 'United States',
      regionZh: '太平洋',
      regionEn: 'Pacific',
      standardOffsetMinutes: -600,
      searchTags: <String>['hawaii', 'usa', 'hst'],
    ),
    ToolboxWorldClockCity(
      id: 'sao_paulo',
      cityZh: '圣保罗',
      cityEn: 'Sao Paulo',
      countryZh: '巴西',
      countryEn: 'Brazil',
      regionZh: '南美',
      regionEn: 'South America',
      standardOffsetMinutes: -180,
      searchTags: <String>['brazil', 'brasil'],
    ),
    ToolboxWorldClockCity(
      id: 'buenos_aires',
      cityZh: '布宜诺斯艾利斯',
      cityEn: 'Buenos Aires',
      countryZh: '阿根廷',
      countryEn: 'Argentina',
      regionZh: '南美',
      regionEn: 'South America',
      standardOffsetMinutes: -180,
      searchTags: <String>['argentina'],
    ),
    ToolboxWorldClockCity(
      id: 'sydney',
      cityZh: '悉尼',
      cityEn: 'Sydney',
      countryZh: '澳大利亚',
      countryEn: 'Australia',
      regionZh: '大洋洲',
      regionEn: 'Oceania',
      standardOffsetMinutes: 600,
      dstRule: ToolboxWorldClockDstRule.australiaEastern,
      defaultPinned: true,
      searchTags: <String>['australia', 'nsw', 'aest', 'aedt'],
    ),
    ToolboxWorldClockCity(
      id: 'melbourne',
      cityZh: '墨尔本',
      cityEn: 'Melbourne',
      countryZh: '澳大利亚',
      countryEn: 'Australia',
      regionZh: '大洋洲',
      regionEn: 'Oceania',
      standardOffsetMinutes: 600,
      dstRule: ToolboxWorldClockDstRule.australiaEastern,
      searchTags: <String>['australia', 'victoria', 'aest', 'aedt'],
    ),
    ToolboxWorldClockCity(
      id: 'brisbane',
      cityZh: '布里斯班',
      cityEn: 'Brisbane',
      countryZh: '澳大利亚',
      countryEn: 'Australia',
      regionZh: '大洋洲',
      regionEn: 'Oceania',
      standardOffsetMinutes: 600,
      searchTags: <String>['australia', 'queensland', 'aest'],
    ),
    ToolboxWorldClockCity(
      id: 'perth',
      cityZh: '珀斯',
      cityEn: 'Perth',
      countryZh: '澳大利亚',
      countryEn: 'Australia',
      regionZh: '大洋洲',
      regionEn: 'Oceania',
      standardOffsetMinutes: 480,
      searchTags: <String>['australia', 'western australia', 'awst'],
    ),
    ToolboxWorldClockCity(
      id: 'auckland',
      cityZh: '奥克兰',
      cityEn: 'Auckland',
      countryZh: '新西兰',
      countryEn: 'New Zealand',
      regionZh: '大洋洲',
      regionEn: 'Oceania',
      standardOffsetMinutes: 720,
      dstRule: ToolboxWorldClockDstRule.newZealand,
      defaultPinned: true,
      searchTags: <String>['new zealand', 'nz', 'nzst', 'nzdt'],
    ),
  ];

  List<ToolboxWorldClockCity> searchCities(
    String query, {
    DateTime? utcNow,
    bool businessHoursOnly = false,
  }) {
    final now = utcNow ?? DateTime.now().toUtc();
    return cities
        .where((city) {
          if (!city.matches(query)) {
            return false;
          }
          if (!businessHoursOnly) {
            return true;
          }
          return snapshotForCity(city, utcNow: now).isBusinessHours;
        })
        .toList(growable: false);
  }

  ToolboxWorldClockCity cityById(String id) {
    return cities.firstWhere(
      (city) => city.id == id,
      orElse: () => cities.first,
    );
  }

  List<ToolboxWorldClockCity> defaultPinnedCities() {
    return cities.where((city) => city.defaultPinned).toList(growable: false);
  }

  ToolboxWorldClockSnapshot snapshotForCity(
    ToolboxWorldClockCity city, {
    DateTime? utcNow,
    int? deviceOffsetMinutes,
  }) {
    final normalizedUtc = (utcNow ?? DateTime.now().toUtc()).toUtc();
    final deviceOffset =
        deviceOffsetMinutes ?? DateTime.now().timeZoneOffset.inMinutes;
    final effectiveOffset = effectiveOffsetMinutes(city, normalizedUtc);
    final cityLocal = normalizedUtc.add(Duration(minutes: effectiveOffset));
    final deviceLocal = normalizedUtc.add(Duration(minutes: deviceOffset));
    final period = periodFor(cityLocal);
    return ToolboxWorldClockSnapshot(
      city: city,
      utcNow: normalizedUtc,
      localTime: cityLocal,
      deviceLocalTime: deviceLocal,
      offsetMinutes: effectiveOffset,
      deviceOffsetMinutes: deviceOffset,
      differenceFromDeviceMinutes: effectiveOffset - deviceOffset,
      isDst: isDstActive(city, normalizedUtc),
      isBusinessHours: period == ToolboxWorldClockPeriod.businessHours,
      period: period,
      dayShift: _dayShift(cityLocal, deviceLocal),
    );
  }

  int effectiveOffsetMinutes(ToolboxWorldClockCity city, DateTime utcNow) {
    return city.standardOffsetMinutes + (isDstActive(city, utcNow) ? 60 : 0);
  }

  bool isDstActive(ToolboxWorldClockCity city, DateTime utcNow) {
    final normalizedUtc = utcNow.toUtc();
    return switch (city.dstRule) {
      ToolboxWorldClockDstRule.none => false,
      ToolboxWorldClockDstRule.europe => _isBetween(
        normalizedUtc,
        DateTime.utc(
          normalizedUtc.year,
          3,
          _lastWeekdayInMonth(normalizedUtc.year, 3, DateTime.sunday),
          1,
        ),
        DateTime.utc(
          normalizedUtc.year,
          10,
          _lastWeekdayInMonth(normalizedUtc.year, 10, DateTime.sunday),
          1,
        ),
      ),
      ToolboxWorldClockDstRule.northAmerica => _isBetween(
        normalizedUtc,
        _transitionUtc(
          normalizedUtc.year,
          3,
          _nthWeekdayInMonth(normalizedUtc.year, 3, DateTime.sunday, 2),
          2,
          city.standardOffsetMinutes,
        ),
        _transitionUtc(
          normalizedUtc.year,
          11,
          _nthWeekdayInMonth(normalizedUtc.year, 11, DateTime.sunday, 1),
          2,
          city.standardOffsetMinutes + 60,
        ),
      ),
      ToolboxWorldClockDstRule.australiaEastern => _isSouthernDstActive(
        normalizedUtc,
        start: _transitionUtc(
          normalizedUtc.year,
          10,
          _nthWeekdayInMonth(normalizedUtc.year, 10, DateTime.sunday, 1),
          2,
          city.standardOffsetMinutes,
        ),
        end: _transitionUtc(
          normalizedUtc.year,
          4,
          _nthWeekdayInMonth(normalizedUtc.year, 4, DateTime.sunday, 1),
          3,
          city.standardOffsetMinutes + 60,
        ),
      ),
      ToolboxWorldClockDstRule.newZealand => _isSouthernDstActive(
        normalizedUtc,
        start: _transitionUtc(
          normalizedUtc.year,
          9,
          _lastWeekdayInMonth(normalizedUtc.year, 9, DateTime.sunday),
          2,
          city.standardOffsetMinutes,
        ),
        end: _transitionUtc(
          normalizedUtc.year,
          4,
          _nthWeekdayInMonth(normalizedUtc.year, 4, DateTime.sunday, 1),
          3,
          city.standardOffsetMinutes + 60,
        ),
      ),
    };
  }

  static ToolboxWorldClockPeriod periodFor(DateTime localTime) {
    if (localTime.weekday == DateTime.saturday ||
        localTime.weekday == DateTime.sunday) {
      return ToolboxWorldClockPeriod.weekend;
    }
    if (localTime.hour >= 9 && localTime.hour < 18) {
      return ToolboxWorldClockPeriod.businessHours;
    }
    if (localTime.hour >= 5 && localTime.hour < 9) {
      return ToolboxWorldClockPeriod.earlyMorning;
    }
    if (localTime.hour >= 18 && localTime.hour < 22) {
      return ToolboxWorldClockPeriod.evening;
    }
    return ToolboxWorldClockPeriod.night;
  }

  static String formatOffset(int minutes) {
    final sign = minutes >= 0 ? '+' : '-';
    final absMinutes = minutes.abs();
    final hours = (absMinutes ~/ 60).toString().padLeft(2, '0');
    final mins = (absMinutes % 60).toString().padLeft(2, '0');
    return 'UTC$sign$hours:$mins';
  }

  static String formatTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static String formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  static bool _isBetween(DateTime value, DateTime start, DateTime end) {
    return !value.isBefore(start) && value.isBefore(end);
  }

  static bool _isSouthernDstActive(
    DateTime value, {
    required DateTime start,
    required DateTime end,
  }) {
    return !value.isBefore(start) || value.isBefore(end);
  }

  static DateTime _transitionUtc(
    int year,
    int month,
    int day,
    int localHour,
    int offsetBeforeMinutes,
  ) {
    return DateTime.utc(
      year,
      month,
      day,
      localHour,
    ).subtract(Duration(minutes: offsetBeforeMinutes));
  }

  static int _dayShift(DateTime cityLocal, DateTime deviceLocal) {
    final cityDate = DateTime.utc(
      cityLocal.year,
      cityLocal.month,
      cityLocal.day,
    );
    final deviceDate = DateTime.utc(
      deviceLocal.year,
      deviceLocal.month,
      deviceLocal.day,
    );
    return cityDate.difference(deviceDate).inDays;
  }

  static int _nthWeekdayInMonth(int year, int month, int weekday, int nth) {
    final first = DateTime.utc(year, month);
    final offset = (weekday - first.weekday + 7) % 7;
    return 1 + offset + (nth - 1) * 7;
  }

  static int _lastWeekdayInMonth(int year, int month, int weekday) {
    final last = DateTime.utc(year, month + 1, 0);
    final offset = (last.weekday - weekday + 7) % 7;
    return last.day - offset;
  }
}
