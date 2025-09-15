import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import 'package:fl_chart/fl_chart.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: "https://vqaggymejtrprzgjtlwd.supabase.co",
    anonKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZxYWdneW1lanRycHJ6Z2p0bHdkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY3OTQ1NTUsImV4cCI6MjA3MjM3MDU1NX0.kAhIDIMVbJyLnVBZ-_KyOtCnJZFvXk9LcGRVfpoRYsg",
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Admin Dashboard",
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      debugShowCheckedModeBanner: false,
      home: const AdminDashboard(),
    );
  }
}

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0; // open Users by default for testing

  final List<String> _menuTitles = [
    "Dashboard Overview",
    "User Management",
    "Attendance Logs",
    "Reports Export",
  ];

  final List<Widget> _pages = const [
    DashboardOverviewPage(),
    UserManagementPage(),
    AttendanceLogsPage(),
    ExportPage(), //  Correct widget name
  ];


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_menuTitles[_selectedIndex],
            style: const TextStyle(color: Colors.white),),
        backgroundColor: Colors.deepPurple,
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
            },
            labelType: NavigationRailLabelType.all,
            backgroundColor: Colors.deepPurple.shade50,
            selectedIconTheme: const IconThemeData(color: Colors.deepPurple),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text("Overview"),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.group_outlined),
                selectedIcon: Icon(Icons.group),
                label: Text("Users"),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.access_time_outlined),
                selectedIcon: Icon(Icons.access_time),
                label: Text("Attendance"),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.file_download_outlined),
                selectedIcon: Icon(Icons.file_download),
                label: Text("Reports"),
              ),
            ],
          ),
          Expanded(
            child: Container(
              color: Colors.grey.shade100,
              child: _pages[_selectedIndex],
            ),
          ),
        ],
      ),
    );
  }
}

class SummaryCard extends StatelessWidget {
  final String title;
  final int value;
  final Color color;
  final IconData icon;

