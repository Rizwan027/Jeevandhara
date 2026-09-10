import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:jeevandhara/services/soil_data_service.dart';
import 'package:jeevandhara/services/weather_service.dart';
import 'package:jeevandhara/services/ai_service.dart';
import 'package:jeevandhara/localization/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

    test('stores data per user and clears its timestamp', () async {
      SharedPreferences.setMockInitialValues({});
      final soilData = {
        'ph': 6.5,
        'moisture': 65.0,
        'temperature': 28.0,
        'nitrogen': 78.0,
        'phosphorus': 82.0,
        'potassium': 71.0,
      };

      await SoilDataService.saveSoilData(soilData, userId: 'user-a');

      expect(await SoilDataService.getSoilData(userId: 'user-a'), soilData);
      expect(await SoilDataService.getSoilData(userId: 'user-b'), isNull);
      expect(await SoilDataService.getLastUpdated(userId: 'user-a'), isNotNull);

      await SoilDataService.clearSoilData(userId: 'user-a');
      expect(await SoilDataService.getSoilData(userId: 'user-a'), isNull);
      expect(await SoilDataService.getLastUpdated(userId: 'user-a'), isNull);
    });
  });

  test('crop diagnosis remains explicitly unavailable', () async {
    final result = await AIService().analyzePlantHealth('plant.jpg');

    expect(result['unavailable'], isTrue);
    expect(result['error'], isTrue);
    expect(result['confidence'], 0.0);
  });

  test(
    'crop recommendations use an explicit fallback when AI is unavailable',
    () async {
      final recommendation = await AIService().getCropRecommendations(
        soilData: {
          'ph': 6.5,
          'moisture': 65.0,
          'temperature': 28.0,
          'nitrogen': 78.0,
          'phosphorus': 82.0,
          'potassium': 71.0,
        },
        weatherData: {
          'temperature': 28.0,
          'humidity': 65,
          'description': 'Clear',
        },
      );

      expect(recommendation.recommendedCrops, isNotEmpty);
      expect(recommendation.aiRecommendation, contains('Fallback'));
    },
  );

  group('Weather models', () {
    test(
      'does not fabricate weather without runtime API configuration',
      () async {
        final weather = await WeatherService().getCurrentWeather();
        expect(weather, isNull);
      },
    );

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

  test('supported locales provide core localized labels', () async {
    for (final language in ['en', 'hi', 'mr', 'te', 'ta', 'bn']) {
      final localization = await AppLocalizations.delegate.load(
        Locale(language),
      );
      expect(localization.getText('home'), isNot('home'));
      expect(
        localization.getText('weather_forecast'),
        isNot('weather_forecast'),
      );
    }
  });
}
