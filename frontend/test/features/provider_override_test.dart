import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:buta_app/shared/theme.dart';
import 'package:buta_app/shared/app_config.dart';
import 'package:buta_app/shared/state/auth_state.dart';
import 'package:buta_app/shared/state/boot_state.dart';
import 'package:buta_app/features/home/home_screen.dart';
import 'package:buta_app/features/battle/battle_tab_screen.dart';
import 'package:buta_app/features/record/record_tab_screen.dart';
import 'package:buta_app/features/account/account_tab_screen.dart';

import '../helpers/test_helpers.dart';

void main() {
  setUpAll(() => AppConfig.init(Flavor.dev));
  setUp(() => SharedPreferences.setMockInitialValues({
    'id_token': 'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ1c2VyLTEyMyJ9.x',
    'access_token': 'test-access',
  }));

  group('HomeScreen with homeDataProvider override', () {
    testWidgets('renders with avatar and records data', (t) async {
      t.view.physicalSize = const Size(390, 740);
      t.view.devicePixelRatio = 1.0;
      addTearDown(() { t.view.resetPhysicalSize(); t.view.resetDevicePixelRatio(); });
      await t.pumpWidget(ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => FakeAuthNotifier(testTokens)),
          bootProvider.overrideWith(() => FakeBootNotifier(BootResult(
            destination: BootDestination.home, profile: testProfile, avatar: testAvatar, summary: testSummary,
          ))),
          homeDataProvider.overrideWith((ref) async => {
            'avatar': {'name': 'テストぶた', 'level': 5, 'totalPoints': 500, 'evolutionStage': 2, 'avatarId': 'a1'},
            'records': [
              {'recordId': 'r1', 'categoryId': 'food_late_ramen', 'points': 50, 'recordedAt': DateTime.now().toIso8601String()},
              {'recordId': 'r2', 'categoryId': 'life_stay_up', 'points': 30, 'recordedAt': DateTime.now().toIso8601String()},
            ],
            'summary': {'todayCount': 2, 'todayPoints': 80},
          }),
        ],
        child: MaterialApp(theme: butaTheme, home: const HomeScreen()),
      ));
      for (var i = 0; i < 20; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('renders with empty records', (t) async {
      t.view.physicalSize = const Size(390, 740);
      t.view.devicePixelRatio = 1.0;
      addTearDown(() { t.view.resetPhysicalSize(); t.view.resetDevicePixelRatio(); });
      await t.pumpWidget(ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => FakeAuthNotifier(testTokens)),
          bootProvider.overrideWith(() => FakeBootNotifier(BootResult(
            destination: BootDestination.home, profile: testProfile, avatar: testAvatar,
          ))),
          homeDataProvider.overrideWith((ref) async => {
            'avatar': {'name': 'こぶた', 'level': 1, 'totalPoints': 0},
            'records': <dynamic>[],
            'summary': {'todayCount': 0, 'todayPoints': 0},
          }),
        ],
        child: MaterialApp(theme: butaTheme, home: const HomeScreen()),
      ));
      for (var i = 0; i < 20; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('renders with high level avatar data', (t) async {
      t.view.physicalSize = const Size(390, 740);
      t.view.devicePixelRatio = 1.0;
      addTearDown(() { t.view.resetPhysicalSize(); t.view.resetDevicePixelRatio(); });
      await t.pumpWidget(ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => FakeAuthNotifier(testTokens)),
          bootProvider.overrideWith(() => FakeBootNotifier(BootResult(
            destination: BootDestination.home, profile: testProfile, avatar: testAvatar, summary: testSummary,
          ))),
          homeDataProvider.overrideWith((ref) async => {
            'avatar': {'name': 'メガトン', 'level': 20, 'totalPoints': 10000, 'evolutionStage': 4, 'avatarId': 'a2'},
            'records': List.generate(5, (i) => {
              'recordId': 'r$i', 'categoryId': 'food_late_ramen', 'points': 50 + i * 10,
              'recordedAt': DateTime.now().subtract(Duration(hours: i)).toIso8601String(),
            }),
            'summary': {'todayCount': 5, 'todayPoints': 300},
          }),
        ],
        child: MaterialApp(theme: butaTheme, home: const HomeScreen()),
      ));
      for (var i = 0; i < 20; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('renders error state', (t) async {
      t.view.physicalSize = const Size(390, 740);
      t.view.devicePixelRatio = 1.0;
      addTearDown(() { t.view.resetPhysicalSize(); t.view.resetDevicePixelRatio(); });
      await t.pumpWidget(ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => FakeAuthNotifier(testTokens)),
          bootProvider.overrideWith(() => FakeBootNotifier(BootResult(
            destination: BootDestination.home, profile: testProfile,
          ))),
          homeDataProvider.overrideWith((ref) => throw Exception('network error')),
        ],
        child: MaterialApp(theme: butaTheme, home: const HomeScreen()),
      ));
      for (var i = 0; i < 20; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(Scaffold), findsOneWidget);
    });

  });

  group('RecordTabScreen with provider override', () {
    testWidgets('renders with weekly records', (t) async {
      final now = DateTime.now();
      await t.pumpWidget(ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => FakeAuthNotifier(testTokens)),
          recordsProvider.overrideWith((ref) async => {
            'records': [
              {'recordId': 'r1', 'categoryId': 'food_late_ramen', 'points': 50, 'recordedAt': now.toIso8601String()},
              {'recordId': 'r2', 'categoryId': 'life_stay_up', 'points': 30, 'recordedAt': now.subtract(const Duration(days: 1)).toIso8601String()},
              {'recordId': 'r3', 'categoryId': 'food_snack', 'points': 20, 'recordedAt': now.subtract(const Duration(days: 3)).toIso8601String()},
              {'recordId': 'r4', 'categoryId': 'life_oversleep', 'points': 25, 'recordedAt': now.subtract(const Duration(days: 5)).toIso8601String()},
              {'recordId': 'r5', 'categoryId': 'food_junkfood', 'points': 35, 'recordedAt': now.subtract(const Duration(days: 10)).toIso8601String()},
              {'recordId': 'r6', 'categoryId': 'life_skip_exercise', 'points': 40, 'recordedAt': now.subtract(const Duration(days: 20)).toIso8601String()},
            ],
            'summary': {'todayPoints': 50},
          }),
        ],
        child: MaterialApp(theme: butaTheme, home: const RecordTabScreen()),
      ));
      for (var i = 0; i < 15; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      // Switch to weekly view
      await t.tap(find.text('しゅう'));
      for (var i = 0; i < 5; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      // Switch to monthly view
      await t.tap(find.text('つき'));
      for (var i = 0; i < 5; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      // Switch back to today
      await t.tap(find.text('きょう'));
      for (var i = 0; i < 5; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('BattleTabScreen with full data', () {
    testWidgets('renders with multiple history entries and rankings', (t) async {
      await t.pumpWidget(ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => FakeAuthNotifier(testTokens)),
          battleHistoryProvider.overrideWith((ref) async => [
            {'result': 'WIN', 'opponentName': 'テスト1', 'pointChange': 15},
            {'result': 'LOSE', 'opponentNickname': 'テスト2', 'pointChange': -10},
            {'result': 'WIN', 'opponentId': 'short', 'pointChange': 20},
            {'result': 'LOSE', 'opponentId': 'very-long-id-that-gets-truncated-12345', 'pointChange': -5},
          ]),
          rankingsProvider.overrideWith((ref) async => {
            'rankings': [
              {'userId': 'u1', 'nickname': 'チャンピオン', 'points': 1000},
              {'userId': 'u2', 'nickname': 'にばん', 'points': 800},
              {'userId': 'u3', 'nickname': 'さんばん', 'points': 600},
              {'userId': 'user-123', 'nickname': 'じぶん', 'points': 400},
              {'userId': 'u5', 'nickname': 'ごばん', 'points': 200},
            ],
            'myId': 'user-123',
          }),
        ],
        child: MaterialApp(theme: butaTheme, home: const BattleTabScreen()),
      ));
      for (var i = 0; i < 15; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('WIN'), findsWidgets);
      expect(find.text('LOSE'), findsWidgets);
      expect(find.text('YOU '), findsOneWidget);
    });
  });

  group('AccountTabScreen with full data', () {
    testWidgets('renders with profile and avatar', (t) async {
      await t.pumpWidget(ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => FakeAuthNotifier(testTokens)),
          bootProvider.overrideWith(() => FakeBootNotifier(BootResult(
            destination: BootDestination.home,
            profile: testProfile,
            avatar: testAvatar,
            summary: testSummary,
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
}
