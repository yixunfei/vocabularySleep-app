import 'dart:convert';
import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import 'daily_choice_models.dart';

const String dailyChoicePlaceMapSourceLabel = 'OpenStreetMap';
const String dailyChoicePlaceMapTileUrlTemplate =
    'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
final Uri dailyChoiceOverpassEndpoint = Uri(
  scheme: 'https',
  host: 'overpass-api.de',
  path: '/api/interpreter',
);

class DailyChoiceGeoPoint {
  const DailyChoiceGeoPoint({
    required this.latitude,
    required this.longitude,
    this.accuracyMeters,
  });

  final double latitude;
  final double longitude;
  final double? accuracyMeters;

  DailyChoiceGeoPoint fuzzed({int gridMeters = 500}) {
    if (gridMeters <= 0) {
      return this;
    }
    const metersPerLatitudeDegree = 111320.0;
    final latitudeGrid = gridMeters / metersPerLatitudeDegree;
    final latitudeRadians = latitude * math.pi / 180;
    final longitudeMetersPerDegree =
        metersPerLatitudeDegree *
        math.cos(latitudeRadians).abs().clamp(0.15, 1);
    final longitudeGrid = gridMeters / longitudeMetersPerDegree;
    return DailyChoiceGeoPoint(
      latitude: (latitude / latitudeGrid).roundToDouble() * latitudeGrid,
      longitude: (longitude / longitudeGrid).roundToDouble() * longitudeGrid,
      accuracyMeters: math.max(accuracyMeters ?? 0, gridMeters.toDouble()),
    );
  }
}

enum DailyChoiceLocationReadStatus {
  ready,
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  failed,
}

class DailyChoiceLocationReadResult {
  const DailyChoiceLocationReadResult({
    required this.status,
    this.point,
    this.message,
    this.usedApproximateLocation = true,
  });

  final DailyChoiceLocationReadStatus status;
  final DailyChoiceGeoPoint? point;
  final String? message;
  final bool usedApproximateLocation;

  bool get hasPoint =>
      status == DailyChoiceLocationReadStatus.ready && point != null;
}

abstract class DailyChoiceLocationProvider {
  Future<DailyChoiceLocationReadResult> readCurrentLocation({
    required bool useApproximateLocation,
  });
}

class DailyChoiceDeviceLocationProvider implements DailyChoiceLocationProvider {
  const DailyChoiceDeviceLocationProvider();

  @override
  Future<DailyChoiceLocationReadResult> readCurrentLocation({
    required bool useApproximateLocation,
  }) async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const DailyChoiceLocationReadResult(
          status: DailyChoiceLocationReadStatus.serviceDisabled,
          message: 'Location services are disabled.',
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        return const DailyChoiceLocationReadResult(
          status: DailyChoiceLocationReadStatus.permissionDenied,
          message: 'Location permission was denied.',
        );
      }
      if (permission == LocationPermission.deniedForever) {
        return const DailyChoiceLocationReadResult(
          status: DailyChoiceLocationReadStatus.permissionDeniedForever,
          message: 'Location permission is permanently denied.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: useApproximateLocation
              ? LocationAccuracy.low
              : LocationAccuracy.high,
          timeLimit: const Duration(seconds: 12),
        ),
      );
      final point = DailyChoiceGeoPoint(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracyMeters: position.accuracy,
      );
      return DailyChoiceLocationReadResult(
        status: DailyChoiceLocationReadStatus.ready,
        point: useApproximateLocation ? point.fuzzed() : point,
        usedApproximateLocation: useApproximateLocation,
      );
    } catch (error) {
      return DailyChoiceLocationReadResult(
        status: DailyChoiceLocationReadStatus.failed,
        message: '$error',
        usedApproximateLocation: useApproximateLocation,
      );
    }
  }
}

class DailyChoiceOsmPlace {
  const DailyChoiceOsmPlace({
    required this.id,
    required this.osmType,
    required this.osmId,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.distanceMeters,
    required this.categoryId,
    required this.sceneId,
    required this.kindZh,
    required this.kindEn,
    required this.tags,
  });

