import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:buta_app/shared/api_client.dart';

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
      final dio = Dio(BaseOptions(baseUrl: ApiClient.baseUrl));
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

  Future<bool> signup(String email, String password) async {
    try {
      final dio = Dio(BaseOptions(baseUrl: ApiClient.baseUrl));
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
      final dio = Dio(BaseOptions(baseUrl: ApiClient.baseUrl));
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
    final currentTokens = state.valueOrNull;
    if (currentTokens?.refreshToken == null) return false;

    try {
      final dio = Dio(BaseOptions(baseUrl: ApiClient.baseUrl));
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
    state = const AsyncData(null);
  }

  Future<void> _saveTokens(AuthTokens tokens) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, tokens.accessToken);
    if (tokens.refreshToken != null) {
      await prefs.setString(_refreshTokenKey, tokens.refreshToken!);
    }
  }
}

final authStateProvider = AsyncNotifierProvider<AuthStateNotifier, AuthTokens?>(() {
  return AuthStateNotifier();
});

// 簡易的にログイン済みかどうかを判定
final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).valueOrNull != null;
});
