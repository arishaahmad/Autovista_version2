import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:awesome_notifications/awesome_notifications.dart' as awesome;
import 'package:flutter/material.dart';

@pragma('vm:entry-point') // Required to run in background isolate
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  final title = message.data['title'] ?? '🚨 Emergency Alert';
  final body = message.data['body'] ?? 'Something critical happened.';

  await awesome.AwesomeNotifications().createNotification(
    content: awesome.NotificationContent(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      channelKey: 'autovista_notifications',
      title: title,
      body: body,
      backgroundColor: const Color(0xFFB71C1C),
      color: Colors.white,
      notificationLayout: awesome.NotificationLayout.BigText,
      criticalAlert: true,
      wakeUpScreen: true,
      fullScreenIntent: false,
      autoDismissible: false,
      displayOnBackground: true,
      displayOnForeground: true,
      locked: true,
    ),
    
  );
}
