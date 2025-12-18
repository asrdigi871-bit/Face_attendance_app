import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';

class EmployeeAttendanceSummaryPage extends StatefulWidget {
  final String employeeId;
  final String employeeName;
  final String? employeeEmail;
  final String? employeeRole;
  final String? employeeDepartment;
  final String? profileImageUrl;

  const EmployeeAttendanceSummaryPage({
    Key? key,
    required this.employeeId,
    required this.employeeName,
    this.employeeEmail,
    this.employeeRole,
    this.employeeDepartment,
    this.profileImageUrl,
  }) : super(key: key);

  @override
  _EmployeeAttendanceSummaryPageState createState() =>
      _EmployeeAttendanceSummaryPageState();
}

class _EmployeeAttendanceSummaryPageState
    extends State<EmployeeAttendanceSummaryPage> {
  final SupabaseService supabaseService = SupabaseService();
  final SupabaseClient supabase = Supabase.instance.client;

  List<Map<String, dynamic>> attendanceList = [];
  bool loading = true;
  String selectedFilter = 'Last 30 Days';
  int daysToShow = 30;

  RealtimeChannel? attendanceChannel;

  @override
  void initState() {
    super.initState();
    fetchAttendance();
    setupRealtimeListener();
  }

  @override
  void dispose() {
    attendanceChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> fetchAttendance() async {
    setState(() => loading = true);
    try {
      final data = await supabaseService.getAttendanceLogs(int.parse(widget.employeeId));
      setState(() => attendanceList = data);
    } catch (e) {
    } finally {
      setState(() => loading = false);
    }
  }

  void setupRealtimeListener() {
    attendanceChannel = supabase
        .channel('attendance_changes_${widget.employeeId}')
        .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'attendance_logs',
      callback: (payload) {
        if (payload.newRecord?['employee_id'] == widget.employeeId ||
            payload.oldRecord?['employee_id'] == widget.employeeId) {
          fetchAttendance();
        }
      },
    )
        .subscribe();
  }

  // UPDATED: Calculate stats with proper absent counting
  Map<String, int> calculateStats() {
    if (attendanceList.isEmpty) {
      return {'present': 0, 'late': 0, 'absent': daysToShow};
    }

    final now = DateTime.now();
    final cutoffDate = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: daysToShow - 1));

    // Get all dates in the range
    Set<String> allDates = {};
    for (int i = 0; i < daysToShow; i++) {
      final date = DateTime.now().subtract(Duration(days: i));
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      allDates.add(dateKey);
    }

    // Track which dates have attendance records
    Set<String> datesWithRecords = {};
    int present = 0, late = 0;
    const int targetHour = 9;

    for (var att in attendanceList) {
      try {
        final dateStr = att['date']?.toString();
        if (dateStr == null || dateStr.isEmpty) continue;

        final date = DateTime.parse(dateStr).toLocal();
        if (date.isBefore(cutoffDate)) continue;

        final dateKey = DateFormat('yyyy-MM-dd').format(date);
        final rawCheckIn = att['check_in']?.toString();

        // Only count if there's a valid check-in
        if (rawCheckIn != null && rawCheckIn.isNotEmpty && rawCheckIn != 'null') {
          datesWithRecords.add(dateKey);

          try {
            final checkIn = DateTime.parse(rawCheckIn).toLocal();
            final target = DateTime(checkIn.year, checkIn.month, checkIn.day, targetHour);

            if (checkIn.isAfter(target)) {
              late++;
            } else {
              present++;
            }
          } catch (_) {
            // If check-in parsing fails, don't count it
          }
        }
      } catch (_) {
        continue;
      }
    }

    // Calculate absent as dates without any check-in records
    final absent = allDates.length - datesWithRecords.length;

    return {'present': present, 'late': late, 'absent': absent};
  }

  // UPDATED: Calculate daily data with proper absent marking
  List<Map<String, dynamic>> calculateDailyData() {
    final now = DateTime.now();
    final cutoffDate = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: daysToShow - 1));

    // Create a map to store attendance by date
    Map<String, String> attendanceByDate = {};

    for (var att in attendanceList) {
      try {
        final dateStr = att['date']?.toString();
        if (dateStr == null) continue;

        final date = DateTime.parse(dateStr).toLocal();
        if (date.isBefore(cutoffDate)) continue;

        final dateKey = DateFormat('yyyy-MM-dd').format(date);
        final rawCheckIn = att['check_in']?.toString();

        String status = 'absent';

        // Only mark as present or late if there's actually a check-in
        if (rawCheckIn != null && rawCheckIn.isNotEmpty && rawCheckIn != 'null') {
          try {
            final checkIn = DateTime.parse(rawCheckIn).toLocal();
            final target = DateTime(checkIn.year, checkIn.month, checkIn.day, 9);

            // If checked in after 9 AM, mark as late, otherwise present
            if (checkIn.isAfter(target)) {
              status = 'late';
            } else {
              status = 'present';
            }
          } catch (_) {
            status = 'absent'; // If check-in parsing fails, mark as absent
          }
        } else {
          // No check-in time means absent
          status = 'absent';
        }

        attendanceByDate[dateKey] = status;
      } catch (_) {
        continue;
      }
    }

    // Create daily data for the selected period
    List<Map<String, dynamic>> dailyData = [];
    for (int i = daysToShow - 1; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final dateKey = DateFormat('yyyy-MM-dd').format(date);

      // If no record exists for this date, mark as absent
      final status = attendanceByDate[dateKey] ?? 'absent';

      dailyData.add({
        'date': date,
        'status': status,
        'label': daysToShow <= 7
            ? DateFormat('E').format(date)
            : daysToShow <= 30
            ? DateFormat('d').format(date)
            : 'Week ${((daysToShow - i) / 7).ceil()}',
      });
    }

    return dailyData;
  }

  void changeFilter(String filter) {
    setState(() {
      selectedFilter = filter;
      daysToShow = (filter == 'Last 7 Days')
          ? 7
          : (filter == 'Last 30 Days')
          ? 30
          : 365;
    });
  }

  @override
  Widget build(BuildContext context) {
    final stats = calculateStats();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "${widget.employeeName}'s Attendance",
          style: const TextStyle(
              color: Colors.black, fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: fetchAttendance,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileHeader(),
              const SizedBox(height: 16),
              _buildFilterButtons(),
              const SizedBox(height: 20),
              _buildSummaryHeader(),
              const SizedBox(height: 12),
              _buildStatsRow(stats),
              const SizedBox(height: 24),
              _buildAttendanceChart(),
              const SizedBox(height: 24),
              _buildDetailedRecords(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final hasProfileImage = widget.profileImageUrl != null &&
        widget.profileImageUrl!.isNotEmpty &&
        widget.profileImageUrl != 'NULL';

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: Colors.blue[100],
            child: hasProfileImage
                ? ClipOval(
              child: Image.network(
                widget.profileImageUrl!,
                width: 70,
                height: 70,
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
                      color: Colors.blue,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Text(
                    widget.employeeName[0].toUpperCase(),
                    style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      color: Color(0xFF2563EB),
                    ),
                  );
                },
              ),
            )
                : Text(
              widget.employeeName[0].toUpperCase(),
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.employeeName,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  '${widget.employeeRole ?? 'employee'} - ${widget.employeeDepartment ?? 'Department'}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                if (widget.employeeEmail != null)
                  Text(widget.employeeEmail!,
                      style:
                      TextStyle(fontSize: 13, color: Colors.grey[500])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButtons() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(
      children: [
        Expanded(child: _buildFilterButton('Last 7 Days')),
        const SizedBox(width: 8),
        Expanded(child: _buildFilterButton('Last 30 Days')),
        const SizedBox(width: 8),
        Expanded(child: _buildFilterButton('Last Year')),
      ],
    ),
  );

  Widget _buildSummaryHeader() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(
      children: [
        const Expanded(
          child: Text(
            'Attendance Summary',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF2563EB)], // light → deep blue
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _exportAttendance, // directly call export function
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.download, size: 16, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'Export',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  /// ✅ Simplified single-tap export and share function
  Future<void> _exportAttendance() async {
    try {
      // Example data (replace with real attendance list)
      List<List<String>> rows = [
        ['Name', 'Email', 'Role', 'Status'],
        ['Ajay Kumar', 'ajay@example.com', 'Employee', 'Present'],
        ['Rahul Singh', 'rahul@example.com', 'Manager', 'Absent'],
      ];

      // Convert to CSV
      String csv = const ListToCsvConverter().convert(rows);

      // Save to a temporary file
      final directory = await getTemporaryDirectory();
      final path =
          '${directory.path}/attendance_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File(path);
      await file.writeAsString(csv);

      // Open share sheet
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Real-time Attendance Report',
      );

      // Confirmation snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Attendance report exported successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error exporting report: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildStatsRow(Map<String, int> stats) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(
      children: [
        Expanded(
            child: _buildStatCard('Present', stats['present'].toString(),
                Colors.green[100]!, Colors.green)),
        const SizedBox(width: 12),
        Expanded(
            child: _buildStatCard(
                'Late',
                stats['late'].toString(),
                Colors.orange[100]!,
                Colors.orange)),
        const SizedBox(width: 12),
        Expanded(
            child: _buildStatCard(
                'Absent',
                stats['absent'].toString(),
                Colors.red[100]!,
                Colors.red)),
      ],
    ),
  );

  Widget _buildAttendanceChart() {
    final dailyData = calculateDailyData();

    if (dailyData.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Daily Attendance Trend',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              height: 250,
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: const Center(
                  child: Text('No attendance data available',
                      style: TextStyle(color: Colors.grey))),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: const Text('Daily Attendance Trend',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 16),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          height: daysToShow <= 7 ? 300 : 350,
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: daysToShow <= 7
              ? _buildDetailedBarChart(dailyData)
              : _buildDetailedScrollableChart(dailyData),
        ),
      ],
    );
  }

  Widget _buildDetailedBarChart(List<Map<String, dynamic>> dailyData) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 1,
          minY: 0,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                if (groupIndex >= 0 && groupIndex < dailyData.length) {
                  final data = dailyData[groupIndex];
                  final date = data['date'] as DateTime;
                  final dateStr = DateFormat('EEEE, MMM dd').format(date);
                  final status = data['status'].toString().toUpperCase();

                  return BarTooltipItem(
                    dateStr,
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    children: [
                      TextSpan(
                        text: '\n$status',
                        style: TextStyle(
                          color: _getStatusColor(status),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  );
                }
                return null;
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < dailyData.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        dailyData[value.toInt()]['label'],
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: dailyData.asMap().entries.map((entry) {
            final index = entry.key;
            final data = entry.value;
            final status = data['status'];

            Color barColor = _getBarColor(status);

            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: 1,
                  color: barColor,
                  width: 35,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDetailedScrollableChart(List<Map<String, dynamic>> dailyData) {
    List<Map<String, dynamic>> weeklyData = [];

    for (int i = 0; i < dailyData.length; i += 7) {
      int end = (i + 7 < dailyData.length) ? i + 7 : dailyData.length;
      final weekData = dailyData.sublist(i, end);

      int present = 0, late = 0, absent = 0;
      DateTime firstDate = weekData.first['date'];
      DateTime lastDate = weekData.last['date'];

      for (var day in weekData) {
        final status = day['status'];
        if (status == 'present') present++;
        else if (status == 'late') late++;
        else absent++;
      }

      weeklyData.add({
        'startDate': firstDate,
        'endDate': lastDate,
        'present': present,
        'late': late,
        'absent': absent,
        'total': weekData.length,
      });
    }

    return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
                width: (weeklyData.length * 80.0).clamp(0, double.infinity),
                height: 280,
                child: BarChart(
                    BarChartData(
                        alignment: BarChartAlignment.spaceEvenly,
                        maxY: weeklyData.isNotEmpty
                            ? weeklyData.map((w) => (w['total'] as int).toDouble()).reduce((a, b) => a > b ? a : b)
                            : 7,
                        minY: 0,
                        barTouchData: BarTouchData(
                            enabled: true,
                            touchTooltipData: BarTouchTooltipData(
                                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                  if (groupIndex >= 0 && groupIndex < weeklyData.length) {
                                    final week = weeklyData[groupIndex];
                                    final startDate = DateFormat('MMM dd').format(week['startDate']);
                                    final endDate = DateFormat('MMM dd').format(week['endDate']);
                                    final present = week['present'];
                                    final late = week['late'];
                                    final absent = week['absent'];
                                    final total = week['total'];

                                    return BarTooltipItem(
                                      'Week ${groupIndex + 1}\n$startDate - $endDate',
                                      const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                      children: [
                                    TextSpan(
                                    text: '\n\nPresent: $present',
                                      style: const TextStyle(
                                        color: Colors.greenAccent,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 11,
                                      ),
                                    ),
                                        TextSpan(
                                          text: '\nLate: $late',
                                          style: const TextStyle(
                                            color: Colors.amber,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 11,
                                          ),
                                        ),
                                        TextSpan(
                                          text: '\nAbsent: $absent',
                                          style: const TextStyle(
                                            color: Colors.redAccent,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 11,
                                          ),
                                        ),
                                        TextSpan(
                                          text: '\nTotal Days: $total',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    );
                                  }
                                  return null;
                                },
                            ),
                        ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index >= 0 && index < weeklyData.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    'Week ${index + 1}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 35,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        horizontalInterval: 1,
                        drawHorizontalLine: true,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey.withOpacity(0.1),
                            strokeWidth: 0.8,
                          );
                        },
                        drawVerticalLine: false,
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: weeklyData.asMap().entries.map((entry) {
                        final index = entry.key;
                        final week = entry.value;
                        final present = (week['present'] as int).toDouble();
                        final late = (week['late'] as int).toDouble();
                        final absent = (week['absent'] as int).toDouble();

                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: present + late + absent,
                              color: Colors.green,
                              width: 40,
                              rodStackItems: [
                                BarChartRodStackItem(0, present, Colors.green),
                                BarChartRodStackItem(present, present + late, Colors.orange),
                                BarChartRodStackItem(present + late, present + late + absent, Colors.red),
                              ],
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                ),
            ),
        ),
    );
  }

  Color _getBarColor(String status) {
    if (status == 'present') {
      return Colors.green;
    } else if (status == 'late') {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  Color _getStatusColor(String status) {
    if (status == 'PRESENT') {
      return Colors.greenAccent;
    } else if (status == 'LATE') {
      return Colors.amber;
    } else {
      return Colors.redAccent;
    }
  }

  Widget _buildDetailedRecords() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Detailed Records',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        attendanceList.isEmpty
            ? Container(
          padding: const EdgeInsets.all(32),
          child: const Center(
              child: Text('No attendance records found',
                  style: TextStyle(
                      color: Colors.grey, fontSize: 16))),
        )
            : ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: attendanceList.length,
          itemBuilder: (context, index) =>
              _buildAttendanceRecord(attendanceList[index]),
        ),
      ],
    ),
  );

  Widget _buildStatCard(
      String title, String value, Color color, Color textColor) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration:
        BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: textColor)),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(fontSize: 14, color: textColor)),
          ],
        ),
      );

  Widget _buildFilterButton(String filter) {
    final isSelected = selectedFilter == filter;
    return ElevatedButton(
      onPressed: () => changeFilter(filter),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.purple : Colors.grey[200],
        foregroundColor: isSelected ? Colors.white : Colors.black,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(filter,
          style: TextStyle(
              fontSize: 13,
              fontWeight:
              isSelected ? FontWeight.w600 : FontWeight.normal)),
    );
  }

  Widget _buildAttendanceRecord(Map<String, dynamic> att) {
    final rawDate = att['date']?.toString() ?? '';
    final rawCheckIn = att['check_in']?.toString() ?? '';
    final rawCheckOut = att['check_out']?.toString() ?? '';

    String formattedDate = 'N/A';
    String checkInDisplay = '-';
    String checkOutDisplay = '-';
    String status = 'Absent';

    try {
      if (rawDate.isNotEmpty && rawDate != 'null') {
        final date = DateTime.parse(rawDate).toLocal();
        formattedDate = DateFormat('EEEE, MMM dd, yyyy').format(date);
      }

      if (rawCheckIn.isNotEmpty && rawCheckIn != 'null') {
        final checkIn = DateTime.parse(rawCheckIn).toLocal();
        checkInDisplay = DateFormat('HH:mm').format(checkIn);
        final target = DateTime(checkIn.year, checkIn.month, checkIn.day, 9);
        status = checkIn.isAfter(target) ? 'Late' : 'Present';
      }

      if (rawCheckOut.isNotEmpty && rawCheckOut != 'null') {
        final checkOut = DateTime.parse(rawCheckOut).toLocal();
        checkOutDisplay = DateFormat('HH:mm').format(checkOut);
      }
    } catch (e) {
    }

    Color statusColor;
    Color bgColor;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'present':
        statusColor = Colors.green;
        bgColor = Colors.green[50]!;
        icon = Icons.check_circle;
        break;
      case 'late':
        statusColor = Colors.orange;
        bgColor = Colors.orange[50]!;
        icon = Icons.access_time;
        break;
      default:
        statusColor = Colors.red;
        bgColor = Colors.red[50]!;
        icon = Icons.cancel;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: statusColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(formattedDate,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text('Check-in: $checkInDisplay',
                    style:
                    TextStyle(fontSize: 13, color: Colors.grey[700])),
                Text('Check-out: $checkOutDisplay',
                    style:
                    TextStyle(fontSize: 13, color: Colors.grey[700])),
              ],
            ),
          ),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(12)),
            child: Text(status,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}