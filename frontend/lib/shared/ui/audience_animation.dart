import 'dart:math';
import 'package:flutter/material.dart';
import 'package:buta_app/shared/theme.dart';

class AudienceAnimation extends StatefulWidget {
  const AudienceAnimation({super.key, this.sx = 1.0, this.sy = 1.0});
  final double sx, sy;
  @override
  State<AudienceAnimation> createState() => _AudienceAnimationState();
}

class _AudienceAnimationState extends State<AudienceAnimation> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(size: Size.infinite, painter: _AudiencePainter(_ctrl.value)),
    );
  }
}

class _AudiencePainter extends CustomPainter {
  _AudiencePainter(this.t);
  final double t;
  static final _colors = [ButaColors.pink, ButaColors.green, ButaColors.yellow, ButaColors.blue, ButaColors.red];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));
    // 背景SVGと同じBoxFit.coverスケーリングを再現
    // SVG viewBox: -200, 0, 800, 740
    const svgW = 800.0, svgH = 740.0;
    final scale = max(size.width / svgW, size.height / svgH);
    final offsetX = (size.width - svgW * scale) / 2;
    final offsetY = (size.height - svgH * scale) / 2;

    // SVG座標→画面座標変換
    double toX(double svgX) => (svgX + 200) * scale + offsetX; // viewBox starts at -200
    double toY(double svgY) => svgY * scale + offsetY;

    final dotSize = 8 * scale;
    final rng = Random(42);

    // 観客席の位置（SVG座標 y=400, y=430、x=50〜320）
    for (int row = 0; row < 2; row++) {
      final baseY = row == 0 ? 398.0 : 426.0;
      for (int i = 0; i < 14; i++) {
        final svgX = 45.0 + i * 20.0 + rng.nextDouble() * 14 - 4;
        final yJitter = rng.nextDouble() * 6 - 3;
        final color = _colors[(i + row * 3) % _colors.length];
        final phase = rng.nextDouble() * 6.28;
        final speed = 0.7 + rng.nextDouble() * 0.6;
        final amp = 4.0 + rng.nextDouble() * 4.0;
        final bounce = sin(t * 2 * pi * speed + phase) * amp * scale;
        canvas.drawRect(
          Rect.fromLTWH(toX(svgX), toY(baseY + yJitter) + bounce, dotSize, dotSize),
          Paint()..color = color,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AudiencePainter old) => true;
}
