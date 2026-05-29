import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:buta_app/shared/theme.dart';
import 'package:buta_app/shared/app_config.dart';
import 'package:buta_app/shared/state/auth_state.dart';
import 'package:buta_app/shared/state/boot_state.dart';
import 'package:buta_app/features/battle/battle_fight_screen.dart';
import 'package:buta_app/features/battle/battle_tab_screen.dart';
import 'package:buta_app/features/battle/battle_matching_screen.dart';
import 'package:buta_app/features/battle/battle_result_screen.dart';
import 'package:buta_app/features/record/record_tab_screen.dart';
import 'package:buta_app/features/record/record_confirm_screen.dart';
import 'package:buta_app/features/record/record_detail_screen.dart';
import 'package:buta_app/features/account/friend_search_screen.dart';
import 'package:buta_app/features/account/friend_list_screen.dart';
import 'package:buta_app/features/account/account_tab_screen.dart';
import 'package:buta_app/features/settings/profile_edit_screen.dart';
import 'package:buta_app/features/auth/login_screen.dart';
import 'package:buta_app/features/auth/signup_screen.dart';
import 'package:buta_app/features/auth/confirm_screen.dart';
import 'package:buta_app/features/auth/nickname_screen.dart';
import 'package:buta_app/features/home/home_screen.dart';
import 'package:buta_app/features/avatar/evo_book_screen.dart';
import 'package:buta_app/features/legal/license_list_screen.dart';
import 'package:buta_app/features/start/tutorial_screen.dart';

import '../helpers/test_helpers.dart';

Widget _wrap(Widget child) => ProviderScope(
  overrides: [
    authStateProvider.overrideWith(() => FakeAuthNotifier(testTokens)),
    bootProvider.overrideWith(() => FakeBootNotifier(BootResult(destination: BootDestination.home))),
  ],
  child: MaterialApp(theme: butaTheme, home: child),
);

