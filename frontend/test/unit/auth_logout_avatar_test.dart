import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:buta_app/shared/state/auth_state.dart';
import 'package:buta_app/shared/services/image_cache_service.dart';

void main() {

  group('AuthStateNotifier.logout', () {
    test('clears tokens and cache', () async {
      SharedPreferences.setMockInitialValues({'access_token': 'a', 'refresh_token': 'r'});
      final tempDir = await Directory.systemTemp.createTemp('logout_test_');

      final authDio = Dio(BaseOptions(baseUrl: 'http://mock'));
      DioAdapter(dio: authDio);

      final c = ProviderContainer(overrides: [
        authDioProvider.overrideWithValue(authDio),
        cacheDirectoryProvider.overrideWithValue(() async => tempDir),
      ]);
      addTearDown(() async {
        c.dispose();
        if (await tempDir.exists()) await tempDir.delete(recursive: true);
      });

      // Verify tokens exist
      final tokens = await c.read(authStateProvider.future);
      expect(tokens?.accessToken, 'a');

      // Logout
      await c.read(authStateProvider.notifier).logout();

      // Verify tokens cleared
      expect(c.read(authStateProvider).value, isNull);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('access_token'), isNull);
      expect(prefs.getString('refresh_token'), isNull);
    });
  });

  group('AuthStateNotifier.createInitialAvatar', () {
    test('returns true on 201 (created)', () async {
      SharedPreferences.setMockInitialValues({'access_token': 'token', 'refresh_token': 'r'});

      final authDio = Dio(BaseOptions(baseUrl: 'http://mock'));
      DioAdapter(dio: authDio);

      final avatarDio = Dio(BaseOptions(baseUrl: 'http://mock-avatar'));
      final avatarAdapter = DioAdapter(dio: avatarDio);
      avatarAdapter.onPost('/avatar', (s) => s.reply(201, {
        'avatar': {
          'avatarId': 'av1', 'userId': 'u1', 'name': 'ぶたさん',
          'totalPoints': 0, 'level': 1, 'evolutionStage': 1,
          'stats': {'hp': 100, 'attack': 10, 'defense': 10, 'speed': 10},
          'skillIds': [], 'spriteSheetKey': 'sprites/stage1/default',
        }
      }), data: Matchers.any);

      final c = ProviderContainer(overrides: [
        authDioProvider.overrideWithValue(authDio),
        avatarDioProvider.overrideWithValue(avatarDio),
      ]);
      addTearDown(c.dispose);

      await c.read(authStateProvider.future);
      final result = await c.read(authStateProvider.notifier).createInitialAvatar();
      expect(result, isTrue);
    });

    test('returns true on 409 (already exists)', () async {
      SharedPreferences.setMockInitialValues({'access_token': 'token', 'refresh_token': 'r'});

      final authDio = Dio(BaseOptions(baseUrl: 'http://mock'));
      DioAdapter(dio: authDio);

      final avatarDio = Dio(BaseOptions(baseUrl: 'http://mock-avatar'));
      final avatarAdapter = DioAdapter(dio: avatarDio);
      avatarAdapter.onPost('/avatar', (s) => s.reply(409, {'error': 'already exists'}), data: Matchers.any);

      final c = ProviderContainer(overrides: [
        authDioProvider.overrideWithValue(authDio),
        avatarDioProvider.overrideWithValue(avatarDio),
      ]);
      addTearDown(c.dispose);

      await c.read(authStateProvider.future);
      final result = await c.read(authStateProvider.notifier).createInitialAvatar();
      expect(result, isTrue);
    });

    test('returns false when no tokens', () async {
      SharedPreferences.setMockInitialValues({});

      final authDio = Dio(BaseOptions(baseUrl: 'http://mock'));
      DioAdapter(dio: authDio);

      final c = ProviderContainer(overrides: [
        authDioProvider.overrideWithValue(authDio),
      ]);
      addTearDown(c.dispose);

      await c.read(authStateProvider.future);
      final result = await c.read(authStateProvider.notifier).createInitialAvatar();
      expect(result, isFalse);
    });

    test('returns false after max retries on 500', () async {
      SharedPreferences.setMockInitialValues({'access_token': 'token', 'refresh_token': 'r'});

      final authDio = Dio(BaseOptions(baseUrl: 'http://mock'));
      DioAdapter(dio: authDio);

      final avatarDio = Dio(BaseOptions(baseUrl: 'http://mock-avatar'));
      final avatarAdapter = DioAdapter(dio: avatarDio);
      avatarAdapter.onPost('/avatar', (s) => s.reply(500, {'error': 'server error'}), data: Matchers.any);

      final c = ProviderContainer(overrides: [
        authDioProvider.overrideWithValue(authDio),
        avatarDioProvider.overrideWithValue(avatarDio),
      ]);
      addTearDown(c.dispose);

      await c.read(authStateProvider.future);
      final result = await c.read(authStateProvider.notifier).createInitialAvatar();
      expect(result, isFalse);
    }, timeout: const Timeout(Duration(seconds: 15)));
  });
}
