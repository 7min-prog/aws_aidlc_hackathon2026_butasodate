import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:buta_app/features/account/account_tab_screen.dart';
import 'package:buta_app/shared/state/auth_state.dart';

import '../helpers/test_helpers.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({'access_token': 'a', 'refresh_token': 'r'}));

  testWidgets('AccountTabScreen renders all menu items', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [authStateProvider.overrideWith(() => FakeAuthNotifier(testTokens))],
      child: MaterialApp(home: const AccountTabScreen()),
    ));
    for (var i = 0; i < 10; i++) { await tester.pump(const Duration(milliseconds: 100)); }

    expect(find.text('プロフィール'), findsOneWidget);
    expect(find.text('おしらせ'), findsOneWidget);
    expect(find.text('ヘルスケア れんけい'), findsOneWidget);
    expect(find.text('ライセンス'), findsOneWidget);
    expect(find.text('ログアウト'), findsOneWidget);
    expect(find.text('アカウント削除'), findsOneWidget);
  });

  testWidgets('logout dialog shows and can be dismissed', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [authStateProvider.overrideWith(() => FakeAuthNotifier(testTokens))],
      child: MaterialApp(home: const AccountTabScreen()),
    ));
    for (var i = 0; i < 10; i++) { await tester.pump(const Duration(milliseconds: 100)); }

    await tester.tap(find.text('ログアウト'));
    for (var i = 0; i < 5; i++) { await tester.pump(const Duration(milliseconds: 100)); }

    expect(find.text('ほんとうに\nログアウトしますか？'), findsOneWidget);
    await tester.tap(find.text('いいえ'));
    for (var i = 0; i < 5; i++) { await tester.pump(const Duration(milliseconds: 100)); }
    expect(find.text('ほんとうに\nログアウトしますか？'), findsNothing);
  });

  testWidgets('delete account dialog shows and can be dismissed', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [authStateProvider.overrideWith(() => FakeAuthNotifier(testTokens))],
      child: MaterialApp(home: const AccountTabScreen()),
    ));
    for (var i = 0; i < 10; i++) { await tester.pump(const Duration(milliseconds: 100)); }

    await tester.tap(find.text('アカウント削除'));
    for (var i = 0; i < 5; i++) { await tester.pump(const Duration(milliseconds: 100)); }

    expect(find.text('さくじょすると\nもとに もどせません！'), findsOneWidget);
    await tester.tap(find.text('やめる'));
    for (var i = 0; i < 5; i++) { await tester.pump(const Duration(milliseconds: 100)); }
    expect(find.text('さくじょすると\nもとに もどせません！'), findsNothing);
  });
}
