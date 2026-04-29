import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'daily_choice_models.dart';

const String dailyChoicePlaceMapSourceLabel = 'OpenStreetMap';
const String dailyChoicePlaceMapUserAgentPackageName = 'group.zn.xianyushengxi';
const int dailyChoicePlaceMapTileCacheMaxBytes = 160 * 1024 * 1024;
const Duration dailyChoicePlaceMapTileFreshAge = Duration(days: 7);
const String dailyChoicePlaceMapTileUrlTemplate =
    'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png';
final Uri dailyChoiceOverpassEndpoint = Uri(
  scheme: 'https',
  host: 'overpass-api.de',
  path: '/api/interpreter',
);
final Uri dailyChoiceIpCoarseLocationEndpoint = Uri(
  scheme: 'https',
  host: 'ipinfo.io',
  path: '/json',
);

class DailyChoiceMapTileProviderSpec {
  const DailyChoiceMapTileProviderSpec({
    required this.id,
    required this.titleZh,
    required this.titleEn,
    required this.descriptionZh,
    required this.descriptionEn,
    required this.urlTemplate,
    required this.attribution,
    this.subdomains = const <String>[],
    this.minZoom = 3,
    this.maxZoom = 19,
    this.usesOsmPublicTileServer = false,
    this.requiresConservativeUse = false,
  });

  final String id;
  final String titleZh;
  final String titleEn;
  final String descriptionZh;
  final String descriptionEn;
  final String urlTemplate;
  final String attribution;
  final List<String> subdomains;
  final double minZoom;
  final double maxZoom;
  final bool usesOsmPublicTileServer;
  final bool requiresConservativeUse;
}

const List<DailyChoiceMapTileProviderSpec>
dailyChoicePlaceMapTileProviders = <DailyChoiceMapTileProviderSpec>[
  DailyChoiceMapTileProviderSpec(
    id: DailyChoicePlaceMapSettings.defaultTileProviderId,
    titleZh: 'OSM HOT',
    titleEn: 'OSM HOT',
    descriptionZh: '默认地图源，使用 OSM 人道主义样式；地名和道路层级更醒目，适合作为受限网络下的优先尝试源。',
    descriptionEn:
        'Default tile source using the OSM humanitarian style, with more visible labels and road hierarchy for restricted networks.',
    urlTemplate: dailyChoicePlaceMapTileUrlTemplate,
    attribution: 'OpenStreetMap contributors, HOT, OpenStreetMap France',
    subdomains: <String>['a', 'b', 'c'],
    requiresConservativeUse: true,
  ),
  DailyChoiceMapTileProviderSpec(
    id: 'osm_france_fallback',
    titleZh: 'OSM France',
    titleEn: 'OSM France',
    descriptionZh: 'OSM France 社区瓦片；作为备用源保留，通常需要可访问国际网络的环境。',
    descriptionEn:
        'OSM France community tiles kept as a fallback; usually requires access to the international network.',
    urlTemplate: 'https://{s}.tile.openstreetmap.fr/osmfr/{z}/{x}/{y}.png',
    attribution: 'OpenStreetMap contributors, OpenStreetMap France',
    subdomains: <String>['a', 'b', 'c'],
    requiresConservativeUse: true,
  ),
  DailyChoiceMapTileProviderSpec(
    id: 'osm_de',
    titleZh: 'OpenStreetMap.de',
    titleEn: 'OpenStreetMap.de',
    descriptionZh: '德国 OSM 社区样式；通常需要可访问国际网络的环境，默认源不稳定时可手动切换。',
    descriptionEn:
        'German OSM community style; usually requires access to the international network and can be selected when the default source is unstable.',
    urlTemplate: 'https://tile.openstreetmap.de/{z}/{x}/{y}.png',
    attribution: 'OpenStreetMap contributors, OpenStreetMap.de',
    requiresConservativeUse: true,
  ),
  DailyChoiceMapTileProviderSpec(
    id: 'osm_standard',
    titleZh: 'OSM Standard',
    titleEn: 'OSM Standard',
    descriptionZh: 'OpenStreetMap 官方标准瓦片；通常需要可访问国际网络的环境，仅在需要核对标准样式时手动切换。',
    descriptionEn:
        'Official OpenStreetMap standard tiles; usually requires access to the international network and should be selected only when the standard style is needed.',
    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    attribution: 'OpenStreetMap contributors',
    maxZoom: 19,
    usesOsmPublicTileServer: true,
    requiresConservativeUse: true,
  ),
  DailyChoiceMapTileProviderSpec(
    id: 'carto_voyager_fallback',
    titleZh: 'CARTO Voyager',
    titleEn: 'CARTO Voyager',
    descriptionZh: 'CARTO 真实街区样式；通常需要可访问国际网络的环境，在部分地区可能不可用。',
    descriptionEn:
        'CARTO street basemap that usually requires access to the international network and may be unavailable in some regions.',
    urlTemplate:
        'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
    attribution: 'OpenStreetMap contributors, CARTO',
    subdomains: <String>['a', 'b', 'c', 'd'],
    maxZoom: 20,
  ),
  DailyChoiceMapTileProviderSpec(
    id: 'carto_light',
    titleZh: 'CARTO Light',
    titleEn: 'CARTO Light',
    descriptionZh: '更克制的浅色底图，适合降低视觉噪声；通常需要可访问国际网络的环境，作为非默认备用源保留。',
    descriptionEn:
        'A quieter light basemap that keeps dense place markers easier to scan; usually requires access to the international network.',
    urlTemplate:
        'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
    attribution: 'OpenStreetMap contributors, CARTO',
    subdomains: <String>['a', 'b', 'c', 'd'],
    maxZoom: 20,
  ),
];

