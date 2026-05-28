import 'package:dio/dio.dart';

/// DioExceptionやその他の例外から、ユーザーに表示するエラー詳細文字列を生成する
String formatApiError(Object error) {
  if (error is DioException) {
    final status = error.response?.statusCode;
    final data = error.response?.data;
    final detail = data is Map ? (data['error'] ?? data['message'] ?? data.toString()) : (data?.toString() ?? error.message ?? 'Unknown');
    if (status != null) return '[$status] $detail';
    // ネットワークエラー等
    return error.message ?? error.type.name;
  }
  return error.toString();
}
