import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/core/error/api_result.dart';
import 'package:weather_app/core/error/failure.dart';
import 'package:weather_app/features/weather/domain/entities/weather_entity.dart';
import 'package:weather_app/features/weather/domain/repositories/weather_repository.dart';
import 'package:weather_app/features/weather/domain/use_cases/get_last_cached_weather.dart';
import 'package:weather_app/features/weather/domain/use_cases/get_recent_searches.dart';
import 'package:weather_app/features/weather/domain/use_cases/get_weather.dart';
import 'package:weather_app/features/weather/domain/use_cases/save_recent_search.dart';
import 'package:weather_app/features/weather/presentation/cubit/weather_cubit.dart';
import 'package:weather_app/features/weather/presentation/cubit/weather_state.dart';

// Manual Mock implementation of WeatherRepository
class MockWeatherRepository implements WeatherRepository {
  ApiResult<WeatherEntity>? getWeatherResult;
  ApiResult<WeatherEntity?>? getLastCachedWeatherResult;
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
  Future<ApiResult<WeatherEntity?>> getLastCachedWeather() async {
    if (getLastCachedWeatherResult != null) return getLastCachedWeatherResult!;
    return const ApiResultSuccess(null);
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
  late GetLastCachedWeatherUseCase getLastCachedWeatherUseCase;
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

  final cachedWeather = WeatherEntity(
    cityName: 'Cairo',
    temperatureCelsius: 30.0,
    conditionText: 'Sunny',
    conditionIconUrl: '//cdn.weather.org/sunny.png',
    humidity: 40,
    windKph: 15.0,
    lastUpdated: DateTime(2026, 6, 15),
    isCached: true,
  );

  setUp(() {
    mockRepository = MockWeatherRepository();
    getWeatherUseCase = GetWeatherUseCase(mockRepository);
    getLastCachedWeatherUseCase = GetLastCachedWeatherUseCase(mockRepository);
    getRecentSearchesUseCase = GetRecentSearchesUseCase(mockRepository);
    saveRecentSearchUseCase = SaveRecentSearchUseCase(mockRepository);
    
    cubit = WeatherCubit(
      getWeatherUseCase: getWeatherUseCase,
      getLastCachedWeatherUseCase: getLastCachedWeatherUseCase,
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
    cubit.emit(const WeatherLoading(recentSearches: []));
    
    // Trigger fetchWeather
    await cubit.fetchWeather('Paris');

    // If it did NOT ignore the duplicate call, it would trigger repo.getWeather('Paris')
    // We expect lastGetWeatherCity to remain null because Paris was ignored
    expect(mockRepository.lastGetWeatherCity, isNull);
  });

  test('should include cachedWeather in WeatherError when cached data exists', () async {
    // Arrange
    mockRepository.getWeatherResult = const ApiResultFailure(InvalidInputFailure('City not found'));
    mockRepository.getLastCachedWeatherResult = ApiResultSuccess(cachedWeather);

    // Assert Later
    expectLater(
      cubit.stream,
      emitsInOrder([
        isA<WeatherLoading>(),
        isA<WeatherError>().having(
          (e) => e.cachedWeather?.cityName,
          'cachedWeather.cityName',
          'Cairo',
        ),
      ]),
    );

    // Act
    await cubit.fetchWeather('InvalidCity');
  });

  test('should emit WeatherError with null cachedWeather when no cache exists', () async {
    // Arrange
    mockRepository.getWeatherResult = const ApiResultFailure(ServerFailure('Server error'));
    mockRepository.getLastCachedWeatherResult = const ApiResultSuccess(null);

    // Assert Later
    expectLater(
      cubit.stream,
      emitsInOrder([
        isA<WeatherLoading>(),
        isA<WeatherError>().having(
          (e) => e.cachedWeather,
          'cachedWeather',
          isNull,
        ),
      ]),
    );

    // Act
    await cubit.fetchWeather('SomeCity');
  });

  test('should emit WeatherError for empty city name without loading', () async {
    // Assert Later
    expectLater(
      cubit.stream,
      emits(isA<WeatherError>().having(
        (e) => e.message,
        'message',
        'City name cannot be empty.',
      )),
    );

    // Act
    await cubit.fetchWeather('   ');
  });
}
