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

  Timer? _lightPollingTimer;
  Timer? _proximityPollingTimer;
  bool _isRunning = false;

  /// Initializes and starts both light and proximity sensor services.
  /// Returns [true] if both services start successfully, [false] otherwise.
  /// Handles [PlatformException] errors (e.g., no sensor available) by adding errors to the streams.
  Future<bool> startService() async {
    try {
      final lightResult =
          await _lightChannel.invokeMethod('startLightSensorService');
      final proximityResult =
          await _proximityChannel.invokeMethod('startProximitySensorService');
      if (lightResult == true && proximityResult == true) {
        _isRunning = true;
        _startPolling();
      }
      return _isRunning;
    } catch (e) {
      print('Error starting service: $e');
      if (e is PlatformException && e.code == 'NO_SENSOR') {
        _lightReadingController.addError('Sensors not available');
        _proximityReadingController.addError('Sensors not available');
      }
      return false;
    }
  }

  /// Stops both light and proximity sensor services.
  /// Returns [true] if both services stop successfully, [false] otherwise.
  /// Cleans up polling timers before stopping the services.
  Future<bool> stopService() async {
    try {
      _stopPolling();
      final lightResult =
          await _lightChannel.invokeMethod('stopLightSensorService');
      final proximityResult =
          await _proximityChannel.invokeMethod('stopProximitySensorService');
      _isRunning = false;
      return lightResult == true && proximityResult == true;
    } catch (e) {
      print('Error stopping service: $e');
      return false;
    }
  }

  /// Retrieves the current light value from the light sensor service.
  /// Returns the lux value as a [double], or 0.0 if an error occurs.
  Future<double> getCurrentLightValue() async {
    try {
      return await _lightChannel.invokeMethod('getCurrentLightValue');
    } catch (e) {
      print('Error getting light value: $e');
      return 0.0;
    }
  }

  /// Retrieves the current proximity value from the proximity sensor service.
  /// Returns the distance in centimeters as a [double], or [double.infinity] if an error occurs.
  Future<double> getCurrentProximityValue() async {
    try {
      return await _proximityChannel.invokeMethod('getCurrentDistance');
    } catch (e) {
      print('Error getting proximity value: $e');
      return double.infinity; // Indicate no valid reading
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
