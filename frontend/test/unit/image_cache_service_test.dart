import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:buta_app/shared/services/image_cache_service.dart';
import 'package:buta_app/shared/constants.dart';

void main() {
  late Directory tempDir;
  late ImageCacheService service;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('img_cache_test_');
    service = ImageCacheService(() async => tempDir);
  });

  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  group('ImageCacheService.resolveImageUrl', () {
    test('returns correct URL for sprite key', () {
      final url = service.resolveImageUrl('sprites/stage1/kobuta');
      expect(url, '${AppConstants.assetsBaseUrl}sprites/stage1/kobuta.png');
    });

    test('handles nested paths', () {
      final url = service.resolveImageUrl('pocchari/walk');
      expect(url, contains('pocchari/walk.png'));
    });
  });

  group('ImageCacheService.isCached', () {
    test('returns false when file does not exist', () async {
      final result = await service.isCached('sprites/stage1/default');
      expect(result, isFalse);
    });

    test('returns true when file exists', () async {
      final fileName = 'sprites_stage1_default';
      final file = File('${tempDir.path}/sprites/$fileName.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes([0x89, 0x50, 0x4E, 0x47]); // PNG header
      final result = await service.isCached('sprites/stage1/default');
      expect(result, isTrue);
    });
  });

  group('ImageCacheService.getOrDownload', () {
    test('returns cached file path when exists', () async {
      final fileName = 'kobuta_idle';
      final file = File('${tempDir.path}/sprites/$fileName.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes([0x89, 0x50, 0x4E, 0x47]);
      final result = await service.getOrDownload('kobuta/idle');
      expect(result, file.path);
    });

    test('returns null when download fails (no network)', () async {
      final result = await service.getOrDownload('nonexistent/sprite');
      expect(result, isNull);
    });
  });

  group('ImageCacheService.clearAll', () {
    test('removes sprites directory', () async {
      final file = File('${tempDir.path}/sprites/test.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes([1, 2, 3]);
      expect(await file.exists(), isTrue);

      await service.clearAll();
      expect(await Directory('${tempDir.path}/sprites').exists(), isFalse);
    });

    test('does nothing when sprites dir does not exist', () async {
      // Should not throw
      await service.clearAll();
    });
  });
}
