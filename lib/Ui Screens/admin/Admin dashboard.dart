import 'package:flutter/material.dart';
import 'package:my_app/Ui%20Screens/login_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'manage_users_page.dart';
import '../mark_attendance.dart';
import '/Ui Screens/employee/employee_dashboard.dart';
import 'dart:io';
import 'dart:ui';
import 'package:intl/intl.dart';

class MainAdminScreen extends StatefulWidget {
  const MainAdminScreen({super.key});

  @override
  State<MainAdminScreen> createState() => _MainAdminScreenState();
}

class _MainAdminScreenState extends State<MainAdminScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late final List<Widget> _screens;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _verifyAdmin();
    _screens = const [
      AdminDashboardSimplified(),
      FaceAttendancePage(),
      ManageUsersPage(),
    ];

    // Animation setup
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

// ✅ Move this outside initState
  Future<void> _verifyAdmin() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final response = await Supabase.instance.client
        .from('users')
        .select('role')
        .eq('id', user.id)
        .maybeSingle();

    final role = response?['role'];

    if (role != 'admin' && mounted) {
      // ❌ Not an admin → Redirect to Employee Dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const EmployeeDashboard()),
      );
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: "Dashboard",
          ),
          BottomNavigationBarItem(
            icon: _QRCodeScanIcon(isActive: _currentIndex == 1),
            label: "Attendance",
          ),

          const BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: "Users",
          ),
        ],
      ),
    );
  }
}



class _QRCodeScanIcon extends StatefulWidget {
  final bool isActive;
  const _QRCodeScanIcon({required this.isActive});

  @override
  State<_QRCodeScanIcon> createState() => _QRCodeScanIconState();
}

