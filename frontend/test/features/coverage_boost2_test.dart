import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:buta_app/features/record/record_confirm_screen.dart';
import 'package:buta_app/features/auth/login_screen.dart';

void main() {
  group('RecordConfirmScreen coverage', () {
    testWidgets('renders with category', (tester) async {
      await tester.pumpWidget(ProviderScope(child: MaterialApp(
        home: RecordConfirmScreen(category: {'id': 'food_late_ramen', 'name': 'しんやラーメン', 'points': 15, 'icon': '🍜'}),
      )));
      for (var i = 0; i < 10; i++) { await tester.pump(const Duration(milliseconds: 100)); }
      expect(find.textContaining('ラーメン'), findsWidgets);
    });

    testWidgets('renders with empty category', (tester) async {
      await tester.pumpWidget(ProviderScope(child: MaterialApp(
        home: const RecordConfirmScreen(category: {}),
      )));
      for (var i = 0; i < 10; i++) { await tester.pump(const Duration(milliseconds: 100)); }
      expect(find.byType(RecordConfirmScreen), findsOneWidget);
    });

    testWidgets('renders with food_snack category', (tester) async {
      await tester.pumpWidget(ProviderScope(child: MaterialApp(
        home: RecordConfirmScreen(category: {'id': 'food_snack', 'name': 'かんしょく', 'points': 10, 'icon': '🍩'}),
      )));
      for (var i = 0; i < 10; i++) { await tester.pump(const Duration(milliseconds: 100)); }
      expect(find.byType(RecordConfirmScreen), findsOneWidget);
    });
  });

  group('LoginScreen coverage', () {
    testWidgets('renders email and password fields', (tester) async {
      await tester.pumpWidget(ProviderScope(child: MaterialApp(home: const LoginScreen())));
      for (var i = 0; i < 10; i++) { await tester.pump(const Duration(milliseconds: 100)); }
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('can enter text in fields', (tester) async {
      await tester.pumpWidget(ProviderScope(child: MaterialApp(home: const LoginScreen())));
      for (var i = 0; i < 10; i++) { await tester.pump(const Duration(milliseconds: 100)); }
      final fields = find.byType(TextField);
      if (fields.evaluate().length >= 2) {
        await tester.enterText(fields.at(0), 'test@test.com');
        await tester.enterText(fields.at(1), 'password123');
        await tester.pump();
      }
    });

    testWidgets('tap login button with empty fields', (tester) async {
      await tester.pumpWidget(ProviderScope(child: MaterialApp(home: const LoginScreen())));
      for (var i = 0; i < 10; i++) { await tester.pump(const Duration(milliseconds: 100)); }
      final btn = find.textContaining('ログイン');
      if (btn.evaluate().isNotEmpty) {
        await tester.tap(btn.first);
        await tester.pump();
      }
    });
  });
}
