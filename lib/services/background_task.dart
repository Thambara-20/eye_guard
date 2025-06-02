import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'light_monitor_service.dart';
import 'notification_service.dart';
import 'sensor_service.dart';
import 'storage_service.dart';

// This class manages background processing for the Eye Guard app
class BackgroundTask {
  static final BackgroundTask _instance = BackgroundTask._();
  factory BackgroundTask() => _instance;

  BackgroundTask._();

  // Initialize the background service
  Future<void> initialize() async {
    final service = FlutterBackgroundService();

    // Create notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'eye_guard_channel',
      'Eye Guard Service',
      description: 'Background service for monitoring eye health',
      importance: Importance.high,
    );

    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
            channel); // Configure the background service
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: 'eye_guard_channel',
        initialNotificationTitle: 'Eye Guard',
        initialNotificationContent: 'Monitoring light conditions',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: (_) async => false,
      ),
    );
  }

  // Entry point for the background service
  @pragma('vm:entry-point')
  static Future<void> onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    // Initialize services
    final notificationService = NotificationService();
    await notificationService.init();

    final sensorService = SensorService();
    final storageService = StorageService();

    // Check if background monitoring is enabled
    final isBackgroundMonitoringEnabled =
        await storageService.getBackgroundMonitoring();

    // If background monitoring is disabled, we'll still show a foreground notification
    // but won't actually do any sensor monitoring
    if (isBackgroundMonitoringEnabled) {
      final monitorService = LightMonitorService(
        sensorService: sensorService,
        storageService: storageService,
        notificationService: notificationService,
      );

      // Start monitoring in the background
      await monitorService.startMonitoring();
    }

    // For Android foreground service notification
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: "Eye Guard Active",
        content: "Monitoring eye health in the background",
      );
    }

    // Check monitoring status every minute
    Timer.periodic(const Duration(minutes: 1), (timer) async {
      // Update the Android notification periodically
      if (service is AndroidServiceInstance) {
        if (await service.isForegroundService()) {
          // Check if background monitoring is enabled
          final isBackgroundMonitoringEnabled =
              await storageService.getBackgroundMonitoring();

          service.setForegroundNotificationInfo(
            title: "Eye Guard Active",
            content: isBackgroundMonitoringEnabled
                ? "Monitoring your eye health: ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}"
                : "Background monitoring is paused",
          );

          // If background monitoring is disabled, don't continue with sensor checks
          if (!isBackgroundMonitoringEnabled) return;
        }
      }

      // Check light conditions
      try {
        final luxValue = await sensorService.getCurrentLightValue();
        final threshold = await storageService.getLuxThreshold();

        if (luxValue < threshold) {
          await notificationService.showPoorLightingNotification(
            id: NotificationService.poorLightingNotificationId,
            title: 'Poor Lighting Detected',
            body: 'Current light level: ${luxValue.toStringAsFixed(1)} lux. ' +
                'For healthy eyes, maintain at least ${threshold.toStringAsFixed(0)} lux.',
          );
        }

        // Also check proximity
        final distance = await sensorService.getCurrentProximityValue();
        if (distance < 30.0 && distance > 0) {
          await notificationService.showPoorLightingNotification(
            id: NotificationService.proximityNotificationId,
            title: 'Device Too Close',
            body:
                'Your device is only ${distance.toStringAsFixed(1)} cm from your face. ' +
                    'For eye health, maintain at least 30 cm distance.',
          );
        }
      } catch (e) {
        print('Error in background check: $e');
      }
    });
  }
}
