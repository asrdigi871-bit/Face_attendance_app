import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/data_models.dart';
import '../../providers/settings_data.dart';

// Page for Notification Display
class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: <Widget>[
          Consumer<NotificationData>(
            builder: (
                BuildContext context,
                NotificationData notificationData,
                Widget? child,
                ) {
              if (notificationData.notifications.any(
                    (NotificationItem n) => !n.isRead,
              )) {
                return TextButton(
                  onPressed: () {
                    for (final NotificationItem item
                    in notificationData.notifications) {
                      if (!item.isRead) {
                        notificationData.markAsRead(item);
                      }
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('All notifications marked as read.'),
                      ),
                    );
                  },
                  child: const Text('Mark All Read'),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () {
              Future.microtask(() {
                Provider.of<NotificationData>(
                  context,
                  listen: false,
                ).clearAllNotifications();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All notifications cleared.')),
                );
              });
            },
          ),
        ],
      ),
      body: Consumer<NotificationData>(
        builder: (
            BuildContext context,
            NotificationData notificationData,
            Widget? child,
            ) {
          if (notificationData.notifications.isEmpty) {
            return const Center(child: Text('No new notifications.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: notificationData.notifications.length,
            itemBuilder: (BuildContext context, int index) {
              final NotificationItem notification =
              notificationData.notifications[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                elevation: notification.isRead ? 0 : 2,
                color: notification.isRead ? Colors.grey.shade100 : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  leading: Icon(
                    notification.isRead
                        ? Icons.check_circle_outline
                        : Icons.info_outline,
                    color: notification.isRead ? Colors.green : Colors.blue,
                  ),
                  title: Text(
                    notification.title,
                    style: TextStyle(
                      fontWeight: notification.isRead
                          ? FontWeight.normal
                          : FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(notification.message),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat(
                          'MMM d, yyyy HH:mm',
                        ).format(notification.timestamp),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    Future.microtask(() {
                      notificationData.markAsRead(notification);
                    });
                  },
                  trailing: notification.isRead
                      ? null
                      : Icon(
                    Icons.fiber_new,
                    color: Colors.red.shade400,
                    size: 18,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}