import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:buta_app/shared/auth_state.dart';
import 'package:buta_app/shared/constants.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref);
});

class ApiClient {
  final Ref _ref;

  ApiClient(this._ref);

  Dio _createDio(String baseUrl) {
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final authState = _ref.read(authStateProvider);
        final token = authState.value?.idToken;
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          final refreshed = await _ref.read(authStateProvider.notifier).refreshToken();
          if (refreshed) {
            final retryResponse = await _createDio(error.requestOptions.baseUrl).fetch(error.requestOptions);
            return handler.resolve(retryResponse);
          }
        }
        handler.next(error);
      },
    ));

    return dio;
  }

  // Auth API
  Future<Response> authGet(String path) => _createDio(AppConstants.authApiBase).get(path);
  Future<Response> authPost(String path, {Object? data}) => _createDio(AppConstants.authApiBase).post(path, data: data);
  Future<Response> authPut(String path, {Object? data}) => _createDio(AppConstants.authApiBase).put(path, data: data);
  Future<Response> authDelete(String path) => _createDio(AppConstants.authApiBase).delete(path);

  // Recording API
  Future<Response> recordingGet(String path) => _createDio(AppConstants.recordingApiBase).get(path);
  Future<Response> recordingPost(String path, {Object? data}) => _createDio(AppConstants.recordingApiBase).post(path, data: data);
  Future<Response> recordingDelete(String path) => _createDio(AppConstants.recordingApiBase).delete(path);

  // Avatar API
  Future<Response> avatarGet(String path) => _createDio(AppConstants.avatarApiBase).get(path);
  Future<Response> avatarPost(String path, {Object? data}) => _createDio(AppConstants.avatarApiBase).post(path, data: data);

  // Social API
  Future<Response> socialGet(String path) => _createDio(AppConstants.socialApiBase).get(path);
  Future<Response> socialPost(String path, {Object? data}) => _createDio(AppConstants.socialApiBase).post(path, data: data);
  Future<Response> socialDelete(String path) => _createDio(AppConstants.socialApiBase).delete(path);
}
