import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import '/Ui Screens/services/image_picker_service.dart'; // Your existing ImagePickerService

class AddEmployeePage extends StatefulWidget {
  final VoidCallback? onEmployeeAdded;

  const AddEmployeePage({Key? key, this.onEmployeeAdded}) : super(key: key);

  @override
  State<AddEmployeePage> createState() => _AddEmployeePageState();
}

class _AddEmployeePageState extends State<AddEmployeePage> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final deptController = TextEditingController();
  final idController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();

  final supabase = Supabase.instance.client;
  File? _selectedImage;
  bool _isLoading = false;

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

  Future<void> _saveEmployee() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? imageUrl;

      // Upload image if selected
      if (_selectedImage != null) {
        imageUrl = await _uploadImage(_selectedImage!);
        if (imageUrl == null) {
          throw Exception('Failed to upload image');
        }
      }

      // Insert employee data
      await supabase.from('users').insert([{
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'role': 'Employee',
        'department': deptController.text.trim().isEmpty ? null : deptController.text.trim(),
        'emp_id': idController.text.trim().isEmpty
            ? null
            : int.tryParse(idController.text.trim()),
        'phone': phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
        'profile_image_url': imageUrl,
      }]);

      setState(() => _isLoading = false);

      // Success screen
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => SuccessAddedEmployeeScreen(
              employeeName: nameController.text.trim(),
              onGoToEmployees: widget.onEmployeeAdded,
            ),
          ),
        );
      }

      // Clear form
      nameController.clear();
      emailController.clear();
      deptController.clear();
      idController.clear();
      phoneController.clear();
      setState(() => _selectedImage = null);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error adding employee: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Employee"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  // Profile Image Section
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
                                : null,
                          ),
                          child: _selectedImage == null
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
                  const SizedBox(height: 24),

                  _buildTextField(
                      controller: nameController,
                      label: "Name",
                      icon: Icons.person,
                      mandatory: true),
                  const SizedBox(height: 16),
                  _buildTextField(
                      controller: emailController,
                      label: "Email",
                      icon: Icons.email,
                      keyboard: TextInputType.emailAddress,
                      mandatory: true),
                  const SizedBox(height: 16),
                  _buildTextField(
                      controller: deptController,
                      label: "Department",
                      icon: Icons.apartment),
                  const SizedBox(height: 16),
                  _buildTextField(
                      controller: idController,
                      label: "ID Number",
                      icon: Icons.badge,
                      keyboard: TextInputType.number),
                  const SizedBox(height: 16),
                  _buildTextField(
                      controller: phoneController,
                      label: "Phone Number",
                      icon: Icons.phone,
                      keyboard: TextInputType.phone),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveEmployee,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
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
                          : const Text("Save",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
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
    bool mandatory = false,
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
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blue, width: 2)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 2)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 2)),
      ),
      validator: (value) {
        if (mandatory && (value == null || value.isEmpty)) {
          return "Please enter $label";
        }
        return null;
      },
    );
  }
}

// ------------------- Success Screen -------------------

class SuccessAddedEmployeeScreen extends StatelessWidget {
  final String employeeName;
  final VoidCallback? onGoToEmployees;

  const SuccessAddedEmployeeScreen({
    super.key,
    required this.employeeName,
    this.onGoToEmployees,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Success'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(Icons.check_circle_outline,
                  color: Colors.green, size: 120),
              const SizedBox(height: 30),
              const Text(
                'Employee Added Successfully!',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 50),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.group_outlined),
                  label: const Text('Go to Employee List'),
                  onPressed: () {
                    if (onGoToEmployees != null) onGoToEmployees!();
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Add Another Employee'),
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => AddEmployeePage(
                          onEmployeeAdded: onGoToEmployees,
                        ),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.blue, width: 1.5),
                    foregroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}