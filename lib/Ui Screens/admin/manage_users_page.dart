// manage_users_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'add_employee.dart';
import 'edit_employee.dart';
import '/Ui Screens/login_page.dart';
import '/Ui Screens/employee/employee_dashboard.dart';
import '/Ui Screens/super_admin/screens/employee_attendance_summary_page.dart';


class ManageUsersPage extends StatefulWidget {
  const ManageUsersPage({super.key});

  @override
  State<ManageUsersPage> createState() => _ManageUsersPageState();
}

String userName = "User";
String userRole = "NA";
String userDepartment = "NA";
String? userProfileImage;

class _ManageUsersPageState extends State<ManageUsersPage> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> users = [];

  int totalUsers = 0;
  int admins = 0;
  int employees = 0;

  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _fetchUserHeaderData();

    _searchController.addListener(() {
      setState(() {}); // rebuild for suffix icon
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserHeaderData() async {
    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) return;

      final response = await supabase
          .from('users')
          .select('name, role, department, profile_image_url')
          .eq('email', currentUser.email!)
          .maybeSingle();

      if (response != null && response is Map<String, dynamic>) {
        setState(() {
          userName = response['name']?.toString() ?? "User";
          userRole = response['role']?.toString() ?? "NA";
          userDepartment = response['department']?.toString() ?? "NA";
          userProfileImage = response['profile_image_url']?.toString();
        });
      }
    } catch (e) {
    }
  }

  Future<void> _fetchUsers() async {
    try {
      final response = await supabase.from('users').select();
      final fetchedUsers = List<Map<String, dynamic>>.from(response);

      if (!mounted) return;

      final employeeUsers = fetchedUsers.where((u) {
        final role = (u['role'] ?? '')
            .toString()
            .toLowerCase()
            .replaceAll(" ", "")
            .replaceAll("_", "");
        return role == 'employee';
      }).toList();

      final adminUsers = fetchedUsers.where((u) {
        final role = (u['role'] ?? '')
            .toString()
            .toLowerCase()
            .replaceAll(" ", "")
            .replaceAll("_", "");
        return role == 'admin' || role == 'superadmin';
      }).toList();

      setState(() {
        _allUsers = employeeUsers;
        users = List.from(_allUsers);

        totalUsers = fetchedUsers.length;
        admins = adminUsers.length;
        employees = employeeUsers.length;
      });
    } catch (e) {
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        users = List.from(_allUsers);
      } else {
        users = _allUsers.where((u) {
          final name = (u['name'] ?? '').toString().toLowerCase();
          final email = (u['email'] ?? '').toString().toLowerCase();
          final q = query.toLowerCase();
          return name.contains(q) ||
              email.contains(q) ||
              (u['employee_id']?.toString().contains(q) ?? false);
        }).toList();
      }
    });
  }

  Future<void> _createNotification({
    required String type,
    required String title,
    required String message,
  }) async {
    try {
      await supabase.from('notifications').insert({
        'type': type,
        'title': title,
        'message': message,
      });
    } catch (e) {
    }
  }

  Future<void> _deleteUserConfirm(Map<String, dynamic> user) async {
    final id = user['id'];
    final name = user['name'] ?? 'this user';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Confirm deletion'),
            content:
            Text(
                'Are you sure you want to delete "$name"? This cannot be undone.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel')),
              ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Delete')),
            ],
          ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await supabase.from('users').delete().eq('id', id);

      await _createNotification(
        type: 'delete',
        title: 'User deleted',
        message: 'User "$name" was removed.',
      );

      await _fetchUsers();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('User deleted')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to delete user: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Confirm Logout'),
            content: const Text('Are you sure you want to log out?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Logout'),
              ),
            ],
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

  Future<void> _exportUsers() async {
    if (users.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No users to export')));
      return;
    }

    String csv = 'Name,Email,Role,Employee ID,Department ID\n';
    for (var u in users) {
      csv +=
      '"${u['name'] ?? ''}","${u['email'] ?? ''}","${u['role'] ??
          ''}","${u['employee_id'] ?? ''}","${u['department_id'] ?? ''}"\n';
    }

    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/users.csv');
      await file.writeAsString(csv);
      await Share.shareXFiles([XFile(file.path)], text: 'User List Export');
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          "Manage Employees",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            tooltip: "Export Users",
            icon: const Icon(Icons.download, color: Colors.white),
            onPressed: _exportUsers,
          ),
          IconButton(
            tooltip: "Logout",
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddEmployeePage(onEmployeeAdded: _fetchUsers),
            ),
          );
        },
        label: const Text("Add Employee"),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.blue,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2196F3), Color(0xFF64B5F6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _fetchUsers,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER CARD
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          backgroundImage: (userProfileImage != null &&
                              userProfileImage!.isNotEmpty)
                              ? NetworkImage(userProfileImage!)
                              : null,
                          child: (userProfileImage == null ||
                              userProfileImage!.isEmpty)
                              ? const Icon(Icons.person,
                              color: Colors.white, size: 32)
                              : null,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(userName,
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                              Text(userRole,
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 14)),
                              Text(userDepartment,
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // SUMMARY CARDS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: _summaryBox(
                            totalUsers.toString(), "Total", Colors.white,
                            Colors.blue),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _summaryBox(
                            admins.toString(), "Admins", Colors.white,
                            Colors.orange),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _summaryBox(
                            employees.toString(), "Employees", Colors.white,
                            Colors.green),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),

                  // SEARCH BAR
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: "Search employees...",
                        prefixIcon: const Icon(Icons.search, color: Colors
                            .blue),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 15),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // EMPLOYEE LIST
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: users.isEmpty
                        ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          "No users found.\nAdd employees to get started.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white70, fontSize: 16),
                        ),
                      ),
                    )
                        : Column(
                      children: users.map((user) {
                        final name = user['name'] ?? "Unknown";
                        final email = user['email'] ?? "";
                        final dept = user['department'] ?? 'N/A';
                        final empId = user['emp_id'] != null ? user['emp_id'].toString() : 'N/A';

                        return Card(
                          elevation: 5,
                          margin:
                          const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      EmployeeAttendanceSummaryPage(
                                        employeeId: (user['emp_id'] ?? '')
                                            .toString(),
                                        employeeName: name,
                                        employeeEmail: email,
                                        employeeRole:
                                        (user['role'] ?? '').toString(),
                                        employeeDepartment: dept,
                                        profileImageUrl:
                                        (user['profile_image_url'] ?? '')
                                            .toString(),
                                      ),
                                ),
                              );
                            },
                            leading: CircleAvatar(
                              radius: 26,
                              backgroundColor: Colors.blue.shade100,
                              backgroundImage: (user['profile_image_url'] !=
                                  null &&
                                  (user['profile_image_url'] as String)
                                      .isNotEmpty)
                                  ? NetworkImage(user['profile_image_url'])
                                  : null,
                              child: (user['profile_image_url'] == null ||
                                  (user['profile_image_url'] as String).isEmpty)
                                  ? Text(
                                name.isNotEmpty
                                    ? name[0].toUpperCase()
                                    : "?",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              )
                                  : null,
                            ),
                            title: Text(name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                            subtitle: Text(
                              "$email\nEmp ID: $empId | Dept: $dept",
                              style: const TextStyle(fontSize: 13),
                            ),
                            isThreeLine: true,
                            trailing: Wrap(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blueAccent),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => EditEmployeePage(
                                          empId: (user['id'] ?? '').toString(),
                                          name: name,
                                          department: dept,
                                          idNumber: empId,
                                          email: email,
                                          phone: (user['phone'] ?? '').toString(),
                                          imagePath: user['profile_image_url']?.toString(),
                                        ),
                                      ),
                                    ).then((updated) {
                                      if (updated == true) _fetchUsers(); // ✅ refresh after editing
                                    });
                                  },
                                ),

                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.redAccent),
                                  onPressed: () => _deleteUserConfirm(user),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Helper widget for summary cards
Widget _summaryBox(
    String value, String label, Color bgColor, Color textColor) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 6,
          offset: const Offset(0, 3),
        ),
      ],
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
