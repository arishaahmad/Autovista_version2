import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationsScreen extends StatefulWidget {
  final String userId;

  const NotificationsScreen({super.key, required this.userId});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _subscribeToNotifications();
  }

  @override
  void dispose() {
    _notificationService.unsubscribeFromNotifications();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final notifications = await _notificationService.getNotifications(widget.userId);
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading notifications: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _subscribeToNotifications() async {
    await _notificationService.subscribeToUserNotifications(widget.userId);
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    try {
      await _notificationService.markAsRead(notification.id);
      setState(() {
        final index = _notifications.indexOf(notification);
        if (index != -1) {
          _notifications[index] = notification.copyWith(isRead: true);
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error marking notification as read: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteNotification(NotificationModel notification) async {
    try {
      await _notificationService.deleteNotification(notification.id);
      setState(() {
        _notifications.remove(notification);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting notification: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotifications,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(
                  child: Text('No notifications'),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      return Dismissible(
                        key: Key(notification.id),
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16.0),
                          child: const Icon(
                            Icons.delete,
                            color: Colors.white,
                          ),
                        ),
                        direction: DismissDirection.endToStart,
                        onDismissed: (direction) {
                          _deleteNotification(notification);
                        },
                        child: ListTile(
                          title: Text(
                            notification.title,
                            style: TextStyle(
                              fontWeight:
                                  notification.isRead ? FontWeight.normal : FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(notification.body),
                              const SizedBox(height: 4),
                              Text(
                                timeago.format(notification.createdAt),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                          leading: Icon(
                            _getNotificationIcon(notification.type),
                            color: _getNotificationColor(notification.type),
                          ),
                          onTap: () {
                            if (!notification.isRead) {
                              _markAsRead(notification);
                            }
                            // TODO: Handle notification tap based on type and data
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'maintenance':
        return Icons.build;
      case 'document_expiry':
        return Icons.description;
      case 'system':
        return Icons.notifications;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'maintenance':
        return Colors.orange;
      case 'document_expiry':
        return Colors.red;
      case 'system':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}