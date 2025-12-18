import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '/Ui Screens/login_page.dart';
import '/Ui Screens/employee/employee_dashboard.dart';
import '/Ui Screens/admin/Admin dashboard.dart';
import '/Ui Screens/super_admin/screens/admin_dashboard_content.dart';

class SessionHandler extends StatefulWidget {
  const SessionHandler({super.key});

  @override
  State<SessionHandler> createState() => _SessionHandlerState();
}

class _SessionHandlerState extends State<SessionHandler> {
  Session? _session;
  String? _role;
  bool _loading = true;
  late final StreamSubscription<AuthState> _authListener;

  @override
  void initState() {
    super.initState();
    _initSession();
  }

  Future<void> _initSession() async {
    final supabase = Supabase.instance.client;
    final session = supabase.auth.currentSession;

    if (session != null) {
      await _fetchUserData(session.user?.email);
    }

    setState(() {
      _session = session;
      _loading = false;
    });

    _authListener = supabase.auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      final newSession = data.session;

      setState(() {
        _session = newSession;
      });

      if (event == AuthChangeEvent.signedIn && newSession != null) {
        await _fetchUserData(newSession.user?.email);
      } else if (event == AuthChangeEvent.signedOut) {
        setState(() => _role = null);
      }
    });
  }

  Map<String, dynamic>? _userMap;
  Future<void> _fetchUserData(String? email) async {
    if (email == null) return;
    try {
      final response = await Supabase.instance.client
          .from('users')
          .select('id, name, email, role, department, profile_image_url')
          .eq('email', email)
          .maybeSingle();

      if (response != null) {
        setState(() {
          _role = response['role'] as String?;
        });

        // store full user map in state
        _userMap = response;
      }
    } catch (e) {
    }
  }


  @override
  void dispose() {
    _authListener.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AppSplashScreen(message: "Loading .....");
    }

    if (_session == null) {
      return const LoginScreen();
    }


    final userMap = {
      'id': _session!.user!.id,
      'email': _session!.user!.email,
      'role': _role,
    };

    if (_userMap == null) {
      return const AppSplashScreen(message: "Loading your dashboard...");
    }

    switch (_role) {
      case 'super admin':
        return UpdatedAdminDashboardContent(userData: _userMap!);
      case 'admin':
        return const MainAdminScreen();
      case 'employee':
        return const EmployeeDashboard();
      default:
        return const LoginScreen();
    }

  }
}

/// 🌟 Beautiful splash/loading screen with logo and animation
class AppSplashScreen extends StatelessWidget {
  final String message;
  const AppSplashScreen({required this.message, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB), // Soft bluish-white
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            //  App Logo
            Image.asset(
              'assets/images/IDent_Logo.png', // Make sure this path matches your asset location
              height: 120,
            ),
            const SizedBox(height: 25),

            //  App Name
            const Text(
              "IDent Face Attendance",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3A8A), // Deep blue
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 40),

            //  Modern Loader
            const SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                color: Color(0xFF6366F1), // Indigo tone
              ),
            ),
            const SizedBox(height: 25),

            //  Dynamic Loading Message
            Text(
              message,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
