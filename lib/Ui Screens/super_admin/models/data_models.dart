import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// --- Enums ---
enum AttendanceStatus { present, late, absent }
enum UserFilter { employees, admins }
enum TimeFilter { month, week, year }

// --- Data Models ---

// Unified Data model for a user
class GenUiEmployee {
  final String id; // <-- Added for Supabase unique ID
  final String name;
  final String email;
  final String role; // 'employee' or 'admin'
  final String time; // Represents check-in time or other time-related info
  final AttendanceStatus status;
  final String? department;
  final String idNumber;
  final String phoneNumber;
  final String? profileImageUrl; // Added profile image URL

  GenUiEmployee({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.time = 'N/A',
    this.status = AttendanceStatus.absent,
    this.department,
    this.idNumber = 'N/A',
    this.phoneNumber = 'N/A',
    this.profileImageUrl, // Added
  });

  // Helper for updating immutable object
  GenUiEmployee copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? time,
    AttendanceStatus? status,
    String? department,
    String? idNumber,
    String? phoneNumber,
    String? profileImageUrl, // Added
  }) {
    return GenUiEmployee(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      time: time ?? this.time,
      status: status ?? this.status,
      department: department ?? this.department,
      idNumber: idNumber ?? this.idNumber,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl, // Added
    );
  }
}

// Data model for daily attendance summary for the graph
class MyAttendanceSummaryDaily {
  final int total;
  final int present;
  final int late;
  final int absent;

  MyAttendanceSummaryDaily({
    required this.total,
    required this.present,
    required this.late,
    required this.absent,
  });
}

// Data model for individual employee's daily attendance record
class EmployeeDailyAttendanceRecord {
  final DateTime date;
  final AttendanceStatus status;
  final String? checkInTime; // Optional: specific time for that day
  final String? checkOutTime; // Optional checkout time

  EmployeeDailyAttendanceRecord({
    required this.date,
    required this.status,
    this.checkInTime,
    this.checkOutTime,
  });
}

// --- Data Model for Holidays ---
class Holiday {
  final String name;
  final DateTime date;
  final String? description;

  Holiday({required this.name, required this.date, this.description});
}

// --- Data Model for Notifications ---
class NotificationItem {
  final String title;
  final String message;
  final DateTime timestamp;
  bool isRead;

  NotificationItem({
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });
}