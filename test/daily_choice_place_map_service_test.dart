import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/toolbox_daily_choice/daily_choice_models.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/toolbox_daily_choice/daily_choice_place_map_service.dart';

void main() {
  test('fuzzed location snaps to a coarse grid without moving too far', () {
    const exact = DailyChoiceGeoPoint(
      latitude: 31.234567,
      longitude: 121.456789,
      accuracyMeters: 12,
    );

    final fuzzed = exact.fuzzed(gridMeters: 500);
    final moved = dailyChoiceDistanceMeters(
      exact.latitude,
      exact.longitude,
      fuzzed.latitude,
      fuzzed.longitude,
    );

    expect(fuzzed.latitude, isNot(exact.latitude));
    expect(fuzzed.longitude, isNot(exact.longitude));
    expect(fuzzed.accuracyMeters, greaterThanOrEqualTo(500));
    expect(moved, lessThan(400));
  });

  test(
    'Overpass client sends a bounded nearby query and parses places',
    () async {
      late String sentBody;
      final client = DailyChoiceOverpassClient(
        httpClient: MockClient((request) async {
          sentBody = Uri.splitQueryString(request.body)['data'] ?? '';
          expect(
            request.headers['User-Agent'],
            contains('vocabulary_sleep_app'),
          );
          expect(request.url.host, 'overpass-api.de');
          return http.Response.bytes(
            utf8.encode(
              jsonEncode(<String, Object?>{
                'elements': <Map<String, Object?>>[
                  <String, Object?>{
                    'type': 'way',
                    'id': 22,
                    'center': <String, Object?>{'lat': 31.231, 'lon': 121.451},
                    'tags': <String, Object?>{
                      'name': 'Quiet Park',
                      'leisure': 'park',
                    },
                  },
                  <String, Object?>{
                    'type': 'node',
                    'id': 11,
                    'lat': 31.2301,
                    'lon': 121.4501,
                    'tags': <String, Object?>{
                      'name': 'Morning Cafe',
                      'amenity': 'cafe',
                    },
                  },
                  <String, Object?>{
                    'type': 'node',
                    'id': 12,
                    'lat': 31.2302,
                    'lon': 121.4502,
                    'tags': <String, Object?>{'amenity': 'bench'},
                  },
                ],
              }),
            ),
            200,
            headers: <String, String>{
              'content-type': 'application/json; charset=utf-8',
            },
          );
        }),
      );

      final places = await client.fetchNearbyPlaces(
        center: const DailyChoiceGeoPoint(latitude: 31.23, longitude: 121.45),
        radiusMeters: 1000,
        limit: 30,
      );

      expect(sentBody, contains('around:1000,31.230000,121.450000'));
      expect(sentBody, contains('out center tags 30'));
      expect(places, hasLength(2));
      expect(places.first.name, 'Morning Cafe');
      expect(places.first.sceneId, 'food');
      expect(places.last.name, 'Quiet Park');
      expect(places.last.sceneId, 'nature');
    },
  );

  test('OSM place converts into a local custom go option', () {
    const place = DailyChoiceOsmPlace(
      id: 'go_osm_node_42',
      osmType: 'node',
      osmId: 42,
      name: 'City Library',
      latitude: 31.2,
      longitude: 121.4,
      distanceMeters: 850,
      categoryId: 'outside',
      sceneId: 'study',
      kindZh: '学习',
      kindEn: 'Study',
      tags: <String, String>{'amenity': 'library'},
    );

    final option = place.toDailyChoiceOption();

    expect(option.id, 'go_osm_node_42');
    expect(option.moduleId, DailyChoiceModuleId.go.storageValue);
    expect(option.categoryId, 'outside');
    expect(option.contextId, 'study');
    expect(option.custom, isTrue);
    expect(option.sourceLabel, 'OpenStreetMap');
    expect(
      option.references.single.url,
      'https://www.openstreetmap.org/node/42',
    );
    expect(option.attributes['osm_id'], <String>['42']);
    expect(option.attributes.containsKey('user_latitude'), isFalse);
    expect(option.detailsZh, contains('不会收集你的定位'));
  });

  test('place map settings persist through custom state JSON', () {
    const state = DailyChoiceCustomState(
      placeMapSettings: DailyChoicePlaceMapSettings(
        consentGranted: true,
        useApproximateLocation: false,
        radiusMeters: 3000,
        tileProviderId: 'carto_light',
        cacheTiles: false,
        autoFitResults: false,
      ),
    );

    final restored = DailyChoiceCustomState.fromJson(state.toJson());

    expect(restored.placeMapSettings.consentGranted, isTrue);
    expect(restored.placeMapSettings.useApproximateLocation, isFalse);
    expect(restored.placeMapSettings.radiusMeters, 3000);
    expect(restored.placeMapSettings.tileProviderId, 'carto_light');
    expect(restored.placeMapSettings.cacheTiles, isFalse);
    expect(restored.placeMapSettings.autoFitResults, isFalse);
  });

  test('default tile provider uses OSM HOT instead of CARTO', () {
    final provider = dailyChoiceResolveMapTileProvider(
      DailyChoicePlaceMapSettings.defaults.tileProviderId,
    );

    expect(provider.id, DailyChoicePlaceMapSettings.defaultTileProviderId);
    expect(provider.urlTemplate, contains('tile.openstreetmap.fr/hot'));
    expect(provider.urlTemplate, isNot(contains('tile.openstreetmap.org')));
    expect(provider.usesOsmPublicTileServer, isFalse);
    expect(provider.requiresConservativeUse, isTrue);
    expect(provider.attribution, contains('OpenStreetMap'));
  });

  test('tile provider resolution includes community fallbacks', () {
    final fallback = dailyChoiceResolveMapTileProvider('missing-provider');
    final osm = dailyChoiceResolveMapTileProvider('osm_standard');
    final france = dailyChoiceResolveMapTileProvider('osm_france_fallback');
    final de = dailyChoiceResolveMapTileProvider('osm_de');
    final carto = dailyChoiceResolveMapTileProvider('carto_voyager_fallback');

    expect(fallback.id, DailyChoicePlaceMapSettings.defaultTileProviderId);
    expect(osm.urlTemplate, contains('tile.openstreetmap.org'));
    expect(osm.usesOsmPublicTileServer, isTrue);
    expect(france.urlTemplate, contains('tile.openstreetmap.fr/osmfr'));
    expect(de.urlTemplate, contains('tile.openstreetmap.de'));
    expect(carto.urlTemplate, contains('basemaps.cartocdn.com'));
  });

  test(
    'legacy CARTO and OSM France default settings migrate to the current default source',
    () {
      final restoredCarto = DailyChoicePlaceMapSettings.fromJson(
        <String, Object?>{'tileProviderId': 'carto_voyager'},
      );
      final restoredFrance = DailyChoicePlaceMapSettings.fromJson(
        <String, Object?>{'tileProviderId': 'osm_france'},
      );

      expect(
        restoredCarto.tileProviderId,
        DailyChoicePlaceMapSettings.defaultTileProviderId,
      );
      expect(
        restoredFrance.tileProviderId,
        DailyChoicePlaceMapSettings.defaultTileProviderId,
      );
    },
  );

  test('IP coarse location provider parses city-level coordinates', () async {
    late Uri requestedUrl;
    final provider = DailyChoiceIpCoarseLocationProvider(
      endpoint: Uri.https('example.test', '/json'),
      httpClient: MockClient((request) async {
        requestedUrl = request.url;
        expect(request.headers['User-Agent'], contains('IP coarse range'));
        return http.Response.bytes(
          utf8.encode(
            jsonEncode(<String, Object?>{
              'city': 'Chengdu',
              'region': 'Sichuan',
              'country': 'CN',
              'loc': '30.6667,104.0667',
            }),
          ),
          200,
          headers: <String, String>{'content-type': 'application/json'},
        );
      }),
    );

    final result = await provider.readCoarseLocation();

    expect(requestedUrl.host, 'example.test');
    expect(result.hasPoint, isTrue);
    expect(result.source, DailyChoiceLocationReadSource.ipCoarse);
    expect(result.usedApproximateLocation, isTrue);
    expect(result.areaLabel, 'Chengdu, Sichuan, CN');
    expect(result.point!.latitude, 30.6667);
    expect(result.point!.longitude, 104.0667);
    expect(
      result.point!.accuracyMeters,
      DailyChoicePlaceMapSettings.coarseRangeRadiusMeters,
    );
  });

  test('map cache byte labels use compact units', () {
    expect(dailyChoiceFormatBytes(512), '512 B');
    expect(dailyChoiceFormatBytes(1536), '1.5 KB');
    expect(dailyChoiceFormatBytes(2 * 1024 * 1024), '2.0 MB');
  });

  test('external map links prefer native map app URI with web fallback', () {
    const place = DailyChoiceOsmPlace(
      id: 'go_osm_node_77',
      osmType: 'node',
      osmId: 77,
      name: 'Pocket Garden',
      latitude: 31.234567,
      longitude: 121.456789,
      distanceMeters: 200,
      categoryId: 'outside',
      sceneId: 'nature',
      kindZh: '自然',
      kindEn: 'Nature',
      tags: <String, String>{'leisure': 'garden'},
    );

    final links = dailyChoiceExternalMapUris(place);

    expect(links, hasLength(3));
    expect(links.first.scheme, 'geo');
    expect(links.first.toString(), contains('31.234567,121.456789'));
    expect(links.first.toString(), contains('Pocket%20Garden'));
    expect(links[1].host, 'maps.apple.com');
    expect(links.last.host, 'www.openstreetmap.org');
  });
}
