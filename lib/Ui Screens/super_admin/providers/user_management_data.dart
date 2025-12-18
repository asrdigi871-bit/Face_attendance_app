import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/data_models.dart';

class UserManagementData extends ChangeNotifier {
  final SupabaseClient supabase = Supabase.instance.client;

  final List<GenUiEmployee> _users = [];
  List<GenUiEmployee> get users => _users;

  RealtimeChannel? _realtimeChannel;

  // --- Fetch employees from Supabase ---
  Future<void> fetchEmployees() async {
    try {
      final List<Map<String, dynamic>> data = await supabase.from('users').select();

      debugPrint('✅ Supabase users fetched: ${data.length} records');

      _users
        ..clear()
        ..addAll(
          data.map((item) => GenUiEmployee(
            id: item['id'].toString(),
            name: item['name'] ?? '',
            email: item['email'] ?? '',
            role: item['role'] ?? '',
            department: item['department'] ?? '',
            idNumber: item['id_number'] ?? '',
            phoneNumber: item['phone_number'] ?? '',
            time: item['time'] ?? '09:00',
            profileImageUrl: item['profile_image_url'], // Added profile image URL
            status: AttendanceStatus.values.firstWhere(
                  (e) => e.toString() == 'AttendanceStatus.${item['status']}',
              orElse: () => AttendanceStatus.present,
            ),
          )),
        );

      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error fetching users: $e');
    }
  }

  // --- Start Realtime Subscription ---
  void startRealtimeSubscription() {
    if (_realtimeChannel != null) return; // avoid duplicates

    _realtimeChannel = supabase.channel('public:users');

    _realtimeChannel!
      ..onPostgresChanges(
        event: PostgresChangeEvent.all, // listen to all events (insert/update/delete)
        schema: 'public',
        table: 'users',
        callback: (payload) async {
          debugPrint('🔄 Realtime change: ${payload.eventType} on users');
          await fetchEmployees(); // reload data whenever a change happens
        },
      )
      ..subscribe();

    debugPrint('👂 Subscribed to realtime updates on users table');
  }

  // --- Stop Realtime ---
  void stopRealtimeSubscription() {
    if (_realtimeChannel != null) {
      supabase.removeChannel(_realtimeChannel!);
      _realtimeChannel = null;
      debugPrint('🛑 Realtime unsubscribed');
    }
  }

  // --- Add employee ---
  Future<void> addUser(GenUiEmployee user) async {
    await supabase.from('users').insert({
      'id': user.id,
      'name': user.name,
      'email': user.email,
      'role': user.role,
      'department': user.department,
      'id_number': user.idNumber,
      'phone_number': user.phoneNumber,
      'time': user.time,
      'profile_image_url': user.profileImageUrl, // Added
      'status': user.status.toString().split('.').last,
    });
  }

  // --- Update employee ---
  Future<void> updateUser(GenUiEmployee user) async {
    await supabase.from('users').update({
      'name': user.name,
      'email': user.email,
      'role': user.role,
      'department': user.department,
      'id_number': user.idNumber,
      'phone_number': user.phoneNumber,
      'time': user.time,
      'profile_image_url': user.profileImageUrl, // Added
      'status': user.status.toString().split('.').last,
    }).eq('id', user.id);
  }

  // --- Delete employee ---
  Future<void> removeUser(String id) async {
    await supabase.from('users').delete().eq('id', id);
  }
}