import 'package:flutter/material.dart';

class NotificationItem {
  final String title;
  final String message;
  final DateTime timestamp;
  final Color color;

  NotificationItem({
    required this.title,
    required this.message,
    required this.timestamp,
    required this.color,
  });
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  // Sample data — replace with your backend data
  List<NotificationItem> _sampleData() {
    final now = DateTime.now();
    return <NotificationItem>[
      NotificationItem(
        title: 'Attendance Alert',
        message: 'Stephen marked present at 14:20',
        timestamp: now.subtract(const Duration(minutes: 2)),
        color: Colors.green,
      ),
      NotificationItem(
        title: 'Late Alert',
        message: 'Ram was late today.',
        timestamp: now.subtract(const Duration(minutes: 15)),
        color: Colors.orange,
      ),
      NotificationItem(
        title: 'Absent Alert',
        message: 'Ajay was absent yesterday.',
        timestamp: now.subtract(const Duration(days: 1, hours: 3)),
        color: Colors.red,
      ),
      NotificationItem(
        title: 'System Update',
        message: 'New features were added to the attendance system.',
        timestamp: now.subtract(const Duration(days: 3)),
        color: Colors.blue,
      ),
    ];
  }

  // Groups items into Today / Yesterday / Earlier
  Map<String, List<NotificationItem>> _groupByDay(List<NotificationItem> items) {
    final Map<String, List<NotificationItem>> result = {
      'Today': [],
      'Yesterday': [],
      'Earlier': [],
    };
    final now = DateTime.now();
    DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
    final today = dateOnly(now);
    final yesterday = dateOnly(now.subtract(const Duration(days: 1)));

    for (final item in items) {
      final d = dateOnly(item.timestamp);
      if (d == today) {
        result['Today']!.add(item);
      } else if (d == yesterday) {
        result['Yesterday']!.add(item);
      } else {
        result['Earlier']!.add(item);
      }
    }
    return result;
  }

  String _formatRelative(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
  }

  String _formatTimeOfDay(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final items = _sampleData();
    final sections = _groupByDay(items);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final sectionTitle in ['Today', 'Yesterday', 'Earlier'])
            if (sections[sectionTitle]!.isNotEmpty) ...[
              _buildSectionTitle(sectionTitle),
              const SizedBox(height: 8),
              for (final item in sections[sectionTitle]!)
                _buildNotificationCard(item),
              const SizedBox(height: 12),
            ]
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem n) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: n.color.withAlpha((255 * 0.12).round()),
          child: Text(
            n.title.isNotEmpty ? n.title[0] : '',
            style: TextStyle(color: n.color, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(n.title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 4),
            Text(n.message),
            const SizedBox(height: 6),
            Text(
              _formatRelative(n.timestamp),
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        isThreeLine: true,
        trailing: Text(
          _formatTimeOfDay(n.timestamp),
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ),
    );
  }
}