DailyChoiceMapTileProviderSpec dailyChoiceResolveMapTileProvider(String id) {
  final normalized = id.trim();
  for (final provider in dailyChoicePlaceMapTileProviders) {
    if (provider.id == normalized) {
      return provider;
    }
  }
  return dailyChoicePlaceMapTileProviders.first;
}

Future<Directory> dailyChoicePlaceMapCacheDirectory() async {
  final root = await getApplicationCacheDirectory();
  return Directory(p.join(root.path, 'daily_choice', 'place_map_tiles'));
}

Future<MapCachingProvider> dailyChoiceCreatePlaceMapCachingProvider({
  required bool cacheTiles,
}) async {
  if (!cacheTiles) {
    return const DisabledMapCachingProvider();
  }
  final directory = await dailyChoicePlaceMapCacheDirectory();
  return BuiltInMapCachingProvider.getOrCreateInstance(
    cacheDirectory: directory.path,
    maxCacheSize: dailyChoicePlaceMapTileCacheMaxBytes,
    overrideFreshAge: dailyChoicePlaceMapTileFreshAge,
  );
}

Future<int> dailyChoicePlaceMapCacheSizeBytes() async {
  final directory = await dailyChoicePlaceMapCacheDirectory();
  if (!await directory.exists()) {
    return 0;
  }
  var size = 0;
  await for (final entity in directory.list(
    recursive: true,
    followLinks: false,
  )) {
    if (entity is File) {
      try {
        size += await entity.length();
      } on FileSystemException {
        // Cache entries are disposable; ignore files removed while scanning.
      }
    }
  }
  return size;
}

Future<void> dailyChoiceClearPlaceMapCache() async {
  final directory = await dailyChoicePlaceMapCacheDirectory();
  final provider = BuiltInMapCachingProvider.getOrCreateInstance(
    cacheDirectory: directory.path,
    maxCacheSize: dailyChoicePlaceMapTileCacheMaxBytes,
    overrideFreshAge: dailyChoicePlaceMapTileFreshAge,
  );
  await provider.destroy(deleteCache: true);
  if (await directory.exists()) {
    await directory.delete(recursive: true);
  }
}

String dailyChoiceFormatBytes(int bytes) {
  if (bytes < 1024) {
    return '$bytes B';
  }
  final kb = bytes / 1024;
  if (kb < 1024) {
    return '${kb.toStringAsFixed(kb < 10 ? 1 : 0)} KB';
  }
  final mb = kb / 1024;
  if (mb < 1024) {
    return '${mb.toStringAsFixed(mb < 10 ? 1 : 0)} MB';
  }
  final gb = mb / 1024;
  return '${gb.toStringAsFixed(gb < 10 ? 1 : 0)} GB';
}

List<Uri> dailyChoiceExternalMapUris(DailyChoiceOsmPlace place) {
  final lat = place.latitude.toStringAsFixed(6);
  final lon = place.longitude.toStringAsFixed(6);
  final label = place.name.trim().isEmpty ? 'Destination' : place.name.trim();
  return <Uri>[
    Uri.parse('geo:0,0?q=$lat,$lon(${Uri.encodeComponent(label)})'),
    Uri.https('maps.apple.com', '/', <String, String>{
      'll': '$lat,$lon',
      'q': label,
    }),
    Uri.https('www.openstreetmap.org', '/', <String, String>{
      'mlat': lat,
      'mlon': lon,
    }).replace(fragment: 'map=17/$lat/$lon'),
  ];
}

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

