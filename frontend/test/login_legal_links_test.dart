import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:buta_app/shared/router.dart';

void main() {
  group('LoginScreen legal links', () {
    testWidgets('displays terms and privacy links', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final router = container.read(routerProvider);

      router.go('/login');
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('利用規約'), findsOneWidget);
      expect(find.text('プライバシーポリシー'), findsOneWidget);
    });

    testWidgets('tapping terms navigates to /terms', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final router = container.read(routerProvider);

      router.go('/login');
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('利用規約'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(router.state.uri.toString(), '/terms');
    });

    testWidgets('tapping privacy navigates to /privacy', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final router = container.read(routerProvider);

      router.go('/login');
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('プライバシーポリシー'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(router.state.uri.toString(), '/privacy');
    });
  });
}
