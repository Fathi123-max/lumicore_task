import 'package:weather_app/core/error/api_result.dart';
import 'package:weather_app/features/weather/domain/entities/weather_entity.dart';
import 'package:weather_app/features/weather/domain/repositories/weather_repository.dart';

class GetLastCachedWeatherUseCase {
  final WeatherRepository repository;

  const GetLastCachedWeatherUseCase(this.repository);

  Future<ApiResult<WeatherEntity?>> call() {
    return repository.getLastCachedWeather();
  }
}
