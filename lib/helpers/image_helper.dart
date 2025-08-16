import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class FileHelper {
  // Folder tujuan: Pictures/Newwicker
  static Future<Directory> getAppImageDirectory() async {
    final directory = await getExternalStorageDirectory(); 
    final newDir = Directory('${directory!.path}/Pictures/Newwicker');
    if (!await newDir.exists()) {
      await newDir.create(recursive: true);
    }
    return newDir;
  }

  // Copy satu asset ke folder internal
  static Future<File> copyAssetToInternal(String assetPath, String fileName) async {
    final byteData = await rootBundle.load(assetPath);
    final dir = await getAppImageDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(byteData.buffer.asUint8List());
    return file;
  }

  // Copy list asset sekaligus
  static Future<void> copyAssets(List<String> assets) async {
    for (var asset in assets) {
      final fileName = asset.split('/').last; // ambil nama file
      await copyAssetToInternal(asset, fileName);
    }
  }

  // Load semua file dari folder
  static Future<List<File>> loadAllImages() async {
    final dir = await getAppImageDirectory();
    return dir
        .listSync()
        .whereType<File>()
        .toList();
  }
}
