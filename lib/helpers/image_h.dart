// image_helper.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';

class ImageHelper {
  /// Load image dari folder local / assets dan kembalikan sebagai Uint8List
  static Future<Uint8List?> loadImage(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<Uint8List?> loadAssetImage(String assetPath) async {
    try {
      final data = await rootBundle.load(assetPath);
      return data.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }
  
}
