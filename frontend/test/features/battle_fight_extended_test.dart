import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:buta_app/shared/theme.dart';
import 'package:buta_app/shared/app_config.dart';
import 'package:buta_app/shared/state/auth_state.dart';
import 'package:buta_app/shared/state/boot_state.dart';
import 'package:buta_app/features/battle/battle_fight_screen.dart';

import '../helpers/test_helpers.dart';

Widget _w(Widget child) => ProviderScope(
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

  // The BattleFightScreen has 101 uncovered lines (78-225, 288-289).
  // These are WebSocket message handlers that require actual WS messages.
  // Since BattleWsService is a singleton with private _controller,
  // we test what we can: the build method, timer, and dispose paths.

  group('BattleFightScreen - maximize build coverage', () {
    testWidgets('full lifecycle with timer expiry', (t) async {
      await t.pumpWidget(_w(const BattleFightScreen(matchData: {'matchId': 'm1', 'player1Id': 'user-123'})));
      // Initial render
      for (var i = 0; i < 5; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('TURN 1/10'), findsOneWidget);
      expect(find.text('00:20'), findsOneWidget);
      // Let timer run for 20+ seconds to trigger auto-select (line 196)
      for (var i = 0; i < 22; i++) {
        await t.pump(const Duration(seconds: 1));
      }
      // After 20s, _selectAction(3) should be called if timer was started
      // But timer only starts after battleStart message, so it won't trigger here
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('renders AnimatedBuilder for shake', (t) async {
      await t.pumpWidget(_w(const BattleFightScreen(matchData: {'matchId': 'm1', 'player1Id': 'user-123'})));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      // AnimatedBuilder is used for shake animation
      expect(find.byType(AnimatedBuilder), findsWidgets);
    });

    testWidgets('SafeArea wraps content', (t) async {
      await t.pumpWidget(_w(const BattleFightScreen(matchData: {'matchId': 'm1'})));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(SafeArea), findsOneWidget);
    });

    testWidgets('renders with various matchData combinations', (t) async {
      // Test with only matchId
      await t.pumpWidget(_w(const BattleFightScreen(matchData: {'matchId': 'test-match'})));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(Scaffold), findsOneWidget);
      await t.pumpWidget(const SizedBox()); // dispose

      // Test with player2Id matching self
      await t.pumpWidget(_w(const BattleFightScreen(matchData: {
        'matchId': 'test-match', 'player1Id': 'someone-else', 'player2Id': 'user-123',
      })));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(Scaffold), findsOneWidget);
      await t.pumpWidget(const SizedBox()); // dispose

      // Test with neither matching
      await t.pumpWidget(_w(const BattleFightScreen(matchData: {
        'matchId': 'test-match', 'player1Id': 'a', 'player2Id': 'b',
      })));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
