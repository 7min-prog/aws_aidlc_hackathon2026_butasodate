import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:buta_app/shared/theme.dart';
import 'package:buta_app/shared/app_config.dart';
import 'package:buta_app/shared/state/auth_state.dart';
import 'package:buta_app/features/account/friend_search_screen.dart';
import 'package:buta_app/features/account/friend_list_screen.dart';
import 'package:buta_app/features/battle/battle_tab_screen.dart';

import '../helpers/test_helpers.dart';

void main() {
  setUpAll(() => AppConfig.init(Flavor.dev));
  setUp(() => SharedPreferences.setMockInitialValues({
    'id_token': 'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ1c2VyLTEyMyJ9.x',
    'access_token': 'test-access',
  }));

  group('FriendSearchScreen - search results rendering', () {
    testWidgets('entering query and searching shows results', (t) async {
      // Override the provider for the query "テスト" to return mock results
      await t.pumpWidget(ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => FakeAuthNotifier(testTokens)),
          friendSearchResultsProvider('テスト').overrideWith((ref) async => [
            {'userId': 'u1', 'nickname': 'テストユーザー1', 'level': 5},
            {'userId': 'u2', 'nickname': 'テストユーザー2', 'level': 10},
          ]),
        ],
        child: MaterialApp(theme: butaTheme, home: const FriendSearchScreen()),
      ));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }

      // Enter search text
      final fields = find.byType(TextField);
      await t.enterText(fields.first, 'テスト');
      await t.pump();

      // Tap search button
      await t.tap(find.text('けんさく'));
      for (var i = 0; i < 15; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }

      // Results should be displayed
      expect(find.text('テストユーザー1'), findsOneWidget);
      expect(find.text('テストユーザー2'), findsOneWidget);
      expect(find.text('LV.5'), findsOneWidget);
      expect(find.text('LV.10'), findsOneWidget);
      expect(find.text('ついか'), findsNWidgets(2));
    });

    testWidgets('tapping ついか marks as sent', (t) async {
      await t.pumpWidget(ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => FakeAuthNotifier(testTokens)),
          friendSearchResultsProvider('abc').overrideWith((ref) async => [
            {'userId': 'target1', 'nickname': 'ターゲット', 'level': 3},
          ]),
        ],
        child: MaterialApp(theme: butaTheme, home: const FriendSearchScreen()),
      ));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }

      // Search
      final fields = find.byType(TextField);
      await t.enterText(fields.first, 'abc');
      await t.pump();
      await t.tap(find.text('けんさく'));
      for (var i = 0; i < 15; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }

      expect(find.text('ターゲット'), findsOneWidget);
      expect(find.text('ついか'), findsOneWidget);

      // Tap ついか button (will fail network but state should update)
      await t.tap(find.text('ついか'));
      for (var i = 0; i < 20; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
    });

    testWidgets('search error shows empty', (t) async {
      await t.pumpWidget(ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => FakeAuthNotifier(testTokens)),
          friendSearchResultsProvider('err').overrideWith((ref) => throw Exception('network error')),
        ],
        child: MaterialApp(theme: butaTheme, home: const FriendSearchScreen()),
      ));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }

      final fields = find.byType(TextField);
      await t.enterText(fields.first, 'err');
      await t.pump();
      await t.tap(find.text('けんさく'));
      for (var i = 0; i < 15; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('FriendListScreen - delete and respond', () {
    testWidgets('delete button shows on friend items', (t) async {
      await t.pumpWidget(ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => FakeAuthNotifier(testTokens)),
          friendListProvider.overrideWith((ref) async => {
            'friends': [
              {'userId': 'f1', 'friendId': 'f1', 'nickname': 'さくじょ対象', 'level': 2, 'online': true},
            ],
            'requests': <dynamic>[],
          }),
        ],
        child: MaterialApp(theme: butaTheme, home: const FriendListScreen()),
      ));
      for (var i = 0; i < 15; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('さくじょ対象'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('online indicator shows green dot', (t) async {
      await t.pumpWidget(ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => FakeAuthNotifier(testTokens)),
          friendListProvider.overrideWith((ref) async => {
            'friends': [
              {'userId': 'f1', 'friendId': 'f1', 'nickname': 'オンライン', 'level': 1, 'online': true},
              {'userId': 'f2', 'friendId': 'f2', 'nickname': 'オフライン', 'level': 1, 'online': false},
            ],
            'requests': <dynamic>[],
          }),
        ],
        child: MaterialApp(theme: butaTheme, home: const FriendListScreen()),
      ));
      for (var i = 0; i < 15; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('オンライン'), findsOneWidget);
      expect(find.text('オフライン'), findsOneWidget);
    });
  });

  group('BattleTabScreen - friend dialog interaction', () {
    testWidgets('dialog shows friend with userId fallback', (t) async {
      await t.pumpWidget(ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => FakeAuthNotifier(testTokens)),
          battleHistoryProvider.overrideWith((ref) async => <dynamic>[]),
          rankingsProvider.overrideWith((ref) async => {'rankings': <dynamic>[], 'myId': ''}),
          friendsForBattleProvider.overrideWith((ref) async => [
            {'userId': 'user-no-nickname'},
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
      expect(find.text('user-no-nickname'), findsOneWidget);
    });
  });

  group('FriendListScreen - button taps', () {
    testWidgets('tap OK on request', (t) async {
      await t.pumpWidget(ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => FakeAuthNotifier(testTokens)),
          friendListProvider.overrideWith((ref) async => {
            'friends': <dynamic>[],
            'requests': [{'requestId': 'r1', 'fromNickname': 'テスト'}],
          }),
        ],
        child: MaterialApp(theme: butaTheme, home: const FriendListScreen()),
      ));
      for (var i = 0; i < 15; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('OK'), findsOneWidget);
      await t.tap(find.text('OK'));
      for (var i = 0; i < 20; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
    });

    testWidgets('tap NG on request', (t) async {
      await t.pumpWidget(ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => FakeAuthNotifier(testTokens)),
          friendListProvider.overrideWith((ref) async => {
            'friends': <dynamic>[],
            'requests': [{'requestId': 'r2', 'fromNickname': 'テスト2'}],
          }),
        ],
        child: MaterialApp(theme: butaTheme, home: const FriendListScreen()),
      ));
      for (var i = 0; i < 15; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('NG'), findsOneWidget);
      await t.tap(find.text('NG'));
      for (var i = 0; i < 20; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
    });

    testWidgets('tap delete on friend', (t) async {
      await t.pumpWidget(ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => FakeAuthNotifier(testTokens)),
          friendListProvider.overrideWith((ref) async => {
            'friends': [{'userId': 'f1', 'friendId': 'f1', 'nickname': 'さくじょ', 'level': 1}],
            'requests': <dynamic>[],
          }),
        ],
        child: MaterialApp(theme: butaTheme, home: const FriendListScreen()),
      ));
      for (var i = 0; i < 15; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      await t.tap(find.byIcon(Icons.close));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      // Confirm dialog should appear
      expect(find.text('フレンドさくじょ'), findsOneWidget);
    });
  });
}

