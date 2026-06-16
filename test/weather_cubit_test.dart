import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/core/error/api_result.dart';
import 'package:weather_app/core/error/failure.dart';
import 'package:weather_app/features/weather/domain/entities/weather_entity.dart';
import 'package:weather_app/features/weather/domain/repositories/weather_repository.dart';
import 'package:weather_app/features/weather/domain/use_cases/get_recent_searches.dart';
import 'package:weather_app/features/weather/domain/use_cases/get_weather.dart';
import 'package:weather_app/features/weather/domain/use_cases/save_recent_search.dart';
import 'package:weather_app/features/weather/presentation/cubit/weather_cubit.dart';
import 'package:weather_app/features/weather/presentation/cubit/weather_state.dart';

// Manual Mock implementation of WeatherRepository
class MockWeatherRepository implements WeatherRepository {
  ApiResult<WeatherEntity>? getWeatherResult;
  ApiResult<List<String>>? getRecentSearchesResult;
  ApiResult<void>? saveRecentSearchResult;
  
  String? lastGetWeatherCity;
  String? lastSavedCity;

  @override
  Future<ApiResult<WeatherEntity>> getWeather(String cityName) async {
    lastGetWeatherCity = cityName;
    if (getWeatherResult != null) return getWeatherResult!;
    return ApiResultFailure(const ServerFailure('Default mock error'));
  }

  @override
  Future<ApiResult<List<String>>> getRecentSearches() async {
    if (getRecentSearchesResult != null) return getRecentSearchesResult!;
    return const ApiResultSuccess([]);
  }

  @override
  Future<ApiResult<void>> saveRecentSearch(String cityName) async {
    lastSavedCity = cityName;
    if (saveRecentSearchResult != null) return saveRecentSearchResult!;
    return const ApiResultSuccess(null);
  }
}

void main() {
  late MockWeatherRepository mockRepository;
  late GetWeatherUseCase getWeatherUseCase;
  late GetRecentSearchesUseCase getRecentSearchesUseCase;
  late SaveRecentSearchUseCase saveRecentSearchUseCase;
  late WeatherCubit cubit;

  final testWeather = WeatherEntity(
    cityName: 'London',
    temperatureCelsius: 15.0,
    conditionText: 'Cloudy',
    conditionIconUrl: '//cdn.weather.org/cloud.png',
    humidity: 80,
    windKph: 12.0,
    lastUpdated: DateTime(2026, 6, 16),
    isCached: false,
  );

  setUp(() {
    mockRepository = MockWeatherRepository();
    getWeatherUseCase = GetWeatherUseCase(mockRepository);
    getRecentSearchesUseCase = GetRecentSearchesUseCase(mockRepository);
    saveRecentSearchUseCase = SaveRecentSearchUseCase(mockRepository);
    
    cubit = WeatherCubit(
      getWeatherUseCase: getWeatherUseCase,
      getRecentSearchesUseCase: getRecentSearchesUseCase,
      saveRecentSearchUseCase: saveRecentSearchUseCase,
    );
  });

  tearDown(() {
    cubit.close();
  });

  test('initial state should be WeatherInitial with empty list', () {
    expect(cubit.state, isA<WeatherInitial>());
    expect(cubit.state.recentSearches, isEmpty);
  });

  test('should emit WeatherLoading and then WeatherLoaded when search is successful', () async {
    // Arrange
    mockRepository.getWeatherResult = ApiResultSuccess(testWeather);
    mockRepository.getRecentSearchesResult = const ApiResultSuccess(['London']);

    // Assert Later
    final expectedStates = [
      isA<WeatherLoading>(),
      isA<WeatherLoaded>(),
    ];
    
    expectLater(cubit.stream, emitsInOrder(expectedStates));

    // Act
    await cubit.fetchWeather('London');

    // Verify use case parameters
    expect(mockRepository.lastGetWeatherCity, 'London');
    expect(mockRepository.lastSavedCity, 'London');
  });

  test('should emit WeatherLoading and then WeatherError when search fails', () async {
    // Arrange
    mockRepository.getWeatherResult = ApiResultFailure(const ServerFailure('City not found'));

    // Assert Later
    final expectedStates = [
      isA<WeatherLoading>(),
      isA<WeatherError>(),
    ];
    
    expectLater(cubit.stream, emitsInOrder(expectedStates));

    // Act
    await cubit.fetchWeather('UnknownCity');
  });

  test('should prevent duplicate requests if currently loading', () async {
    // Arrange
    mockRepository.getWeatherResult = ApiResultSuccess(testWeather);
    
    // Act (manually push to loading state)
    // We emit WeatherLoading state
    cubit.emit(const WeatherLoading(recentSearches: []));
    
    // Trigger fetchWeather
    await cubit.fetchWeather('Paris');

    // If it did NOT ignore the duplicate call, it would trigger repo.getWeather('Paris')
    // We expect lastGetWeatherCity to remain null because Paris was ignored
    expect(mockRepository.lastGetWeatherCity, isNull);
  });
}
