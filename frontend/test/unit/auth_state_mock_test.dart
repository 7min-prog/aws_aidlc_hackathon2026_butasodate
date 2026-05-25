import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:buta_app/shared/state/auth_state.dart';
import 'package:buta_app/shared/app_config.dart';

void main() {

  group('AuthStateNotifier.login', () {
    test('returns true on success', () async {
      SharedPreferences.setMockInitialValues({});
      final dio = Dio(BaseOptions(baseUrl: 'http://mock'));
      final adapter = DioAdapter(dio: dio);
      adapter.onPost('/auth/login', (s) => s.reply(200, {'accessToken': 'a', 'refreshToken': 'r', 'idToken': 'i'}), data: Matchers.any);

      final c = ProviderContainer(overrides: [authDioProvider.overrideWithValue(dio)]);
      addTearDown(c.dispose);
      final result = await c.read(authStateProvider.notifier).login('t@t.com', 'p');
      expect(result, isTrue);
      expect(c.read(authStateProvider).value?.accessToken, 'a');
    });

    test('returns false on 401', () async {
      SharedPreferences.setMockInitialValues({});
      final dio = Dio(BaseOptions(baseUrl: 'http://mock'));
      final adapter = DioAdapter(dio: dio);
      adapter.onPost('/auth/login', (s) => s.reply(401, {'error': 'bad'}), data: Matchers.any);

      final c = ProviderContainer(overrides: [authDioProvider.overrideWithValue(dio)]);
      addTearDown(c.dispose);
      final result = await c.read(authStateProvider.notifier).login('b@b.com', 'x');
      expect(result, isFalse);
    });
  });

  group('AuthStateNotifier.signup', () {
    test('returns true on success', () async {
      SharedPreferences.setMockInitialValues({});
      final dio = Dio(BaseOptions(baseUrl: 'http://mock'));
      final adapter = DioAdapter(dio: dio);
      adapter.onPost('/auth/signup', (s) => s.reply(200, {}), data: Matchers.any);

      final c = ProviderContainer(overrides: [authDioProvider.overrideWithValue(dio)]);
      addTearDown(c.dispose);
      final result = await c.read(authStateProvider.notifier).signup('n@n.com', 'p');
      expect(result, isTrue);
    });

    test('returns false on error', () async {
      SharedPreferences.setMockInitialValues({});
      final dio = Dio(BaseOptions(baseUrl: 'http://mock'));
      final adapter = DioAdapter(dio: dio);
      adapter.onPost('/auth/signup', (s) => s.reply(400, {}), data: Matchers.any);

      final c = ProviderContainer(overrides: [authDioProvider.overrideWithValue(dio)]);
      addTearDown(c.dispose);
      final result = await c.read(authStateProvider.notifier).signup('d@d.com', 'p');
      expect(result, isFalse);
    });
  });

  group('AuthStateNotifier.confirmSignup', () {
    test('returns true on success', () async {
      SharedPreferences.setMockInitialValues({});
      final dio = Dio(BaseOptions(baseUrl: 'http://mock'));
      final adapter = DioAdapter(dio: dio);
      adapter.onPost('/auth/confirm', (s) => s.reply(200, {}), data: Matchers.any);

      final c = ProviderContainer(overrides: [authDioProvider.overrideWithValue(dio)]);
      addTearDown(c.dispose);
      final result = await c.read(authStateProvider.notifier).confirmSignup('t@t.com', '123456');
      expect(result, isTrue);
    });

    test('returns false on error', () async {
      SharedPreferences.setMockInitialValues({});
      final dio = Dio(BaseOptions(baseUrl: 'http://mock'));
      final adapter = DioAdapter(dio: dio);
      adapter.onPost('/auth/confirm', (s) => s.reply(400, {}), data: Matchers.any);

      final c = ProviderContainer(overrides: [authDioProvider.overrideWithValue(dio)]);
      addTearDown(c.dispose);
      final result = await c.read(authStateProvider.notifier).confirmSignup('t@t.com', 'bad');
      expect(result, isFalse);
    });
  });

  group('AuthStateNotifier.refreshToken', () {
    test('returns true on success', () async {
      SharedPreferences.setMockInitialValues({'access_token': 'old', 'refresh_token': 'rt'});
      final dio = Dio(BaseOptions(baseUrl: 'http://mock'));
      final adapter = DioAdapter(dio: dio);
      adapter.onPost('/auth/refresh', (s) => s.reply(200, {'accessToken': 'new', 'idToken': 'id'}), data: Matchers.any);

      final c = ProviderContainer(overrides: [authDioProvider.overrideWithValue(dio)]);
      addTearDown(c.dispose);
      await c.read(authStateProvider.future);
      final result = await c.read(authStateProvider.notifier).refreshToken();
      expect(result, isTrue);
      expect(c.read(authStateProvider).value?.accessToken, 'new');
    });

    test('returns false when no refresh token', () async {
      SharedPreferences.setMockInitialValues({'access_token': 'a'});
      final dio = Dio(BaseOptions(baseUrl: 'http://mock'));
      DioAdapter(dio: dio);

      final c = ProviderContainer(overrides: [authDioProvider.overrideWithValue(dio)]);
      addTearDown(c.dispose);
      await c.read(authStateProvider.future);
      final result = await c.read(authStateProvider.notifier).refreshToken();
      expect(result, isFalse);
    });
  });
}
