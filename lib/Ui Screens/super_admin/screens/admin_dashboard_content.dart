import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../models/data_models.dart';
import '../providers/user_management_data.dart';
import '../providers/realtime_attendance_provider.dart';
import '/Ui Screens/super_admin/screens/manage_employees_content.dart'; // Manage Users page
import '/Ui Screens/super_admin/screens/settings/settings_content.dart'; // Settings page
import '/Ui Screens/super_admin/providers/settings_data.dart'; // Settings page
import '/Ui Screens/notifications_screen.dart';

class UpdatedAdminDashboardContent extends StatefulWidget {
  final Map<String, dynamic> userData;

  const UpdatedAdminDashboardContent({
    super.key,
    required this.userData,
  });

  @override
  State<UpdatedAdminDashboardContent> createState() =>
      _UpdatedAdminDashboardContentState();
}

class _UpdatedAdminDashboardContentState
    extends State<UpdatedAdminDashboardContent> {
  String _selectedFilter = 'Employees';
  String _dashboardSearchQuery = '';
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();

    // Existing post-frame callbacks
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserManagementData>().fetchEmployees();
      context.read<RealtimeAttendanceProvider>().refreshAttendance();
    });
  }

  void _onNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  /// Export CSV
  void _exportAttendance(List<GenUiEmployee> users) async {
    List<List<String>> rows = [
      ['Name', 'Email', 'Role', 'Status']
    ];

    for (var user in users) {
      rows.add([
        user.name,
        user.email,
        user.role,
        user.status.toString().split('.').last
      ]);
    }

    String csv = const ListToCsvConverter().convert(rows);

    final directory = await getTemporaryDirectory();
    final path =
        '${directory.path}/attendance_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File(path);
    await file.writeAsString(csv);

    Share.shareXFiles([XFile(file.path)], text: 'Real-time Attendance Data');
  }

  @override
  Widget build(BuildContext context) {
    // Pages for navigation
    final List<Widget> pages = [
      _buildDashboardContent(), // Dashboard Page
      ManageEmployeesContent(), // User Management
      SettingsContent(), // Settings
    ];

    return Scaffold(
      backgroundColor: Colors.white, // Light blue background for contrast
      appBar: AppBar(
        title: const Text(
          'Super Admin Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 0.5,
          ),
        ),
        foregroundColor: Colors.white, // Text & icon color
        centerTitle: true,
        elevation: 4, // Slight shadow for depth
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16), // Rounded bottom for modern look
          ),
        ),

        // 👇 Replace backgroundColor with a gradient using flexibleSpace
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF2563EB)], // Light to deep blue
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onNavTapped,
          selectedItemColor: const Color(0xFF2563EB),
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              backgroundColor: Colors.black,
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.group_outlined),
              backgroundColor: Colors.black,
              activeIcon: Icon(Icons.group),
              label: 'Users',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              backgroundColor: Colors.black,
              activeIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminProfileHeader(Map<String, dynamic> userData, BuildContext context) {
    final name = (userData['name'] != null && userData['name'].toString().trim().isNotEmpty)
        ? userData['name']
        : 'User';

    final role = (userData['role'] != null && userData['role'].toString().trim().isNotEmpty)
        ? userData['role']
        : 'Employee';

    final imageUrl = userData['profile_image_url'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF2563EB)], // light to deep blue
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Profile Avatar
          CircleAvatar(
            radius: 38,
            backgroundColor: Colors.white.withOpacity(0.2),
            backgroundImage: (imageUrl != null &&
                imageUrl != 'NULL' &&
                imageUrl.toString().trim().isNotEmpty)
                ? NetworkImage(imageUrl)
                : null,
            child: (imageUrl == null ||
                imageUrl == 'NULL' ||
                imageUrl.toString().trim().isEmpty)
                ? Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'U',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            )
                : null,
          ),
          const SizedBox(width: 18),

          // Name + Role
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),

                // Role (always one line)
                Text(
                  role.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                    letterSpacing: 0.6,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),

          // Notification Icon only
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, size: 28),
            color: Colors.white.withOpacity(0.95),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotificationsScreen(), // <-- Replace with your notification screen
                ),
              );
            },
          ),
        ],
      ),
    );
  }



  /// The main dashboard content
  Widget _buildDashboardContent() {
    return Consumer2<UserManagementData, RealtimeAttendanceProvider>(
      builder: (context, userManagementData, attendanceProvider, child) {
        List<GenUiEmployee> currentUsers;
        if (_selectedFilter == 'Employees') {
          currentUsers = userManagementData.users
              .where((user) => user.role.toLowerCase() == 'employee')
              .toList();
        } else {
          currentUsers = userManagementData.users
              .where((user) =>
          user.role.toLowerCase() == 'admin')
              .toList();
        }

        final userIds = currentUsers.map((user) => user.id).toList();
        final attendanceSummary =
        attendanceProvider.getAttendanceSummary(userIds);

        final filteredUsers = currentUsers
            .where((user) => user.name
            .toLowerCase()
            .contains(_dashboardSearchQuery.toLowerCase()))
            .toList();

        final usersWithStatus = filteredUsers.map((user) {
          final status = attendanceProvider.getUserStatus(user.id);
          return user.copyWith(status: status);
        }).toList();

        return RefreshIndicator(
          onRefresh: () async {
            await userManagementData.fetchEmployees();
            await attendanceProvider.refreshAttendance();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAdminProfileHeader(widget.userData, context),
                _buildFilterButtons(),
                const SizedBox(height: 20),
                _buildAttendanceSummaryHeader(usersWithStatus),
                const SizedBox(height: 10),
                _buildAttendanceCards(attendanceSummary),
                const SizedBox(height: 10),
                _buildProgressBar(attendanceSummary),
                const SizedBox(height: 20),
                _buildRealtimeGraphDynamic(attendanceProvider),
                const SizedBox(height: 20),
                _buildSearchBar(),
                const SizedBox(height: 15),
                _buildLiveAttendanceHeader(),
                const SizedBox(height: 10),
                _buildUserList(usersWithStatus, attendanceProvider),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

Widget _buildFilterButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _selectedFilter = 'Employees';
                _dashboardSearchQuery = '';
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _selectedFilter == 'Employees'
                  ? const Color(0xFF2563EB)
                  : Colors.grey[200],
              foregroundColor: _selectedFilter == 'Employees'
                  ? Colors.white
                  : Colors.black87,
              padding: const EdgeInsets.symmetric(vertical: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Employees',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _selectedFilter = 'Admins';
                _dashboardSearchQuery = '';
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _selectedFilter == 'Admins'
                  ? const Color(0xFF2563EB)
                  : Colors.grey[200],
              foregroundColor: _selectedFilter == 'Admins'
                  ? Colors.white
                  : Colors.black87,
              padding: const EdgeInsets.symmetric(vertical: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Admins',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceSummaryHeader(List<GenUiEmployee> usersWithStatus) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Today's Attendance",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        ElevatedButton.icon(
          onPressed: () => _exportAttendance(usersWithStatus),
          icon: const Icon(Icons.download, size: 14),
          label: const Text('Export', style: TextStyle(fontSize: 12)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceCards(Map<String, int> summary) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                summary['present'].toString(),
                'Present',
                Colors.green[100]!,
                Colors.green,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatCard(
                summary['late'].toString(),
                'Late',
                Colors.yellow[100]!,
                Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                summary['absent'].toString(),
                'Absent',
                Colors.red[100]!,
                Colors.red,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatCard(
                summary['total'].toString(),
                _selectedFilter == 'Employees'
                    ? 'Total Employees'
                    : 'Total Admins',
                Colors.blue[100]!,
                Colors.blue,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String value, String label, Color bgColor, Color textColor) {
    return Card(
      color: bgColor,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 14, color: textColor.withOpacity(0.7)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(Map<String, int> summary) {
    final total = summary['total'] ?? 0;
    final present = summary['present'] ?? 0;
    final notPresent = (summary['late'] ?? 0) + (summary['absent'] ?? 0);
    final progressValue = total == 0 ? 0.0 : present / total;
    final percentage = (progressValue * 100).toStringAsFixed(0);

    return Column(
      children: [
        LinearProgressIndicator(
          value: progressValue,
          minHeight: 8,
          backgroundColor: Colors.grey[300],
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
        const SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Not Present (Late/Absent): $notPresent',
              style: const TextStyle(color: Colors.orange, fontSize: 13),
            ),
            Text(
              '$percentage%',
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            ),
          ],
        ),
      ],
    );
  }

  /// Real-time Graph - UPDATED WITH FIX
  Widget _buildRealtimeGraphDynamic(RealtimeAttendanceProvider attendanceProvider) {
    return Consumer<UserManagementData>(
      builder: (context, userManagementData, child) {
        final currentUsers = _selectedFilter == 'Employees'
            ? userManagementData.users
            .where((u) => u.role.toLowerCase() == 'employee')
            .toList()
            : userManagementData.users
            .where((u) =>
        u.role.toLowerCase() == 'admin' ||
            u.role.toLowerCase() == 'super admin')
            .toList();

        final userIds = currentUsers.map((u) => u.id).toList();
        final summary = attendanceProvider.getAttendanceSummary(userIds);

        final total = summary['total'] ?? 0;
        final present = summary['present'] ?? 0;
        final late = summary['late'] ?? 0;
        final absent = summary['absent'] ?? 0;

        return Container(
          height: 250, // Increased from 220 to 250
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: total > 0 ? (total.toDouble() * 1.2) : 10,
              minY: 0,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    String label;
                    switch (groupIndex) {
                      case 0:
                        label = 'Present (On Time)';
                        break;
                      case 1:
                        label = 'Present (Late)';
                        break;
                      case 2:
                        label = 'Absent';
                        break;
                      default:
                        label = '';
                    }
                    return BarTooltipItem(
                      '$label\n${rod.toY.toInt()}',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    );
                  },
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: (total > 0 ? total.toDouble() / 4 : 2.5),
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey.withOpacity(0.2),
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  );
                },
              ),
              borderData: FlBorderData(
                show: true,
                border: Border(
                  left: BorderSide(color: Colors.grey.withOpacity(0.3), width: 1),
                  bottom: BorderSide(color: Colors.grey.withOpacity(0.3), width: 1),
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
                    reservedSize: 32,
                    interval: (total > 0 ? total.toDouble() / 4 : 2.5),
                    getTitlesWidget: (value, meta) {
                      if (value == meta.max || value == meta.min) {
                        return const SizedBox.shrink();
                      }
                      return Text(
                        value.toInt().toString(),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 45, // Increased from 32 to 45
                    getTitlesWidget: (value, meta) {
                      String text;
                      switch (value.toInt()) {
                        case 0:
                          text = 'Present\n(On Time)';
                          break;
                        case 1:
                          text = 'Present\n(Late)';
                          break;
                        case 2:
                          text = 'Absent';
                          break;
                        default:
                          return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          text,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 10, // Reduced from 11 to 10
                            fontWeight: FontWeight.w600,
                            height: 1.2, // Added line height for better spacing
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: [
                BarChartGroupData(
                  x: 0,
                  barRods: [
                    BarChartRodData(
                      toY: present.toDouble(),
                      color: Colors.green,
                      width: 40,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6),
                      ),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: total > 0 ? total.toDouble() : 10,
                        color: Colors.grey.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
                BarChartGroupData(
                  x: 1,
                  barRods: [
                    BarChartRodData(
                      toY: late.toDouble(),
                      color: Colors.orange,
                      width: 40,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6),
                      ),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: total > 0 ? total.toDouble() : 10,
                        color: Colors.grey.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
                BarChartGroupData(
                  x: 2,
                  barRods: [
                    BarChartRodData(
                      toY: absent.toDouble(),
                      color: Colors.red,
                      width: 40,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6),
                      ),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: total > 0 ? total.toDouble() : 10,
                        color: Colors.grey.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search live attendance...',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.grey[200],
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
      ),
      onChanged: (query) {
        setState(() {
          _dashboardSearchQuery = query;
        });
      },
    );
  }

  Widget _buildLiveAttendanceHeader() {
    return Text(
      'Live Attendance ($_selectedFilter)',
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildUserList(List<GenUiEmployee> users, RealtimeAttendanceProvider attendanceProvider) {
    if (users.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'No ${_selectedFilter.toLowerCase()} found',
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return _buildUserTile(user, attendanceProvider);
      },
    );
  }

  // UPDATED: User tile with profile image support
  Widget _buildUserTile(GenUiEmployee user, RealtimeAttendanceProvider attendanceProvider) {
    final isLate = attendanceProvider.isUserLate(user.id);

    Color statusColor;
    String statusText;

    // If present and late, show "Present • Late"
    if (user.status == AttendanceStatus.present && isLate) {
      statusColor = Colors.orange;
      statusText = 'Present • Late';
    } else if (user.status == AttendanceStatus.present) {
      statusColor = Colors.green;
      statusText = 'Present';
    } else if (user.status == AttendanceStatus.absent) {
      statusColor = Colors.red;
      statusText = 'Absent';
    } else {
      statusColor = Colors.grey;
      statusText = 'Unknown';
    }

    // Check if user has profile image
    final hasProfileImage = user.profileImageUrl != null &&
        user.profileImageUrl!.isNotEmpty &&
        user.profileImageUrl != 'NULL';

    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: statusColor.withOpacity(0.2),
          child: hasProfileImage
              ? ClipOval(
            child: Image.network(
              user.profileImageUrl!,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                        : null,
                    strokeWidth: 2,
                    color: statusColor,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                // Fallback to initial if image fails to load
                return Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                );
              },
            ),
          )
              : Text(
            user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        title: Text(
          user.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          user.email,
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: statusColor.withOpacity(0.3)),
          ),
          child: Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}