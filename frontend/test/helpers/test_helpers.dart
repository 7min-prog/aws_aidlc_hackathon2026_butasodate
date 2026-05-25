import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:buta_app/shared/models/models.dart';
import 'package:buta_app/shared/state/auth_state.dart';
import 'package:buta_app/shared/state/boot_state.dart';
import 'package:buta_app/shared/services/image_cache_service.dart';
import 'package:buta_app/shared/services/api_client.dart';
import 'package:buta_app/shared/theme.dart';
import 'package:dio/dio.dart';

// --- テストデータ ---

final testTokens = AuthTokens(
  accessToken: 'test-access-token',
  refreshToken: 'test-refresh-token',
  idToken: 'test-id-token',
);

final testProfile = UserProfile(
  userId: 'user-123',
  nickname: 'テストぶた',
  email: 'test@example.com',
  authProvider: 'EMAIL',
  createdAt: '2026-01-01T00:00:00Z',
);

final testAvatar = Avatar(
  avatarId: 'avatar-1',
  userId: 'user-123',
  name: 'ぶたさん',
  totalPoints: 100,
  level: 3,
  evolutionStage: 1,
  stats: AvatarStats(hp: 60, attack: 15, defense: 12, speed: 11),
  skillIds: [],
  spriteSheetKey: 'sprites/stage1/default',
);

final testSummary = RecordSummary(
  todayCount: 3,
  todayPoints: 45,
  date: DateTime.now().toIso8601String().substring(0, 10),
);

// --- ヘルパー ---

Widget testApp({
  required Widget child,
  AuthTokens? tokens,
  BootResult? bootResult,
}) {
  return ProviderScope(
    overrides: [
      authStateProvider.overrideWith(() => FakeAuthNotifier(tokens)),
      if (bootResult != null)
        bootProvider.overrideWith(() => FakeBootNotifier(bootResult)),
    ],
    child: MaterialApp(theme: butaTheme, home: child),
  );
}

// --- Fakes ---

class FakeAuthNotifier extends AuthStateNotifier {
  final AuthTokens? _tokens;
  FakeAuthNotifier(this._tokens);
  @override
  Future<AuthTokens?> build() async => _tokens;
}

class FakeBootNotifier extends BootNotifier {
  final BootResult _result;
  FakeBootNotifier(this._result);
  @override
  Future<BootResult> build() async => _result;
}

class FakeImageCacheService extends ImageCacheService {
  FakeImageCacheService() : super(() async => Directory.systemTemp);
  @override
  Future<void> clearAll() async {}
  @override
  Future<bool> isCached(String k) async => false;
  @override
  Future<String?> getOrDownload(String k) async => null;
}

/// テスト用ApiClient（Dioをモックアダプター付きで注入）
class FakeApiClient implements ApiClient {
  final Dio dio;
  FakeApiClient(this.dio);

  @override
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) => dio.get(path, queryParameters: queryParameters);
  @override
  Future<Response> post(String path, {Object? data}) => dio.post(path, data: data);
  @override
  Future<Response> put(String path, {Object? data}) => dio.put(path, data: data);
  @override
  Future<Response> delete(String path) => dio.delete(path);
}
