import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:buta_app/shared/auth_state.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref);
});

class ApiClient {
  final Ref _ref;
  late final Dio _dio;

  // TODO: cdk deploy後に実際のURLに差し替え
  static const baseUrl = 'https://YOUR_API_URL.execute-api.ap-northeast-1.amazonaws.com/dev';

  ApiClient(this._ref) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final authState = _ref.read(authStateProvider);
        final token = authState.valueOrNull?.accessToken;
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          // トークン期限切れ → リフレッシュ試行
          final refreshed = await _ref.read(authStateProvider.notifier).refreshToken();
          if (refreshed) {
            // リトライ
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
}
