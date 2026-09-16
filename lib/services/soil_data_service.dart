import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SoilDataService {
  static const Map<String, List<double>> _ranges = {
    'ph': [4, 9],
    'moisture': [0, 100],
    'nitrogen': [0, 100],
    'phosphorus': [0, 100],
    'potassium': [0, 100],
  };

  static Map<String, double> validateSoilData(Map<String, double> soilData) {
    for (final entry in _ranges.entries) {
      final value = soilData[entry.key];
      if (value == null || !value.isFinite) {
        throw ArgumentError('Invalid ${entry.key} value.');
      }
      if (value < entry.value[0] || value > entry.value[1]) {
        throw ArgumentError(
          '${entry.key} must be between ${entry.value[0]} and ${entry.value[1]}.',
        );
      }
    }
    return Map<String, double>.from(soilData);
  }

  static String _soilDataKey(String userId) => 'soil_data_$userId';
  static String _lastUpdatedKey(String userId) =>
      'soil_data_last_updated_$userId';

  // Save soil data
  static Future<void> saveSoilData(
    Map<String, double> soilData, {
    required String userId,
  }) async {
    final validatedData = validateSoilData(soilData);
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(validatedData);
    await prefs.setString(_soilDataKey(userId), jsonString);
    await prefs.setString(
      _lastUpdatedKey(userId),
      DateTime.now().toIso8601String(),
    );
  }

  // Get saved soil data
  static Future<Map<String, double>?> getSoilData({
    required String userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_soilDataKey(userId));

    if (jsonString != null) {
      try {
        final decoded = json.decode(jsonString);
        if (decoded is! Map) return null;
        return decoded.map<String, double>((key, value) {
          final number = value is num
              ? value.toDouble()
              : double.parse(value.toString());
          return MapEntry(key.toString(), number);
        });
      } on FormatException {
        return null;
      }
    }

    return null;
  }

  // Check if soil data exists
  static Future<bool> hasSoilData({required String userId}) async {
    final soilData = await getSoilData(userId: userId);
    return soilData != null;
  }

  // Get last updated timestamp
  static Future<DateTime?> getLastUpdated({required String userId}) async {
    final prefs = await SharedPreferences.getInstance();
    final dateString = prefs.getString(_lastUpdatedKey(userId));

    if (dateString != null) {
      try {
        return DateTime.parse(dateString);
      } on FormatException {
        return null;
      }
    }

    return null;
  }

  // Clear soil data
  static Future<void> clearSoilData({required String userId}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_soilDataKey(userId));
    await prefs.remove(_lastUpdatedKey(userId));
  }

  // Check if data is recent (within last 30 days)
  static Future<bool> isDataRecent({required String userId}) async {
    final lastUpdated = await getLastUpdated(userId: userId);
    if (lastUpdated == null) return false;

    final now = DateTime.now();
    final difference = now.difference(lastUpdated).inDays;
    return difference <= 30;
  }
}
