import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '/Ui Screens/login_page.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '/Ui Screens/mark_attendance.dart';
import '/Ui Screens/admin/Admin dashboard.dart';
import 'dart:async';

class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Attendance App',
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: const EmployeeDashboard(),
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
            width: 20,  // Match your _attendancePage() size
            height: 20,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Colors.blueAccent, Colors.lightBlueAccent],
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
                  size: 30,
                  color: widget.isActive ? Colors.white : Colors.white,
                ),
                Positioned(
                  top: 8 + 80 * _scanAnimation.value,
                  child: Container(
                    width: 40,
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

class EmployeeDashboard extends StatefulWidget {
  const EmployeeDashboard({super.key});

  @override
  State<EmployeeDashboard> createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends State<EmployeeDashboard> with TickerProviderStateMixin {
  DateTime? checkInTime;
  DateTime? checkOutTime;

  bool isLoading = true;
  List<Map<String, dynamic>> attendanceHistory = [];
  final supabase = Supabase.instance.client;

  Map<String, dynamic> employeeData = {};

  int _selectedIndex = 0;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  StreamSubscription? _attendanceSubscription;

  // Real-time stats
  int presentCount = 0;
  int absentCount = 0;
  int lateCount = 0;
  double attendancePercentage = 0.0;

  Timer? _liveTimer;

  @override
  void initState() {
    super.initState();

    _verifyAdmin();
    _initializeDashboard();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Add this
    _liveTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {}); // Triggers rebuild to update elapsed time
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _attendanceSubscription?.cancel();
    _liveTimer?.cancel(); // Cancel timer
    super.dispose();
  }

  void _processAttendanceData(List<Map<String, dynamic>> data) {
    if (!mounted) return;

    attendanceHistory = data.map((r) {
      DateTime? checkIn = r['check_in'] != null
          ? DateTime.parse(r['check_in'])
          : null;
      DateTime? checkOut = r['check_out'] != null
          ? DateTime.parse(r['check_out'])
          : null;

      return {
        'check_in': checkIn,
        'check_out': checkOut,
        'status': r['status'] ?? "Late",
      };
    }).toList();

    attendanceHistory.sort((a, b) {
      if (a['check_in'] == null) return 1;
      if (b['check_in'] == null) return -1;
      return b['check_in'].compareTo(a['check_in']);
    });

    _calculateStats();
    _updateTodayAttendance();

    setState(() {});
  }

  void _calculateStats() {
    presentCount = attendanceHistory
        .where((r) => r['status'].toString().toLowerCase() == 'present')
        .length;

    absentCount = attendanceHistory
        .where((r) => r['status'].toString().toLowerCase() == 'absent')
        .length;

    // Calculate late count based on check-in time
    const lateThresholdHour = 9; // 9:15 AM is late
    const lateThresholdMinute = 15;

    lateCount = attendanceHistory.where((r) {
      if (r['status'].toString().toLowerCase() != 'present' ||
          r['check_in'] == null) return false;

      DateTime checkIn = r['check_in'];
      final threshold = DateTime(checkIn.year, checkIn.month, checkIn.day,
          lateThresholdHour, lateThresholdMinute);

      return checkIn.isAfter(threshold);
    }).length;

    int total = presentCount + absentCount;
    attendancePercentage = total > 0 ? (presentCount / total) * 100 : 0;
  }


  void _updateTodayAttendance() {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);

    try {
      final todayRecord = attendanceHistory.firstWhere(
            (r) {
          if (r['check_in'] == null) return false;
          DateTime checkInDate = DateTime(
            r['check_in'].year,
            r['check_in'].month,
            r['check_in'].day,
          );
          return checkInDate.isAtSameMomentAs(today);
        },
      );

      checkInTime = todayRecord['check_in'];
      checkOutTime = todayRecord['check_out'];

    } catch (e) {
      checkInTime = null;
      checkOutTime = null;
    }
  }

  Future<void> _verifyAdmin() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final response = await supabase
        .from('users')
        .select('role')
        .eq('id', user.id)
        .maybeSingle();

    final role = response?['role'];

    if (!mounted) return;

    if (role == 'admin') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainAdminScreen()),
      );
    }
  }

  Future<void> _initializeDashboard() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      setState(() {
        employeeData = {
          'id': '---',
          'name': 'John Doe',
          'email': 'john@example.com',
          'role': 'Software Developer',
        };
        attendanceHistory = [];
        isLoading = false;
      });
      return;
    }

    try {
      await _fetchEmployeeData(user.email!);

      if (employeeData['id'] != null) {
        await _fetchAttendanceHistory(employeeData['id'].toString());
        _setupRealtimeSubscription(); // ✅ moved after data fetch
      }
    } catch (e) {
      debugPrint('Dashboard initialization error: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _setupRealtimeSubscription() {
    final user = supabase.auth.currentUser;
    if (user == null || employeeData['id'] == null) return;

    // ✅ Cancel old subscription if already active
    _attendanceSubscription?.cancel();

    _attendanceSubscription = supabase
        .from('attendance_logs')
        .stream(primaryKey: ['id'])
        .eq('employee_id', employeeData['id'])
        .listen((List<Map<String, dynamic>> data) {
      if (!mounted) return;

      debugPrint('Realtime update received: ${data.length} records');
      _processAttendanceData(data); // ✅ updates chart + stats
      setState(() {}); // ✅ triggers UI rebuild
    });
  }


  Future<void> _fetchEmployeeData(String email) async {
    try {
      final response = await supabase
          .from('users')
          .select('id, name, role, email, employee_code')
          .eq('email', email)
          .maybeSingle();

      if (response != null) {
        setState(() {
          employeeData = Map<String, dynamic>.from(response);
        });
      } else {
        setState(() {
          employeeData = {
            'id': '---',
            'name': 'Unknown Employee',
            'role': 'Not Assigned',
            'email': email,
          };
        });
      }
    } catch (e) {
    }
  }

  Future<void> _fetchAttendanceHistory(String employeeId) async {
    try {
      final response = await supabase
          .from('attendance_logs')
          .select('id, check_in, check_out, status')
          .eq('employee_id', int.parse(employeeId))
          .order('check_in', ascending: false);

      if (response != null) {
        _processAttendanceData(response);
      }
    } catch (e) {
    }
  }

  Future<void> _markAttendance() async {
    if (isLoading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Loading employee data...")),
      );
      return;
    }

    if (employeeData['id'] == null || employeeData['employee_code'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Employee data not loaded properly.")),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MarkAttendancePage(
          employeeId: employeeData['id'].toString(),
          employeeCode: employeeData['employee_code'].toString(),
        ),
      ),
    );
  }

  Future<void> _logout() async {
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
              const Text(
                'Confirm Logout',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Are you sure you want to log out?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
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
      await supabase.auth.signOut();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }


  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildPage() {
    if (_selectedIndex == 0) return _dashboardPage();
    if (_selectedIndex == 1) return _attendancePage();
    if (_selectedIndex == 2) return _historyPage();
    return _dashboardPage();
  }


  Widget _dashboardPage() {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
      onRefresh: () async {
        if (employeeData['id'] != null) {
          await _fetchAttendanceHistory(employeeData['id'].toString());
        }
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _modernAttendanceCard(),
            const SizedBox(height: 16),
            _statsRow(),
            const SizedBox(height: 20),
            _modernAttendanceGraph(),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Recent Activity",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        "Live",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            ...attendanceHistory.take(10).map((record) {
              DateTime? checkIn = record['check_in'];
              DateTime? checkOut = record['check_out'];
              String date = checkIn != null
                  ? DateFormat('MMM dd, yyyy').format(checkIn)
                  : "--";
              String time = (checkIn != null && checkOut != null)
                  ? "${DateFormat('hh:mm a').format(checkIn)} - ${DateFormat('hh:mm a').format(checkOut)}"
                  : checkIn != null
                  ? "In: ${DateFormat('hh:mm a').format(checkIn)}"
                  : "--";
              String status = record['status'];

              // removed hours parameter
              return _modernAttendanceTile(date, time, status, checkIn);
            }).toList(),
          ],
        ),
      ),
    );
  }


  Widget _modernAttendanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.blueAccent,Colors.lightBlueAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Today's Status",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  DateFormat('MMM dd').format(DateTime.now()),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _timeCard(
                  "Check-In",
                  checkInTime != null
                      ? DateFormat('hh:mm a').format(checkInTime!)
                      : "--:--",
                  Icons.login,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _timeCard(
                  "Check-Out",
                  checkOutTime != null
                      ? DateFormat('hh:mm a').format(checkOutTime!)
                      : "--:--",
                  Icons.logout,
                ),
              ),
            ],
          ),
          if (checkInTime != null && checkOutTime == null) ...[
            const SizedBox(height: 16),
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.greenAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "Currently Active",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _timeCard(String label, String time, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white70, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            time,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsRow() {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            "Present",
            presentCount.toString(),
            Colors.green,
            Icons.check_circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            "Absent",
            absentCount.toString(),
            Colors.red,
            Icons.cancel,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            "Late",
            lateCount.toString(),
            Colors.orange,
            Icons.access_time_filled,
          ),
        ),
      ],
    );
  }


  Widget _statCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // NOTE: Keeping the graph function intact in case you need it,
  // but it's not being modified for spacing as per your last request.
  Widget _modernAttendanceGraph() {
    final total = presentCount + absentCount + lateCount;
    final safeLateCount = lateCount.toDouble() < 0 ? 0.0 : lateCount.toDouble();

    // Defensive check
    final safePresentCount = presentCount.toDouble() < 0 ? 0.0 : presentCount.toDouble();
    final safeAbsentCount = absentCount.toDouble() < 0 ? 0.0 : absentCount.toDouble();
    final safeLeaveCount = lateCount.toDouble() < 0 ? 0.0 : lateCount.toDouble();

    double maxY = [
      safePresentCount,
      safeAbsentCount,
      safeLateCount,
    ].reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Attendance Overview",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "${attendancePercentage.toStringAsFixed(1)}%",
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: double.infinity,
              height: 240,
              child: BarChart(
                BarChartData(
                  maxY: maxY,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (group) => Colors.black87,
                      tooltipPadding: const EdgeInsets.all(8),
                      tooltipMargin: 8,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        String label;
                        Color color;
                        switch (group.x) {
                          case 0:
                            label = 'Present';
                            color = Colors.green;
                            break;
                          case 1:
                            label = 'Absent';
                            color = Colors.red;
                            break;
                          case 2:
                            label = 'Late';
                            color = Colors.orange;
                            break;
                          default:
                            label = '';
                            color = Colors.grey;
                        }
                        return BarTooltipItem(
                          '$label\n${rod.toY.toInt()} days',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          const style = TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          );
                          Widget text;
                          switch (value.toInt()) {
                            case 0:
                              text = const Text('Present', style: style);
                              break;
                            case 1:
                              text = const Text('Absent', style: style);
                              break;
                            case 2:
                              text = const Text('Late', style: style);
                              break;
                            default:
                              text = const Text('', style: style);
                          }
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            space: 8,
                            child: text,
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade200,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(
                          toY: safePresentCount,
                          width: 40,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            topRight: Radius.circular(8),
                          ),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4CAF50), Color(0xFF8BC34A)],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(
                          toY: safeAbsentCount,
                          width: 40,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            topRight: Radius.circular(8),
                          ),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE57373), Color(0xFFEF5350)],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 2,
                      barRods: [
                        BarChartRodData(
                          toY: safeLeaveCount,
                          width: 40,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            topRight: Radius.circular(8),
                          ),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFB74D), Color(0xFFFF9800)],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 2,
                      barRods: [
                        BarChartRodData(
                          toY: safeLateCount,
                          width: 40,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            topRight: Radius.circular(8),
                          ),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFB74D), Color(0xFFFF9800)],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modernAttendanceTile(String date, String time, String status, DateTime? checkIn)
 {
    Color statusColor;
    IconData statusIcon;

    switch (status.toLowerCase()) {
      case 'present':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'absent':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.event_busy;
    }

    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    bool isToday = false;

    if (checkIn != null) {
      DateTime checkInDate = DateTime(checkIn.year, checkIn.month, checkIn.day);
      isToday = checkInDate.isAtSameMomentAs(today);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        // Keep the blue border to visually highlight "Today"
        border: isToday
            ? Border.all(color: Colors.blue.shade300, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(statusIcon, color: statusColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      date,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    // ❌ REMOVED: The logic for the "Today" badge and its space is gone.
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 6),
            ],
          ),
        ],
      ),
    );
  }

  Widget _attendancePage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 150,
            height: 150,
            child: _QRCodeScanIcon(isActive: true),
          ),
          const SizedBox(height: 30),
          const Text(
            "Mark Your Attendance",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Tap below to check in or check out",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: isLoading ? null : _markAttendance,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 8,
              shadowColor: const Color(0xFF667EEA).withOpacity(0.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.camera_alt, color: Colors.white),
                SizedBox(width: 12),
                Text(
                  "Mark Attendance",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _historyPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Attendance History",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Total Records: ${attendanceHistory.length}",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      "Live Updates",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _historyStatsCard(),
          const SizedBox(height: 24),
          const Text(
            "Records",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          attendanceHistory.isEmpty
              ? Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                "No attendance records found",
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ),
          )
              : ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: attendanceHistory.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final record = attendanceHistory[index];
              DateTime? checkIn = record['check_in'];
              DateTime? checkOut = record['check_out'];
              String date = checkIn != null
                  ? DateFormat('MMM dd, yyyy').format(checkIn)
                  : "--";
              String time = (checkIn != null && checkOut != null)
                  ? "${DateFormat('hh:mm a').format(checkIn)} - ${DateFormat('hh:mm a').format(checkOut)}"
                  : checkIn != null
                  ? "In: ${DateFormat('hh:mm a').format(checkIn)}"
                  : "--";
              String hours = (checkIn != null && checkOut != null)
                  ? "${checkOut.difference(checkIn).inHours}h ${(checkOut.difference(checkIn).inMinutes % 60)}m"
                  : "0h";
              String status = record['status'];
              return _modernAttendanceTile(date, time, status,checkIn);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _historyStatsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.check_circle, color: Colors.green, size: 28),
              ),
              const SizedBox(height: 8),
              Text(
                presentCount.toString(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              Text(
                "Present",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          Column(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.cancel, color: Colors.red, size: 28),
              ),
              const SizedBox(height: 8),
              Text(
                absentCount.toString(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              Text(
                "Absent",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          Column(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.event_busy, color: Colors.orange, size: 28),
              ),
              const SizedBox(height: 8),
              Text(
                lateCount.toString(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              Text(
                "Late",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.blueAccent,Colors.lightBlueAccent],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  employeeData['name'] ?? "Employee",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  "ID: ${employeeData['id'] ?? '---'}",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: _logout, // Calls the new dialog
              icon: const Icon(Icons.logout, color: Colors.red, size: 20),
              tooltip: "Logout",
            ),
          ),
        ],

      ),
      body: _buildPage(),
      bottomNavigationBar: Container(
        decoration: BoxShadow(
          color: Colors.grey.shade300,
          blurRadius: 10,
          offset: const Offset(0, -2),
        ).toBoxDecoration(),
        child:  BottomNavigationBar(
          backgroundColor: Colors.white,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: const Color(0xFF667EEA),
          unselectedItemColor: Colors.grey.shade400,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 12,
          ),
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              label: "Dashboard",
            ),
            BottomNavigationBarItem(
              icon: SizedBox(
                width: 80,
                height: 60,
                child: _QRCodeScanIcon(isActive: true), // always show QR icon
              ),
              label: "Mark",
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: "History",
            ),
          ],
        ),

      ),
    );
  }
}

extension BoxShadowExtension on BoxShadow {
  BoxDecoration toBoxDecoration() {
    return BoxDecoration(
      boxShadow: [this],
    );
  }
}