import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:buta_app/shared/state/auth_state.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref);
});

class ApiClient {
  final Ref _ref;
  late final Dio _dio;

  // mockサーバー: http://localhost:3000
  // 本番: https://YOUR_API_URL.execute-api.ap-northeast-1.amazonaws.com/dev
  static const baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:3000');

  ApiClient(this._ref) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final authState = await _ref.read(authStateProvider.future);
        final token = authState?.accessToken;
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
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

  Future<Response> get(String path) => _dio.get(path);
  Future<Response> post(String path, {Object? data}) => _dio.post(path, data: data);
  Future<Response> put(String path, {Object? data}) => _dio.put(path, data: data);
  Future<Response> delete(String path) => _dio.delete(path);
}
