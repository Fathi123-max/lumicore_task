import 'package:weather_app/features/weather/domain/entities/weather_entity.dart';

sealed class WeatherState {
  final List<String> recentSearches;

  const WeatherState({required this.recentSearches});
}

class WeatherInitial extends WeatherState {
  const WeatherInitial({required super.recentSearches});
}

class WeatherLoading extends WeatherState {
  const WeatherLoading({required super.recentSearches});
}

class WeatherLoaded extends WeatherState {
  final WeatherEntity weather;
  final bool isFromCache;

  const WeatherLoaded({
    required this.weather,
    required super.recentSearches,
    required this.isFromCache,
  });
}

class WeatherError extends WeatherState {
  final String message;
  final WeatherEntity? cachedWeather;

  const WeatherError({
    required this.message,
    required super.recentSearches,
    this.cachedWeather,
  });
}
