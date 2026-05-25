import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:buta_app/shared/theme.dart';
import 'package:buta_app/shared/ui/audience_animation.dart';
import 'package:buta_app/shared/ui/cloud_animation.dart';

class BattleReadyScreen extends StatefulWidget {
  const BattleReadyScreen({super.key});
  @override
  State<BattleReadyScreen> createState() => _BattleReadyScreenState();
}

class _BattleReadyScreenState extends State<BattleReadyScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) context.go('/battle-fight');
    });
  }

  @override
  void dispose() { _pulse.dispose(); super.dispose(); }

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
        // VS (パルスアニメーション)
        Positioned(top: 60 * sy, left: 55 * sx, width: 280 * sx, child: AnimatedBuilder(
          animation: _pulse,
          builder: (_, __) => Transform.scale(
            scale: 1.0 + _pulse.value * 0.15,
            child: Text('VS', textAlign: TextAlign.center, style: TextStyle(fontFamily: kFontPressStart2P, fontSize: 32, color: ButaColors.yellow)),
          ),
        )),
        // 自分のぶた
        Positioned(top: 200 * sy, left: 50 * sx, child: SizedBox(
          width: 120 * sx, height: 120 * sy,
          child: CustomPaint(painter: _BattlePigPainter(color: const Color(0xFFFF9BB3))),
        )),
        // 相手のぶた
        Positioned(top: 200 * sy, left: 220 * sx, child: SizedBox(
          width: 120 * sx, height: 120 * sy,
          child: CustomPaint(painter: _BattlePigPainter(color: const Color(0xFF5A8ED1))),
        )),
        // 自分の名前
        Positioned(top: 330 * sy, left: 60 * sx, child: Text('じぶん LV.3', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 12, color: ButaColors.paper))),
        // 相手の名前
        Positioned(top: 330 * sy, left: 230 * sx, child: Text('あいて LV.5', style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 12, color: ButaColors.paper))),
        // まもなく開始
        Positioned(top: 550 * sy, left: 0, right: 0, child: Text('まもなく かいし...', textAlign: TextAlign.center, style: TextStyle(fontFamily: kFontDotGothic16, fontSize: 14, color: ButaColors.ink))),
      ]),
    );
  }
}

class _BattlePigPainter extends CustomPainter {
  _BattlePigPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 16;
    void px(double x, double y, double w, double h, Color c) =>
        canvas.drawRect(Rect.fromLTWH(x * u, y * u, w * u, h * u), Paint()..color = c);
    // body
    px(4, 5, 8, 7, color);
    // head
    px(5, 2, 6, 5, color);
    // ears
    px(4, 1, 2, 2, color); px(10, 1, 2, 2, color);
    // eyes
    px(6, 4, 1, 1, const Color(0xFF3D2B4D)); px(9, 4, 1, 1, const Color(0xFF3D2B4D));
    // snout
    px(7, 5, 2, 1, const Color(0xFFE8485A));
    // legs
    px(5, 12, 2, 2, color); px(9, 12, 2, 2, color);
    // tail
    px(12, 6, 1, 1, color); px(13, 5, 1, 1, color); px(13, 7, 1, 1, color);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
