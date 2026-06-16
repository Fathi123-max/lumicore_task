import 'package:weather_app/core/error/api_result.dart';
import 'package:weather_app/features/weather/domain/repositories/weather_repository.dart';

class SaveRecentSearchUseCase {
  final WeatherRepository repository;

  const SaveRecentSearchUseCase(this.repository);

  Future<ApiResult<void>> call(String cityName) {
    return repository.saveRecentSearch(cityName);
  }
}