  final String id;
  final String osmType;
  final int osmId;
  final String name;
  final double latitude;
  final double longitude;
  final double distanceMeters;
  final String categoryId;
  final String sceneId;
  final String kindZh;
  final String kindEn;
  final Map<String, String> tags;

  String get osmUrl => 'https://www.openstreetmap.org/$osmType/$osmId';

  DailyChoiceOption toDailyChoiceOption() {
    final distanceLabelZh = dailyChoiceDistanceLabelZh(distanceMeters);
    final distanceLabelEn = dailyChoiceDistanceLabelEn(distanceMeters);
    final mapQuery = name.trim();
    return DailyChoiceOption(
      id: id,
      moduleId: DailyChoiceModuleId.go.storageValue,
      categoryId: categoryId,
      contextId: sceneId,
      contextIds: <String>[sceneId],
      titleZh: name,
      titleEn: name,
      subtitleZh: '来自周边地图 · $kindZh · 约 $distanceLabelZh',
      subtitleEn: 'From nearby map · $kindEn · about $distanceLabelEn',
      detailsZh:
          '这是你从 OpenStreetMap 周边结果保存的真实场所。App 不会收集你的定位，也不会把你的 GPS 写入这个条目；保存的只是这个公共场所本身、OSM 标识和便于再次查找的地图搜索词。',
      detailsEn:
          'This is a real place you saved from nearby OpenStreetMap results. The app does not collect your location or write your GPS position into this item; it only saves the public place, its OSM id, and a map search term.',
      materialsZh: <String>[
        '场所类型：$kindZh',
        '地图搜索词：$mapQuery',
        '距离参考：约 $distanceLabelZh（基于本次查询中心）',
        '数据来源：OpenStreetMap',
      ],
      materialsEn: <String>[
        'Place type: $kindEn',
        'Map query: $mapQuery',
        'Distance: about $distanceLabelEn from this query center',
        'Data source: OpenStreetMap',
      ],
      stepsZh: <String>[
        '出发前在地图 App 中重新搜索“$mapQuery”，确认营业时间、路线和当前开放状态。',
        '如果你使用了模糊位置，距离只作为粗略参考，请以地图导航结果为准。',
        '到达前准备一个同区域替代点，避免临时闭店或路线变化。',
      ],
      stepsEn: <String>[
        'Search "$mapQuery" again before leaving and confirm hours, route, and current availability.',
        'If approximate location was used, treat distance as a rough reference and rely on map navigation.',
        'Keep a same-area backup in case the place is closed or the route changes.',
      ],
      notesZh: <String>[
        '这个条目由你主动保存到本机场所清单。',
        'OSM 数据由社区维护，名称、分类和开放状态可能需要现场确认。',
        '保存后你可以在管理里继续编辑场景、备注和标签。',
      ],
      notesEn: <String>[
        'You explicitly saved this item into your local place list.',
        'OSM data is community-maintained, so names, categories, and availability may need confirmation.',
        'You can edit scene, notes, and tags later in Manage.',
      ],
      tagsZh: <String>[kindZh, '周边地图', 'OSM'],
      tagsEn: <String>[kindEn, 'Nearby map', 'OSM'],
      sourceLabel: dailyChoicePlaceMapSourceLabel,
      sourceUrl: osmUrl,
      references: <DailyChoiceReferenceLink>[
        DailyChoiceReferenceLink(
          labelZh: 'OpenStreetMap 条目',
          labelEn: 'OpenStreetMap item',
          url: osmUrl,
        ),
      ],
      attributes: <String, List<String>>{
        'source': <String>['openstreetmap'],
        'osm_type': <String>[osmType],
        'osm_id': <String>['$osmId'],
        'place_kind': <String>[kindEn],
        'map_query_zh': <String>[mapQuery],
        'map_query_en': <String>[mapQuery],
        'distance_band': <String>[
          dailyChoicePlaceDistanceCategoryForDistance(distanceMeters),
        ],
        'public_place_latitude': <String>[latitude.toStringAsFixed(6)],
        'public_place_longitude': <String>[longitude.toStringAsFixed(6)],
      },
      custom: true,
    );
  }
}

