import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:weather_app/features/weather/data/models/weather_model.dart';

abstract class WeatherRemoteDataSource {
  Future<WeatherModel> getWeather(String cityName);
}

class WeatherRemoteDataSourceImpl implements WeatherRemoteDataSource {
  final http.Client client;
  
  // Use --dart-define=WEATHER_API_KEY=xxx
  static const String apiKey = String.fromEnvironment('WEATHER_API_KEY');

  WeatherRemoteDataSourceImpl({required this.client});

  @override
  Future<WeatherModel> getWeather(String cityName) async {
    if (apiKey.isEmpty) {
      throw const ServerException('API Key is missing. Please run with --dart-define=WEATHER_API_KEY=your_key');
    }

    final encodedCity = Uri.encodeComponent(cityName);
    final url = Uri.parse('https://api.weatherapi.com/v1/current.json?key=$apiKey&q=$encodedCity');

    final response = await client.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonMap = json.decode(response.body);
      return WeatherModel.fromJson(jsonMap);
    } else {
      // Parse WeatherAPI error details
      try {
        final Map<String, dynamic> errorJson = json.decode(response.body);
        final errorDetail = errorJson['error'];
        if (errorDetail != null) {
          final int code = errorDetail['code'] as int? ?? 0;
          final String message = errorDetail['message'] as String? ?? 'Server returned error';
          
          if (code == 1006) {
            throw InvalidCityException(message);
          } else {
            throw ServerException(message);
          }
        }
      } catch (e) {
        if (e is InvalidCityException || e is ServerException) {
          rethrow;
        }
      }
      throw ServerException('Failed to fetch weather: ${response.statusCode} ${response.reasonPhrase}');
    }
  }
}

// Exception classes for Data Layer
class ServerException implements Exception {
  final String message;
  const ServerException(this.message);
  
  @override
  String toString() => message;
}

class InvalidCityException implements Exception {
  final String message;
  const InvalidCityException(this.message);

  @override
  String toString() => message;
}
