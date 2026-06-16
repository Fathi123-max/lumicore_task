import 'package:weather_app/core/error/api_result.dart';
import 'package:weather_app/features/weather/domain/entities/weather_entity.dart';

abstract class WeatherRepository {
  Future<ApiResult<WeatherEntity>> getWeather(String cityName);
  Future<ApiResult<List<String>>> getRecentSearches();
  Future<ApiResult<void>> saveRecentSearch(String cityName);
}
