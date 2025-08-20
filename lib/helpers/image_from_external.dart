import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class ImageHelper {
  static const _internalFolder = 'NewwickerImages';
  static const _publicFolder = '/storage/emulated/0/DCIM/Pictures/Newwicker';
  static final Map<String, Uint8List> cachedImages = {};

  static Future<void> preloadImages(List<Map<String, dynamic>> carts) async {
    for (var cart in carts) {
      final code = cart['article_code']?.toString() ?? '';
      if (code.isNotEmpty && !cachedImages.containsKey(code)) {
        final bytes = await loadWithCache(code); // loadWithCache tetap async
        if (bytes != null) {
          cachedImages[code] = bytes;
          print('✅ Image preloaded: $code'); 
        } else {
          print('⚠️ Image not found: $code');
        }
      }
    }
  }

  /// Load gambar dengan caching
  static Future<Uint8List?> loadWithCache(String articleCode) async {
    final internalFile = await _getInternalFile(articleCode);

    // 1️⃣ Cek cache internal
    if (await internalFile.exists()) {
      return await internalFile.readAsBytes();
    }

    // 2️⃣ Cek folder publik
    final publicFile = File('$_publicFolder/$articleCode.webp');
    if (await publicFile.exists()) {
      final bytes = await publicFile.readAsBytes();
      // Simpan ke internal app untuk cache
      await saveToInternal(articleCode, bytes);
      return bytes;
    }

    // 3️⃣ Fallback ke asset
    try {
      final bytes = await rootBundle.load('assets/images/$articleCode.webp');
      return bytes.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }

  /// Simpan ke internal app folder
  static Future<File> saveToInternal(String articleCode, Uint8List data) async {
    final file = await _getInternalFile(articleCode);
    await file.create(recursive: true);
    return file.writeAsBytes(data, flush: true);
  }

  static Future<File> _getInternalFile(String articleCode) async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/$_internalFolder');
    if (!folder.existsSync()) folder.createSync(recursive: true);
    return File('${folder.path}/$articleCode.webp');
  }
}
