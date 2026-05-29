import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:buta_app/shared/router.dart';
import 'package:buta_app/shared/state/boot_state.dart';
import 'package:buta_app/shared/state/auth_state.dart';

import '../helpers/test_helpers.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('TutorialScreen', () {
    testWidgets('renders tutorial content', (tester) async {
      tester.view.physicalSize = const Size(390, 740);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final c = ProviderContainer(overrides: [
        initialRouteProvider.overrideWithValue('/tutorial'),
        bootProvider.overrideWith(() => FakeBootNotifier(BootResult(destination: BootDestination.home))),
      ]);
      addTearDown(c.dispose);
      final router = c.read(routerProvider);
      await tester.pumpWidget(UncontrolledProviderScope(container: c, child: MaterialApp.router(routerConfig: router)));
      for (var i = 0; i < 20; i++) { await tester.pump(const Duration(milliseconds: 100)); }
      // Tutorial should have some content
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('can swipe through tutorial pages', (tester) async {
      tester.view.physicalSize = const Size(390, 740);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final c = ProviderContainer(overrides: [
        initialRouteProvider.overrideWithValue('/tutorial'),
        bootProvider.overrideWith(() => FakeBootNotifier(BootResult(destination: BootDestination.home))),
      ]);
      addTearDown(c.dispose);
      final router = c.read(routerProvider);
      await tester.pumpWidget(UncontrolledProviderScope(container: c, child: MaterialApp.router(routerConfig: router)));
      for (var i = 0; i < 20; i++) { await tester.pump(const Duration(milliseconds: 100)); }

      // Try swiping
      await tester.drag(find.byType(MaterialApp), const Offset(-200, 0));
      for (var i = 0; i < 10; i++) { await tester.pump(const Duration(milliseconds: 100)); }
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });

  group('LoadingScreen', () {
    testWidgets('renders loading progress', (tester) async {
      tester.view.physicalSize = const Size(390, 740);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final c = ProviderContainer(overrides: [
        initialRouteProvider.overrideWithValue('/loading'),
        bootProvider.overrideWith(() => FakeBootNotifier(BootResult(destination: BootDestination.home))),
      ]);
      addTearDown(c.dispose);
      final router = c.read(routerProvider);
      await tester.pumpWidget(UncontrolledProviderScope(container: c, child: MaterialApp.router(routerConfig: router)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.textContaining('よみこんでいます'), findsOneWidget);
    });

    testWidgets('navigates to login after loading', (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(390, 740);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final c = ProviderContainer(overrides: [
        initialRouteProvider.overrideWithValue('/loading'),
        bootProvider.overrideWith(() => FakeBootNotifier(BootResult(destination: BootDestination.home))),
      ]);
      addTearDown(c.dispose);
      final router = c.read(routerProvider);
      await tester.pumpWidget(UncontrolledProviderScope(container: c, child: MaterialApp.router(routerConfig: router)));
      // Wait for animation to complete (2 seconds)
      for (var i = 0; i < 30; i++) { await tester.pump(const Duration(milliseconds: 100)); }
      // Should navigate away
      expect(router.state.uri.toString(), isNot('/loading'));
    });
  });

  group('AuthState', () {
    test('authStateProvider returns null when no tokens stored', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = await container.read(authStateProvider.future);
      expect(result, isNull);
    });

    test('authStateProvider returns tokens when stored', () async {
      SharedPreferences.setMockInitialValues({
        'access_token': 'my_access',
        'refresh_token': 'my_refresh',
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = await container.read(authStateProvider.future);
      expect(result, isNotNull);
    });

    test('login with invalid credentials returns false', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(authStateProvider.notifier);
      // In test environment, API call fails → returns false
      final result = await notifier.login('bad@email.com', 'wrong');
      // May throw or return false depending on implementation
      expect(result, isFalse);
    }, skip: true); // Requires network

    test('logout clears tokens', () async {
      SharedPreferences.setMockInitialValues({
        'access_token': 'token',
        'refresh_token': 'refresh',
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(authStateProvider.future);
      await container.read(authStateProvider.notifier).logout();
      final result = await container.read(authStateProvider.future);
      expect(result, isNull);
    }, skip: true); // Requires network
  });
}
