import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/data_models.dart';
import '../providers/user_management_data.dart';

class EditUserPage extends StatefulWidget {
  final GenUiEmployee user;

  const EditUserPage({super.key, required this.user});

  @override
  State<EditUserPage> createState() => _EditUserPageState();
}

class _EditUserPageState extends State<EditUserPage> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _roleController;
  late TextEditingController _departmentController;
  late TextEditingController _idNumberController;
  late TextEditingController _phoneNumberController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _emailController = TextEditingController(text: widget.user.email);
    _roleController = TextEditingController(text: widget.user.role);
    _departmentController =
        TextEditingController(text: widget.user.department);
    _idNumberController = TextEditingController(text: widget.user.idNumber);
    _phoneNumberController =
        TextEditingController(text: widget.user.phoneNumber);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _roleController.dispose();
    _departmentController.dispose();
    _idNumberController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userManagementData =
    Provider.of<UserManagementData>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: Text('Edit ${widget.user.name}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name')),
            TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email')),
            TextField(
                controller: _roleController,
                decoration: const InputDecoration(labelText: 'Role')),
            TextField(
                controller: _departmentController,
                decoration: const InputDecoration(labelText: 'Department')),
            TextField(
                controller: _idNumberController,
                decoration: const InputDecoration(labelText: 'ID Number')),
            TextField(
                controller: _phoneNumberController,
                decoration: const InputDecoration(labelText: 'Phone Number')),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Create updated user object
                final updatedUser = GenUiEmployee(
                  id: widget.user.id,
                  name: _nameController.text,
                  email: _emailController.text,
                  role: _roleController.text,
                  department: _departmentController.text,
                  idNumber: _idNumberController.text,
                  phoneNumber: _phoneNumberController.text,
                  time: widget.user.time,
                  status: widget.user.status,
                );

                try {
                  userManagementData.updateUser(updatedUser); // ✅ just call it
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('User updated successfully!')),
                    );
                    Navigator.pop(context);
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error updating user: $e')),
                    );
                  }
                }
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
