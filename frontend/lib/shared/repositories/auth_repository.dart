import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:buta_app/shared/state/auth_state.dart';
import 'package:buta_app/shared/models/user_profile.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.read(authDioProvider));
});

class AuthRepository {
  final Dio _dio;
  AuthRepository(this._dio);

  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await _dio.post('/auth/login', data: {'email': email, 'password': password});
    return res.data as Map<String, dynamic>;
  }

  Future<void> signup(String email, String password) async {
    await _dio.post('/auth/signup', data: {'email': email, 'password': password});
  }

  Future<void> confirmSignup(String email, String code) async {
    await _dio.post('/auth/confirm', data: {'email': email, 'code': code});
  }

  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    final res = await _dio.post('/auth/refresh', data: {'refreshToken': refreshToken});
    return res.data as Map<String, dynamic>;
  }

  Future<UserProfile> getProfile(String accessToken) async {
    final res = await _dio.get('/users/me', options: Options(headers: {'Authorization': accessToken}));
    return UserProfile.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> setNickname(String accessToken, String nickname) async {
    await _dio.post('/users/profile', data: {'nickname': nickname}, options: Options(headers: {'Authorization': accessToken}));
  }
}
