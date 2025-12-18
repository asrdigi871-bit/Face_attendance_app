import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/data_models.dart';
import '../providers/user_management_data.dart';
import '../providers/realtime_attendance_provider.dart';
import '../screens/add_employee.dart';
import '../screens/edit_employee.dart';
import '../screens/employee_attendance_summary_page.dart';

class ManageEmployeesContent extends StatefulWidget {
  const ManageEmployeesContent({super.key});

  @override
  State<ManageEmployeesContent> createState() => _ManageEmployeesContentState();
}

class _ManageEmployeesContentState extends State<ManageEmployeesContent> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    Future.microtask(() {
      final userData = Provider.of<UserManagementData>(context, listen: false);
      final attendanceProvider = Provider.of<RealtimeAttendanceProvider>(context, listen: false);

      userData.fetchEmployees();
      userData.startRealtimeSubscription();
      attendanceProvider.refreshAttendance();
    });
  }

  @override
  void dispose() {
    Provider.of<UserManagementData>(context, listen: false).stopRealtimeSubscription();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<UserManagementData, RealtimeAttendanceProvider>(
      builder: (context, userData, attendanceProvider, child) {
        final allUsers = userData.users;

        // Update user status from real-time attendance
        final usersWithStatus = allUsers.map((user) {
          final status = attendanceProvider.getUserStatus(user.id);
          return user.copyWith(status: status);
        }).toList();

        // Separate employees and admins based on role
        final employees = usersWithStatus.where((user) => user.role.toLowerCase() == 'employee').toList();
        final admins = usersWithStatus.where((user) => user.role.toLowerCase() == 'admin').toList();

        // Filter based on search query
        final filteredEmployees = employees.where((user) {
          return user.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              user.email.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();

        final filteredAdmins = admins.where((user) {
          return user.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              user.email.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();

        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            title: const Text(
              'Manage Employees',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _openAddEmployeePage(context, userData),
            backgroundColor:const Color(0xFF2563EB),
            elevation: 6,
            tooltip: 'Add Employee',
            child: const Icon(Icons.add, size: 28, color: Colors.white),
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              await userData.fetchEmployees();
              await attendanceProvider.refreshAttendance();
            },
            child: CustomScrollView(
              slivers: [
                // Statistics Cards
                SliverToBoxAdapter(
                  child: _buildStatisticsCards(
                      employees,
                      admins,
                      attendanceProvider,
                      showEmployeeStats: _tabController.index == 0
                  ),
                ),

                // Search Bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search users...',
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ),
                ),

                // Tab Bar
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: Color(0xFF2563EB),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.black,
                      labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
                      dividerColor: Colors.transparent,
                      padding: EdgeInsets.zero,
                      labelPadding: EdgeInsets.zero,
                      onTap: (index) {
                        setState(() {});
                      },
                      tabs: [
                        Tab(
                          child: SizedBox(
                            width: double.infinity,
                            child: Center(child: Text('Employees (${employees.length})')),
                          ),
                        ),
                        Tab(
                          child: SizedBox(
                            width: double.infinity,
                            child: Center(child: Text('Admins (${admins.length})')),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // User List
                _tabController.index == 0
                    ? _buildUserListSliver(filteredEmployees, 'employee', userData, attendanceProvider)
                    : _buildUserListSliver(filteredAdmins, 'admin', userData, attendanceProvider),

                // Bottom spacing for FAB
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatisticsCards(
      List<GenUiEmployee> employees,
      List<GenUiEmployee> admins,
      RealtimeAttendanceProvider attendanceProvider,
      {required bool showEmployeeStats}
      ) {
    if (showEmployeeStats) {
      // Calculate employee statistics - Present on time vs Present but late
      final presentOnTimeCount = employees
          .where((u) => u.status == AttendanceStatus.present && !attendanceProvider.isUserLate(u.id))
          .length;
      final presentLateCount = employees
          .where((u) => u.status == AttendanceStatus.present && attendanceProvider.isUserLate(u.id))
          .length;
      final absentCount = employees.where((u) => u.status == AttendanceStatus.absent).length;

      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Present',
                    value: presentOnTimeCount.toString(),
                    color: Colors.green[100]!,
                    textColor: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    title: 'Late',
                    value: presentLateCount.toString(),
                    color: Colors.orange[100]!,
                    textColor: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Absent',
                    value: absentCount.toString(),
                    color: Colors.red[100]!,
                    textColor: Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    title: 'Total Employees',
                    value: employees.length.toString(),
                    color: Colors.blue[100]!,
                    textColor: Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      // Calculate admin statistics
      final presentOnTimeCount = admins
          .where((u) => u.status == AttendanceStatus.present && !attendanceProvider.isUserLate(u.id))
          .length;
      final absentCount = admins.where((u) => u.status == AttendanceStatus.absent).length;

      return Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Present',
                value: presentOnTimeCount.toString(),
                color: Colors.green[100]!,
                textColor: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Total Admins',
                value: admins.length.toString(),
                color: Colors.blue[100]!,
                textColor: Colors.blue,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required Color color,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
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
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserListSliver(
      List<GenUiEmployee> users,
      String userType,
      UserManagementData userData,
      RealtimeAttendanceProvider attendanceProvider,
      ) {
    if (users.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Text(
            'No ${userType}s found.',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            final user = users[index];
            final isLate = attendanceProvider.isUserLate(user.id);

            // Determine status color and text
            Color statusColor;
            String statusText;

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

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
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
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EmployeeAttendanceSummaryPage(
                        employeeId: user.id,
                        employeeName: user.name,
                        employeeEmail: user.email,
                        employeeRole: user.role,
                        employeeDepartment: user.department,
                        profileImageUrl: user.profileImageUrl,
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _buildProfileAvatar(user, statusColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.email,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: statusColor.withOpacity(0.3)),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        onSelected: (value) async {
                          if (value == 'edit') {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditEmployeePage(
                                  empId: user.id,
                                  name: user.name,
                                  department: user.department ?? '',
                                  idNumber: user.idNumber,
                                  email: user.email,
                                  phone: user.phoneNumber,
                                ),
                              ),
                            );

                            if (result == true) {
                              await userData.fetchEmployees();
                              if (mounted) setState(() {});
                            }
                          } else if (value == 'delete') {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete User'),
                                content: Text('Are you sure you want to delete ${user.name}?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              await userData.removeUser(user.id);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('${user.name} deleted successfully')),
                                );
                              }
                            }
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, color: Colors.blue, size: 20),
                                SizedBox(width: 12),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red, size: 20),
                                SizedBox(width: 12),
                                Text('Delete'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          childCount: users.length,
        ),
      ),
    );
  }

  // Helper method to build profile avatar with image support
  Widget _buildProfileAvatar(GenUiEmployee user, Color statusColor) {
    final hasProfileImage = user.profileImageUrl != null &&
        user.profileImageUrl!.isNotEmpty &&
        user.profileImageUrl != 'NULL';

    if (hasProfileImage) {
      return CircleAvatar(
        radius: 25,
        backgroundColor: statusColor.withOpacity(0.2),
        child: ClipOval(
          child: Image.network(
            user.profileImageUrl!,
            width: 50,
            height: 50,
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
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
      );
    }

    // Default avatar with initial
    return CircleAvatar(
      backgroundColor: statusColor.withOpacity(0.2),
      radius: 25,
      child: Text(
        user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
        style: TextStyle(
          color: statusColor,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Navigate to Add Employee page (full screen)
  void _openAddEmployeePage(BuildContext context, UserManagementData userData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEmployeePage(
          onEmployeeAdded: () async {
            await userData.fetchEmployees();
            if (mounted) setState(() {});
          },
        ),
      ),
    );
  }
}