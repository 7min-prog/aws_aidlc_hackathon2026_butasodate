import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:buta_app/shared/services/api_client.dart';
import 'package:buta_app/shared/models/avatar.dart';

final avatarRepositoryProvider = Provider<AvatarRepository>((ref) {
  return AvatarRepository(ref.read(apiClientProvider));
});

class AvatarRepository {
  final ApiClient _api;
  AvatarRepository(this._api);

  Future<Avatar?> getAvatar() async {
    try {
      final res = await _api.get('/avatar');
      return Avatar.fromJson(res.data['avatar'] as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<Avatar?> createAvatar(String name) async {
    try {
      final res = await _api.post('/avatar', data: {'name': name});
      return Avatar.fromJson(res.data['avatar'] as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
