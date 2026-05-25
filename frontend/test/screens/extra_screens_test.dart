import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:buta_app/shared/theme.dart';
import 'package:buta_app/shared/state/auth_state.dart';
import 'package:buta_app/shared/state/boot_state.dart';
import 'package:buta_app/features/battle/battle_invite_dialog.dart';
import 'package:buta_app/features/battle/battle_result_screen.dart';
import 'package:buta_app/features/record/record_confirm_screen.dart';
import 'package:buta_app/features/record/record_complete_screen.dart';
import 'package:buta_app/features/battle/battle_matching_screen.dart';

import '../helpers/test_helpers.dart';

Widget _w(Widget child) {
  final router = GoRouter(initialLocation: '/test', routes: [
    GoRoute(path: '/test', builder: (_, __) => child),
    GoRoute(path: '/battle-fight', builder: (_, __) => const Scaffold()),
    GoRoute(path: '/battle', builder: (_, __) => const Scaffold()),
    GoRoute(path: '/recording', builder: (_, __) => const Scaffold()),
    GoRoute(path: '/home', builder: (_, __) => const Scaffold()),
    GoRoute(path: '/record-complete', builder: (_, __) => const Scaffold()),
  ]);
  return ProviderScope(
    overrides: [
      authStateProvider.overrideWith(() => FakeAuthNotifier(testTokens)),
      bootProvider.overrideWith(() => FakeBootNotifier(BootResult(destination: BootDestination.home))),
    ],
    child: MaterialApp.router(theme: butaTheme, routerConfig: router),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Extra screens', () {
    testWidgets('BattleInviteDialog renders', (t) async {
      await t.pumpWidget(ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => FakeAuthNotifier(testTokens)),
          bootProvider.overrideWith(() => FakeBootNotifier(BootResult(destination: BootDestination.home))),
        ],
        child: MaterialApp(theme: butaTheme, home: Scaffold(body: Builder(builder: (ctx) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            showBattleInviteDialog(ctx, opponent: 'テスト');
          });
          return const SizedBox();
        }))),
      ));
      await t.pumpAndSettle();
      expect(find.textContaining('テスト'), findsAtLeast(1));
    });

    testWidgets('BattleResultScreen win', (t) async {
      t.view.physicalSize = const Size(390, 740);
      t.view.devicePixelRatio = 1.0;
      addTearDown(() => t.view.resetPhysicalSize());
      await t.pumpWidget(_w(const BattleResultScreen(win: true)));
      await t.pump();
      expect(find.byType(Scaffold), findsAtLeast(1));
    });

    testWidgets('BattleResultScreen lose', (t) async {
      t.view.physicalSize = const Size(390, 740);
      t.view.devicePixelRatio = 1.0;
      addTearDown(() => t.view.resetPhysicalSize());
      await t.pumpWidget(_w(const BattleResultScreen(win: false)));
      await t.pump();
      expect(find.byType(Scaffold), findsAtLeast(1));
    });

    testWidgets('RecordConfirmScreen', (t) async {
      t.view.physicalSize = const Size(390, 740);
      t.view.devicePixelRatio = 1.0;
      addTearDown(() => t.view.resetPhysicalSize());
      await t.pumpWidget(_w(RecordConfirmScreen(category: {'categoryId': 'c1', 'name': 'ラーメン', 'basePoints': 50, 'iconKey': 'cat-ramen'})));
      await t.pump();
      expect(find.byType(Scaffold), findsAtLeast(1));
    });

    testWidgets('RecordCompleteScreen', (t) async {
      t.view.physicalSize = const Size(390, 740);
      t.view.devicePixelRatio = 1.0;
      addTearDown(() => t.view.resetPhysicalSize());
      await t.pumpWidget(_w(const RecordCompleteScreen(points: 50)));
      for (var i = 0; i < 30; i++) { await t.pump(const Duration(milliseconds: 100)); }
    });

    testWidgets('BattleMatchingScreen', (t) async {
      t.view.physicalSize = const Size(390, 740);
      t.view.devicePixelRatio = 1.0;
      addTearDown(() => t.view.resetPhysicalSize());
      await t.pumpWidget(_w(const BattleMatchingScreen()));
      for (var i = 0; i < 50; i++) { await t.pump(const Duration(milliseconds: 100)); }
    });
  });
}
