import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:buta_app/shared/theme.dart';
import 'package:buta_app/features/home/home_screen.dart';

class EvoBookScreen extends StatelessWidget {
  const EvoBookScreen({super.key});

  static const _evos = [
    {'name': 'たまご', 'lv': 0, 'unlocked': true},
    {'name': 'こぶた', 'lv': 1, 'unlocked': true},
    {'name': 'ぽっちゃり', 'lv': 3, 'unlocked': true},
    {'name': 'まるまる', 'lv': 5, 'unlocked': false},
    {'name': 'メガトン', 'lv': 8, 'unlocked': false},
    {'name': '???', 'lv': 10, 'unlocked': false},
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
            Text('しんか ずかん', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 16, color: ButaColors.paper)),
          ]),
        )),
        // 進化カードグリッド
        ...List.generate(6, (i) {
          final col = i % 3, row = i ~/ 3;
          final x = (14 + col * 124) * sx;
          final y = (68 + row * 140) * sy;
          final evo = _evos[i];
          final unlocked = evo['unlocked'] as bool;
          final bg = unlocked ? ButaColors.paper : ButaColors.bgDeep;
          final textColor = unlocked ? ButaColors.ink : ButaColors.gray;
          return Positioned(top: y, left: x, child: Container(
            width: 116 * sx, height: 130 * sy,
            decoration: BoxDecoration(color: bg, border: Border.all(color: ButaColors.ink, width: 1)),
            child: Column(children: [
              SizedBox(height: 10 * sy),
              SizedBox(width: 60 * sx, height: 60 * sy, child: CustomPaint(
                painter: unlocked ? _EvoBookPigPainter() : _LockedPigPainter(),
              )),
              SizedBox(height: 8 * sy),
              Text(evo['name'] as String, style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 10, color: textColor)),
              SizedBox(height: 2 * sy),
              Text('LV.${evo['lv']}', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 9, color: const Color(0xFFC46A85))),
            ]),
          ));
        }),
        // タブバー
        Positioned(bottom: 0, left: 0, right: 0, height: 56 * sy, child: PixelTabBar(sx: sx, sy: sy, activeIndex: 0)),
      ]),
    );
  }
}

class _EvoBookPigPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 16;
    void px(double x, double y, double w, double h, Color c) =>
        canvas.drawRect(Rect.fromLTWH(x * u, y * u, w * u, h * u), Paint()..color = c);
    px(4, 5, 8, 7, const Color(0xFFFF9BB3));
    px(5, 2, 6, 5, const Color(0xFFFF9BB3));
    px(4, 1, 2, 2, const Color(0xFFFF9BB3)); px(10, 1, 2, 2, const Color(0xFFFF9BB3));
    px(6, 4, 1, 1, const Color(0xFF3D2B4D)); px(9, 4, 1, 1, const Color(0xFF3D2B4D));
    px(7, 5, 2, 1, const Color(0xFFE8485A));
    px(5, 12, 2, 2, const Color(0xFFFF9BB3)); px(9, 12, 2, 2, const Color(0xFFFF9BB3));
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LockedPigPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 16;
    void px(double x, double y, double w, double h, Color c) =>
        canvas.drawRect(Rect.fromLTWH(x * u, y * u, w * u, h * u), Paint()..color = c);
    px(4, 5, 8, 7, const Color(0xFFB8A99A));
    px(5, 2, 6, 5, const Color(0xFFB8A99A));
    px(4, 1, 2, 2, const Color(0xFFB8A99A)); px(10, 1, 2, 2, const Color(0xFFB8A99A));
    px(7, 6, 2, 2, const Color(0xFF8A5A2B)); // ?マーク
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
