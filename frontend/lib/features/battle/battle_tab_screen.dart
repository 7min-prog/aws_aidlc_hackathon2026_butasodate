import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:buta_app/shared/theme.dart';
import 'package:buta_app/shared/ui/cloud_animation.dart';
import 'package:buta_app/shared/ui/grass_animation.dart';
import 'package:buta_app/features/home/home_screen.dart';
import 'package:buta_app/features/battle/battle_invite_dialog.dart';

class BattleTabScreen extends ConsumerWidget {
  const BattleTabScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.sizeOf(context);
    final sx = size.width / 390, sy = size.height / 740;

    return Scaffold(
      backgroundColor: ButaColors.blue,
      body: Stack(children: [
        Positioned.fill(child: SvgPicture.asset('assets/pixel-art/backgrounds/bg-meadow.svg', fit: BoxFit.cover)),
        const Positioned.fill(child: CloudAnimation()),
        Positioned.fill(child: GrassAnimation(sx: sx, sy: sy)),
        // ヘッダー
        Positioned(top: 0, left: 0, right: 0, height: 48 * sy, child: Container(color: ButaColors.ink, alignment: Alignment.center, child: Text('バトル', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 18, color: ButaColors.paper)))),
        // ランダムマッチボタン
        Positioned(top: 68 * sy, left: 14 * sx, child: GestureDetector(
          onTap: () => context.go('/battle-matching'),
          child: Container(
            width: 362 * sx, height: 80 * sy,
            decoration: BoxDecoration(color: ButaColors.red, border: Border.all(color: ButaColors.ink, width: 2)),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('⚔', style: TextStyle(fontSize: 24, color: ButaColors.paper)),
              Text('ランダムマッチ', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 18, color: ButaColors.paper)),
            ]),
          ),
        )),
        // フレンド対戦ボタン（招待デモ）
        Positioned(top: 168 * sy, left: 14 * sx, child: GestureDetector(
          onTap: () async {
            final accepted = await showBattleInviteDialog(context, opponent: 'まるまる');
            if (accepted == true && context.mounted) context.go('/battle-matching');
          },
          child: Container(
            width: 362 * sx, height: 60 * sy,
            decoration: BoxDecoration(color: ButaColors.paper, border: Border.all(color: ButaColors.ink, width: 2)),
            alignment: Alignment.center,
            child: Text('📩 しょうたい デモ', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 16, color: ButaColors.ink)),
          ),
        )),
        // バトル履歴タイトル
        Positioned(top: 260 * sy, left: 14 * sx, child: Text('バトル りれき', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 14, color: ButaColors.ink))),
        // 履歴カード
        Positioned(top: 290 * sy, left: 14 * sx, child: Container(
          width: 362 * sx, height: 48 * sy,
          padding: EdgeInsets.symmetric(horizontal: 12 * sx),
          decoration: BoxDecoration(color: ButaColors.paper, border: Border.all(color: ButaColors.ink, width: 1)),
          alignment: Alignment.center,
          child: Text('まだ りれきが ないよ', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 12, color: ButaColors.gray)),
        )),
        // タブバー
        Positioned(bottom: 0, left: 0, right: 0, height: 56 * sy, child: PixelTabBar(sx: sx, sy: sy, activeIndex: 2)),
      ]),
    );
  }
}
