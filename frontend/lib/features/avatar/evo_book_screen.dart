import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:buta_app/shared/theme.dart';
import 'package:buta_app/shared/ui/widgets.dart';
import 'package:buta_app/shared/ui/pixel_tab_bar.dart';
import 'package:buta_app/shared/ui/cloud_animation.dart';
import 'package:buta_app/shared/ui/grass_animation.dart';

class EvoBookScreen extends StatelessWidget {
  const EvoBookScreen({super.key});

  static const _evos = [
    {'name': 'たまご', 'lv': 0, 'unlocked': true},
    {'name': 'こぶた', 'lv': 1, 'unlocked': true},
    {'name': 'ぽっちゃり', 'lv': 3, 'unlocked': true},
    {'name': 'まるまる', 'lv': 5, 'unlocked': false},
    {'name': 'メガトン', 'lv': 8, 'unlocked': false},
    {'name': 'ぶたキング', 'lv': 10, 'unlocked': false},
    {'name': 'ねむりぶた', 'lv': 12, 'unlocked': false},
    {'name': 'はやあしぶた', 'lv': 14, 'unlocked': false},
    {'name': 'てつぶた', 'lv': 16, 'unlocked': false},
    {'name': 'ほのおぶた', 'lv': 18, 'unlocked': false},
    {'name': 'こおりぶた', 'lv': 20, 'unlocked': false},
    {'name': 'かみなりぶた', 'lv': 22, 'unlocked': false},
    {'name': 'どくぶた', 'lv': 24, 'unlocked': false},
    {'name': 'ひかりぶた', 'lv': 26, 'unlocked': false},
    {'name': 'やみぶた', 'lv': 28, 'unlocked': false},
    {'name': 'きぞくぶた', 'lv': 30, 'unlocked': false},
    {'name': 'かいぞくぶた', 'lv': 32, 'unlocked': false},
    {'name': 'にんじゃぶた', 'lv': 34, 'unlocked': false},
    {'name': 'まほうぶた', 'lv': 36, 'unlocked': false},
    {'name': 'ロボぶた', 'lv': 38, 'unlocked': false},
    {'name': 'ドラゴンぶた', 'lv': 40, 'unlocked': false},
    {'name': 'てんしぶた', 'lv': 42, 'unlocked': false},
    {'name': 'あくまぶた', 'lv': 44, 'unlocked': false},
    {'name': 'うちゅうぶた', 'lv': 46, 'unlocked': false},
    {'name': 'おうさまぶた', 'lv': 48, 'unlocked': false},
    {'name': 'ゴッドぶた', 'lv': 50, 'unlocked': false},
    {'name': 'すいちゅうぶた', 'lv': 52, 'unlocked': false},
    {'name': 'そらとぶぶた', 'lv': 54, 'unlocked': false},
    {'name': 'きょだいぶた', 'lv': 56, 'unlocked': false},
    {'name': 'ちびぶた', 'lv': 58, 'unlocked': false},
    {'name': 'ゴールドぶた', 'lv': 60, 'unlocked': false},
    {'name': 'クリスタルぶた', 'lv': 62, 'unlocked': false},
    {'name': 'シャドウぶた', 'lv': 64, 'unlocked': false},
    {'name': 'レインボーぶた', 'lv': 66, 'unlocked': false},
    {'name': 'さいきょうぶた', 'lv': 68, 'unlocked': false},
    {'name': 'でんせつぶた', 'lv': 70, 'unlocked': false},
    {'name': 'しんわぶた', 'lv': 72, 'unlocked': false},
    {'name': 'むげんぶた', 'lv': 74, 'unlocked': false},
    {'name': 'さいしゅうぶた', 'lv': 76, 'unlocked': false},
    {'name': '???', 'lv': 99, 'unlocked': false},
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final sx = size.width / 390, sy = size.height / 740;

    return Scaffold(
      backgroundColor: ButaColors.blue,
      appBar: const PixelAppBar(title: 'しんか ずかん', showBack: true),
      bottomNavigationBar: SafeArea(child: PixelTabBar(sx: sx, sy: sy, activeIndex: 0)),
      body: Stack(children: [
        Positioned.fill(child: SvgPicture.asset('assets/pixel-art/backgrounds/bg-meadow.svg', fit: BoxFit.cover)),
        const Positioned.fill(child: CloudAnimation()),
        Positioned.fill(child: GrassAnimation(sx: sx, sy: sy)),
        Positioned.fill(child: GridView.builder(
          padding: EdgeInsets.all(14 * sx),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10 * sy,
            crossAxisSpacing: 8 * sx,
            childAspectRatio: 116 / 130,
          ),
          itemCount: _evos.length,
          itemBuilder: (context, i) {
            final evo = _evos[i];
            final unlocked = evo['unlocked'] as bool;
            final bg = unlocked ? ButaColors.paper : ButaColors.bgDeep;
            final textColor = unlocked ? ButaColors.ink : ButaColors.gray;
            return Container(
              decoration: BoxDecoration(color: bg, border: Border.all(color: ButaColors.ink, width: 1)),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                SizedBox(width: 50, height: 50, child: CustomPaint(
                  painter: unlocked ? _EvoBookPigPainter() : _LockedPigPainter(),
                )),
                const SizedBox(height: 6),
                Text(evo['name'] as String, style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 10, color: textColor)),
                const SizedBox(height: 2),
                Text('LV.${evo['lv']}', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 9, color: const Color(0xFFC46A85))),
              ]),
            );
          },
        )),
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