import 'dart:io';
import 'package:image/image.dart' as img;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../helpers/face_embedder.dart';   // <-- adjust path to where FaceEmbedder.dart is
import '../../helpers/face_preprocessor.dart';
import 'dart:math' as math;


class AddEmployeePage extends StatefulWidget {
  final VoidCallback? onEmployeeAdded; // Callback to refresh users

  const AddEmployeePage({Key? key, this.onEmployeeAdded}) : super(key: key);

  @override
  State<AddEmployeePage> createState() => _AddEmployeePageState();
}
List<double> normalizeEmbedding(List<double> embedding) {
  final norm = embedding.fold(0.0, (sum, e) => sum + e * e);
  final magnitude = norm == 0 ? 1.0 : math.sqrt(norm);
  return embedding.map((e) => e / magnitude).toList();
}

class _AddEmployeePageState extends State<AddEmployeePage> {

  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final deptController = TextEditingController();
  final idController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();

  String? _profileImageUrl;

  final supabase = Supabase.instance.client;

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _profileImageUrl = null; // reset network url
      });
    }
  }

  FaceEmbedder? faceEmbedder;

  @override
  void initState() {
    super.initState();
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

  Future<void> _saveEmployee() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload a face photo to add an employee")),
      );
      return;
    }

    try {
      // 1️⃣ Upload image
      final imageUrl = await _uploadImage(_selectedImage!);
      if (imageUrl == null) throw Exception("Image upload failed");

      // 2️⃣ Preprocess face (detect + align)
      final processedFace = await FacePreprocessor.extractAlignedFace(
        imagePath: _selectedImage!.path,
      );
      if (processedFace == null) throw Exception("No face detected in selected image");

      // 3️⃣ Generate embedding
      // 3️⃣ Generate embedding from the processed face
      var embedding = await faceEmbedder!.getEmbeddingFromImage(processedFace);
      embedding = normalizeEmbedding(embedding);
      if (embedding.isEmpty) throw Exception("Failed to generate embedding");

      // 4️⃣ Save to Supabase
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
        'face_embedding': embedding,
      }]);

      // ✅ Success
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => SuccessAddedEmployeeScreen(
            employeeName: nameController.text.trim(),
            onGoToEmployees: widget.onEmployeeAdded,
          ),
        ),
      );

      // Clear form
      nameController.clear();
      emailController.clear();
      deptController.clear();
      idController.clear();
      phoneController.clear();
      setState(() => _selectedImage = null);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error adding employee: $e")),
      );
    }
  }




  Future<String?> _uploadImage(File image) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      await supabase.storage.from('employee_images').upload(fileName, image);
      final publicUrl = supabase.storage.from('employee_images').getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Employee"), backgroundColor: Colors.white, foregroundColor: Colors.black87, elevation: 0),
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
                          if (value == 'camera') {
                            _pickImage(ImageSource.camera);
                          } else if (value == 'gallery') {
                            _pickImage(ImageSource.gallery);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'camera',
                            child: Text('Capture Photo'),
                          ),
                          const PopupMenuItem(
                            value: 'gallery',
                            child: Text('Select from Gallery'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Mandatory Fields
              _buildTextField(controller: nameController, label: "Name", icon: Icons.person, mandatory: true),
              const SizedBox(height: 16),
              _buildTextField(controller: emailController, label: "Email", icon: Icons.email, keyboard: TextInputType.emailAddress, mandatory: true),
              const SizedBox(height: 16),

              // Optional Fields
              _buildTextField(controller: deptController, label: "Department", icon: Icons.apartment),
              const SizedBox(height: 16),
              _buildTextField(controller: idController, label: "ID Number", icon: Icons.badge, keyboard: TextInputType.number),
              const SizedBox(height: 16),
              _buildTextField(controller: phoneController, label: "Phone Number", icon: Icons.phone, keyboard: TextInputType.phone),
              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveEmployee,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text("Save", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blue, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 2)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 2)),
      ),
      validator: (value) {
        if (mandatory && (value == null || value.isEmpty)) return "Please enter $label";
        return null;
      },
    );
  }
}


// ------------------- Success Screen -------------------


class SuccessAddedEmployeeScreen extends StatelessWidget {
  final String employeeName;
  final VoidCallback? onGoToEmployees; // Optional callback to refresh list

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
          onPressed: () => Navigator.of(context).pop(), // Back button
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

              // Header
              const Text(
                'Employee Added Successfully!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 10),



              const SizedBox(height: 50),

              // Go to Employee List button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.group_outlined),
                  label: const Text('Go to Employee List'),
                  onPressed: () {
                    if (onGoToEmployees != null) {
                      onGoToEmployees!(); // refresh employee list
                    }
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

              // Add Another Employee button
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

