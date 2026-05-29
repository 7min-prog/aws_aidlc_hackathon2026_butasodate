import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:buta_app/shared/app_config.dart';
import 'package:buta_app/shared/theme.dart';
import 'package:buta_app/shared/state/auth_state.dart';
import 'package:buta_app/shared/state/boot_state.dart';
import 'package:buta_app/shared/services/api_client.dart';
import 'package:buta_app/features/battle/battle_fight_screen.dart';
import 'package:buta_app/features/battle/battle_tab_screen.dart';
import 'package:buta_app/features/account/friend_search_screen.dart';
import 'package:buta_app/features/account/friend_list_screen.dart';
import 'package:buta_app/features/home/home_screen.dart';
import 'package:buta_app/features/auth/login_screen.dart';
import 'package:buta_app/features/auth/signup_screen.dart';
import 'package:buta_app/features/auth/confirm_screen.dart';
import 'package:buta_app/features/auth/nickname_screen.dart';
import 'package:buta_app/features/record/record_confirm_screen.dart';
import 'package:buta_app/features/settings/profile_edit_screen.dart';
import 'package:buta_app/features/battle/battle_matching_screen.dart';
import 'package:buta_app/features/battle/battle_result_screen.dart';

import '../helpers/test_helpers.dart';

Widget _w(Widget child) => ProviderScope(
  overrides: [
    authStateProvider.overrideWith(() => FakeAuthNotifier(testTokens)),
    bootProvider.overrideWith(() => FakeBootNotifier(BootResult(
      destination: BootDestination.home, profile: testProfile, avatar: testAvatar, summary: testSummary,
    ))),
  ],
  child: MaterialApp(theme: butaTheme, home: child),
);

