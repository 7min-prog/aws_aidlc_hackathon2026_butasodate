import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:buta_app/shared/app_config.dart';
import 'package:buta_app/shared/constants.dart';
import 'package:buta_app/shared/services/cache_service.dart';
import 'package:buta_app/shared/services/image_cache_service.dart';

/// テストでオーバーライド可能なDioプロバイダー
final authDioProvider = Provider<Dio>((ref) => Dio(BaseOptions(baseUrl: AppConfig.authApiBase)));
final avatarDioProvider = Provider<Dio>((ref) => Dio(BaseOptions(baseUrl: AppConstants.avatarApiBase)));

class AuthTokens {
  final String accessToken;
  final String? refreshToken;
  final String? idToken;

  AuthTokens({required this.accessToken, this.refreshToken, this.idToken});
}

class AuthStateNotifier extends AsyncNotifier<AuthTokens?> {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  @override
  Future<AuthTokens?> build() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString(_accessTokenKey);
    final refreshToken = prefs.getString(_refreshTokenKey);

    if (accessToken == null) return null;
    return AuthTokens(accessToken: accessToken, refreshToken: refreshToken);
  }

  Future<bool> login(String email, String password) async {
    try {
      final dio = ref.read(authDioProvider);
      final response = await dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      final tokens = AuthTokens(
        accessToken: response.data['accessToken'],
        refreshToken: response.data['refreshToken'],
        idToken: response.data['idToken'],
      );

      await _saveTokens(tokens);
      state = AsyncData(tokens);
      return true;
    } on DioException catch (e) {
      state = AsyncError(e.response?.data?['error'] ?? 'Login failed', StackTrace.current);
      return false;
    }
  }

  Future<void> devLogin() async {
    final tokens = AuthTokens(accessToken: 'mock-token-admin', refreshToken: 'mock-refresh-admin');
    await _saveTokens(tokens);
    state = AsyncData(tokens);
  }

  Future<bool> signup(String email, String password) async {
    try {
      final dio = ref.read(authDioProvider);
      await dio.post('/auth/signup', data: {
        'email': email,
        'password': password,
      });
      return true;
    } on DioException {
      return false;
    }
  }

  Future<bool> confirmSignup(String email, String code) async {
    try {
      final dio = ref.read(authDioProvider);
      await dio.post('/auth/confirm', data: {
        'email': email,
        'code': code,
      });
      return true;
    } on DioException {
      return false;
    }
  }

  Future<bool> refreshToken() async {
    final currentTokens = state.value;
    if (currentTokens?.refreshToken == null) return false;

    try {
      final dio = ref.read(authDioProvider);
      final response = await dio.post('/auth/refresh', data: {
        'refreshToken': currentTokens!.refreshToken,
      });

      final newTokens = AuthTokens(
        accessToken: response.data['accessToken'],
        refreshToken: currentTokens.refreshToken,
        idToken: response.data['idToken'],
      );

      await _saveTokens(newTokens);
      state = AsyncData(newTokens);
      return true;
    } on DioException {
      await logout();
      return false;
    }
  }


  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    // キャッシュも全削除
    await ref.read(cacheServiceProvider).clearAll();
    await ref.read(imageCacheServiceProvider).clearAll();
    state = const AsyncData(null);
  }

  /// ニックネーム設定後にアバターを作成（最大3回リトライ）
  Future<bool> createInitialAvatar() async {
    final tokens = state.value;
    if (tokens == null) return false;

    final dio = ref.read(avatarDioProvider);
    dio.options.headers['Authorization'] = 'Bearer ${tokens.accessToken}';

    for (var i = 0; i < AppConstants.avatarCreateMaxRetries; i++) {
      try {
        await dio.post('/avatar', data: {'name': 'ぶたさん'});
        return true;
      } on DioException catch (e) {
        if (e.response?.statusCode == 409) return true; // 既に存在
        if (i < AppConstants.avatarCreateMaxRetries - 1) {
          await Future.delayed(AppConstants.avatarCreateRetryDelay);
        }
      }
    }
    return false;
  }

  static const _idTokenKey = 'id_token';

  Future<void> _saveTokens(AuthTokens tokens) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, tokens.accessToken);
    if (tokens.refreshToken != null) {
      await prefs.setString(_refreshTokenKey, tokens.refreshToken!);
    }
    if (tokens.idToken != null) {
      await prefs.setString(_idTokenKey, tokens.idToken!);
    }
  }
}

final authStateProvider = AsyncNotifierProvider<AuthStateNotifier, AuthTokens?>(() {
  return AuthStateNotifier();
});

// 簡易的にログイン済みかどうかを判定
final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).value != null;
});
