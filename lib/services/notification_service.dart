import 'package:awesome_notifications/awesome_notifications.dart' as awesome;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest.dart' as tz;
import '../models/notification_model.dart';
import 'package:logger/logger.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  final supabase = Supabase.instance.client;
  final logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 50,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );
  RealtimeChannel? _notificationChannel;

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  Future<void> initialize() async {
    try {
      // Initialize timezone
      tz.initializeTimeZones();

      // Initialize awesome notifications
      await awesome.AwesomeNotifications().initialize(
        null, // no icon for now
        [
          awesome.NotificationChannel(
            channelKey: 'autovista_notifications',
            channelName: 'AutoVista Notifications',
            channelDescription: 'Notifications for AutoVista app',
            defaultColor: const Color(0xFF9D50DD),
            ledColor: const Color(0xFF9D50DD),
            importance: awesome.NotificationImportance.High,
          ),
        ],
      );

      logger.i('NotificationService initialized successfully');
    } catch (e) {
      logger.e('Error initializing NotificationService: $e');
      rethrow;
    }
  }

  Future<bool> requestUserPermission(BuildContext context) async {
    try {
      final isAllowed = await awesome.AwesomeNotifications().isNotificationAllowed();
      if (!isAllowed) {
        // Show dialog to explain why we need notifications
        if (!context.mounted) return false;
        final shouldAsk = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Enable Notifications'),
            content: const Text(
              'AutoVista would like to send you notifications for important updates about your vehicles, such as maintenance reminders and document expiry alerts.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Not Now'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Enable'),
              ),
            ],
          ),
        );

        if (shouldAsk == true) {
          final result = await awesome.AwesomeNotifications().requestPermissionToSendNotifications();
          return result;
        }
        return false;
      }
      return true;
    } catch (e) {
      logger.e('Error requesting notification permission: $e');
      return false;
    }
  }

  Future<void> _showLocalNotification(NotificationModel notification) async {
    try {
      await awesome.AwesomeNotifications().createNotification(
        content: awesome.NotificationContent(
          id: notification.hashCode,
          channelKey: 'autovista_notifications',
          title: notification.title,
          body: notification.body,
          notificationLayout: awesome.NotificationLayout.BigText,
          payload: {'data': notification.data ?? ''},
        ),
      );
    } catch (e) {
      logger.e('Error showing local notification: $e');
    }
  }

  Future<void> subscribeToUserNotifications(String userId) async {
    try {
      // Unsubscribe from any existing subscription
      await unsubscribeFromNotifications();

      // Subscribe to user-specific notifications using Postgres Changes
      _notificationChannel = supabase.channel('notifications:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          callback: (payload) {
            if (payload.newRecord['user_id'] == userId) {
              _handleNewNotification(payload.newRecord);
            }
          },
        )
        .subscribe();

      logger.i('Subscribed to notifications for user: $userId');
    } catch (e) {
      logger.e('Error subscribing to notifications: $e');
      rethrow;
    }
  }

  Future<void> unsubscribeFromNotifications() async {
    try {
      if (_notificationChannel != null) {
        await _notificationChannel!.unsubscribe();
        _notificationChannel = null;
        logger.i('Unsubscribed from notifications');
      }
    } catch (e) {
      logger.e('Error unsubscribing from notifications: $e');
      rethrow;
    }
  }

  void _handleNewNotification(Map<String, dynamic> payload) {
    try {
      final notification = NotificationModel.fromJson(payload);
      _showLocalNotification(notification);
      logger.i('Received new notification: ${notification.title}');
    } catch (e) {
      logger.e('Error handling new notification: $e');
    }
  }

  Future<List<NotificationModel>> getNotifications(String userId) async {
    try {
      final response = await supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => NotificationModel.fromJson(json))
          .toList();
    } catch (e) {
      logger.e('Error fetching notifications: $e');
      rethrow;
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);

      logger.i('Marked notification as read: $notificationId');
    } catch (e) {
      logger.e('Error marking notification as read: $e');
      rethrow;
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await supabase
          .from('notifications')
          .delete()
          .eq('id', notificationId);

      logger.i('Deleted notification: $notificationId');
    } catch (e) {
      logger.e('Error deleting notification: $e');
      rethrow;
    }
  }
}