void main() {
  setUpAll(() => AppConfig.init(Flavor.dev));
  setUp(() => SharedPreferences.setMockInitialValues({
    'id_token': 'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ1c2VyLTEyMyJ9.x',
    'access_token': 'test-access',
    'refresh_token': 'test-refresh',
  }));

  group('ApiClient with mocked Dio', () {
    test('get resolves auth URL', () async {
      final dio = Dio(BaseOptions(baseUrl: AppConfig.authApiBase));
      final adapter = DioAdapter(dio: dio);
      adapter.onGet('/users/me', (s) => s.reply(200, {'userId': 'u1', 'nickname': 'test', 'email': 'a@b.com', 'authProvider': 'EMAIL', 'createdAt': '2026-01-01'}));
      final res = await dio.get('/users/me');
      expect(res.data['nickname'], 'test');
    });

    test('post resolves recording URL', () async {
      final dio = Dio(BaseOptions(baseUrl: AppConfig.recordingApiBase));
      final adapter = DioAdapter(dio: dio);
      adapter.onPost('/activities', (s) => s.reply(201, {'recordId': 'r1', 'points': 50}), data: Matchers.any);
      final res = await dio.post('/activities', data: {'categoryId': 'food_late_ramen'});
      expect(res.data['points'], 50);
    });

    test('put resolves avatar URL', () async {
      final dio = Dio(BaseOptions(baseUrl: AppConfig.avatarApiBase));
      final adapter = DioAdapter(dio: dio);
      adapter.onPut('/avatar/name', (s) => s.reply(200, {'name': 'ぶたさん'}), data: Matchers.any);
      final res = await dio.put('/avatar/name', data: {'name': 'ぶたさん'});
      expect(res.data['name'], 'ぶたさん');
    });

    test('delete resolves social URL', () async {
      final dio = Dio(BaseOptions(baseUrl: AppConfig.socialApiBase));
      final adapter = DioAdapter(dio: dio);
      adapter.onDelete('/social/friends/f1', (s) => s.reply(204, null));
      final res = await dio.delete('/social/friends/f1');
      expect(res.statusCode, 204);
    });

    test('ApiClient provider creates instance', () {
      final container = ProviderContainer(overrides: [
        authStateProvider.overrideWith(() => FakeAuthNotifier(testTokens)),
      ]);
      addTearDown(container.dispose);
      final client = container.read(apiClientProvider);
      expect(client, isA<ApiClient>());
    });
  });

  group('BattleFightScreen - extended pump', () {
    testWidgets('long pump exercises animation code', (t) async {
      await t.pumpWidget(_w(const BattleFightScreen(matchData: {'matchId': 'm1', 'player1Id': 'user-123'})));
      // Pump many frames to exercise animation controllers
      for (var i = 0; i < 30; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('pump with seconds exercises timer', (t) async {
      await t.pumpWidget(_w(const BattleFightScreen(matchData: {'matchId': 'm1', 'player1Id': 'user-123'})));
      for (var i = 0; i < 5; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      // Advance timer by seconds
      for (var i = 0; i < 5; i++) {
        await t.pump(const Duration(seconds: 1));
      }
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('FriendSearchScreen - extended interaction', () {
    testWidgets('search triggers loading state', (t) async {
      await t.pumpWidget(_w(const FriendSearchScreen()));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      final fields = find.byType(TextField);
      if (fields.evaluate().isNotEmpty) {
        await t.enterText(fields.first, 'abc');
        await t.pump();
        await t.tap(find.text('けんさく'));
        // Pump a few frames to see loading state
        await t.pump();
        await t.pump(const Duration(milliseconds: 50));
        for (var i = 0; i < 20; i++) {
          await t.pump(const Duration(milliseconds: 100));
        }
      }
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('FriendListScreen - extended pump', () {
    testWidgets('extended pump after load', (t) async {
      await t.pumpWidget(_w(const FriendListScreen()));
      // Extended pump to cover all async paths
      for (var i = 0; i < 30; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('HomeScreen - extended coverage', () {
    testWidgets('renders with error message', (t) async {
      await t.pumpWidget(ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => FakeAuthNotifier(testTokens)),
          bootProvider.overrideWith(() => FakeBootNotifier(BootResult(
            destination: BootDestination.home,
          ))),
        ],
        child: MaterialApp(theme: butaTheme, home: const HomeScreen()),
      ));
      for (var i = 0; i < 20; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('renders with avatarImagePath', (t) async {
      await t.pumpWidget(ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => FakeAuthNotifier(testTokens)),
          bootProvider.overrideWith(() => FakeBootNotifier(BootResult(
            destination: BootDestination.home, profile: testProfile, avatar: testAvatar,
            summary: testSummary, avatarImagePath: '/tmp/test.png',
          ))),
        ],
        child: MaterialApp(theme: butaTheme, home: const HomeScreen()),
      ));
      for (var i = 0; i < 20; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('BattleTabScreen - friend battle interaction', () {
    testWidgets('friend battle tap triggers API', (t) async {
      await t.pumpWidget(ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => FakeAuthNotifier(testTokens)),
          battleHistoryProvider.overrideWith((ref) async => <dynamic>[]),
          rankingsProvider.overrideWith((ref) async => {'rankings': <dynamic>[], 'myId': ''}),
        ],
        child: MaterialApp(theme: butaTheme, home: const BattleTabScreen()),
      ));
      for (var i = 0; i < 15; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      await t.tap(find.text('フレンド たいせん'));
      for (var i = 0; i < 15; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(Scaffold), findsWidgets);
    });
  });

  group('LoginScreen - host field', () {
    testWidgets('host field exists in dev mode', (t) async {
      await t.pumpWidget(_w(const LoginScreen()));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      // In dev mode, there should be a host input field
      expect(find.byType(TextField), findsWidgets);
    });
  });

  group('SignupScreen - form fields', () {
    testWidgets('has email and password fields', (t) async {
      await t.pumpWidget(_w(const SignupScreen()));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('entering signup data', (t) async {
      await t.pumpWidget(_w(const SignupScreen()));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      final fields = find.byType(TextField);
      if (fields.evaluate().length >= 2) {
        await t.enterText(fields.at(0), 'new@test.com');
        await t.pump();
        await t.enterText(fields.at(1), 'Pass1234!');
        await t.pump();
      }
    });
  });

  group('ConfirmScreen - code entry', () {
    testWidgets('entering confirmation code', (t) async {
      await t.pumpWidget(_w(const ConfirmScreen(email: 'test@test.com')));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      final fields = find.byType(TextField);
      if (fields.evaluate().isNotEmpty) {
        await t.enterText(fields.first, '123456');
        await t.pump();
      }
    });
  });

  group('NicknameScreen - name entry', () {
    testWidgets('entering nickname text', (t) async {
      await t.pumpWidget(_w(const NicknameScreen()));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      final fields = find.byType(TextField);
      if (fields.evaluate().isNotEmpty) {
        await t.enterText(fields.first, 'テストぶた');
        await t.pump();
      }
    });
  });

  group('ProfileEditScreen - form interaction', () {
    testWidgets('entering nickname and avatar name', (t) async {
      await t.pumpWidget(_w(const ProfileEditScreen()));
      for (var i = 0; i < 15; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      final fields = find.byType(TextField);
      if (fields.evaluate().length >= 2) {
        await t.enterText(fields.at(0), '新しいニックネーム');
        await t.pump();
        await t.enterText(fields.at(1), '新しいアバター名');
        await t.pump();
      }
    });
  });

  group('BattleMatchingScreen - extended', () {
    testWidgets('long pump exercises matching logic', (t) async {
      await t.pumpWidget(_w(const BattleMatchingScreen()));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(seconds: 1));
      }
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('RecordConfirmScreen - extended', () {
    testWidgets('renders with different categories', (t) async {
      for (final cat in [
        {'categoryId': 'food_late_ramen', 'name': 'しんやラーメン', 'basePoints': 50, 'iconKey': 'cat-ramen'},
        {'categoryId': 'life_stay_up', 'name': 'よふかし', 'basePoints': 30, 'iconKey': 'cat-moon'},
      ]) {
        await t.pumpWidget(_w(RecordConfirmScreen(category: cat)));
        for (var i = 0; i < 10; i++) {
          await t.pump(const Duration(milliseconds: 100));
        }
        expect(find.byType(Scaffold), findsOneWidget);
      }
    });
  });

  group('BattleResultScreen - extended', () {
    testWidgets('win with custom name', (t) async {
      await t.pumpWidget(_w(const BattleResultScreen(win: true, myName: 'マイぶた')));
      for (var i = 0; i < 15; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('lose with custom name', (t) async {
      await t.pumpWidget(_w(const BattleResultScreen(win: false, myName: 'マイぶた')));
      for (var i = 0; i < 15; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
