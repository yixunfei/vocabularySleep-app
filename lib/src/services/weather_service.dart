import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/weather_snapshot.dart';
import 'app_log_service.dart';

class WeatherService {
  WeatherService({http.Client? client}) : _client = client;

  final http.Client? _client;
  final AppLogService _log = AppLogService.instance;

  Future<WeatherSnapshot> fetchCurrentWeather() async {
    final client = _client ?? http.Client();
    try {
      final location = await _lookupApproximateLocation(client);
      return await _fetchWeather(client, location);
    } finally {
      if (_client == null) {
        client.close();
      }
    }
  }

  Future<_ApproximateLocation> _lookupApproximateLocation(
    http.Client client,
  ) async {
    final uri = Uri.https('ipwho.is', '/', <String, String>{
      'fields': 'success,message,city,country_code,latitude,longitude',
    });
    final response = await client.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'Approximate location lookup failed (${response.statusCode}).',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw const FormatException('Approximate location payload is invalid.');
    }
    final payload = decoded.cast<String, Object?>();
    if (payload['success'] == false) {
      throw StateError(
        '${payload['message'] ?? 'Approximate location lookup failed.'}',
      );
    }

    final city = '${payload['city'] ?? ''}'.trim();
    final latitude = (payload['latitude'] as num?)?.toDouble();
    final longitude = (payload['longitude'] as num?)?.toDouble();
    if (city.isEmpty || latitude == null || longitude == null) {
      throw const FormatException('Approximate location is incomplete.');
    }

    return _ApproximateLocation(
      city: city,
      countryCode: '${payload['country_code'] ?? ''}'.trim().toUpperCase(),
      latitude: latitude,
      longitude: longitude,
    );
  }

  Future<WeatherSnapshot> _fetchWeather(
    http.Client client,
    _ApproximateLocation location,
  ) async {
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', <
      String,
      String
    >{
      'latitude': location.latitude.toString(),
      'longitude': location.longitude.toString(),
      'current':
          'temperature_2m,apparent_temperature,weather_code,is_day,wind_speed_10m',
      'daily': 'weather_code,temperature_2m_max,temperature_2m_min',
      'timezone': 'auto',
      'forecast_days': '4',
    });
    final response = await client.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Weather lookup failed (${response.statusCode}).');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw const FormatException('Weather payload is invalid.');
    }
    final payload = decoded.cast<String, Object?>();
    final current = payload['current'];
    if (current is! Map) {
      throw const FormatException(
        'Weather payload is missing current conditions.',
      );
    }
    final currentMap = current.cast<String, Object?>();
    final forecastDays = _parseForecastDays(payload['daily']);

    final temperature = (currentMap['temperature_2m'] as num?)?.toDouble();
    final apparentTemperature = (currentMap['apparent_temperature'] as num?)
        ?.toDouble();
    final weatherCode = (currentMap['weather_code'] as num?)?.toInt();
    final isDay = ((currentMap['is_day'] as num?)?.toInt() ?? 1) == 1;
    final windSpeed = (currentMap['wind_speed_10m'] as num?)?.toDouble();
    if (temperature == null ||
        apparentTemperature == null ||
        weatherCode == null ||
        windSpeed == null) {
      throw const FormatException('Weather payload is incomplete.');
    }

    final snapshot = WeatherSnapshot(
      city: location.city,
      countryCode: location.countryCode,
      temperatureCelsius: temperature,
      apparentTemperatureCelsius: apparentTemperature,
      windSpeedKph: windSpeed,
      weatherCode: weatherCode,
      isDay: isDay,
      fetchedAt: DateTime.now(),
      forecastDays: forecastDays,
    );
    _log.d(
      'weather',
      'current weather updated',
      data: <String, Object?>{
        'city': snapshot.city,
        'countryCode': snapshot.countryCode,
        'temperatureCelsius': snapshot.temperatureCelsius,
        'weatherCode': snapshot.weatherCode,
      },
    );
    return snapshot;
  }

  List<WeatherForecastDay> _parseForecastDays(Object? dailyPayload) {
    if (dailyPayload is! Map) {
      return const <WeatherForecastDay>[];
    }
    final daily = dailyPayload.cast<String, Object?>();
    final times = _readStringList(daily['time']);
    final weatherCodes = _readIntList(daily['weather_code']);
    final maxTemperatures = _readDoubleList(daily['temperature_2m_max']);
    final minTemperatures = _readDoubleList(daily['temperature_2m_min']);
    final length = <int>[
      times.length,
      weatherCodes.length,
      maxTemperatures.length,
      minTemperatures.length,
    ].reduce((left, right) => left < right ? left : right);
    if (length <= 0) {
      return const <WeatherForecastDay>[];
    }

    final days = <WeatherForecastDay>[];
    for (var index = 0; index < length; index += 1) {
      final date = DateTime.tryParse(times[index]);
      if (date == null) {
        continue;
      }
      days.add(
        WeatherForecastDay(
          date: date,
          weatherCode: weatherCodes[index],
          maxTemperatureCelsius: maxTemperatures[index],
          minTemperatureCelsius: minTemperatures[index],
        ),
      );
    }
    return days;
  }

  List<String> _readStringList(Object? value) {
    if (value is! List) {
      return const <String>[];
    }
    final output = <String>[];
    for (final item in value) {
      final text = '$item'.trim();
      if (text.isNotEmpty) {
        output.add(text);
      }
    }
    return output;
  }

  List<int> _readIntList(Object? value) {
    if (value is! List) {
      return const <int>[];
    }
    final output = <int>[];
    for (final item in value) {
      if (item is num) {
        output.add(item.toInt());
      }
    }
    return output;
  }

  List<double> _readDoubleList(Object? value) {
    if (value is! List) {
      return const <double>[];
    }
    final output = <double>[];
    for (final item in value) {
      if (item is num) {
        output.add(item.toDouble());
      }
    }
    return output;
  }
}

class _ApproximateLocation {
  const _ApproximateLocation({
    required this.city,
    required this.countryCode,
    required this.latitude,
    required this.longitude,
  });

  final String city;
  final String countryCode;
  final double latitude;
  final double longitude;
}
