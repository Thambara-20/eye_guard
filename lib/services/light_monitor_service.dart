import 'dart:async';
import '../models/light_reading.dart';
import '../models/proximity_reading.dart';
import 'sensor_service.dart';
import 'storage_service.dart';
import 'notification_service.dart';

class LightMonitorService {
  final SensorService _sensorService;
  final StorageService _storageService;
  final NotificationService _notificationService;

  DateTime? _poorLightingStartTime;
  DateTime? _closeProximityStartTime;
  bool _lightingNotificationShown = false;
  bool _proximityNotificationShown = false;

  static const Duration _warningThreshold = Duration(minutes: 5);
  static const double _safeDistanceThreshold = 30.0; // cm

  StreamSubscription<LightReading>? _lightReadingSubscription;
  StreamSubscription<ProximityReading>? _proximityReadingSubscription;

  LightMonitorService._({
    required SensorService sensorService,
    required StorageService storageService,
    required NotificationService notificationService,
  })  : _sensorService = sensorService,
        _storageService = storageService,
        _notificationService = notificationService;

  static LightMonitorService? _instance;

  /// Factory constructor to create or return a singleton instance of LightMonitorService.
  /// [sensorService], [storageService], and [notificationService] are required dependencies.
  factory LightMonitorService({
    required SensorService sensorService,
    required StorageService storageService,
    required NotificationService notificationService,
  }) {
    _instance ??= LightMonitorService._(
      sensorService: sensorService,
      storageService: storageService,
      notificationService: notificationService,
    );
    return _instance!;
  }

  /// Starts monitoring light and proximity sensor data.
  /// Returns [true] if the sensor service starts successfully, [false] otherwise.
  Future<bool> startMonitoring() async {
    final success = await _sensorService.startService();
    if (success) {
      _lightReadingSubscription =
          _sensorService.lightReadingStream.listen(_processLightReading);
      _proximityReadingSubscription = _sensorService.proximityReadingStream
          .listen(_processProximityReading);
    }
    return success;
  }

  /// Stops monitoring light and proximity sensor data.
  /// Returns [true] if the sensor service stops successfully, [false] otherwise.
  Future<bool> stopMonitoring() async {
    _lightReadingSubscription?.cancel();
    _proximityReadingSubscription?.cancel();
    _lightReadingSubscription = null;
    _proximityReadingSubscription = null;
    return await _sensorService.stopService();
  }

  /// Processes incoming light reading data from the sensor stream.
  /// Saves the reading to storage and triggers a notification if lighting is poor for 5 minutes.
  void _processLightReading(LightReading reading) async {
    await _storageService.saveLightReading(reading);
    final threshold = await _storageService.getLuxThreshold();
    if (reading.luxValue < threshold) {
      _poorLightingStartTime ??= DateTime.now();
      final poorLightingDuration =
          DateTime.now().difference(_poorLightingStartTime!);
      if (poorLightingDuration > _warningThreshold &&
          !_lightingNotificationShown) {
        await _notificationService.showPoorLightingNotification(
          id: 1,
          title: 'Poor Lighting Detected',
          body:
              'You have been in poor lighting for ${poorLightingDuration.inMinutes} minutes. '
              'Consider improving your lighting conditions.',
        );
        _lightingNotificationShown = true;
      }
    } else {
      _poorLightingStartTime = null;
      if (_lightingNotificationShown) {
        await _notificationService.cancelNotification(1);
        _lightingNotificationShown = false;
      }
    }
  }

  /// Processes incoming proximity reading data from the sensor stream.
  /// Saves the reading to storage and triggers a notification if the device is too close for 5 minutes.
  void _processProximityReading(ProximityReading reading) async {
    await _storageService.saveLightReading(LightReading(
        luxValue: 0, timestamp: reading.timestamp)); // Placeholder storage
    if (reading.distance < _safeDistanceThreshold) {
      _closeProximityStartTime ??= DateTime.now();
      final proximityDuration =
          DateTime.now().difference(_closeProximityStartTime!);
      if (proximityDuration > _warningThreshold &&
          !_proximityNotificationShown) {
        await _notificationService.showPoorLightingNotification(
          id: 2,
          title: 'Too Close to Screen',
          body:
              'You have been too close (<30cm) for ${proximityDuration.inMinutes} minutes. '
              'Move back to reduce eye strain.',
        );
        _proximityNotificationShown = true;
      }
    } else {
      _closeProximityStartTime = null;
      if (_proximityNotificationShown) {
        await _notificationService.cancelNotification(2);
        _proximityNotificationShown = false;
      }
    }
  }

  /// Retrieves light exposure statistics from stored readings.
  /// Returns a [Map] containing average lux, time below/above threshold, min/max lux.
  Future<Map<String, dynamic>> getLightStats() async {
    final readings = await _storageService.getLightReadings();
    if (readings.isEmpty) {
      return {
        'averageLux': 0.0,
        'timeBelowThreshold': 0.0,
        'timeAboveThreshold': 0.0,
        'minLux': 0.0,
        'maxLux': 0.0,
      };
    }
    final threshold = await _storageService.getLuxThreshold();
    double totalLux = 0;
    double minLux = double.infinity;
    double maxLux = 0;
    int belowThresholdCount = 0;
    for (final reading in readings) {
      totalLux += reading.luxValue;
      minLux = minLux > reading.luxValue ? reading.luxValue : minLux;
      maxLux = maxLux < reading.luxValue ? reading.luxValue : maxLux;
      if (reading.luxValue < threshold) belowThresholdCount++;
    }
    final averageLux = totalLux / readings.length;
    final belowThresholdPercentage =
        (belowThresholdCount / readings.length) * 100;
    final aboveThresholdPercentage = 100 - belowThresholdPercentage;
    return {
      'averageLux': averageLux,
      'timeBelowThreshold': belowThresholdPercentage,
      'timeAboveThreshold': aboveThresholdPercentage,
      'minLux': minLux == double.infinity ? 0 : minLux,
      'maxLux': maxLux,
    };
  }

  /// Checks if the monitoring service is currently active.
  /// Returns [true] if running, [false] otherwise.
  bool get isMonitoring => _sensorService.isRunning;

  /// Retrieves the current light value from the sensor service.
  /// Returns the lux value as a [double].
  Future<double> getCurrentLightValue() async {
    return await _sensorService.getCurrentLightValue();
  }

  /// Retrieves the current proximity value from the sensor service.
  /// Returns the distance in centimeters as a [double].
  Future<double> getCurrentProximityValue() async {
    return await _sensorService.getCurrentProximityValue();
  }
}
