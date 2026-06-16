import 'package:weather_app/core/error/api_result.dart';
import 'package:weather_app/features/weather/domain/repositories/weather_repository.dart';

class GetRecentSearchesUseCase {
  final WeatherRepository repository;

  const GetRecentSearchesUseCase(this.repository);

  Future<ApiResult<List<String>>> call() {
    return repository.getRecentSearches();
  }
}
