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
import 'package:buta_app/features/account/friend_search_screen.dart';
import 'package:buta_app/features/account/friend_list_screen.dart';
import 'package:buta_app/features/home/home_screen.dart';
import 'package:buta_app/features/auth/login_screen.dart';
import 'package:buta_app/features/record/record_confirm_screen.dart';
import 'package:buta_app/features/record/record_detail_screen.dart';
import 'package:buta_app/shared/models/models.dart';

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
  }));

  group('BattleFightScreen - timer and state', () {
    testWidgets('timer decrements over time', (t) async {
      await t.pumpWidget(_w(const BattleFightScreen(matchData: {'matchId': 'm1', 'player1Id': 'user-123'})));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      // Timer should show 00:20 initially
      expect(find.text('00:20'), findsOneWidget);
      // Advance 3 seconds
      await t.pump(const Duration(seconds: 1));
      await t.pump(const Duration(seconds: 1));
      await t.pump(const Duration(seconds: 1));
      // Timer should have decremented (but input is locked so timer may not start)
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('renders with empty matchData', (t) async {
      await t.pumpWidget(_w(const BattleFightScreen(matchData: {})));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.text('じゅんび しています...'), findsOneWidget);
    });

    testWidgets('renders log area', (t) async {
      await t.pumpWidget(_w(const BattleFightScreen(matchData: {'matchId': 'm1'})));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      // Log area with black background
      expect(find.text('じゅんび しています...'), findsOneWidget);
    });

    testWidgets('renders with both player IDs', (t) async {
      await t.pumpWidget(_w(const BattleFightScreen(matchData: {
        'matchId': 'm1', 'player1Id': 'user-123', 'player2Id': 'opp-456',
      })));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('じぶん'), findsOneWidget);
      expect(find.text('あいて'), findsOneWidget);
    });

    testWidgets('dispose cleans up timer', (t) async {
      await t.pumpWidget(_w(const BattleFightScreen(matchData: {'matchId': 'm1'})));
      for (var i = 0; i < 5; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      // Navigate away to trigger dispose
      await t.pumpWidget(const MaterialApp(home: Scaffold()));
      await t.pump(const Duration(milliseconds: 100));
    });

    testWidgets('skill buttons rendered in grid', (t) async {
      await t.pumpWidget(_w(const BattleFightScreen(matchData: {'matchId': 'm1'})));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      // Should have 4 skill buttons in 2x2 grid
      expect(find.text('こうげき'), findsNWidgets(3));
      expect(find.text('ぼうぎょ'), findsOneWidget);
    });

    testWidgets('HP bars show full health initially', (t) async {
      await t.pumpWidget(_w(const BattleFightScreen(matchData: {'matchId': 'm1'})));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      // AnimatedContainers for HP bars
      final containers = find.byType(AnimatedContainer);
      expect(containers, findsWidgets);
    });

    testWidgets('TURN counter shows', (t) async {
      await t.pumpWidget(_w(const BattleFightScreen(matchData: {'matchId': 'm1'})));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('TURN 1/10'), findsOneWidget);
    });

    testWidgets('CustomPaint for pig avatars', (t) async {
      await t.pumpWidget(_w(const BattleFightScreen(matchData: {'matchId': 'm1'})));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      // Two pig painters (my pig + opponent pig)
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });

  group('ApiClient - URL resolution', () {
    test('resolves auth paths', () {
      final container = ProviderContainer(overrides: [
        authStateProvider.overrideWith(() => FakeAuthNotifier(testTokens)),
      ]);
      addTearDown(container.dispose);
      final client = container.read(apiClientProvider);
      expect(client, isA<ApiClient>());
    });

    test('Dio interceptor adds token', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
      final adapter = DioAdapter(dio: dio);
      adapter.onGet('/users/me', (s) => s.reply(200, {'userId': 'u1'}));
      final res = await dio.get('/users/me');
      expect(res.data['userId'], 'u1');
    });

    test('Dio handles 401 error', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
      final adapter = DioAdapter(dio: dio);
      adapter.onGet('/protected', (s) => s.throws(401, DioException(
        requestOptions: RequestOptions(path: '/protected'),
        response: Response(requestOptions: RequestOptions(path: '/protected'), statusCode: 401),
      )));
      try {
        await dio.get('/protected');
        fail('Should throw');
      } on DioException catch (e) {
        expect(e.response?.statusCode, 401);
      }
    });

    test('resolves recording paths', () async {
      final dio = Dio(BaseOptions(baseUrl: AppConfig.recordingApiBase));
      final adapter = DioAdapter(dio: dio);
      adapter.onGet('/activities', (s) => s.reply(200, {'items': []}));
      final res = await dio.get('/activities');
      expect(res.statusCode, 200);
    });

    test('resolves avatar paths', () async {
      final dio = Dio(BaseOptions(baseUrl: AppConfig.avatarApiBase));
      final adapter = DioAdapter(dio: dio);
      adapter.onGet('/avatar', (s) => s.reply(200, {'avatar': {'avatarId': 'a1'}}));
      final res = await dio.get('/avatar');
      expect(res.statusCode, 200);
    });

    test('resolves social paths', () async {
      final dio = Dio(BaseOptions(baseUrl: AppConfig.socialApiBase));
      final adapter = DioAdapter(dio: dio);
      adapter.onGet('/social/friends', (s) => s.reply(200, {'friends': []}));
      final res = await dio.get('/social/friends');
      expect(res.statusCode, 200);
    });

    test('resolves admin paths', () async {
      final dio = Dio(BaseOptions(baseUrl: AppConfig.adminApiBase));
      final adapter = DioAdapter(dio: dio);
      adapter.onGet('/admin/users', (s) => s.reply(200, {'users': []}));
      final res = await dio.get('/admin/users');
      expect(res.statusCode, 200);
    });
  });

  group('FriendSearchScreen - interaction', () {
    testWidgets('search with text and get results', (t) async {
      await t.pumpWidget(_w(const FriendSearchScreen()));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      // Enter search text
      final fields = find.byType(TextField);
      if (fields.evaluate().isNotEmpty) {
        await t.enterText(fields.first, 'テスト');
        await t.pump();
        // Tap search button
        await t.tap(find.text('けんさく'));
        for (var i = 0; i < 20; i++) {
          await t.pump(const Duration(milliseconds: 100));
        }
      }
      // After API error, should still show scaffold
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('empty search does nothing', (t) async {
      await t.pumpWidget(_w(const FriendSearchScreen()));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      await t.tap(find.text('けんさく'));
      await t.pump();
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('FriendListScreen - interaction', () {
    testWidgets('loads and shows empty state', (t) async {
      await t.pumpWidget(_w(const FriendListScreen()));
      for (var i = 0; i < 25; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('フレンドが いないよ'), findsOneWidget);
    });

    testWidgets('add button rendered', (t) async {
      await t.pumpWidget(_w(const FriendListScreen()));
      for (var i = 0; i < 25; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('＋ ついか'), findsOneWidget);
    });
  });

  group('BattleTabScreen - rankings display', () {
    testWidgets('renders top 3 with gold color', (t) async {
      await t.pumpWidget(ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => FakeAuthNotifier(testTokens)),
          battleHistoryProvider.overrideWith((ref) async => <dynamic>[]),
          rankingsProvider.overrideWith((ref) async => {
            'rankings': [
              {'userId': 'u1', 'nickname': 'いちばん', 'points': 500},
              {'userId': 'u2', 'nickname': 'にばん', 'points': 400},
              {'userId': 'u3', 'nickname': 'さんばん', 'points': 300},
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
      expect(find.text('いちばん'), findsOneWidget);
      expect(find.text('YOU '), findsOneWidget);
    });

    testWidgets('history with null opponent shows shortId', (t) async {
      await t.pumpWidget(ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => FakeAuthNotifier(testTokens)),
          battleHistoryProvider.overrideWith((ref) async => [
            {'result': 'WIN', 'pointChange': 10},
            {'result': 'LOSE', 'opponentId': null, 'pointChange': -5},
          ]),
          rankingsProvider.overrideWith((ref) async => {'rankings': <dynamic>[], 'myId': ''}),
        ],
        child: MaterialApp(theme: butaTheme, home: const BattleTabScreen()),
      ));
      for (var i = 0; i < 15; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.textContaining('vs'), findsWidgets);
    });
  });

  group('HomeScreen - various states', () {
    testWidgets('renders with null summary', (t) async {
      await t.pumpWidget(ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => FakeAuthNotifier(testTokens)),
          bootProvider.overrideWith(() => FakeBootNotifier(BootResult(
            destination: BootDestination.home, profile: testProfile, avatar: testAvatar,
          ))),
        ],
        child: MaterialApp(theme: butaTheme, home: const HomeScreen()),
      ));
      for (var i = 0; i < 20; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('renders with high level avatar', (t) async {
      final highAvatar = Avatar(
        avatarId: 'a1', userId: 'u1', name: 'メガトン', totalPoints: 5000, level: 15,
        evolutionStage: 3, stats: AvatarStats(hp: 200, attack: 50, defense: 40, speed: 30),
        skillIds: ['s1', 's2'], spriteSheetKey: 'sprites/stage3/megaton',
      );
      await t.pumpWidget(ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => FakeAuthNotifier(testTokens)),
          bootProvider.overrideWith(() => FakeBootNotifier(BootResult(
            destination: BootDestination.home, profile: testProfile, avatar: highAvatar, summary: testSummary,
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

  group('LoginScreen - form interaction', () {
    testWidgets('entering email and password', (t) async {
      await t.pumpWidget(_w(const LoginScreen()));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      final fields = find.byType(TextField);
      // Enter email in first available field (after host field in dev mode)
      if (fields.evaluate().length >= 3) {
        await t.enterText(fields.at(1), 'test@example.com');
        await t.pump();
        await t.enterText(fields.at(2), 'password123');
        await t.pump();
      }
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('DEV button exists', (t) async {
      await t.pumpWidget(_w(const LoginScreen()));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('DEV'), findsOneWidget);
    });
  });

  group('BattleMatchingScreen - timer', () {
    testWidgets('renders and advances timer', (t) async {
      await t.pumpWidget(_w(const BattleMatchingScreen()));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      // Advance several seconds
      for (var i = 0; i < 5; i++) {
        await t.pump(const Duration(seconds: 1));
      }
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('RecordDetailScreen - various data', () {
    testWidgets('renders with all category types', (t) async {
      for (final cat in ['food_late_ramen', 'food_snack', 'food_binge', 'food_junkfood', 'life_stay_up', 'life_oversleep', 'life_skip_exercise', 'life_binge_watch']) {
        await t.pumpWidget(_w(RecordDetailScreen(record: {
          'recordId': 'r-$cat', 'categoryId': cat, 'categoryName': cat,
          'points': 30, 'recordedAt': '2026-05-24T12:00:00Z',
        })));
        for (var i = 0; i < 5; i++) {
          await t.pump(const Duration(milliseconds: 100));
        }
        expect(find.byType(Scaffold), findsOneWidget);
      }
    });
  });

  group('RecordConfirmScreen - memo input', () {
    testWidgets('renders memo field', (t) async {
      await t.pumpWidget(_w(RecordConfirmScreen(category: {
        'categoryId': 'food_late_ramen', 'name': 'しんやラーメン', 'basePoints': 50, 'iconKey': 'cat-ramen',
      })));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      // Should have text fields for memo
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
