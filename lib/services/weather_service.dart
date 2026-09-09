import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:developer' as developer;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class WeatherService {
  static const _cachedWeatherKey = 'weather_cache';
  static const _cachedForecastKey = 'weather_forecast_cache';
  // Get current location
  Future<Position?> getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      developer.log('Error getting location', error: e, name: 'WeatherService');
      return null;
    }
  }

  // Get city name from coordinates
  Future<String> getCityName(double lat, double lon) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return '${place.locality}, ${place.administrativeArea}';
      }
      return 'Unknown Location';
    } catch (e) {
      return 'Unknown Location';
    }
  }

  // Get current weather
  Future<WeatherData?> getCurrentWeather() async {
    return null;
  }

  // Get weather forecast (5 days)
  Future<List<WeatherForecast>> getWeatherForecast() async {
    return const <WeatherForecast>[];
  }

  Future<void> cacheWeather(
    WeatherData weather,
    List<WeatherForecast> forecast,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cachedWeatherKey, jsonEncode(weather.toJson()));
    await prefs.setString(
      _cachedForecastKey,
      jsonEncode(forecast.map((item) => item.toJson()).toList()),
    );
    await saveCacheTimestamp();
  }

  Future<CachedWeather?> getCachedWeather() async {
    final prefs = await SharedPreferences.getInstance();
    final weatherJson = prefs.getString(_cachedWeatherKey);
    final forecastJson = prefs.getString(_cachedForecastKey);
    if (weatherJson == null || forecastJson == null) return null;
    try {
      final weather = WeatherData.fromCache(jsonDecode(weatherJson));
      final forecast = (jsonDecode(forecastJson) as List)
          .map((item) => WeatherForecast.fromCache(item))
          .toList();
      return CachedWeather(
        weather: weather,
        forecast: forecast,
        savedAt: DateTime.fromMillisecondsSinceEpoch(
          prefs.getInt('${_cachedWeatherKey}_timestamp') ?? 0,
        ),
      );
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  Future<void> saveCacheTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      '${_cachedWeatherKey}_timestamp',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  List<WeatherForecast> aggregateDailyForecasts(List<WeatherForecast> entries) {
    final byDay = <DateTime, List<WeatherForecast>>{};
    for (final entry in entries) {
      final day = DateTime(entry.date.year, entry.date.month, entry.date.day);
      byDay.putIfAbsent(day, () => []).add(entry);
    }
    return byDay.entries.map((day) {
      final values = day.value;
      final average =
          values.fold<double>(0, (sum, item) => sum + item.temperature) /
          values.length;
      return WeatherForecast(
        date: day.key,
        temperature: average,
        description: values.first.description,
      );
    }).toList();
  }

  // Generate weather alerts for farming
  List<WeatherAlert> generateFarmingAlerts(
    WeatherData weather,
    List<WeatherForecast> forecast,
  ) {
    List<WeatherAlert> alerts = [];

    // High temperature alert
    if (weather.temperature > 35) {
      alerts.add(
        WeatherAlert(
          title: 'High Temperature Alert',
          message:
              'Temperature is ${weather.temperature.round()}°C. Consider extra irrigation for crops.',
          severity: AlertSeverity.warning,
          icon: '🌡️',
          actionRequired: true,
        ),
      );
    }

    // Heavy rain alert
    if (weather.humidity > 80 &&
        weather.description.toLowerCase().contains('rain')) {
      alerts.add(
        WeatherAlert(
          title: 'Heavy Rain Expected',
          message:
              'High humidity (${weather.humidity}%) and rain predicted. Ensure proper drainage.',
          severity: AlertSeverity.urgent,
          icon: '🌧️',
          actionRequired: true,
        ),
      );
    }

    // Wind alert
    if (weather.windSpeed > 20) {
      alerts.add(
        WeatherAlert(
          title: 'Strong Wind Alert',
          message:
              'Wind speed ${weather.windSpeed} km/h. Secure lightweight crops and equipment.',
          severity: AlertSeverity.warning,
          icon: '💨',
          actionRequired: true,
        ),
      );
    }

    // Drought warning
    if (weather.humidity < 30 && weather.temperature > 30) {
      alerts.add(
        WeatherAlert(
          title: 'Drought Conditions',
          message:
              'Low humidity (${weather.humidity}%) and high temperature. Increase irrigation frequency.',
          severity: AlertSeverity.urgent,
          icon: '☀️',
          actionRequired: true,
        ),
      );
    }

    // Check forecast for upcoming alerts
    for (var day in forecast) {
      if (day.description.toLowerCase().contains('storm')) {
        alerts.add(
          WeatherAlert(
            title: 'Storm Warning',
            message:
                'Storm expected in next few days. Prepare crops and equipment.',
            severity: AlertSeverity.urgent,
            icon: '⛈️',
            actionRequired: true,
          ),
        );
        break;
      }
    }

    return alerts;
  }
}

// Data models
class WeatherData {
  final double temperature;
  final int humidity;
  final double windSpeed;
  final String description;
  final String cityName;
  final String icon;

  WeatherData({
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.description,
    required this.cityName,
    required this.icon,
  });

  Map<String, dynamic> toJson() => {
    'temperature': temperature,
    'humidity': humidity,
    'windSpeed': windSpeed,
    'description': description,
    'cityName': cityName,
    'icon': icon,
  };

  factory WeatherData.fromCache(dynamic json) {
    if (json is! Map) throw const FormatException('Invalid cached weather.');
    return WeatherData(
      temperature: (json['temperature'] as num).toDouble(),
      humidity: (json['humidity'] as num).toInt(),
      windSpeed: (json['windSpeed'] as num).toDouble(),
      description: json['description'] as String,
      cityName: json['cityName'] as String,
      icon: json['icon'] as String,
    );
  }

  factory WeatherData.fromJson(Map<String, dynamic> json, String cityName) {
    final main = json['main'];
    final wind = json['wind'];
    final weather = json['weather'];
    if (main is! Map || wind is! Map || weather is! List || weather.isEmpty) {
      throw const FormatException('Invalid weather response.');
    }
    final temperature = (main['temp'] as num?)?.toDouble();
    final humidity = main['humidity'] as num?;
    final windSpeed = (wind['speed'] as num?)?.toDouble();
    final description = weather.first is Map
        ? weather.first['description']
        : null;
    final icon = weather.first is Map ? weather.first['icon'] : null;
    if (temperature == null ||
        humidity == null ||
        windSpeed == null ||
        description is! String ||
        icon is! String) {
      throw const FormatException('Invalid weather values.');
    }
    return WeatherData(
      temperature: temperature,
      humidity: humidity.toInt(),
      windSpeed: windSpeed * 3.6,
      description: description,
      cityName: cityName,
      icon: icon,
    );
  }
}

class WeatherForecast {
  final DateTime date;
  final double temperature;
  final String description;

  WeatherForecast({
    required this.date,
    required this.temperature,
    required this.description,
  });

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'temperature': temperature,
    'description': description,
  };

  factory WeatherForecast.fromCache(dynamic json) {
    if (json is! Map) throw const FormatException('Invalid cached forecast.');
    return WeatherForecast(
      date: DateTime.parse(json['date'] as String),
      temperature: (json['temperature'] as num).toDouble(),
      description: json['description'] as String,
    );
  }

  factory WeatherForecast.fromJson(Map<String, dynamic> json) {
    final main = json['main'];
    final weather = json['weather'];
    final timestamp = json['dt'];
    if (main is! Map ||
        weather is! List ||
        weather.isEmpty ||
        timestamp is! num) {
      throw const FormatException('Invalid forecast response.');
    }
    final temperature = (main['temp'] as num?)?.toDouble();
    final description = weather.first is Map
        ? weather.first['description']
        : null;
    if (temperature == null || description is! String) {
      throw const FormatException('Invalid forecast values.');
    }
    return WeatherForecast(
      date: DateTime.fromMillisecondsSinceEpoch(timestamp.toInt() * 1000),
      temperature: temperature,
      description: description,
    );
  }
}

class CachedWeather {
  final WeatherData weather;
  final List<WeatherForecast> forecast;
  final DateTime savedAt;

  const CachedWeather({
    required this.weather,
    required this.forecast,
    required this.savedAt,
  });

  bool get isStale => DateTime.now().difference(savedAt).inHours >= 1;
}

class WeatherAlert {
  final String title;
  final String message;
  final AlertSeverity severity;
  final String icon;
  final bool actionRequired;

  WeatherAlert({
    required this.title,
    required this.message,
    required this.severity,
    required this.icon,
    required this.actionRequired,
  });
}

enum AlertSeverity { info, warning, urgent }
