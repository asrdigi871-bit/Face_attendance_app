import 'package:flutter/material.dart';
import 'dart:math';
import 'package:intl/intl.dart';
import '../models/data_models.dart';

// --- Data Model for Attendance Data Provider ---
class AttendanceDataProvider extends ChangeNotifier {
  // Helper to calculate summary for a given list of GenUiEmployee
  Map<String, int> getAttendanceSummary(List<GenUiEmployee> users) {
    int presentCount = 0;
    int lateCount = 0;
    int absentCount = 0;

    for (final GenUiEmployee user in users) {
      if (user.status == AttendanceStatus.present) {
        presentCount++;
      } else if (user.status == AttendanceStatus.late) {
        lateCount++;
      } else {
        absentCount++;
      }
    }
    return <String, int>{
      'present': presentCount,
      'late': lateCount,
      'absent': absentCount,
      'total': users.length,
    };
  }

  // Method to generate mock historical attendance data for a single employee
  List<EmployeeDailyAttendanceRecord> getEmployeeHistoricalAttendance(
      String employeeEmail, {
        int days = 30, // Default to 30 days for filtering flexibility
      }) {
    // This is mock data generation for demonstration
    final List<EmployeeDailyAttendanceRecord> records =
    <EmployeeDailyAttendanceRecord>[];
    final Random random = Random();
    final DateTime today = DateTime.now();

    for (int i = days - 1; i >= 0; i--) {
      final DateTime date = DateTime(
        today.year,
        today.month,
        today.day,
      ).subtract(Duration(days: i));
      AttendanceStatus status;
      String? checkInTime;
      String? checkOutTime;

      final int statusRoll = random.nextInt(100); // 0-99
      if (statusRoll < 70) {
        // 70% present
        status = AttendanceStatus.present;
        DateTime checkInDateTime = date.add(
          Duration(hours: 8 + random.nextInt(2), minutes: random.nextInt(60)),
        ); // 8-10 AM
        checkInTime = DateFormat('HH:mm').format(checkInDateTime);

        DateTime checkOutDateTime = checkInDateTime.add(
          Duration(hours: 8 + random.nextInt(2), minutes: random.nextInt(60)),
        ); // 8-10 hours later
        checkOutTime = DateFormat('HH:mm').format(checkOutDateTime);
      } else if (statusRoll < 85) {
        // 15% late
        status = AttendanceStatus.late;
        DateTime checkInDateTime = date.add(
          Duration(hours: 10 + random.nextInt(3), minutes: random.nextInt(60)),
        ); // 10 AM - 1 PM
        checkInTime = DateFormat('HH:mm').format(checkInDateTime);

        DateTime checkOutDateTime = checkInDateTime.add(
          Duration(hours: 7 + random.nextInt(2), minutes: random.nextInt(60)),
        ); // 7-9 hours later
        checkOutTime = DateFormat('HH:mm').format(checkOutDateTime);
      } else {
        // 15% absent
        status = AttendanceStatus.absent;
        checkInTime = null;
        checkOutTime = null;
      }

      records.add(
        EmployeeDailyAttendanceRecord(
          date: date,
          status: status,
          checkInTime: checkInTime,
          checkOutTime: checkOutTime,
        ),
      );
    }
    return records;
  }
}