  const SummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.2),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    value.toString(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class DashboardOverviewPage extends StatefulWidget {
  const DashboardOverviewPage({super.key});

  @override
  State<DashboardOverviewPage> createState() => _DashboardOverviewPageState();
}

class _DashboardOverviewPageState extends State<DashboardOverviewPage> {
  int totalEmployees = 0;
  int present = 0;
  int absent = 0;
  int late = 0;

  List<Map<String, dynamic>> weeklyData = []; // for bar chart

  @override
  void initState() {
    super.initState();
    _fetchSummary();
    _fetchWeeklyData();
  }

  Future<void> _fetchSummary() async {
    final supabase = Supabase.instance.client;
    final today = DateTime.now().toUtc();
    final startOfDay = DateTime.utc(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    try {
      final employees = await supabase.from('users').select();
      final logs = await supabase
          .from('attendance_logs')
          .select('id, check_in, check_out, users!fk_employee(id)')
          .gte('check_in', startOfDay.toIso8601String())
          .lt('check_in', endOfDay.toIso8601String());

      final presentIds = logs.map((log) => log['users']['id']).toSet();

      final int presentCount = presentIds.length;
      final int totalCount = employees.length;
      final int absentCount = totalCount - presentCount;

      // Late rule: check_in after 9:15 AM
      final int lateCount = logs.where((log) {
        final checkIn = DateTime.tryParse(log['check_in'] ?? "");
        return checkIn != null &&
            checkIn.isAfter(DateTime(today.year, today.month, today.day, 9, 15));
      }).length;

      if (!mounted) return;
      setState(() {
        totalEmployees = totalCount;
        present = presentCount;
        absent = absentCount;
        late = lateCount;
      });
    } catch (e) {
      debugPrint("Error fetching summary: $e");
    }
  }

  Future<void> _fetchWeeklyData() async {
    final supabase = Supabase.instance.client;
    final today = DateTime.now().toUtc();

    try {
      final employees = await supabase.from('users').select();
      final int totalCount = employees.length;

      List<Map<String, dynamic>> weekData = [];

      for (int i = 6; i >= 0; i--) {
        final date = today.subtract(Duration(days: i));
        final startOfDay = DateTime.utc(date.year, date.month, date.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));

        final logs = await supabase
            .from('attendance_logs')
            .select('id, check_in, users!fk_employee(id)')
            .gte('check_in', startOfDay.toIso8601String())
            .lt('check_in', endOfDay.toIso8601String());

        final presentCount = logs.length;
        final absentCount = totalCount - presentCount;

        weekData.add({
          "date": "${date.month}/${date.day}",
          "present": presentCount,
          "absent": absentCount,
        });
      }

      if (!mounted) return;
      setState(() {
        weeklyData = weekData;
      });
    } catch (e) {
      debugPrint("Error fetching weekly data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Dashboard Overview")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ Summary Cards
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCard("Total Employees", totalEmployees, Colors.blue),
                _buildCard("Present", present, Colors.green),
                _buildCard("Absent", absent, Colors.red),
                _buildCard("Late", late, Colors.orange),
              ],
            ),
            const SizedBox(height: 30),

            // ✅ Pie Chart
            const Text("Reports & Analysis",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            SizedBox(
              height: 250,
              child: PieChart(
                PieChartData(
                  centerSpaceRadius: 40,
                  sections: [
                    PieChartSectionData(
                      value: present.toDouble(),
                      color: Colors.green,
                      title: "Present\n$present",
                      radius: 60,
                      titleStyle: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    PieChartSectionData(
                      value: absent.toDouble(),
                      color: Colors.red,
                      title: "Absent\n$absent",
                      radius: 60,
                      titleStyle: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    PieChartSectionData(
                      value: late.toDouble(),
                      color: Colors.orange,
                      title: "Late\n$late",
                      radius: 60,
                      titleStyle: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),

            // ✅ Weekly Bar Chart
            const Text("Last 7 Days Attendance Trend",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            weeklyData.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  barGroups: weeklyData.asMap().entries.map((entry) {
                    final index = entry.key;
                    final day = entry.value;

                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: (day["present"] as int).toDouble(),
                          color: Colors.green,
                          width: 12,
                        ),
                        BarChartRodData(
                          toY: (day["absent"] as int).toDouble(),
                          color: Colors.red,
                          width: 12,
                        ),
                      ],
                    );
                  }).toList(),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < weeklyData.length) {
                            return Text(
                              weeklyData[value.toInt()]["date"],
                              style: const TextStyle(fontSize: 12),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(String title, int count, Color color) {
    return Expanded(
      child: Card(
        color: color.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(title,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 8),
              Text("$count",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      final response = await Supabase.instance.client
          .from('users')
          .select()
          .order('id');
      setState(() {
        _users = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      debugPrint("Error fetching users: $e");
    }
  }

  Future<void> _deleteUser(int id, String name) async {
    try {
      await Supabase.instance.client.from("users").delete().eq("id", id);
      await _fetchUsers();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("🗑 $name deleted successfully"),
          backgroundColor: Colors.red.shade400,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting user: $e")),
      );
    }
  }

  void _showAddUserDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    String role = "employee";

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add User"),
          content: StatefulBuilder(
            builder: (ctx, setLocalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: "Name"),
                  ),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: "Email"),
                  ),
                  DropdownButtonFormField<String>(
                    value: role,
                    items: const [
                      DropdownMenuItem(value: "admin", child: Text("Admin")),
                      DropdownMenuItem(value: "employee", child: Text("Employee")),
                    ],
                    onChanged: (value) => setLocalState(() => role = value!),
                    decoration: const InputDecoration(labelText: "Role"),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final email = emailController.text.trim();

                if (name.isEmpty || email.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("All fields are required")),
                  );
                  return;
                }

                try {
                  await Supabase.instance.client.from("users").insert({
                    "name": name,
                    "email": email,
                    "role": role,
                  });

                  if (!mounted) return;
                  Navigator.pop(context);
                  await _fetchUsers();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(" User added successfully"),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error: $e")),
                  );
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void _showEditUserDialog(Map<String, dynamic> user) {
    final nameController = TextEditingController(text: user['name']);
    final emailController = TextEditingController(text: user['email']);
    String role = user['role'];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit User"),
          content: StatefulBuilder(
            builder: (ctx, setLocalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: "Name"),
                  ),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: "Email"),
                  ),
                  DropdownButtonFormField<String>(
                    value: role,
                    items: const [
                      DropdownMenuItem(value: "admin", child: Text("Admin")),
                      DropdownMenuItem(value: "employee", child: Text("Employee")),
                    ],
                    onChanged: (value) => setLocalState(() => role = value!),
                    decoration: const InputDecoration(labelText: "Role"),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final userId = (user['id'] as num).toInt();
                  debugPrint(" Updating user id=$userId");

                  final updated = await Supabase.instance.client
                      .from("users")
                      .update({
                    "name": nameController.text.trim(),
                    "email": emailController.text.trim(),
                    "role": role,
                  })
                      .eq("id", userId)
                      .select(); //  fetch updated row back

                  debugPrint(" Update response: $updated");

                  if (updated.isEmpty) {
                    throw "No row updated (check policies or id)";
                  }

                  if (!mounted) return;
                  Navigator.pop(context); // close edit dialog
                  await _fetchUsers();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(" User updated successfully"),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(" Update failed: $e")),
                  );
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _users.isEmpty
          ? const Center(child: Text("No users found"))
          : ListView.builder(
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final user = _users[index];
          return ListTile(
            leading: const Icon(Icons.person),
            title: Text(user['name']),
            subtitle: Text(user['email']),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(user['role']),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _showEditUserDialog(user),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text("Confirm Delete"),
                        content: Text(
                            "Are you sure you want to delete ${user['name']}?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Cancel"),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              _deleteUser((user['id'] as num).toInt(), user['name']);
                            },
                            child: const Text("Delete"),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddUserDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AttendanceLogsPage extends StatefulWidget {
  const AttendanceLogsPage({super.key});

  @override
  State<AttendanceLogsPage> createState() => _AttendanceLogsPageState();
}

class _AttendanceLogsPageState extends State<AttendanceLogsPage> {
  List<Map<String, dynamic>> _logs = [];
  List<Map<String, dynamic>> _filteredLogs = []; // filtered list
  DateTime? _selectedDate;
  String _sortOrder = "latest"; // default sort order
  String _searchQuery = ""; // search state

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  Future<void> _fetchLogs({DateTime? filterDate}) async {
    try {
      final supabase = Supabase.instance.client;
      dynamic response;

      final bool ascending = _sortOrder == "earliest";

      if (filterDate != null) {
        final startUtc = DateTime.utc(
          filterDate.year,
          filterDate.month,
          filterDate.day,
        );
        final endUtc = startUtc.add(const Duration(days: 1));

        response = await supabase
            .from('attendance_logs')
            .select('id, check_in, check_out, users!fk_employee(name, email)')
            .gte('check_in', startUtc.toIso8601String())
            .lt('check_in', endUtc.toIso8601String())
            .order('check_in', ascending: ascending);
      } else {
        response = await supabase
            .from('attendance_logs')
            .select('id, check_in, check_out, users!fk_employee(name, email)')
            .order('check_in', ascending: ascending);
      }

      print("Logs raw response: $response");

      if (!mounted) return;
      setState(() {
        _logs = List<Map<String, dynamic>>.from(response);
        _applySearch(); // apply filter immediately
      });
    } catch (e) {
      debugPrint("Error fetching logs: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching logs: $e")),
      );
    }
  }

  void _applySearch() {
    setState(() {
      if (_searchQuery.isEmpty) {
        _filteredLogs = _logs;
      } else {
        _filteredLogs = _logs.where((log) {
          final user = log['users'] ?? {};
          final name = (user['name'] ?? "").toString().toLowerCase();
          final email = (user['email'] ?? "").toString().toLowerCase();
          return name.contains(_searchQuery.toLowerCase()) ||
              email.contains(_searchQuery.toLowerCase());
        }).toList();
      }
    });
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
      _fetchLogs(filterDate: picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          decoration: const InputDecoration(
            hintText: "Search by name or email",
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey),
          ),
          style: const TextStyle(color: Colors.black),
          onChanged: (value) {
            _searchQuery = value;
            _applySearch();
          },
        ),
        actions: [
          DropdownButton<String>(
            value: _sortOrder,
            underline: const SizedBox(),
            icon: const Icon(Icons.sort, color: Colors.black),
            dropdownColor: Colors.white,
            items: const [
              DropdownMenuItem(value: "latest", child: Text("Latest First")),
              DropdownMenuItem(value: "earliest", child: Text("Earliest First")),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _sortOrder = value);
                _fetchLogs(filterDate: _selectedDate);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today, color: Colors.black),
            onPressed: _pickDate,
          ),
          if (_selectedDate != null)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.black),
              onPressed: () {
                setState(() => _selectedDate = null);
                _fetchLogs();
              },
            ),
        ],
      ),
      body: _filteredLogs.isEmpty
          ? const Center(child: Text("No attendance logs found"))
          : ListView.builder(
        itemCount: _filteredLogs.length,
        itemBuilder: (context, index) {
          final log = _filteredLogs[index];
          final user = log['users'] ?? {};
          return ListTile(
            leading: const Icon(Icons.access_time),
            title: Text(user['name'] ?? "Unknown"),
            subtitle: Text(
              "Check-in: ${log['check_in'] ?? '-'}\n"
                  "Check-out: ${log['check_out'] ?? '-'}",
            ),
          );
        },
      ),
    );
  }
}


