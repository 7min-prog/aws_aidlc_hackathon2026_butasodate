import 'dart:math';
import 'package:flutter/material.dart';
import 'package:buta_app/shared/theme.dart';

/// 星空背景ウィジェット（瞬きアニメーション付き）
/// X-00, X-02, X-06a/b/c等で共通利用
class StarryBackground extends StatefulWidget {
  final int seed;
  const StarryBackground({super.key, this.seed = 42});

  @override
  State<StarryBackground> createState() => _StarryBackgroundState();
}

class _StarryBackgroundState extends State<StarryBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<_Star> _stars;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    final rng = Random(widget.seed);
    _stars = [
      for (int i = 0; i < 150; i++) _Star(rng.nextDouble() * 390, rng.nextDouble() * 740, 2, ButaColors.paper, rng.nextDouble()),
      for (int i = 0; i < 60; i++) _Star(rng.nextDouble() * 390, rng.nextDouble() * 740, 3, ButaColors.paper, rng.nextDouble()),
      for (int i = 0; i < 25; i++) _Star(rng.nextDouble() * 390, rng.nextDouble() * 740, 3, ButaColors.yellow, rng.nextDouble()),
    ];
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final sx = size.width / 390;
    final sy = size.height / 740;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) => CustomPaint(size: size, painter: _StarPainter(_stars, _ctrl.value, sx, sy)),
    );
  }
}

class _Star {
  final double x, y, size;
  final Color color;
  final double phase;
  const _Star(this.x, this.y, this.size, this.color, this.phase);
}

class _StarPainter extends CustomPainter {
  final List<_Star> stars;
  final double t, sx, sy;
  _StarPainter(this.stars, this.t, this.sx, this.sy);

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in stars) {
      final opacity = (0.3 + 0.7 * ((sin((t + s.phase) * pi * 2) + 1) / 2)).clamp(0.0, 1.0);
      canvas.drawRect(Rect.fromLTWH(s.x * sx, s.y * sy, s.size * sx, s.size * sy), Paint()..color = s.color.withValues(alpha: opacity));
    }
  }

  @override
  bool shouldRepaint(_StarPainter old) => old.t != t;
}
