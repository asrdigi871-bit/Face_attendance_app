import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image/image.dart' as img;
import '../../helpers/face_embedder.dart'; // adjust path

class EditEmployeePage extends StatefulWidget {
  final String empId;
  final String name;
  final String department;
  final String idNumber;
  final String email;
  final String phone;
  final String? imagePath;

  const EditEmployeePage({
    Key? key,
    required this.empId,
    required this.name,
    required this.department,
    required this.idNumber,
    required this.email,
    required this.phone,
    this.imagePath,
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

  String? _profileImageUrl;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  FaceEmbedder? faceEmbedder;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.name);
    deptController = TextEditingController(text: widget.department);
    idController = TextEditingController(text: widget.idNumber);
    emailController = TextEditingController(text: widget.email);
    phoneController = TextEditingController(text: widget.phone);
    _profileImageUrl = widget.imagePath;

    faceEmbedder = FaceEmbedder();
    faceEmbedder!.loadModel();
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

  /// 🔹 Pick image from camera/gallery
  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source, imageQuality: 80);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _profileImageUrl = null; // reset old URL
      });
    }
  }

  /// 🔹 Upload image to Supabase Storage
  Future<String?> _uploadImage(File image) async {
    try {
      final fileName = 'updated_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await supabase.storage.from('employee_images').upload(fileName, image);
      final publicUrl = supabase.storage.from('employee_images').getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      return null;
    }
  }

  /// 🔹 Update Employee (with embedding)
  Future<void> _updateEmployee() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      String? imageUrl = _profileImageUrl;
      List<double>? embedding;

      // If a new image is selected
      if (_selectedImage != null) {
        // 1️⃣ Upload the image
        imageUrl = await _uploadImage(_selectedImage!);
        if (imageUrl == null) throw Exception("Image upload failed");

        // 2️⃣ Decode image
        final rawImage = img.decodeImage(await _selectedImage!.readAsBytes());
        if (rawImage == null) throw Exception("Failed to decode image for embedding");

        // 3️⃣ Generate face embedding
        embedding = await faceEmbedder!.getEmbeddingFromImage(rawImage);
      }

      // 4️⃣ Update user record
      await supabase.from('users').update({
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'department': deptController.text.trim().isEmpty ? null : deptController.text.trim(),
        'emp_id': idController.text.trim().isEmpty ? null : idController.text.trim(),
        'phone': phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
        'profile_image_url': imageUrl,
        'face_embedding': embedding?.isEmpty ?? true ? null : embedding,
      }).eq('id', widget.empId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Employee updated successfully!")),
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating employee: $e")),
      );
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Profile Image
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage: _selectedImage != null
                          ? FileImage(_selectedImage!)
                          : (_profileImageUrl != null
                          ? NetworkImage(_profileImageUrl!)
                          : null) as ImageProvider?,
                      child: (_selectedImage == null && _profileImageUrl == null)
                          ? const Icon(Icons.person, size: 50, color: Colors.white)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: PopupMenuButton<String>(
                        icon: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        ),
                        onSelected: (value) {
                          if (value == 'camera') _pickImage(ImageSource.camera);
                          if (value == 'gallery') _pickImage(ImageSource.gallery);
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'camera', child: Text('Capture Photo')),
                          const PopupMenuItem(value: 'gallery', child: Text('Select from Gallery')),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Fields
              _buildTextField(controller: nameController, label: "Name", icon: Icons.person, isRequired: true),
              const SizedBox(height: 16),
              _buildTextField(controller: emailController, label: "Email", icon: Icons.email, keyboard: TextInputType.emailAddress, isRequired: true),
              const SizedBox(height: 16),
              _buildTextField(controller: deptController, label: "Department", icon: Icons.apartment),
              const SizedBox(height: 16),
              _buildTextField(controller: idController, label: "ID Number", icon: Icons.badge),
              const SizedBox(height: 16),
              _buildTextField(controller: phoneController, label: "Phone Number", icon: Icons.phone, keyboard: TextInputType.phone),
              const SizedBox(height: 24),

              // Update Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _updateEmployee,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    backgroundColor: Colors.blue,
                  ),
                  child: const Text("Update", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
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
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blue, width: 2)),
      ),
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) return "Please enter $label";
        return null;
      },
    );
  }
}
