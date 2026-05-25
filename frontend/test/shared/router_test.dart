import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:buta_app/shared/router.dart';
import 'package:buta_app/shared/theme.dart';
import 'package:buta_app/shared/state/auth_state.dart';
import 'package:buta_app/shared/state/boot_state.dart';

import '../helpers/test_helpers.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({'access_token': 'a', 'refresh_token': 'r'}));

  Future<void> _testRoute(WidgetTester t, String path) async {
    t.view.physicalSize = const Size(390, 740);
    t.view.devicePixelRatio = 1.0;
    addTearDown(() => t.view.resetPhysicalSize());
    final c = ProviderContainer(overrides: [
      initialRouteProvider.overrideWithValue(path),
      bootProvider.overrideWith(() => FakeBootNotifier(BootResult(destination: BootDestination.home))),
    ]);
    await c.read(authStateProvider.future);
    final router = c.read(routerProvider);
    await t.pumpWidget(UncontrolledProviderScope(
      container: c, child: MaterialApp.router(theme: butaTheme, routerConfig: router),
    ));
    // タイマーを消化
    for (var i = 0; i < 50; i++) { await t.pump(const Duration(milliseconds: 100)); }
    addTearDown(c.dispose);
  }

  group('Router all routes', () {
    for (final path in ['/login', '/signup', '/confirm', '/nickname', '/', '/home', '/recording', '/battle', '/settings', '/evo-book', '/battle-result', '/friend-list', '/friend-search', '/battle-history', '/profile-edit', '/health-data', '/notification-settings', '/account-manage', '/legal/terms', '/legal/privacy', '/licenses']) {
      testWidgets('route $path', (t) async => _testRoute(t, path));
    }
  });
}
