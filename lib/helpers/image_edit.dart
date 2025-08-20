import 'dart:typed_data';

class ImageHelper {
  static Future<Uint8List?> loadWithCache(String articleCode, {required int maxWidth}) async {
    // simulasi load gambar (misalnya dari asset / db / file system)
    await Future.delayed(const Duration(milliseconds: 200));
    // return null kalau gak ada gambar
    return null;
  }
}

// === Global Cache sederhana ===
class ImageCacheManager {
  static final Map<String, Future<Uint8List?>> _cache = {};

  static Future<Uint8List?> loadImage(String articleCode) {
    if (_cache.containsKey(articleCode)) {
      return _cache[articleCode]!;
    } else {
      final future = ImageHelper.loadWithCache(articleCode, maxWidth: 300);
      _cache[articleCode] = future;
      return future;
    }
  }
}