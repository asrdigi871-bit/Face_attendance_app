import 'dart:io';
import 'dart:collection'; // <- for UnmodifiableUint8ListView
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class FaceEmbedder {
  late Interpreter _interpreter;
  bool _isLoaded = false;

  FaceEmbedder();

  Future<void> loadModel() async {
    if (!_isLoaded) {
      _interpreter = await Interpreter.fromAsset('assets/models/facenet.tflite');
      _isLoaded = true;
    }
  }

  List<List<List<List<double>>>> _imageToInputFromImage(img.Image image) {
    final resized = img.copyResize(image, width: 160, height: 160); // match model input

    return List.generate(1, (_) {
      return List.generate(160, (y) {
        return List.generate(160, (x) {
          final pixel = resized.getPixel(x, y);
          final r = pixel.r;
          final g = pixel.g;
          final b = pixel.b;
          return [
            (r - 127.5) / 128.0,
            (g - 127.5) / 128.0,
            (b - 127.5) / 128.0,
          ];
        });
      });
    });

  }

  Future<List<double>> getEmbeddingFromImage(img.Image image) async {
    if (!_isLoaded) await loadModel();

    final input = _imageToInputFromImage(image);

    // Output shape must match [1, 128]
    final output = List.generate(1, (_) => List.filled(128, 0.0));

    _interpreter.run(input, output);

    // Return flat list (128 values)
    return List<double>.from(output.first);
  }


}

extension ListReshape on List {
  List reshape(List<int> shape) {
    if (shape.reduce((a, b) => a * b) != length) {
      throw Exception("Shape does not match total elements");
    }
    List res = this;
    for (int i = shape.length - 1; i > 0; i--) {
      int size = shape.sublist(i).reduce((a, b) => a * b);
      res = List.generate(shape[i - 1],
              (j) => res.sublist(j * size ~/ shape[i - 1], (j + 1) * size ~/ shape[i - 1]));
    }
    return res;
  }
}
