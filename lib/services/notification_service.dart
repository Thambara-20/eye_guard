import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  // Private constructor for singleton pattern
  NotificationService._();
  static final NotificationService _instance = NotificationService._();

  // Flutter Local Notifications Plugin instance
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Singleton instance
  factory NotificationService() => _instance;

  // Initialize notifications
  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) {
        debugPrint('Notification clicked: ${notificationResponse.payload}');
      },
    );

    // Request permission on iOS
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    debugPrint('NotificationService initialized with real implementation');
  } // Constants for notification IDs

  static const int poorLightingNotificationId = 100;
  static const int proximityNotificationId = 101;

  // Show poor lighting notification - always using a fixed ID to replace previous notifications
  Future<void> showPoorLightingNotification({
    required int id, // Parameter kept for backward compatibility but not used
    required String title,
    required String body,
  }) async {
    // Use the appropriate notification ID based on the title
    final int notificationId = title.contains('Lighting')
        ? poorLightingNotificationId
        : proximityNotificationId;

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'poor_lighting_channel',
      'Poor Lighting Alerts',
      channelDescription: 'Notifications for poor lighting conditions',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
      // Set these to true to ensure the notification replaces the previous one
      channelShowBadge: true,
      autoCancel: false,
      ongoing: true, // Makes it persistent until user dismisses or we cancel it
      onlyAlertOnce: false, // Alert each time for important lighting changes
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    // Cancel any existing notification with this ID first
    await _flutterLocalNotificationsPlugin.cancel(notificationId);

    // Show new notification with the fixed ID
    await _flutterLocalNotificationsPlugin.show(
      notificationId, // Always use the same ID to replace previous notification
      title,
      body,
      platformChannelSpecifics,
      payload: 'poor_lighting_notification',
    );

    debugPrint('Real notification shown: $title - $body');
  }

  // Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
    debugPrint('Notification canceled: $id');
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
    debugPrint('All notifications canceled');
  }
}
