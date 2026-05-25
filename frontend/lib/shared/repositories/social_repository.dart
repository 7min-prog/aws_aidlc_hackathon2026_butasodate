import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:buta_app/shared/services/api_client.dart';

final socialRepositoryProvider = Provider<SocialRepository>((ref) {
  return SocialRepository(ref.read(apiClientProvider));
});

class SocialRepository {
  final ApiClient _api;
  SocialRepository(this._api);

  Future<List<Map<String, dynamic>>> getFriends() async {
    final res = await _api.get('/social/friends');
    return (res.data['friends'] as List?)?.cast<Map<String, dynamic>>() ?? [];
  }

  Future<List<Map<String, dynamic>>> getPendingRequests() async {
    final res = await _api.get('/social/friends/requests');
    return (res.data['requests'] as List?)?.cast<Map<String, dynamic>>() ?? [];
  }

  Future<void> sendFriendRequest(String targetUserId) async {
    await _api.post('/social/friends/request', data: {'targetUserId': targetUserId});
  }

  Future<void> respondToRequest(String requestId, bool accept) async {
    await _api.post('/social/friends/respond', data: {'requestId': requestId, 'accept': accept});
  }

  Future<List<Map<String, dynamic>>> getRankings() async {
    final res = await _api.get('/rankings');
    return (res.data['rankings'] as List?)?.cast<Map<String, dynamic>>() ?? [];
  }

  Future<List<Map<String, dynamic>>> getBattleHistory() async {
    final res = await _api.get('/battles/history');
    return (res.data['history'] as List?)?.cast<Map<String, dynamic>>() ?? [];
  }
}
