import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:buta_app/shared/app_config.dart';
import 'package:buta_app/shared/state/auth_state.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref);
});

class ApiClient {
  final Ref _ref;
  late final Dio _dio;

  ApiClient(this._ref) {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('id_token') ?? prefs.getString('access_token');
        if (token != null) {
          options.headers['Authorization'] = token;
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          final refreshed = await _ref.read(authStateProvider.notifier).refreshToken();
          if (refreshed) {
            final retryResponse = await _dio.fetch(error.requestOptions);
            return handler.resolve(retryResponse);
          }
        }
        handler.next(error);
      },
    ));
  }

  String _resolveUrl(String path) {
    if (path.startsWith('/auth/') || path.startsWith('/users/') || path == '/account') {
      return '${AppConfig.authApiBase}$path';
    } else if (path.startsWith('/activities') || path.startsWith('/categories')) {
      return '${AppConfig.recordingApiBase}$path';
    } else if (path.startsWith('/avatar')) {
      return '${AppConfig.avatarApiBase}$path';
    } else if (path.startsWith('/social/') || path.startsWith('/rankings') || path.startsWith('/battles/')) {
      return '${AppConfig.socialApiBase}$path';
    } else if (path.startsWith('/admin')) {
      return '${AppConfig.adminApiBase}$path';
    }
    return '${AppConfig.authApiBase}$path';
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) =>
      _dio.get(_resolveUrl(path), queryParameters: queryParameters);
  Future<Response> post(String path, {Object? data}) =>
      _dio.post(_resolveUrl(path), data: data);
  Future<Response> put(String path, {Object? data}) =>
      _dio.put(_resolveUrl(path), data: data);
  Future<Response> delete(String path) =>
      _dio.delete(_resolveUrl(path));
}
