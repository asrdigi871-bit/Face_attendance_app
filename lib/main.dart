import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'Ui Screens/session_handler.dart';
import 'Ui Screens/super_admin/providers/user_management_data.dart';
import 'Ui Screens/super_admin/providers/realtime_attendance_provider.dart';
import 'Ui Screens/super_admin/providers/settings_data.dart';
import 'Ui Screens/super_admin/screens/admin_dashboard_content.dart';
import 'Ui Screens/employee/employee_dashboard.dart';
import 'Ui Screens/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: "https://vqaggymejtrprzgjtlwd.supabase.co",
    anonKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZxYWdneW1lanRycHJ6Z2p0bHdkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY3OTQ1NTUsImV4cCI6MjA3MjM3MDU1NX0.kAhIDIMVbJyLnVBZ-_KyOtCnJZFvXk9LcGRVfpoRYsg",
    authOptions: const FlutterAuthClientOptions(
      autoRefreshToken: true,
      // ✅ persistSession removed
    ),
  );


  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserManagementData()),
        ChangeNotifierProvider(create: (_) => RealtimeAttendanceProvider()),
        ChangeNotifierProvider(create: (_) => SettingsData()),
        ChangeNotifierProvider(create: (_) => AdminProfileData()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return OverlaySupport.global(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'IDent Face Attendance',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: Colors.black87), // Default text color
          ),
          inputDecorationTheme: const InputDecorationTheme(
            hintStyle: TextStyle(color: Colors.grey),
          ),
        ),        home: const SessionHandler(), // Handles session persistence
      ),
    );
  }
}
