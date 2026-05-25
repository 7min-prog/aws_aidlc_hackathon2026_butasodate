import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:buta_app/shared/theme.dart';
import 'package:buta_app/shared/state/auth_state.dart';
import 'package:buta_app/shared/state/boot_state.dart';
import 'package:buta_app/features/avatar/avatar_detail_screen2.dart';
import 'package:buta_app/features/avatar/evo_anim_screen.dart';
import 'package:buta_app/features/battle/battle_fight_screen.dart';
import 'package:buta_app/features/battle/battle_ready_screen.dart';
import 'package:buta_app/features/record/category_select_screen.dart';
import 'package:buta_app/features/legal/license_list_screen.dart';
import 'package:buta_app/features/home/home_screen.dart';

import '../helpers/test_helpers.dart';

Widget _w(Widget child) {
  final router = GoRouter(initialLocation: '/test', routes: [
    GoRoute(path: '/test', builder: (_, __) => child),
    GoRoute(path: '/login', builder: (_, __) => const Scaffold()),
    GoRoute(path: '/home', builder: (_, __) => const Scaffold()),
    GoRoute(path: '/splash', builder: (_, __) => const Scaffold()),
    GoRoute(path: '/recording', builder: (_, __) => const Scaffold()),
    GoRoute(path: '/category-select', builder: (_, __) => const Scaffold()),
    GoRoute(path: '/record-confirm', builder: (_, __) => const Scaffold()),
    GoRoute(path: '/avatar-detail', builder: (_, __) => const Scaffold()),
    GoRoute(path: '/evo-anim', builder: (_, __) => const Scaffold()),
    GoRoute(path: '/battle-fight', builder: (_, __) => const Scaffold()),
    GoRoute(path: '/battle-result', builder: (_, __) => const Scaffold()),
  ]);
  return ProviderScope(
    overrides: [
      authStateProvider.overrideWith(() => FakeAuthNotifier(testTokens)),
      bootProvider.overrideWith(() => FakeBootNotifier(BootResult(destination: BootDestination.home))),
    ],
    child: MaterialApp.router(theme: butaTheme, routerConfig: router),
  );
}

/// pumpで全タイマーを消化してからウィジェットを破棄
Future<void> _buildAndClean(WidgetTester t, Widget screen) async {
  t.view.physicalSize = const Size(390, 740);
  t.view.devicePixelRatio = 1.0;
  addTearDown(() => t.view.resetPhysicalSize());
  await t.pumpWidget(_w(screen));
  for (var i = 0; i < 50; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Timer/Nav screens', () {
    testWidgets('EvoAnimScreen', (t) async {
      t.view.physicalSize = const Size(390, 740);
      t.view.devicePixelRatio = 1.0;
      addTearDown(() => t.view.resetPhysicalSize());
      await t.pumpWidget(_w(const EvoAnimScreen()));
      // アニメーション全段階を通過（8秒分）
      for (var i = 0; i < 80; i++) { await t.pump(const Duration(milliseconds: 100)); }
    });
    testWidgets('BattleFightScreen', (t) async => _buildAndClean(t, const BattleFightScreen()));
    testWidgets('BattleReadyScreen', (t) async => _buildAndClean(t, const BattleReadyScreen()));
    testWidgets('LicenseListScreen', (t) async => _buildAndClean(t, const LicenseListScreen()));
    testWidgets('CategorySelectScreen', (t) async => _buildAndClean(t, const CategorySelectScreen()));
    testWidgets('HomeScreen', (t) async => _buildAndClean(t, const HomeScreen()));
    testWidgets('AvatarDetailScreen with data', (t) async => _buildAndClean(t, const AvatarDetailScreen(avatar: {
      'name': 'ぶた', 'level': 3, 'totalPoints': 150,
      'stats': {'hp': 60, 'attack': 15, 'defense': 12, 'speed': 11},
      'categoryPoints': {'FOOD': 80, 'LIFESTYLE': 50, 'MIXED': 20},
    })));
    testWidgets('AvatarDetailScreen null', (t) async => _buildAndClean(t, const AvatarDetailScreen(avatar: null)));
  });
}
