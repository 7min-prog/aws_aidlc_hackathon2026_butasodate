import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:buta_app/features/record/record_tab_screen.dart';
import 'package:buta_app/features/battle/battle_tab_screen.dart';
import 'package:buta_app/features/home/home_screen.dart';
import 'package:buta_app/shared/services/api_client.dart';
import 'package:buta_app/shared/state/auth_state.dart';
import 'package:buta_app/shared/repositories/avatar_repository.dart';
import 'package:buta_app/shared/repositories/recording_repository.dart';
import 'package:buta_app/shared/theme.dart';

import '../helpers/test_helpers.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({'access_token': 'a', 'refresh_token': 'r'}));

  group('RecordTabScreen', () {
    testWidgets('renders with records data', (tester) async {
      final dio = Dio(BaseOptions(baseUrl: 'http://mock'));
      final adapter = DioAdapter(dio: dio);
      final now = DateTime.now().toIso8601String();
      adapter.onGet('/activities', (s) => s.reply(200, {
        'records': [
          {'recordId': 'r1', 'categoryId': 'food-ramen', 'points': 50, 'recordedAt': now, 'source': 'MANUAL'},
          {'recordId': 'r2', 'categoryId': 'life-oversleep', 'points': 30, 'recordedAt': now, 'source': 'MANUAL'},
        ],
        'summary': {'todayPoints': 80, 'todayCount': 2},
      }));

      await tester.pumpWidget(ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => FakeAuthNotifier(testTokens)),
          apiClientProvider.overrideWithValue(FakeApiClient(dio)),
        ],
        child: const MaterialApp(home: RecordTabScreen()),
      ));
      for (var i = 0; i < 20; i++) { await tester.pump(const Duration(milliseconds: 100)); }

      expect(find.text('きろく'), findsWidgets);
      expect(find.text('深夜ラーメン'), findsOneWidget);
      expect(find.text('二度寝した'), findsOneWidget);
      expect(find.text('+50pt'), findsOneWidget);
    });

    testWidgets('renders empty state', (tester) async {
      final dio = Dio(BaseOptions(baseUrl: 'http://mock'));
      final adapter = DioAdapter(dio: dio);
      adapter.onGet('/activities', (s) => s.reply(200, {'records': [], 'summary': {'todayPoints': 0}}));

      await tester.pumpWidget(ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => FakeAuthNotifier(testTokens)),
          apiClientProvider.overrideWithValue(FakeApiClient(dio)),
        ],
        child: const MaterialApp(home: RecordTabScreen()),
      ));
      for (var i = 0; i < 20; i++) { await tester.pump(const Duration(milliseconds: 100)); }

      expect(find.text('まだ きろくが ないよ'), findsOneWidget);
    });

    testWidgets('segment switch works', (tester) async {
      final dio = Dio(BaseOptions(baseUrl: 'http://mock'));
      final adapter = DioAdapter(dio: dio);
      adapter.onGet('/activities', (s) => s.reply(200, {'records': [], 'summary': {'todayPoints': 0}}));

      await tester.pumpWidget(ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => FakeAuthNotifier(testTokens)),
          apiClientProvider.overrideWithValue(FakeApiClient(dio)),
        ],
        child: const MaterialApp(home: RecordTabScreen()),
      ));
      for (var i = 0; i < 20; i++) { await tester.pump(const Duration(milliseconds: 100)); }

      await tester.tap(find.text('しゅう'));
      await tester.pump();
      await tester.tap(find.text('つき'));
      await tester.pump();
    });
  });

  group('BattleTabScreen', () {
    testWidgets('renders with history', (tester) async {
      final dio = Dio(BaseOptions(baseUrl: 'http://mock'));
      final adapter = DioAdapter(dio: dio);
      adapter.onGet('/battles/history', (s) => s.reply(200, {
        'history': [
          {'battleId': 'b1', 'result': 'WIN', 'opponentNickname': 'テスト相手', 'pointsChange': 10, 'date': '2026-05-25'},
        ],
      }));

      await tester.pumpWidget(ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => FakeAuthNotifier(testTokens)),
          apiClientProvider.overrideWithValue(FakeApiClient(dio)),
        ],
        child: const MaterialApp(home: BattleTabScreen()),
      ));
      for (var i = 0; i < 20; i++) { await tester.pump(const Duration(milliseconds: 100)); }

      expect(find.text('バトル'), findsWidgets);
      expect(find.text('ランダムマッチ'), findsOneWidget);
    });

    testWidgets('renders empty history', (tester) async {
      final dio = Dio(BaseOptions(baseUrl: 'http://mock'));
      final adapter = DioAdapter(dio: dio);
      adapter.onGet('/battles/history', (s) => s.reply(200, {'history': []}));

      await tester.pumpWidget(ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => FakeAuthNotifier(testTokens)),
          apiClientProvider.overrideWithValue(FakeApiClient(dio)),
        ],
        child: const MaterialApp(home: BattleTabScreen()),
      ));
      for (var i = 0; i < 20; i++) { await tester.pump(const Duration(milliseconds: 100)); }

      expect(find.text('ランダムマッチ'), findsOneWidget);
    });
  });

  group('HomeScreen with homeDataProvider', () {
    testWidgets('renders with avatar and records', (tester) async {
      final dio = Dio(BaseOptions(baseUrl: 'http://mock'));
      final adapter = DioAdapter(dio: dio);
      adapter.onGet('/avatar', (s) => s.reply(200, {'avatar': {'avatarId': 'a1', 'userId': 'u1', 'name': 'テストぶた', 'totalPoints': 200, 'level': 3, 'evolutionStage': 1, 'stats': {'hp': 60, 'attack': 15, 'defense': 12, 'speed': 11}, 'skillIds': [], 'spriteSheetKey': 'sprites/stage1/default'}}));
      adapter.onGet('/activities', (s) => s.reply(200, {'records': [{'recordId': 'r1', 'categoryId': 'food-ramen', 'points': 50, 'recordedAt': DateTime.now().toIso8601String(), 'source': 'MANUAL'}], 'summary': {'todayCount': 1, 'todayPoints': 50}}));

      final fakeApi = FakeApiClient(dio);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => FakeAuthNotifier(testTokens)),
          apiClientProvider.overrideWithValue(fakeApi),
          avatarRepositoryProvider.overrideWithValue(AvatarRepository(fakeApi)),
          recordingRepositoryProvider.overrideWithValue(RecordingRepository(fakeApi)),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ));
      for (var i = 0; i < 20; i++) { await tester.pump(const Duration(milliseconds: 100)); }

      expect(find.text('テストぶた'), findsWidgets);
    });

    testWidgets('renders fallback on error', (tester) async {
      final dio = Dio(BaseOptions(baseUrl: 'http://mock'));
      final adapter = DioAdapter(dio: dio);
      adapter.onGet('/avatar', (s) => s.reply(500, {}));
      adapter.onGet('/activities', (s) => s.reply(500, {}));

      final fakeApi = FakeApiClient(dio);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => FakeAuthNotifier(testTokens)),
          apiClientProvider.overrideWithValue(fakeApi),
          avatarRepositoryProvider.overrideWithValue(AvatarRepository(fakeApi)),
          recordingRepositoryProvider.overrideWithValue(RecordingRepository(fakeApi)),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ));
      for (var i = 0; i < 20; i++) { await tester.pump(const Duration(milliseconds: 100)); }

      expect(find.text('こぶた'), findsWidgets);
    });
  });
}
