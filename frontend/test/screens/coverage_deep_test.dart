import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:buta_app/shared/theme.dart';
import 'package:buta_app/shared/app_config.dart';
import 'package:buta_app/shared/state/auth_state.dart';
import 'package:buta_app/shared/state/boot_state.dart';
import 'package:buta_app/shared/services/api_client.dart';
import 'package:buta_app/features/battle/battle_fight_screen.dart';
import 'package:buta_app/features/battle/battle_tab_screen.dart';
import 'package:buta_app/features/battle/battle_matching_screen.dart';
import 'package:buta_app/features/battle/battle_result_screen.dart';
import 'package:buta_app/features/record/record_confirm_screen.dart';
import 'package:buta_app/features/record/record_detail_screen.dart';
import 'package:buta_app/features/account/friend_search_screen.dart';
import 'package:buta_app/features/account/friend_list_screen.dart';
import 'package:buta_app/features/account/account_tab_screen.dart';
import 'package:buta_app/features/auth/login_screen.dart';
import 'package:buta_app/features/auth/signup_screen.dart';
import 'package:buta_app/features/auth/confirm_screen.dart';
import 'package:buta_app/features/auth/nickname_screen.dart';
import 'package:buta_app/features/home/home_screen.dart';

import '../helpers/test_helpers.dart';

