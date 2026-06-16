import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/features/weather/data/models/weather_model.dart';

void main() {
  group('WeatherModel.fromJson', () {
    test('should parse a valid API response correctly', () {
      // Arrange
      final json = {
        'location': {'name': 'London'},
        'current': {
          'temp_c': 15.5,
          'condition': {
            'text': 'Partly cloudy',
            'icon': '//cdn.weatherapi.com/weather/64x64/day/116.png',
          },
          'humidity': 72,
          'wind_kph': 18.4,
          'last_updated': '2026-06-16 14:30',
        },
      };

      // Act
      final model = WeatherModel.fromJson(json);

      // Assert
      expect(model.cityName, 'London');
      expect(model.temperatureCelsius, 15.5);
      expect(model.conditionText, 'Partly cloudy');
      expect(model.conditionIconUrl, '//cdn.weatherapi.com/weather/64x64/day/116.png');
      expect(model.humidity, 72);
      expect(model.windKph, 18.4);
      expect(model.isCached, false);
    });

    test('should handle integer temperature and wind values', () {
      // Arrange — WeatherAPI sometimes returns int instead of double
      final json = {
        'location': {'name': 'Dubai'},
        'current': {
          'temp_c': 42,
          'condition': {'text': 'Sunny', 'icon': '//icon.png'},
          'humidity': 20,
          'wind_kph': 10,
          'last_updated': '2026-06-16 12:00',
        },
      };

      // Act
      final model = WeatherModel.fromJson(json);

      // Assert
      expect(model.temperatureCelsius, 42.0);
      expect(model.windKph, 10.0);
      expect(model.temperatureCelsius, isA<double>());
      expect(model.windKph, isA<double>());
    });

    test('should use defaults when fields are null or missing', () {
      // Arrange — minimal/empty response
      final json = <String, dynamic>{};

      // Act
      final model = WeatherModel.fromJson(json);

      // Assert
      expect(model.cityName, '');
      expect(model.temperatureCelsius, 0.0);
      expect(model.conditionText, 'Unknown');
      expect(model.conditionIconUrl, '');
      expect(model.humidity, 0);
      expect(model.windKph, 0.0);
    });

    test('should handle null last_updated gracefully', () {
      // Arrange
      final json = {
        'location': {'name': 'Test'},
        'current': {
          'temp_c': 20.0,
          'condition': {'text': 'Clear'},
          'humidity': 50,
          'wind_kph': 5.0,
          'last_updated': null,
        },
      };

      // Act
      final model = WeatherModel.fromJson(json);

      // Assert — should not throw, should use DateTime.now() fallback
      expect(model.lastUpdated, isNotNull);
      expect(model.cityName, 'Test');
    });

    test('should handle malformed last_updated string gracefully', () {
      // Arrange
      final json = {
        'location': {'name': 'Test'},
        'current': {
          'temp_c': 20.0,
          'condition': {'text': 'Clear'},
          'humidity': 50,
          'wind_kph': 5.0,
          'last_updated': 'not-a-valid-date',
        },
      };

      // Act
      final model = WeatherModel.fromJson(json);

      // Assert — should fall back to DateTime.now() without throwing
      expect(model.lastUpdated, isNotNull);
    });
  });

  group('WeatherModel.fromLocalJson', () {
    test('should parse cached local JSON correctly with isCached = true', () {
      // Arrange
      final json = {
        'cityName': 'Cairo',
        'temperatureCelsius': 32.5,
        'conditionText': 'Sunny',
        'conditionIconUrl': '//icon.png',
        'humidity': 35,
        'windKph': 12.0,
        'lastUpdated': '2026-06-16T10:00:00.000',
      };

      // Act
      final model = WeatherModel.fromLocalJson(json);

      // Assert
      expect(model.cityName, 'Cairo');
      expect(model.temperatureCelsius, 32.5);
      expect(model.isCached, true); // Always true for local cache
      expect(model.lastUpdated, DateTime(2026, 6, 16, 10, 0, 0));
    });

    test('should handle numeric types as num correctly', () {
      // Arrange — JSON decode can produce int or double depending on the value
      final json = {
        'cityName': 'Berlin',
        'temperatureCelsius': 18,
        'conditionText': 'Overcast',
        'conditionIconUrl': '',
        'humidity': 65,
        'windKph': 8,
        'lastUpdated': '2026-06-16T08:00:00.000',
      };

      // Act
      final model = WeatherModel.fromLocalJson(json);

      // Assert
      expect(model.temperatureCelsius, 18.0);
      expect(model.windKph, 8.0);
    });
  });

  group('WeatherModel.toJson', () {
    test('should serialize to JSON and round-trip correctly', () {
      // Arrange
      final original = WeatherModel(
        cityName: 'Tokyo',
        temperatureCelsius: 25.3,
        conditionText: 'Rain',
        conditionIconUrl: '//cdn.weatherapi.com/rain.png',
        humidity: 85,
        windKph: 22.1,
        lastUpdated: DateTime(2026, 6, 16, 14, 30),
        isCached: false,
      );

      // Act
      final json = original.toJson();
      final restored = WeatherModel.fromLocalJson(json);

      // Assert — round-trip preserves data
      expect(restored.cityName, original.cityName);
      expect(restored.temperatureCelsius, original.temperatureCelsius);
      expect(restored.conditionText, original.conditionText);
      expect(restored.conditionIconUrl, original.conditionIconUrl);
      expect(restored.humidity, original.humidity);
      expect(restored.windKph, original.windKph);
      expect(restored.lastUpdated, original.lastUpdated);
      expect(restored.isCached, true); // fromLocalJson always sets isCached = true
    });
  });
}
