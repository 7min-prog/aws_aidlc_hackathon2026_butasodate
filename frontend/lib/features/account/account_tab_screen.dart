import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:buta_app/shared/theme.dart';
import 'package:buta_app/shared/ui/cloud_animation.dart';
import 'package:buta_app/shared/ui/grass_animation.dart';
import 'package:buta_app/features/home/home_screen.dart';

class AccountTabScreen extends ConsumerWidget {
  const AccountTabScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.sizeOf(context);
    final sx = size.width / 390, sy = size.height / 740;

    final items = ['バトル りれき', 'プロフィール', 'おしらせ', 'ヘルスケア れんけい', 'ライセンス', 'りようきやく', 'プライバシーポリシー', 'ログアウト', 'アカウント削除'];

    return Scaffold(
      backgroundColor: ButaColors.blue,
      body: Stack(children: [
        Positioned.fill(child: SvgPicture.asset('assets/pixel-art/backgrounds/bg-meadow.svg', fit: BoxFit.cover)),
        const Positioned.fill(child: CloudAnimation()),
        Positioned.fill(child: GrassAnimation(sx: sx, sy: sy)),
        // ヘッダー
        Positioned(top: 0, left: 0, right: 0, height: 48 * sy, child: Container(color: ButaColors.ink, alignment: Alignment.center, child: Text('せってい', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 18, color: ButaColors.paper)))),
        // リスト
        Positioned(top: 60 * sy, left: 14 * sx, child: Column(children: [
          for (int i = 0; i < items.length; i++) GestureDetector(
            onTap: () => _onTap(context, i),
            child: Container(
              width: 362 * sx, height: 48 * sy, margin: EdgeInsets.only(bottom: 2 * sy),
              padding: EdgeInsets.symmetric(horizontal: 14 * sx),
              decoration: BoxDecoration(color: ButaColors.paper, border: Border.all(color: ButaColors.ink, width: 2)),
              child: Row(children: [
                Text(items[i], style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 14, color: i >= 7 ? ButaColors.red : ButaColors.ink)),
                const Spacer(),
                Text('▶', style: TextStyle(fontSize: 12, color: ButaColors.ink)),
              ]),
            ),
          ),
        ])),
        // タブバー
        Positioned(bottom: 0, left: 0, right: 0, height: 56 * sy, child: PixelTabBar(sx: sx, sy: sy, activeIndex: 4)),
      ]),
    );
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0: context.push('/battle-history');
      case 1: context.push('/profile-edit');
      case 2: context.push('/notification-settings');
      case 3: context.push('/health-data');
      case 4: context.push('/licenses');
      case 5: context.push('/terms');
      case 6: context.push('/privacy');
      case 7: context.push('/account-manage');
      case 8: context.push('/account-manage');
    }
  }
}
