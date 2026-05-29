import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:buta_app/shared/theme.dart';
import 'package:buta_app/shared/ui/widgets.dart';
import 'package:buta_app/shared/ui/cloud_animation.dart';
import 'package:buta_app/shared/ui/grass_animation.dart';
import 'package:buta_app/shared/ui/pixel_tab_bar.dart';
import 'package:buta_app/shared/services/api_client.dart';
import 'package:buta_app/shared/state/auth_state.dart';

class AccountTabScreen extends ConsumerWidget {
  const AccountTabScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.sizeOf(context);
    final sx = size.width / 390, sy = size.height / 740;

    final items = ['プロフィール', 'おしらせ', 'ヘルスケア れんけい', 'ライセンス', 'りようきやく', 'プライバシーポリシー', 'ログアウト', 'アカウント削除'];

    return Scaffold(
      backgroundColor: ButaColors.blue,
      appBar: const PixelAppBar(title: 'せってい'),
      bottomNavigationBar: SafeArea(child: PixelTabBar(sx: sx, sy: sy, activeIndex: 4)),
      body: Stack(children: [
        Positioned.fill(child: SvgPicture.asset('assets/pixel-art/backgrounds/bg-meadow.svg', fit: BoxFit.cover)),
        const Positioned.fill(child: CloudAnimation()),
        Positioned.fill(child: GrassAnimation(sx: sx, sy: sy)),
        // ヘッダー
        // リスト
        Positioned(top: 12 * sy, left: 14 * sx, child: Column(children: [
          for (int i = 0; i < items.length; i++) GestureDetector(
            onTap: () => _onTap(context, i),
            child: Container(
              width: 362 * sx, height: 48 * sy, margin: EdgeInsets.only(bottom: 2 * sy),
              padding: EdgeInsets.symmetric(horizontal: 14 * sx),
              decoration: BoxDecoration(color: ButaColors.paper, border: Border.all(color: ButaColors.ink, width: 2)),
              child: Row(children: [
                Text(items[i], style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 14, color: i >= 7 ? ButaColors.red : ButaColors.ink)),
                const Spacer(),
                SvgPicture.asset('assets/pixel-art/icons/play.svg', width: 12, height: 12),
              ]),
            ),
          ),
        ])),
        // タブバー
      ]),
    );
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0: context.push('/profile-edit');
      case 1: context.push('/notification-settings');
      case 2: context.push('/health-data');
      case 3: context.push('/licenses');
      case 4: context.push('/terms');
      case 5: context.push('/privacy');
      case 6: _confirmLogout(context);
      case 7: _confirmDeleteAccount(context);
    }
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 310, height: 280,
            decoration: BoxDecoration(
              color: ButaColors.paper,
              border: Border.all(color: ButaColors.ink2, width: 4),
            ),
            child: Stack(children: [
              // 内枠
              Positioned(left: 8, top: 8, right: 8, bottom: 8, child: Container(
                decoration: BoxDecoration(border: Border.all(color: ButaColors.blue, width: 2)),
              )),
              // 四隅装飾
              Positioned(left: 4, top: 4, child: Container(width: 8, height: 8, color: ButaColors.blue)),
              Positioned(right: 4, top: 4, child: Container(width: 8, height: 8, color: ButaColors.blue)),
              Positioned(left: 4, bottom: 4, child: Container(width: 8, height: 8, color: ButaColors.blue)),
              Positioned(right: 4, bottom: 4, child: Container(width: 8, height: 8, color: ButaColors.blue)),
              // タイトルバー
              Positioned(left: 25, top: 36, right: 25, height: 28, child: Container(color: ButaColors.blue.withValues(alpha: 0.15))),
              // アイコン背景
              Positioned(left: 30, top: 34, child: Container(
                width: 32, height: 32,
                decoration: BoxDecoration(color: ButaColors.blue, border: Border.all(color: ButaColors.ink2, width: 2)),
                alignment: Alignment.center,
                child: const Text('？', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 16, color: ButaColors.paper)),
              )),
              // タイトル
              Positioned(left: 75, top: 40, child: const Text('ログアウト', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 14, color: ButaColors.ink))),
              // 区切り線
              Positioned(left: 35, top: 75, right: 35, height: 3, child: Container(color: ButaColors.blue)),
              // メッセージ
              Positioned(left: 45, top: 100, child: const Text('ほんとうに\nログアウトしますか？', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 13, color: ButaColors.ink2, height: 1.6))),
              // ボタン: はい
              Positioned(left: 20, bottom: 30, child: GestureDetector(
                onTap: () {
                  Navigator.pop(ctx);
                  ProviderScope.containerOf(context).read(authStateProvider.notifier).logout();
                  GoRouter.of(context).go('/login');
                },
                child: Container(
                  width: 120, height: 40,
                  decoration: BoxDecoration(color: ButaColors.blue, border: Border.all(color: ButaColors.ink2, width: 2)),
                  alignment: Alignment.center,
                  child: const Text('はい', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 14, color: ButaColors.paper)),
                ),
              )),
              // ボタン: いいえ
              Positioned(right: 20, bottom: 30, child: GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  width: 120, height: 40,
                  decoration: BoxDecoration(color: const Color(0xFFB8A99A), border: Border.all(color: ButaColors.ink2, width: 2)),
                  alignment: Alignment.center,
                  child: const Text('いいえ', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 14, color: ButaColors.paper)),
                ),
              )),
            ]),
          ),
        ),
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 310, height: 280,
            decoration: BoxDecoration(
              color: ButaColors.paper,
              border: Border.all(color: ButaColors.ink2, width: 4),
            ),
            child: Stack(children: [
              Positioned(left: 8, top: 8, right: 8, bottom: 8, child: Container(
                decoration: BoxDecoration(border: Border.all(color: ButaColors.red, width: 2)),
              )),
              Positioned(left: 4, top: 4, child: Container(width: 8, height: 8, color: ButaColors.red)),
              Positioned(right: 4, top: 4, child: Container(width: 8, height: 8, color: ButaColors.red)),
              Positioned(left: 4, bottom: 4, child: Container(width: 8, height: 8, color: ButaColors.red)),
              Positioned(right: 4, bottom: 4, child: Container(width: 8, height: 8, color: ButaColors.red)),
              Positioned(left: 25, top: 36, right: 25, height: 28, child: Container(color: ButaColors.red.withValues(alpha: 0.15))),
              Positioned(left: 30, top: 34, child: Container(
                width: 32, height: 32,
                decoration: BoxDecoration(color: ButaColors.red, border: Border.all(color: ButaColors.ink2, width: 2)),
                alignment: Alignment.center,
                child: const Text('！', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 16, color: ButaColors.paper)),
              )),
              Positioned(left: 75, top: 40, child: const Text('アカウントさくじょ', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 14, color: ButaColors.ink))),
              Positioned(left: 35, top: 75, right: 35, height: 3, child: Container(color: ButaColors.red)),
              Positioned(left: 45, top: 100, child: const Text('さくじょすると\nもとに もどせません！', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 13, color: ButaColors.ink2, height: 1.6))),
              Positioned(left: 20, bottom: 30, child: GestureDetector(
                onTap: () async {
                  Navigator.pop(ctx);
                  final container = ProviderScope.containerOf(context);
                  final router = GoRouter.of(context);
                  try {
                    final api = ProviderScope.containerOf(context).read(apiClientProvider);
                    await api.delete('/account');
                  } catch (_) {}
                  container.read(authStateProvider.notifier).logout();
                  router.go('/login');
                },
                child: Container(
                  width: 120, height: 40,
                  decoration: BoxDecoration(color: ButaColors.red, border: Border.all(color: ButaColors.ink2, width: 2)),
                  alignment: Alignment.center,
                  child: const Text('さくじょする', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 12, color: ButaColors.paper)),
                ),
              )),
              Positioned(right: 20, bottom: 30, child: GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  width: 120, height: 40,
                  decoration: BoxDecoration(color: const Color(0xFFB8A99A), border: Border.all(color: ButaColors.ink2, width: 2)),
                  alignment: Alignment.center,
                  child: const Text('やめる', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 14, color: ButaColors.paper)),
                ),
              )),
            ]),
          ),
        ),
      ),
    );
  }
}
