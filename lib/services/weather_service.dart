import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:developer' as developer;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class WeatherService {
  static String get _apiKey => dotenv.env['OPENWEATHER_API_KEY']?.trim() ?? '';
  static const _baseUrl = 'https://api.openweathermap.org/data/2.5';
  static const _cachedWeatherKey = 'weather_cache';
  static const _cachedForecastKey = 'weather_forecast_cache';
  static const _cachedLatitudeKey = 'weather_location_latitude';
  static const _cachedLongitudeKey = 'weather_location_longitude';
  // Get current location
  Future<Position?> getCurrentLocation() async {
    try {
      developer.log('[WEATHER] permission status check', name: 'Weather');
      if (!await Geolocator.isLocationServiceEnabled()) {
        developer.log('[WEATHER] location service disabled', name: 'Weather');
        return _getCachedLocation();
      }
      LocationPermission permission = await Geolocator.checkPermission();
      developer.log(
        '[WEATHER] permission status: $permission',
        name: 'Weather',
      );
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        developer.log(
          '[WEATHER] permission status after request: $permission',
          name: 'Weather',
        );
        if (permission == LocationPermission.denied) {
          return _getCachedLocation();
        }
      }

      if (permission == LocationPermission.deniedForever) {
        developer.log('[WEATHER] permission denied forever', name: 'Weather');
        return _getCachedLocation();
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
      if (!_validCoordinates(position.latitude, position.longitude)) {
        developer.log(
          '[WEATHER] invalid coordinates: ${position.latitude}, ${position.longitude}',
          name: 'Weather',
        );
        return _getCachedLocation();
      }
      developer.log(
        '[WEATHER] coordinates: ${position.latitude}, ${position.longitude}',
        name: 'Weather',
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_cachedLatitudeKey, position.latitude);
      await prefs.setDouble(_cachedLongitudeKey, position.longitude);
      return position;
    } catch (e) {
      developer.log('[WEATHER] location error', error: e, name: 'Weather');
      return _getCachedLocation();
    }
  }

  Future<Position?> _getCachedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final latitude = prefs.getDouble(_cachedLatitudeKey);
    final longitude = prefs.getDouble(_cachedLongitudeKey);
    if (latitude == null ||
        longitude == null ||
        !_validCoordinates(latitude, longitude)) {
      developer.log('[WEATHER] no valid cached coordinates', name: 'Weather');
      return null;
    }
    developer.log(
      '[WEATHER] using cached coordinates: $latitude, $longitude',
      name: 'Weather',
    );
    return Position(
      longitude: longitude,
      latitude: latitude,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }

  // Get city name from coordinates
  Future<String> getCityName(double lat, double lon) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        lat,
        lon,
      ).timeout(const Duration(seconds: 10));
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final locality = place.locality ?? place.subAdministrativeArea;
        final area = place.administrativeArea;
        final name = [
          locality,
          area,
        ].whereType<String>().where((value) => value.isNotEmpty).join(', ');
        developer.log('[WEATHER] location name: $name', name: 'Weather');
        return name.isEmpty ? 'Unknown Location' : name;
      }
      return 'Unknown Location';
    } catch (e) {
      developer.log(
        '[WEATHER] geocoding failed; continuing without city name',
        error: e,
        name: 'Weather',
      );
      return 'Unknown Location';
    }
  }

  // Get current weather
  Future<WeatherData?> getCurrentWeather() async {
    if (_apiKey.isEmpty) {
      developer.log(
        '[WEATHER] API key unavailable; pass --dart-define=OPENWEATHER_API_KEY=...',
        name: 'Weather',
      );
      return null;
    }
    developer.log('[WEATHER] request started', name: 'Weather');
    final position = await getCurrentLocation();
    if (position == null) return null;
    final cityName = await getCityName(position.latitude, position.longitude);
    final uri = Uri.parse('$_baseUrl/weather').replace(
      queryParameters: {
        'lat': '${position.latitude}',
        'lon': '${position.longitude}',
        'appid': _apiKey,
        'units': 'metric',
      },
    );
    try {
      developer.log(
        '[WEATHER] API request started: ${uri.replace(queryParameters: {...uri.queryParameters, 'appid': '<redacted>'})}',
        name: 'Weather',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      developer.log(
        '[WEATHER] HTTP status: ${response.statusCode}',
        name: 'Weather',
      );
      if (response.statusCode != 200) {
        developer.log('[WEATHER] API error response', name: 'Weather');
        return null;
      }
      final weather = WeatherData.fromJson(jsonDecode(response.body), cityName);
      developer.log('[WEATHER] parsing succeeded', name: 'Weather');
      final cached = await getCachedWeather();
      await cacheWeather(weather, cached?.forecast ?? const []);
      developer.log('[WEATHER] cache updated', name: 'Weather');
      return weather;
    } catch (e) {
      developer.log(
        '[WEATHER] current weather error',
        error: e,
        name: 'Weather',
      );
      return null;
    }
  }

  Future<WeatherObservation> getWeatherObservation() async {
    final current = await getCurrentWeather();
    if (current != null) return WeatherObservation.live(current);

    final cached = await getCachedWeather();
    if (cached != null) return WeatherObservation.cached(cached);

    return const WeatherObservation.unavailable();
  }

  // Get weather forecast (5 days)
  Future<List<WeatherForecast>> getWeatherForecast() async {
    if (_apiKey.isEmpty) return const <WeatherForecast>[];
    final position = await getCurrentLocation();
    if (position == null) return const <WeatherForecast>[];
    final uri = Uri.parse('$_baseUrl/forecast').replace(
      queryParameters: {
        'lat': '${position.latitude}',
        'lon': '${position.longitude}',
        'appid': _apiKey,
        'units': 'metric',
      },
    );
    try {
      developer.log('[WEATHER] forecast API request started', name: 'Weather');
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      developer.log(
        '[WEATHER] forecast HTTP status: ${response.statusCode}',
        name: 'Weather',
      );
      if (response.statusCode != 200) return const <WeatherForecast>[];
      final body = jsonDecode(response.body);
      if (body is! Map || body['list'] is! List) {
        throw const FormatException('Invalid forecast response.');
      }
      final entries = (body['list'] as List)
          .whereType<Map>()
          .map(
            (item) => WeatherForecast.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
      final forecast = aggregateDailyForecasts(entries).take(5).toList();
      developer.log(
        '[WEATHER] forecast parsing succeeded: ${forecast.length} days',
        name: 'Weather',
      );
      final cached = await getCachedWeather();
      if (cached != null) await cacheWeather(cached.weather, forecast);
      return forecast;
    } catch (e) {
      developer.log('[WEATHER] forecast error', error: e, name: 'Weather');
      return const <WeatherForecast>[];
    }
  }

  static bool _validCoordinates(double latitude, double longitude) =>
      latitude.isFinite &&
      longitude.isFinite &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;

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

enum WeatherObservationSource { live, cached, unavailable }

class WeatherObservation {
  final WeatherObservationSource source;
  final WeatherData? weather;
  final bool isStale;

  const WeatherObservation.live(WeatherData weather)
    : source = WeatherObservationSource.live,
      weather = weather,
      isStale = false;

  WeatherObservation.cached(CachedWeather cached)
    : source = WeatherObservationSource.cached,
      weather = cached.weather,
      isStale = cached.isStale;

  const WeatherObservation.unavailable()
    : source = WeatherObservationSource.unavailable,
      weather = null,
      isStale = false;

  Map<String, double>? get recommendationInputs {
    final observation = weather;
    if (observation == null) return null;
    return {
      'temperature': observation.temperature,
      'humidity': observation.humidity.toDouble(),
    };
  }
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
