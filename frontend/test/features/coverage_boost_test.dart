import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:buta_app/features/home/health_sync_result_dialog.dart';
import 'package:buta_app/features/record/record_complete_screen.dart';
import 'package:buta_app/features/home/home_screen.dart';
import 'package:buta_app/features/battle/battle_ready_screen.dart';
import 'package:buta_app/features/settings/profile_edit_screen.dart';

void main() {
  group('HealthSyncResultDialog', () {
    testWidgets('renders with items', (tester) async {
      await tester.pumpWidget(ProviderScope(child: MaterialApp(home: Scaffold(
        body: HealthSyncResultDialog(
          items: [
            {'category': 'weight', 'points': 10, 'description': '体重増加'},
          ],
          totalPoints: 10,
          avatarName: 'こぶた',
        ),
      ))));
      for (var i = 0; i < 5; i++) { await tester.pump(const Duration(milliseconds: 100)); }
      expect(find.byType(HealthSyncResultDialog), findsOneWidget);
    });

    testWidgets('renders with empty items', (tester) async {
      await tester.pumpWidget(ProviderScope(child: MaterialApp(home: Scaffold(
        body: HealthSyncResultDialog(items: const [], totalPoints: 0, avatarName: 'ぶた'),
      ))));
      await tester.pump();
      expect(find.byType(HealthSyncResultDialog), findsOneWidget);
    });

    testWidgets('renders with multiple items', (tester) async {
      await tester.pumpWidget(ProviderScope(child: MaterialApp(home: Scaffold(
        body: HealthSyncResultDialog(
          items: [
            {'category': 'bmi', 'points': 20, 'description': 'BMI上昇'},
            {'category': 'weight', 'points': 15, 'description': '体重増加'},
          ],
          totalPoints: 35,
          avatarName: 'ぽっちゃり',
        ),
      ))));
      for (var i = 0; i < 5; i++) { await tester.pump(const Duration(milliseconds: 100)); }
      expect(find.byType(HealthSyncResultDialog), findsOneWidget);
    });
  });

  group('RecordCompleteScreen coverage', () {
    testWidgets('renders with points', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [homeDataProvider.overrideWith((ref) async => {'avatar': {'name': 'こぶた', 'level': 1}, 'records': [], 'summary': {}})],
        child: MaterialApp(home: const RecordCompleteScreen(points: 42)),
      ));
      for (var i = 0; i < 5; i++) { await tester.pump(const Duration(milliseconds: 100)); }
      expect(find.text('+42pt!'), findsOneWidget);
    });
  });

  group('BattleReadyScreen coverage', () {
    testWidgets('renders screen', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(ProviderScope(child: MaterialApp(home: const BattleReadyScreen())));
        await tester.pump(const Duration(milliseconds: 500));
      });
      expect(find.byType(BattleReadyScreen), findsOneWidget);
    });
  });

  group('ProfileEditScreen coverage', () {
    testWidgets('renders form', (tester) async {
      await tester.pumpWidget(ProviderScope(child: MaterialApp(home: const ProfileEditScreen())));
      for (var i = 0; i < 10; i++) { await tester.pump(const Duration(milliseconds: 100)); }
      expect(find.byType(ProfileEditScreen), findsOneWidget);
    });

    testWidgets('can interact with fields', (tester) async {
      await tester.pumpWidget(ProviderScope(child: MaterialApp(home: const ProfileEditScreen())));
      for (var i = 0; i < 10; i++) { await tester.pump(const Duration(milliseconds: 100)); }
      final fields = find.byType(TextField);
      if (fields.evaluate().isNotEmpty) {
        await tester.enterText(fields.first, 'テスト');
        await tester.pump();
      }
    });
  });
}
