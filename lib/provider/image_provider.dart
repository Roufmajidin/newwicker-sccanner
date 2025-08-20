import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:newwicker/helpers/image_edit.dart';

class ImageCacheProvider with ChangeNotifier {
  final Map<String, Uint8List?> _cache = {};

  Uint8List? getImage(String articleCode) => _cache[articleCode];

  Future<void> loadImage(String articleCode) async {
    if (_cache.containsKey(articleCode)) return; // sudah ada
    final img = await ImageHelper.loadWithCache(articleCode, maxWidth: 300); 
    _cache[articleCode] = img;
    notifyListeners();
  }
}