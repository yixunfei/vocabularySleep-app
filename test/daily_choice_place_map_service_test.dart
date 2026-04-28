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
      ),
    );

    final restored = DailyChoiceCustomState.fromJson(state.toJson());

    expect(restored.placeMapSettings.consentGranted, isTrue);
    expect(restored.placeMapSettings.useApproximateLocation, isFalse);
    expect(restored.placeMapSettings.radiusMeters, 3000);
  });
}