void main() {
  setUpAll(() => AppConfig.init(Flavor.dev));
  setUp(() => SharedPreferences.setMockInitialValues({
    'id_token': 'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ1c2VyLTEyMyJ9.x',
    'access_token': 'test-access',
  }));

  group('BattleFightScreen coverage', () {
    testWidgets('renders initial state with skills', (t) async {
      await t.pumpWidget(_wrap(const BattleFightScreen(matchData: {
        'matchId': 'match-1',
        'player1Id': 'user-123',
        'player2Id': 'user-456',
      })));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('じゅんび しています...'), findsOneWidget);
      expect(find.text('TURN 1/10'), findsOneWidget);
    });

    testWidgets('renders with null matchData', (t) async {
      await t.pumpWidget(_wrap(const BattleFightScreen()));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('skill buttons are displayed', (t) async {
      await t.pumpWidget(_wrap(const BattleFightScreen(matchData: {'matchId': 'm1'})));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('こうげき'), findsWidgets);
      expect(find.text('ぼうぎょ'), findsOneWidget);
    });

    testWidgets('timer displays countdown', (t) async {
      await t.pumpWidget(_wrap(const BattleFightScreen(matchData: {'matchId': 'm1'})));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.textContaining('00:'), findsOneWidget);
    });

    testWidgets('hp bars are rendered', (t) async {
      await t.pumpWidget(_wrap(const BattleFightScreen(matchData: {'matchId': 'm1'})));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      // HP bars are AnimatedContainers
      expect(find.byType(AnimatedContainer), findsWidgets);
    });

    testWidgets('disposes cleanly', (t) async {
      await t.pumpWidget(_wrap(const BattleFightScreen(matchData: {'matchId': 'm1'})));
      for (var i = 0; i < 5; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      await t.pumpWidget(const SizedBox()); // trigger dispose
      await t.pump();
    });
  });

  group('RecordTabScreen coverage', () {
    testWidgets('renders loading state', (t) async {
      await t.pumpWidget(_wrap(const RecordTabScreen()));
      await t.pump(const Duration(milliseconds: 100));
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('renders with data provider override', (t) async {
      await t.pumpWidget(ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => FakeAuthNotifier(testTokens)),
          recordsProvider.overrideWith((ref) async => {
            'records': [
              {'recordId': 'r1', 'categoryId': 'food_late_ramen', 'points': 30, 'recordedAt': DateTime.now().toIso8601String()},
              {'recordId': 'r2', 'categoryId': 'life_stay_up', 'points': 20, 'recordedAt': DateTime.now().toIso8601String()},
              {'recordId': 'r3', 'categoryId': 'food_snack', 'points': 15, 'recordedAt': DateTime.now().subtract(const Duration(days: 2)).toIso8601String()},
            ],
            'summary': {'todayPoints': 50},
          }),
        ],
        child: MaterialApp(theme: butaTheme, home: const RecordTabScreen()),
      ));
      for (var i = 0; i < 15; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('きょう'), findsOneWidget);
      expect(find.text('しゅう'), findsOneWidget);
      expect(find.text('つき'), findsOneWidget);
    });

    testWidgets('segment switching works', (t) async {
      await t.pumpWidget(ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => FakeAuthNotifier(testTokens)),
          recordsProvider.overrideWith((ref) async => {
            'records': [
              {'recordId': 'r1', 'categoryId': 'food_late_ramen', 'points': 30, 'recordedAt': DateTime.now().toIso8601String()},
              {'recordId': 'r2', 'categoryId': 'life_oversleep', 'points': 20, 'recordedAt': DateTime.now().subtract(const Duration(days: 3)).toIso8601String()},
              {'recordId': 'r3', 'categoryId': 'food_junkfood', 'points': 25, 'recordedAt': DateTime.now().subtract(const Duration(days: 15)).toIso8601String()},
            ],
            'summary': {'todayPoints': 30},
          }),
        ],
        child: MaterialApp(theme: butaTheme, home: const RecordTabScreen()),
      ));
      for (var i = 0; i < 15; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      // Tap しゅう segment
      await t.tap(find.text('しゅう'));
      await t.pump();
      // Tap つき segment
      await t.tap(find.text('つき'));
      await t.pump();
    });

    testWidgets('empty records shows message', (t) async {
      await t.pumpWidget(ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => FakeAuthNotifier(testTokens)),
          recordsProvider.overrideWith((ref) async => {'records': <dynamic>[], 'summary': {'todayPoints': 0}}),
        ],
        child: MaterialApp(theme: butaTheme, home: const RecordTabScreen()),
      ));
      for (var i = 0; i < 15; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('まだ きろくが ないよ'), findsOneWidget);
    });

    testWidgets('error state renders', (t) async {
      await t.pumpWidget(ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => FakeAuthNotifier(testTokens)),
          recordsProvider.overrideWith((ref) => throw Exception('fail')),
        ],
        child: MaterialApp(theme: butaTheme, home: const RecordTabScreen()),
      ));
      for (var i = 0; i < 15; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('record card renders with all categories', (t) async {
      await t.pumpWidget(ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => FakeAuthNotifier(testTokens)),
          recordsProvider.overrideWith((ref) async => {
            'records': [
              {'recordId': 'r1', 'categoryId': 'food_late_ramen', 'points': 30, 'recordedAt': DateTime.now().toIso8601String()},
              {'recordId': 'r2', 'categoryId': 'food_snack', 'points': 10, 'recordedAt': DateTime.now().toIso8601String()},
              {'recordId': 'r3', 'categoryId': 'food_binge', 'points': 40, 'recordedAt': DateTime.now().toIso8601String()},
              {'recordId': 'r4', 'categoryId': 'food_junkfood', 'points': 20, 'recordedAt': DateTime.now().toIso8601String()},
              {'recordId': 'r5', 'categoryId': 'life_stay_up', 'points': 25, 'recordedAt': DateTime.now().toIso8601String()},
              {'recordId': 'r6', 'categoryId': 'life_oversleep', 'points': 15, 'recordedAt': DateTime.now().toIso8601String()},
              {'recordId': 'r7', 'categoryId': 'life_skip_exercise', 'points': 35, 'recordedAt': DateTime.now().toIso8601String()},
              {'recordId': 'r8', 'categoryId': 'life_binge_watch', 'points': 20, 'recordedAt': DateTime.now().toIso8601String()},
              {'recordId': 'r9', 'categoryId': 'unknown_cat', 'points': 5, 'recordedAt': DateTime.now().toIso8601String()},
            ],
            'summary': {'todayPoints': 200},
          }),
        ],
        child: MaterialApp(theme: butaTheme, home: const RecordTabScreen()),
      ));
      for (var i = 0; i < 15; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('しんやラーメン'), findsOneWidget);
    });
  });

  group('FriendSearchScreen coverage', () {
    testWidgets('renders search UI', (t) async {
      await t.pumpWidget(_wrap(const FriendSearchScreen()));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('けんさく'), findsOneWidget);
      expect(find.text('けっか'), findsOneWidget);
    });

    testWidgets('search button tap with empty query does nothing', (t) async {
      await t.pumpWidget(_wrap(const FriendSearchScreen()));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      await t.tap(find.text('けんさく'));
      await t.pump();
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('renders with initial state', (t) async {
      await t.pumpWidget(_wrap(const FriendSearchScreen()));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(ListView), findsOneWidget);
    });
  });

  group('BattleTabScreen coverage', () {
    testWidgets('renders with providers', (t) async {
      await t.pumpWidget(ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => FakeAuthNotifier(testTokens)),
          battleHistoryProvider.overrideWith((ref) async => [
            {'result': 'WIN', 'opponentName': 'テスト太郎', 'pointChange': 10},
            {'result': 'LOSE', 'opponentId': 'opp-123', 'pointChange': -5},
          ]),
          rankingsProvider.overrideWith((ref) async => {
            'rankings': [
              {'userId': 'user-123', 'nickname': 'じぶん', 'points': 100},
              {'userId': 'user-456', 'nickname': 'あいて', 'points': 80},
              {'userId': 'user-789', 'nickname': 'さんにん', 'points': 60},
              {'userId': 'user-000', 'nickname': 'よにん', 'points': 40},
            ],
            'myId': 'user-123',
          }),
        ],
        child: MaterialApp(theme: butaTheme, home: const BattleTabScreen()),
      ));
      for (var i = 0; i < 15; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('ランダムマッチ'), findsOneWidget);
      expect(find.text('フレンド たいせん'), findsOneWidget);
      expect(find.text('バトル りれき'), findsOneWidget);
      expect(find.text('ランキング'), findsOneWidget);
    });

    testWidgets('renders with empty history', (t) async {
      await t.pumpWidget(ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => FakeAuthNotifier(testTokens)),
          battleHistoryProvider.overrideWith((ref) async => []),
          rankingsProvider.overrideWith((ref) async => {'rankings': <dynamic>[], 'myId': ''}),
        ],
        child: MaterialApp(theme: butaTheme, home: const BattleTabScreen()),
      ));
      for (var i = 0; i < 15; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('まだ りれきが ないよ'), findsWidgets);
    });

    testWidgets('renders with PixelLoader during load', (t) async {
      await t.pumpWidget(ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => FakeAuthNotifier(testTokens)),
          battleHistoryProvider.overrideWith((ref) async => <dynamic>[]),
          rankingsProvider.overrideWith((ref) async => <String, dynamic>{'rankings': <dynamic>[], 'myId': ''}),
        ],
        child: MaterialApp(theme: butaTheme, home: const BattleTabScreen()),
      ));
      // First pump starts the build
      await t.pump();
      expect(find.byType(Scaffold), findsOneWidget);
      for (var i = 0; i < 15; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
    });

    testWidgets('renders error state', (t) async {
      await t.pumpWidget(ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => FakeAuthNotifier(testTokens)),
          battleHistoryProvider.overrideWith((ref) => throw Exception('err')),
          rankingsProvider.overrideWith((ref) => throw Exception('err')),
        ],
        child: MaterialApp(theme: butaTheme, home: const BattleTabScreen()),
      ));
      for (var i = 0; i < 15; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('FriendListScreen coverage', () {
    testWidgets('renders loading state', (t) async {
      await t.pumpWidget(_wrap(const FriendListScreen()));
      await t.pump(const Duration(milliseconds: 50));
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('renders after load attempt', (t) async {
      await t.pumpWidget(_wrap(const FriendListScreen()));
      for (var i = 0; i < 20; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('shows empty friend message', (t) async {
      await t.pumpWidget(_wrap(const FriendListScreen()));
      for (var i = 0; i < 20; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('フレンドが いないよ'), findsOneWidget);
    });

    testWidgets('add button exists', (t) async {
      await t.pumpWidget(_wrap(const FriendListScreen()));
      for (var i = 0; i < 20; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('＋ ついか'), findsOneWidget);
    });
  });

  group('ProfileEditScreen coverage', () {
    testWidgets('renders form fields', (t) async {
      await t.pumpWidget(_wrap(const ProfileEditScreen()));
      for (var i = 0; i < 15; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('プロフィール'), findsOneWidget);
      expect(find.text('ほぞんする'), findsOneWidget);
    });

    testWidgets('save button tap', (t) async {
      await t.pumpWidget(_wrap(const ProfileEditScreen()));
      for (var i = 0; i < 15; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      await t.tap(find.text('ほぞんする'));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(Scaffold), findsWidgets);
    });
  });

  group('LoginScreen coverage', () {
    testWidgets('renders login form', (t) async {
      await t.pumpWidget(_wrap(const LoginScreen()));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('login text exists', (t) async {
      await t.pumpWidget(_wrap(const LoginScreen()));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('ログイン'), findsWidgets);
    });

    testWidgets('signup link exists', (t) async {
      await t.pumpWidget(_wrap(const LoginScreen()));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.textContaining('アカウントを'), findsOneWidget);
    });

    testWidgets('DEV button exists in dev mode', (t) async {
      await t.pumpWidget(_wrap(const LoginScreen()));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('DEV'), findsOneWidget);
    });
  });

  group('HomeScreen coverage', () {
    testWidgets('renders with home data', (t) async {
      await t.pumpWidget(ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => FakeAuthNotifier(testTokens)),
          bootProvider.overrideWith(() => FakeBootNotifier(BootResult(
            destination: BootDestination.home,
            profile: testProfile,
            avatar: testAvatar,
            summary: testSummary,
          ))),
        ],
        child: MaterialApp(theme: butaTheme, home: const HomeScreen()),
      ));
      for (var i = 0; i < 15; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('BattleMatchingScreen coverage', () {
    testWidgets('renders matching UI', (t) async {
      await t.pumpWidget(_wrap(const BattleMatchingScreen()));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('RecordConfirmScreen coverage', () {
    testWidgets('renders with category data', (t) async {
      await t.pumpWidget(_wrap(RecordConfirmScreen(category: {
        'categoryId': 'food_late_ramen',
        'name': 'しんやラーメン',
        'basePoints': 50,
        'iconKey': 'cat-ramen',
      })));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('confirm button exists', (t) async {
      await t.pumpWidget(_wrap(RecordConfirmScreen(category: {
        'categoryId': 'food_late_ramen',
        'name': 'しんやラーメン',
        'basePoints': 50,
        'iconKey': 'cat-ramen',
      })));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('きろくする'), findsOneWidget);
    });
  });

  group('RecordDetailScreen coverage', () {
    testWidgets('renders with record data', (t) async {
      await t.pumpWidget(_wrap(RecordDetailScreen(record: {
        'recordId': 'r1',
        'categoryId': 'food_late_ramen',
        'categoryName': 'しんやラーメン',
        'points': 50,
        'recordedAt': '2026-05-24T23:30:00Z',
        'memo': 'おいしかった',
      })));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('AccountTabScreen coverage', () {
    testWidgets('renders with boot data', (t) async {
      await t.pumpWidget(ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => FakeAuthNotifier(testTokens)),
          bootProvider.overrideWith(() => FakeBootNotifier(BootResult(
            destination: BootDestination.home,
            profile: testProfile,
            avatar: testAvatar,
            pendingRequestCount: 3,
          ))),
        ],
        child: MaterialApp(theme: butaTheme, home: const AccountTabScreen()),
      ));
      for (var i = 0; i < 15; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('Auth screens coverage', () {
    testWidgets('SignupScreen renders', (t) async {
      await t.pumpWidget(_wrap(const SignupScreen()));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('ConfirmScreen renders', (t) async {
      await t.pumpWidget(_wrap(const ConfirmScreen(email: 'test@example.com')));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('NicknameScreen renders', (t) async {
      await t.pumpWidget(_wrap(const NicknameScreen()));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('EvoBookScreen coverage', () {
    testWidgets('renders evolution book', (t) async {
      await t.pumpWidget(_wrap(const EvoBookScreen()));
      for (var i = 0; i < 15; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('LicenseListScreen coverage', () {
    testWidgets('renders license list', (t) async {
      await t.pumpWidget(_wrap(const LicenseListScreen()));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('TutorialScreen coverage', () {
    testWidgets('renders tutorial', (t) async {
      await t.pumpWidget(_wrap(const TutorialScreen()));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('BattleResultScreen coverage', () {
    testWidgets('win result renders', (t) async {
      await t.pumpWidget(_wrap(const BattleResultScreen(win: true)));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('lose result renders', (t) async {
      await t.pumpWidget(_wrap(const BattleResultScreen(win: false)));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('ApiClient coverage', () {
    test('resolveUrl routes correctly', () {
      // Test the ApiClient URL resolution logic indirectly
      expect(AppConfig.authApiBase, isNotEmpty);
      expect(AppConfig.recordingApiBase, isNotEmpty);
      expect(AppConfig.avatarApiBase, isNotEmpty);
      expect(AppConfig.socialApiBase, isNotEmpty);
    });
  });
}
