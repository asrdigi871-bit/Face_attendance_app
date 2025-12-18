import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '/Ui Screens/super_admin/providers/settings_data.dart';
import '/Ui Screens/super_admin/screens/settings/admin_profile_page.dart';
import '/Ui Screens/login_page.dart';
class SettingsContent extends StatelessWidget {
  const SettingsContent({super.key});

  @override
  Widget build(BuildContext context) {
    final adminProfile = context.watch<AdminProfileData>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'General Settings',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          // Placeholder options
          _SettingsOptionTile(
            title: 'Company Information',
            icon: Icons.business,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Company Info clicked')),
              );
            },
          ),
          _SettingsOptionTile(
            title: 'Holidays',
            icon: Icons.calendar_today,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Holidays clicked')),
              );
            },
          ),
          _SettingsOptionTile(
            title: 'Notifications',
            icon: Icons.notifications,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications clicked')),
              );
            },
          ),

          const SizedBox(height: 20),
          const Text(
            'Account',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          // Admin Profile (real-time super admin details)
          _SettingsOptionTile(
            title: adminProfile.name.isNotEmpty
                ? 'Admin Profile (${adminProfile.name})'
                : 'Admin Profile',
            icon: Icons.account_circle,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (BuildContext context) => const AdminProfilePage(),
                ),
              );
            },
          ),

          // Logout Button
          _SettingsOptionTile(
            title: 'Logout',
            icon: Icons.logout,
            iconColor: Colors.red,
            textColor: Colors.red,
            onTap: () => _logout(context),
          ),

        ],
      ),
    );
  }
}

Future<void> _logout(BuildContext context) async {
  // Show modern login-style dialog
  final shouldLogout = await showDialog<bool>(
    context: context,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.logout, size: 50, color: Colors.redAccent),
            const SizedBox(height: 16),
            const Text(
              'Logout',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Are you sure you want to log out from your account?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel', style: TextStyle(fontSize: 16)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Logout', style: TextStyle(fontSize: 16)),
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
          MaterialPageRoute(builder: (_) => const LoginScreen()),
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


// Helper widget
class _SettingsOptionTile extends StatelessWidget {
  const _SettingsOptionTile({
    required this.title,
    required this.icon,
    required this.onTap,
    this.iconColor = Colors.blue,
    this.textColor = Colors.black87,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final Color iconColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(title, style: TextStyle(fontSize: 16, color: textColor)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
