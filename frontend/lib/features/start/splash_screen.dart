import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:buta_app/shared/theme.dart';

/// X-01 スプラッシュ画面（アプリ起動時の最初の画面）
/// bg-starry + 中央にlogo-pig (120x120)
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    // 2秒後にX-00スタート画面へ遷移
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) context.go('/start');
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final sx = size.width / 390;
    final sy = size.height / 740;

    return Scaffold(
      backgroundColor: ButaColors.ink,
      body: Stack(
        children: [
          // 星空アニメーション
          _StarryBg(ctrl: _ctrl, sx: sx, sy: sy, size: size),
          // logo-pig 中央 (120x120, x:137, y:310)
          Positioned(
            top: 310 * sy,
            left: (size.width - 120 * sx) / 2,
            child: Container(
              width: 120 * sx, height: 120 * sx,
              decoration: BoxDecoration(color: ButaColors.pink, border: Border.all(color: ButaColors.ink, width: 2)),
              child: const Center(child: Text('🐷', style: TextStyle(fontSize: 48))),
            ),
          ),
        ],
      ),
    );
  }
}

class _StarryBg extends StatelessWidget {
  final AnimationController ctrl;
  final double sx, sy;
  final Size size;
  const _StarryBg({required this.ctrl, required this.sx, required this.sy, required this.size});

  static final List<_Star> _stars = _generateStars();
  static List<_Star> _generateStars() {
    final rng = Random(42);
    return [
      for (int i = 0; i < 150; i++) _Star(rng.nextDouble() * 390, rng.nextDouble() * 740, 2, ButaColors.paper, rng.nextDouble()),
      for (int i = 0; i < 60; i++) _Star(rng.nextDouble() * 390, rng.nextDouble() * 740, 3, ButaColors.paper, rng.nextDouble()),
      for (int i = 0; i < 25; i++) _Star(rng.nextDouble() * 390, rng.nextDouble() * 740, 3, ButaColors.yellow, rng.nextDouble()),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (context, _) => CustomPaint(size: size, painter: _StarPainter(_stars, ctrl.value, sx, sy)),
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
  final double t;
  final double sx, sy;
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
