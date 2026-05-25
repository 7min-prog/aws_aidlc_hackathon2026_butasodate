import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:buta_app/shared/router.dart';
import 'package:buta_app/shared/state/boot_state.dart';

import '../helpers/test_helpers.dart';

/// ルーターの各ルートを実際にナビゲートしてbuilderを通過させるテスト
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({'access_token': 'a', 'refresh_token': 'r'}));

  final routesWithExtra = {
    '/battle-result': {'win': true},
    '/record-confirm': {'category': 'FOOD', 'title': 'テスト'},
    '/record-complete': {'points': 100},
    '/record-detail': {'id': 'r1', 'category': 'FOOD', 'title': 'ラーメン', 'points': 50},
    '/confirm': 'test@example.com',
    '/evo-anim': {'name': 'メガトン', 'level': 5},
    '/avatar-detail': {'name': 'ぶた', 'level': 3},
  };

  for (final entry in routesWithExtra.entries) {
    testWidgets('route ${entry.key} with extra renders', (tester) async {
      tester.view.physicalSize = const Size(390, 740);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final c = ProviderContainer(overrides: [
        initialRouteProvider.overrideWithValue('/login'),
        bootProvider.overrideWith(() => FakeBootNotifier(BootResult(destination: BootDestination.home))),
      ]);
      addTearDown(c.dispose);
      final router = c.read(routerProvider);
      await tester.pumpWidget(UncontrolledProviderScope(container: c, child: MaterialApp.router(routerConfig: router)));
      await tester.pump();

      router.go(entry.key, extra: entry.value);
      for (var i = 0; i < 10; i++) { await tester.pump(const Duration(milliseconds: 100)); }
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  }
}
