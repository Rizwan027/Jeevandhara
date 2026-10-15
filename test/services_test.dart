import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:jeevandhara/services/soil_data_service.dart';
import 'package:jeevandhara/services/weather_service.dart';
import 'package:jeevandhara/services/ai_service.dart';
import 'package:jeevandhara/services/market_data_service.dart';
import 'package:jeevandhara/models/crop_diagnosis_result.dart';
import 'package:jeevandhara/localization/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    dotenv.testLoad(fileInput: '');
  });
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

  group('MarketDataService mapping', () {
    test('maps ML crop names to AGMARKNET taxonomy correctly', () {
      expect(MarketDataService.mapCommodityName('Chickpea'), 'Gram');
      expect(
        MarketDataService.mapCommodityName('Pigeonpeas'),
        'Arhar (Tur/Red Gram)(Whole)',
      );
      expect(
        MarketDataService.mapCommodityName('Blackgram'),
        'Black Gram (Urd Beans)(Whole)',
      );
      expect(
        MarketDataService.mapCommodityName('Mungbean'),
        'Green Gram (Moong)(Whole)',
      );
      expect(MarketDataService.mapCommodityName('Kidneybeans'), 'Rajmah');
      expect(
        MarketDataService.mapCommodityName('Muskmelon'),
        'Karbuja(Musk Melon)',
      );
    });

    test('passes direct matches through correctly', () {
      expect(MarketDataService.mapCommodityName('Wheat'), 'Wheat');
      expect(MarketDataService.mapCommodityName('Rice'), 'Rice');
      expect(MarketDataService.mapCommodityName('Cotton'), 'Cotton');
      expect(MarketDataService.mapCommodityName('Mustard'), 'Mustard');
      expect(MarketDataService.mapCommodityName('Maize'), 'Maize');
    });

    test('handles case-insensitivity and whitespace safety', () {
      expect(MarketDataService.mapCommodityName('  chickpea  '), 'Gram');
      expect(
        MarketDataService.mapCommodityName('PIGEONPEAS'),
        'Arhar (Tur/Red Gram)(Whole)',
      );
    });

    test('leaves unknown crop names unchanged', () {
      expect(MarketDataService.mapCommodityName('Dragonfruit'), 'Dragonfruit');
    });
  });

  group('CropDiagnosisResult', () {
    test('unavailable and unsupported results have no prediction fields', () {
      final results = {
        CropDiagnosisStatus.unavailable:
            const CropDiagnosisResult.unavailable(),
        CropDiagnosisStatus.unsupported:
            const CropDiagnosisResult.unsupported(),
      };
      for (final entry in results.entries) {
        final result = entry.value;
        expect(result.status, entry.key);
        expect(result.toLegacyMap()['diagnosis_status'], entry.key.name);
        expect(result.cropLabel, isNull);
        expect(result.diseaseLabel, isNull);
        expect(result.confidence, isNull);
      }
    });

    test('uncertain results allow only meaningful optional fields', () {
      final result = CropDiagnosisResult.uncertain(
        cropLabel: 'Rice',
        confidence: 0.4,
      );

      expect(result.status, CropDiagnosisStatus.uncertain);
      expect(result.toLegacyMap()['diagnosis_status'], 'uncertain');
      expect(result.cropLabel, 'Rice');
      expect(result.diseaseLabel, isNull);
      expect(result.confidence, 0.4);
    });

    test('diagnosis requires labels and finite probability confidence', () {
      final result = CropDiagnosisResult.diagnosis(
        cropLabel: 'Rice',
        diseaseLabel: 'Supported class',
        confidence: 0.9,
      );

      expect(result.status, CropDiagnosisStatus.diagnosis);
      expect(result.toLegacyMap()['diagnosis_status'], 'diagnosis');
      expect(result.cropLabel, 'Rice');
      expect(result.diseaseLabel, 'Supported class');
      expect(result.confidence, 0.9);
      expect(
        () => CropDiagnosisResult.diagnosis(
          cropLabel: 'Rice',
          diseaseLabel: 'Supported class',
          confidence: double.nan,
        ),
        throwsArgumentError,
      );
    });

    test('AIService remains unavailable in the legacy result format', () async {
      final result = await AIService().analyzePlantHealth('plant.jpg');

      expect(result['unavailable'], isTrue);
      expect(result['error'], isTrue);
      expect(result['confidence'], isNull);
      expect(result['crop_type'], isNull);
      expect(result['disease'], isNull);
      expect(
        result['status'],
        'Crop diagnosis is unavailable in this version.',
      );
      expect(result['diagnosis_status'], 'unavailable');
    });
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
      'missing weather stays unavailable instead of becoming inputs',
      () async {
        SharedPreferences.setMockInitialValues({});
        final observation = await WeatherService().getWeatherObservation();

        expect(observation.source, WeatherObservationSource.unavailable);
        expect(observation.weather, isNull);
        expect(observation.recommendationInputs, isNull);
      },
    );

    test(
      'cached weather is identified and supplies only observed inputs',
      () async {
        SharedPreferences.setMockInitialValues({});
        final service = WeatherService();
        await service.cacheWeather(
          WeatherData(
            temperature: 28,
            humidity: 65,
            windSpeed: 10.8,
            description: 'clear sky',
            cityName: 'Pune',
            icon: '01d',
          ),
          const [],
        );

        final observation = await service.getWeatherObservation();

        expect(observation.source, WeatherObservationSource.cached);
        expect(observation.recommendationInputs, {
          'temperature': 28.0,
          'humidity': 65.0,
        });
      },
    );

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
