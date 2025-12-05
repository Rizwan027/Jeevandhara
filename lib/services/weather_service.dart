import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class WeatherService {
  static const String _apiKey =
      '9504d3db9f8d098b58292d89bd29f882'; // Replace with your OpenWeatherMap API key
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';

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
      print('Error getting location: $e');
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
    try {
      final position = await getCurrentLocation();
      if (position == null) {
        return _getFallbackWeather();
      }

      final url =
          '$_baseUrl/weather?lat=${position.latitude}&lon=${position.longitude}&appid=$_apiKey&units=metric';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final cityName = await getCityName(
          position.latitude,
          position.longitude,
        );

        return WeatherData.fromJson(data, cityName);
      } else {
        return _getFallbackWeather();
      }
    } catch (e) {
      print('Weather API Error: $e');
      return _getFallbackWeather();
    }
  }

  // Get weather forecast (5 days)
  Future<List<WeatherForecast>> getWeatherForecast() async {
    try {
      final position = await getCurrentLocation();
      if (position == null) {
        return _getFallbackForecast();
      }

      final url =
          '$_baseUrl/forecast?lat=${position.latitude}&lon=${position.longitude}&appid=$_apiKey&units=metric';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> forecasts = data['list'];

        return forecasts
            .take(5)
            .map((forecast) => WeatherForecast.fromJson(forecast))
            .toList();
      } else {
        return _getFallbackForecast();
      }
    } catch (e) {
      print('Forecast API Error: $e');
      return _getFallbackForecast();
    }
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

  // Fallback data when API is unavailable
  WeatherData _getFallbackWeather() {
    return WeatherData(
      temperature: 28.0,
      humidity: 65,
      windSpeed: 12.0,
      description: 'Partly Cloudy',
      cityName: 'Your Location',
      icon: '02d',
    );
  }

  List<WeatherForecast> _getFallbackForecast() {
    return [
      WeatherForecast(
        date: DateTime.now().add(const Duration(days: 1)),
        temperature: 29.0,
        description: 'Sunny',
      ),
      WeatherForecast(
        date: DateTime.now().add(const Duration(days: 2)),
        temperature: 26.0,
        description: 'Light Rain',
      ),
      WeatherForecast(
        date: DateTime.now().add(const Duration(days: 3)),
        temperature: 31.0,
        description: 'Partly Cloudy',
      ),
      WeatherForecast(
        date: DateTime.now().add(const Duration(days: 4)),
        temperature: 28.0,
        description: 'Cloudy',
      ),
      WeatherForecast(
        date: DateTime.now().add(const Duration(days: 5)),
        temperature: 30.0,
        description: 'Sunny',
      ),
    ];
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

  factory WeatherData.fromJson(Map<String, dynamic> json, String cityName) {
    return WeatherData(
      temperature: json['main']['temp'].toDouble(),
      humidity: json['main']['humidity'],
      windSpeed: json['wind']['speed'].toDouble() * 3.6, // Convert m/s to km/h
      description: json['weather'][0]['description'],
      cityName: cityName,
      icon: json['weather'][0]['icon'],
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

  factory WeatherForecast.fromJson(Map<String, dynamic> json) {
    return WeatherForecast(
      date: DateTime.fromMillisecondsSinceEpoch(json['dt'] * 1000),
      temperature: json['main']['temp'].toDouble(),
      description: json['weather'][0]['description'],
    );
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
