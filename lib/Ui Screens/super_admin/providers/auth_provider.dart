import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provider to manage authenticated user data
class AuthProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Current logged-in user data
  Map<String, dynamic>? _currentUserData;
  bool _isLoading = true;

  Map<String, dynamic>? get currentUserData => _currentUserData;
  bool get isLoading => _isLoading;

  // User details getters
  String get userName => _currentUserData?['name'] ?? 'Super Admin';
  String get userEmail => _currentUserData?['email'] ?? 'admin@example.com';
  String get userRole => _currentUserData?['role'] ?? 'Super Admin';
  String get userDepartment => _currentUserData?['department'] ?? 'User Management';
  String? get profileImageUrl => _currentUserData?['profile_image_url'];

  AuthProvider() {
    _initializeUser();
  }

  /// Initialize and fetch current user data
  Future<void> _initializeUser() async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = _supabase.auth.currentUser;

      if (user != null) {
        // Fetch user data from users table
        final response = await _supabase
            .from('users')
            .select()
            .eq('email', user.email ?? '')
            .maybeSingle();

        if (response != null) {
          _currentUserData = response;
          debugPrint('✅ User data loaded: ${_currentUserData?['name']}');
        } else {
          // If not in users table, check super_admins table
          final adminResponse = await _supabase
              .from('super_admins')
              .select()
              .eq('email', user.email ?? '')
              .maybeSingle();

          if (adminResponse != null) {
            _currentUserData = {
              'id': adminResponse['id'].toString(),
              'name': adminResponse['name'],
              'email': adminResponse['email'],
              'role': 'Super Admin',
              'department': 'User Management',
              'profile_image_url': null,
            };
            debugPrint('✅ Super Admin data loaded: ${_currentUserData?['name']}');
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading user data: $e');
      // Set default admin data
      _currentUserData = {
        'name': 'Super Admin',
        'email': 'admin@example.com',
        'role': 'Super Admin',
        'department': 'User Management',
      };
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh user data
  Future<void> refreshUserData() async {
    await _initializeUser();
  }

  /// Update profile image URL
  Future<void> updateProfileImage(String imageUrl) async {
    if (_currentUserData != null) {
      try {
        await _supabase
            .from('users')
            .update({'profile_image_url': imageUrl})
            .eq('id', _currentUserData!['id']);

        _currentUserData!['profile_image_url'] = imageUrl;
        notifyListeners();
        debugPrint('✅ Profile image updated');
      } catch (e) {
        debugPrint('❌ Error updating profile image: $e');
      }
    }
  }

  /// Clear user data on logout
  void clearUserData() {
    _currentUserData = null;
    notifyListeners();
  }
}