class DailyChoiceOsmQueryException implements Exception {
  const DailyChoiceOsmQueryException(this.message);

  final String message;

  @override
  String toString() => message;
}

class DailyChoiceOverpassClient {
  DailyChoiceOverpassClient({
    http.Client? httpClient,
    Uri? endpoint,
    String userAgent =
        'vocabulary_sleep_app/1.0 (Daily Choice place map; OpenStreetMap opt-in feature)',
  }) : _httpClient = httpClient ?? http.Client(),
       _ownsClient = httpClient == null,
       _endpoint = endpoint ?? dailyChoiceOverpassEndpoint,
       _userAgent = userAgent;

  final http.Client _httpClient;
  final bool _ownsClient;
  final Uri _endpoint;
  final String _userAgent;

  static const int maxRadiusMeters =
      DailyChoicePlaceMapSettings.maxRadiusMeters;
  static const int maxResultCount = 60;

  Future<List<DailyChoiceOsmPlace>> fetchNearbyPlaces({
    required DailyChoiceGeoPoint center,
    required int radiusMeters,
    int limit = maxResultCount,
  }) async {
    final normalizedRadius = radiusMeters.clamp(
      DailyChoicePlaceMapSettings.minRadiusMeters,
      maxRadiusMeters,
    );
    final normalizedLimit = limit.clamp(10, maxResultCount);
    final response = await _httpClient
        .post(
          _endpoint,
          headers: <String, String>{
            'Content-Type': 'application/x-www-form-urlencoded; charset=utf-8',
            'Accept': 'application/json',
            'User-Agent': _userAgent,
          },
          body: <String, String>{
            'data': buildNearbyPlaceQuery(
              center: center,
              radiusMeters: normalizedRadius.toInt(),
              limit: normalizedLimit.toInt(),
            ),
          },
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw DailyChoiceOsmQueryException(
        'OpenStreetMap nearby query failed (${response.statusCode}).',
      );
    }
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map || decoded['elements'] is! List) {
      throw const DailyChoiceOsmQueryException(
        'OpenStreetMap nearby query returned an unexpected response.',
      );
    }
    return parseOverpassElements(
      decoded['elements'] as List,
      center: center,
      limit: normalizedLimit.toInt(),
    );
  }

  void close() {
    if (_ownsClient) {
      _httpClient.close();
    }
  }

  static String buildNearbyPlaceQuery({
    required DailyChoiceGeoPoint center,
    required int radiusMeters,
    required int limit,
  }) {
    final lat = center.latitude.toStringAsFixed(6);
    final lon = center.longitude.toStringAsFixed(6);
    final radius = radiusMeters.clamp(
      DailyChoicePlaceMapSettings.minRadiusMeters,
      maxRadiusMeters,
    );
    final cappedLimit = limit.clamp(10, maxResultCount);
    return '''
[out:json][timeout:18];
(
  node(around:$radius,$lat,$lon)[~"^(amenity|tourism|leisure|shop|historic|natural|sport)\$"~"."];
  way(around:$radius,$lat,$lon)[~"^(amenity|tourism|leisure|shop|historic|natural|sport)\$"~"."];
  relation(around:$radius,$lat,$lon)[~"^(amenity|tourism|leisure|shop|historic|natural|sport)\$"~"."];
);
out center tags $cappedLimit;
''';
  }

  static List<DailyChoiceOsmPlace> parseOverpassElements(
    List elements, {
    required DailyChoiceGeoPoint center,
    int limit = maxResultCount,
  }) {
    final places = <DailyChoiceOsmPlace>[];
    final seen = <String>{};
    for (final raw in elements) {
      if (raw is! Map) {
        continue;
      }
      final type = '${raw['type'] ?? ''}'.trim();
      final osmId = int.tryParse('${raw['id'] ?? ''}');
      if (type.isEmpty || osmId == null) {
        continue;
      }
      final tags = _stringTagMap(raw['tags']);
      final name = _placeName(tags);
      if (name.isEmpty) {
        continue;
      }
      final point = _elementPoint(raw);
      if (point == null) {
        continue;
      }
      final key = '$type/$osmId';
      if (!seen.add(key)) {
        continue;
      }
      final distance = dailyChoiceDistanceMeters(
        center.latitude,
        center.longitude,
        point.latitude,
        point.longitude,
      );
      final kind = _placeKind(tags);
      places.add(
        DailyChoiceOsmPlace(
          id: 'go_osm_${type}_$osmId',
          osmType: type,
          osmId: osmId,
          name: name,
          latitude: point.latitude,
          longitude: point.longitude,
          distanceMeters: distance,
          categoryId: dailyChoicePlaceDistanceCategoryForDistance(distance),
          sceneId: kind.sceneId,
          kindZh: kind.titleZh,
          kindEn: kind.titleEn,
          tags: tags,
        ),
      );
    }
    places.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
    return places.take(limit).toList(growable: false);
  }
}

