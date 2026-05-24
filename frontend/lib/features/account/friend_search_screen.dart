import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:buta_app/shared/theme.dart';
import 'package:buta_app/features/home/home_screen.dart';

class FriendSearchScreen extends StatelessWidget {
  const FriendSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final sx = size.width / 390, sy = size.height / 740;

    return Scaffold(
      backgroundColor: ButaColors.blue,
      body: Stack(children: [
        Positioned.fill(child: SvgPicture.asset('assets/pixel-art/backgrounds/bg-meadow.svg', fit: BoxFit.cover)),
        // ヘッダー
        Positioned(top: 0, left: 0, right: 0, height: 48 * sy, child: Container(
          color: ButaColors.ink,
          child: Row(children: [
            GestureDetector(onTap: () => context.pop(), child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 14 * sx),
              child: Text('◀', style: TextStyle(fontSize: 18, color: ButaColors.paper)),
            )),
            Text('フレンド けんさく', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 16, color: ButaColors.paper)),
          ]),
        )),
        // 検索入力欄
        Positioned(top: 68 * sy, left: 14 * sx, child: Container(
          width: 290 * sx, height: 36 * sy,
          padding: EdgeInsets.symmetric(horizontal: 12 * sx),
          decoration: BoxDecoration(color: ButaColors.paper, border: Border.all(color: ButaColors.ink, width: 1)),
          alignment: Alignment.centerLeft,
          child: Text('ニックネーム / ID', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 11, color: ButaColors.gray)),
        )),
        // けんさくボタン
        Positioned(top: 68 * sy, left: 312 * sx, child: Container(
          width: 64 * sx, height: 36 * sy,
          decoration: BoxDecoration(color: ButaColors.yellow, border: Border.all(color: ButaColors.ink, width: 1)),
          alignment: Alignment.center,
          child: Text('けんさく', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 10, color: ButaColors.ink)),
        )),
        // けっか
        Positioned(top: 124 * sy, left: 14 * sx, child: Text('けっか', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 11, color: ButaColors.gray))),
        // 検索結果
        Positioned(top: 144 * sy, left: 14 * sx, child: Container(
          width: 362 * sx, height: 52 * sy,
          padding: EdgeInsets.symmetric(horizontal: 12 * sx),
          decoration: BoxDecoration(color: ButaColors.paper, border: Border.all(color: ButaColors.ink, width: 1)),
          child: Row(children: [
            Container(width: 36 * sx, height: 36 * sy, color: ButaColors.blue, alignment: Alignment.center, child: Text('🐷', style: TextStyle(fontSize: 16))),
            SizedBox(width: 10 * sx),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('ぶたキング', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 12, color: ButaColors.ink)),
              Text('LV.7', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 9, color: ButaColors.gray)),
            ])),
            Container(
              width: 80 * sx, height: 28 * sy,
              decoration: BoxDecoration(color: ButaColors.green, border: Border.all(color: ButaColors.ink, width: 1)),
              alignment: Alignment.center,
              child: Text('ついか', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 10, color: ButaColors.paper)),
            ),
          ]),
        )),
        // タブバー
        Positioned(bottom: 0, left: 0, right: 0, height: 56 * sy, child: PixelTabBar(sx: sx, sy: sy, activeIndex: 3)),
      ]),
    );
  }
}
