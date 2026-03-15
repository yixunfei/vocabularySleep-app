class WeatherForecastDay {
  const WeatherForecastDay({
    required this.date,
    required this.weatherCode,
    required this.maxTemperatureCelsius,
    required this.minTemperatureCelsius,
  });

  final DateTime date;
  final int weatherCode;
  final double maxTemperatureCelsius;
  final double minTemperatureCelsius;
}

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
    this.forecastDays = const <WeatherForecastDay>[],
  });

  final String city;
  final String countryCode;
  final double temperatureCelsius;
  final double apparentTemperatureCelsius;
  final double windSpeedKph;
  final int weatherCode;
  final bool isDay;
  final DateTime fetchedAt;
  final List<WeatherForecastDay> forecastDays;

  double? get todayMaxTemperatureCelsius =>
      forecastDays.isEmpty ? null : forecastDays.first.maxTemperatureCelsius;

  double? get todayMinTemperatureCelsius =>
      forecastDays.isEmpty ? null : forecastDays.first.minTemperatureCelsius;
}