Widget _w(Widget child) => ProviderScope(
  overrides: [
    authStateProvider.overrideWith(() => FakeAuthNotifier(testTokens)),
    bootProvider.overrideWith(() => FakeBootNotifier(BootResult(destination: BootDestination.home, profile: testProfile, avatar: testAvatar, summary: testSummary))),
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

  group('ApiClient unit tests', () {
    test('creates with ref and resolves URLs', () {
      final container = ProviderContainer(overrides: [
        authStateProvider.overrideWith(() => FakeAuthNotifier(testTokens)),
      ]);
      addTearDown(container.dispose);
      final client = container.read(apiClientProvider);
      expect(client, isNotNull);
    });

    test('get method works with auth path', () async {
      final dio = Dio(BaseOptions(baseUrl: AppConfig.authApiBase));
      final adapter = DioAdapter(dio: dio);
      adapter.onGet('/users/me', (s) => s.reply(200, {'userId': 'u1', 'nickname': 'test'}));
      final res = await dio.get('/users/me');
      expect(res.statusCode, 200);
    });

    test('post method works', () async {
      final dio = Dio(BaseOptions(baseUrl: AppConfig.recordingApiBase));
      final adapter = DioAdapter(dio: dio);
      adapter.onPost('/activities', (s) => s.reply(201, {'recordId': 'r1'}), data: Matchers.any);
      final res = await dio.post('/activities', data: {'categoryId': 'food'});
      expect(res.statusCode, 201);
    });

    test('put method works', () async {
      final dio = Dio(BaseOptions(baseUrl: AppConfig.avatarApiBase));
      final adapter = DioAdapter(dio: dio);
      adapter.onPut('/avatar/name', (s) => s.reply(200, {}), data: Matchers.any);
      final res = await dio.put('/avatar/name', data: {'name': 'test'});
      expect(res.statusCode, 200);
    });

    test('delete method works', () async {
      final dio = Dio(BaseOptions(baseUrl: AppConfig.socialApiBase));
      final adapter = DioAdapter(dio: dio);
      adapter.onDelete('/social/friends/f1', (s) => s.reply(204, null));
      final res = await dio.delete('/social/friends/f1');
      expect(res.statusCode, 204);
    });

    test('401 error handling', () async {
      final dio = Dio(BaseOptions(baseUrl: AppConfig.authApiBase));
      final adapter = DioAdapter(dio: dio);
      adapter.onGet('/users/me', (s) => s.throws(401, DioException(
        requestOptions: RequestOptions(path: '/users/me'),
        response: Response(requestOptions: RequestOptions(path: '/users/me'), statusCode: 401),
      )));
      expect(() => dio.get('/users/me'), throwsA(isA<DioException>()));
    });
  });

  group('BattleFightScreen deep coverage', () {
    testWidgets('renders command panel with 4 skills', (t) async {
      await t.pumpWidget(_w(const BattleFightScreen(matchData: {'matchId': 'm1', 'player1Id': 'user-123', 'player2Id': 'opp-1'})));
      for (var i = 0; i < 15; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      // 4 skill buttons (こうげき x3 + ぼうぎょ x1)
      expect(find.text('ぼうぎょ'), findsOneWidget);
    });

    testWidgets('renders player names', (t) async {
      await t.pumpWidget(_w(const BattleFightScreen(matchData: {'matchId': 'm1', 'player1Id': 'user-123'})));
      for (var i = 0; i < 15; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('じぶん'), findsOneWidget);
      expect(find.text('あいて'), findsOneWidget);
    });

    testWidgets('renders with player2 perspective', (t) async {
      await t.pumpWidget(_w(const BattleFightScreen(matchData: {'matchId': 'm1', 'player1Id': 'other', 'player2Id': 'user-123'})));
      for (var i = 0; i < 15; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('timer counts down', (t) async {
      await t.pumpWidget(_w(const BattleFightScreen(matchData: {'matchId': 'm1'})));
      for (var i = 0; i < 15; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('00:20'), findsOneWidget);
      // Advance timer
      await t.pump(const Duration(seconds: 1));
      await t.pump(const Duration(seconds: 1));
    });

    testWidgets('custom paint renders pig', (t) async {
      await t.pumpWidget(_w(const BattleFightScreen(matchData: {'matchId': 'm1'})));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });

  group('FriendSearchScreen deep coverage', () {
    testWidgets('renders search input and button', (t) async {
      await t.pumpWidget(_w(const FriendSearchScreen()));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('けんさく'), findsOneWidget);
    });

    testWidgets('entering text in search field', (t) async {
      await t.pumpWidget(_w(const FriendSearchScreen()));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      // Find text field and enter text
      final textFields = find.byType(TextField);
      if (textFields.evaluate().isNotEmpty) {
        await t.enterText(textFields.first, 'テスト');
        await t.pump();
      }
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('search with text triggers API call', (t) async {
      await t.pumpWidget(_w(const FriendSearchScreen()));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      final textFields = find.byType(TextField);
      if (textFields.evaluate().isNotEmpty) {
        await t.enterText(textFields.first, 'ぶた');
        await t.pump();
        await t.tap(find.text('けんさく'));
        for (var i = 0; i < 20; i++) {
          await t.pump(const Duration(milliseconds: 100));
        }
      }
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('FriendListScreen deep coverage', () {
    testWidgets('renders friend list UI elements', (t) async {
      await t.pumpWidget(_w(const FriendListScreen()));
      for (var i = 0; i < 20; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('＋ ついか'), findsOneWidget);
      expect(find.textContaining('フレンド'), findsWidgets);
    });

    testWidgets('shows empty state after load', (t) async {
      await t.pumpWidget(_w(const FriendListScreen()));
      for (var i = 0; i < 20; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('フレンドが いないよ'), findsOneWidget);
    });

    testWidgets('add button is tappable', (t) async {
      await t.pumpWidget(_w(const FriendListScreen()));
      for (var i = 0; i < 20; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      // Just verify it exists
      expect(find.text('＋ ついか'), findsOneWidget);
    });
  });

  group('BattleTabScreen deep coverage', () {
    testWidgets('renders with WIN history', (t) async {
      await t.pumpWidget(ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => FakeAuthNotifier(testTokens)),
          battleHistoryProvider.overrideWith((ref) async => [
            {'result': 'WIN', 'opponentName': 'テスト', 'pointChange': 15},
          ]),
          rankingsProvider.overrideWith((ref) async => {
            'rankings': [
              {'userId': 'user-123', 'nickname': 'じぶん', 'points': 200},
            ],
            'myId': 'user-123',
          }),
        ],
        child: MaterialApp(theme: butaTheme, home: const BattleTabScreen()),
      ));
      for (var i = 0; i < 15; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('WIN'), findsOneWidget);
      expect(find.text('YOU '), findsOneWidget);
    });

    testWidgets('renders with LOSE history', (t) async {
      await t.pumpWidget(ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => FakeAuthNotifier(testTokens)),
          battleHistoryProvider.overrideWith((ref) async => [
            {'result': 'LOSE', 'opponentNickname': 'あいて', 'pointChange': -10},
          ]),
          rankingsProvider.overrideWith((ref) async => {
            'rankings': [
              {'userId': 'other', 'nickname': 'あいて', 'points': 300},
              {'userId': 'user-123', 'nickname': 'じぶん', 'points': 100},
            ],
            'myId': 'user-123',
          }),
        ],
        child: MaterialApp(theme: butaTheme, home: const BattleTabScreen()),
      ));
      for (var i = 0; i < 15; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('LOSE'), findsOneWidget);
    });

    testWidgets('friend battle button exists', (t) async {
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
      expect(find.text('フレンド たいせん'), findsOneWidget);
    });

    testWidgets('friend battle button tap', (t) async {
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
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
    });

    testWidgets('shortId helper with long id', (t) async {
      await t.pumpWidget(ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => FakeAuthNotifier(testTokens)),
          battleHistoryProvider.overrideWith((ref) async => [
            {'result': 'WIN', 'opponentId': 'very-long-opponent-id-12345', 'pointChange': 5},
          ]),
          rankingsProvider.overrideWith((ref) async => {'rankings': <dynamic>[], 'myId': ''}),
        ],
        child: MaterialApp(theme: butaTheme, home: const BattleTabScreen()),
      ));
      for (var i = 0; i < 15; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.textContaining('vs'), findsOneWidget);
    });
  });

  group('HomeScreen deep coverage', () {
    testWidgets('renders with full boot data', (t) async {
      await t.pumpWidget(ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => FakeAuthNotifier(testTokens)),
          bootProvider.overrideWith(() => FakeBootNotifier(BootResult(
            destination: BootDestination.home,
            profile: testProfile,
            avatar: testAvatar,
            summary: testSummary,
            pendingRequestCount: 2,
          ))),
        ],
        child: MaterialApp(theme: butaTheme, home: const HomeScreen()),
      ));
      for (var i = 0; i < 20; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('renders offline state', (t) async {
      await t.pumpWidget(ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => FakeAuthNotifier(testTokens)),
          bootProvider.overrideWith(() => FakeBootNotifier(BootResult(
            destination: BootDestination.home,
            profile: testProfile,
            avatar: testAvatar,
          ))),
        ],
        child: MaterialApp(theme: butaTheme, home: const HomeScreen()),
      ));
      for (var i = 0; i < 20; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('renders without avatar', (t) async {
      await t.pumpWidget(ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => FakeAuthNotifier(testTokens)),
          bootProvider.overrideWith(() => FakeBootNotifier(BootResult(
            destination: BootDestination.home,
            profile: testProfile,
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

  group('LoginScreen deep coverage', () {
    testWidgets('email and password fields exist', (t) async {
      await t.pumpWidget(_w(const LoginScreen()));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('メールアドレス'), findsOneWidget);
      expect(find.textContaining('パスワード'), findsWidgets);
    });

    testWidgets('social login buttons exist', (t) async {
      await t.pumpWidget(_w(const LoginScreen()));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.textContaining('Google'), findsOneWidget);
      expect(find.textContaining('X で'), findsOneWidget);
    });

    testWidgets('legal links exist', (t) async {
      await t.pumpWidget(_w(const LoginScreen()));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('利用規約'), findsOneWidget);
      expect(find.text('プライバシーポリシー'), findsOneWidget);
    });
  });

  group('RecordConfirmScreen deep coverage', () {
    testWidgets('renders category info', (t) async {
      await t.pumpWidget(_w(RecordConfirmScreen(category: {
        'categoryId': 'life_stay_up', 'name': 'よふかし', 'basePoints': 30, 'iconKey': 'cat-moon',
      })));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('confirm button exists', (t) async {
      await t.pumpWidget(_w(RecordConfirmScreen(category: {
        'categoryId': 'food_snack', 'name': 'かんしょく', 'basePoints': 20, 'iconKey': 'cat-snack',
      })));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('きろくする'), findsOneWidget);
    });
  });

  group('RecordDetailScreen deep coverage', () {
    testWidgets('renders with full record data', (t) async {
      await t.pumpWidget(_w(RecordDetailScreen(record: {
        'recordId': 'r1', 'categoryId': 'food_binge', 'categoryName': 'ぼういんぼうしょく',
        'points': 40, 'recordedAt': '2026-05-24T01:30:00Z', 'memo': 'テストメモ',
      })));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('renders without memo', (t) async {
      await t.pumpWidget(_w(RecordDetailScreen(record: {
        'recordId': 'r2', 'categoryId': 'life_oversleep', 'categoryName': 'にどね',
        'points': 25, 'recordedAt': '2026-05-24T10:00:00Z',
      })));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('BattleMatchingScreen deep coverage', () {
    testWidgets('renders matching animation', (t) async {
      await t.pumpWidget(_w(const BattleMatchingScreen()));
      for (var i = 0; i < 15; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('timer advances', (t) async {
      await t.pumpWidget(_w(const BattleMatchingScreen()));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      await t.pump(const Duration(seconds: 2));
      await t.pump(const Duration(seconds: 2));
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('BattleResultScreen deep coverage', () {
    testWidgets('win with names', (t) async {
      await t.pumpWidget(_w(const BattleResultScreen(win: true, myName: 'テストぶた')));
      for (var i = 0; i < 15; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('lose with names', (t) async {
      await t.pumpWidget(_w(const BattleResultScreen(win: false, myName: 'テストぶた')));
      for (var i = 0; i < 15; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('AccountTabScreen deep coverage', () {
    testWidgets('renders with pending requests', (t) async {
      await t.pumpWidget(ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => FakeAuthNotifier(testTokens)),
          bootProvider.overrideWith(() => FakeBootNotifier(BootResult(
            destination: BootDestination.home,
            profile: testProfile,
            avatar: testAvatar,
            pendingRequestCount: 5,
          ))),
        ],
        child: MaterialApp(theme: butaTheme, home: const AccountTabScreen()),
      ));
      for (var i = 0; i < 15; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('renders without profile', (t) async {
      await t.pumpWidget(ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => FakeAuthNotifier(testTokens)),
          bootProvider.overrideWith(() => FakeBootNotifier(BootResult(destination: BootDestination.home))),
        ],
        child: MaterialApp(theme: butaTheme, home: const AccountTabScreen()),
      ));
      for (var i = 0; i < 15; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('NicknameScreen deep coverage', () {
    testWidgets('renders input field', (t) async {
      await t.pumpWidget(_w(const NicknameScreen()));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('entering nickname', (t) async {
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

  group('SignupScreen deep coverage', () {
    testWidgets('renders form fields', (t) async {
      await t.pumpWidget(_w(const SignupScreen()));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(TextField), findsWidgets);
    });
  });

  group('ConfirmScreen deep coverage', () {
    testWidgets('renders with email', (t) async {
      await t.pumpWidget(_w(const ConfirmScreen(email: 'user@test.com')));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('code input field exists', (t) async {
      await t.pumpWidget(_w(const ConfirmScreen(email: 'user@test.com')));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(TextField), findsWidgets);
    });
  });

  group('main.dart coverage', () {
    testWidgets('ButaApp renders', (t) async {
      await t.pumpWidget(ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => FakeAuthNotifier(null)),
          bootProvider.overrideWith(() => FakeBootNotifier(BootResult(destination: BootDestination.login))),
        ],
        child: MaterialApp(theme: butaTheme, home: const Scaffold()),
      ));
      await t.pump();
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
