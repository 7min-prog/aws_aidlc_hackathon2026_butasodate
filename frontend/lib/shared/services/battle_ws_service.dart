import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:buta_app/shared/app_config.dart';

/// バトル用WebSocket接続をアプリ全体で共有するシングルトン
class BattleWsService {
  BattleWsService._();
  static final instance = BattleWsService._();

  WebSocketChannel? channel;
  String? matchId;
  StreamController<Map<String, dynamic>> _controller = StreamController.broadcast();
  Stream<Map<String, dynamic>> get messages => _controller.stream;

  Future<void> connect() async {
    if (channel != null) return;
    // 前回closeされていたらcontrollerを再生成
    if (_controller.isClosed) {
      _controller = StreamController.broadcast();
    }
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('id_token') ?? prefs.getString('access_token') ?? '';
    String userId = 'unknown';
    try {
      final parts = token.split('.');
      if (parts.length == 3) {
        final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
        userId = (jsonDecode(payload) as Map<String, dynamic>)['sub'] ?? 'unknown';
      }
    } catch (_) {}

    final wsUrl = AppConfig.isDev
        ? 'ws://${Uri.parse(AppConfig.authApiBase).host}:${Uri.parse(AppConfig.authApiBase).port}/ws?token=$token&userId=$userId'
        : 'wss://cd3lmmh06a.execute-api.ap-northeast-1.amazonaws.com/dev?token=$token&userId=$userId';
    channel = WebSocketChannel.connect(Uri.parse(wsUrl));
    channel!.stream.listen((message) {
      if (!_controller.isClosed) {
        _controller.add(jsonDecode(message as String) as Map<String, dynamic>);
      }
    }, onError: (e) {
      if (!_controller.isClosed) _controller.addError(e);
    }, onDone: () {});
  }

  void send(Map<String, dynamic> msg) {
    channel?.sink.add(jsonEncode(msg));
  }

  void close() {
    channel?.sink.close();
    channel = null;
    matchId = null;
  }

  /// テスト用: ストリームにメッセージを注入
  void injectMessage(Map<String, dynamic> msg) {
    if (_controller.isClosed) {
      _controller = StreamController.broadcast();
    }
    _controller.add(msg);
  }

  /// テスト用: サービスをリセット
  void resetForTest() {
    channel?.sink.close();
    channel = null;
    matchId = null;
    if (_controller.isClosed) {
      _controller = StreamController.broadcast();
    }
  }
}
