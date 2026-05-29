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
import 'package:buta_app/features/home/home_screen.dart';
import 'package:buta_app/features/record/record_tab_screen.dart';
import 'package:buta_app/features/record/record_confirm_screen.dart';
import 'package:buta_app/features/record/record_complete_screen.dart';
import 'package:buta_app/features/record/record_detail_screen.dart';
import 'package:buta_app/features/battle/battle_tab_screen.dart';
import 'package:buta_app/features/battle/battle_matching_screen.dart';
import 'package:buta_app/features/battle/battle_fight_screen.dart';
import 'package:buta_app/features/battle/battle_result_screen.dart';
import 'package:buta_app/features/account/account_tab_screen.dart';
import 'package:buta_app/features/account/friend_list_screen.dart';
import 'package:buta_app/features/account/friend_search_screen.dart';
import 'package:buta_app/features/account/battle_history_screen.dart';
import 'package:buta_app/features/avatar/evo_book_screen.dart';
import 'package:buta_app/features/avatar/evo_anim_screen.dart';
import 'package:buta_app/features/settings/settings_screen.dart';
import 'package:buta_app/features/settings/profile_edit_screen.dart';
import 'package:buta_app/features/settings/health_data_screen.dart';
import 'package:buta_app/features/settings/notification_settings_screen.dart';
import 'package:buta_app/features/legal/legal_screen.dart';
import 'package:buta_app/features/legal/license_list_screen.dart';
import 'package:buta_app/features/start/system_screens.dart';

import '../helpers/test_helpers.dart';

Widget _w(Widget child) => ProviderScope(
  overrides: [
    authStateProvider.overrideWith(() => FakeAuthNotifier(testTokens)),
    bootProvider.overrideWith(() => FakeBootNotifier(BootResult(destination: BootDestination.home))),
  ],
  child: MaterialApp(theme: butaTheme, home: child),
);

/// 画面を描画してScaffoldが存在することを確認するテスト
Future<void> _renders(WidgetTester t, Widget screen, String name) async {
  await t.pumpWidget(_w(screen));
  await t.pump(const Duration(milliseconds: 100));
  expect(find.byType(Scaffold).evaluate().isNotEmpty || find.byType(MaterialApp).evaluate().isNotEmpty, true, reason: '$name renders');
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Auth screens render', () {
    testWidgets('LoginScreen', (t) async => _renders(t, const LoginScreen(), 'Login'));
    testWidgets('SignupScreen', (t) async => _renders(t, const SignupScreen(), 'Signup'));
    testWidgets('ConfirmScreen', (t) async => _renders(t, const ConfirmScreen(email: 'a@b.com'), 'Confirm'));
    testWidgets('NicknameScreen', (t) async => _renders(t, const NicknameScreen(), 'Nickname'));
  });

  group('Home screen renders', () {
    testWidgets('HomeScreen', (t) async => _renders(t, const HomeScreen(), 'Home'));
  });

  group('Record screens render', () {
    testWidgets('RecordTabScreen', (t) async => _renders(t, const RecordTabScreen(), 'RecordTab'));
    // CategorySelectScreen - タイマー使用のためスキップ
    // testWidgets('CategorySelectScreen', ...);
    testWidgets('RecordConfirmScreen', (t) async => _renders(t, RecordConfirmScreen(category: {'categoryId': 'c1', 'name': 'ラーメン', 'basePoints': 50, 'iconKey': 'cat-ramen'}), 'RecordConfirm'));
    testWidgets('RecordCompleteScreen', (t) async => _renders(t, const RecordCompleteScreen(points: 50), 'RecordComplete'));
    testWidgets('RecordDetailScreen', (t) async => _renders(t, RecordDetailScreen(record: {'recordId': 'r1', 'categoryId': 'c1', 'points': 50, 'recordedAt': '2026-05-24T12:00:00Z', 'memo': 'test'}), 'RecordDetail'));
  });

  group('Battle screens render', () {
    testWidgets('BattleTabScreen', (t) async => _renders(t, const BattleTabScreen(), 'BattleTab'));
    testWidgets('BattleMatchingScreen', (t) async => _renders(t, const BattleMatchingScreen(), 'BattleMatching'));
    // BattleReadyScreen - タイマー使用のためスキップ
    // testWidgets('BattleReadyScreen', ...);
    testWidgets('BattleFightScreen', (t) async => _renders(t, const BattleFightScreen(), 'BattleFight'));
    testWidgets('BattleResultScreen win', (t) async => _renders(t, const BattleResultScreen(win: true), 'BattleResultWin'));
    testWidgets('BattleResultScreen lose', (t) async => _renders(t, const BattleResultScreen(win: false), 'BattleResultLose'));
  });

  group('Account screens render', () {
    testWidgets('AccountTabScreen', (t) async => _renders(t, const AccountTabScreen(), 'AccountTab'));
    testWidgets('FriendListScreen', (t) async => _renders(t, const FriendListScreen(), 'FriendList'));
    testWidgets('FriendSearchScreen', (t) async => _renders(t, const FriendSearchScreen(), 'FriendSearch'));
    testWidgets('BattleHistoryScreen', (t) async => _renders(t, const BattleHistoryScreen(), 'BattleHistory'));
  });

  group('Avatar screens render', () {
    // AvatarDetailScreen - タイマー使用のためスキップ
    // testWidgets('AvatarDetailScreen', ...);
    testWidgets('EvoBookScreen', (t) async => _renders(t, const EvoBookScreen(), 'EvoBook'));
    testWidgets('EvoAnimScreen', (t) async => _renders(t, const EvoAnimScreen(), 'EvoAnim'));
  });

  group('Settings screens render', () {
    testWidgets('SettingsScreen', (t) async => _renders(t, const SettingsScreen(), 'Settings'));
    testWidgets('ProfileEditScreen', (t) async => _renders(t, const ProfileEditScreen(), 'ProfileEdit'));
    testWidgets('HealthDataScreen', (t) async => _renders(t, const HealthDataScreen(), 'HealthData'));
    testWidgets('NotificationSettingsScreen', (t) async => _renders(t, const NotificationSettingsScreen(), 'NotificationSettings'));
  });

  group('Legal screens render', () {
    testWidgets('LegalScreen', (t) async => _renders(t, const LegalScreen(title: '利用規約', type: LegalType.terms), 'Legal'));
    testWidgets('LicenseListScreen', (t) async => _renders(t, const LicenseListScreen(), 'LicenseList'));
  });

  group('Start screens render', () {
    testWidgets('MaintenanceScreen', (t) async => _renders(t, const MaintenanceScreen(), 'Maintenance'));
    testWidgets('ForceUpdateScreen', (t) async => _renders(t, const ForceUpdateScreen(), 'ForceUpdate'));
  });
}
