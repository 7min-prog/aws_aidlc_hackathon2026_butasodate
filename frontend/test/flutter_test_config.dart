import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:buta_app/shared/app_config.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  try { AppConfig.init(Flavor.dev); } catch (_) {}

  // アセットファイルをメモリにキャッシュ
  final assetCache = <String, ByteData>{};
  final dirs = ['assets/pixel-art/backgrounds', 'assets/pixel-art/icons'];
  for (final dirPath in dirs) {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) continue;
    for (final file in dir.listSync().whereType<File>()) {
      final key = '$dirPath/${file.uri.pathSegments.last}';
      final bytes = file.readAsBytesSync();
      assetCache[key] = ByteData.sublistView(Uint8List.fromList(bytes));
    }
  }

  // アセットリクエストをインターセプト
  ServicesBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
    'flutter/assets',
    (message) async {
      if (message == null) return null;
      final key = String.fromCharCodes(message.buffer.asUint8List(message.offsetInBytes, message.lengthInBytes));
      return assetCache[key];
    },
  );

  return testMain();
}
