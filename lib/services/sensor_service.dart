import 'dart:async';
import 'package:flutter/services.dart';
import '../models/light_reading.dart';
import '../models/proximity_reading.dart';

class SensorService {
  static const MethodChannel _lightChannel =
      MethodChannel('com.eyeguard.eye_guard/sensor');
  static const MethodChannel _proximityChannel =
      MethodChannel('com.eyeguard.eye_guard/proximity');

  SensorService._();
  static final SensorService _instance = SensorService._();
  factory SensorService() => _instance;

  final _lightReadingController = StreamController<LightReading>.broadcast();
  Stream<LightReading> get lightReadingStream => _lightReadingController.stream;

  final _proximityReadingController =
      StreamController<ProximityReading>.broadcast();
  Stream<ProximityReading> get proximityReadingStream =>
      _proximityReadingController.stream;

  // Store the latest readings for background service access
  LightReading? _latestLightReading;
  ProximityReading? _latestProximityReading;

  Timer? _lightPollingTimer;
  Timer? _proximityPollingTimer;
  bool _isRunning = false;
  bool _lightSensorAvailable = true;
  bool _proximitySensorAvailable = true;

  /// Initializes and starts both light and proximity sensor services.
  /// Returns [true] if at least one service starts successfully, [false] otherwise.
  /// Handles [PlatformException] errors by adding fallback values.
  Future<bool> startService() async {
    bool serviceStarted = false;

    // Try to start light sensor service
    try {
      final lightResult =
          await _lightChannel.invokeMethod('startLightSensorService');
      if (lightResult == true) {
        _lightSensorAvailable = true;
        serviceStarted = true;
      } else {
        _lightSensorAvailable = false;
        print('Light sensor service failed to start');
      }
    } catch (e) {
      print('Error starting light service: $e');
      _lightSensorAvailable = false;
      if (e is PlatformException && e.code == 'NO_SENSOR') {
        _lightReadingController.addError('Light sensor not available');
      }
    }

    // Try to start proximity sensor service
    try {
      final proximityResult =
          await _proximityChannel.invokeMethod('startProximitySensorService');
      if (proximityResult == true) {
        _proximitySensorAvailable = true;
        serviceStarted = true;
      } else {
        _proximitySensorAvailable = false;
        print('Proximity sensor service failed to start');
      }
    } catch (e) {
      print('Error starting proximity service: $e');
      _proximitySensorAvailable = false;
      if (e is PlatformException && e.code == 'NO_SENSOR') {
        _proximityReadingController.addError('Proximity sensor not available');
      }
    }

    // If at least one service started, consider service as running
    if (serviceStarted) {
      _isRunning = true;
      _startPolling();
    }

    return serviceStarted;
  }

  /// Stops both light and proximity sensor services.
  /// Returns [true] if services stop successfully, [false] otherwise.
  /// Cleans up polling timers before stopping the services.
  Future<bool> stopService() async {
    bool success = true;
    _stopPolling();

    if (_lightSensorAvailable) {
      try {
        final lightResult =
            await _lightChannel.invokeMethod('stopLightSensorService');
        if (lightResult != true) success = false;
      } catch (e) {
        print('Error stopping light service: $e');
        success = false;
      }
    }

    if (_proximitySensorAvailable) {
      try {
        final proximityResult =
            await _proximityChannel.invokeMethod('stopProximitySensorService');
        if (proximityResult != true) success = false;
      } catch (e) {
        print('Error stopping proximity service: $e');
        success = false;
      }
    }

    _isRunning = false;
    return success;
  }

  /// Retrieves the current light value from the light sensor service.
  /// Returns the lux value as a [double], with a reasonable fallback.
  Future<double> getCurrentLightValue() async {
    if (!_lightSensorAvailable) {
      // Return a reasonable default value if sensor isn't available
      return 300.0; // Moderate indoor lighting as fallback
    }

    try {
      final value = await _lightChannel.invokeMethod('getCurrentLightValue');
      return value is double ? value : 0.0;
    } catch (e) {
      print('Error getting light value: $e');
      return 300.0;
    }
  }

  /// Retrieves the current proximity value from the proximity sensor service.
  /// Returns the distance in centimeters as a [double], with a reasonable fallback.
  Future<double> getCurrentProximityValue() async {
    if (!_proximitySensorAvailable) {
      // Return a reasonable default value if sensor isn't available
      return 40.0; // Safe distance as fallback
    }

    try {
      final value = await _proximityChannel.invokeMethod('getCurrentDistance');
      return value is double ? value : double.infinity;
    } catch (e) {
      print('Error getting proximity value: $e');
      return 40.0;
    }
  }

  /// Gets the latest light reading for background monitoring.
  /// Returns a [LightReading] or null if no reading is available.
  Future<LightReading?> getLatestLightReading() async {
    try {
      final luxValue = await getCurrentLightValue();
      return LightReading(
        timestamp: DateTime.now(),
        luxValue: luxValue,
      );
    } catch (e) {
      print('Error getting latest light reading: $e');
      return null;
    }
  }

  /// Gets the latest proximity reading for background monitoring.
  /// Returns a [ProximityReading] or null if no reading is available.
  Future<ProximityReading?> getLatestProximityReading() async {
    try {
      final distance = await getCurrentProximityValue();
      return ProximityReading(
        timestamp: DateTime.now(),
        distance: distance,
      );
    } catch (e) {
      print('Error getting latest proximity reading: $e');
      return null;
    }
  }

  /// Starts periodic polling for both light and proximity sensor data.
  /// Uses a 1-second interval to fetch and broadcast readings via their respective streams.
  /// Only polls if the service is running.
  void _startPolling() {
    _lightPollingTimer?.cancel();
    _lightPollingTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (_isRunning) {
        final lightValue = await getCurrentLightValue();
        _lightReadingController.add(
          LightReading(luxValue: lightValue, timestamp: DateTime.now()),
        );
      }
    });

    _proximityPollingTimer?.cancel();
    _proximityPollingTimer =
        Timer.periodic(const Duration(seconds: 1), (_) async {
      if (_isRunning) {
        final proximityValue = await getCurrentProximityValue();
        _proximityReadingController.add(
          ProximityReading(distance: proximityValue, timestamp: DateTime.now()),
        );
      }
    });
  }

  /// Stops periodic polling for both light and proximity sensor data.
  /// Cancels and nullifies the polling timers.
  void _stopPolling() {
    _lightPollingTimer?.cancel();
    _proximityPollingTimer?.cancel();
    _lightPollingTimer = null;
    _proximityPollingTimer = null;
  }

  /// Disposes of the sensor service resources.
  /// Stops polling and closes the light and proximity stream controllers.
  void dispose() {
    _stopPolling();
    _lightReadingController.close();
    _proximityReadingController.close();
  }

  /// Checks if the sensor service is currently running.
  /// Returns [true] if running, [false] otherwise.
  bool get isRunning => _isRunning;
}
