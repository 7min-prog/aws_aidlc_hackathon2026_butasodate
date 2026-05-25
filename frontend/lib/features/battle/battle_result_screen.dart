import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:buta_app/shared/theme.dart';
import 'package:buta_app/shared/ui/audience_animation.dart';
import 'package:buta_app/shared/ui/cloud_animation.dart';

class BattleResultScreen extends StatelessWidget {
  const BattleResultScreen({super.key, this.win = true});
  final bool win;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final sx = size.width / 390, sy = size.height / 740;

    return Scaffold(
      backgroundColor: ButaColors.blue,
      body: Stack(children: [
        Positioned.fill(child: SvgPicture.asset('assets/pixel-art/backgrounds/bg-arena.svg', fit: BoxFit.cover)),
        const Positioned.fill(child: CloudAnimation()),
        const Positioned.fill(child: AudienceAnimation()),
        // 結果
        Positioned(top: 100 * sy, left: 55 * sx, width: 280 * sx, child: Text(
          win ? 'WIN!' : 'LOSE...',
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: kFontPressStart2P, fontSize: 32, color: ButaColors.yellow),
        )),
        // メッセージ
        Positioned(top: 160 * sy, left: 55 * sx, width: 280 * sx, child: Text(
          win ? 'ぽっちゃり の しょうり！' : 'ぽっちゃり は まけた...',
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 14, color: ButaColors.ink),
        )),
        // ポイント
        Positioned(top: 220 * sy, left: 120 * sx, child: Container(
          width: 150 * sx, height: 50 * sy,
          decoration: BoxDecoration(color: win ? ButaColors.green : ButaColors.red),
          alignment: Alignment.center,
          child: Text(win ? '+15 RP' : '-5 RP', style: TextStyle(fontFamily: kFontPressStart2P, fontSize: 16, color: ButaColors.ink)),
        )),
        // ランキング
        Positioned(top: 300 * sy, left: 55 * sx, width: 280 * sx, child: Text(
          'ランキング: 1250 → ${win ? "1265" : "1245"}',
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 12, color: ButaColors.gray),
        )),
        // もう1回ボタン
        Positioned(top: 400 * sy, left: 55 * sx, child: GestureDetector(
          onTap: () => context.go('/battle-matching'),
          child: Container(
            width: 280 * sx, height: 44 * sy,
            decoration: BoxDecoration(color: ButaColors.yellow, border: Border.all(color: ButaColors.ink, width: 2)),
            alignment: Alignment.center,
            child: Row(mainAxisSize: MainAxisSize.min, children: [SvgPicture.asset('assets/pixel-art/icons/play.svg', width: 14, height: 14), const SizedBox(width: 4), Text('もう1かい', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 14, color: ButaColors.ink))]),
          ),
        )),
        // ホームへ戻るボタン
        Positioned(top: 460 * sy, left: 55 * sx, child: GestureDetector(
          onTap: () => context.go('/battle'),
          child: Container(
            width: 280 * sx, height: 44 * sy,
            decoration: BoxDecoration(color: ButaColors.paper, border: Border.all(color: ButaColors.ink, width: 2)),
            alignment: Alignment.center,
            child: Text('ホームへ もどる', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 14, color: ButaColors.ink)),
          ),
        )),
      ]),
    );
  }
}
