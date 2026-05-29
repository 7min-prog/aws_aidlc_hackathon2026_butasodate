import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:buta_app/shared/theme.dart';
import 'package:buta_app/shared/state/auth_state.dart';
import 'package:buta_app/shared/state/boot_state.dart';
import 'package:buta_app/features/auth/login_screen.dart';
import 'package:buta_app/features/auth/signup_screen.dart';
import 'package:buta_app/features/auth/confirm_screen.dart';
import 'package:buta_app/features/auth/nickname_screen.dart';
import 'package:buta_app/features/battle/battle_tab_screen.dart';
import 'package:buta_app/features/record/record_tab_screen.dart';
import 'package:buta_app/features/account/account_tab_screen.dart';
import 'package:buta_app/features/settings/settings_screen.dart';

import '../helpers/test_helpers.dart';

Widget _wrap(Widget child) {
  return ProviderScope(
    overrides: [
      authStateProvider.overrideWith(() => FakeAuthNotifier(testTokens)),
      bootProvider.overrideWith(() => FakeBootNotifier(BootResult(destination: BootDestination.home))),
    ],
    child: MaterialApp(theme: butaTheme, home: child),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  // アニメーション画面はpumpAndSettleがタイムアウトするのでpump+固定時間で撮影
  Future<void> goldenTest(WidgetTester t, Widget screen, String name) async {
    await t.pumpWidget(_wrap(screen));
    await t.pump(const Duration(milliseconds: 500));
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/$name.png'));
  }

  group('Golden - Auth', () {
    testWidgets('LoginScreen', (t) async => goldenTest(t, const LoginScreen(), 'login_screen'));
    testWidgets('SignupScreen', (t) async => goldenTest(t, const SignupScreen(), 'signup_screen'));
    testWidgets('ConfirmScreen', (t) async => goldenTest(t, const ConfirmScreen(email: 'test@example.com'), 'confirm_screen'));
    testWidgets('NicknameScreen', (t) async => goldenTest(t, const NicknameScreen(), 'nickname_screen'));
  });

  group('Golden - Tabs', () {
    testWidgets('RecordTabScreen', (t) async => goldenTest(t, const RecordTabScreen(), 'record_tab_screen'));
    testWidgets('BattleTabScreen', (t) async => goldenTest(t, const BattleTabScreen(), 'battle_tab_screen'));
    testWidgets('AccountTabScreen', (t) async => goldenTest(t, const AccountTabScreen(), 'account_tab_screen'));
    testWidgets('SettingsScreen', (t) async => goldenTest(t, const SettingsScreen(), 'settings_screen'));
  });
}