enum DailyChoiceLocationReadSource { device, ipCoarse }

class DailyChoiceLocationReadResult {
  const DailyChoiceLocationReadResult({
    required this.status,
    this.point,
    this.message,
    this.usedApproximateLocation = true,
    this.source = DailyChoiceLocationReadSource.device,
    this.areaLabel,
  });

  final DailyChoiceLocationReadStatus status;
  final DailyChoiceGeoPoint? point;
  final String? message;
  final bool usedApproximateLocation;
  final DailyChoiceLocationReadSource source;
  final String? areaLabel;

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

abstract class DailyChoiceCoarseLocationProvider {
  Future<DailyChoiceLocationReadResult> readCoarseLocation();
}

class DailyChoiceIpCoarseLocationProvider
    implements DailyChoiceCoarseLocationProvider {
  const DailyChoiceIpCoarseLocationProvider({
    http.Client? httpClient,
    Uri? endpoint,
  }) : _httpClient = httpClient,
       _endpoint = endpoint;

  final http.Client? _httpClient;
  final Uri? _endpoint;

  @override
  Future<DailyChoiceLocationReadResult> readCoarseLocation() async {
    final client = _httpClient ?? http.Client();
    try {
      final response = await client
          .get(
            _endpoint ?? dailyChoiceIpCoarseLocationEndpoint,
            headers: const <String, String>{
              'Accept': 'application/json',
              'User-Agent':
                  'vocabulary_sleep_app/1.0 (Daily Choice IP coarse range lookup)',
            },
          )
          .timeout(const Duration(seconds: 12));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return DailyChoiceLocationReadResult(
          status: DailyChoiceLocationReadStatus.failed,
          message: 'IP coarse location failed (${response.statusCode}).',
          source: DailyChoiceLocationReadSource.ipCoarse,
        );
      }
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map) {
        return const DailyChoiceLocationReadResult(
          status: DailyChoiceLocationReadStatus.failed,
          message: 'IP coarse location returned an unexpected response.',
          source: DailyChoiceLocationReadSource.ipCoarse,
        );
      }
      return _parseIpCoarseLocation(decoded);
    } catch (error) {
      return DailyChoiceLocationReadResult(
        status: DailyChoiceLocationReadStatus.failed,
        message: '$error',
        source: DailyChoiceLocationReadSource.ipCoarse,
      );
    } finally {
      if (_httpClient == null) {
        client.close();
      }
    }
  }

  static DailyChoiceLocationReadResult _parseIpCoarseLocation(Map raw) {
    final loc = '${raw['loc'] ?? ''}'.trim();
    double? latitude;
    double? longitude;
    if (loc.contains(',')) {
      final parts = loc.split(',');
      if (parts.length >= 2) {
        latitude = _doubleValue(parts[0]);
        longitude = _doubleValue(parts[1]);
      }
    }
    latitude ??= _doubleValue(raw['latitude']) ?? _doubleValue(raw['lat']);
    longitude ??= _doubleValue(raw['longitude']) ?? _doubleValue(raw['lon']);
    if (latitude == null || longitude == null) {
      return const DailyChoiceLocationReadResult(
        status: DailyChoiceLocationReadStatus.failed,
        message: 'IP coarse location did not include coordinates.',
        source: DailyChoiceLocationReadSource.ipCoarse,
      );
    }
    final areaParts = <String>[
      '${raw['city'] ?? ''}'.trim(),
      '${raw['region'] ?? raw['regionName'] ?? ''}'.trim(),
      '${raw['country'] ?? ''}'.trim(),
    ].where((item) => item.isNotEmpty).toList(growable: false);
    return DailyChoiceLocationReadResult(
      status: DailyChoiceLocationReadStatus.ready,
      point: DailyChoiceGeoPoint(
        latitude: latitude,
        longitude: longitude,
        accuracyMeters: DailyChoicePlaceMapSettings.coarseRangeRadiusMeters
            .toDouble(),
      ),
      usedApproximateLocation: true,
      source: DailyChoiceLocationReadSource.ipCoarse,
      areaLabel: areaParts.join(', '),
    );
  }
}

Future<bool> dailyChoiceOpenLocationSettings() {
  return Geolocator.openLocationSettings();
}

Future<bool> dailyChoiceOpenAppSettings() {
  return Geolocator.openAppSettings();
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
      DailyChoicePlaceMapSettings.coarseRangeRadiusMeters;
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
