import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:buta_app/shared/theme.dart';
import 'package:buta_app/features/home/home_screen.dart';

class FriendListScreen extends StatelessWidget {
  const FriendListScreen({super.key});

  static const _friends = [
    {'name': 'まるまる', 'lv': 5},
    {'name': 'ぶたキング', 'lv': 7},
    {'name': 'こぶたろう', 'lv': 2},
    {'name': 'メガトン', 'lv': 8},
  ];

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
            Text('フレンド', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 16, color: ButaColors.paper)),
          ]),
        )),
        // ＋ついかボタン
        Positioned(top: 68 * sy, left: 300 * sx, child: GestureDetector(
          onTap: () => context.push('/friend-search'),
          child: Container(
            width: 76 * sx, height: 32 * sy,
            decoration: BoxDecoration(color: ButaColors.paper, border: Border.all(color: ButaColors.ink, width: 1)),
            alignment: Alignment.center,
            child: Text('＋ ついか', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 10, color: ButaColors.ink)),
          ),
        )),
        // フレンドリスト
        ...List.generate(_friends.length, (i) => Positioned(
          top: (110 + i * 60) * sy, left: 14 * sx,
          child: Container(
            width: 362 * sx, height: 48 * sy,
            padding: EdgeInsets.symmetric(horizontal: 12 * sx),
            decoration: BoxDecoration(color: ButaColors.paper, border: Border.all(color: ButaColors.ink, width: 1)),
            child: Row(children: [
              // ぶたアイコン
              Container(width: 36 * sx, height: 36 * sy, color: ButaColors.pink, alignment: Alignment.center, child: Text('🐷', style: TextStyle(fontSize: 16))),
              SizedBox(width: 10 * sx),
              Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(_friends[i]['name'] as String, style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 12, color: ButaColors.ink)),
                Text('LV.${_friends[i]['lv']}', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 9, color: ButaColors.gray)),
              ]),
            ]),
          ),
        )),
        // タブバー
        Positioned(bottom: 0, left: 0, right: 0, height: 56 * sy, child: PixelTabBar(sx: sx, sy: sy, activeIndex: 3)),
      ]),
    );
  }
}
