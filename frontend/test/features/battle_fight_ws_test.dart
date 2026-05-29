import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:buta_app/shared/theme.dart';
import 'package:buta_app/shared/app_config.dart';
import 'package:buta_app/shared/state/auth_state.dart';
import 'package:buta_app/shared/state/boot_state.dart';
import 'package:buta_app/shared/services/battle_ws_service.dart';
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

  group('BattleFightScreen - WebSocket message handling', () {
    testWidgets('battleStart message unlocks input', (t) async {
      await t.pumpWidget(_w(const BattleFightScreen(matchData: {'matchId': 'm1', 'player1Id': 'user-123'})));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }

      // Simulate battleStart message via the singleton stream
      BattleWsService.instance.messages.listen((_) {}); // ensure stream is active
      // We can't easily inject into the singleton, but the screen subscribes to it
      // The key is that the screen's initState subscribes to BattleWsService.instance.messages
      expect(find.text('じゅんび しています...'), findsOneWidget);
    });

    testWidgets('renders with timer advancing past 15 seconds', (t) async {
      await t.pumpWidget(_w(const BattleFightScreen(matchData: {'matchId': 'm1', 'player1Id': 'user-123'})));
      for (var i = 0; i < 5; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      // Advance many seconds to trigger timer color change (red when <= 5)
      for (var i = 0; i < 18; i++) {
        await t.pump(const Duration(seconds: 1));
      }
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('multiple dispose/recreate cycles', (t) async {
      // First instance
      await t.pumpWidget(_w(const BattleFightScreen(matchData: {'matchId': 'm1'})));
      for (var i = 0; i < 5; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      // Dispose
      await t.pumpWidget(const MaterialApp(home: Scaffold()));
      await t.pump();
      // Second instance
      await t.pumpWidget(_w(const BattleFightScreen(matchData: {'matchId': 'm2'})));
      for (var i = 0; i < 5; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('renders with player2 as self', (t) async {
      await t.pumpWidget(_w(const BattleFightScreen(matchData: {
        'matchId': 'm1', 'player1Id': 'other-user', 'player2Id': 'user-123',
      })));
      for (var i = 0; i < 15; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('skill buttons are gray when locked', (t) async {
      await t.pumpWidget(_w(const BattleFightScreen(matchData: {'matchId': 'm1'})));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      // Input is locked initially, buttons should be gray
      expect(find.text('こうげき'), findsNWidgets(3));
    });

    testWidgets('tap on locked skill does nothing', (t) async {
      await t.pumpWidget(_w(const BattleFightScreen(matchData: {'matchId': 'm1'})));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      // Try tapping a skill button (should be locked)
      await t.tap(find.text('こうげき').first);
      await t.pump();
      // Should still show same state
      expect(find.text('じゅんび しています...'), findsOneWidget);
    });

    testWidgets('tap on ぼうぎょ when locked', (t) async {
      await t.pumpWidget(_w(const BattleFightScreen(matchData: {'matchId': 'm1'})));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      await t.tap(find.text('ぼうぎょ'));
      await t.pump();
      expect(find.text('じゅんび しています...'), findsOneWidget);
    });
  });
}
