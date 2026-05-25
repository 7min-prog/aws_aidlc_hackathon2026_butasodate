import 'package:flutter/material.dart';

/// 草原の草が風になびくアニメーション（bg-meadow画面共通）
class GrassAnimation extends StatefulWidget {
  const GrassAnimation({super.key, required this.sx, required this.sy});
  final double sx, sy;
  @override
  State<GrassAnimation> createState() => _GrassAnimationState();
}

class _GrassAnimationState extends State<GrassAnimation> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(animation: _ctrl, builder: (_, __) {
      return CustomPaint(painter: _GrassPainter(_ctrl.value, widget.sx, widget.sy));
    });
  }
}

class _GrassPainter extends CustomPainter {
  final double t, sx, sy;
  _GrassPainter(this.t, this.sx, this.sy);

  static const _blades = [
    [30.0, 420.0], [120.0, 415.0], [210.0, 425.0], [310.0, 418.0],
    [70.0, 440.0], [160.0, 450.0], [250.0, 435.0], [340.0, 445.0],
    [45.0, 470.0], [135.0, 465.0], [225.0, 475.0], [305.0, 468.0],
    [80.0, 500.0], [180.0, 495.0], [270.0, 505.0], [360.0, 498.0],
    [50.0, 530.0], [150.0, 540.0], [240.0, 525.0], [330.0, 535.0],
    [100.0, 560.0], [200.0, 555.0], [290.0, 565.0], [370.0, 558.0],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (int i = 0; i < _blades.length; i++) {
      final bx = _blades[i][0] * sx;
      final by = _blades[i][1] * sy;
      final windPhase = t * 2 * 3.14159 - (_blades[i][0] / 390) * 3.14159;
      final bend = _sin(windPhase) * 3 * sx;
      paint.color = i % 3 == 0 ? const Color(0xFF2F6B3C) : const Color(0xFF4A9B5A);
      final h = (8 + (i % 3) * 2).toDouble() * sy;
      canvas.drawRect(Rect.fromLTWH(bx, by, 2 * sx, h * 0.4), paint);
      canvas.drawRect(Rect.fromLTWH(bx + bend * 0.3, by - h * 0.3, 2 * sx, h * 0.3), paint);
      canvas.drawRect(Rect.fromLTWH(bx + bend * 0.7, by - h * 0.6, 2 * sx, h * 0.3), paint);
    }
  }

  double _sin(double v) {
    v = v % (2 * 3.14159);
    if (v < 0) v += 2 * 3.14159;
    final x = v > 3.14159 ? v - 2 * 3.14159 : v;
    return (16 * x * (3.14159 - x)) / (5 * 3.14159 * 3.14159 - 4 * x * (3.14159 - x));
  }

  @override
  bool shouldRepaint(_GrassPainter old) => old.t != t;
}
