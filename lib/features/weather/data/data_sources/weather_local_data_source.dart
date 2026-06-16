import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather_app/features/weather/data/models/weather_model.dart';

abstract class WeatherLocalDataSource {
  Future<WeatherModel?> getLastWeather();
  Future<void> cacheWeather(WeatherModel weather);
  Future<List<String>> getRecentSearches();
  Future<void> saveRecentSearch(String cityName);
}

class WeatherLocalDataSourceImpl implements WeatherLocalDataSource {
  final SharedPreferences sharedPreferences;

  static const String _keyLastWeather = 'CACHED_WEATHER';
  static const String _keyRecentSearches = 'RECENT_SEARCHES';

  WeatherLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<WeatherModel?> getLastWeather() async {
    final jsonString = sharedPreferences.getString(_keyLastWeather);
    if (jsonString != null) {
      try {
        final Map<String, dynamic> jsonMap = json.decode(jsonString);
        return WeatherModel.fromLocalJson(jsonMap);
      } catch (_) {
        throw const CacheException('Failed to parse cached weather data.');
      }
    }
    return null;
  }

  @override
  Future<void> cacheWeather(WeatherModel weather) async {
    final jsonString = json.encode(weather.toJson());
    final success = await sharedPreferences.setString(_keyLastWeather, jsonString);
    if (!success) {
      throw const CacheException('Failed to write weather to local cache.');
    }
  }

  @override
  Future<List<String>> getRecentSearches() async {
    final list = sharedPreferences.getStringList(_keyRecentSearches);
    return list ?? [];
  }

  @override
  Future<void> saveRecentSearch(String cityName) async {
    // Standardize casing to sentence case or trimmed representation
    final trimmed = cityName.trim();
    if (trimmed.isEmpty) return;

    // Fetch existing searches
    final currentSearches = await getRecentSearches();
    
    // Create new list without duplicates (case-insensitive check, but retain user's input case if unique)
    final newList = <String>[];
    
    // Insert new city at front
    newList.add(trimmed);
    
    for (final search in currentSearches) {
      if (search.toLowerCase() != trimmed.toLowerCase()) {
        newList.add(search);
      }
    }

    // Keep only the last 10 searches
    if (newList.length > 10) {
      newList.removeRange(10, newList.length);
    }

    final success = await sharedPreferences.setStringList(_keyRecentSearches, newList);
    if (!success) {
      throw const CacheException('Failed to save search history.');
    }
  }
}

class CacheException implements Exception {
  final String message;
  const CacheException(this.message);

  @override
  String toString() => message;
}
