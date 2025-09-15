// import 'package:flutter/material.dart';
//
// class AdminDashboard extends StatefulWidget {
//   const AdminDashboard({super.key});
//
//   @override
//   State<AdminDashboard> createState() => _AdminDashboardState();
// }
//
// class _AdminDashboardState extends State<AdminDashboard> {
//   int _selectedIndex = 0;
//
//   final List<Widget> _pages = [
//     const DashboardOverviewPage(),
//     const UserManagementPage(),
//     const AttendanceLogsPage(),
//     const ReportsPage(),
//   ];
//
//   void _onItemTapped(int index) {
//     setState(() {
//       _selectedIndex = index;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Admin Dashboard"),
//         centerTitle: true,
//         backgroundColor: Colors.deepPurple,
//       ),
//       body: _pages[_selectedIndex],
//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: _selectedIndex,
//         onTap: _onItemTapped,
//         selectedItemColor: Colors.deepPurple,
//         unselectedItemColor: Colors.grey,
//         type: BottomNavigationBarType.fixed,
//         items: const [
//           BottomNavigationBarItem(
//             icon: Icon(Icons.dashboard),
//             label: "Overview",
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.group),
//             label: "Users",
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.access_time),
//             label: "Attendance",
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.file_download),
//             label: "Reports",
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// //
// // 📌 Page 1: Dashboard Overview
// //
// class DashboardOverviewPage extends StatelessWidget {
//   const DashboardOverviewPage({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: const [
//           Text("📊 Dashboard Overview",
//               style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
//           SizedBox(height: 20),
//           Text("Show KPIs here: Total Users, Present Today, Absent, etc."),
//         ],
//       ),
//     );
//   }
// }
//
// //
// // 📌 Page 2: User Management
// //
// class UserManagementPage extends StatelessWidget {
//   const UserManagementPage({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: ListView(
//         children: const [
//           ListTile(
//             leading: Icon(Icons.person),
//             title: Text("Employee 1"),
//             subtitle: Text("employee1@email.com"),
//             trailing: Icon(Icons.delete, color: Colors.red),
//           ),
//           ListTile(
//             leading: Icon(Icons.person),
//             title: Text("Employee 2"),
//             subtitle: Text("employee2@email.com"),
//             trailing: Icon(Icons.delete, color: Colors.red),
//           ),
//         ],
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           // TODO: Open form to add new user
//         },
//         child: const Icon(Icons.add),
//       ),
//     );
//   }
// }
//
// //
// // 📌 Page 3: Attendance Logs
// //
// class AttendanceLogsPage extends StatelessWidget {
//   const AttendanceLogsPage({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return ListView(
//       children: const [
//         ListTile(
//           leading: Icon(Icons.access_time),
//           title: Text("Employee 1"),
//           subtitle: Text("Checked in at 9:05 AM"),
//         ),
//         ListTile(
//           leading: Icon(Icons.access_time),
//           title: Text("Employee 2"),
//           subtitle: Text("Checked in at 9:15 AM"),
//         ),
//       ],
//     );
//   }
// }
//
// //
// // 📌 Page 4: Reports Export
// //
// class ReportsPage extends StatelessWidget {
//   const ReportsPage({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           const Text("📑 Export Reports",
//               style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
//           const SizedBox(height: 30),
//           ElevatedButton.icon(
//             onPressed: () {
//               // TODO: Export to CSV
//             },
//             icon: const Icon(Icons.table_chart),
//             label: const Text("Export CSV"),
//           ),
//           const SizedBox(height: 15),
//           ElevatedButton.icon(
//             onPressed: () {
//               // TODO: Export to PDF
//             },
//             icon: const Icon(Icons.picture_as_pdf),
//             label: const Text("Export PDF"),
//           ),
//         ],
//       ),
//     );
//   }
// }
