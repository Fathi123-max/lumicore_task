import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/core/error/api_result.dart';
import 'package:weather_app/core/error/failure.dart';
import 'package:weather_app/features/weather/domain/entities/weather_entity.dart';
import 'package:weather_app/features/weather/data/data_sources/weather_local_data_source.dart';
import 'package:weather_app/features/weather/data/data_sources/weather_remote_data_source.dart';
import 'package:weather_app/features/weather/data/models/weather_model.dart';
import 'package:weather_app/features/weather/data/repositories/weather_repository_impl.dart';

// Mock implementations
class MockRemoteDataSource implements WeatherRemoteDataSource {
  WeatherModel? weatherResult;
  Exception? exceptionToThrow;
  String? queriedCity;

  @override
  Future<WeatherModel> getWeather(String cityName) async {
    queriedCity = cityName;
    if (exceptionToThrow != null) throw exceptionToThrow!;
    if (weatherResult != null) return weatherResult!;
    throw const ServerException('Default remote error');
  }
}

class MockLocalDataSource implements WeatherLocalDataSource {
  WeatherModel? lastWeather;
  List<String> searches = [];
  
  bool cacheWeatherCalled = false;
  bool saveSearchCalled = false;

  @override
  Future<WeatherModel?> getLastWeather() async => lastWeather;

  @override
  Future<void> cacheWeather(WeatherModel weather) async {
    cacheWeatherCalled = true;
    lastWeather = weather;
  }

  @override
  Future<List<String>> getRecentSearches() async => searches;

  @override
  Future<void> saveRecentSearch(String cityName) async {
    saveSearchCalled = true;
    searches.add(cityName);
  }
}

void main() {
  late MockRemoteDataSource mockRemoteDataSource;
  late MockLocalDataSource mockLocalDataSource;
  late WeatherRepositoryImpl repository;

  final testWeather = WeatherModel(
    cityName: 'Cairo',
    temperatureCelsius: 30.0,
    conditionText: 'Sunny',
    conditionIconUrl: '//cdn.weather.org/sunny.png',
    humidity: 40,
    windKph: 15.0,
    lastUpdated: DateTime(2026, 6, 16),
    isCached: false,
  );

  setUp(() {
    mockRemoteDataSource = MockRemoteDataSource();
    mockLocalDataSource = MockLocalDataSource();
    repository = WeatherRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
    );
  });

  group('getWeather', () {
    test('should return remote weather and cache it locally when remote call is successful', () async {
      // Arrange
      mockRemoteDataSource.weatherResult = testWeather;

      // Act
      final result = await repository.getWeather('Cairo');

      // Assert
      expect(result, isA<ApiResultSuccess<WeatherEntity>>());
      final successResult = result as ApiResultSuccess<WeatherEntity>;
      expect(successResult.data.cityName, 'Cairo');
      
      expect(mockLocalDataSource.cacheWeatherCalled, isTrue);
      expect(mockLocalDataSource.lastWeather?.cityName, 'Cairo');
    });

    test('should return cached weather fallback when remote call fails with SocketException', () async {
      // Arrange
      mockRemoteDataSource.exceptionToThrow = const SocketException('No internet');
      
      // Populate local cache
      final cachedWeather = WeatherModel(
        cityName: 'Cairo',
        temperatureCelsius: 30.0,
        conditionText: 'Sunny',
        conditionIconUrl: '//cdn.weather.org/sunny.png',
        humidity: 40,
        windKph: 15.0,
        lastUpdated: DateTime(2026, 6, 16),
        isCached: true,
      );
      mockLocalDataSource.lastWeather = cachedWeather;

      // Act
      final result = await repository.getWeather('Cairo');

      // Assert
      expect(result, isA<ApiResultSuccess<WeatherEntity>>());
      final successResult = result as ApiResultSuccess<WeatherEntity>;
      expect(successResult.data.isCached, isTrue);
      expect(successResult.data.cityName, 'Cairo');
    });

    test('should return NetworkFailure when remote fails with SocketException and no cache exists', () async {
      // Arrange
      mockRemoteDataSource.exceptionToThrow = const SocketException('No internet');
      mockLocalDataSource.lastWeather = null;

      // Act
      final result = await repository.getWeather('Cairo');

      // Assert
      expect(result, isA<ApiResultFailure<WeatherEntity>>());
      final failureResult = result as ApiResultFailure<WeatherEntity>;
      expect(failureResult.failure, isA<NetworkFailure>());
    });

    test('should return InvalidInputFailure when remote fails with InvalidCityException', () async {
      // Arrange
      mockRemoteDataSource.exceptionToThrow = const InvalidCityException('City not found');

      // Act
      final result = await repository.getWeather('InvalidCity');

      // Assert
      expect(result, isA<ApiResultFailure<WeatherEntity>>());
      final failureResult = result as ApiResultFailure<WeatherEntity>;
      expect(failureResult.failure, isA<InvalidInputFailure>());
    });
  });

  group('getLastCachedWeather', () {
    test('should return cached weather when it exists', () async {
      // Arrange
      final cachedWeather = WeatherModel(
        cityName: 'Cairo',
        temperatureCelsius: 30.0,
        conditionText: 'Sunny',
        conditionIconUrl: '//cdn.weather.org/sunny.png',
        humidity: 40,
        windKph: 15.0,
        lastUpdated: DateTime(2026, 6, 16),
        isCached: true,
      );
      mockLocalDataSource.lastWeather = cachedWeather;

      // Act
      final result = await repository.getLastCachedWeather();

      // Assert
      expect(result, isA<ApiResultSuccess<WeatherEntity?>>());
      final successResult = result as ApiResultSuccess<WeatherEntity?>;
      expect(successResult.data?.cityName, 'Cairo');
      expect(successResult.data?.isCached, isTrue);
    });

    test('should return null when no cached weather exists', () async {
      // Arrange
      mockLocalDataSource.lastWeather = null;

      // Act
      final result = await repository.getLastCachedWeather();

      // Assert
      expect(result, isA<ApiResultSuccess<WeatherEntity?>>());
      final successResult = result as ApiResultSuccess<WeatherEntity?>;
      expect(successResult.data, isNull);
    });
  });
}
