import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:buta_app/shared/constants.dart';
import 'package:buta_app/shared/models/models.dart';
import 'package:buta_app/shared/services/image_cache_service.dart';
import 'package:buta_app/shared/state/auth_state.dart';

enum AppBootStatus { checking, loadingData, done, error }

enum BootDestination { login, nickname, home }

class BootResult {
  final BootDestination destination;
  final UserProfile? profile;
  final Avatar? avatar;
  final RecordSummary? summary;
  final int pendingRequestCount;
  final String? avatarImagePath;

  BootResult({
    required this.destination,
    this.profile,
    this.avatar,
    this.summary,
    this.pendingRequestCount = 0,
    this.avatarImagePath,
  });
}

/// テストでオーバーライド可能なDioファクトリ（baseURL + token付き）
final bootDioFactoryProvider = Provider<Dio Function(String baseUrl, String token)>((ref) {
  return (baseUrl, token) => Dio(BaseOptions(
    baseUrl: baseUrl,
    headers: {'Authorization': token},
  ));
});

class BootNotifier extends AsyncNotifier<BootResult> {
  @override
  Future<BootResult> build() => _executeBoot();

  Future<BootResult> _executeBoot() async {
    final startTime = DateTime.now();

    // トークン確認
    final authState = ref.read(authStateProvider);
    final tokens = authState.value;
    if (tokens == null) {
      await _waitMinDuration(startTime);
      return BootResult(destination: BootDestination.login);
    }

    // トークン検証 + プロフィール取得
    try {
      final profile = await _fetchProfile(tokens.idToken ?? tokens.accessToken);
      if (profile == null || !profile.hasNickname) {
        await _waitMinDuration(startTime);
        return BootResult(destination: BootDestination.nickname, profile: profile);
      }

      // 初期データ並列取得
      final results = await _fetchInitialData(tokens.idToken ?? tokens.accessToken, profile);
      await _waitMinDuration(startTime);
      return results;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        final refreshed = await ref.read(authStateProvider.notifier).refreshToken();
        if (!refreshed) {
          await _waitMinDuration(startTime);
          return BootResult(destination: BootDestination.login);
        }
        return _executeBoot();
      }
      // ネットワークエラー → ログインに戻す
      await _waitMinDuration(startTime);
      return BootResult(destination: BootDestination.login);
    } catch (_) {
      await _waitMinDuration(startTime);
      return BootResult(destination: BootDestination.login);
    }
  }

  Future<UserProfile?> _fetchProfile(String accessToken) async {
    final dioFactory = ref.read(bootDioFactoryProvider);
    final dio = dioFactory(AppConstants.authApiBase, accessToken);
    try {
      final res = await dio.get('/users/me');
      return UserProfile.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<BootResult> _fetchInitialData(String accessToken, UserProfile profile) async {
    final imageCache = ref.read(imageCacheServiceProvider);
    final dioFactory = ref.read(bootDioFactoryProvider);

    final avatarDio = dioFactory(AppConstants.avatarApiBase, accessToken);
    final recordingDio = dioFactory(AppConstants.recordingApiBase, accessToken);
    final socialDio = dioFactory(AppConstants.socialApiBase, accessToken);

    // 並列実行
    final results = await Future.wait([
      _fetchAvatar(avatarDio),
      _fetchSummary(recordingDio),
      _fetchPendingCount(socialDio),
    ], eagerError: false);

    final avatar = results[0] as Avatar?;
    final summary = results[1] as RecordSummary?;
    final pendingCount = results[2] as int? ?? 0;

    // 画像プリロード（非ブロッキング）
    String? imagePath;
    if (avatar != null) {
      imagePath = await imageCache.getOrDownload(avatar.spriteSheetKey);
    }

    return BootResult(
      destination: BootDestination.home,
      profile: profile,
      avatar: avatar,
      summary: summary,
      pendingRequestCount: pendingCount,
      avatarImagePath: imagePath,
    );
  }

  Future<Avatar?> _fetchAvatar(Dio dio) async {
    try {
      final res = await dio.get('/avatar');
      return Avatar.fromJson(res.data['avatar'] as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        try {
          final createRes = await dio.post('/avatar', data: {'name': 'ぶたさん'});
          return Avatar.fromJson(createRes.data['avatar'] as Map<String, dynamic>);
        } catch (_) {
          return null;
        }
      }
      return null;
    }
  }

  Future<RecordSummary?> _fetchSummary(Dio dio) async {
    try {
      final res = await dio.get('/activities/summary', queryParameters: {'period': 'today'});
      return RecordSummary.fromJson(res.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<int> _fetchPendingCount(Dio dio) async {
    try {
      final res = await dio.get('/social/friends/requests');
      final requests = res.data['requests'] as List<dynamic>? ?? [];
      return requests.length;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _waitMinDuration(DateTime startTime) async {
    final elapsed = DateTime.now().difference(startTime);
    if (elapsed < AppConstants.splashMinDuration) {
      await Future.delayed(AppConstants.splashMinDuration - elapsed);
    }
  }

  Future<void> retry() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _executeBoot());
  }
}

final bootProvider = AsyncNotifierProvider<BootNotifier, BootResult>(() => BootNotifier());
