import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:buta_app/features/home/health_sync_result_dialog.dart';
import 'package:buta_app/features/record/record_complete_screen.dart';
import 'package:buta_app/features/home/home_screen.dart';
import 'package:buta_app/features/avatar/avatar_detail_screen2.dart';

void main() {
  group('HealthSyncResultDialog full coverage', () {
    testWidgets('renders items list and total points', (tester) async {
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: Center(
        child: HealthSyncResultDialog(
          items: [
            {'category': 'weight', 'points': 20, 'description': '体重+2kg'},
            {'category': 'bmi', 'points': 15, 'description': 'BMI上昇'},
            {'category': 'steps', 'points': 10, 'description': '歩数少ない'},
          ],
          totalPoints: 45,
          avatarName: 'こぶた',
        ),
      ))));
      for (var i = 0; i < 5; i++) { await tester.pump(const Duration(milliseconds: 100)); }
      expect(find.byType(HealthSyncResultDialog), findsOneWidget);
      expect(find.textContaining('45'), findsWidgets);
    });

    testWidgets('tap close/ok button', (tester) async {
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: Center(
        child: HealthSyncResultDialog(items: [{'category': 'x', 'points': 5, 'description': 'y'}], totalPoints: 5, avatarName: 'ぶた'),
      ))));
      for (var i = 0; i < 5; i++) { await tester.pump(const Duration(milliseconds: 100)); }
      final btns = find.byType(ElevatedButton);
      if (btns.evaluate().isNotEmpty) {
        await tester.tap(btns.first);
        await tester.pump();
      } else {
        final gestures = find.byType(GestureDetector);
        if (gestures.evaluate().isNotEmpty) {
          await tester.tap(gestures.last);
          await tester.pump();
        }
      }
    });
  });

  group('RecordCompleteScreen full coverage', () {
    testWidgets('renders large points', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [homeDataProvider.overrideWith((ref) async => {'avatar': {'name': 'x', 'level': 1}, 'records': [], 'summary': {}})],
        child: MaterialApp(home: const RecordCompleteScreen(points: 999)),
      ));
      for (var i = 0; i < 5; i++) { await tester.pump(const Duration(milliseconds: 100)); }
      expect(find.text('+999pt!'), findsOneWidget);
    });

    testWidgets('renders zero points', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [homeDataProvider.overrideWith((ref) async => {'avatar': {'name': 'x', 'level': 1}, 'records': [], 'summary': {}})],
        child: MaterialApp(home: const RecordCompleteScreen(points: 0)),
      ));
      for (var i = 0; i < 5; i++) { await tester.pump(const Duration(milliseconds: 100)); }
      expect(find.text('+0pt!'), findsOneWidget);
    });
  });
}
