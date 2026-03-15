import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:vocabulary_sleep_app/src/services/app_log_service.dart';
import 'package:vocabulary_sleep_app/src/services/weather_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('weather_service_test_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (call) async {
          return tempDir.path;
        });
    AppLogService.instance.resetForTest();
  });

  tearDown(() async {
    await AppLogService.instance.flushForTest();
    AppLogService.instance.resetForTest();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test(
    'fetchCurrentWeather combines approximate city and Open-Meteo data',
    () async {
      final client = MockClient((request) async {
        if (request.url.host == 'ipwho.is') {
          return http.Response(
            jsonEncode(<String, Object?>{
              'success': true,
              'city': 'Shanghai',
              'country_code': 'CN',
              'latitude': 31.2222,
              'longitude': 121.4581,
            }),
            200,
          );
        }

        if (request.url.host == 'api.open-meteo.com') {
          expect(
            request.url.queryParameters['current'],
            contains('temperature_2m'),
          );
          expect(
            request.url.queryParameters['daily'],
            contains('temperature_2m_max'),
          );
          return http.Response(
            jsonEncode(<String, Object?>{
              'current': <String, Object?>{
                'temperature_2m': 18.4,
                'apparent_temperature': 17.8,
                'weather_code': 1,
                'is_day': 1,
                'wind_speed_10m': 6.2,
              },
              'daily': <String, Object?>{
                'time': <String>[
                  '2026-03-15',
                  '2026-03-16',
                  '2026-03-17',
                  '2026-03-18',
                ],
                'weather_code': <int>[1, 3, 61, 0],
                'temperature_2m_max': <double>[22.1, 19.3, 18.0, 21.6],
                'temperature_2m_min': <double>[14.2, 13.4, 11.8, 12.7],
              },
            }),
            200,
          );
        }

        throw StateError('Unexpected request: ${request.url}');
      });

      final snapshot = await WeatherService(
        client: client,
      ).fetchCurrentWeather();

      expect(snapshot.city, 'Shanghai');
      expect(snapshot.countryCode, 'CN');
      expect(snapshot.temperatureCelsius, 18.4);
      expect(snapshot.apparentTemperatureCelsius, 17.8);
      expect(snapshot.weatherCode, 1);
      expect(snapshot.isDay, isTrue);
      expect(snapshot.windSpeedKph, 6.2);
      expect(snapshot.todayMaxTemperatureCelsius, 22.1);
      expect(snapshot.todayMinTemperatureCelsius, 14.2);
      expect(snapshot.forecastDays, hasLength(4));
      expect(snapshot.forecastDays[2].weatherCode, 61);
    },
  );
}
