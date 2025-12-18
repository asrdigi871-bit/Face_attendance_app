import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  static final supabase = Supabase.instance.client;

  /// Initialize realtime listeners
  static void initListeners() {
    _listenToUserChanges();
    _listenToAttendanceLogs();
  }

  /// 🔹 Users table listener
  static void _listenToUserChanges() {
    supabase
        .channel('users-changes')
        .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'users',
      callback: (payload) {
        final newUser = payload.newRecord;
        _showInAppNotification(
          "👤 New Employee Added",
          "${newUser['email']} joined the company",
        );
      },
    )
        .onPostgresChanges(
      event: PostgresChangeEvent.delete,
      schema: 'public',
      table: 'users',
      callback: (payload) {
        final oldUser = payload.oldRecord;
        _showInAppNotification(
          "❌ Employee Removed",
          "${oldUser['email']} was deleted",
        );
      },
    )
        .subscribe();
  }

  /// 🔹 Attendance logs listener
  static void _listenToAttendanceLogs() {
    supabase
        .channel('attendance-changes')
        .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'attendance_logs',
      callback: (payload) {
        final log = payload.newRecord;
        if (log['status'] == 'late') {
          _showInAppNotification(
            "⚠️ Late Check-in",
            "${log['employee_name']} checked in late",
          );
        }
      },
    )
        .subscribe();
  }

  /// 🔹 Helper for showing notification
  static void _showInAppNotification(String title, String message) {
    showSimpleNotification(
      Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(message),
      background: Colors.blueAccent,
      duration: const Duration(seconds: 4),
    );
  }
}
