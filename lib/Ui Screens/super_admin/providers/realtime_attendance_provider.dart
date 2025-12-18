import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/data_models.dart';

/// Provider for real-time attendance tracking
class RealtimeAttendanceProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Map to store user attendance status by user ID
  Map<String, AttendanceStatus> _userAttendanceStatus = {};

  // Map to store if user is late (separate from presence)
  Map<String, bool> _userIsLate = {};

  // Real-time channels
  RealtimeChannel? _attendanceChannel;

  Map<String, AttendanceStatus> get userAttendanceStatus => _userAttendanceStatus;
  Map<String, bool> get userIsLate => _userIsLate;

  RealtimeAttendanceProvider() {
    _initializeRealtimeAttendance();
  }

  /// Initialize real-time attendance tracking
  Future<void> _initializeRealtimeAttendance() async {
    // First, fetch today's attendance
    await _fetchTodayAttendance();

    // Then setup real-time listener
    _setupRealtimeListener();
  }

  /// Fetch today's attendance for all users
  Future<void> _fetchTodayAttendance() async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // Fetch today's attendance logs
      final response = await _supabase
          .from('attendance_logs')
          .select('employee_id, check_in, status')
          .gte('check_in', startOfDay.toIso8601String())
          .lt('check_in', endOfDay.toIso8601String());

      // Process attendance data
      _userAttendanceStatus.clear();
      _userIsLate.clear();

      for (var record in response) {
        final employeeId = record['employee_id'].toString();
        final checkIn = record['check_in']?.toString();

        AttendanceStatus status;
        bool isLate = false;

        if (checkIn == null || checkIn.isEmpty || checkIn == 'null') {
          // No check-in = Absent
          status = AttendanceStatus.absent;
        } else {
          try {
            final checkInTime = DateTime.parse(checkIn).toLocal();
            final targetTime = DateTime(
              checkInTime.year,
              checkInTime.month,
              checkInTime.day,
              9, // 9 AM threshold
            );

            // IMPORTANT: Employee is ALWAYS present if they checked in
            status = AttendanceStatus.present;

            // Check if they checked in AFTER 9 AM (late)
            if (checkInTime.isAfter(targetTime)) {
              isLate = true;
            }
          } catch (e) {
            status = AttendanceStatus.absent;
          }
        }

        _userAttendanceStatus[employeeId] = status;
        _userIsLate[employeeId] = isLate;
      }

      debugPrint('✅ Fetched attendance for ${_userAttendanceStatus.length} users');

      // DEBUG: Print all users and their status
      for (var entry in _userAttendanceStatus.entries) {
        final isLate = _userIsLate[entry.key] ?? false;
        debugPrint('User ${entry.key}: Status=${entry.value}, IsLate=$isLate');
      }

      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error fetching today\'s attendance: $e');
    }
  }

  /// Setup real-time listener for attendance changes
  void _setupRealtimeListener() {
    _attendanceChannel = _supabase.channel('realtime_attendance_changes');

    _attendanceChannel!
        .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'attendance_logs',
      callback: (payload) {
        debugPrint('🔔 Real-time attendance change: ${payload.eventType}');

        // Refetch attendance when changes occur
        _fetchTodayAttendance();
      },
    )
        .subscribe();

    debugPrint('👂 Subscribed to real-time attendance updates');
  }

  /// Get attendance status for a specific user
  AttendanceStatus getUserStatus(String userId) {
    return _userAttendanceStatus[userId] ?? AttendanceStatus.absent;
  }

  /// Check if user is late
  bool isUserLate(String userId) {
    return _userIsLate[userId] ?? false;
  }

  /// Get attendance summary counts
  Map<String, int> getAttendanceSummary(List<String> userIds) {
    int presentCount = 0;
    int lateCount = 0;
    int absentCount = 0;

    for (var userId in userIds) {
      final status = getUserStatus(userId);
      final isLate = isUserLate(userId);

      if (status == AttendanceStatus.present) {
        if (isLate) {
          // Present but late
          lateCount++;
        } else {
          // Present on time
          presentCount++;
        }
      } else if (status == AttendanceStatus.absent) {
        absentCount++;
      }
    }

    return {
      'present': presentCount,
      'late': lateCount,
      'absent': absentCount,
      'total': userIds.length,
    };
  }

  /// Manually refresh attendance data
  Future<void> refreshAttendance() async {
    await _fetchTodayAttendance();
  }

  /// Clean up resources
  void dispose() {
    if (_attendanceChannel != null) {
      _supabase.removeChannel(_attendanceChannel!);
      _attendanceChannel = null;
    }
    super.dispose();
  }
}