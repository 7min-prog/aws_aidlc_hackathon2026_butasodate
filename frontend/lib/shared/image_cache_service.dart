import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:buta_app/shared/constants.dart';

final imageCacheServiceProvider = Provider<ImageCacheService>((ref) => ImageCacheService());

class ImageCacheService {
  String resolveImageUrl(String spriteSheetKey) {
    return '${AppConstants.assetsBaseUrl}$spriteSheetKey.png';
  }

  Future<String?> getOrDownload(String spriteSheetKey) async {
    final dir = await getApplicationCacheDirectory();
    final fileName = spriteSheetKey.replaceAll('/', '_');
    final file = File('${dir.path}/sprites/$fileName.png');

    if (await file.exists()) return file.path;

    try {
      final url = resolveImageUrl(spriteSheetKey);
      await file.parent.create(recursive: true);
      await Dio().download(url, file.path);
      return file.path;
    } catch (_) {
      return null;
    }
  }

  Future<bool> isCached(String spriteSheetKey) async {
    final dir = await getApplicationCacheDirectory();
    final fileName = spriteSheetKey.replaceAll('/', '_');
    return File('${dir.path}/sprites/$fileName.png').exists();
  }

  Future<void> clearAll() async {
    final dir = await getApplicationCacheDirectory();
    final spritesDir = Directory('${dir.path}/sprites');
    if (await spritesDir.exists()) {
      await spritesDir.delete(recursive: true);
    }
  }
}