class ExportPage extends StatefulWidget {
  const ExportPage({super.key});

  @override
  State<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends State<ExportPage> {
  bool _loading = false;

  Future<List<Map<String, dynamic>>> _fetchLogs() async {
    final response = await Supabase.instance.client
        .from('attendance_logs')
        .select('id, check_in, check_out, users!fk_employee(name, email)')
        .order('check_in', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<String> _getDownloadPath(String filename) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/$filename");
    return file.path;
  }

  Future<void> _exportCSV() async {
    setState(() => _loading = true);
    final logs = await _fetchLogs();

    List<List<dynamic>> rows = [
      ["ID", "Employee Name", "Email", "Check In", "Check Out"]
    ];

    for (final log in logs) {
      final user = log['users'] ?? {};
      rows.add([
        log['id'],
        user['name'] ?? "Unknown",
        user['email'] ?? "Unknown",
        log['check_in'] ?? "-",
        log['check_out'] ?? "-",
      ]);
    }

    String csvData = const ListToCsvConverter().convert(rows);
    final filePath = await _getDownloadPath("attendance_logs.csv");
    final file = File(filePath);
    await file.writeAsString(csvData);

    setState(() => _loading = false);

    await Share.shareXFiles([XFile(file.path)], text: "Attendance Logs CSV");
  }

  Future<void> _exportPDF() async {
    setState(() => _loading = true);
    final logs = await _fetchLogs();

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Table.fromTextArray(
            headers: ["ID", "Employee", "Email", "Check In", "Check Out"],
            data: logs.map((log) {
              final user = log['users'] ?? {};
              return [
                log['id'].toString(),
                user['name'] ?? "Unknown",
                user['email'] ?? "Unknown",
                log['check_in'] ?? "-",
                log['check_out'] ?? "-",
              ];
            }).toList(),
          );
        },
      ),
    );

    final filePath = await _getDownloadPath("attendance_logs.pdf");
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    setState(() => _loading = false);

    await Share.shareXFiles([XFile(file.path)], text: "Attendance Logs PDF");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Export Attendance Logs")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Download Attendance Data",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: _exportCSV,
              icon: const Icon(Icons.file_download),
              label: const Text("Export as CSV"),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _exportPDF,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text("Export as PDF"),
            ),
          ],
        ),
      ),
    );
  }
}
