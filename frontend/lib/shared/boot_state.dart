import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:buta_app/shared/constants.dart';
import 'package:buta_app/shared/models/models.dart';
import 'package:buta_app/shared/cache_service.dart';
import 'package:buta_app/shared/image_cache_service.dart';
import 'package:buta_app/shared/auth_state.dart';

enum AppBootStatus { checking, loadingData, done, error }

enum BootDestination { login, nickname, home }

class BootResult {
  final BootDestination destination;
  final UserProfile? profile;
  final Avatar? avatar;
  final RecordSummary? summary;
  final int pendingRequestCount;
  final bool isOffline;
  final String? errorMessage;

  BootResult({
    required this.destination,
    this.profile,
    this.avatar,
    this.summary,
    this.pendingRequestCount = 0,
    this.isOffline = false,
    this.errorMessage,
  });
}

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

    // ネットワーク確認
    final connectivity = await Connectivity().checkConnectivity();
    final isOffline = connectivity.contains(ConnectivityResult.none);

    if (isOffline) {
      return _handleOffline(startTime);
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
        // リフレッシュ試行
        final refreshed = await ref.read(authStateProvider.notifier).refreshToken();
        if (!refreshed) {
          await _waitMinDuration(startTime);
          return BootResult(destination: BootDestination.login);
        }
        // リフレッシュ成功 → 再実行
        return _executeBoot();
      }
      return _handleOffline(startTime);
    } catch (_) {
      return _handleOffline(startTime);
    }
  }

  Future<UserProfile?> _fetchProfile(String accessToken) async {
    final dio = Dio(BaseOptions(
      baseUrl: AppConstants.authApiBase,
      headers: {'Authorization': 'Bearer $accessToken'},
    ));
    try {
      final res = await dio.get('/users/me');
      return UserProfile.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<BootResult> _fetchInitialData(String accessToken, UserProfile profile) async {
    final cache = ref.read(cacheServiceProvider);
    final imageCache = ref.read(imageCacheServiceProvider);

    final avatarDio = Dio(BaseOptions(
      baseUrl: AppConstants.avatarApiBase,
      headers: {'Authorization': 'Bearer $accessToken'},
    ));
    final recordingDio = Dio(BaseOptions(
      baseUrl: AppConstants.recordingApiBase,
      headers: {'Authorization': 'Bearer $accessToken'},
    ));
    final socialDio = Dio(BaseOptions(
      baseUrl: AppConstants.socialApiBase,
      headers: {'Authorization': 'Bearer $accessToken'},
    ));

    // 並列実行
    final results = await Future.wait([
      _fetchAvatar(avatarDio),
      _fetchSummary(recordingDio),
      _fetchPendingCount(socialDio),
    ], eagerError: false);

    final avatar = results[0] as Avatar?;
    final summary = results[1] as RecordSummary?;
    final pendingCount = results[2] as int? ?? 0;

    // キャッシュ保存
    await cache.saveProfile(profile);
    if (avatar != null) await cache.saveAvatar(avatar);
    if (summary != null) await cache.saveSummary(summary);

    return BootResult(
      destination: BootDestination.home,
      profile: profile,
      avatar: avatar,
      summary: summary,
      pendingRequestCount: pendingCount,
    );
  }

  Future<Avatar?> _fetchAvatar(Dio dio) async {
    try {
      final res = await dio.get('/avatar');
      return Avatar.fromJson(res.data['avatar'] as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // 自己修復: アバター自動作成
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

  Future<BootResult> _handleOffline(DateTime startTime) async {
    final cache = ref.read(cacheServiceProvider);
    final profile = await cache.loadProfile();
    final avatar = await cache.loadAvatar();
    final summary = await cache.loadSummary();

    if (profile != null) {
      await _waitMinDuration(startTime);
      return BootResult(
        destination: BootDestination.home,
        profile: profile,
        avatar: avatar,
        summary: summary,
        isOffline: true,
      );
    }

    await _waitMinDuration(startTime);
    return BootResult(
      destination: BootDestination.home,
      isOffline: true,
      errorMessage: 'ネットワークに接続できません',
    );
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
