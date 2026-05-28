import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:buta_app/shared/app_config.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  try { AppConfig.init(Flavor.dev); } catch (_) {}

  // Image.assetのエラーを無視
  final originalOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    final msg = details.exceptionAsString();
    if (msg.contains('AssetManifest') || msg.contains('Unable to load asset') || msg.contains('IMAGE RESOURCE SERVICE')) return;
    originalOnError?.call(details);
  };

  ErrorWidget.builder = (details) => const SizedBox.shrink();

  // アセットファイルをメモリにキャッシュ
  final assetCache = <String, ByteData>{};
  final dirs = ['assets/pixel-art/backgrounds', 'assets/pixel-art/icons', 'assets/tutorial', 'assets/bgm'];
  for (final dirPath in dirs) {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) continue;
    for (final file in dir.listSync().whereType<File>()) {
      final key = '$dirPath/${file.uri.pathSegments.last}';
      final bytes = file.readAsBytesSync();
      assetCache[key] = ByteData.sublistView(Uint8List.fromList(bytes));
    }
  }
  // 個別PNGアセット
  for (final path in ['assets/pig_default.png', 'assets/pig_ramen.png', 'assets/pig_happy.png', 'assets/pig_utouto.png', 'assets/splash2.png', 'assets/app_icon.png']) {
    final file = File(path);
    if (file.existsSync()) {
      assetCache[path] = ByteData.sublistView(Uint8List.fromList(file.readAsBytesSync()));
    }
  }

  // AssetManifest.binをStandardMessageCodecでエンコード
  // 全PNGアセットをマニフェストに登録
  final manifestMap = <String, List<Map<String, Object>>>{};
  for (final key in assetCache.keys) {
    manifestMap[key] = [{'asset': key}];
  }
  final manifestBytes = const StandardMessageCodec().encodeMessage(manifestMap)!;
  assetCache['AssetManifest.bin'] = manifestBytes;

  // 1x1透明PNG
  const pixel = [137,80,78,71,13,10,26,10,0,0,0,13,73,72,68,82,0,0,0,1,0,0,0,1,8,6,0,0,0,31,21,196,137,0,0,0,13,73,68,65,84,120,156,99,96,0,2,0,0,5,0,1,226,38,5,155,0,0,0,0,73,69,78,68,174,66,96,130];
  final pixelData = ByteData.sublistView(Uint8List.fromList(pixel));

  // アセットリクエストをインターセプト
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
    'flutter/assets',
    (message) async {
      if (message == null) return null;
      final key = String.fromCharCodes(message.buffer.asUint8List(message.offsetInBytes, message.lengthInBytes));
      if (assetCache.containsKey(key)) return assetCache[key];
      if (key.endsWith('.png') || key.endsWith('.jpg')) return pixelData;
      return null;
    },
  );

  // audioplayersプラグインのモック
  const audioChannel = MethodChannel('xyz.luan/audioplayers.global');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    audioChannel,
    (call) async => null,
  );
  const audioPlayerChannel = MethodChannel('xyz.luan/audioplayers');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    audioPlayerChannel,
    (call) async => null,
  );

  return testMain();
}
