import 'package:flutter_test/flutter_test.dart';
import 'package:jeevandhara/services/soil_data_service.dart';
import 'package:jeevandhara/services/weather_service.dart';

void main() {
  group('SoilDataService', () {
    test('accepts valid soil data', () {
      final data = SoilDataService.validateSoilData({
        'ph': 6.5,
        'moisture': 65,
        'temperature': 28,
        'nitrogen': 78,
        'phosphorus': 82,
        'potassium': 71,
      });
      expect(data['ph'], 6.5);
    });

    test('rejects missing, non-finite, and out-of-range values', () {
      expect(
        () => SoilDataService.validateSoilData({
          'ph': 6.5,
          'moisture': double.nan,
          'temperature': 28,
          'nitrogen': 78,
          'phosphorus': 82,
          'potassium': 71,
        }),
        throwsArgumentError,
      );
      expect(
        () => SoilDataService.validateSoilData({
          'ph': 10,
          'moisture': 65,
          'temperature': 28,
          'nitrogen': 78,
          'phosphorus': 82,
          'potassium': 71,
        }),
        throwsArgumentError,
      );
    });
  });

  group('Weather models', () {
    test('parses valid current weather', () {
      final weather = WeatherData.fromJson({
        'main': {'temp': 28, 'humidity': 65},
        'wind': {'speed': 3},
        'weather': [
          {'description': 'clear sky', 'icon': '01d'},
        ],
      }, 'Pune');
      expect(weather.temperature, 28);
      expect(weather.windSpeed, closeTo(10.8, 0.001));
    });

    test('rejects malformed weather responses', () {
      expect(() => WeatherData.fromJson({}, 'Pune'), throwsFormatException);
    });
  });

  test('aggregates forecast entries by calendar day', () {
    final service = WeatherService();
    final aggregated = service.aggregateDailyForecasts([
      WeatherForecast(
        date: DateTime(2026, 1, 2, 9),
        temperature: 20,
        description: 'clear sky',
      ),
      WeatherForecast(
        date: DateTime(2026, 1, 2, 15),
        temperature: 30,
        description: 'cloudy',
      ),
    ]);
    expect(aggregated, hasLength(1));
    expect(aggregated.single.temperature, 25);
    expect(aggregated.single.date, DateTime(2026, 1, 2));
  });
}
