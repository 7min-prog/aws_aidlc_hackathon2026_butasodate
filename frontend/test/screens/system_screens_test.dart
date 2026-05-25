import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:buta_app/shared/router.dart';

void main() {
  group('System screens', () {
    testWidgets('ErrorScreen renders', (tester) async {
      final c = ProviderContainer(overrides: [initialRouteProvider.overrideWithValue('/error')]);
      addTearDown(c.dispose);
      final router = c.read(routerProvider);
      await tester.pumpWidget(UncontrolledProviderScope(container: c, child: MaterialApp.router(routerConfig: router)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('エラーが はっせいしました'), findsOneWidget);
      expect(find.text('リトライ'), findsOneWidget);
    });

    testWidgets('MaintenanceScreen renders', (tester) async {
      final c = ProviderContainer(overrides: [initialRouteProvider.overrideWithValue('/maintenance')]);
      addTearDown(c.dispose);
      final router = c.read(routerProvider);
      await tester.pumpWidget(UncontrolledProviderScope(container: c, child: MaterialApp.router(routerConfig: router)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('メンテナンスちゅう'), findsOneWidget);
    });

    testWidgets('ForceUpdateScreen renders', (tester) async {
      final c = ProviderContainer(overrides: [initialRouteProvider.overrideWithValue('/force-update')]);
      addTearDown(c.dispose);
      final router = c.read(routerProvider);
      await tester.pumpWidget(UncontrolledProviderScope(container: c, child: MaterialApp.router(routerConfig: router)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('アップデートが ひつようです'), findsOneWidget);
      expect(find.text('ストアへ'), findsOneWidget);
    });
  });

  group('StartScreen', () {
    testWidgets('renders title and press start', (tester) async {
      final c = ProviderContainer(overrides: [initialRouteProvider.overrideWithValue('/start')]);
      addTearDown(c.dispose);
      final router = c.read(routerProvider);
      await tester.pumpWidget(UncontrolledProviderScope(container: c, child: MaterialApp.router(routerConfig: router)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('ぶたそだて'), findsWidgets);
      expect(find.text('〜 人をダメにする育成RPG 〜'), findsOneWidget);
      expect(find.text('+ PRESS START +'), findsOneWidget);
    });
  });

  group('LegalScreen', () {
    testWidgets('/terms renders', (tester) async {
      final c = ProviderContainer(overrides: [initialRouteProvider.overrideWithValue('/terms')]);
      addTearDown(c.dispose);
      final router = c.read(routerProvider);
      await tester.pumpWidget(UncontrolledProviderScope(container: c, child: MaterialApp.router(routerConfig: router)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('利用規約'), findsOneWidget);
    });

    testWidgets('/privacy renders', (tester) async {
      final c = ProviderContainer(overrides: [initialRouteProvider.overrideWithValue('/privacy')]);
      addTearDown(c.dispose);
      final router = c.read(routerProvider);
      await tester.pumpWidget(UncontrolledProviderScope(container: c, child: MaterialApp.router(routerConfig: router)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('プライバシーポリシー'), findsOneWidget);
    });
  });
}
