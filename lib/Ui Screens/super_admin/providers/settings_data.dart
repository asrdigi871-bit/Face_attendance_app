import 'package:flutter/material.dart';
import '../models/data_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- Data Model for Settings ---
class SettingsData extends ChangeNotifier {
  String _companyName;
  String _companyAddress;
  String _companyPhone;
  String _companyWebsite;

  SettingsData()
      : _companyName = 'My Company Inc.',
        _companyAddress = '123 Main St, Anytown',
        _companyPhone = '+1 (555) 123-4567',
        _companyWebsite = 'www.example.com';

  String get companyName => _companyName;
  String get companyAddress => _companyAddress;
  String get companyPhone => _companyPhone;
  String get companyWebsite => _companyWebsite;

  void updateCompanyName(String newName) {
    if (_companyName != newName) {
      _companyName = newName;
      notifyListeners();
    }
  }

  void updateCompanyAddress(String newAddress) {
    if (_companyAddress != newAddress) {
      _companyAddress = newAddress;
      notifyListeners();
    }
  }

  void updateCompanyPhone(String newPhone) {
    if (_companyPhone != newPhone) {
      _companyPhone = newPhone;
      notifyListeners();
    }
  }

  void updateCompanyWebsite(String newWebsite) {
    if (_companyWebsite != newWebsite) {
      _companyWebsite = newWebsite;
      notifyListeners();
    }
  }
}

class AdminProfileData with ChangeNotifier {
  String name = '';
  String role = '';
  String email = '';
  String department = '';
  String employeeId = '';
  String? profileImageUrl;

  void updateName(String newName) {
    name = newName;
    notifyListeners();
  }

  void updateEmail(String newEmail) {
    email = newEmail;
    notifyListeners();
  }

  void updateRole(String newRole) {
    role = newRole;
    notifyListeners();
  }

  void updateDepartment(String newDept) {
    department = newDept;
    notifyListeners();
  }

  void updateProfileImage(String newUrl) {
    profileImageUrl = newUrl;
    notifyListeners();
  }

  void updateEmployeeId(String newId) {
    employeeId = newId;
    notifyListeners();
  }

  /// ✅ Auto-load details for the logged-in Super Admin
  Future<void> loadSuperAdminDetails() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) return;

    final response = await supabase
        .from('employees')
        .select()
        .eq('email', user.email!)
        .maybeSingle();

    if (response != null) {
      name = response['name'] ?? 'Super Admin';
      role = response['role'] ?? 'Super Admin';
      employeeId = response['employee_id'] ?? 'ADMIN001';
      profileImageUrl = response['profile_image'] ?? null;
      email = response['email'] ?? '';
      department = response['department'] ?? '';
      notifyListeners();
    }
  }
}


// --- Data Model for Holidays ---
class HolidayData extends ChangeNotifier {
  final List<Holiday> _holidays = <Holiday>[
    Holiday(
      name: 'New Year\'s Day',
      date: DateTime(2024, 1, 1),
      description: 'First day of the year',
    ),
    Holiday(
      name: 'Independence Day',
      date: DateTime(2024, 7, 4),
      description: 'National holiday in the US',
    ),
    Holiday(
      name: 'Labor Day',
      date: DateTime(2024, 9, 2),
      description: 'Celebration of the American labor movement',
    ),
    Holiday(
      name: 'Christmas Day',
      date: DateTime(2024, 12, 25),
      description: 'Winter holiday',
    ),
  ];

  List<Holiday> get holidays => List<Holiday>.unmodifiable(_holidays);

  void addHoliday(Holiday newHoliday) {
    _holidays.add(newHoliday);
    // Sort by date after adding
    _holidays.sort((Holiday a, Holiday b) => a.date.compareTo(b.date));
    notifyListeners();
  }

  void removeHoliday(Holiday holidayToRemove) {
    _holidays.removeWhere(
          (Holiday holiday) =>
      holiday.name == holidayToRemove.name &&
          holiday.date == holidayToRemove.date,
    );
    notifyListeners();
  }
}

// --- Data Model for Notifications ---
class NotificationData extends ChangeNotifier {
  final List<NotificationItem> _notifications = <NotificationItem>[
    NotificationItem(
      title: 'New Policy Update',
      message: 'Please review the updated company policy document.',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: false,
    ),
    NotificationItem(
      title: 'System Maintenance',
      message: 'Scheduled maintenance on 2024-08-15 from 2-4 AM.',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
    ),
    NotificationItem(
      title: 'New Employee Onboarded',
      message: 'John Doe has joined as a new software engineer.',
      timestamp: DateTime.now().subtract(const Duration(days: 3)),
      isRead: false,
    ),
  ];

  List<NotificationItem> get notifications =>
      List<NotificationItem>.unmodifiable(_notifications.reversed);

  int get unreadCount =>
      _notifications.where((NotificationItem n) => !n.isRead).length;

  void markAsRead(NotificationItem item) {
    final int index = _notifications.indexOf(item);
    if (index != -1) {
      _notifications[index].isRead = true;
      notifyListeners();
    }
  }

  void addNotification(NotificationItem item) {
    _notifications.add(item);
    notifyListeners();
  }

  void clearAllNotifications() {
    _notifications.clear();
    notifyListeners();
  }
}