class _QRCodeScanIconState extends State<_QRCodeScanIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scanAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _controller =
    AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat();

    _scanAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );

    // Pulse animation for scaling the icon
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: SizedBox(
            width: 60,  // Increased size
            height: 60, // Increased size
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Colors.blueAccent,Colors.lightBlueAccent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueAccent.withOpacity(0.5),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.qr_code_scanner,
                  size: 36, // Bigger icon
                  color: widget.isActive ? Colors.white : Colors.white,
                ),
                Positioned(
                  top: 8 + 44 * _scanAnimation.value,
                  child: Container(
                    width: 44,
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.0),
                          Colors.white.withOpacity(0.8),
                          Colors.white.withOpacity(0.0),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}


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
  Map<String, List<NotificationItem>> _groupByDay(
      List<NotificationItem> items,
      ) {
    final Map<String, List<NotificationItem>> result = {
      'Today': <NotificationItem>[],
      'Yesterday': <NotificationItem>[],
      'Earlier': <NotificationItem>[],
    };
    final now = DateTime.now();
    DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
    final DateTime today = dateOnly(now);
    final DateTime yesterday = dateOnly(now.subtract(const Duration(days: 1)));

    for (final NotificationItem item in items) {
      final DateTime d = dateOnly(item.timestamp);
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
    final Duration diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
  }

  String _formatTimeOfDay(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final List<NotificationItem> items = _sampleData();
    final Map<String, List<NotificationItem>> sections = _groupByDay(items);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87, // black title like your image
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              Navigator.pop(context);            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          for (final String sectionTitle in <String>['Today', 'Yesterday', 'Earlier']) ...<Widget>[
            if (sections[sectionTitle]!.isNotEmpty) ...<Widget>[
              _buildSectionTitle(sectionTitle),
              const SizedBox(height: 8),
              for (final NotificationItem item in sections[sectionTitle]!)
                _buildNotificationCard(item),
              const SizedBox(height: 12),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 2),
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
        title: Text(
          n.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize
              .min, // <-- IMPORTANT: prevents render overflow / unbounded height
          children: <Widget>[
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

// Add these
String userName = "User";
String userRole = "NA";
String userDepartment = "NA";
String? userProfileImage;

/// ---------------- DASHBOARD WITH GRAPHS & EXPORT ----------------
class AdminDashboardSimplified extends StatefulWidget {
  const AdminDashboardSimplified({super.key});

  @override
  State<AdminDashboardSimplified> createState() =>
      _AdminDashboardSimplifiedState();
}

class _AdminDashboardSimplifiedState extends State<AdminDashboardSimplified> {
  final supabase = Supabase.instance.client;

  int totalEmployees = 0;
  int present = 0;
  int late = 0;
  int absent = 0;
  String? userName, userRole, userDepartment, userProfileImage;
  DateTime? latestCheckIn, latestCheckOut;

  List<Map<String, dynamic>> liveAttendance = [];
  List<Map<String, dynamic>> weeklyAttendance = [];

  @override
  void initState() {
    super.initState();

    // Call async functions safely
    _fetchSummaryAndLiveAttendance();
    _fetchWeeklyAttendance();
    // _fetchAdminCheckTimes();
    _fetchUserHeaderData();
  }

  Future<void> _fetchUserHeaderData() async {
    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) return;

      // Fetch user info
      final response = await supabase
          .from('users')
          .select('id, name, role, department, profile_image_url')
          .eq('email', currentUser.email!)
          .maybeSingle();

      if (response != null && response is Map<String, dynamic>) {
        final userId = response['id'];

        // Fetch latest attendance entry
        final latestAttendance = await supabase
            .from('attendance_logs')
            .select('check_in, check_out')
            .eq('employee_id', userId)
            .order('check_in', ascending: false)
            .limit(1)
            .maybeSingle();

        DateTime? checkIn;
        DateTime? checkOut;

        if (latestAttendance != null && latestAttendance['check_in'] != null) {
          final fetchedCheckIn = DateTime.parse(latestAttendance['check_in']).toLocal();

          // Check if fetched date is today
          final now = DateTime.now();
          final isToday = fetchedCheckIn.year == now.year &&
              fetchedCheckIn.month == now.month &&
              fetchedCheckIn.day == now.day;

          if (isToday) {
            checkIn = fetchedCheckIn;

            if (latestAttendance['check_out'] != null) {
              checkOut = DateTime.parse(latestAttendance['check_out']).toLocal();
            }
          }
        }

        setState(() {
          userName = response['name'] ?? "User";
          userRole = response['role'] ?? "NA";
          userDepartment = response['department'] ?? "NA";
          userProfileImage = response['profile_image_url'];
          latestCheckIn = checkIn;
          latestCheckOut = checkOut;
        });
      }
    } catch (e) {
      debugPrint('Error fetching header data: $e');
    }
  }


  Future<void> _fetchSummaryAndLiveAttendance() async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // 1️⃣ Get all employees
      final userResponse = await supabase
          .from('users')
          .select('id, name, role, profile_image_url')
          .eq('role', 'employee'); // case-sensitive safe in Supabase

      final employees = List<Map<String, dynamic>>.from(userResponse);

      // 2️⃣ Get today's attendance logs only
      final logsResponse = await supabase
          .from('attendance_logs')
          .select('employee_id, check_in')
          .gte('check_in', startOfDay.toIso8601String())
          .lt('check_in', endOfDay.toIso8601String());

      final logs = List<Map<String, dynamic>>.from(logsResponse);

      // 3️⃣ Build attendance status for each employee
      final List<Map<String, dynamic>> tempLive = [];
      int presentCount = 0;
      int lateCount = 0;
      int absentCount = 0;

      final lateThreshold = DateTime(today.year, today.month, today.day, 9, 15);

      for (final emp in employees) {
        final empId = emp['id'];
        final empName = emp['name'] ?? "Unknown";
        final profileImage = emp['profile_image_url'];

        // Find today's log for this employee
        final todayLog = logs.firstWhere(
              (l) => l['employee_id'] == empId,
          orElse: () => {},
        );

        if (todayLog.isEmpty) {
          // ❌ No attendance today → mark as Absent
          absentCount++;
          tempLive.add({
            'name': empName,
            'status': 'Absent',
            'time': '-',
            'color': Colors.redAccent,
            'profile_image': profileImage,
          });
        } else {
          final checkIn = DateTime.parse(todayLog['check_in']).toLocal();
          final formattedTime =
              "${checkIn.hour.toString().padLeft(2, '0')}:${checkIn.minute.toString().padLeft(2, '0')}";

          if (checkIn.isAfter(lateThreshold)) {
            lateCount++;
            tempLive.add({
              'name': empName,
              'status': 'Late',
              'time': formattedTime,
              'color': Colors.orangeAccent,
              'profile_image': profileImage,
            });
          } else {
            presentCount++;
            tempLive.add({
              'name': empName,
              'status': 'Present',
              'time': formattedTime,
              'color': Colors.green,
              'profile_image': profileImage,
            });
          }
        }
      }

      // 4️⃣ Sort list by status (Present → Late → Absent)
      tempLive.sort((a, b) {
        const order = {'Present': 0, 'Late': 1, 'Absent': 2};
        return order[a['status']]!.compareTo(order[b['status']]!);
      });

      if (!mounted) return;
      setState(() {
        totalEmployees = employees.length;
        present = presentCount;
        late = lateCount;
        absent = absentCount;
        liveAttendance = tempLive;
      });
    } catch (e) {
      debugPrint("Error fetching summary and attendance: $e");
    }
  }


  Future<void> _fetchWeeklyAttendance() async {
    try {
      // 1️⃣ Fetch only employees (exclude admins)
      final employeesResponse = await supabase
          .from('users')
          .select('id, name, role')
          .ilike('role', 'employee'); // ✅ only employees (case-insensitive)

      final employees = List<Map<String, dynamic>>.from(employeesResponse);

      // 2️⃣ Define date range for last 7 days
      final now = DateTime.now();
      final startDate = now.subtract(const Duration(days: 6));
      final startIso = DateTime(startDate.year, startDate.month, startDate.day)
          .toIso8601String();

      // 3️⃣ Fetch attendance logs for last 7 days
      final logsResponse = await supabase
          .from('attendance_logs')
          .select('employee_id, check_in')
          .gte('check_in', startIso);

      final logs = List<Map<String, dynamic>>.from(logsResponse);

      // 4️⃣ Filter logs to only include employees
      final employeeIds = employees.map((e) => e['id']).toSet();
      final filteredLogs =
      logs.where((log) => employeeIds.contains(log['employee_id'])).toList();

      // 5️⃣ Prepare map for weekday summary
      final List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
      final Map<String, Map<String, int>> summary = {
        for (var day in days) day: {'present': 0, 'late': 0, 'absent': 0}
      };

      // 6️⃣ Define late threshold (e.g., after 9:15 AM = late)
      const int lateHour = 9;
      const int lateMinute = 15;

      // 7️⃣ Process attendance logs
      for (var log in filteredLogs) {
        final checkIn = DateTime.parse(log['check_in']);
        if (checkIn.weekday == DateTime.sunday) continue; // skip Sunday

        final dayLabel = days[checkIn.weekday - 1];
        final lateThreshold =
        DateTime(checkIn.year, checkIn.month, checkIn.day, lateHour, lateMinute);

        if (checkIn.isAfter(lateThreshold)) {
          summary[dayLabel]!['late'] = summary[dayLabel]!['late']! + 1;
        } else {
          summary[dayLabel]!['present'] = summary[dayLabel]!['present']! + 1;
        }
      }

      // 8️⃣ Calculate absentees
      for (var day in days) {
        final totalPresentLate =
            summary[day]!['present']! + summary[day]!['late']!;
        summary[day]!['absent'] =
            (employees.length - totalPresentLate).clamp(0, employees.length);
      }

      // 9️⃣ Convert summary to list
      final weeklyData = days
          .map((d) => {
        'day': d,
        'present': summary[d]!['present'],
        'late': summary[d]!['late'],
        'absent': summary[d]!['absent'],
      })
          .toList();

      if (!mounted) return;
      setState(() {
        weeklyAttendance = weeklyData;
      });
    } catch (e) {
      debugPrint('Error fetching weekly attendance: $e');
    }
  }

Future<void> _logout(BuildContext context) async {
  final shouldLogout = await showDialog<bool>(
    context: context,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon at the top
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.redAccent.withOpacity(0.2),
              child: const Icon(
                Icons.logout,
                color: Colors.redAccent,
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            // Title
            const Text(
              'Confirm Logout',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            // Description
            const Text(
              'Are you sure you want to log out?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 24),
            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Cancel button
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.grey),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                // Logout button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Logout'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );


  if (shouldLogout == true) {
    try {
      await Supabase.instance.client.auth.signOut();

      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging out: $e')),
      );
    }
  }
}

  // List<Map<String, dynamic>> todayLogs = [];
  //
  // Future<void> _fetchAdminCheckTimes() async {
  //   try {
  //     final currentUser = supabase.auth.currentUser;
  //     if (currentUser == null) return;
  //
  //     final today = DateTime.now();
  //     final startOfDay = DateTime(today.year, today.month, today.day);
  //     final endOfDay = startOfDay.add(const Duration(days: 1));
  //
  //     final response = await supabase
  //         .from('attendance_logs')
  //         .select('check_in, check_out')
  //         .eq('employee_id', currentUser.id)
  //         .gte('check_in', startOfDay.toIso8601String())
  //         .lt('check_in', endOfDay.toIso8601String())
  //         .order('check_in', ascending: false);
  //
  //     if (response != null && response is List) {
  //       todayLogs = List<Map<String, dynamic>>.from(response);
  //       if (!mounted) return;
  //
  //       setState(() {
  //         if (todayLogs.isNotEmpty) {
  //           final log = todayLogs.first;
  //           final checkIn = log['check_in'] != null
  //               ? DateTime.parse(log['check_in']).toLocal()
  //               : null;
  //           final checkOut = log['check_out'] != null
  //               ? DateTime.tryParse(log['check_out'])?.toLocal()
  //               : null;
  //
  //           checkInTime = checkIn != null
  //               ? "${checkIn.hour.toString().padLeft(2, '0')}:${checkIn.minute.toString().padLeft(2, '0')}"
  //               : "-";
  //           checkOutTime = checkOut != null
  //               ? "${checkOut.hour.toString().padLeft(2, '0')}:${checkOut.minute.toString().padLeft(2, '0')}"
  //               : "-";
  //         } else {
  //           checkInTime = "-";
  //           checkOutTime = "-";
  //         }
  //       });
  //     }
  //   } catch (e) {
  //     debugPrint("Error fetching admin check-in/out times: $e");
  //   }
  // }

  Widget _buildBarChart() {
    // Weekdays excluding Sunday
    final List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return AspectRatio(
      aspectRatio: 1.6,
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: 10, // adjust depending on total values
              gridData: FlGridData(
                show: true,
                drawHorizontalLine: true,
                horizontalInterval: 2,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.grey.withOpacity(0.2),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (group) => Colors.blueGrey.shade800,
                  tooltipPadding: const EdgeInsets.all(10),
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final day = days[groupIndex];
                    final data = weeklyAttendance[groupIndex];
                    final present = data['present'] ?? 0;
                    final late = data['late'] ?? 0;
                    final absent = data['absent'] ?? 0;
                    final total = present + late + absent;

                    return BarTooltipItem(
                      '$day\n',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      children: [
                        TextSpan(
                          text: 'Present: $present\n',
                          style: const TextStyle(
                              color: Colors.greenAccent, fontSize: 12),
                        ),
                        TextSpan(
                          text: 'Late: $late\n',
                          style: const TextStyle(
                              color: Colors.amberAccent, fontSize: 12),
                        ),
                        TextSpan(
                          text: 'Absent: $absent\n',
                          style: const TextStyle(
                              color: Colors.redAccent, fontSize: 12),
                        ),
                        TextSpan(
                          text: 'Total: $total',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: 2,
                    getTitlesWidget: (value, meta) => Text(
                      value.toInt().toString(),
                      style: const TextStyle(
                          fontSize: 11, color: Colors.black54),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < days.length) {
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          space: 6,
                          child: Text(
                            days[index],
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),

              // 🟩🟨🟥 Each bar stacked by present, late, absent
              barGroups: List.generate(days.length, (index) {
                final data = weeklyAttendance[index];
                final present = (data['present'] ?? 0).toDouble();
                final late = (data['late'] ?? 0).toDouble();
                final absent = (data['absent'] ?? 0).toDouble();

                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: present + late + absent,
                      width: 18,
                      rodStackItems: [
                        BarChartRodStackItem(0, present, Colors.greenAccent.shade400),
                        BarChartRodStackItem(
                            present, present + late, Colors.amberAccent.shade200),
                        BarChartRodStackItem(present + late,
                            present + late + absent, Colors.redAccent.shade200),
                      ],
                      borderRadius: BorderRadius.circular(6),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: 10,
                        color: Colors.grey.withOpacity(0.1),
                      ),
                    ),
                  ],
                );
              }),
            ),
            swapAnimationDuration: const Duration(milliseconds: 800),
            swapAnimationCurve: Curves.easeInOut,
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    double attendancePercent =
    totalEmployees > 0 ? present / totalEmployees : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB), // modern light grey background
      appBar: AppBar(
        elevation: 2,
        backgroundColor: Colors.blueAccent,
        title: const Text(
          "Admin Dashboard",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => _logout(context),
          ),
        ],
      ),

      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            // Add refresh logic if needed]

          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// --- Profile Header ---
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.blueAccent, Colors.lightBlue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Profile Picture
                      CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.white,
                        backgroundImage: (userProfileImage != null && userProfileImage!.isNotEmpty)
                            ? NetworkImage(userProfileImage!)
                            : null,
                        child: (userProfileImage == null || userProfileImage!.isEmpty)
                            ? const Icon(Icons.person, size: 35, color: Colors.blueAccent)
                            : null,
                      ),

                      const SizedBox(width: 16),

                      // User Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName ?? "Loading...",
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              userRole ?? "Role",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              userDepartment ?? "Department",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 10),
                            SingleChildScrollView( // ✅ prevents overflow on small devices
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  Icon(Icons.login, size: 18, color: Colors.greenAccent.shade100),
                                  const SizedBox(width: 5),
                                  Text(
                                    latestCheckIn != null
                                        ? "In: ${DateFormat('hh:mm a').format(latestCheckIn!)}"
                                        : "In: --",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Icon(Icons.logout, size: 18, color: Colors.redAccent.shade100),
                                  const SizedBox(width: 5),
                                  Text(
                                    latestCheckOut != null
                                        ? "Out: ${DateFormat('hh:mm a').format(latestCheckOut!)}"
                                        : "Out: --",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                /// --- Attendance Summary Card ---
                Card(
                  elevation: 4,
                  shadowColor: Colors.blue.withOpacity(0.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Today's Attendance Summary",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // First row: Present and Total
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _summaryBox(
                              present.toString(),
                              "Present",
                              Colors.green.shade50,
                              Colors.green,
                            ),
                            _summaryBox(
                              totalEmployees.toString(),
                              "Total",
                              Colors.blue.shade50,
                              Colors.blueAccent,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Second row: Late and Absent
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _summaryBox(
                              late.toString(),
                              "Late",
                              Colors.amber.shade50,
                              Colors.amber,
                            ),
                            _summaryBox(
                              absent.toString(),
                              "Absent",
                              Colors.red.shade50,
                              Colors.redAccent,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: attendancePercent,
                            minHeight: 8,
                            backgroundColor: Colors.grey[300],
                            color: Colors.blueAccent,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            "${(attendancePercent * 100).toStringAsFixed(1)}% Attendance",
                            style: const TextStyle(fontSize: 13, color: Colors.black54),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                /// --- Live Attendance Section ---
                const Text(
                  "Live Attendance",
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                liveAttendance.isEmpty
                    ? Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                  child: const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        "No employees found.",
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                    ),
                  ),
                )
                    : ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: liveAttendance.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final log = liveAttendance[index];
                    final name = log['name'];
                    final time = log['time'];
                    final status = log['status'];
                    final color = log['color'];
                    final profileImage = log['profile_image'];

                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      shadowColor: Colors.grey.withOpacity(0.2),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 25,
                              backgroundColor: Colors.grey[200],
                              backgroundImage:
                              (profileImage != null && profileImage.isNotEmpty) ? NetworkImage(profileImage) : null,
                              child: (profileImage == null || profileImage.isEmpty)
                                  ? const Icon(Icons.person, color: Colors.blueAccent)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    time,
                                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 25),

                /// --- Attendance Overview Chart ---
                const Text(
                  "Attendance Overview (Last 7 Days)",
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 250,
                          child: weeklyAttendance.isEmpty
                              ? const Center(child: Text("No data available"))
                              : _buildBarChart(),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            _LegendDot(color: Colors.green, label: "Present"),
                            SizedBox(width: 16),
                            _LegendDot(color: Colors.redAccent, label: "Absent"),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}
class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}

/// ---------------- HELPER WIDGETS ----------------
Widget _summaryBox(String value, String label, Color bgColor, Color textColor) {
  return Container(
    padding: const EdgeInsets.all(16),
    width: 140,
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
        const SizedBox(height: 6),
        Text(label),
      ],
    ),
  );
}

class _attendanceTile extends StatelessWidget {
  final String name;
  final String time;
  final String status;
  final Color color;
  final String? profileImageUrl;

  const _attendanceTile(
      {required this.name,
        required this.time,
        required this.status,
        required this.color,
        this.profileImageUrl});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.grey[300],
        backgroundImage: (profileImageUrl != null && profileImageUrl!.isNotEmpty)
            ? NetworkImage(profileImageUrl!)

            : null,
        child: (profileImageUrl == null || profileImageUrl!.isEmpty)
            ? Text(
          name.substring(0, 2).toUpperCase(),
          style: const TextStyle(color: Colors.white),
        )
            : null,
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(time),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          status,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}


/// ---------------- FACE ATTENDANCE (Placeholder) ----------------
/// ---------------- FACE ATTENDANCE (Fixed) ----------------
class FaceAttendancePage extends StatefulWidget {
  const FaceAttendancePage({super.key});

  @override
  State<FaceAttendancePage> createState() => _FaceAttendancePageState();
}

class _FaceAttendancePageState extends State<FaceAttendancePage> {
  bool _loading = true;
  String? _employeeId;
  String? _employeeCode;
  bool _hasNavigated = false; // ✅ Add flag to prevent multiple navigations

  @override
  void initState() {
    super.initState();
    _fetchEmployeeData();
  }

  Future<void> _fetchEmployeeData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null || user.email == null) throw "No logged-in user found";

      final response = await Supabase.instance.client
          .from('users')
          .select('id, employee_code')
          .eq('email', user.email!)
          .limit(1)
          .maybeSingle();

      if (response != null &&
          response['id'] != null &&
          response['employee_code'] != null) {
        _employeeId = response['id'].toString();
        _employeeCode = response['employee_code'].toString();
      }

      if (mounted) {
        setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ✅ NEW: Manual navigation triggered by button press
  void _navigateToMarkAttendance() {
    if (_hasNavigated) return; // Prevent multiple navigations

    if (_employeeId == null || _employeeCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Employee data not loaded. Please try again."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _hasNavigated = true;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MarkAttendancePage(
          employeeId: _employeeId!,
          employeeCode: _employeeCode!,
        ),
      ),
    ).then((_) {
      // ✅ Reset flag when returning from MarkAttendancePage
      if (mounted) {
        setState(() => _hasNavigated = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: _loading
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text(
              "Loading employee data...",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        )
            : _employeeId == null || _employeeCode == null
            ? Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[300],
              ),
              const SizedBox(height: 20),
              const Text(
                "Employee data not found",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                "Please contact admin to set up your employee profile.",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text("Retry"),
                onPressed: () {
                  setState(() => _loading = true);
                  _fetchEmployeeData();
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        )
            : Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ✅ Animated QR Scanner Icon
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.withOpacity(0.1),
                      Colors.blue.withOpacity(0.3),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(
                  Icons.qr_code_scanner,
                  size: 100,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                "Mark Attendance",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Click below to capture your face and mark attendance",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              // ✅ Button to manually trigger navigation
              ElevatedButton(
                onPressed: _navigateToMarkAttendance,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 4,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.camera_alt, color: Colors.white),
                    SizedBox(width: 12),
                    Text(
                      "Open Camera",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}