import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:uuid/uuid.dart';

class MarkAttendancePage extends StatefulWidget {
  final String employeeId;
  final String employeeCode;

  const MarkAttendancePage({
    super.key,
    required this.employeeId,
    required this.employeeCode,
  });

  @override
  State<MarkAttendancePage> createState() => _MarkAttendancePageState();
}

class _MarkAttendancePageState extends State<MarkAttendancePage>
    with SingleTickerProviderStateMixin {
  final SupabaseClient supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(enableContours: true, enableLandmarks: true),
  );

  File? _capturedImage;
  bool _isLoading = false;
  String? _lastAction;

  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController =
    AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _glowAnimation =
        Tween<double>(begin: 0.0, end: 12.0).animate(_glowController);

    _markAbsentIfMissedDays();
  }

  @override
  void dispose() {
    _faceDetector.close();
    _glowController.dispose();
    super.dispose();
  }
  Future<void> _markAbsentIfMissedDays() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // 1️⃣ Fetch latest attendance entry for this employee
      final response = await supabase
          .from('attendance_logs')
          .select('date')
          .eq('employee_id', int.parse(widget.employeeId))
          .order('date', ascending: false)
          .limit(1)
          .maybeSingle();

      DateTime? lastAttendanceDate;

      if (response != null && response['date'] != null) {
        lastAttendanceDate = DateTime.parse(response['date']);
      }

      // 2️⃣ Calculate missed days (between last attendance and today)
      DateTime startDate = lastAttendanceDate != null
          ? lastAttendanceDate.add(const Duration(days: 1))
          : today; // if no record found, start from today

      while (startDate.isBefore(today)) {
        final formattedDate =
            "${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}";

        // Check if record for that day exists
        final existing = await supabase
            .from('attendance_logs')
            .select('id')
            .eq('employee_id', int.parse(widget.employeeId))
            .eq('date', formattedDate)
            .maybeSingle();

        if (existing == null) {
          await supabase.from('attendance_logs').insert({
            'employee_id': int.parse(widget.employeeId),
            'check_in': null,
            'check_out': null,
            'photo_url': null,
            'status': 'Absent',
            'date': formattedDate,
          });
        }

        startDate = startDate.add(const Duration(days: 1));
      }
    } catch (e) {
      debugPrint("Error marking absentees: $e");
    }
  }


  Future<void> _handleAttendance(String type) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (pickedFile == null) return;

    setState(() {
      _capturedImage = File(pickedFile.path);
      _isLoading = true;
      _lastAction = type;
    });

    try {
      final hasFace = await _detectFace(_capturedImage!);
      if (!hasFace) {
        _showMessage("No face detected. Try again.", isError: true);
        setState(() => _isLoading = false);
        return;
      }

      // Compress image
      final compressed = await _compressImage(_capturedImage!);
      final filePath =
          'attendance/${widget.employeeId}/${const Uuid().v4()}.jpg';

      await supabase.storage.from('attendance_photos').upload(
        filePath,
        compressed,
        fileOptions: const FileOptions(upsert: true),
      );

      final photoUrl =
      supabase.storage.from('attendance_photos').getPublicUrl(filePath);

      final now = DateTime.now();
      final formattedDate =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day
          .toString().padLeft(2, '0')}";



      // Step 1: Get today's record
      final response = await supabase
          .from('attendance_logs')
          .select('id, check_in, check_out')
          .eq('employee_id', int.parse(widget.employeeId))
          .eq('date', formattedDate)
          .maybeSingle();


      // Step 2: Handle Check-in
      if (type == "checkin") {
        if (response == null) {
          final insertResult = await supabase.from('attendance_logs').insert({
            'employee_id': int.parse(widget.employeeId),
            'photo_url': photoUrl,
            'check_in': now.toIso8601String(),
            'check_out': null,
            'status': 'Present',
            'date': formattedDate,
          }).select().single();

          _showMessage("Checked In successfully!");
        } else {
          _showMessage("Already checked in today!");
        }
      }

      // Step 3: Handle Check-out
      else if (type == "checkout") {
        if (response == null) {
          _showMessage("You haven't checked in yet!", isError: true);
        } else if (response['check_out'] != null) {
          _showMessage("You already checked out today!", isError: true);
        } else {

          try {
            final updateResult = await supabase
                .from('attendance_logs')
                .update({
              'check_out': now.toIso8601String(),
              'status': 'Checked Out',
              'photo_url': photoUrl,
            })
                .eq('id', response['id'])
                .select()
                .single();

            _showMessage(" Checked Out successfully!");

            // Wait a bit for the update to propagate
            await Future.delayed(const Duration(milliseconds: 500));

            // Navigate back and signal refresh
            if (mounted) {
              Navigator.pop(context, true);
            }
          } catch (updateError) {
            _showMessage(
                "Failed to update checkout: $updateError", isError: true);
          }
        }
      }

      setState(() => _capturedImage = null);
    } catch (e, stackTrace) {
      _showMessage("Error: $e", isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<File> _compressImage(File file) async {
    final dir = await Directory.systemTemp.createTemp();
    final targetPath = '${dir.path}/${const Uuid().v4()}.jpg';
    final compressedXFile = await FlutterImageCompress.compressAndGetFile(
      file.path,
      targetPath,
      quality: 70,
    );
    return compressedXFile != null ? File(compressedXFile.path) : file;
  }

  Future<bool> _detectFace(File image) async {
    final inputImage = InputImage.fromFile(image);
    final faces = await _faceDetector.processImage(inputImage);
    return faces.isNotEmpty;
  }

  void _showMessage(String msg, {bool isError = false}) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    final screenHeight = MediaQuery
        .of(context)
        .size
        .height;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Mark Attendance",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20,color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF3E9FED), Colors.black],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 140),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: screenWidth * 0.85,
                height: screenHeight * 0.35,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.4), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: _capturedImage != null
                      ? Image.file(
                    _capturedImage!,
                    fit: BoxFit.cover,
                  )
                      : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.camera_alt, color: Colors.white70, size: 60),
                      SizedBox(height: 12),
                      Text(
                        "No Photo Captured",
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height:50),

              // Loading indicator
              if (_isLoading)
                Column(
                  children: const [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      "Processing...",
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    _buildGlowButton(
                      text: "Check In",
                      colors: [Colors.greenAccent, Colors.green],
                      onTap: () => _handleAttendance("checkin"),
                      icon: Icons.login_rounded,
                    ),
                    const SizedBox(height: 55),
                    _buildGlowButton(
                      text: "Check Out",
                      colors: [Colors.redAccent, Colors.deepOrangeAccent],
                      onTap: () => _handleAttendance("checkout"),
                      icon: Icons.logout_rounded,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlowButton({
    required String text,
    required List<Color> colors,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    final screenWidth = MediaQuery
        .of(context)
        .size
        .width;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          return Container(
            width: screenWidth * 0.7,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              gradient: LinearGradient(colors: colors),
              boxShadow: [
                BoxShadow(
                  color: colors.first.withOpacity(0.6),
                  blurRadius: _glowAnimation.value * 2,
                  spreadRadius: _glowAnimation.value / 1.5,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 22),
                const SizedBox(width: 8),
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}