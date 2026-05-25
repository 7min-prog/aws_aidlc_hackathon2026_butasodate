import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:buta_app/shared/theme.dart';
import 'package:buta_app/shared/state/auth_state.dart';
import 'package:buta_app/shared/state/boot_state.dart';
import 'package:buta_app/shared/ui/pixel_dialog.dart';
import 'package:buta_app/shared/ui/pixel_input.dart';
import 'package:buta_app/shared/ui/starry_background.dart';
import 'package:buta_app/features/home/widgets/avatar_card.dart';
import 'package:buta_app/features/home/widgets/summary_card.dart';
import 'package:buta_app/features/home/widgets/record_button.dart';
import 'package:buta_app/features/home/widgets/offline_banner.dart';

import '../helpers/test_helpers.dart';

Widget _w(Widget child) => ProviderScope(
  overrides: [
    authStateProvider.overrideWith(() => FakeAuthNotifier(testTokens)),
    bootProvider.overrideWith(() => FakeBootNotifier(BootResult(destination: BootDestination.home))),
  ],
  child: MaterialApp(theme: butaTheme, home: Scaffold(body: child)),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('PixelInput', () {
    testWidgets('renders', (t) async {
      final ctrl = TextEditingController();
      await t.pumpWidget(_w(PixelInput(controller: ctrl, sx: 1, sy: 1)));
      expect(find.byType(PixelInput), findsOneWidget);
    });

    testWidgets('can enter text', (t) async {
      final ctrl = TextEditingController();
      await t.pumpWidget(_w(PixelInput(controller: ctrl, sx: 1, sy: 1)));
      await t.enterText(find.byType(TextField), 'hello');
      expect(ctrl.text, 'hello');
    });

    testWidgets('obscure mode', (t) async {
      final ctrl = TextEditingController();
      await t.pumpWidget(_w(PixelInput(controller: ctrl, sx: 1, sy: 1, obscure: true)));
      expect(find.byType(PixelInput), findsOneWidget);
    });
  });

  group('PixelActionButton', () {
    testWidgets('renders with label', (t) async {
      await t.pumpWidget(_w(const PixelActionButton(width: 200, height: 44, label: 'テスト')));
      expect(find.text('テスト'), findsOneWidget);
    });

    testWidgets('onTap fires', (t) async {
      var tapped = false;
      await t.pumpWidget(_w(PixelActionButton(width: 200, height: 44, label: 'tap', onTap: () => tapped = true)));
      await t.tap(find.text('tap'));
      expect(tapped, true);
    });

    testWidgets('disabled state', (t) async {
      var tapped = false;
      await t.pumpWidget(_w(PixelActionButton(width: 200, height: 44, label: 'x', enabled: false, onTap: () => tapped = true)));
      await t.tap(find.text('x'));
      expect(tapped, false);
    });
  });

  group('PixelDialog', () {
    testWidgets('showPixelAlert shows message', (t) async {
      await t.pumpWidget(_w(Builder(builder: (ctx) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showPixelAlert(ctx, message: 'テストメッセージ');
        });
        return const SizedBox();
      })));
      await t.pumpAndSettle();
      expect(find.text('テストメッセージ'), findsOneWidget);
    });

    testWidgets('showPixelConfirm shows buttons', (t) async {
      await t.pumpWidget(_w(Builder(builder: (ctx) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showPixelConfirm(ctx, message: '削除しますか？');
        });
        return const SizedBox();
      })));
      await t.pumpAndSettle();
      expect(find.text('削除しますか？'), findsOneWidget);
      expect(find.text('けす'), findsOneWidget);
      expect(find.text('やめる'), findsOneWidget);
    });
  });

  group('Home Widgets', () {
    testWidgets('AvatarCard', (t) async {
      await t.pumpWidget(_w(const AvatarCard()));
      await t.pump();
      expect(find.byType(AvatarCard), findsOneWidget);
    });

    testWidgets('SummaryCard', (t) async {
      await t.pumpWidget(_w(const SummaryCard()));
      await t.pump();
      expect(find.byType(SummaryCard), findsOneWidget);
    });

    testWidgets('RecordButton', (t) async {
      await t.pumpWidget(_w(const RecordButton()));
      await t.pump();
      expect(find.byType(RecordButton), findsOneWidget);
    });

    testWidgets('OfflineBanner', (t) async {
      await t.pumpWidget(_w(const OfflineBanner()));
      await t.pump();
      expect(find.byType(OfflineBanner), findsOneWidget);
    });
  });

  group('StarryBackground', () {
    testWidgets('renders', (t) async {
      await t.pumpWidget(_w(const StarryBackground(seed: 42)));
      await t.pump();
      expect(find.byType(StarryBackground), findsOneWidget);
    });
  });
}
