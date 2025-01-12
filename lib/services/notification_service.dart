import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:pathpal/screens/tabs.dart';

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;

  static Future<void> initialize(BuildContext context) async {
    // Request permission for iOS
    await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    // Initialize local notifications
    const initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsIOS = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // For now, just navigate to home screen
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const Tabs()));
      },
    );

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification tap when app is in background but opened
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // For now, just navigate to home screen
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    });

    // Update token on app start
    await updateUserToken();
  }

  static Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    // Initialize Firebase if needed (required for background handlers)
    // await Firebase.initializeApp();
    print('Handling a background message: ${message.messageId}');
  }

  static void _handleForegroundMessage(RemoteMessage message) async {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');

    if (message.notification != null) {
      await _showLocalNotification(
        title: message.notification!.title ?? 'New Message',
        body: message.notification!.body ?? '',
        payload: message.data,
      );
    }
  }

  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    required Map<String, dynamic> payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'chat_messages',
      'Chat Messages',
      channelDescription: 'Notifications for new chat messages',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      details,
      payload: const JsonEncoder().convert(payload),
    );
  }

  static Future<void> updateUserToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'fcmToken': token});
      }

      // Also listen for token refreshes
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'fcmToken': newToken});
      });
    }
  }

  static Future<void> sendChatNotification({
    required String recipientId,
    required String senderId,
    required String message,
    required String chatId,
  }) async {
    try {
      // Get sender's name
      final senderDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(senderId)
          .get();

      final senderName = senderDoc.data()?['name'] ?? 'User';

      // Call the Cloud Function
      await _functions.httpsCallable('sendChatNotification').call({
        'recipientId': recipientId,
        'message': message,
        'senderName': senderName,
        'chatId': chatId,
      });
    } catch (e) {
      print('Error sending notification: $e');
    }
  }
}
