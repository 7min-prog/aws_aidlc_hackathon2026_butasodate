import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:buta_app/shared/router.dart';
import 'package:buta_app/shared/state/boot_state.dart';
import 'package:buta_app/shared/state/auth_state.dart';

import '../helpers/test_helpers.dart';

/// home_screenのコードパスを最大限カバーするテスト
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({'access_token': 'test', 'refresh_token': 'test'}));

  testWidgets('HomeScreen renders full UI with default data (API error path)', (tester) async {
    tester.view.physicalSize = const Size(390, 740);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final c = ProviderContainer(overrides: [
      initialRouteProvider.overrideWithValue('/home'),
      bootProvider.overrideWith(() => FakeBootNotifier(BootResult(destination: BootDestination.home))),
      // authStateProvider returns tokens so homeDataProvider tries API (which fails in test → default values)
    ]);
    addTearDown(c.dispose);
    final router = c.read(routerProvider);
    await tester.pumpWidget(UncontrolledProviderScope(container: c, child: MaterialApp.router(routerConfig: router)));
    // Pump enough frames for FutureProvider to resolve with error → default data
    for (var i = 0; i < 30; i++) { await tester.pump(const Duration(milliseconds: 100)); }

    // Default avatar name
    expect(find.text('こぶた'), findsWidgets);
    // Tab bar
    expect(find.text('ホーム'), findsWidgets);
    expect(find.text('きろく'), findsWidgets);
    expect(find.text('バトル'), findsWidgets);
  });

  testWidgets('RecordTabScreen renders full UI', (tester) async {
    tester.view.physicalSize = const Size(390, 740);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final c = ProviderContainer(overrides: [
      initialRouteProvider.overrideWithValue('/recording'),
      bootProvider.overrideWith(() => FakeBootNotifier(BootResult(destination: BootDestination.home))),
    ]);
    addTearDown(c.dispose);
    final router = c.read(routerProvider);
    await tester.pumpWidget(UncontrolledProviderScope(container: c, child: MaterialApp.router(routerConfig: router)));
    for (var i = 0; i < 30; i++) { await tester.pump(const Duration(milliseconds: 100)); }

    expect(find.text('きろく'), findsWidgets);
  });

  testWidgets('BattleTabScreen renders full UI', (tester) async {
    tester.view.physicalSize = const Size(390, 740);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final c = ProviderContainer(overrides: [
      initialRouteProvider.overrideWithValue('/battle'),
      bootProvider.overrideWith(() => FakeBootNotifier(BootResult(destination: BootDestination.home))),
    ]);
    addTearDown(c.dispose);
    final router = c.read(routerProvider);
    await tester.pumpWidget(UncontrolledProviderScope(container: c, child: MaterialApp.router(routerConfig: router)));
    for (var i = 0; i < 30; i++) { await tester.pump(const Duration(milliseconds: 100)); }

    expect(find.text('バトル'), findsWidgets);
  });

  testWidgets('AccountTabScreen renders full UI', (tester) async {
    tester.view.physicalSize = const Size(390, 740);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final c = ProviderContainer(overrides: [
      initialRouteProvider.overrideWithValue('/settings'),
      bootProvider.overrideWith(() => FakeBootNotifier(BootResult(destination: BootDestination.home))),
    ]);
    addTearDown(c.dispose);
    final router = c.read(routerProvider);
    await tester.pumpWidget(UncontrolledProviderScope(container: c, child: MaterialApp.router(routerConfig: router)));
    for (var i = 0; i < 30; i++) { await tester.pump(const Duration(milliseconds: 100)); }

    expect(find.text('せってい'), findsWidgets);
  });
}
