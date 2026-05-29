import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:buta_app/features/auth/login_screen.dart';
import 'package:buta_app/shared/state/boot_state.dart';

import '../helpers/test_helpers.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('LoginScreen', () {
    Widget build() => testApp(child: const LoginScreen(), bootResult: BootResult(destination: BootDestination.login));

    testWidgets('Scaffold生成', (t) async {
      await t.pumpWidget(build());
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('ログインテキスト表示', (t) async {
      await t.pumpWidget(build());
      expect(find.text('ログイン'), findsAtLeast(1));
    });

    testWidgets('メールアドレスラベル表示', (t) async {
      await t.pumpWidget(build());
      expect(find.text('メールアドレス'), findsOneWidget);
    });

    testWidgets('パスワードラベル表示', (t) async {
      await t.pumpWidget(build());
      expect(find.text('パスワード'), findsAtLeast(1));
    });

    testWidgets('サインアップリンク表示', (t) async {
      await t.pumpWidget(build());
      expect(find.text('アカウントを つくる →'), findsOneWidget);
    });
  });
}
