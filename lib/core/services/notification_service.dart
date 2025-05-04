
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  
  NotificationService() {
    _initializeNotifications();
  }
  
  Future<void> _initializeNotifications() async {
    // Request permission for notifications
    await _requestPermissions();
    
    // Initialize local notifications plugin
    await _initializeLocalNotifications();
    
    // Handle received notifications when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showNotification(message);
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');
      }
    });
    
    // Handle notification taps when app is terminated
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        _handleNotificationTap(message);
      }
    });
    
    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }
  
  Future<void> _requestPermissions() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    
    if (kDebugMode) {
      print('User granted permission: ${settings.authorizationStatus}');
    }
    
    // Get FCM token
    String? token = await _messaging.getToken();
    if (kDebugMode && token != null) {
      print('FCM Token: $token');
    }
    
    // Subscribe to topics
    await _messaging.subscribeToTopic('all_users');
    await _messaging.subscribeToTopic('riders');
  }
  
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    final DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      onDidReceiveLocalNotification: (int id, String? title, String? body, String? payload) async {
        // Handle iOS local notification
      },
    );
    
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) {
        // Handle local notification tap
      },
    );
    
    // Create notification channel for Android
    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'campus_dash_channel',
        'Campus Dash Notifications',
        description: 'This channel is used for important notifications.',
        importance: Importance.high,
      );
      
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }
  
  Future<void> _showNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;
    
    if (notification != null && android != null) {
      await _flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'campus_dash_channel',
            'Campus Dash Notifications',
            channelDescription: 'This channel is used for important notifications.',
            icon: android.smallIcon,
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data['type'],
      );
    }
  }
  
  void _handleNotificationTap(RemoteMessage message) {
    // Handle navigation based on notification type
    final notificationType = message.data['type'];
    
    switch (notificationType) {
      case 'ride_accepted':
        final rideId = message.data['ride_id'];
        if (rideId != null) {
          // Navigate to ride tracking screen
          // We'll implement this later with GoRouter
        }
        break;
      case 'ride_completed':
        // Navigate to ride history or rating screen
        break;
      case 'wallet_updated':
        // Navigate to wallet screen
        break;
      default:
        // Default action or do nothing
        break;
    }
  }
  
  Future<void> subscribeToRideTopic(String rideId) async {
    await _messaging.subscribeToTopic('ride_$rideId');
  }
  
  Future<void> unsubscribeFromRideTopic(String rideId) async {
    await _messaging.unsubscribeFromTopic('ride_$rideId');
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
