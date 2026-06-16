class WeatherEntity {
  final String cityName;
  final double temperatureCelsius;
  final String conditionText;
  final String conditionIconUrl;
  final int humidity;
  final double windKph;
  final DateTime lastUpdated;
  final bool isCached;

  const WeatherEntity({
    required this.cityName,
    required this.temperatureCelsius,
    required this.conditionText,
    required this.conditionIconUrl,
    required this.humidity,
    required this.windKph,
    required this.lastUpdated,
    required this.isCached,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeatherEntity &&
          runtimeType == other.runtimeType &&
          cityName == other.cityName &&
          temperatureCelsius == other.temperatureCelsius &&
          conditionText == other.conditionText &&
          conditionIconUrl == other.conditionIconUrl &&
          humidity == other.humidity &&
          windKph == other.windKph &&
          lastUpdated == other.lastUpdated &&
          isCached == other.isCached;

  @override
  int get hashCode =>
      cityName.hashCode ^
      temperatureCelsius.hashCode ^
      conditionText.hashCode ^
      conditionIconUrl.hashCode ^
      humidity.hashCode ^
      windKph.hashCode ^
      lastUpdated.hashCode ^
      isCached.hashCode;
}
