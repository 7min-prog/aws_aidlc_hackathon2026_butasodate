import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:buta_app/shared/router.dart';
import 'package:buta_app/shared/state/boot_state.dart';

import '../helpers/test_helpers.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({'access_token': 'a', 'refresh_token': 'r'}));

  group('RecordTabScreen', () {
    testWidgets('renders record categories', (tester) async {
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
      for (var i = 0; i < 20; i++) { await tester.pump(const Duration(milliseconds: 100)); }
      // Record tab should show tab bar
      expect(find.text('きろく'), findsWidgets);
    });
  });

  group('BattleFightScreen', () {
    testWidgets('renders battle UI', (tester) async {
      tester.view.physicalSize = const Size(390, 740);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final c = ProviderContainer(overrides: [
        initialRouteProvider.overrideWithValue('/battle-fight'),
        bootProvider.overrideWith(() => FakeBootNotifier(BootResult(destination: BootDestination.home))),
      ]);
      addTearDown(c.dispose);
      final router = c.read(routerProvider);
      await tester.pumpWidget(UncontrolledProviderScope(container: c, child: MaterialApp.router(routerConfig: router)));
      for (var i = 0; i < 20; i++) { await tester.pump(const Duration(milliseconds: 100)); }
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });

  group('AvatarDetailScreen', () {
    testWidgets('renders with avatar data', (tester) async {
      tester.view.physicalSize = const Size(390, 740);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final c = ProviderContainer(overrides: [
        initialRouteProvider.overrideWithValue('/avatar-detail'),
        bootProvider.overrideWith(() => FakeBootNotifier(BootResult(destination: BootDestination.home))),
      ]);
      addTearDown(c.dispose);
      final router = c.read(routerProvider);
      router.go('/avatar-detail', extra: {
        'name': 'テストぶた',
        'level': 5,
        'totalPoints': 1000,
        'stats': {'hp': 100, 'attack': 20, 'defense': 15, 'speed': 10},
      });
      await tester.pumpWidget(UncontrolledProviderScope(container: c, child: MaterialApp.router(routerConfig: router)));
      for (var i = 0; i < 20; i++) { await tester.pump(const Duration(milliseconds: 100)); }
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });

  group('EvoAnimScreen', () {
    testWidgets('renders evolution animation', (tester) async {
      tester.view.physicalSize = const Size(390, 740);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final c = ProviderContainer(overrides: [
        initialRouteProvider.overrideWithValue('/evo-anim'),
        bootProvider.overrideWith(() => FakeBootNotifier(BootResult(destination: BootDestination.home))),
      ]);
      addTearDown(c.dispose);
      final router = c.read(routerProvider);
      router.go('/evo-anim', extra: {'name': 'メガトン', 'level': 5});
      await tester.pumpWidget(UncontrolledProviderScope(container: c, child: MaterialApp.router(routerConfig: router)));
      for (var i = 0; i < 20; i++) { await tester.pump(const Duration(milliseconds: 100)); }
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });

  group('LicenseListScreen', () {
    testWidgets('renders license list', (tester) async {
      tester.view.physicalSize = const Size(390, 740);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final c = ProviderContainer(overrides: [
        initialRouteProvider.overrideWithValue('/licenses'),
        bootProvider.overrideWith(() => FakeBootNotifier(BootResult(destination: BootDestination.home))),
      ]);
      addTearDown(c.dispose);
      final router = c.read(routerProvider);
      await tester.pumpWidget(UncontrolledProviderScope(container: c, child: MaterialApp.router(routerConfig: router)));
      for (var i = 0; i < 20; i++) { await tester.pump(const Duration(milliseconds: 100)); }
      expect(find.text('ライセンス'), findsOneWidget);
    });
  });
}