double dailyChoiceDistanceMeters(
  double lat1,
  double lon1,
  double lat2,
  double lon2,
) {
  const earthRadiusMeters = 6371000.0;
  final phi1 = lat1 * math.pi / 180;
  final phi2 = lat2 * math.pi / 180;
  final deltaPhi = (lat2 - lat1) * math.pi / 180;
  final deltaLambda = (lon2 - lon1) * math.pi / 180;
  final a =
      math.sin(deltaPhi / 2) * math.sin(deltaPhi / 2) +
      math.cos(phi1) *
          math.cos(phi2) *
          math.sin(deltaLambda / 2) *
          math.sin(deltaLambda / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return earthRadiusMeters * c;
}

String dailyChoicePlaceDistanceCategoryForDistance(double distanceMeters) {
  if (distanceMeters <= 1800) {
    return 'outside';
  }
  if (distanceMeters <= 12000) {
    return 'nearby';
  }
  return 'travel';
}

String dailyChoiceDistanceLabelZh(double distanceMeters) {
  if (distanceMeters < 1000) {
    return '${distanceMeters.round()} 米';
  }
  return '${(distanceMeters / 1000).toStringAsFixed(1)} 公里';
}

String dailyChoiceDistanceLabelEn(double distanceMeters) {
  if (distanceMeters < 1000) {
    return '${distanceMeters.round()} m';
  }
  return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
}

Map<String, String> _stringTagMap(Object? raw) {
  if (raw is! Map) {
    return const <String, String>{};
  }
  final result = <String, String>{};
  for (final entry in raw.entries) {
    final key = '${entry.key}'.trim();
    final value = '${entry.value}'.trim();
    if (key.isNotEmpty && value.isNotEmpty) {
      result[key] = value;
    }
  }
  return result;
}

String _placeName(Map<String, String> tags) {
  for (final key in <String>[
    'name:zh-Hans',
    'name:zh',
    'name',
    'official_name',
    'brand',
    'operator',
  ]) {
    final value = tags[key]?.trim();
    if (value != null && value.isNotEmpty) {
      return value;
    }
  }
  return '';
}

DailyChoiceGeoPoint? _elementPoint(Map raw) {
  final lat = _doubleValue(raw['lat']);
  final lon = _doubleValue(raw['lon']);
  if (lat != null && lon != null) {
    return DailyChoiceGeoPoint(latitude: lat, longitude: lon);
  }
  final center = raw['center'];
  if (center is Map) {
    final centerLat = _doubleValue(center['lat']);
    final centerLon = _doubleValue(center['lon']);
    if (centerLat != null && centerLon != null) {
      return DailyChoiceGeoPoint(latitude: centerLat, longitude: centerLon);
    }
  }
  return null;
}

double? _doubleValue(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse('${value ?? ''}');
}

class _ResolvedOsmKind {
  const _ResolvedOsmKind({
    required this.sceneId,
    required this.titleZh,
    required this.titleEn,
  });

  final String sceneId;
  final String titleZh;
  final String titleEn;
}

_ResolvedOsmKind _placeKind(Map<String, String> tags) {
  final amenity = tags['amenity'];
  final tourism = tags['tourism'];
  final leisure = tags['leisure'];
  final shop = tags['shop'];
  final historic = tags['historic'];
  final natural = tags['natural'];
  final sport = tags['sport'];

  if (amenity != null) {
    if (<String>{
      'restaurant',
      'cafe',
      'fast_food',
      'food_court',
      'ice_cream',
    }.contains(amenity)) {
      return const _ResolvedOsmKind(
        sceneId: 'food',
        titleZh: '餐饮',
        titleEn: 'Food',
      );
    }
    if (<String>{'bar', 'pub', 'biergarten', 'nightclub'}.contains(amenity)) {
      return const _ResolvedOsmKind(
        sceneId: 'nightlife',
        titleZh: '夜间',
        titleEn: 'Nightlife',
      );
    }
    if (<String>{
      'library',
      'college',
      'university',
      'school',
    }.contains(amenity)) {
      return const _ResolvedOsmKind(
        sceneId: 'study',
        titleZh: '学习',
        titleEn: 'Study',
      );
    }
    if (<String>{'cinema', 'theatre', 'arts_centre'}.contains(amenity)) {
      return const _ResolvedOsmKind(
        sceneId: 'culture',
        titleZh: '文化',
        titleEn: 'Culture',
      );
    }
    if (<String>{'community_centre', 'events_venue'}.contains(amenity)) {
      return const _ResolvedOsmKind(
        sceneId: 'social',
        titleZh: '社交',
        titleEn: 'Social',
      );
    }
  }

  if (tourism != null) {
    if (<String>{'museum', 'gallery', 'artwork'}.contains(tourism)) {
      return const _ResolvedOsmKind(
        sceneId: 'culture',
        titleZh: '文化',
        titleEn: 'Culture',
      );
    }
    if (<String>{'zoo', 'viewpoint', 'attraction'}.contains(tourism)) {
      return const _ResolvedOsmKind(
        sceneId: 'photo',
        titleZh: '出片',
        titleEn: 'Photo',
      );
    }
    return const _ResolvedOsmKind(
      sceneId: 'specialty',
      titleZh: '特色区域',
      titleEn: 'Special area',
    );
  }

  if (leisure != null) {
    if (<String>{'park', 'garden', 'nature_reserve'}.contains(leisure)) {
      return const _ResolvedOsmKind(
        sceneId: 'nature',
        titleZh: '自然',
        titleEn: 'Nature',
      );
    }
    if (<String>{
      'sports_centre',
      'fitness_centre',
      'swimming_pool',
      'stadium',
      'pitch',
    }.contains(leisure)) {
      return const _ResolvedOsmKind(
        sceneId: 'sports',
        titleZh: '运动',
        titleEn: 'Sports',
      );
    }
    return const _ResolvedOsmKind(
      sceneId: 'entertainment',
      titleZh: '娱乐',
      titleEn: 'Entertainment',
    );
  }

  if (shop != null) {
    return const _ResolvedOsmKind(
      sceneId: 'shopping',
      titleZh: '购物',
      titleEn: 'Shopping',
    );
  }
  if (historic != null) {
    return const _ResolvedOsmKind(
      sceneId: 'history',
      titleZh: '历史',
      titleEn: 'History',
    );
  }
  if (natural != null) {
    return const _ResolvedOsmKind(
      sceneId: 'nature',
      titleZh: '自然',
      titleEn: 'Nature',
    );
  }
  if (sport != null) {
    return const _ResolvedOsmKind(
      sceneId: 'sports',
      titleZh: '运动',
      titleEn: 'Sports',
    );
  }
  return const _ResolvedOsmKind(
    sceneId: 'specialty',
    titleZh: '特色区域',
    titleEn: 'Special area',
  );
}
