import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart'; // for debugPrint

final supabase = Supabase.instance.client;

class SupabaseService {
  RealtimeChannel? _usersChannel;
  RealtimeChannel? _attendanceChannel;

  // ---------------- AUTH ----------------
  Future<User?> signIn(String email, String password) async {
    final AuthResponse res = await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return res.user;
  }

  Future<User?> signUp(String email, String password) async {
    final AuthResponse res = await supabase.auth.signUp(
      email: email,
      password: password,
    );
    return res.user;
  }

  Future<void> signOut() async => await supabase.auth.signOut();

  // ---------------- USERS ----------------
  Future<List<Map<String, dynamic>>> getUsers() async {
    try {
      final List<Map<String, dynamic>> res = await supabase
          .from('users')
          .select()
          .order('created_at', ascending: false);

      debugPrint('✅ USERS fetched: ${res.length}');
      return res;
    } catch (e) {
      debugPrint('❌ Error fetching users: $e');
      return [];
    }
  }

  Future<void> addUser(Map<String, dynamic> data) async {
    await supabase.from('users').insert(data);
  }

  Future<void> updateUser(int id, Map<String, dynamic> data) async {
    await supabase.from('users').update(data).eq('id', id);
  }

  Future<void> deleteUser(int id) async {
    await supabase.from('users').delete().eq('id', id);
  }

  // ---------------- ATTENDANCE ----------------
  Future<void> markAttendance({
    required int employeeId,
    required String status,
    String? photoUrl,
  }) async {
    final now = DateTime.now().toUtc();

    await supabase.from('attendance_logs').insert({
      'employee_id': employeeId,
      'check_in': now.toIso8601String(),
      'created_at': now.toIso8601String(),
      'date': now.toIso8601String(),
      'status': status,
      'photo_url': photoUrl,
    });

    debugPrint('✅ Attendance marked for employee $employeeId');
  }

  Future<List<Map<String, dynamic>>> getAttendanceLogs(int employeeId) async {
    try {
      final List<Map<String, dynamic>> res = await supabase
          .from('attendance_logs')
          .select()
          .eq('employee_id', employeeId)
          .order('created_at', ascending: false);

      debugPrint('✅ ATTENDANCE fetched: ${res.length} records for employee $employeeId');
      return res;
    } catch (e) {
      debugPrint('❌ Error fetching attendance logs: $e');
      return [];
    }
  }

  // ---------------- REALTIME SUBSCRIPTIONS ----------------

  // Realtime for users table
  void startUserRealtime(void Function(String event, Map<String, dynamic> data) onChange) {
    _usersChannel ??= supabase.channel('public:users');

    _usersChannel!
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'users',
        callback: (payload) {
          debugPrint('👂 USERS Realtime: ${payload.eventType}');
          onChange(payload.eventType.name, payload.newRecord ?? {});
        },
      )
      ..subscribe();

    debugPrint('✅ Subscribed to USERS realtime changes');
  }

  // Realtime for attendance_logs table
  void startAttendanceRealtime(void Function(String event, Map<String, dynamic> data) onChange) {
    _attendanceChannel ??= supabase.channel('public:attendance_logs');

    _attendanceChannel!
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'attendance_logs',
        callback: (payload) {
          debugPrint('👂 ATTENDANCE Realtime: ${payload.eventType}');
          onChange(payload.eventType.name, payload.newRecord ?? {});
        },
      )
      ..subscribe();

    debugPrint('✅ Subscribed to ATTENDANCE realtime changes');
  }

  void stopAllRealtime() {
    if (_usersChannel != null) {
      supabase.removeChannel(_usersChannel!);
      _usersChannel = null;
    }
    if (_attendanceChannel != null) {
      supabase.removeChannel(_attendanceChannel!);
      _attendanceChannel = null;
    }
    debugPrint('🛑 Realtime unsubscribed for users and attendance_logs');
  }
}
