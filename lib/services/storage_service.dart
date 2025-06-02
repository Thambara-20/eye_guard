import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/light_reading.dart';

class StorageService {
  static const String _lightReadingsKey = 'light_readings';
  static const String _thresholdKey = 'lux_threshold';
  
  // Default threshold in lux (300 lux is recommended for normal reading)
  static const double defaultThreshold = 300.0;
  
  // Private constructor for singleton pattern
  StorageService._();
  static final StorageService _instance = StorageService._();
  
  // Singleton instance
  factory StorageService() => _instance;
  
  // Save a light reading to storage
  Future<void> saveLightReading(LightReading reading) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Get existing readings
    List<LightReading> readings = await getLightReadings();
    
    // Add new reading
    readings.add(reading);
    
    // Keep only last 1000 readings (about 16 hours if reading every minute)
    if (readings.length > 1000) {
      readings = readings.sublist(readings.length - 1000);
    }
    
    // Convert to JSON list and save
    final List<String> jsonReadings = readings
        .map((reading) => jsonEncode(reading.toJson()))
        .toList();
    
    await prefs.setStringList(_lightReadingsKey, jsonReadings);
  }
  
  // Get all stored light readings
  Future<List<LightReading>> getLightReadings() async {
    final prefs = await SharedPreferences.getInstance();
    
    final List<String>? jsonReadings = prefs.getStringList(_lightReadingsKey);
    
    if (jsonReadings == null || jsonReadings.isEmpty) {
      return [];
    }
    
    return jsonReadings
        .map((jsonString) => LightReading.fromJson(jsonDecode(jsonString)))
        .toList();
  }
  
  // Get readings from a specific date range
  Future<List<LightReading>> getReadingsInRange(DateTime start, DateTime end) async {
    final readings = await getLightReadings();
    
    return readings.where((reading) {
      return reading.timestamp.isAfter(start) && reading.timestamp.isBefore(end);
    }).toList();
  }
  
  // Save user-set threshold for optimal lighting
  Future<void> saveLuxThreshold(double threshold) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_thresholdKey, threshold);
  }
  
  // Get user-set threshold for optimal lighting
  Future<double> getLuxThreshold() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_thresholdKey) ?? defaultThreshold;
  }
  
  // Clear all stored light readings
  Future<void> clearReadings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lightReadingsKey);
  }
}
