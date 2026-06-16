import 'package:weather_app/core/error/api_result.dart';
import 'package:weather_app/features/weather/domain/entities/weather_entity.dart';
import 'package:weather_app/features/weather/domain/repositories/weather_repository.dart';

class GetWeatherUseCase {
  final WeatherRepository repository;

  const GetWeatherUseCase(this.repository);

  Future<ApiResult<WeatherEntity>> call(String cityName) {
    return repository.getWeather(cityName);
  }
}
