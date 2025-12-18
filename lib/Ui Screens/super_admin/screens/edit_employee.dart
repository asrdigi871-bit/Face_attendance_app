import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import '/Ui Screens/services//image_picker_service.dart'; // Your existing ImagePickerService

class EditEmployeePage extends StatefulWidget {
  final String empId;
  final String name;
  final String department;
  final String idNumber;
  final String email;
  final String phone;
  final String? profileImageUrl;

  const EditEmployeePage({
    Key? key,
    required this.empId,
    required this.name,
    required this.department,
    required this.idNumber,
    required this.email,
    required this.phone,
    this.profileImageUrl,
  }) : super(key: key);

  @override
  State<EditEmployeePage> createState() => _EditEmployeePageState();
}

class _EditEmployeePageState extends State<EditEmployeePage> {
  final _formKey = GlobalKey<FormState>();
  final supabase = Supabase.instance.client;

  late TextEditingController nameController;
  late TextEditingController deptController;
  late TextEditingController idController;
  late TextEditingController emailController;
  late TextEditingController phoneController;

  File? _selectedImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.name);
    deptController = TextEditingController(text: widget.department);
    idController = TextEditingController(text: widget.idNumber);
    emailController = TextEditingController(text: widget.email);
    phoneController = TextEditingController(text: widget.phone);
  }

  @override
  void dispose() {
    nameController.dispose();
    deptController.dispose();
    idController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  void _handleImageSelection(File image) {
    setState(() {
      _selectedImage = image;
    });
  }

  Future<String?> _uploadImage(File imageFile) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${emailController.text.trim()}.jpg';
      final path = 'employee_photos/$fileName';

      // Delete old image if exists
      if (widget.profileImageUrl != null && widget.profileImageUrl!.isNotEmpty) {
        try {
          final oldPath = Uri.parse(widget.profileImageUrl!).pathSegments.last;
          await supabase.storage
              .from('employee-images')
              .remove(['employee_photos/$oldPath']);
        } catch (e) {
        }
      }

      await supabase.storage
          .from('employee-images')
          .upload(path, imageFile);

      final imageUrl = supabase.storage
          .from('employee-images')
          .getPublicUrl(path);

      return imageUrl;
    } catch (e) {
      return null;
    }
  }

  Future<void> _updateEmployee() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? imageUrl = widget.profileImageUrl;

      // Upload new image if selected
      if (_selectedImage != null) {
        final uploadedUrl = await _uploadImage(_selectedImage!);
        if (uploadedUrl != null) {
          imageUrl = uploadedUrl;
        }
      }

      await supabase.from('users').update({
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'department': deptController.text.trim().isEmpty
            ? null
            : deptController.text.trim(),
        'emp_id': idController.text.trim().isEmpty
            ? null
            : idController.text.trim(),
        'phone': phoneController.text.trim().isEmpty
            ? null
            : phoneController.text.trim(),
        'profile_image_url': imageUrl,
      }).eq('id', widget.empId);

      setState(() => _isLoading = false);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Employee updated successfully!")),
      );
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error updating employee: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Employee"),
        elevation: 0,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                // Profile Image Section with blue background
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(bottom: 30),
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: () {
                          ImagePickerService.showImagePickerDialog(
                            context,
                            _handleImageSelection,
                          );
                        },
                        child: Stack(
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey[300],
                                image: _selectedImage != null
                                    ? DecorationImage(
                                  image: FileImage(_selectedImage!),
                                  fit: BoxFit.cover,
                                )
                                    : widget.profileImageUrl != null &&
                                    widget.profileImageUrl!.isNotEmpty
                                    ? DecorationImage(
                                  image: NetworkImage(
                                      widget.profileImageUrl!),
                                  fit: BoxFit.cover,
                                )
                                    : null,
                              ),
                              child: (_selectedImage == null &&
                                  (widget.profileImageUrl == null ||
                                      widget.profileImageUrl!.isEmpty))
                                  ? Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.grey[400],
                              )
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Form Section
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        _buildTextField(
                          controller: nameController,
                          label: "Name",
                          icon: Icons.person,
                          isRequired: true,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: emailController,
                          label: "Email",
                          icon: Icons.email,
                          keyboard: TextInputType.emailAddress,
                          isRequired: true,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: deptController,
                          label: "Department",
                          icon: Icons.apartment,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: idController,
                          label: "ID Number",
                          icon: Icons.badge,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: phoneController,
                          label: "Phone Number",
                          icon: Icons.phone,
                          keyboard: TextInputType.phone,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _updateEmployee,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              backgroundColor: Colors.blue,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                                : const Text(
                              "Update",
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
    bool isRequired = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue),
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding:
        const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
      ),
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) {
          return "Please enter $label";
        }
        return null;
      },
    );
  }
}