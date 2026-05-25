import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:buta_app/shared/router.dart';
import 'package:buta_app/shared/state/auth_state.dart';
import 'package:buta_app/shared/state/boot_state.dart';

import '../helpers/test_helpers.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({'access_token': 'a', 'refresh_token': 'r'}));

  group('HomeScreen', () {
    testWidgets('renders home elements', (tester) async {
      tester.view.physicalSize = const Size(390, 740);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final c = ProviderContainer(overrides: [
        initialRouteProvider.overrideWithValue('/home'),
        bootProvider.overrideWith(() => FakeBootNotifier(BootResult(destination: BootDestination.home))),
      ]);
      addTearDown(c.dispose);
      final router = c.read(routerProvider);
      await tester.pumpWidget(UncontrolledProviderScope(container: c, child: MaterialApp.router(routerConfig: router)));
      for (var i = 0; i < 30; i++) { await tester.pump(const Duration(milliseconds: 100)); }
      // ホーム画面にはタブバーがある
      expect(find.text('ホーム'), findsWidgets);
    });
  });

  group('RecordTabScreen', () {
    testWidgets('renders record tab', (tester) async {
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
  });

  group('BattleTabScreen', () {
    testWidgets('renders battle tab', (tester) async {
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
  });

  group('SettingsScreen', () {
    testWidgets('renders settings tab', (tester) async {
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
  });
}
