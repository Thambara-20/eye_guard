import 'dart:async';
import 'package:flutter/services.dart';
import '../models/light_reading.dart';

class SensorService {
  static const MethodChannel _channel =
      MethodChannel('com.eyeguard.eye_guard/sensor');

  // Private constructor for singleton pattern
  SensorService._();
  static final SensorService _instance = SensorService._();

  // Singleton instance
  factory SensorService() => _instance;

  // Stream controller to broadcast light sensor readings
  final _lightReadingController = StreamController<LightReading>.broadcast();
  Stream<LightReading> get lightReadingStream => _lightReadingController.stream;

  Timer? _pollingTimer;
  bool _isRunning = false;
  // Start the background sensor service
  Future<bool> startService() async {
    try {
      final bool result =
          await _channel.invokeMethod('startLightSensorService');
      if (result) {
        _isRunning = true;
        _startPolling();
      }
      return result;
    } catch (e) {
      print('Error starting service: $e');
      // Check if the error is due to missing sensor
      if (e is PlatformException && e.code == 'NO_SENSOR') {
        _lightReadingController
            .addError('Light sensor not available on this device');
      }
      return false;
    }
  }

  // Stop the background sensor service
  Future<bool> stopService() async {
    try {
      _stopPolling();
      final bool result = await _channel.invokeMethod('stopLightSensorService');
      _isRunning = false;
      return result;
    } catch (e) {
      print('Error stopping service: $e');
      return false;
    }
  }

  // Get the current light value
  Future<double> getCurrentLightValue() async {
    try {
      final double value = await _channel.invokeMethod('getCurrentLightValue');
      return value;
    } catch (e) {
      print('Error getting light value: $e');
      return 0.0;
    }
  }

  // Poll the light sensor service periodically
  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (_isRunning) {
        final lightValue = await getCurrentLightValue();
        _lightReadingController.add(
          LightReading(
            luxValue: lightValue,
            timestamp: DateTime.now(),
          ),
        );
      }
    });
  }

  // Stop polling the light sensor service
  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  // Dispose resources
  void dispose() {
    _stopPolling();
    _lightReadingController.close();
  }

  // Check if service is running
  bool get isRunning => _isRunning;
}
