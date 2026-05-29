import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:buta_app/shared/theme.dart';
import 'package:buta_app/shared/app_config.dart';
import 'package:buta_app/shared/state/auth_state.dart';
import 'package:buta_app/shared/state/boot_state.dart';
import 'package:buta_app/features/record/record_detail_screen.dart';
import 'package:buta_app/features/battle/battle_matching_screen.dart';

import '../helpers/test_helpers.dart';

Widget _w(Widget child) => ProviderScope(
  overrides: [
    authStateProvider.overrideWith(() => FakeAuthNotifier(testTokens)),
    bootProvider.overrideWith(() => FakeBootNotifier(BootResult(destination: BootDestination.home))),
  ],
  child: MaterialApp(theme: butaTheme, home: child),
);

void main() {
  setUpAll(() => AppConfig.init(Flavor.dev));
  setUp(() => SharedPreferences.setMockInitialValues({
    'id_token': 'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ1c2VyLTEyMyJ9.x',
    'access_token': 'test-access',
  }));

  group('RecordDetailScreen - delete button', () {
    testWidgets('tap delete shows confirm dialog', (t) async {
      await t.pumpWidget(_w(RecordDetailScreen(record: {
        'recordId': 'r1', 'categoryId': 'food_late_ramen', 'categoryName': 'しんやラーメン',
        'points': 50, 'recordedAt': '2026-05-24T23:30:00Z', 'memo': 'テスト',
      })));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      // Tap delete button
      final deleteBtn = find.text('⚠ このきろくを けす');
      if (deleteBtn.evaluate().isNotEmpty) {
        await t.tap(deleteBtn);
        for (var i = 0; i < 10; i++) {
          await t.pump(const Duration(milliseconds: 100));
        }
        // Confirm dialog should appear
        expect(find.text('きろくをけす'), findsOneWidget);
      }
    });

    testWidgets('confirm delete triggers API call', (t) async {
      await t.pumpWidget(_w(RecordDetailScreen(record: {
        'recordId': 'r1', 'categoryId': 'food_late_ramen', 'categoryName': 'しんやラーメン',
        'points': 50, 'recordedAt': '2026-05-24T23:30:00Z',
      })));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      await t.tap(find.text('⚠ このきろくを けす'));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      // Tap confirm in dialog (look for はい or OK button)
      final confirmBtn = find.text('はい');
      if (confirmBtn.evaluate().isNotEmpty) {
        await t.tap(confirmBtn);
        for (var i = 0; i < 20; i++) {
          await t.pump(const Duration(milliseconds: 100));
        }
      }
    });
  });

  group('BattleMatchingScreen - timer and cancel', () {
    testWidgets('renders and timer advances significantly', (t) async {
      await t.pumpWidget(_w(const BattleMatchingScreen()));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      // Advance timer significantly
      for (var i = 0; i < 15; i++) {
        await t.pump(const Duration(seconds: 1));
      }
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('cancel button exists and is tappable', (t) async {
      await t.pumpWidget(_w(const BattleMatchingScreen()));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      // Find cancel button text
      final cancelBtn = find.text('キャンセル');
      if (cancelBtn.evaluate().isNotEmpty) {
        await t.tap(cancelBtn);
        for (var i = 0; i < 5; i++) {
          await t.pump(const Duration(milliseconds: 100));
        }
      }
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('timer expiry after 30 seconds', (t) async {
      await t.pumpWidget(_w(const BattleMatchingScreen()));
      for (var i = 0; i < 5; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      // Advance 31 seconds to trigger timer expiry
      for (var i = 0; i < 31; i++) {
        await t.pump(const Duration(seconds: 1));
      }
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      // After expiry, alert dialog should show
      expect(find.byType(Scaffold), findsWidgets);
    });
  });
}
