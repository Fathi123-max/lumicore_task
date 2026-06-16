import 'dart:io';
import 'package:weather_app/core/error/api_result.dart';
import 'package:weather_app/core/error/failure.dart';
import 'package:weather_app/features/weather/data/data_sources/weather_local_data_source.dart';
import 'package:weather_app/features/weather/data/data_sources/weather_remote_data_source.dart';
import 'package:weather_app/features/weather/domain/entities/weather_entity.dart';
import 'package:weather_app/features/weather/domain/repositories/weather_repository.dart';

class WeatherRepositoryImpl implements WeatherRepository {
  final WeatherRemoteDataSource remoteDataSource;
  final WeatherLocalDataSource localDataSource;

  WeatherRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<ApiResult<WeatherEntity>> getWeather(String cityName) async {
    try {
      final remoteWeather = await remoteDataSource.getWeather(cityName);
      // Cache the successfully retrieved weather data
      await localDataSource.cacheWeather(remoteWeather);
      return ApiResultSuccess(remoteWeather);
    } on InvalidCityException catch (e) {
      return ApiResultFailure(InvalidInputFailure(e.message));
    } on ServerException catch (e) {
      return ApiResultFailure(ServerFailure(e.message));
    } on SocketException catch (_) {
      return await _getCachedWeatherFallback();
    } catch (e) {
      final errString = e.toString();
      if (errString.contains('SocketException') || errString.contains('Failed host lookup') || errString.contains('ClientException')) {
        return await _getCachedWeatherFallback();
      }
      return ApiResultFailure(UnknownFailure('An unexpected error occurred: $e'));
    }
  }

  Future<ApiResult<WeatherEntity>> _getCachedWeatherFallback() async {
    try {
      final cachedWeather = await localDataSource.getLastWeather();
      if (cachedWeather != null) {
        return ApiResultSuccess(cachedWeather);
      } else {
        return const ApiResultFailure(NetworkFailure(
          'No internet connection and no cached weather data is available.',
        ));
      }
    } on CacheException catch (e) {
      return ApiResultFailure(CacheFailure(e.message));
    } catch (e) {
      return ApiResultFailure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<ApiResult<List<String>>> getRecentSearches() async {
    try {
      final list = await localDataSource.getRecentSearches();
      return ApiResultSuccess(list);
    } on CacheException catch (e) {
      return ApiResultFailure(CacheFailure(e.message));
    } catch (e) {
      return ApiResultFailure(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<ApiResult<void>> saveRecentSearch(String cityName) async {
    try {
      await localDataSource.saveRecentSearch(cityName);
      return const ApiResultSuccess(null);
    } on CacheException catch (e) {
      return ApiResultFailure(CacheFailure(e.message));
    } catch (e) {
      return ApiResultFailure(UnknownFailure(e.toString()));
    }
  }
}
