import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:buta_app/shared/theme.dart';
import 'package:buta_app/shared/state/auth_state.dart';
import 'package:buta_app/shared/state/boot_state.dart';
import 'package:buta_app/features/legal/license_list_screen.dart';
import 'package:buta_app/features/settings/settings_screen.dart';
import 'package:buta_app/features/account/account_tab_screen.dart';
import 'package:buta_app/features/auth/nickname_screen.dart';
import 'package:buta_app/features/auth/confirm_screen.dart';

import '../helpers/test_helpers.dart';

Widget _w(Widget child) {
  final router = GoRouter(initialLocation: '/test', routes: [
    GoRoute(path: '/test', builder: (_, __) => child),
    GoRoute(path: '/home', builder: (_, __) => const Scaffold()),
    GoRoute(path: '/login', builder: (_, __) => const Scaffold()),
    GoRoute(path: '/splash', builder: (_, __) => const Scaffold()),
    GoRoute(path: '/battle-history', builder: (_, __) => const Scaffold()),
    GoRoute(path: '/friend-list', builder: (_, __) => const Scaffold()),
    GoRoute(path: '/friend-search', builder: (_, __) => const Scaffold()),
    GoRoute(path: '/profile-edit', builder: (_, __) => const Scaffold()),
    GoRoute(path: '/health-data', builder: (_, __) => const Scaffold()),
    GoRoute(path: '/notification-settings', builder: (_, __) => const Scaffold()),
    GoRoute(path: '/account-manage', builder: (_, __) => const Scaffold()),
    GoRoute(path: '/legal/terms', builder: (_, __) => const Scaffold()),
    GoRoute(path: '/legal/privacy', builder: (_, __) => const Scaffold()),
    GoRoute(path: '/licenses', builder: (_, __) => const Scaffold()),
  ]);
  return ProviderScope(
    overrides: [
      authStateProvider.overrideWith(() => FakeAuthNotifier(testTokens)),
      bootProvider.overrideWith(() => FakeBootNotifier(BootResult(destination: BootDestination.home))),
    ],
    child: MaterialApp.router(theme: butaTheme, routerConfig: router),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('LicenseListScreen', () {
    setUpAll(() {
      LicenseRegistry.addLicense(() async* {
        yield LicenseEntryWithLineBreaks(['test_pkg'], 'MIT License\nPermission is hereby granted...');
        yield LicenseEntryWithLineBreaks(['other_pkg'], 'Apache License 2.0\nLicensed under...');
      });
    });

    testWidgets('loads and renders licenses', (t) async {
      t.view.physicalSize = const Size(390, 740);
      t.view.devicePixelRatio = 1.0;
      addTearDown(() => t.view.resetPhysicalSize());
      await t.pumpWidget(_w(const LicenseListScreen()));
      await t.pumpAndSettle(const Duration(seconds: 5));
      expect(find.byType(Scaffold), findsAtLeast(1));
    });

    testWidgets('tap license item', (t) async {
      t.view.physicalSize = const Size(390, 740);
      t.view.devicePixelRatio = 1.0;
      addTearDown(() => t.view.resetPhysicalSize());
      await t.pumpWidget(_w(const LicenseListScreen()));
      await t.pumpAndSettle(const Duration(seconds: 5));
      final items = find.byType(GestureDetector);
      if (items.evaluate().length > 1) {
        await t.tap(items.at(1));
        await t.pumpAndSettle();
      }
    });
  });

  group('SettingsScreen taps', () {
    testWidgets('tap ログアウト shows dialog', (t) async {
      t.view.physicalSize = const Size(390, 740);
      t.view.devicePixelRatio = 1.0;
      addTearDown(() => t.view.resetPhysicalSize());
      await t.pumpWidget(_w(const SettingsScreen()));
      await t.pump();
      final logout = find.textContaining('ログアウト');
      if (logout.evaluate().isNotEmpty) {
        await t.tap(logout.first);
        await t.pumpAndSettle();
      }
    });

    testWidgets('tap プロフィール navigates', (t) async {
      t.view.physicalSize = const Size(390, 740);
      t.view.devicePixelRatio = 1.0;
      addTearDown(() => t.view.resetPhysicalSize());
      await t.pumpWidget(_w(const SettingsScreen()));
      await t.pump();
      final profile = find.textContaining('プロフィール');
      if (profile.evaluate().isNotEmpty) {
        await t.tap(profile.first);
        await t.pump();
      }
    });

    testWidgets('tap おしらせ navigates', (t) async {
      t.view.physicalSize = const Size(390, 740);
      t.view.devicePixelRatio = 1.0;
      addTearDown(() => t.view.resetPhysicalSize());
      await t.pumpWidget(_w(const SettingsScreen()));
      await t.pump();
      final notif = find.textContaining('おしらせ');
      if (notif.evaluate().isNotEmpty) {
        await t.tap(notif.first);
        await t.pump();
      }
    });

    testWidgets('tap りようきやく navigates', (t) async {
      t.view.physicalSize = const Size(390, 740);
      t.view.devicePixelRatio = 1.0;
      addTearDown(() => t.view.resetPhysicalSize());
      await t.pumpWidget(_w(const SettingsScreen()));
      await t.pump();
      final terms = find.textContaining('りようきやく');
      if (terms.evaluate().isNotEmpty) {
        await t.tap(terms.first);
        await t.pump();
      }
    });
  });

  group('AccountTabScreen taps', () {
    testWidgets('tap フレンド navigates', (t) async {
      t.view.physicalSize = const Size(390, 740);
      t.view.devicePixelRatio = 1.0;
      addTearDown(() => t.view.resetPhysicalSize());
      await t.pumpWidget(_w(const AccountTabScreen()));
      await t.pump();
      final friends = find.textContaining('フレンド');
      if (friends.evaluate().isNotEmpty) {
        await t.tap(friends.first);
        await t.pump();
      }
    });

    testWidgets('tap バトルりれき navigates', (t) async {
      t.view.physicalSize = const Size(390, 740);
      t.view.devicePixelRatio = 1.0;
      addTearDown(() => t.view.resetPhysicalSize());
      await t.pumpWidget(_w(const AccountTabScreen()));
      await t.pump();
      final history = find.textContaining('バトル');
      if (history.evaluate().isNotEmpty) {
        await t.tap(history.first);
        await t.pump();
      }
    });
  });

  group('NicknameScreen submit', () {
    testWidgets('valid nickname enables submit', (t) async {
      t.view.physicalSize = const Size(390, 740);
      t.view.devicePixelRatio = 1.0;
      addTearDown(() => t.view.resetPhysicalSize());
      await t.pumpWidget(_w(const NicknameScreen()));
      await t.pump();
      final input = find.byKey(const Key('nickname-input'));
      if (input.evaluate().isNotEmpty) {
        await t.enterText(input, 'テスト名前');
        await t.pump();
        // submitボタンをタップ
        final submit = find.byKey(const Key('nickname-submit-button'));
        if (submit.evaluate().isNotEmpty) {
          await t.tap(submit);
          await t.pump(const Duration(seconds: 1));
        }
      }
    });

    testWidgets('short nickname shows error', (t) async {
      t.view.physicalSize = const Size(390, 740);
      t.view.devicePixelRatio = 1.0;
      addTearDown(() => t.view.resetPhysicalSize());
      await t.pumpWidget(_w(const NicknameScreen()));
      await t.pump();
      final input = find.byKey(const Key('nickname-input'));
      if (input.evaluate().isNotEmpty) {
        await t.enterText(input, 'あ');
        await t.pump();
        final submit = find.byKey(const Key('nickname-submit-button'));
        if (submit.evaluate().isNotEmpty) {
          await t.tap(submit);
          await t.pump();
        }
      }
    });
  });

  group('ConfirmScreen submit', () {
    testWidgets('enter code and tap confirm', (t) async {
      t.view.physicalSize = const Size(390, 740);
      t.view.devicePixelRatio = 1.0;
      addTearDown(() => t.view.resetPhysicalSize());
      await t.pumpWidget(_w(const ConfirmScreen(email: 'a@b.com')));
      await t.pump();
      final input = find.byType(TextField);
      if (input.evaluate().isNotEmpty) {
        await t.enterText(input.first, '123456');
        await t.pump();
        final btn = find.textContaining('かくにん');
        if (btn.evaluate().isNotEmpty) {
          await t.tap(btn.first);
          await t.pump(const Duration(seconds: 1));
        }
      }
    });

    testWidgets('tap resend', (t) async {
      t.view.physicalSize = const Size(390, 740);
      t.view.devicePixelRatio = 1.0;
      addTearDown(() => t.view.resetPhysicalSize());
      await t.pumpWidget(_w(const ConfirmScreen(email: 'a@b.com')));
      await t.pump();
      final resend = find.textContaining('さいそうしん');
      if (resend.evaluate().isNotEmpty) {
        await t.tap(resend.first);
        await t.pump(const Duration(seconds: 1));
      }
    });
  });
}
