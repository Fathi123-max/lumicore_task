import 'package:weather_app/features/weather/domain/entities/weather_entity.dart';

class WeatherModel extends WeatherEntity {
  const WeatherModel({
    required super.cityName,
    required super.temperatureCelsius,
    required super.conditionText,
    required super.conditionIconUrl,
    required super.humidity,
    required super.windKph,
    required super.lastUpdated,
    required super.isCached,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json, {bool isCached = false}) {
    final location = json['location'] as Map<String, dynamic>? ?? {};
    final current = json['current'] as Map<String, dynamic>? ?? {};
    final condition = current['condition'] as Map<String, dynamic>? ?? {};

    // WeatherAPI returns wind_kph as a double or int
    final tempValue = current['temp_c'];
    final double temp = tempValue is int ? tempValue.toDouble() : (tempValue as double? ?? 0.0);

    final windValue = current['wind_kph'];
    final double wind = windValue is int ? windValue.toDouble() : (windValue as double? ?? 0.0);

    // Date parsing
    DateTime lastUpdatedTime;
    try {
      final lastUpdatedStr = current['last_updated'] as String?;
      if (lastUpdatedStr != null) {
        lastUpdatedTime = DateTime.parse(lastUpdatedStr);
      } else {
        lastUpdatedTime = DateTime.now();
      }
    } catch (_) {
      lastUpdatedTime = DateTime.now();
    }

    return WeatherModel(
      cityName: location['name'] as String? ?? '',
      temperatureCelsius: temp,
      conditionText: condition['text'] as String? ?? 'Unknown',
      conditionIconUrl: condition['icon'] as String? ?? '',
      humidity: current['humidity'] as int? ?? 0,
      windKph: wind,
      lastUpdated: lastUpdatedTime,
      isCached: isCached,
    );
  }

  // To support local database cache representation
  factory WeatherModel.fromLocalJson(Map<String, dynamic> json) {
    return WeatherModel(
      cityName: json['cityName'] as String? ?? '',
      temperatureCelsius: (json['temperatureCelsius'] as num? ?? 0.0).toDouble(),
      conditionText: json['conditionText'] as String? ?? 'Unknown',
      conditionIconUrl: json['conditionIconUrl'] as String? ?? '',
      humidity: json['humidity'] as int? ?? 0,
      windKph: (json['windKph'] as num? ?? 0.0).toDouble(),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String? ?? DateTime.now().toIso8601String()),
      isCached: true, // Local cache is always cached
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cityName': cityName,
      'temperatureCelsius': temperatureCelsius,
      'conditionText': conditionText,
      'conditionIconUrl': conditionIconUrl,
      'humidity': humidity,
      'windKph': windKph,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}
