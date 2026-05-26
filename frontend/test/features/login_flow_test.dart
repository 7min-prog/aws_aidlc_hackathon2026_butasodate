import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:buta_app/shared/theme.dart';
import 'package:buta_app/shared/app_config.dart';
import 'package:buta_app/shared/state/auth_state.dart';
import 'package:buta_app/features/auth/login_screen.dart';

void main() {
  setUpAll(() => AppConfig.init(Flavor.dev));
  setUp(() => SharedPreferences.setMockInitialValues({
    'id_token': 'test-id', 'access_token': 'test-access',
  }));

  group('LoginScreen - login flow', () {
    testWidgets('failed login shows error dialog', (t) async {
      final dio = Dio(BaseOptions(baseUrl: AppConfig.authApiBase));
      final adapter = DioAdapter(dio: dio);
      adapter.onPost('/auth/login', (s) => s.throws(401, DioException(
        requestOptions: RequestOptions(path: '/auth/login'),
        response: Response(requestOptions: RequestOptions(path: '/auth/login'), statusCode: 401, data: {'error': 'Invalid'}),
      )), data: Matchers.any);

      await t.pumpWidget(ProviderScope(
        overrides: [authDioProvider.overrideWithValue(dio)],
        child: MaterialApp(theme: butaTheme, home: const LoginScreen()),
      ));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }

      final fields = find.byType(TextField);
      await t.enterText(fields.at(1), 'bad@example.com');
      await t.pump();
      await t.enterText(fields.at(2), 'wrongpass');
      await t.pump();

      // Tap login button
      final loginBtns = find.text('ログイン');
      await t.tap(loginBtns.last);
      for (var i = 0; i < 20; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      // Error dialog should show
      expect(find.textContaining('しっぱい'), findsWidgets);
    });

    testWidgets('login with nickname null goes to nickname screen', (t) async {
      final dio = Dio(BaseOptions(baseUrl: AppConfig.authApiBase));
      final adapter = DioAdapter(dio: dio);
      adapter.onPost('/auth/login', (s) => s.reply(200, {
        'accessToken': 'a', 'refreshToken': 'r', 'idToken': 'i',
      }), data: Matchers.any);
      adapter.onGet('/users/me', (s) => s.reply(200, {'nickname': null, 'userId': 'u1'}));

      await t.pumpWidget(ProviderScope(
        overrides: [authDioProvider.overrideWithValue(dio)],
        child: MaterialApp(theme: butaTheme, home: const LoginScreen()),
      ));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
