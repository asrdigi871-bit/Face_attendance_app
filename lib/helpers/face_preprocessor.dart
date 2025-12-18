import 'dart:math';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FacePreprocessor {
  static final _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableLandmarks: true,
    ),
  );

  /// Detects the largest face, aligns using eyes, crops, and resizes to 160x160
  /// Also saves debug image to local storage
  static Future<img.Image?> extractAlignedFace({
    required String imagePath,
  }) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final faces = await _faceDetector.processImage(inputImage);
    if (faces.isEmpty) return null;

    // Pick largest face
    faces.sort((a, b) => (b.boundingBox.width * b.boundingBox.height)
        .compareTo(a.boundingBox.width * a.boundingBox.height));
    final face = faces.first;
    final box = face.boundingBox;

    final bytes = await File(imagePath).readAsBytes();
    final original = img.decodeImage(bytes);
    if (original == null) return null;

    // Center crop around the bounding box + some margin
    final margin = 0.2; // 20% margin
    final cropX = max(0, (box.left - box.width * margin).toInt());
    final cropY = max(0, (box.top - box.height * margin).toInt());
    final cropWidth = min(original.width - cropX, (box.width * (1 + 2 * margin)).toInt());
    final cropHeight = min(original.height - cropY, (box.height * (1 + 2 * margin)).toInt());

    img.Image cropped = img.copyCrop(
      original,
      x: cropX,
      y: cropY,
      width: cropWidth,
      height: cropHeight,
    );

    // Align using eyes
    final leftEye = face.landmarks[FaceLandmarkType.leftEye]?.position;
    final rightEye = face.landmarks[FaceLandmarkType.rightEye]?.position;
    if (leftEye != null && rightEye != null) {
      final dx = rightEye.x - leftEye.x;
      final dy = rightEye.y - leftEye.y;
      final angle = atan2(dy, dx) * 180 / pi;
      cropped = img.copyRotate(cropped, angle: -angle);
    }

    // Resize for model input
    final processed = img.copyResize(cropped, width: 160, height: 160);

    // Save debug image
    final debugFile = File('${Directory.systemTemp.path}/debug_face.jpg');
    await debugFile.writeAsBytes(img.encodeJpg(processed));

    print("Debug face saved at: ${debugFile.path}");

    return processed;
  }
}
