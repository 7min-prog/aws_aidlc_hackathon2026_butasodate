import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:buta_app/shared/state/boot_state.dart';
import 'package:buta_app/shared/state/auth_state.dart';
import 'package:buta_app/shared/services/image_cache_service.dart';
import 'package:buta_app/shared/app_config.dart';

/// テスト用Connectivity関数
Future<List<ConnectivityResult>> Function() fakeOnline() => () async => [ConnectivityResult.wifi];
Future<List<ConnectivityResult>> Function() fakeOffline() => () async => [ConnectivityResult.none];

void main() {

  /// 全APIをモックしたDioファクトリを返す
  Dio Function(String, String) createMockDioFactory({
    Map<String, dynamic>? profileResponse,
    Map<String, dynamic>? avatarResponse,
    Map<String, dynamic>? summaryResponse,
    Map<String, dynamic>? friendsResponse,
    int profileStatus = 200,
    int avatarStatus = 200,
  }) {
    return (baseUrl, token) {
      final dio = Dio(BaseOptions(baseUrl: baseUrl));
      final adapter = DioAdapter(dio: dio);

      // Auth API
      if (profileResponse != null) {
        adapter.onGet('/users/me', (s) => s.reply(profileStatus, profileResponse));
      }

      // Avatar API
      if (avatarResponse != null) {
        adapter.onGet('/avatar', (s) => s.reply(avatarStatus, avatarResponse));
      }
      adapter.onPost('/avatar', (s) => s.reply(201, avatarResponse ?? {}), data: Matchers.any);

      // Recording API
      adapter.onGet('/activities/summary', (s) => s.reply(200, summaryResponse ?? {'todayCount': 0, 'todayPoints': 0, 'date': DateTime.now().toIso8601String().substring(0, 10)}), queryParameters: {'period': 'today'});

      // Social API
      adapter.onGet('/social/friends/requests', (s) => s.reply(200, friendsResponse ?? {'requests': []}));

      // Health sync (fire-and-forget)
      adapter.onPost('/health-sync', (s) => s.reply(200, {}), data: Matchers.any);

      return dio;
    };
  }

  group('BootNotifier - no tokens', () {
    test('returns login destination', () async {
      SharedPreferences.setMockInitialValues({});
      final authDio = Dio(BaseOptions(baseUrl: 'http://mock'));
      DioAdapter(dio: authDio);

      final c = ProviderContainer(overrides: [
        authDioProvider.overrideWithValue(authDio),
        connectivityCheckProvider.overrideWithValue(fakeOnline()),
      ]);
      addTearDown(c.dispose);

      final result = await c.read(bootProvider.future);
      expect(result.destination, BootDestination.login);
    });
  });

  group('BootNotifier - offline', () {
    test('returns home with offline flag when no cache', () async {
      SharedPreferences.setMockInitialValues({'access_token': 'a', 'refresh_token': 'r'});
      final tempDir = await Directory.systemTemp.createTemp('boot_offline_');
      final authDio = Dio(BaseOptions(baseUrl: 'http://mock'));
      DioAdapter(dio: authDio);

      final c = ProviderContainer(overrides: [
        authDioProvider.overrideWithValue(authDio),
        connectivityCheckProvider.overrideWithValue(fakeOffline()),
        cacheDirectoryProvider.overrideWithValue(() async => tempDir),
      ]);
      addTearDown(() async { c.dispose(); if (await tempDir.exists()) await tempDir.delete(recursive: true); });

      // authStateを先に初期化
      await c.read(authStateProvider.future);
      final result = await c.read(bootProvider.future);
      expect(result.destination, BootDestination.home);
      expect(result.isOffline, isTrue);
      expect(result.errorMessage, 'ネットワークに接続できません');
    });
  });

  group('BootNotifier - online, profile has no nickname', () {
    test('returns nickname destination', () async {
      SharedPreferences.setMockInitialValues({'access_token': 'a', 'refresh_token': 'r'});
      final tempDir = await Directory.systemTemp.createTemp('boot_nick_');
      final authDio = Dio(BaseOptions(baseUrl: 'http://mock'));
      DioAdapter(dio: authDio);

      final factory = createMockDioFactory(
        profileResponse: {'userId': 'u1', 'email': 'a@b.com', 'nickname': null, 'authProvider': 'EMAIL', 'createdAt': '2026-01-01'},
      );

      final c = ProviderContainer(overrides: [
        authDioProvider.overrideWithValue(authDio),
        connectivityCheckProvider.overrideWithValue(fakeOnline()),
        bootDioFactoryProvider.overrideWithValue(factory),
        cacheDirectoryProvider.overrideWithValue(() async => tempDir),
      ]);
      addTearDown(() async { c.dispose(); if (await tempDir.exists()) await tempDir.delete(recursive: true); });

      await c.read(authStateProvider.future);
      final result = await c.read(bootProvider.future);
      expect(result.destination, BootDestination.nickname);
      expect(result.profile?.userId, 'u1');
    });
  });

  group('BootNotifier - online, full success', () {
    test('returns home with all data', () async {
      SharedPreferences.setMockInitialValues({'access_token': 'a', 'refresh_token': 'r'});
      final tempDir = await Directory.systemTemp.createTemp('boot_full_');
      final authDio = Dio(BaseOptions(baseUrl: 'http://mock'));
      DioAdapter(dio: authDio);

      final factory = createMockDioFactory(
        profileResponse: {'userId': 'u1', 'email': 'a@b.com', 'nickname': 'テスト', 'authProvider': 'EMAIL', 'createdAt': '2026-01-01'},
        avatarResponse: {'avatar': {'avatarId': 'av1', 'userId': 'u1', 'name': 'ぶた', 'totalPoints': 100, 'level': 2, 'evolutionStage': 1, 'stats': {'hp': 50, 'attack': 10, 'defense': 5, 'speed': 3}, 'skillIds': [], 'spriteSheetKey': 'sprites/stage1/default'}},
        summaryResponse: {'todayCount': 3, 'todayPoints': 150, 'date': DateTime.now().toIso8601String().substring(0, 10)},
        friendsResponse: {'requests': [{'id': 'req1'}, {'id': 'req2'}]},
      );

      final c = ProviderContainer(overrides: [
        authDioProvider.overrideWithValue(authDio),
        connectivityCheckProvider.overrideWithValue(fakeOnline()),
        bootDioFactoryProvider.overrideWithValue(factory),
        cacheDirectoryProvider.overrideWithValue(() async => tempDir),
      ]);
      addTearDown(() async { c.dispose(); if (await tempDir.exists()) await tempDir.delete(recursive: true); });

      await c.read(authStateProvider.future);
      final result = await c.read(bootProvider.future);
      expect(result.destination, BootDestination.home);
      expect(result.profile?.nickname, 'テスト');
      expect(result.avatar?.name, 'ぶた');
      expect(result.avatar?.level, 2);
      expect(result.pendingRequestCount, 2);
      expect(result.isOffline, isFalse);
    });
  });

  group('BootNotifier - 401 then refresh fails', () {
    test('returns login destination', () async {
      SharedPreferences.setMockInitialValues({'access_token': 'expired', 'refresh_token': 'bad'});
      final tempDir = await Directory.systemTemp.createTemp('boot_401_');

      final authDio = Dio(BaseOptions(baseUrl: 'http://mock'));
      final authAdapter = DioAdapter(dio: authDio);
      authAdapter.onPost('/auth/refresh', (s) => s.reply(401, {'error': 'invalid'}), data: Matchers.any);

      final factory = (String baseUrl, String token) {
        final dio = Dio(BaseOptions(baseUrl: baseUrl));
        final adapter = DioAdapter(dio: dio);
        adapter.onGet('/users/me', (s) => s.reply(401, {'error': 'unauthorized'}));
        return dio;
      };

      final c = ProviderContainer(overrides: [
        authDioProvider.overrideWithValue(authDio),
        connectivityCheckProvider.overrideWithValue(fakeOnline()),
        bootDioFactoryProvider.overrideWithValue(factory),
        cacheDirectoryProvider.overrideWithValue(() async => tempDir),
      ]);
      addTearDown(() async { c.dispose(); if (await tempDir.exists()) await tempDir.delete(recursive: true); });

      await c.read(authStateProvider.future);
      final result = await c.read(bootProvider.future);
      expect(result.destination, BootDestination.login);
    });
  });

  group('BootNotifier - profile 404', () {
    test('returns nickname destination with null profile', () async {
      SharedPreferences.setMockInitialValues({'access_token': 'a', 'refresh_token': 'r'});
      final tempDir = await Directory.systemTemp.createTemp('boot_404_');
      final authDio = Dio(BaseOptions(baseUrl: 'http://mock'));
      DioAdapter(dio: authDio);

      final factory = createMockDioFactory(
        profileResponse: {'error': 'not found'},
        profileStatus: 404,
      );

      final c = ProviderContainer(overrides: [
        authDioProvider.overrideWithValue(authDio),
        connectivityCheckProvider.overrideWithValue(fakeOnline()),
        bootDioFactoryProvider.overrideWithValue(factory),
        cacheDirectoryProvider.overrideWithValue(() async => tempDir),
      ]);
      addTearDown(() async { c.dispose(); if (await tempDir.exists()) await tempDir.delete(recursive: true); });

      await c.read(authStateProvider.future);
      final result = await c.read(bootProvider.future);
      expect(result.destination, BootDestination.nickname);
      expect(result.profile, isNull);
    });
  });
}
