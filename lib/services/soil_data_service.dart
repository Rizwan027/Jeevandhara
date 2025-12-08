import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SoilDataService {
  static const String _soilDataKey = 'soil_data';
  static const String _lastUpdatedKey = 'soil_data_last_updated';

  // Save soil data
  static Future<void> saveSoilData(Map<String, double> soilData) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(soilData);
    await prefs.setString(_soilDataKey, jsonString);
    await prefs.setString(_lastUpdatedKey, DateTime.now().toIso8601String());
  }

  // Get saved soil data
  static Future<Map<String, double>?> getSoilData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_soilDataKey);
    
    if (jsonString != null) {
      final Map<String, dynamic> decoded = json.decode(jsonString);
      return decoded.map((key, value) => MapEntry(key, value.toDouble()));
    }
    
    return null;
  }

  // Check if soil data exists
  static Future<bool> hasSoilData() async {
    final soilData = await getSoilData();
    return soilData != null;
  }

  // Get last updated timestamp
  static Future<DateTime?> getLastUpdated() async {
    final prefs = await SharedPreferences.getInstance();
    final dateString = prefs.getString(_lastUpdatedKey);
    
    if (dateString != null) {
      return DateTime.parse(dateString);
    }
    
    return null;
  }

  // Clear soil data
  static Future<void> clearSoilData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_soilDataKey);
    await prefs.remove(_lastUpdatedKey);
  }

  // Check if data is recent (within last 30 days)
  static Future<bool> isDataRecent() async {
    final lastUpdated = await getLastUpdated();
    if (lastUpdated == null) return false;
    
    final now = DateTime.now();
    final difference = now.difference(lastUpdated).inDays;
    return difference <= 30;
  }
}