class WeatherSnapshot {
  const WeatherSnapshot({
    required this.city,
    required this.countryCode,
    required this.temperatureCelsius,
    required this.apparentTemperatureCelsius,
    required this.windSpeedKph,
    required this.weatherCode,
    required this.isDay,
    required this.fetchedAt,
  });

  final String city;
  final String countryCode;
  final double temperatureCelsius;
  final double apparentTemperatureCelsius;
  final double windSpeedKph;
  final int weatherCode;
  final bool isDay;
  final DateTime fetchedAt;
}
