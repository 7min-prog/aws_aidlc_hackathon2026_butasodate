import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:buta_app/shared/theme.dart';
import 'package:buta_app/shared/ui/widgets.dart';
import 'package:buta_app/shared/ui/pixel_tab_bar.dart';

class BattleHistoryScreen extends StatelessWidget {
  const BattleHistoryScreen({super.key});

  static const _history = [
    {'opponent': 'まるまる', 'result': 'WIN', 'rp': '+15'},
    {'opponent': 'ぶたキング', 'result': 'LOSE', 'rp': '-5'},
    {'opponent': 'こぶたろう', 'result': 'WIN', 'rp': '+12'},
    {'opponent': 'メガトン', 'result': 'LOSE', 'rp': '-8'},
    {'opponent': 'まるまる', 'result': 'WIN', 'rp': '+15'},
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final sx = size.width / 390, sy = size.height / 740;

    return Scaffold(
      backgroundColor: ButaColors.blue,
      appBar: const PixelAppBar(title: 'バトル りれき', showBack: true),
      bottomNavigationBar: SafeArea(child: PixelTabBar(sx: sx, sy: sy, activeIndex: 2)),
      body: Stack(children: [
        Positioned.fill(child: SvgPicture.asset('assets/pixel-art/backgrounds/bg-meadow.svg', fit: BoxFit.cover)),
        // 勝率
        Positioned(top: 12 * sy, left: 14 * sx, width: 362 * sx, child: Text(
          'しょうりつ: 65%  (13勝 / 7敗)',
          style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 12, color: ButaColors.ink),
        )),
        // 履歴リスト
        ...List.generate(_history.length, (i) {
          final h = _history[i];
          final isWin = h['result'] == 'WIN';
          return Positioned(
            top: (96 + i * 52) * sy, left: 14 * sx,
            child: Container(
              width: 362 * sx, height: 48 * sy,
              padding: EdgeInsets.symmetric(horizontal: 12 * sx),
              decoration: BoxDecoration(color: ButaColors.paper, border: Border.all(color: ButaColors.ink, width: 1)),
              child: Row(children: [
                Container(
                  width: 40 * sx, height: 20 * sy,
                  decoration: BoxDecoration(color: isWin ? ButaColors.green : ButaColors.red),
                  alignment: Alignment.center,
                  child: Text(h['result']!, style: TextStyle(fontFamily: kFontPressStart2P, fontSize: 8, color: ButaColors.paper)),
                ),
                SizedBox(width: 10 * sx),
                Expanded(child: Text('vs ${h['opponent']}', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 11, color: ButaColors.ink))),
                Text(h['rp']!, style: TextStyle(fontFamily: kFontPressStart2P, fontSize: 10, color: isWin ? ButaColors.green : ButaColors.red)),
              ]),
            ),
          );
        }),
        // タブバー
      ]),
    );
  }
}