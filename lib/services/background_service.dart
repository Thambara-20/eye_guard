import 'dart:async';
import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';

import '../services/light_monitor_service.dart';
import '../services/notification_service.dart';
import '../services/sensor_service.dart';
import '../services/storage_service.dart';

// This class is responsible for running the background service for eye monitoring
class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  factory BackgroundService() => _instance;

  BackgroundService._internal();

  Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    // Configure Android-specific foreground notification settings
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'eye_guard_channel', // id
      'Eye Guard Monitoring', // title
      description:
          'Background service for monitoring eye health', // description
      importance: Importance.high,
    );

    // Create the notification channel on Android devices
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Configure the background service
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
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );

    // Start the service
    service.startService();
  }

  // This is the main background service function
  @pragma('vm:entry-point')
  static Future<void> onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    // Initialize services for background operation
    final notificationService = NotificationService();
    await notificationService.init();

    final sensorService = SensorService();
    final storageService = StorageService();

    final monitorService = LightMonitorService(
      sensorService: sensorService,
      storageService: storageService,
      notificationService: notificationService,
    );

    // Start monitoring in the background
    await monitorService.startMonitoring();

    // For debugging - when the service starts
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: "Eye Guard Active",
        content: "Monitoring your eye health in the background",
      );
    } // Check monitoring status every minute
    Timer.periodic(const Duration(minutes: 1), (timer) async {
      if (service is AndroidServiceInstance) {
        if (await service.isForegroundService()) {
          // Update the notification periodically
          service.setForegroundNotificationInfo(
            title: "Eye Guard Active",
            content: "Monitoring your eye health: ${DateTime.now()}",
          );
        }
      }
      // Get the latest light reading from the sensor service and check if we need to notify
      try {
        final latestReading = await sensorService.getLatestLightReading();
        final threshold = await storageService.getLuxThreshold();

        // Check if lighting is poor and needs a notification
        if (latestReading != null && latestReading.luxValue < threshold) {
          await notificationService.showPoorLightingNotification(
            id: 100,
            title: 'Poor Lighting Detected',
            body: 'Current light level: ${latestReading.luxValue.toStringAsFixed(1)} lux. ' +
                'For healthy eyes, maintain at least ${threshold.toStringAsFixed(0)} lux.',
          );
        }
      } catch (e) {
        print('Error in background monitoring: $e');
      }

      // Store health check timestamp
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_background_check', DateTime.now().toString());

      // Broadcast to clients (if any are connected)
      service.invoke('update', {
        'timestamp': DateTime.now().toString(),
        'service_active': true,
      });
    });
  }

  // iOS-specific background handler
  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();

    // iOS background processing is more limited, so we'll do minimal work
    SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setString(
        'last_ios_background_timestamp', DateTime.now().toString());

    return true;
  }
}
