import 'dart:io';
import 'package:http/http.dart' as http;
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
      return await _fetchAndCacheWeather(cityName);
    } on InvalidCityException catch (e) {
      return ApiResultFailure(InvalidInputFailure(e.message));
    } on ServerException catch (e) {
      return ApiResultFailure(ServerFailure(e.message));
    } on SocketException catch (_) {
      // Direct SocketException (rare — http package usually wraps these)
      return await _getCachedWeatherFallback();
    } on http.ClientException catch (_) {
      // The http package wraps all transport errors (including SocketException)
      // inside ClientException. This can fire for transient hiccups (DNS delay,
      // connection reset) even when the device IS online.
      // Retry once before assuming the device is offline.
      return await _retryOrFallback(cityName);
    } catch (e) {
      return ApiResultFailure(UnknownFailure('An unexpected error occurred: $e'));
    }
  }

  /// Fetches weather from remote API and caches the result locally.
  Future<ApiResult<WeatherEntity>> _fetchAndCacheWeather(String cityName) async {
    final remoteWeather = await remoteDataSource.getWeather(cityName);
    await localDataSource.cacheWeather(remoteWeather);
    return ApiResultSuccess(remoteWeather);
  }

  /// Retries a single fetch after a brief delay to handle transient network
  /// hiccups (e.g., DNS not ready at startup, brief connection reset).
  /// Only falls back to cache if the retry also fails.
  Future<ApiResult<WeatherEntity>> _retryOrFallback(String cityName) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      return await _fetchAndCacheWeather(cityName);
    } on InvalidCityException catch (e) {
      return ApiResultFailure(InvalidInputFailure(e.message));
    } on ServerException catch (e) {
      return ApiResultFailure(ServerFailure(e.message));
    } catch (_) {
      // Retry also failed — device is likely truly offline
      return await _getCachedWeatherFallback();
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
  Future<ApiResult<WeatherEntity?>> getLastCachedWeather() async {
    try {
      final cachedWeather = await localDataSource.getLastWeather();
      return ApiResultSuccess(cachedWeather);
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
