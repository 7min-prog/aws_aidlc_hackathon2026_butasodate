import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:buta_app/shared/theme.dart';
import 'package:buta_app/shared/state/auth_state.dart';
import 'package:buta_app/shared/state/boot_state.dart';
import 'package:buta_app/features/battle/battle_fight_screen.dart';

import '../helpers/test_helpers.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('BattleFightScreen - tap skills and progress turns', (t) async {
    t.view.physicalSize = const Size(390, 740);
    t.view.devicePixelRatio = 1.0;
    addTearDown(() => t.view.resetPhysicalSize());

    final router = GoRouter(initialLocation: '/fight', routes: [
      GoRoute(path: '/fight', builder: (_, __) => const BattleFightScreen()),
      GoRoute(path: '/battle-result', builder: (_, __) => const Scaffold(body: Text('result'))),
    ]);

    await t.pumpWidget(ProviderScope(
      overrides: [
        authStateProvider.overrideWith(() => FakeAuthNotifier(testTokens)),
        bootProvider.overrideWith(() => FakeBootNotifier(BootResult(destination: BootDestination.home))),
      ],
      child: MaterialApp.router(theme: butaTheme, routerConfig: router),
    ));
    await t.pump(const Duration(milliseconds: 100));

    // スキルボタンをタップして攻撃
    for (var turn = 0; turn < 10; turn++) {
      final skill = find.text('にくあつプレス');
      if (skill.evaluate().isNotEmpty) {
        await t.tap(skill.first);
      }
      // タイマーを進める
      for (var i = 0; i < 15; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      // バトル終了したら抜ける
      if (find.text('result').evaluate().isNotEmpty) break;
    }

    // 防御も試す
    final defense = find.text('ぼうぎょ');
    if (defense.evaluate().isNotEmpty) {
      await t.tap(defense.first);
      for (var i = 0; i < 15; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
    }

    // 最終的にウィジェットを破棄
    await t.pumpWidget(const MaterialApp(home: SizedBox()));
  });
}
