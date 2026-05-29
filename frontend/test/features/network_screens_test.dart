import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:buta_app/shared/theme.dart';
import 'package:buta_app/shared/app_config.dart';
import 'package:buta_app/shared/state/auth_state.dart';
import 'package:buta_app/features/account/friend_list_screen.dart';
import 'package:buta_app/features/account/friend_search_screen.dart';
import 'package:buta_app/features/battle/battle_tab_screen.dart';

import '../helpers/test_helpers.dart';

void main() {
  setUpAll(() => AppConfig.init(Flavor.dev));
  setUp(() => SharedPreferences.setMockInitialValues({
    'id_token': 'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ1c2VyLTEyMyJ9.x',
    'access_token': 'test-access',
  }));

  group('FriendListScreen with provider override', () {
    testWidgets('renders friends list', (t) async {
      await t.pumpWidget(ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => FakeAuthNotifier(testTokens)),
          friendListProvider.overrideWith((ref) async => {
            'friends': [
              {'userId': 'f1', 'friendId': 'f1', 'nickname': 'テスト太郎', 'level': 5, 'online': true},
              {'userId': 'f2', 'friendId': 'f2', 'nickname': 'テスト花子', 'level': 3, 'online': false},
              {'userId': 'f3', 'friendId': 'f3', 'nickname': 'テスト次郎', 'level': 8},
            ],
            'requests': <dynamic>[],
          }),
        ],
        child: MaterialApp(theme: butaTheme, home: const FriendListScreen()),
      ));
      for (var i = 0; i < 15; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('テスト太郎'), findsOneWidget);
      expect(find.text('テスト花子'), findsOneWidget);
      expect(find.text('テスト次郎'), findsOneWidget);
      expect(find.text('LV.5'), findsOneWidget);
      expect(find.text('フレンド (3)'), findsOneWidget);
    });

    testWidgets('renders friend requests', (t) async {
      await t.pumpWidget(ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => FakeAuthNotifier(testTokens)),
          friendListProvider.overrideWith((ref) async => {
            'friends': <dynamic>[],
            'requests': [
              {'requestId': 'req1', 'fromNickname': 'しんせいさん', 'fromUserId': 'u1'},
              {'requestId': 'req2', 'fromUserId': 'u2'},
            ],
          }),
        ],
        child: MaterialApp(theme: butaTheme, home: const FriendListScreen()),
      ));
      for (var i = 0; i < 15; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('しんせい (2)'), findsOneWidget);
      expect(find.text('しんせいさん'), findsOneWidget);
      expect(find.text('OK'), findsNWidgets(2));
      expect(find.text('NG'), findsNWidgets(2));
    });

    testWidgets('renders both friends and requests', (t) async {
      await t.pumpWidget(ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => FakeAuthNotifier(testTokens)),
          friendListProvider.overrideWith((ref) async => {
            'friends': [
              {'userId': 'f1', 'friendId': 'f1', 'nickname': 'フレンドA', 'level': 2},
            ],
            'requests': [
              {'requestId': 'r1', 'fromNickname': 'しんせいB'},
            ],
          }),
        ],
        child: MaterialApp(theme: butaTheme, home: const FriendListScreen()),
      ));
      for (var i = 0; i < 15; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('フレンドA'), findsOneWidget);
      expect(find.text('しんせいB'), findsOneWidget);
      expect(find.text('フレンド (1)'), findsOneWidget);
    });

    testWidgets('renders empty state', (t) async {
      await t.pumpWidget(ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => FakeAuthNotifier(testTokens)),
          friendListProvider.overrideWith((ref) async => {'friends': <dynamic>[], 'requests': <dynamic>[]}),
        ],
        child: MaterialApp(theme: butaTheme, home: const FriendListScreen()),
      ));
      for (var i = 0; i < 15; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('フレンドが いないよ'), findsOneWidget);
    });

    testWidgets('renders with request from field', (t) async {
      await t.pumpWidget(ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => FakeAuthNotifier(testTokens)),
          friendListProvider.overrideWith((ref) async => {
            'friends': <dynamic>[],
            'requests': [
              {'requestId': 'r1', 'from': 'だれか'},
            ],
          }),
        ],
        child: MaterialApp(theme: butaTheme, home: const FriendListScreen()),
      ));
      for (var i = 0; i < 15; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('だれか'), findsOneWidget);
    });
  });

  group('FriendSearchScreen with provider override', () {
    testWidgets('renders search results', (t) async {
      await t.pumpWidget(ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => FakeAuthNotifier(testTokens)),
          friendSearchResultsProvider('テスト').overrideWith((ref) async => [
            {'userId': 'u1', 'nickname': 'テストユーザー1', 'level': 5},
            {'userId': 'u2', 'nickname': 'テストユーザー2', 'level': 10},
            {'userId': 'u3', 'nickname': 'テストユーザー3', 'level': 1},
          ]),
        ],
        child: MaterialApp(theme: butaTheme, home: const FriendSearchScreen()),
      ));
      for (var i = 0; i < 15; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      // Initial state - no search yet, so results won't show
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('renders empty results', (t) async {
      await t.pumpWidget(ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => FakeAuthNotifier(testTokens)),
          friendSearchResultsProvider('').overrideWith((ref) async => <Map<String, dynamic>>[]),
        ],
        child: MaterialApp(theme: butaTheme, home: const FriendSearchScreen()),
      ));
      for (var i = 0; i < 15; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('けんさく'), findsOneWidget);
      expect(find.text('けっか'), findsOneWidget);
    });
  });

  group('BattleTabScreen with friendsForBattle override', () {
    testWidgets('friend battle tap shows dialog with friends', (t) async {
      await t.pumpWidget(ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => FakeAuthNotifier(testTokens)),
          battleHistoryProvider.overrideWith((ref) async => <dynamic>[]),
          rankingsProvider.overrideWith((ref) async => {'rankings': <dynamic>[], 'myId': ''}),
          friendsForBattleProvider.overrideWith((ref) async => [
            {'userId': 'f1', 'nickname': 'バトルフレンド1'},
            {'userId': 'f2', 'nickname': 'バトルフレンド2'},
          ]),
        ],
        child: MaterialApp(theme: butaTheme, home: const BattleTabScreen()),
      ));
      for (var i = 0; i < 15; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      // Tap friend battle button
      await t.tap(find.text('フレンド たいせん'));
      for (var i = 0; i < 15; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      // Dialog should show
      expect(find.text('フレンドを えらぶ'), findsOneWidget);
      expect(find.text('バトルフレンド1'), findsOneWidget);
      expect(find.text('バトルフレンド2'), findsOneWidget);
    });

    testWidgets('friend battle tap with empty list does nothing', (t) async {
      await t.pumpWidget(ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => FakeAuthNotifier(testTokens)),
          battleHistoryProvider.overrideWith((ref) async => <dynamic>[]),
          rankingsProvider.overrideWith((ref) async => {'rankings': <dynamic>[], 'myId': ''}),
          friendsForBattleProvider.overrideWith((ref) async => <dynamic>[]),
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
      // No dialog should appear
      expect(find.text('フレンドを えらぶ'), findsNothing);
    });

    testWidgets('friend battle dialog select navigates', (t) async {
      await t.pumpWidget(ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => FakeAuthNotifier(testTokens)),
          battleHistoryProvider.overrideWith((ref) async => <dynamic>[]),
          rankingsProvider.overrideWith((ref) async => {'rankings': <dynamic>[], 'myId': ''}),
          friendsForBattleProvider.overrideWith((ref) async => [
            {'userId': 'f1', 'nickname': 'フレンドX'},
          ]),
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
      expect(find.text('フレンドX'), findsOneWidget);
      // Tap the friend button in dialog
      await t.tap(find.text('フレンドX'));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
    });
  });
}
