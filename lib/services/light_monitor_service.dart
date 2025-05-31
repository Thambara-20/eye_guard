import 'dart:async';
import '../models/light_reading.dart';
import 'sensor_service.dart';
import 'storage_service.dart';
import 'notification_service.dart';

class LightMonitorService {
  final SensorService _sensorService;
  final StorageService _storageService;
  final NotificationService _notificationService;

  // Tracks how long the user has been in poor lighting
  DateTime? _poorLightingStartTime;
  bool _notificationShown = false;

  // Duration thresholds for warnings
  static const Duration _warningThreshold = Duration(minutes: 5);

  // Stream subscription for light readings
  StreamSubscription<LightReading>? _lightReadingSubscription;

  // Private constructor
  LightMonitorService._({
    required SensorService sensorService,
    required StorageService storageService,
    required NotificationService notificationService,
  })  : _sensorService = sensorService,
        _storageService = storageService,
        _notificationService = notificationService;

  // Singleton instance
  static LightMonitorService? _instance;

  // Factory constructor
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

  // Start monitoring light levels
  Future<bool> startMonitoring() async {
    final bool success = await _sensorService.startService();

    if (success) {
      _lightReadingSubscription =
          _sensorService.lightReadingStream.listen(_processLightReading);
    }

    return success;
  }

  // Stop monitoring light levels
  Future<bool> stopMonitoring() async {
    _lightReadingSubscription?.cancel();
    _lightReadingSubscription = null;

    return await _sensorService.stopService();
  }

  // Process a light reading
  void _processLightReading(LightReading reading) async {
    // Save the reading to storage (could be optimized to save less frequently)
    await _storageService.saveLightReading(reading);

    // Get user's threshold setting
    final threshold = await _storageService.getLuxThreshold();

    // Check if lighting is poor
    if (reading.luxValue < threshold) {
      // If this is the start of poor lighting, record the time
      _poorLightingStartTime ??= DateTime.now();

      // Check if user has been in poor lighting for too long
      final poorLightingDuration =
          DateTime.now().difference(_poorLightingStartTime!);

      // Show notification if threshold exceeded and no notification shown yet
      if (poorLightingDuration > _warningThreshold && !_notificationShown) {
        await _notificationService.showPoorLightingNotification(
          id: 1,
          title: 'Poor Lighting Detected',
          body:
              'You have been in poor lighting for ${poorLightingDuration.inMinutes} minutes. '
              'Consider improving your lighting conditions.',
        );
        _notificationShown = true;
      }
    } else {
      // Reset poor lighting tracking if lighting is good
      if (_poorLightingStartTime != null) {
        _poorLightingStartTime = null;
        if (_notificationShown) {
          await _notificationService.cancelNotification(1);
          _notificationShown = false;
        }
      }
    }
  }

  // Get user's light exposure stats
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

    // Calculate stats
    double totalLux = 0;
    double minLux = double.infinity;
    double maxLux = 0;
    int belowThresholdCount = 0;

    for (final reading in readings) {
      totalLux += reading.luxValue;
      minLux = minLux > reading.luxValue ? reading.luxValue : minLux;
      maxLux = maxLux < reading.luxValue ? reading.luxValue : maxLux;

      if (reading.luxValue < threshold) {
        belowThresholdCount++;
      }
    }

    final averageLux = totalLux / readings.length;
    final belowThresholdPercentage =
        readings.isEmpty ? 0 : (belowThresholdCount / readings.length) * 100;
    final aboveThresholdPercentage = 100 - belowThresholdPercentage;

    return {
      'averageLux': averageLux,
      'timeBelowThreshold': belowThresholdPercentage,
      'timeAboveThreshold': aboveThresholdPercentage,
      'minLux': minLux == double.infinity ? 0 : minLux,
      'maxLux': maxLux,
    };
  }

  // Check if monitoring is active
  bool get isMonitoring => _sensorService.isRunning;

  // Provide access to current light value
  Future<double> getCurrentLightValue() async {
    return await _sensorService.getCurrentLightValue();
  }
}
