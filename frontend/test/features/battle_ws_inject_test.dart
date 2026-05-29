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
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'id_token': 'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ1c2VyLTEyMyJ9.x',
      'access_token': 'test-access',
    });
    BattleWsService.instance.resetForTest();
  });

  testWidgets('BattleFightScreen - battleStart + turnResults + selectAction', (t) async {
    await t.pumpWidget(_w(const BattleFightScreen(matchData: {'matchId': 'm1', 'player1Id': 'user-123', 'player2Id': 'opp-1'})));
    for (var i = 0; i < 10; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }

    // battleStart unlocks input
    BattleWsService.instance.injectMessage({'type': 'battleStart', 'data': {'opponentName': 'テスト相手'}});
    await t.pump(const Duration(milliseconds: 100));
    await t.pump(const Duration(milliseconds: 100));
    expect(find.text('バトル かいし！'), findsOneWidget);

    // Select action
    await t.tap(find.text('こうげき').first);
    await t.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('えらんだ'), findsOneWidget);

    // turnResult - opponent damage
    BattleWsService.instance.injectMessage({
      'type': 'turnResult',
      'data': {
        'description': 'ヒット！',
        'battleState': {
          'player1': {'currentHp': 300, 'maxHp': 300},
          'player2': {'currentHp': 250, 'maxHp': 300},
        },
      },
    });
    for (var i = 0; i < 15; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('TURN 2/10'), findsOneWidget);

    // Select ぼうぎょ
    await t.tap(find.text('ぼうぎょ'));
    await t.pump(const Duration(milliseconds: 100));

    // turnResult - self damage only
    BattleWsService.instance.injectMessage({
      'type': 'turnResult',
      'data': {
        'description': 'あいての こうげき！',
        'battleState': {
          'player1': {'currentHp': 260, 'maxHp': 300},
          'player2': {'currentHp': 250, 'maxHp': 300},
        },
      },
    });
    for (var i = 0; i < 15; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('TURN 3/10'), findsOneWidget);

    // Select action
    await t.tap(find.text('こうげき').first);
    await t.pump(const Duration(milliseconds: 100));

    // turnResult - both damage
    BattleWsService.instance.injectMessage({
      'type': 'turnResult',
      'data': {
        'description': 'おたがいに ダメージ！',
        'battleState': {
          'player1': {'currentHp': 230, 'maxHp': 300},
          'player2': {'currentHp': 200, 'maxHp': 300},
        },
      },
    });
    for (var i = 0; i < 20; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('TURN 4/10'), findsOneWidget);

    // Select action
    await t.tap(find.text('こうげき').first);
    await t.pump(const Duration(milliseconds: 100));

    // turnResult - no damage (both defend)
    BattleWsService.instance.injectMessage({
      'type': 'turnResult',
      'data': {
        'description': 'おたがい ぼうぎょ',
        'battleState': {
          'player1': {'currentHp': 230, 'maxHp': 300},
          'player2': {'currentHp': 200, 'maxHp': 300},
        },
      },
    });
    for (var i = 0; i < 10; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('TURN 5/10'), findsOneWidget);
  });
}
