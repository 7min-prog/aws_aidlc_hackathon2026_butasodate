import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:buta_app/shared/services/api_client.dart';
import 'package:buta_app/shared/models/record_summary.dart';

final recordingRepositoryProvider = Provider<RecordingRepository>((ref) {
  return RecordingRepository(ref.read(apiClientProvider));
});

class RecordingRepository {
  final ApiClient _api;
  RecordingRepository(this._api);

  Future<Map<String, dynamic>> getActivities({int limit = 20, String? cursor}) async {
    final res = await _api.get('/activities', queryParameters: {'limit': limit, if (cursor != null) 'cursor': cursor});
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> recordActivity({required String categoryId, String? memo, String? recordId}) async {
    final res = await _api.post('/activities', data: {
      'records': [{'categoryId': categoryId, if (memo != null) 'memo': memo, if (recordId != null) 'recordId': recordId}],
    });
    return res.data as Map<String, dynamic>;
  }

  Future<RecordSummary?> getSummary() async {
    try {
      final res = await _api.get('/activities', queryParameters: {'limit': 1});
      final data = res.data['summary'] as Map<String, dynamic>?;
      if (data == null) return null;
      return RecordSummary.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    final res = await _api.get('/categories');
    return (res.data['categories'] as List?)?.cast<Map<String, dynamic>>() ?? [];
  }
}
